package alternativa.engine3d.primitives {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.core.Geometry;

	use namespace alternativa3d;
	
	/**
	 * Геосфера.
	 */	
	public class GeoSphere extends Mesh	{
		
		/**
		 * Создание новой геосферы.
		 * @param radius Радиус геосферы. Не может быть меньше нуля.
		 * @param segments Количество сегментов геосферы.
		 * @param reverse Флаг инверирования нормалей. При значении <code>true</code> нормали направлены внуть геосферы.
		 * @param material Материал. При использовании <code>TextureMaterial</code> нужно установить его свойство <code>repeat</code> в <code>true</code>.
		 */
		public function GeoSphere(radius:Number = 100, segments:uint = 2, reverse:Boolean = false, material:Material = null) {
			if (segments == 0) return;
			geometry = new Geometry();
			this.material = material;
			radius = (radius < 0) ? 0 : radius;
			var sections:uint = 20;
			var deg180:Number = Math.PI;
			var deg360:Number = Math.PI*2;
			var vertices:Vector.<Vertex> = new Vector.<Vertex>();
			var i:uint;
			var f:uint;
			var theta:Number;
			var sin:Number;
			var cos:Number;
			// z расстояние до нижней и верхней крышки полюса  
			var subz:Number = 4.472136E-001*radius;
			// радиус на расстоянии subz 
			var subrad:Number = 2*subz;
			vertices.push(createVertex(0, 0, radius));
			// Создание вершин верхней крышки
			for (i = 0; i < 5; i++) {
				theta = deg360*i/5;
				sin = Math.sin(theta);
				cos = Math.cos(theta);
				vertices.push(createVertex(subrad*cos, subrad*sin, subz));
			}
			// Создание вершин нижней крышки
			for (i = 0; i < 5; i++) {
				theta = deg180*((i << 1) + 1)/5;
				sin = Math.sin(theta);
				cos = Math.cos(theta);
				vertices.push(createVertex(subrad*cos, subrad*sin, -subz));
			}
			vertices.push(createVertex(0, 0, -radius));
			for (i = 1; i < 6; i++) {
				interpolate(0, i, segments, vertices);
			}
			for (i = 1; i < 6; i++) {
				interpolate(i, i % 5 + 1, segments, vertices);
			}
			for (i = 1; i < 6; i++) {
				interpolate(i, i + 5, segments, vertices);
			}
			for (i = 1; i < 6; i++) {
				interpolate(i, (i + 3) % 5 + 6, segments, vertices);
			}
			for (i = 1; i < 6; i++) {
				interpolate(i + 5, i % 5 + 6, segments, vertices);
			}
			for (i = 6; i < 11; i++) {
				interpolate(11, i, segments, vertices);
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					interpolate(12 + f*(segments - 1) + i, 12 + (f + 1) % 5*(segments - 1) + i, i + 1, vertices);
				}
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					interpolate(12 + (f + 15)*(segments - 1) + i, 12 + (f + 10)*(segments - 1) + i, i + 1, vertices);
				}
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					interpolate(12 + ((f + 1) % 5 + 15)*(segments - 1) + segments - 2 - i, 12 + (f + 10)*(segments - 1) + segments - 2 - i, i + 1, vertices);
				}
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					interpolate(12 + ((f + 1) % 5 + 25)*(segments - 1) + i, 12 + (f + 25)*(segments - 1) + i, i + 1, vertices);
				}
			}
			// Создание граней
			for (f = 0; f < sections; f++) {
				for (var row:uint = 0; row < segments; row++) {
					for (var column:uint = 0; column <= row; column++) {
						var aIndex:uint = findVertices(segments, f, row, column);
						var bIndex:uint = findVertices(segments, f, row + 1, column);
						var cIndex:uint = findVertices(segments, f, row + 1, column + 1);
						var a:Vertex = vertices[aIndex];
						var b:Vertex = vertices[bIndex];
						var c:Vertex = vertices[cIndex];
						var au:Number;
						var av:Number;
						var bu:Number;
						var bv:Number;
						var cu:Number;
						var cv:Number;
						if (a.y >= 0 && (a.x < 0) && (b.y < 0 || c.y < 0)) {
							au = Math.atan2(a.y, a.x)/deg360 - 0.5;
						} else {
							au = Math.atan2(a.y, a.x)/deg360 + 0.5;
						}
						av = -Math.asin(a.z/radius)/deg180 + 0.5;
 						if (b.y >= 0 && (b.x < 0) && (a.y < 0 || c.y < 0)) {
							bu = Math.atan2(b.y, b.x)/deg360 - 0.5;
						} else {
							bu = Math.atan2(b.y, b.x)/deg360 + 0.5;
						}
						bv = -Math.asin(b.z/radius)/deg180 + 0.5;
						if (c.y >= 0 && (c.x < 0) && (a.y < 0 || b.y < 0)) {
							cu = Math.atan2(c.y, c.x)/deg360 - 0.5;
						} else {
							cu = Math.atan2(c.y, c.x)/deg360 + 0.5;
						}
						cv = -Math.asin(c.z/radius)/deg180 + 0.5;
    					// полюс
						if (aIndex == 0 || aIndex == 11) {
							au = bu + (cu - bu)*0.5;
						}
						if (bIndex == 0 || bIndex == 11) {
							bu = au + (cu - au)*0.5;
						}
						if (cIndex == 0 || cIndex == 11) {
							cu = au + (bu - au)*0.5;
						}
						// Дублирование
						if (a.offset > 0 && a.u != au) {
							a = createVertex(a.x, a.y, a.z);
						}
						a._u = au;
						a._v = av;
						a.offset = 1;
						if (b.offset > 0 && b.u != bu) {
							b = createVertex(b.x, b.y, b.z);
						}
						b._u = bu;
						b._v = bv;
						b.offset = 1;
						if (c.offset > 0 && c.u != cu) {
							c = createVertex(c.x, c.y, c.z);
						}
						c._u = cu;
						c._v = cv;
						c.offset = 1;
						if (reverse) {
							createFace(a, c, b);
						} else {
							createFace(a, b, c);
						}
 						if (column < row) {
 							bIndex = findVertices(segments, f, row, column + 1);
							b = vertices[bIndex];
							if (a.y >= 0 && (a.x < 0) && (b.y < 0 || c.y < 0)) {
								au = Math.atan2(a.y, a.x)/deg360 - 0.5;
							} else {
								au = Math.atan2(a.y, a.x)/deg360 + 0.5;
							}
							av = -Math.asin(a.z/radius)/deg180 + 0.5;
	 						if (b.y >= 0 && (b.x < 0) && (a.y < 0 || c.y < 0)) {
								bu = Math.atan2(b.y, b.x)/deg360 - 0.5;
							} else {
								bu = Math.atan2(b.y, b.x)/deg360 + 0.5;
							}
							bv = -Math.asin(b.z/radius)/deg180 + 0.5;
							if (c.y >= 0 && (c.x < 0) && (a.y < 0 || b.y < 0)) {
								cu = Math.atan2(c.y, c.x)/deg360 - 0.5;
							} else {
								cu = Math.atan2(c.y, c.x)/deg360 + 0.5;
							}
							cv = -Math.asin(c.z/radius)/deg180 + 0.5;
							if (aIndex == 0 || aIndex == 11)  {
								au = bu + (cu - bu)*0.5;
							}
							if (bIndex == 0 || bIndex == 11) {
								bu = au + (cu - au)*0.5;
							}
							if (cIndex == 0 || cIndex == 11)  {
								cu = au + (bu - au)*0.5;
							}
							// Дублирование
							if (a.offset > 0 && a.u != au) {
								a = createVertex(a.x, a.y, a.z);
							}
							a._u = au;
							a._v = av;
							a.offset = 1;
							if (b.offset > 0 && b.u != bu) {
								b = createVertex(b.x, b.y, b.z);
							}
							b._u = bu;
							b._v = bv;
							b.offset = 1;
							if (c.offset > 0 && c.u != cu) {
								c = createVertex(c.x, c.y, c.z);
							}
							c._u = cu;
							c._v = cv;
							c.offset = 1;
							if (reverse) {
								createFace(a, b, c);
							} else {
								createFace(a, c, b);
							}
						}
 					}
				}
			}
			// Установка границ
			boundMinX = -radius;
			boundMinY = -radius;
			boundMinZ = -radius;
			boundMaxX = radius;
			boundMaxY = radius;
			boundMaxZ = radius;
		}
		
		private function createVertex(x:Number, y:Number, z:Number):Vertex {
			var vertex:Vertex = new Vertex();
			vertex._x = x;
			vertex._y = y;
			vertex._z = z;
			vertex.offset = -1;
			vertex.geometry = geometry;
			geometry._vertices[geometry.vertexIdCounter++] = vertex;
			return vertex;
		}
		
		private function createFace(a:Vertex, b:Vertex, c:Vertex):void {
			var face:Face = new Face();
			face.geometry = geometry;
			face.wrapper = new Wrapper();
			face.wrapper.vertex = a;
			face.wrapper.next = new Wrapper();
			face.wrapper.next.vertex = b;
			face.wrapper.next.next = new Wrapper();
			face.wrapper.next.next.vertex = c;
			geometry._faces[geometry.faceIdCounter++] = face;
		}
		
		private function interpolate(v1:uint, v2:uint, num:uint, vertices:Vector.<Vertex>):void {
			if (num < 2) {
				return;
			}
			var a:Vertex = Vertex(vertices[v1]);
			var b:Vertex = Vertex(vertices[v2]);
			var cos:Number = (a.x*b.x + a.y*b.y + a.z*b.z)/(a.x*a.x + a.y*a.y + a.z*a.z);
			cos = (cos < -1) ? -1 : ((cos > 1) ? 1 : cos);
			var theta:Number = Math.acos(cos);
			var sin:Number = Math.sin(theta);
			for (var e:uint = 1; e < num; e++) {
				var theta1:Number = theta*e/num;
				var theta2:Number = theta*(num - e)/num;
				var st1:Number = Math.sin(theta1);
				var st2:Number = Math.sin(theta2);
				vertices.push(createVertex((a.x*st2 + b.x*st1)/sin, (a.y*st2 + b.y*st1)/sin, (a.z*st2 + b.z*st1)/sin));
			}
		}

		private function findVertices(segments:uint, section:uint, row:uint, column:uint):uint {
			if (row == 0) {
				if (section < 5) {
					return (0);
				}
				if (section > 14) {
					return (11);
				}
				return (section - 4);
			}
			if (row == segments && column == 0) {
				if (section < 5) {
					return (section + 1);
				}
				if (section < 10) {
					return ((section + 4) % 5 + 6);
				}
				if (section < 15) {
					return ((section + 1) % 5 + 1);
				}
				return ((section + 1) % 5 + 6);
			}
			if (row == segments && column == segments) {
				if (section < 5) {
					return ((section + 1) % 5 + 1);
				}
				if (section < 10) {
					return (section + 1);
				}
				if (section < 15) {
					return (section - 9);
				}
				return (section - 9);
			}
			if (row == segments) {
				if (section < 5) {
					return (12 + (5 + section)*(segments - 1) + column - 1);
				}
				if (section < 10) {
					return (12 + (20 + (section + 4) % 5)*(segments - 1) + column - 1);
				}
				if (section < 15) {
					return (12 + (section - 5)*(segments - 1) + segments - 1 - column);
				}
				return (12 + (5 + section)*(segments - 1) + segments - 1 - column);
			}
			if (column == 0) {
				if (section < 5) {
					return (12 + section*(segments - 1) + row - 1);
				}
				if (section < 10) {
					return (12 + (section % 5 + 15)*(segments - 1) + row - 1);
				}
				if (section < 15) {
					return (12 + ((section + 1) % 5 + 15)*(segments - 1) + segments - 1 - row);
				}
				return (12 + ((section + 1) % 5 + 25)*(segments - 1) + row - 1);
			}
			if (column == row) {
				if (section < 5) {
					return (12 + (section + 1) % 5*(segments - 1) + row - 1);
				}
				if (section < 10) {
					return (12 + (section % 5 + 10)*(segments - 1) + row - 1);
				}
				if (section < 15) {
					return (12 + (section % 5 + 10)*(segments - 1) + segments - row - 1);
				}
				return (12 + (section % 5 + 25)*(segments - 1) + row - 1);
			}
			return (12 + 30*(segments - 1) + section*(segments - 1)*(segments - 2)/2 + (row - 1)*(row - 2)/2 + column - 1);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var geoSphere:GeoSphere = new GeoSphere();
			geoSphere.cloneBaseProperties(this);
			geoSphere.geometry = geometry;
			geoSphere.material = material;
			return geoSphere;
		}
		
	}
}
