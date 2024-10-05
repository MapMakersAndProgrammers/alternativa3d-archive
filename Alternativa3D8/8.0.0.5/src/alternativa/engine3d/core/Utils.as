package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.View;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Texture3D;
	import flash.display3D.TextureCube3D;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	public class Utils {
		
		static public var temporaryBitmapData:BitmapData;
		
		static private const filter:ConvolutionFilter = new ConvolutionFilter(2, 2, [1, 1, 1, 1], 4, 0, false, true);
		static private const matrix:Matrix = new Matrix(0.5, 0, 0, 0.5);
		static private const rect:Rectangle = new Rectangle();
		static private const point:Point = new Point();
		
		static public function uploadMap(view:View, map:BitmapData, dispose:Boolean = false):Texture3D {
			var texture3d:Texture3D = view.context3d.createTexture(map.width, map.height, Context3DTextureFormat.BGRA, false);
			filter.preserveAlpha = !map.transparent;
			var bmp:BitmapData = (temporaryBitmapData != null) ? temporaryBitmapData : new BitmapData(map.width, map.height, map.transparent);
			var level:int = 0;
			texture3d.upload(map, level++);
			var current:BitmapData = map;
			rect.width = map.width;
			rect.height = map.height;
			while (rect.width % 2 == 0 || rect.height % 2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != map) current.dispose();
				current = new BitmapData(rect.width, rect.height, map.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				texture3d.upload(current, level++);
			}
			if (temporaryBitmapData == null) bmp.dispose();
			if (dispose) map.dispose();
			return texture3d;
		}
		
		static public function uploadCubeMap(view:View, left:BitmapData, right:BitmapData, back:BitmapData, front:BitmapData, bottom:BitmapData, top:BitmapData, dispose:Boolean = false):TextureCube3D {
			var textureCube3D:TextureCube3D = view.context3d.createTextureCube(left.width, Context3DTextureFormat.BGRA, false);
			
			filter.preserveAlpha = !left.transparent;
			var bmp:BitmapData = (temporaryBitmapData != null) ? temporaryBitmapData : new BitmapData(left.width, left.height, left.transparent);
			
			var level:int = 0;
			textureCube3D.upload(left, 1, level++);
			var current:BitmapData = left;
			rect.width = left.width;
			rect.height = left.height;
			while (rect.width % 2 == 0 || rect.height % 2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != left) current.dispose();
				current = new BitmapData(rect.width, rect.height, left.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				textureCube3D.upload(current, 1, level++);
			}

			level = 0;
			textureCube3D.upload(right, 0, level++);
			current = right;
			rect.width = right.width;
			rect.height = right.height;
			while (rect.width % 2 == 0 || rect.height % 2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != right) current.dispose();
				current = new BitmapData(rect.width, rect.height, right.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				textureCube3D.upload(current, 0, level++);
			}
			
			level = 0;
			textureCube3D.upload(back, 3, level++);
			current = back;
			rect.width = back.width;
			rect.height = back.height;
			while (rect.width % 2 == 0 || rect.height % 2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != back) current.dispose();
				current = new BitmapData(rect.width, rect.height, back.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				textureCube3D.upload(current, 3, level++);
			}
			
			level = 0;
			textureCube3D.upload(front, 2, level++);
			current = front;
			rect.width = front.width;
			rect.height = front.height;
			while (rect.width % 2 == 0 || rect.height % 2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != front) current.dispose();
				current = new BitmapData(rect.width, rect.height, front.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				textureCube3D.upload(current, 2, level++);
			}
			
			level = 0;
			textureCube3D.upload(bottom, 5, level++);
			current = bottom;
			rect.width = bottom.width;
			rect.height = bottom.height;
			while (rect.width % 2 == 0 || rect.height % 2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != bottom) current.dispose();
				current = new BitmapData(rect.width, rect.height, bottom.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				textureCube3D.upload(current, 5, level++);
			}
			
			level = 0;
			textureCube3D.upload(top, 4, level++);
			current = top;
			rect.width = top.width;
			rect.height = top.height;
			while (rect.width % 2 == 0 || rect.height % 2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != top) current.dispose();
				current = new BitmapData(rect.width, rect.height, top.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				textureCube3D.upload(current, 4, level++);
			}
			
			if (temporaryBitmapData == null) bmp.dispose();
			if (dispose) {
				left.dispose();
				right.dispose();
				back.dispose();
				front.dispose();
				bottom.dispose();
				top.dispose();
			}
			return textureCube3D;
		}
		
		static public function uploadGeometry(view:View, geometry:Geometry, dispose:Boolean = false):void {
			geometry.update(view.context3d);
			if (dispose) {
				geometry._vertices = null;
				geometry._faces = null;
				geometry.uvChannels = null;
			}
		}
		
		static public function calculateVertexNormals(geometry:Geometry, weld:Boolean = false):void {
			var vertex:Vertex;
			var face:Face;
			var normal:Vector3D;
			var nx:Number;
			var ny:Number;
			var nz:Number;
			var len:Number;
			if (weld) {
				// Заполнение массива вершин
				var verts:Vector.<Vertex> = new Vector.<Vertex>();
				var vertsLength:int = 0;
				for each (vertex in geometry._vertices) {
					verts[vertsLength] = vertex;
					vertsLength++;
				}
				// Группировка
				geometry.group(verts, 0, vertsLength, 0, 0.001, 100, new Vector.<int>());
				// Расчёт нормалей объединённых вершин
				for each (face in geometry.faces) {
					normal = face.normal;
					for each (vertex in face.vertices) {
						if (vertex.value != null) vertex = vertex.value;
						if (vertex.attributes == null) {
							vertex.attributes = Vector.<Number>([normal.x, normal.y, normal.z]);
						} else {
							vertex.attributes[0] += normal.x;
							vertex.attributes[1] += normal.y;
							vertex.attributes[2] += normal.z;
						}
					}
				}
				// Нормализация
				for each (vertex in geometry.vertices) {
					if (vertex.value == null && vertex.attributes != null) {
						nx = vertex.attributes[0];
						ny = vertex.attributes[1];
						nz = vertex.attributes[2];
						len = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
						vertex.attributes[0] = nx*len;
						vertex.attributes[1] = ny*len;
						vertex.attributes[2] = nz*len;
						vertex._jointsWeights = null;
						vertex._jointsIndices = null;
					}
				}
				// Установка нормалей и сброс ремапа
				for each (vertex in geometry.vertices) {
					if (vertex.value != null) {
						vertex.attributes = vertex.value.attributes;
						vertex.value = null;
					}
				}
			} else {
				for each (face in geometry.faces) {
					normal = face.normal;
					for each (vertex in face.vertices) {
						if (vertex.attributes == null) {
							vertex.attributes = Vector.<Number>([normal.x, normal.y, normal.z]);
						} else {
							vertex.attributes[0] += normal.x;
							vertex.attributes[1] += normal.y;
							vertex.attributes[2] += normal.z;
						}
					}
				}
				for each (vertex in geometry.vertices) {
					if (vertex.attributes != null) {
						nx = vertex.attributes[0];
						ny = vertex.attributes[1];
						nz = vertex.attributes[2];
						len = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
						vertex.attributes[0] = nx*len;
						vertex.attributes[1] = ny*len;
						vertex.attributes[2] = nz*len;
						vertex._jointsWeights = null;
						vertex._jointsIndices = null;
					}
				}
			}
		}
		
	}
}
