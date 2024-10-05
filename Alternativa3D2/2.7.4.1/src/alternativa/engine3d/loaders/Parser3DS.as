package alternativa.engine3d.loaders {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.geom.Matrix;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	use namespace alternativa3d;
	
	public class Parser3DS {
	
		private static const CHUNK_MAIN:int = 0x4D4D;
		private static const CHUNK_VERSION:int = 0x0002;
		private static const CHUNK_SCENE:int = 0x3D3D;
		private static const CHUNK_ANIMATION:int = 0xB000;
		private static const CHUNK_OBJECT:int = 0x4000;
		private static const CHUNK_TRIMESH:int = 0x4100;
		private static const CHUNK_VERTICES:int = 0x4110;
		private static const CHUNK_FACES:int = 0x4120;
		private static const CHUNK_FACESMATERIAL:int = 0x4130;
		private static const CHUNK_MAPPINGCOORDS:int = 0x4140;
		//private static const CHUNK_OBJECTCOLOR:int = 0x4165;
		private static const CHUNK_TRANSFORMATION:int = 0x4160;
		//private static const CHUNK_MESHANIMATION:int = 0xB002;
		private static const CHUNK_MATERIAL:int = 0xAFFF;
	
		private var data:ByteArray;
		private var objectDatas:Object;
		private var animationDatas:Array;
		private var materialDatas:Object;
	
		public var objects:Vector.<Object3D>;
		public var parents:Vector.<Object3D>;
		public var materials:Vector.<Material>;
		public var textureMaterials:Vector.<TextureMaterial>;
	
		public function parse(data:ByteArray, texturesBaseURL:String = "", scale:Number = 1):void {
			if (data.bytesAvailable < 6) return;
			this.data = data;
			data.endian = Endian.LITTLE_ENDIAN;
			parse3DSChunk(data.position, data.bytesAvailable);
			objects = new Vector.<Object3D>();
			parents = new Vector.<Object3D>();
			materials = new Vector.<Material>();
			textureMaterials = new Vector.<TextureMaterial>();
			buildContent(texturesBaseURL, scale);
			data = null;
			objectDatas = null;
			animationDatas = null;
			materialDatas = null;
		}
	
		private function readChunkInfo(dataPosition:int):ChunkInfo {
			data.position = dataPosition;
			var chunkInfo:ChunkInfo = new ChunkInfo();
			chunkInfo.id = data.readUnsignedShort();
			chunkInfo.size = data.readUnsignedInt();
			chunkInfo.dataSize = chunkInfo.size - 6;
			chunkInfo.dataPosition = data.position;
			chunkInfo.nextChunkPosition = dataPosition + chunkInfo.size;
			return chunkInfo;
		}
	
		private function parse3DSChunk(dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			data.position = dataPosition;
			switch (chunkInfo.id) {
				// Главный
				case CHUNK_MAIN:
					parseMainChunk(chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
			}
			parse3DSChunk(chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}
	
		private function parseMainChunk(dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Версия
				case CHUNK_VERSION:
					//version = data.readUnsignedInt();
					break;
				// 3D-сцена
				case CHUNK_SCENE:
					parse3DChunk(chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
				// Анимация
				case CHUNK_ANIMATION:
					parseAnimationChunk(chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
			}
			parseMainChunk(chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}
	
		private function parse3DChunk(dataPosition:int, bytesAvailable:int):void {
			while (bytesAvailable >= 6) {
				var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
				switch (chunkInfo.id) {
					// Материал
					case CHUNK_MATERIAL:
						// Парсим материал
						var material:MaterialData = new MaterialData();
						parseMaterialChunk(material, chunkInfo.dataPosition, chunkInfo.dataSize);
						break;
					// Объект
					case CHUNK_OBJECT:
						parseObject(chunkInfo);
						break;
				}
				dataPosition = chunkInfo.nextChunkPosition;
				bytesAvailable -= chunkInfo.size;
			}
		}
	
		private function parseObject(chunkInfo:ChunkInfo):void {
			// Создаём список объектов, если надо
			if (objectDatas == null) {
				objectDatas = new Object();
			}
			// Создаём данные объекта
			var object:ObjectData = new ObjectData();
			// Получаем название объекта
			object.name = getString(chunkInfo.dataPosition);
			// Помещаем данные объекта в список
			objectDatas[object.name] = object;
			// Парсим объект
			var offset:int = object.name.length + 1;
			parseObjectChunk(object, chunkInfo.dataPosition + offset, chunkInfo.dataSize - offset);
		}
	
		private function parseObjectChunk(object:ObjectData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Меш
				case CHUNK_TRIMESH:
					parseMeshChunk(object, chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
				// Источник света
				case 0x4600:
					break;
				// Камера
				case 0x4700:
					break;
			}
			parseObjectChunk(object, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}
	
		private function parseMeshChunk(object:ObjectData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Вершины
				case CHUNK_VERTICES:
					parseVertices(object);
					break;
				// UV
				case CHUNK_MAPPINGCOORDS:
					parseUVs(object);
					break;
				// Трансформация
				case CHUNK_TRANSFORMATION:
					parseMatrix(object);
					break;
				// Грани
				case CHUNK_FACES:
					parseFaces(object, chunkInfo);
					break;
			}
			parseMeshChunk(object, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}
	
		private function parseVertices(object:ObjectData):void {
			var num:int = data.readUnsignedShort();
			object.vertices = new Vector.<Number>();
			for (var i:int = 0, j:int = 0; i < num; i++) {
				object.vertices[j++] = data.readFloat();
				object.vertices[j++] = data.readFloat();
				object.vertices[j++] = data.readFloat();
			}
		}
	
		private function parseUVs(object:ObjectData):void {
			var num:int = data.readUnsignedShort();
			object.uvs = new Vector.<Number>();
			for (var i:int = 0, j:int = 0; i < num; i++) {
				object.uvs[j++] = data.readFloat();
				object.uvs[j++] = data.readFloat();
			}
		}
	
		private function parseMatrix(object:ObjectData):void {
			object.a = data.readFloat();
			object.e = data.readFloat();
			object.i = data.readFloat();
			object.b = data.readFloat();
			object.f = data.readFloat();
			object.j = data.readFloat();
			object.c = data.readFloat();
			object.g = data.readFloat();
			object.k = data.readFloat();
			object.d = data.readFloat();
			object.h = data.readFloat();
			object.l = data.readFloat();
		}
	
		private function parseFaces(object:ObjectData, chunkInfo:ChunkInfo):void {
			var num:int = data.readUnsignedShort();
			object.faces = new Vector.<int>();
			for (var i:int = 0, j:int = 0; i < num; i++) {
				object.faces[j++] = data.readUnsignedShort();
				object.faces[j++] = data.readUnsignedShort();
				object.faces[j++] = data.readUnsignedShort();
				data.position += 2; // Пропускаем флаг отрисовки рёбер
			}
			var offset:int = 2 + 8*num;
			parseFacesChunk(object, chunkInfo.dataPosition + offset, chunkInfo.dataSize - offset);
		}
	
		private function parseFacesChunk(object:ObjectData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Поверхности
				case CHUNK_FACESMATERIAL:
					parseSurface(object);
					break;
			}
			parseFacesChunk(object, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}
	
		private function parseSurface(object:ObjectData):void {
			// Создаём список поверхностей, если надо
			if (object.surfaces == null) {
				object.surfaces = new Object();
			}
			// Создаём данные поверхности
			var surface:Vector.<int> = new Vector.<int>;
			// Помещаем данные поверхности в список
			object.surfaces[getString(data.position)] = surface;
			// Получаем грани поверхности
			var num:int = data.readUnsignedShort();
			for (var i:int = 0; i < num; i++) {
				surface[i] = data.readUnsignedShort();
			}
		}
	
		private function parseAnimationChunk(dataPosition:int, bytesAvailable:int):void {
			while (bytesAvailable >= 6) {
				var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
				switch (chunkInfo.id) {
					// Анимация объекта
					case 0xB001:
					case 0xB002:
					case 0xB003:
					case 0xB004:
					case 0xB005:
					case 0xB006:
					case 0xB007:
						if (animationDatas == null) {
							animationDatas = new Array();
						}
						var animation:AnimationData = new AnimationData();
						animationDatas.push(animation);
						parseObjectAnimationChunk(animation, chunkInfo.dataPosition, chunkInfo.dataSize);
						break;
					// Таймлайн
					case 0xB008:
						break;
				}
				dataPosition = chunkInfo.nextChunkPosition;
				bytesAvailable -= chunkInfo.size;
			}
		}
	
		private function parseObjectAnimationChunk(animation:AnimationData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Идентификация объекта и его связь
				case 0xB010:
					// Имя объекта
					animation.objectName = getString(data.position);
					data.position += 4;
					// Индекс родительского объекта в линейном списке объектов сцены
					animation.parentIndex = data.readUnsignedShort();
					break;
				// Имя dummy объекта
				case 0xB011:
					animation.objectName = getString(data.position);
					break;
				// Точка привязки объекта (pivot)
				case 0xB013:
					animation.pivot = new Vector3D(data.readFloat(), data.readFloat(), data.readFloat());
					break;
				// Смещение объекта относительно родителя
				case 0xB020:
					data.position += 20;
					animation.position = new Vector3D(data.readFloat(), data.readFloat(), data.readFloat());
					break;
				// Поворот объекта относительно родителя (angle-axis)
				case 0xB021:
					data.position += 20;
					animation.rotation = getRotationFrom3DSAngleAxis(data.readFloat(), data.readFloat(), data.readFloat(), data.readFloat());
					break;
				// Масштабирование объекта относительно родителя
				case 0xB022:
					data.position += 20;
					animation.scale = new Vector3D(data.readFloat(), data.readFloat(), data.readFloat());
					break;
			}
			parseObjectAnimationChunk(animation, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}
	
		private function parseMaterialChunk(material:MaterialData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Имя материала
				case 0xA000:
					parseMaterialName(material);
					break;
				// Ambient color
				case 0xA010:
					break;
				// Diffuse color
				case 0xA020:
					data.position = chunkInfo.dataPosition + 6;
					material.color = (data.readUnsignedByte() << 16) + (data.readUnsignedByte() << 8) + data.readUnsignedByte();
					break;
				// Specular color
				case 0xA030:
					break;
				// Shininess percent
				case 0xA040:
					data.position = chunkInfo.dataPosition + 6;
					material.glossiness = data.readUnsignedShort();
					break;
				// Shininess strength percent
				case 0xA041:
					data.position = chunkInfo.dataPosition + 6;
					material.specular = data.readUnsignedShort();
					break;
				// Transperensy
				case 0xA050:
					data.position = chunkInfo.dataPosition + 6;
					material.transparency = data.readUnsignedShort();
					break;
				// Texture map 1
				case 0xA200:
					material.diffuseMap = new MapData();
					parseMapChunk(material.name, material.diffuseMap, chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
				// Texture map 2
				case 0xA33A:
					break;
				// Opacity map
				case 0xA210:
					material.opacityMap = new MapData();
					parseMapChunk(material.name, material.opacityMap, chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
				// Bump map
				case 0xA230:
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
			parseMaterialChunk(material, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}
	
		private function parseMaterialName(material:MaterialData):void {
			// Создаём список материалов, если надо
			if (materialDatas == null) {
				materialDatas = new Object();
			}
			// Получаем название материала
			material.name = getString(data.position);
			// Помещаем данные материала в список
			materialDatas[material.name] = material;
		}
	
		private function parseMapChunk(materialName:String, map:MapData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Имя файла
				case 0xA300:
					map.filename = getString(chunkInfo.dataPosition).toLowerCase();
					break;
				case 0xA351:
					// Параметры текстурирования
					//trace("MAP OPTIONS", data.readShort().toString(2));
					break;
				// Масштаб по U
				case 0xA354:
					map.scaleU = data.readFloat();
					break;
				// Масштаб по V
				case 0xA356:
					map.scaleV = data.readFloat();
					break;
				// Смещение по U
				case 0xA358:
					map.offsetU = data.readFloat();
					break;
				// Смещение по V
				case 0xA35A:
					map.offsetV = data.readFloat();
					break;
				// Угол поворота
				case 0xA35C:
					map.rotation = data.readFloat();
					break;
			}
			parseMapChunk(materialName, map, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}
	
		private function buildContent(texturesBaseURL:String, scale:Number):void {
			// Расчёт матриц текстурных материалов
			for (var materialName:String in materialDatas) {
				var materialData:MaterialData = materialDatas[materialName];
				var mapData:MapData = materialData.diffuseMap;
				if (mapData != null) {
					var materialMatrix:Matrix = new Matrix();
					var rot:Number = mapData.rotation*Math.PI/180;
					materialMatrix.translate(-mapData.offsetU, mapData.offsetV);
					materialMatrix.translate(-0.5, -0.5);
					materialMatrix.rotate(-rot);
					materialMatrix.scale(mapData.scaleU, mapData.scaleV);
					materialMatrix.translate(0.5, 0.5);
					materialData.matrix = materialMatrix;
					var textureMaterial:TextureMaterial = new TextureMaterial();
					textureMaterial.name = materialName;
					textureMaterial.diffuseMapURL = texturesBaseURL + mapData.filename;
					textureMaterial.opacityMapURL = (materialData.opacityMap != null) ? (texturesBaseURL + materialData.opacityMap.filename) : null;
					materialData.material = textureMaterial;
					textureMaterial.name = materialData.name;
					textureMaterials.push(textureMaterial);
				} else {
					var fillMaterial:FillMaterial = new FillMaterial(materialData.color);
					materialData.material = fillMaterial;
					fillMaterial.name = materialData.name;
				}
				materials.push(materialData.material);
			}
			var objectName:String;
			var objectData:ObjectData;
			var object:Object3D;
			// В сцене есть иерархически связанные оьъекты и (или) указаны данные о трансформации объектов.
			if (animationDatas != null) {
				if (objectDatas != null) {
					var i:int;
					var length:int = animationDatas.length;
					var animationData:AnimationData;
					for (i = 0; i < length; i++) {
						animationData = animationDatas[i];
						objectName = animationData.objectName;
						objectData = objectDatas[objectName];
						// Проверка на инстансы
						if (objectData != null) {
							for (var j:int = i + 1, nameCounter:int = 1; j < length; j++) {
								var animationData2:AnimationData = animationDatas[j];
								if (!animationData2.isInstance && objectName == animationData2.objectName) {
									// Найдено совпадение имени объекта в проверяемой секции анимации. Создаём референс.
									var newObjectData:ObjectData = new ObjectData();
									var newName:String = objectName + nameCounter++;
									newObjectData.name = newName;
									objectDatas[newName] = newObjectData;
									animationData2.objectName = newName;
									newObjectData.vertices = objectData.vertices;
									newObjectData.uvs = objectData.uvs;
									newObjectData.faces = objectData.faces;
									newObjectData.surfaces = objectData.surfaces;
									newObjectData.a = objectData.a;
									newObjectData.b = objectData.b;
									newObjectData.c = objectData.c;
									newObjectData.d = objectData.d;
									newObjectData.e = objectData.e;
									newObjectData.f = objectData.f;
									newObjectData.g = objectData.g;
									newObjectData.h = objectData.h;
									newObjectData.i = objectData.i;
									newObjectData.j = objectData.j;
									newObjectData.k = objectData.k;
									newObjectData.l = objectData.l;
								}
							}
						}
						// Если меш
						if (objectData != null && objectData.vertices != null) {
							// Создание полигонального объекта
							object = new Mesh();
							buildMesh(object as Mesh, objectData, animationData, scale);
						} else {
							// Создание пустого 3д-объекта
							object = new Object3D();
						}
						object.name = objectName;
						animationData.object = object;
						if (animationData.position != null) {
							object.x = animationData.position.x*scale;
							object.y = animationData.position.y*scale;
							object.z = animationData.position.z*scale;
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
					}
					// Добавление объектов
					for (i = 0; i < length; i++) {
						animationData = animationDatas[i];
						objects.push(animationData.object);
						parents.push((animationData.parentIndex == 0xFFFF) ? null : AnimationData(animationDatas[animationData.parentIndex]).object);
					}
				}
				// В сцене нет иерархически связанных объектов и не заданы трансформации для объектов. В контейнер добавляются только полигональные объекты.
			} else {
				for (objectName in objectDatas) {
					objectData = objectDatas[objectName];
					if (objectData.vertices != null) {
						object = new Mesh();
						object.name = objectName;
						buildMesh(object as Mesh, objectData, null, scale);
						objects.push(object);
						parents.push(null);
					}
				}
			}
		}
	
		private function buildMesh(mesh:Mesh, objectData:ObjectData, animationData:AnimationData, scale:Number):void {
			var vertices:Vector.<Vertex> = new Vector.<Vertex>();
			var faces:Vector.<Face> = new Vector.<Face>();
			var numVertices:int = 0;
			var numFaces:int = 0;
			var n:int;
			var m:int;
			var face:Face;
			var vertex:Vertex;
			var correct:Boolean = false;
			if (animationData != null) {
				var a:Number = objectData.a;
				var b:Number = objectData.b;
				var c:Number = objectData.c;
				var d:Number = objectData.d;
				var e:Number = objectData.e;
				var f:Number = objectData.f;
				var g:Number = objectData.g;
				var h:Number = objectData.h;
				var i:Number = objectData.i;
				var j:Number = objectData.j;
				var k:Number = objectData.k;
				var l:Number = objectData.l;
				var det:Number = 1/(-c*f*i + b*g*i + c*e*j - a*g*j - b*e*k + a*f*k);
				objectData.a = (-g*j + f*k)*det;
				objectData.b = (c*j - b*k)*det;
				objectData.c = (-c*f + b*g)*det;
				objectData.d = (d*g*j - c*h*j - d*f*k + b*h*k + c*f*l - b*g*l)*det;
				objectData.e = (g*i - e*k)*det;
				objectData.f = (-c*i + a*k)*det;
				objectData.g = (c*e - a*g)*det;
				objectData.h = (c*h*i - d*g*i + d*e*k - a*h*k - c*e*l + a*g*l)*det;
				objectData.i = (-f*i + e*j)*det;
				objectData.j = (b*i - a*j)*det;
				objectData.k = (-b*e + a*f)*det;
				objectData.l = (d*f*i - b*h*i - d*e*j + a*h*j + b*e*l - a*f*l)*det;
				if (animationData.pivot != null) {
					objectData.d -= animationData.pivot.x;
					objectData.h -= animationData.pivot.y;
					objectData.l -= animationData.pivot.z;
				}
				correct = true;
			}
			// Создание и корректировка вершин
			var uv:Boolean = objectData.uvs != null && objectData.uvs.length > 0;
			for (n = 0, m = 0; n < objectData.vertices.length;) {
				vertex = new Vertex();
				if (correct) {
					var x:Number = objectData.vertices[n++];
					var y:Number = objectData.vertices[n++];
					var z:Number = objectData.vertices[n++];
					vertex.x = objectData.a*x + objectData.b*y + objectData.c*z + objectData.d;
					vertex.y = objectData.e*x + objectData.f*y + objectData.g*z + objectData.h;
					vertex.z = objectData.i*x + objectData.j*y + objectData.k*z + objectData.l;
				} else {
					vertex.x = objectData.vertices[n++];
					vertex.y = objectData.vertices[n++];
					vertex.z = objectData.vertices[n++];
				}
				vertex.x *= scale;
				vertex.y *= scale;
				vertex.z *= scale;
				if (uv) {
					vertex.u = objectData.uvs[m++];
					vertex.v = 1 - objectData.uvs[m++];
				}
				vertex.transformID = -1;
				vertices[numVertices++] = vertex;
				vertex.next = mesh.vertexList;
				mesh.vertexList = vertex;
			}
			// Создание граней
			var last:Face;
			for (n = 0; n < objectData.faces.length;) {
				face = new Face();
				face.wrapper = new Wrapper();
				face.wrapper.next = new Wrapper();
				face.wrapper.next.next = new Wrapper();
				face.wrapper.vertex = vertices[objectData.faces[n++]];
				face.wrapper.next.vertex = vertices[objectData.faces[n++]];
				face.wrapper.next.next.vertex = vertices[objectData.faces[n++]];
				faces[numFaces++] = face;
				if (last != null) {
					last.next = face;
				} else {
					mesh.faceList = face;
				}
				last = face;
			}
			// Назначение материалов
			if (objectData.surfaces != null) {
				for (var key:String in objectData.surfaces) {
					var surface:Vector.<int> = objectData.surfaces[key];
					var materialData:MaterialData = materialDatas[key];
					var material:Material = materialData.material;
					for (n = 0; n < surface.length; n++) {
						face = faces[surface[n]];
						face.material = material;
						// Коррекция UV-координат
						if (materialData.matrix != null) {
							for (var w:Wrapper = face.wrapper; w != null; w = w.next) {
								vertex = w.vertex;
								if (vertex.transformID < 0) {
									var u:Number = vertex.u;
									var v:Number = vertex.v;
									vertex.u = materialData.matrix.a*u + materialData.matrix.b*v + materialData.matrix.tx;
									vertex.v = materialData.matrix.c*u + materialData.matrix.d*v + materialData.matrix.ty;
									vertex.transformID = 0;
								}
							}
						}
					}
				}
			}
			// Назначение материала по-умолчанию для граней без поверхностей
			var defaultMaterial:FillMaterial = new FillMaterial(0x7F7F7F);
			defaultMaterial.name = "default";
			for (face = mesh.faceList; face != null; face = face.next) {
				if (face.material == null) {
					face.material = defaultMaterial;
				}
			}
			// Расчёт нормалей
			mesh.calculateNormals(true);
			mesh.calculateBounds();
		}
	
		private function getString(index:int):String {
			data.position = index;
			var charCode:int;
			var res:String = "";
			while ((charCode = data.readByte()) != 0) {
				res += String.fromCharCode(charCode);
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
			if (k >= 1) {
				half = angle/2;
				res.z = -2*Math.atan2(x*Math.sin(half), Math.cos(half));
				res.y = -Math.PI/2;
				res.x = 0;
				return res;
			}
			if (k <= -1) {
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
import alternativa.engine3d.materials.Material;

import flash.geom.Matrix;
import flash.geom.Vector3D;

class MaterialData {
	public var name:String;
	public var color:int;
	public var specular:int;
	public var glossiness:int;
	public var transparency:int;
	public var diffuseMap:MapData;
	public var opacityMap:MapData;
	public var matrix:Matrix;
	public var material:Material;
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
	public var vertices:Vector.<Number>;
	public var uvs:Vector.<Number>;
	public var faces:Vector.<int>;
	public var surfaces:Object;
	public var a:Number;
	public var b:Number;
	public var c:Number;
	public var d:Number;
	public var e:Number;
	public var f:Number;
	public var g:Number;
	public var h:Number;
	public var i:Number;
	public var j:Number;
	public var k:Number;
	public var l:Number;
}

class AnimationData {
	public var objectName:String;
	public var object:Object3D;
	public var parentIndex:int;
	public var pivot:Vector3D;
	public var position:Vector3D;
	public var rotation:Vector3D;
	public var scale:Vector3D;
	public var isInstance:Boolean;
}

class ChunkInfo {
	public var id:int;
	public var size:int;
	public var dataSize:int;
	public var dataPosition:int;
	public var nextChunkPosition:int;
}
