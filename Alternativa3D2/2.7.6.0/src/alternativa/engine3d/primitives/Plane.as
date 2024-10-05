package alternativa.engine3d.primitives {

	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.geom.Point;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Wrapper;
	import flash.utils.Dictionary;
	import alternativa.engine3d.materials.Material;

	use namespace alternativa3d;
	
	/**
	 * Плоскость.
	 */
	public class Plane extends Mesh {

		/**
		 * Создание новой плоскости.
		 * @param width Ширина. Размерность по оси Х. Не может быть меньше нуля.
		 * @param length Длина. Размерность по оси Y. Не может быть меньше нуля.
		 * @param widthSegments Количество сегментов по ширине.
		 * @param lengthSegments Количество сегментов по длине .
		 * @param twoSided Если значении параметра равно <code>true</code>, то формируется двусторонняя плоскость.
		 * @param reverse Флаг инвертирования нормалей.
		 * @param triangulate Флаг триангуляции. Если указано значение <code>true</code>, четырехугольники в плоскости будут триангулированы. 
		 * @param bottom Материал для нижней стороны.
		 * @param top Материал для верхней стороны.
		 */
		public function Plane(width:Number = 100, length:Number = 100, widthSegments:uint = 1, lengthSegments:uint = 1, twoSided:Boolean = true, reverse:Boolean = false, triangulate:Boolean = false, bottom:Material = null, top:Material = null) {
			if (widthSegments <= 0 || lengthSegments <= 0) return;
			var x:int;
			var y:int;
			var z:int;
			var wp:int = widthSegments + 1;
			var lp:int = lengthSegments + 1;
			var wh:Number = width*0.5;
			var lh:Number = length*0.5;
			var wd:Number = 1/widthSegments;
			var ld:Number = 1/lengthSegments;
			var ws:Number = width/widthSegments;
			var ls:Number = length/lengthSegments;
			var vertices:Vector.<Vertex> = new Vector.<Vertex>();
			var verticesLength:int = 0;
			// Верхняя грань
			for (x = 0; x < wp; x++) {
				for (y = 0; y < lp; y++) {
					vertices[verticesLength++] = createVertex(x*ws - wh, y*ls - lh, 0, x*wd, (lengthSegments - y)*ld);
				}
			}
			for (x = 0; x < wp; x++) {
				for (y = 0; y < lp; y++) {
					if (x < widthSegments && y < lengthSegments) {
						createFace(vertices[x*lp + y], vertices[(x + 1)*lp + y], vertices[(x + 1)*lp + y + 1], vertices[x*lp + y + 1], 0, 0, 1, 0, reverse, triangulate, top);
					}
				}
			}
			if (twoSided) {
				verticesLength = 0;
				// Нижняя грань
				for (x = 0; x < wp; x++) {
					for (y = 0; y < lp; y++) {
						vertices[verticesLength++] = createVertex(x*ws - wh, y*ls - lh, 0, (widthSegments - x)*wd, (lengthSegments - y)*ld);
					}
				}
				for (x = 0; x < wp; x++) {
					for (y = 0; y < lp; y++) {
						if (x < widthSegments && y < lengthSegments) {
							createFace(vertices[(x + 1)*lp + y + 1], vertices[(x + 1)*lp + y], vertices[x*lp + y], vertices[x*lp + y + 1], 0, 0, -1, 0, reverse, triangulate, bottom);
						}
					}
				}
			}
			// Установка границ
			boundMinX = -wh;
			boundMinY = -lh;
			boundMinZ = 0;
			boundMaxX = wh;
			boundMaxY = lh;
			boundMaxZ = 0;
		}
		
		private function createVertex(x:Number, y:Number, z:Number, u:Number, v:Number):Vertex {
			var vertex:Vertex = new Vertex();
			vertex.x = x;
			vertex.y = y;
			vertex.z = z;
			vertex.u = u;
			vertex.v = v;
			vertex.next = vertexList;
			vertexList = vertex;
			return vertex;
		}
		
		private function createFace(a:Vertex, b:Vertex, c:Vertex, d:Vertex, nx:Number, ny:Number, nz:Number, no:Number, reverse:Boolean, triangulate:Boolean, material:Material):void {
			var v:Vertex;
			var face:Face;
			if (reverse) {
				nx = -nx;
				ny = -ny;
				nz = -nz;
				no = -no;
				v = a;
				a = d;
				d = v;
				v = b;
				b = c;
				c = v;
			}
			if (triangulate) {
				face = new Face();
				face.material = material;
				face.wrapper = new Wrapper();
				face.wrapper.vertex = a;
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = b;
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = c;
				face.normalX = nx;
				face.normalY = ny;
				face.normalZ = nz;
				face.offset = no;
				face.next = faceList;
				faceList = face;
				face = new Face();
				face.material = material;
				face.wrapper = new Wrapper();
				face.wrapper.vertex = a;
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = c;
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = d;
				face.normalX = nx;
				face.normalY = ny;
				face.normalZ = nz;
				face.offset = no;
				face.next = faceList;
				faceList = face;
			} else {
				face = new Face();
				face.material = material;
				face.wrapper = new Wrapper();
				face.wrapper.vertex = a;
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = b;
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = c;
				face.wrapper.next.next.next = new Wrapper();
				face.wrapper.next.next.next.vertex = d;
				face.normalX = nx;
				face.normalY = ny;
				face.normalZ = nz;
				face.offset = no;
				face.next = faceList;
				faceList = face;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var plane:Plane = new Plane();
			plane.cloneBaseProperties(this);
			plane.clipping = clipping;
			plane.sorting = sorting;
			plane.threshold = threshold;
			// Клонирование вершин
			var vertex:Vertex;
			var lastVertex:Vertex;
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				var newVertex:Vertex = new Vertex();
				newVertex.x = vertex.x;
				newVertex.y = vertex.y;
				newVertex.z = vertex.z;
				newVertex.u = vertex.u;
				newVertex.v = vertex.v;
				vertex.value = newVertex;
				if (lastVertex != null) {
					lastVertex.next = newVertex;
				} else {
					plane.vertexList = newVertex;
				}
				lastVertex = newVertex;
			}
			// Клонирование граней
			var lastFace:Face;
			for (var face:Face = faceList; face != null; face = face.next) {
				var newFace:Face = new Face();
				newFace.material = face.material;
				newFace.normalX = face.normalX;
				newFace.normalY = face.normalY;
				newFace.normalZ = face.normalZ;
				newFace.offset = face.offset;
				// Клонирование обёрток
				var lastWrapper:Wrapper = null;
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var newWrapper:Wrapper = new Wrapper();
					newWrapper.vertex = wrapper.vertex.value;
					if (lastWrapper != null) {
						lastWrapper.next = newWrapper;
					} else {
						newFace.wrapper = newWrapper;
					}
					lastWrapper = newWrapper;
				}
				if (lastFace != null) {
					lastFace.next = newFace;
				} else {
					plane.faceList = newFace;
				}
				lastFace = newFace;
			}
			// Сброс после ремапа
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
			return plane;
		}
		
	}
}
