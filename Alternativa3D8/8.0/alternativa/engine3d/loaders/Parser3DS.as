package alternativa.engine3d.loaders {
	
	import flash.geom.Matrix;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
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
	
		public function parse(data:ByteArray, texturesBaseURL:String = "", scale:Number = 1):void {
			if (data.bytesAvailable < 6) return;
			this.data = data;
			data.endian = Endian.LITTLE_ENDIAN;
			parse3DSChunk(data.position, data.bytesAvailable);
			data = null;
			//objectDatas = null;
			//animationDatas = null;
			//materialDatas = null;
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
				object.uvs[j++] = 1 - data.readFloat();
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
			object.faces = new Vector.<uint>();
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
	
		public function getVertices(objectName:String):Vector.<Number> {
			return ObjectData(objectDatas[objectName]).vertices;
		}
		
		public function getIndices(objectName:String):Vector.<uint> {
			return ObjectData(objectDatas[objectName]).faces;
		}
		
		public function getUVs(objectName:String):Vector.<Number> {
			return ObjectData(objectDatas[objectName]).uvs;
		}
		
	}
}

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
	public var faces:Vector.<uint>;
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
