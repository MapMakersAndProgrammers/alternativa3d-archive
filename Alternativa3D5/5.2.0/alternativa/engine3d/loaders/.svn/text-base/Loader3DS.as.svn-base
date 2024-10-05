package alternativa.engine3d.loaders {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Surface;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.TextureMaterialPrecision;
	import alternativa.engine3d.materials.WireMaterial;
	import alternativa.types.Matrix3D;
	import alternativa.types.Point3D;
	import alternativa.types.Texture;
	import alternativa.utils.ColorUtils;
	import alternativa.utils.MathUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Loader;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import alternativa.types.Map;
	
	use namespace alternativa3d;
	
	/**
	 * Загрузчик моделей в формате 3DS.
	 * 
	 * <p> Класс предоставляет средства загрузки объектов из 3DS-файла с заданным URL. Если
	 * в модели используются текстуры, то все файлы текстур должны находиться рядом с файлом модели.
	 * 
	 * <p> Из файла модели загружаются:
	 * <ul>
	 * <li> Все полигональные объекты с учётом их иерархии. Неподдерживаемые объекты заменяются экземплярами <code>Object3D</code>;
	 * <li> Материалы. Если для материала указанна диффузная текстура, то он представляется в виде <code>TextureMaterial</code>,
	 * иначе в виде <code>FillMaterial</code> с указанным цветом. Если произошла ошибка при загрузке файла текстуры
	 * (например, файл отсутствует), то создаётся текстура-заглушка и генерируется исключение.
	 * </ul>
	 * 
	 * Порядок загрузки каждого объекта из 3DS-файла:
	 * <ul>
	 * <li> Создаётся набор вершин и граней;
	 * <li> Грани, имеющие одинаковый назначенный материал, объединяются в поверхности. Идентификаторы поверхностей совпадают
	 * с названием соответствующего материала. 
	 * <li> Если для объекта не задан ни один материал, то все грани помещаются в одну поверхность, для которой устанавливается
	 * материал WireMaterial с линиями чёрного цвета.
	 * </ul>
	 * 
	 * Перед загрузкой файла можно установить ряд свойств, влияющих на создаваемые текстурные материалы.
	 */
	public class Loader3DS extends EventDispatcher {
		
		/**
		 * Коэффициент пересчёта в дюймы.  
		 */
		public static const INCHES:Number = 1;
		
		/**
		 * Коэффициент пересчёта в футы. 
		 */
		public static const FEET:Number = 0.0833333334;
		/**
		 * Коэффициент пересчёта в мили. 
		 */
		public static const MILES:Number = 0.0000157828;
		/**
		 * Коэффициент пересчёта в миллиметры. 
		 */
		public static const MILLIMETERS:Number = 25.4000000259;
		/**
		 * Коэффициент пересчёта в сантиметры. 
		 */
		public static const CENTIMETERS:Number = 2.5400000025;
		/**
		 * Коэффициент пересчёта в метры. 
		 */
		public static const METERS:Number = 0.0254;
		/**
		 * Коэффициент пересчёта в километры. 
		 */
		public static const KILOMETERS:Number = 0.0000254;
		
		private static var stub:BitmapData;
		
		private var _content:Object3D;
		private var version:uint;
		private var objectDatas:Map;
		private var animationDatas:Array;
		private var materialDatas:Array;
		private var bitmaps:Array;
		
		private var urlLoader:URLLoader;
		private var data:ByteArray;
		
		private var counter:uint;
		private var sequence:Array;
		private var loader:Loader;
		private var context:LoaderContext;
		private var path:String;
		
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
		 * Точность перспективной коррекции для создаваемых текстурных материалов.
		 * 
		 * @see alternativa.engine3d.materials.TextureMaterial
		 */		
		public var precision:Number = TextureMaterialPrecision.MEDIUM;

		/**
		 * Коэффициент пересчёта единиц измерения модели.
		 */
		public var units:Number = INCHES;
		/**
		 * Устанавливаемый уровень мобильности загруженных объектов.
		 */		
		public var mobility:int = 0;

		/**
		 * Загрузка модели. При успешном окончании загрузки генерируется событие <code>Event.COMPLETE</code>.
		 * 
		 * @param url URL файла модели
		 * @param context
		 */
		public function load(url:String, context:LoaderContext = null):void {
			path = url.substring(0, url.lastIndexOf("/") + 1);
			this.context = context;
			
			urlLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.load(new URLRequest(url));
			urlLoader.addEventListener(Event.COMPLETE, on3DSLoad);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, on3DSError);
			urlLoader.addEventListener(IOErrorEvent.NETWORK_ERROR, on3DSError);
			urlLoader.addEventListener(IOErrorEvent.VERIFY_ERROR, on3DSError);
			
			// Очистка
			_content = null;
			version = 0;
			objectDatas = null;
			animationDatas = null;
			materialDatas = null;
			bitmaps = null;
			sequence = null;
			if (loader != null) {
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadNextBitmap);
				loader.close();
				loader = null;
			}
		} 
		
		private function on3DSLoad(e:Event):void {
			data = urlLoader.data;
			data.endian = Endian.LITTLE_ENDIAN;
			parse3DSChunk(0, data.bytesAvailable);
			
			urlLoader.removeEventListener(Event.COMPLETE, on3DSLoad);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, on3DSError);
			urlLoader.removeEventListener(IOErrorEvent.NETWORK_ERROR, on3DSError);
			urlLoader.removeEventListener(IOErrorEvent.VERIFY_ERROR, on3DSError);
			urlLoader = null;
		}
		
		private function on3DSError(e:Event):void {
			_content = null;

			urlLoader.removeEventListener(Event.COMPLETE, on3DSLoad);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, on3DSError);
			urlLoader.removeEventListener(IOErrorEvent.NETWORK_ERROR, on3DSError);
			urlLoader.removeEventListener(IOErrorEvent.VERIFY_ERROR, on3DSError);

			throw new IOError(IOErrorEvent(e).text);
		}
		
		private function loadBitmaps():void {
			if (bitmaps != null) {
				counter = 0;
				sequence = new Array();
				for (var filename:String in bitmaps) {
					sequence.push(filename);
				}
				loader = new Loader();
				loader.load(new URLRequest(path + sequence[counter]), context);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadNextBitmap);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadNextBitmap);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, loadNextBitmap);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, loadNextBitmap);
			} else {
				buildContent();
			}
		}
		
		private function loadNextBitmap(e:Event = null):void {
			if (!(e is IOErrorEvent)) {
				bitmaps[sequence[counter]] = Bitmap(loader.content).bitmapData;
			} else {
				if (stub == null) {
					var size:uint = 10;
					stub = new BitmapData(size, size, false, 0);
					for (var i:uint = 0; i < size; i++) {
						for (var j:uint = 0; j < size; j+=2) {
							stub.setPixel((i % 2) ? j : (j+1), i, 0xFF00FF);
						}
					}
				}
				bitmaps[sequence[counter]] = stub;
			}
			counter++;
			if (counter < sequence.length) {
				loader.load(new URLRequest(path + sequence[counter]), context);
			} else {
				buildContent();
			}
			if (e is IOErrorEvent) {
				throw new IOError(IOErrorEvent(e).text);
			}
		}
		
		private function buildContent():void {
			var i:uint;
			var length:uint;
			
			// Формируем связи объектов
			_content = new Object3D();
			
			// Создаём материалы
			var materialData:MaterialData;
			for (var materialName:String in materialDatas) {
				materialData = materialDatas[materialName];
				var mapData:MapData = materialData.diffuseMap;
				var materialMatrix:Matrix = new Matrix();
				if (mapData != null) {
					var rot:Number = MathUtils.toRadian(mapData.rotation);
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
										newObjectData.vertices = new Array().concat(objectData.vertices);
									}
									if (objectData.uvs != null) {
										newObjectData.uvs = new Array().concat(objectData.uvs);
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
							mesh = new Mesh(objectName);
							animationData.object = mesh;
							buildObject(animationData);
							buildMesh(mesh, objectData, animationData);
						} else {
							var object:Object3D = new Object3D(objectName);
							animationData.object = object;
							buildObject(animationData);
						}
					}
					
					buildHierarchy(_content, 0, length - 1);
				}
			} else {
				for (objectName in objectDatas) {
					objectData = objectDatas[objectName];
					if (objectData.vertices != null) {
						// Меш
						mesh = new Mesh(objectName);
						buildMesh(mesh, objectData, null);
						_content.addChild(mesh);
					}
				}
			}
			
			// Рассылаем событие о завершении
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function buildObject(animationData:AnimationData):void {
			var object:Object3D = animationData.object;
			if (animationData.position != null) {
				object.x = animationData.position.x * units;
				object.y = animationData.position.y * units;
				object.z = animationData.position.z * units;
			}
			if (animationData.rotation != null) {
				object.rotationX = animationData.rotation.x;
				object.rotationY = animationData.rotation.y;
				object.rotationZ = animationData.rotation.z;
			}
			if (animationData.scale != null) {
				object.scaleX = animationData.scale.x;
				object.scaleY = animationData.scale.y;
				object.scaleZ = animationData.scale.z;
			}
			object.mobility = mobility;
		}
		
		private function buildMesh(mesh:Mesh, objectData:ObjectData, animationData:AnimationData):void {
			// Добавляем вершины
			var i:uint;
			var key:*;
			var vertex:Vertex;
			var face:Face;
			var length:uint = objectData.vertices.length;
			for (i = 0; i < length; i++) {
				var vertexData:Point3D = objectData.vertices[i];
				objectData.vertices[i] = mesh.createVertex(vertexData.x, vertexData.y, vertexData.z, i);
			}
			
			// Коррекция вершин
			if (animationData != null) {
				// Инвертируем матрицу
				objectData.matrix.invert();
				
				// Вычитаем точку привязки из смещения матрицы
				objectData.matrix.d -= animationData.pivot.x;
				objectData.matrix.h -= animationData.pivot.y;
				objectData.matrix.l -= animationData.pivot.z;
				
				// Трансформируем вершины
				for (key in mesh._vertices) {
					vertex = mesh._vertices[key];
					vertex._coords.transform(objectData.matrix);
				}
			}
			for (key in mesh._vertices) {
				vertex = mesh._vertices[key];
				vertex._coords.multiply(units);
			}
			
			// Добавляем грани
			length = objectData.faces.length;
			for (i = 0; i < length; i++) {
				var faceData:FaceData = objectData.faces[i];
				face = mesh.createFace([objectData.vertices[faceData.a], objectData.vertices[faceData.b], objectData.vertices[faceData.c]], i);
				if (objectData.uvs != null) {
					face.aUV = objectData.uvs[faceData.a];
					face.bUV = objectData.uvs[faceData.b];
					face.cUV = objectData.uvs[faceData.c];
				}
			}
			
			// Добавляем поверхности
			if (objectData.surfaces != null) {
				for (var surfaceId:String in objectData.surfaces) {
					var materialData:MaterialData = materialDatas[surfaceId];
					var surfaceData:SurfaceData = objectData.surfaces[surfaceId];
					var surface:Surface = mesh.createSurface(surfaceData.faces, surfaceId);
					if (materialData.diffuseMap != null) {
						surface.material = new TextureMaterial(new Texture(bitmaps[materialData.diffuseMap.filename], materialData.diffuseMap.filename), 1 - materialData.transparency/100, repeat, smooth, blendMode, -1, 0, precision);
						length = surfaceData.faces.length;
						for (i = 0; i < length; i++) {
							face = mesh.getFaceById(surfaceData.faces[i]);
							if (face._aUV != null && face._bUV != null && face._cUV != null && ((face._bUV.x - face._aUV.x)*(face._cUV.y - face._aUV.y) - (face._bUV.y - face._aUV.y)*(face._cUV.x - face._aUV.x) != 0)) {
								var m:Matrix = materialData.matrix;
								var x:Number = face.aUV.x;
								var y:Number = face.aUV.y;
								face._aUV.x = m.a*x + m.b*y + m.tx; 
								face._aUV.y = m.c*x + m.d*y + m.ty; 
								x = face._bUV.x;
								y = face._bUV.y;
								face._bUV.x = m.a*x + m.b*y + m.tx; 
								face._bUV.y = m.c*x + m.d*y + m.ty; 
								x = face._cUV.x;
								y = face._cUV.y;
								face._cUV.x = m.a*x + m.b*y + m.tx; 
								face._cUV.y = m.c*x + m.d*y + m.ty; 
							} else {
								face.aUV = null;
								face.bUV = null;
								face.cUV = null;
							}
						}
					} else {
						surface.material = new FillMaterial(materialDatas[surfaceId].color, 1 - materialData.transparency/100);
					}
				}
			} else {
				// Поверхность по умолчанию
				var defaultSurface:Surface = mesh.createSurface();
				// Добавляем грани
				for (var faceId:String in mesh._faces) {
					defaultSurface.addFace(mesh._faces[faceId]);
				}
				defaultSurface.material = new WireMaterial(0, 0x7F7F7F);
			}
		}
		
		private function buildHierarchy(parent:Object3D, begin:uint, end:uint):void {
			if (begin <= end) {
				var animation:AnimationData = animationDatas[begin];
				var object:Object3D = animation.object;
				parent.addChild(object);
				
				var parentIndex:uint = animation.parentIndex;
				for (var i:uint = begin + 1; i <= end; i++) {
					animation = animationDatas[i];
					if (parentIndex == animation.parentIndex) {
						buildHierarchy(object, begin + 1, i - 1);
						buildHierarchy(parent, i, end);
						return;
					}
				}
				buildHierarchy(object, begin + 1, end);
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
						material.color = ColorUtils.rgb(data.readUnsignedByte(), data.readUnsignedByte(), data.readUnsignedByte());
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
						parseMapChunk(material.diffuseMap, dataIndex, dataLength);
						break;
					// Texture map 2
					case 0xA33A:
						break;
					// Opacity map
					case 0xA210:
						break;
					// Bump map
					case 0xA230:
						material.normalMap = new MapData();
						parseMapChunk(material.normalMap, dataIndex, dataLength);
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
		
		private function parseMapChunk(map:MapData, index:uint, length:uint):void {
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
						if (bitmaps == null) {
							bitmaps = new Array();
						}
						bitmaps[map.filename] = null;
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
				
				parseMapChunk(map, index + chunkLength, length - chunkLength);
			}
		}
		
		private function parseObject(object:ObjectData, index:uint):uint {
			// Создаём список объектов, если надо
			if (objectDatas == null) {
				objectDatas = new Map();
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
			object.vertices = new Array();
			for (var i:uint = 0; i < num; i++) {
				object.vertices.push(new Point3D(data.readFloat(), data.readFloat(), data.readFloat()));
			}
		}
		
		private function parseUVs(object:ObjectData, index:uint):void {
			data.position = index;
			var num:uint = data.readUnsignedShort();
			object.uvs = new Array();
			for (var i:uint = 0; i < num; i++) {
				object.uvs.push(new Point(data.readFloat(), data.readFloat()));
			}
		}
		
		private function parseMatrix(object:ObjectData, index:uint):void {
			data.position = index;
			object.matrix = new Matrix3D();
			object.matrix.a = data.readFloat();
			object.matrix.e = data.readFloat();
			object.matrix.i = data.readFloat();
			object.matrix.b = data.readFloat();
			object.matrix.f = data.readFloat();
			object.matrix.j = data.readFloat();
			object.matrix.c = data.readFloat();
			object.matrix.g = data.readFloat();
			object.matrix.k = data.readFloat();
			object.matrix.d = data.readFloat();
			object.matrix.h = data.readFloat();
			object.matrix.l = data.readFloat();
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
				object.surfaces = new Map();
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
			animation.pivot = new Point3D(data.readFloat(), data.readFloat(), data.readFloat());
		}
		
		private function parseObjectAnimationPosition(animation:AnimationData, index:uint):void {
			data.position = index + 20;
			animation.position = new Point3D(data.readFloat(), data.readFloat(), data.readFloat());
		}
		
		private function parseObjectAnimationRotation(animation:AnimationData, index:uint):void {
			data.position = index + 20;
			animation.rotation = getRotationFrom3DSAngleAxis(data.readFloat(), data.readFloat(), data.readFloat(), data.readFloat());
		}
		
		private function parseObjectAnimationScale(animation:AnimationData, index:uint):void {
			data.position = index + 20;
			animation.scale = new Point3D(data.readFloat(), data.readFloat(), data.readFloat());
		}
		
		/**
		 * Объект-контейнер, содержащий все загруженные объекты. 
		 */
		public function get content():Object3D {
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
		
		private function getRotationFrom3DSAngleAxis(angle:Number, x:Number, z:Number, y:Number):Point3D {
			var res:Point3D = new Point3D();
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

import alternativa.engine3d.core.Object3D;
import alternativa.types.Matrix3D;
import alternativa.types.Point3D;

import flash.geom.Matrix;
import alternativa.types.Map;

class MaterialData {
	public var name:String;
	public var color:uint;
	public var specular:uint;
	public var glossiness:uint;
	public var transparency:uint;
	public var diffuseMap:MapData;
	public var normalMap:MapData;
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
	public var vertices:Array;
	public var uvs:Array;
	public var matrix:Matrix3D;
	public var faces:Array; 
	public var surfaces:Map; 
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
	public var object:Object3D;
	public var parentIndex:uint;
	public var pivot:Point3D;
	public var position:Point3D;
	public var rotation:Point3D;
	public var scale:Point3D;
}