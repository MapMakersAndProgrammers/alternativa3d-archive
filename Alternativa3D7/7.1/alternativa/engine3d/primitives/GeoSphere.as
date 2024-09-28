package alternativa.engine3d.primitives {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.objects.Mesh;

	use namespace alternativa3d;
	
	public class GeoSphere extends Mesh {

		public function GeoSphere(radius:Number = 100, segments:uint = 2, reverse:Boolean = false) {

			const sections:uint = 20;

			var i:uint;

			var theta:Number;
			var sin:Number;
			var cos:Number;
			// z расстояние до нижней и верхней крышки полюса  
			var subz:Number = 4.472136E-001*radius;
			// радиус на расстоянии subz 
			var subrad:Number = 2*subz;

			var v:uint = 0;

			var f:uint = sections*segments*segments;
			createEmptyGeometry(f/2 + 2, f);
			
			vertices[v++] = 0;
			vertices[v++] = 0;
			vertices[v++] = radius;
			
			// Создание вершин верхней крышки
			for (i = 0; i < 5; i++) {
				theta = Math.PI*2*i/5;
				sin = Math.sin(theta);
				cos = Math.cos(theta);
				vertices[v++] = subrad*cos;
				vertices[v++] = subrad*sin;
				vertices[v++] = subz;
			}
			// Создание вершин нижней крышки
			for (i = 0; i < 5; i++) {
				theta = Math.PI*((i << 1) + 1)/5;
				sin = Math.sin(theta);
				cos = Math.cos(theta);
				vertices[v++] = subrad*cos;
				vertices[v++] = subrad*sin;
				vertices[v++] = -subz;
			}

			vertices[v++] = 0;
			vertices[v++] = 0;
			vertices[v++] = -radius;
			
			for (i = 1; i < 6; i++) {
				v = interpolate(0, i, segments, v);
			}
			for (i = 1; i < 6; i++) {
				v = interpolate(i, i % 5 + 1, segments, v);
			}
			for (i = 1; i < 6; i++) {
				v = interpolate(i, i + 5, segments, v);
			}
			for (i = 1; i < 6; i++) {
				v = interpolate(i, (i + 3) % 5 + 6, segments, v);
			}
			for (i = 1; i < 6; i++) {
				v = interpolate(i + 5, i % 5 + 6, segments, v);
			}
			for (i = 6; i < 11; i++) {
				v = interpolate(11, i, segments, v);
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					v = interpolate(12 + f*(segments - 1) + i, 12 + (f + 1) % 5*(segments - 1) + i, i + 1, v);
				}
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					v = interpolate(12 + (f + 15)*(segments - 1) + i, 12 + (f + 10)*(segments - 1) + i, i + 1, v);
				}
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					v = interpolate(12 + ((f + 1) % 5 + 15)*(segments - 1) + segments - 2 - i, 12 + (f + 10)*(segments - 1) + segments - 2 - i, i + 1, v);
				}
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					v = interpolate(12 + ((f + 1) % 5 + 25)*(segments - 1) + i, 12 + (f + 25)*(segments - 1) + i, i + 1, v);
				}
			}

			for (i = 0; i < numVertices; i++) {
				var j:uint = i*3;
				uvts[j] = Math.atan2(vertices[j + 1], vertices[j])/(Math.PI*2);
				uvts[j] = 0.5 + (reverse ? -uvts[j] : uvts[j]);
				uvts[j + 1] = 0.5 + Math.asin(vertices[j + 2]/radius)/Math.PI;
				uvs[i << 1] = uvts[j];
				uvs[(i << 1) + 1] = uvts[j + 1];
			}

		    var num:uint = 0;
		    for (f = 0; f <= sections - 1; f++) {
		        for (var row:uint = 0; row <= segments - 1; row++) {
		            for (var column:uint = 0; column <= row; column++) {
		                var a:uint = findVertices(segments, f, row, column);
		                var b:uint = findVertices(segments, f, row + 1, column);
		                var c:uint = findVertices(segments, f, row + 1, column + 1);
		                
		                if (reverse) {
		                	indices[num++] = a;
		                	indices[num++] = c;
		                	indices[num++] = b;
		                } else {
		                	indices[num++] = a;
		                	indices[num++] = b;
		                	indices[num++] = c;
		                }
		                
		                if (column < row) {
		                    var d:uint = findVertices(segments, f, row, column + 1);
		                    if (reverse) {
			                	indices[num++] = a;
			                	indices[num++] = d;
			                	indices[num++] = c;
		                    } else {
			                	indices[num++] = a;
			                	indices[num++] = c;
			                	indices[num++] = d;
		                    }
		                }
		            }
		        }
		    }
		    
		    // Установка границ
		    _boundBox = new BoundBox();
		    _boundBox.setSize(-radius, -radius, -radius, radius, radius, radius);
		}

		private function interpolate(a:uint, b:uint, num:uint, v:uint):uint {
			if (num < 2) {
				return v;
			}
			a *= 3;
			b *= 3;
			var ax:Number = vertices[a];
			var ay:Number = vertices[a + 1];
			var az:Number = vertices[a + 2];
			var bx:Number = vertices[b];
			var by:Number = vertices[b + 1];
			var bz:Number = vertices[b + 2];
			var cos:Number = (ax*bx + ay*by + az*bz)/(ax*ax + ay*ay + az*az);
			cos = (cos < -1) ? -1 : ((cos > 1) ? 1 : cos);
			var theta:Number = Math.acos(cos);
			var sin:Number = Math.sin(theta);
			for (var e:uint = 1; e < num; e++) {
				var theta1:Number = theta*e/num;
				var theta2:Number = theta*(num - e)/num;
				var st1:Number = Math.sin(theta1);
				var st2:Number = Math.sin(theta2);
				vertices[v++] = (ax*st2 + bx*st1)/sin;
				vertices[v++] = (ay*st2 + by*st1)/sin;
				vertices[v++] = (az*st2 + bz*st1)/sin;
			}
			return v;
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
		
	}
}