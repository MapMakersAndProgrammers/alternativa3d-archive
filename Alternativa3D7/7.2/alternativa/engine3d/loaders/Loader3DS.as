package alternativa.engine3d.loaders {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	[Event (name="complete", type="flash.events.Event")]	
	/**
	 * 
	 */
	public class Loader3DS extends EventDispatcher {

		private static const STATE_IDLE:int = -1;
		private static const STATE_LOADING_MODEL:int = 0;
		private static const STATE_LOADING_TEXTURES:int = 1;
		
		private static var stubBitmapData:BitmapData;
		
		private var _content:Vector.<Mesh>;
		private var version:uint;
		private var objectDatas:Object;
		private var animationDatas:Array;
		private var materialDatas:Array;
		private var bitmaps:Array;
		
		private var modelLoader:URLLoader;
		private var textureLoader:TextureLoader;
		private var data:ByteArray;
		
		private var counter:int;
		private var textureMaterialNames:Array;
		private var context:LoaderContext;
		private var path:String;
		
		private var loaderState:int = STATE_IDLE;
		
		/**
		 * Повтор текстуры при заливке для создаваемых текстурных материалов.
		 * 
		 * @see alternativa.engine3d.materials.TextureMaterial
		 */
		public var repeat:Boolean = true;
		/**
		 * Сглаживание текстур при увеличении масштаба.
		 * 
		 * @see alternativa.engine3d.materials.TextureMaterial
		 */		
		public var smooth:Boolean = false;
		/**
		 * Режим наложения цвета для создаваемых текстурных материалов.
		 * 
		 * @see alternativa.engine3d.materials.TextureMaterial
		 */
		public var blendMode:String = BlendMode.NORMAL;

		/**
		 * Коэффициент пересчёта единиц измерения модели.
		 */
		public var units:Number = 1;
		/**
		 * Устанавливаемый уровень мобильности загруженных объектов.
		 */		
		public var mobility:int = 0;

		/**
		 * Прекращение текущей загрузки.
		 */
		public function close():void {
			if (loaderState == STATE_LOADING_MODEL) {
				modelLoader.close();
			}
			if (loaderState == STATE_LOADING_TEXTURES) {
				textureLoader.close();
			}
			loaderState = STATE_IDLE;
		}
		
		/**
		 * Метод очищает внутренние ссылки на загруженные данные чтобы сборщик мусора мог освободить занимаемую ими память. Метод не работает
		 * во время загрузки.
		 */
		public function unload():void {
			if (loaderState == STATE_IDLE) {
				clean();
			}
		}
		
		private function clean():void {
			_content = null;
			objectDatas = null;
			animationDatas = null;
			materialDatas = null;
			bitmaps = null;
			textureMaterialNames = null;
		}
		
		public function load(url:String, context:LoaderContext = null):void {
			path = url.substring(0, url.lastIndexOf("/") + 1);
			this.context = context;
			
			// Очистка
			version = 0;
			clean();
			
			if (modelLoader == null) {
				modelLoader = new URLLoader();
				modelLoader.dataFormat = URLLoaderDataFormat.BINARY;
				modelLoader.addEventListener(Event.COMPLETE, on3DSLoad);
				modelLoader.addEventListener(IOErrorEvent.IO_ERROR, on3DSError);
				modelLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, on3DSError);
			} else {
				close();
			}
			
			loaderState = STATE_LOADING_MODEL;
			modelLoader.load(new URLRequest(url));
		} 

		private function on3DSLoad(e:Event):void {
			loaderState = STATE_IDLE;
			data = modelLoader.data;
			data.endian = Endian.LITTLE_ENDIAN;
			parse3DSChunk(0, data.bytesAvailable);
		}
		
		private function on3DSError(e:Event):void {
			loaderState = STATE_IDLE;
			dispatchEvent(e);
		}
		
		private function loadBitmaps():void {
			if (textureLoader == null) {
				textureLoader = new TextureLoader();
				textureLoader.addEventListener(Event.COMPLETE, loadNextBitmap);
				textureLoader.addEventListener(IOErrorEvent.IO_ERROR, loadNextBitmap);
			}
			
			// Имена материалов с диффузными текстурами собираются в массив textureMaterialNames
			bitmaps = new Array();
			textureMaterialNames = new Array();
			for each (var materialData:MaterialData in materialDatas) {
				if (materialData.diffuseMap != null) {
					textureMaterialNames.push(materialData.name);
				}
			}
			
			loaderState = STATE_LOADING_TEXTURES;
			loadNextBitmap();
		}
		
		private function loadNextBitmap(e:Event = null):void {
			if (e != null) {
				if (!(e is IOErrorEvent)) {
					bitmaps[textureMaterialNames[counter]] = textureLoader.bitmapData;
				} else {
					if (stubBitmapData == null) {
						var size:uint = 20;
						stubBitmapData = new BitmapData(size, size, false, 0);
						for (var i:uint = 0; i < size; i++) {
							for (var j:uint = 0; j < size; j+=2) {
								stubBitmapData.setPixel((i % 2) ? j : (j+1), i, 0xFF00FF);
							}
						}
					}
					bitmaps[textureMaterialNames[counter]] = stubBitmapData;
				}
			} else {
				counter = -1;
			}
			counter++;
			if (counter < textureMaterialNames.length) {
				var materialData:MaterialData = materialDatas[textureMaterialNames[counter]];
				textureLoader.load(path + materialData.diffuseMap.filename, materialData.opacityMap == null ? null : path + materialData.opacityMap.filename, context);
			} else {
				loaderState = STATE_IDLE;
				buildContent();
			}
		}
		
		private function buildContent():void {
			var i:uint;
			var length:uint;
			
			// Формируем связи объектов
			_content = new Vector.<Mesh>();
			
			// Создаём материалы
			var materialData:MaterialData;
			for (var materialName:String in materialDatas) {
				materialData = materialDatas[materialName];
				var mapData:MapData = materialData.diffuseMap;
				var materialMatrix:Matrix = new Matrix();
				if (mapData != null) {
					var rot:Number = mapData.rotation*Math.PI/180;
					var rotSin:Number = Math.sin(rot);
					var rotCos:Number = Math.cos(rot);
					materialMatrix.translate(-mapData.offsetU, mapData.offsetV);
					materialMatrix.translate(-0.5, -0.5);
					materialMatrix.rotate(-rot);
					materialMatrix.scale(mapData.scaleU, mapData.scaleV);
					materialMatrix.translate(0.5, 0.5);
				}
				materialData.matrix = materialMatrix;
			}
			
			// Если есть данные об анимации и иерархии объектов
			var objectName:String;
			var objectData:ObjectData;
			var mesh:Mesh;
			if (animationDatas != null) {
				if (objectDatas != null) {
					
					length = animationDatas.length;
					for (i = 0; i < length; i++) {
						var animationData:AnimationData = animationDatas[i];
						objectName = animationData.objectName;
						objectData = objectDatas[objectName];
						
						// Если на один объект приходится несколько данных об анимации
						if (objectData != null) {
							var nameCounter:uint = 2;
							for (var j:uint = i + 1; j < length; j++) {
								var animationData2:AnimationData = animationDatas[j];
								if (objectName == animationData2.objectName) {
									var newName:String = objectName + nameCounter;
									var newObjectData:ObjectData = new ObjectData();
									animationData2.objectName = newName;
									newObjectData.name = newName;
									if (objectData.vertices != null) {
										newObjectData.vertices = new Vector.<Vector3D>().concat(objectData.vertices);
									}
									if (objectData.uvs != null) {
										newObjectData.uvs = new new Vector.<Point>().concat(objectData.uvs);
									}
									if (objectData.matrix != null) {
										newObjectData.matrix = objectData.matrix.clone();
									}
									if (objectData.faces != null) {
										newObjectData.faces = new Array().concat(objectData.faces);
									}
									if (objectData.surfaces != null) {
										newObjectData.surfaces = objectData.surfaces.clone();
									}
									objectDatas[newName] = newObjectData;
									nameCounter++;
								}
							}
						}
						
						if (objectData != null && objectData.vertices != null) {
							// Меш
							mesh = new Mesh();
							mesh.createEmptyGeometry(objectData.vertices.length, objectData.faces.length);
							animationData.object = mesh;
							buildObject(animationData);
							buildMesh(mesh, objectData, animationData);
							_content.push(mesh);
						}
					}
				}
			} else {
				for (objectName in objectDatas) {
					objectData = objectDatas[objectName];
					if (objectData.vertices != null) {
						// Меш
						mesh = new Mesh();
						mesh.createEmptyGeometry(objectData.vertices.length, objectData.faces.length);
						buildMesh(mesh, objectData, null);
						_content.push(mesh);
					}
				}
			}
			
			// Рассылаем событие о завершении
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function buildObject(animationData:AnimationData):void {
			var object:Mesh = animationData.object;
			object.name = animationData.objectName;
			var transform:Vector.<Vector3D> = new Vector.<Vector3D>(3, true);
			transform[0] = (animationData.position == null) ? new Vector3D() : new Vector3D(animationData.position.x * units, animationData.position.y * units, animationData.position.z * units);
			transform[1] = (animationData.rotation == null) ? new Vector3D() : animationData.rotation.clone();
			transform[2] = (animationData.scale == null) ? new Vector3D(1, 1, 1) : animationData.scale.clone();
			object.matrix.recompose(transform, Orientation3D.AXIS_ANGLE);
		}
		
		private function buildMesh(mesh:Mesh, objectData:ObjectData, animationData:AnimationData):void {
			// Добавляем вершины
			var i:uint;
			var j:uint;
			var key:*;
			var length:uint = objectData.vertices.length;
			for (i = 0; i < length; i++) {
				var vertexData:Vector3D = objectData.vertices[i];
				var uv:Point = objectData.uvs[i];
				j = i*3;
				mesh.vertices[j] = vertexData.x;
				mesh.vertices[j + 1] = vertexData.y;
				mesh.vertices[j + 2] = vertexData.z;
				mesh.uvts[j] = uv.x;
				mesh.uvts[j + 1] = 1 - uv.y;
			}
			
			// Коррекция вершин
			if (animationData != null) {
				// Инвертируем матрицу
				objectData.matrix.invert();
				
				// Вычитаем точку привязки из смещения матрицы
				if (animationData.pivot != null) {
					objectData.matrix.appendTranslation(-animationData.pivot.x, -animationData.pivot.y, -animationData.pivot.z); 
				}
				
				// Трансформируем вершины
				objectData.matrix.transformVectors(mesh.vertices, mesh.vertices);
			}
			for (i = 0; i < mesh.numVertices*3; i++) {
				mesh.vertices[i] *= units;
			}
			
			// Добавляем грани
			length = objectData.faces.length;
			for (i = 0; i < length; i++) {
				var faceData:FaceData = objectData.faces[i];
				j = i*3;
				mesh.indices[j] = faceData.a;
				mesh.indices[j + 1] = faceData.b;
				mesh.indices[j + 2] = faceData.c;
			}
			
			// Добавляем поверхности
			if (objectData.surfaces != null) {
				for (var surfaceId:String in objectData.surfaces) {
					var materialData:MaterialData = materialDatas[surfaceId];
					if (materialData.diffuseMap != null) {
						mesh.texture = bitmaps[materialData.name];
					}
				}
			}
		}
		private function parse3DSChunk(index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				
				switch (chunkId) {
					// Главный
					case 0x4D4D:
						parseMainChunk(dataIndex, dataLength);
						break;
				}
				
				parse3DSChunk(index + chunkLength, length - chunkLength);
			} else {
				// Загрузка битмап
				loadBitmaps();
			}
		}
		
		private function parseMainChunk(index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				
				switch (chunkId) {
					// Версия
					case 0x0002:
						parseVersion(dataIndex);
						break;
					// 3D-сцена
					case 0x3D3D:
						parse3DChunk(dataIndex, dataLength);
						break;
					// Анимация
					case 0xB000:
						parseAnimationChunk(dataIndex, dataLength);
						break;
				}
				
				parseMainChunk(index + chunkLength, length - chunkLength);
			}
		}
		
		private function parseVersion(index:uint):void {
			data.position = index;
			version = data.readUnsignedInt();
		}
		
		private function parse3DChunk(index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				
				switch (chunkId) {
					// Материал
					case 0xAFFF:
						// Парсим материал
						var material:MaterialData = new MaterialData();
						parseMaterialChunk(material, dataIndex, dataLength);
						break;
					// Объект
					case 0x4000:
						// Создаём данные объекта
						var object:ObjectData = new ObjectData();
						var objectLength:uint = parseObject(object, dataIndex);
						// Парсим объект
						parseObjectChunk(object, dataIndex + objectLength, dataLength - objectLength);
						break;
				}
				
				parse3DChunk(index + chunkLength, length - chunkLength);
			}
		}
		
		private function parseMaterialChunk(material:MaterialData, index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				switch (chunkId) {
					// Имя материала
					case 0xA000:
						parseMaterialName(material, dataIndex);
						break;
					// Ambient color
					case 0xA010:
						break;
					// Diffuse color
					case 0xA020:
						data.position = dataIndex + 6;
						material.color = (data.readUnsignedByte() << 16) + (data.readUnsignedByte() << 8) + data.readUnsignedByte();
						break;
					// Specular color
					case 0xA030:
						break;
					// Shininess percent
					case 0xA040:
						data.position = dataIndex + 6;
						material.glossiness = data.readUnsignedShort();
						break;
					// Shininess strength percent
					case 0xA041:
						data.position = dataIndex + 6;
						material.specular = data.readUnsignedShort();
						break;
					// Transperensy
					case 0xA050:
						data.position = dataIndex + 6;
						material.transparency = data.readUnsignedShort();
						break;
					// Texture map 1
					case 0xA200:
						material.diffuseMap = new MapData();
						parseMapChunk(material.name, material.diffuseMap, dataIndex, dataLength);
						break;
					// Texture map 2
					case 0xA33A:
						break;
					// Opacity map
					case 0xA210:
						material.opacityMap = new MapData();
						parseMapChunk(material.name, material.opacityMap, dataIndex, dataLength);
						break;
					// Bump map
					case 0xA230:
						//material.normalMap = new MapData();
						//parseMapChunk(material.normalMap, dataIndex, dataLength);
						break;
					// Shininess map
					case 0xA33C:
						break;
					// Specular map
					case 0xA204:
						break;
					// Self-illumination map
					case 0xA33D:
						break;
					// Reflection map
					case 0xA220:
						break;
				}
				
				parseMaterialChunk(material, index + chunkLength, length - chunkLength);
			}
		}
		
		private function parseMaterialName(material:MaterialData, index:uint):void {
			// Создаём список материалов, если надо
			if (materialDatas == null) {
				materialDatas = new Array();
			}
			// Получаем название материала
			material.name = getString(index);
			// Помещаем данные материала в список
			materialDatas[material.name] = material;
		}
		
		private function parseMapChunk(materialName:String, map:MapData, index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				
				switch (chunkId) {
					// Имя файла
					case 0xA300:
						map.filename = getString(dataIndex).toLowerCase();
						break;
					// Масштаб по U
					case 0xA354:
						data.position = dataIndex;
						map.scaleU = data.readFloat();
						break;
					// Масштаб по V
					case 0xA356:
						data.position = dataIndex;
						map.scaleV = data.readFloat();
						break;
					// Смещение по U
					case 0xA358:
						data.position = dataIndex;
						map.offsetU = data.readFloat();
						break;
					// Смещение по V
					case 0xA35A:
						data.position = dataIndex;
						map.offsetV = data.readFloat();
						break;
					// Угол поворота
					case 0xA35C:
						data.position = dataIndex;
						map.rotation = data.readFloat();
						break;
				}
				
				parseMapChunk(materialName, map, index + chunkLength, length - chunkLength);
			}
		}
		
		private function parseObject(object:ObjectData, index:uint):uint {
			// Создаём список объектов, если надо
			if (objectDatas == null) {
				objectDatas = new Object();
			}
			// Получаем название объекта
			object.name = getString(index);
			// Помещаем данные объекта в список
			objectDatas[object.name] = object;
			return object.name.length + 1;
		}
		
		private function parseObjectChunk(object:ObjectData, index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				
				switch (chunkId) {
					// Меш
					case 0x4100:
						parseMeshChunk(object, dataIndex, dataLength);
						break;
					// Источник света
					case 0x4600:
						break;
					// Камера
					case 0x4700:
						break;
				}
				
				parseObjectChunk(object, index + chunkLength, length - chunkLength);
			}
		}
		
		private function parseMeshChunk(object:ObjectData, index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				
				switch (chunkId) {
					// Вершины
					case 0x4110:
						parseVertices(object, dataIndex);
						break;
					// UV
					case 0x4140:
						parseUVs(object, dataIndex);
						break;
					// Трансформация
					case 0x4160:
						parseMatrix(object, dataIndex);
						break;
					// Грани
					case 0x4120:
						var facesLength:uint = parseFaces(object, dataIndex);
						parseFacesChunk(object, dataIndex + facesLength, dataLength - facesLength);
						break;
				}
				
				parseMeshChunk(object, index + chunkLength, length - chunkLength);
  			}
		}
		
		private function parseVertices(object:ObjectData, index:uint):void {
			data.position = index;
			var num:uint = data.readUnsignedShort();
			object.vertices = new Vector.<Vector3D>();
			for (var i:uint = 0; i < num; i++) {
				object.vertices.push(new Vector3D(data.readFloat(), data.readFloat(), data.readFloat()));
			}
		}
		
		private function parseUVs(object:ObjectData, index:uint):void {
			data.position = index;
			var num:uint = data.readUnsignedShort();
			object.uvs = new Vector.<Point>();
			for (var i:uint = 0; i < num; i++) {
				object.uvs.push(new Point(data.readFloat(), data.readFloat()));
			}
		}
		
		private function parseMatrix(object:ObjectData, index:uint):void {
			data.position = index;
			object.matrix = new Matrix3D(Vector.<Number>([
				data.readFloat(), data.readFloat(), data.readFloat(), 0,
				data.readFloat(), data.readFloat(), data.readFloat(), 0,
				data.readFloat(), data.readFloat(), data.readFloat(), 0,
				data.readFloat(), data.readFloat(), data.readFloat(), 1
			]));
		}
		
		private function parseFaces(object:ObjectData, index:uint):uint {
			data.position = index;
			var num:uint = data.readUnsignedShort();
			object.faces = new Array();
			for (var i:uint = 0; i < num; i++) {
				var face:FaceData = new FaceData();
				face.a = data.readUnsignedShort();
				face.b = data.readUnsignedShort();
				face.c = data.readUnsignedShort();
				object.faces.push(face);
				data.position += 2; // Пропускаем флаг
			}
			return 2 + num*8;
		}
		
		private function parseFacesChunk(object:ObjectData, index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				
				switch (chunkId) {
					// Поверхности
					case 0x4130:
						parseSurface(object, dataIndex);
						break;
					// Группы сглаживания
					case 0x4150:
						break;
				}
				
				parseFacesChunk(object, index + chunkLength, length - chunkLength);
  			}
		}
		
		private function parseSurface(object:ObjectData, index:uint):void {
			// Создаём данные поверхности
			var surface:SurfaceData = new SurfaceData();
			// Создаём список поверхностей, если надо
			if (object.surfaces == null) {
				object.surfaces = new Object();
			}
			// Получаем название материала
			surface.materialName = getString(index);
			// Помещаем данные поверхности в список
			object.surfaces[surface.materialName] = surface;
			
			// Получаем грани поверхности
			data.position = index + surface.materialName.length + 1;
			var num:uint = data.readUnsignedShort();
			surface.faces = new Array();
			for (var i:uint = 0; i < num; i++) {
				surface.faces.push(data.readUnsignedShort());
			}
		}
		
		private function parseAnimationChunk(index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				switch (chunkId) {
					// Анимация объекта
					case 0xB001:
					case 0xB002:
					case 0xB003:
					case 0xB004:
					case 0xB005:
					case 0xB006:
					case 0xB007:
						var animation:AnimationData = new AnimationData();
						if (animationDatas == null) {
							animationDatas = new Array();
						}
						animationDatas.push(animation);
						parseObjectAnimationChunk(animation, dataIndex, dataLength);
						break;
						
					// Таймлайн
					case 0xB008:
						break;
				}
				
				parseAnimationChunk(index + chunkLength, length - chunkLength);
  			}
		}

		private function parseObjectAnimationChunk(animation:AnimationData, index:uint, length:uint):void {
			if (length > 6) {
				data.position = index;
				var chunkId:uint = data.readUnsignedShort();
				var chunkLength:uint = data.readUnsignedInt();
				var dataIndex:uint = index + 6;
				var dataLength:uint = chunkLength - 6;
				switch (chunkId) {
					// Идентификация объекта и его связь
					case 0xB010:
						parseObjectAnimationInfo(animation, dataIndex);
						break;
					// Точка привязки объекта (pivot)
					case 0xB013:
						parseObjectAnimationPivot(animation, dataIndex);
						break;
					// Смещение объекта относительно родителя
					case 0xB020:
						parseObjectAnimationPosition(animation, dataIndex);
						break;
					// Поворот объекта относительно родителя (angle-axis)
					case 0xB021:
						parseObjectAnimationRotation(animation, dataIndex);
						break;
					// Масштабирование объекта относительно родителя
					case 0xB022:
						parseObjectAnimationScale(animation, dataIndex);
						break;
				}
				
				parseObjectAnimationChunk(animation, index + chunkLength, length - chunkLength);
  			}
		}

		private function parseObjectAnimationInfo(animation:AnimationData, index:uint):void {
			var name:String = getString(index);
			data.position = index + name.length + 1 + 4;
			animation.objectName = name;
			animation.parentIndex = data.readUnsignedShort();
		}
		
		private function parseObjectAnimationPivot(animation:AnimationData, index:uint):void {
			data.position = index;
			animation.pivot = new Vector3D(data.readFloat(), data.readFloat(), data.readFloat());
		}
		
		private function parseObjectAnimationPosition(animation:AnimationData, index:uint):void {
			data.position = index + 20;
			animation.position = new Vector3D(data.readFloat(), data.readFloat(), data.readFloat());
		}
		
		private function parseObjectAnimationRotation(animation:AnimationData, index:uint):void {
			data.position = index + 20;
			var angle:Number = data.readFloat();
			animation.rotation = new Vector3D(-data.readFloat(), -data.readFloat(), -data.readFloat(), angle);
		}
		
		private function parseObjectAnimationScale(animation:AnimationData, index:uint):void {
			data.position = index + 20;
			animation.scale = new Vector3D(data.readFloat(), data.readFloat(), data.readFloat());
		}
		
		/**
		 * Объект-контейнер, содержащий все загруженные объекты. 
		 */
		public function get content():Vector.<Mesh> {
			return _content;
		}
		
		// Считываем строку заканчивающуюся на нулевой байт
		private function getString(index:uint):String {
			data.position = index;
			var charCode:uint = data.readByte();
			var res:String = "";
			while (charCode != 0) {
				res += String.fromCharCode(charCode);
				charCode = data.readByte();
			}
			return res;
		}
		
		private function getRotationFrom3DSAngleAxis(angle:Number, x:Number, z:Number, y:Number):Vector3D {
			var res:Vector3D = new Vector3D();
			var s:Number = Math.sin(angle);
			var c:Number = Math.cos(angle);
			var t:Number = 1 - c;
			var k:Number = x*y*t + z*s;
			var half:Number;
			if (k > 0.998) {
				half = angle/2;
				res.z = -2*Math.atan2(x*Math.sin(half), Math.cos(half));
				res.y = -Math.PI/2;
				res.x = 0;
				return res;
			}
			if (k < -0.998) {
				half = angle/2;
				res.z = 2*Math.atan2(x*Math.sin(half), Math.cos(half));
				res.y = Math.PI/2;
				res.x = 0;
				return res;
			}
			res.z = -Math.atan2(y*s - x*z*t, 1 - (y*y + z*z)*t);
			res.y = -Math.asin(x*y*t + z*s);
			res.x = -Math.atan2(x*s - y*z*t, 1 - (x*x + z*z)*t);			
			return res;
		}
		
	}
}


import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import __AS3__.vec.Vector;
import flash.geom.Point;
import alternativa.engine3d.objects.Mesh;

class MaterialData {
	public var name:String;
	public var color:uint;
	public var specular:uint;
	public var glossiness:uint;
	public var transparency:uint;
	public var diffuseMap:MapData;
	public var opacityMap:MapData;
	//public var normalMap:MapData;
	public var matrix:Matrix;
}

class MapData {
	public var filename:String;
	public var scaleU:Number = 1;
	public var scaleV:Number = 1;
	public var offsetU:Number = 0;
	public var offsetV:Number = 0;
	public var rotation:Number = 0;
}

class ObjectData {
	public var name:String;
	public var vertices:Vector.<Vector3D>;
	public var uvs:Vector.<Point>;
	public var matrix:Matrix3D;
	public var faces:Array; 
	public var surfaces:Object;
}

class FaceData {
	public var a:uint;
	public var b:uint;
	public var c:uint;
}

class SurfaceData {
	public var materialName:String;
	public var faces:Array;
}

class AnimationData {
	public var objectName:String;
	public var object:Mesh;
	public var parentIndex:uint;
	public var pivot:Vector3D;
	public var position:Vector3D;
	public var rotation:Vector3D;
	public var scale:Vector3D;
}