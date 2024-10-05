package alternativa.engine3d.primitives {

	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.Material;

	use namespace alternativa3d;

	/**
	 * Сфера.
	 */
	public class Sphere extends Mesh {

		/**
		 * Создание новой сферы.
		 * @param radius Радиус сферы. Не может быть меньше нуля.
		 * @param radialSegments Количество сегментов по экватору сферы.
		 * @param heightSegments Количество сегментов по высоте.
		 * @param reverse Флаг инвертирования нормалей. При параметре установленном в <code>true</code> нормали направлены внутрь сферы.
		 * @param material Материал.
		 */
		public function Sphere(radius:Number = 100, radialSegments:uint = 8, heightSegments:uint = 8, reverse:Boolean = false, material:Material = null) {
			if (radialSegments < 3 || heightSegments < 2) return;
			radius = (radius < 0) ? 0 : radius;
			var map:Object = new Object();
			var radialAngle:Number = Math.PI*2/radialSegments;
			var heightAngle:Number = Math.PI*2/(heightSegments << 1);
			var radial:uint;
			var segment:uint;
			// Создание вершин 
			for (segment = 0; segment <= heightSegments; segment++) {
				var currentHeightAngle:Number = heightAngle*segment;
				var segmentRadius:Number = Math.sin(currentHeightAngle)*radius;
				var segmentZ:Number = Math.cos(currentHeightAngle)*radius;
				for (radial = 0; radial <= radialSegments; radial++) {
					var currentRadialAngle:Number = radialAngle*radial;
					createVertex(-Math.sin(currentRadialAngle)*segmentRadius, Math.cos(currentRadialAngle)*segmentRadius, segmentZ, radial/radialSegments, segment/heightSegments, radial + "_" + segment, map);
				}
			}
			// Создание граней
			var prevRadial:uint = 0;
			var a:Vertex; 
			var b:Vertex; 
			var c:Vertex; 
			for (radial = 1; radial <= radialSegments; radial++) {
				for (segment = 0; segment < heightSegments; segment++) {
					if (segment < heightSegments - 1) {
						a = map[prevRadial + "_" + segment];
						b = map[prevRadial + "_" + (segment + 1)];
						c = map[radial + "_" + (segment + 1)];
						if (reverse) {
							createFace(a, c, b, material);
						} else {
							createFace(a, b, c, material);
						}
					}
					if (segment > 0) {
						a = map[radial + "_" + (segment + 1)];
						b = map[radial + "_" + segment];
						c = map[prevRadial + "_" + segment];
						if (reverse) {
							createFace(a, c, b, material);
						} else {
							createFace(a, b, c, material);
						}
					}
				}
				prevRadial = radial;
			}
			calculateNormals(true);
			// Установка границ
			boundMinX = -radius;
			boundMinY = -radius;
			boundMinZ = -radius;
			boundMaxX = radius;
			boundMaxY = radius;
			boundMaxZ = radius;
		}
		
		private function createVertex(x:Number, y:Number, z:Number, u:Number, v:Number, id:String, map:Object):Vertex {
			var vertex:Vertex = new Vertex();
			vertex.x = x;
			vertex.y = y;
			vertex.z = z;
			vertex.u = u;
			vertex.v = v;
			vertex.next = vertexList;
			vertexList = vertex;
			map[id] = vertex;
			return vertex;
		}
		
		private function createFace(a:Vertex, b:Vertex, c:Vertex, material:Material):void {
			var face:Face = new Face();
			face.material = material;
			face.wrapper = new Wrapper();
			face.wrapper.vertex = a;
			face.wrapper.next = new Wrapper();
			face.wrapper.next.vertex = b;
			face.wrapper.next.next = new Wrapper();
			face.wrapper.next.next.vertex = c;
			face.next = faceList;
			faceList = face;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var sphere:Sphere = new Sphere();
			sphere.cloneBaseProperties(this);
			sphere.clipping = clipping;
			sphere.sorting = sorting;
			sphere.threshold = threshold;
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
					sphere.vertexList = newVertex;
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
					sphere.faceList = newFace;
				}
				lastFace = newFace;
			}
			// Сброс после ремапа
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
			return sphere;
		}
		
	}
}
