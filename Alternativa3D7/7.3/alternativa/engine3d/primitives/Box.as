package alternativa.engine3d.primitives {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.objects.Mesh;
	
	use namespace alternativa3d;
	
	public class Box extends Mesh {
	
		public function Box(width:Number = 100, length:Number = 100, height:Number = 100, widthSegments:uint = 1, lengthSegments:uint = 1, heightSegments:uint = 1, reverse:Boolean = false) {
	
			var wp:int = widthSegments + 1;
			var lp:int = lengthSegments + 1;
			var hp:int = heightSegments + 1;
	
			var wh:Number = width*0.5;
			var lh:Number = length*0.5;
			var hh:Number = height*0.5;
			var wd:Number = 1/widthSegments;
			var ld:Number = 1/lengthSegments;
			var hd:Number = 1/heightSegments;
			var ws:Number = width/widthSegments;
			var ls:Number = length/lengthSegments;
			var hs:Number = height/heightSegments;
			var x:int;
			var y:int;
			var z:int;
	
			var v:int = 0;
	
			var vertices:Vector.<Vertex> = new Vector.<Vertex>();
			var face:Face;
	
			// Нижняя грань
			for (x = 0; x < wp; x++) {
				for (y = 0; y < lp; y++) {
					vertices[v++] = addVertex(x*ws - wh, y*ls - lh, -hh, (widthSegments - x)*wd, (lengthSegments - y)*ld);
				}
			}
			for (x = 0; x < wp; x++) {
				for (y = 0; y < lp; y++) {
					if (x < widthSegments && y < lengthSegments) {
						if (reverse) {
							face = addQuadFace(vertices[(x + 1)*lp + y + 1], vertices[x*lp + y + 1], vertices[x*lp + y], vertices[(x + 1)*lp + y]);
							face.normalZ = 1;
							face.offset = -hh;
						} else {
							face = addQuadFace(vertices[(x + 1)*lp + y + 1], vertices[(x + 1)*lp + y], vertices[x*lp + y], vertices[x*lp + y + 1]);
							face.normalZ = -1;
							face.offset = hh;
						}
						face.normalX = 0;
						face.normalY = 0;
					}
				}
			}
			var o:uint = wp*lp;
	
			// Верхняя грань
			for (x = 0; x < wp; x++) {
				for (y = 0; y < lp; y++) {
					vertices[v++] = addVertex(x*ws - wh, y*ls - lh, hh, x*wd, (lengthSegments - y)*ld);
				}
			}
			for (x = 0; x < wp; x++) {
				for (y = 0; y < lp; y++) {
					if (x < widthSegments && y < lengthSegments) {
						if (reverse) {
							face = addQuadFace(vertices[o + x*lp + y + 1], vertices[o + (x + 1)*lp + y + 1], vertices[o + (x + 1)*lp + y], vertices[o + x*lp + y]);
							face.normalZ = -1;
							face.offset = -hh;
						} else {
							face = addQuadFace(vertices[o + x*lp + y], vertices[o + (x + 1)*lp + y], vertices[o + (x + 1)*lp + y + 1], vertices[o + x*lp + y + 1]);
							face.normalZ = 1;
							face.offset = hh;
						}
						face.normalX = 0;
						face.normalY = 0;
					}
				}
			}
			o += wp*lp;
	
			// Передняя грань
			for (x = 0; x < wp; x++) {
				for (z = 0; z < hp; z++) {
					vertices[v++] = addVertex(x*ws - wh, -lh, z*hs - hh, x*wd, (heightSegments - z)*hd);
				}
			}
			for (x = 0; x < wp; x++) {
				for (z = 0; z < hp; z++) {
					if (x < widthSegments && z < heightSegments) {
						if (reverse) {
							face = addQuadFace(vertices[o + x*hp + z + 1], vertices[o + (x + 1)*hp + z + 1], vertices[o + (x + 1)*hp + z], vertices[o + x*hp + z]);
							face.normalY = 1;
							face.offset = -lh;
						} else {
							face = addQuadFace(vertices[o + x*hp + z], vertices[o + (x + 1)*hp + z], vertices[o + (x + 1)*hp + z + 1], vertices[o + x*hp + z + 1]);
							face.normalY = -1;
							face.offset = lh;
						}
						face.normalX = 0;
						face.normalZ = 0;
					}
				}
			}
			o += wp*hp;
	
			// Задняя грань
			for (x = 0; x < wp; x++) {
				for (z = 0; z < hp; z++) {
					vertices[v++] = addVertex(x*ws - wh, lh, z*hs - hh, (widthSegments - x)*wd, (heightSegments - z)*hd);
				}
			}
			for (x = 0; x < wp; x++) {
				for (z = 0; z < hp; z++) {
					if (x < widthSegments && z < heightSegments) {
						if (reverse) {
							face = addQuadFace(vertices[o + (x + 1)*hp + z], vertices[o + (x + 1)*hp + z + 1], vertices[o + x*hp + z + 1], vertices[o + x*hp + z]);
							face.normalY = -1;
							face.offset = -lh;
						} else {
							face = addQuadFace(vertices[o + x*hp + z], vertices[o + x*hp + z + 1], vertices[o + (x + 1)*hp + z + 1], vertices[o + (x + 1)*hp + z]);
							face.normalY = 1;
							face.offset = lh;
						}
						face.normalX = 0;
						face.normalZ = 0;
					}
				}
			}
			o += wp*hp;
	
			// Левая грань
			for (y = 0; y < lp; y++) {
				for (z = 0; z < hp; z++) {
					vertices[v++] = addVertex(-wh, y*ls - lh, z*hs - hh, (lengthSegments - y)*ld, (heightSegments - z)*hd);
				}
			}
			for (y = 0; y < lp; y++) {
				for (z = 0; z < hp; z++) {
					if (y < lengthSegments && z < heightSegments) {
						if (reverse) {
							face = addQuadFace(vertices[o + (y + 1)*hp + z], vertices[o + (y + 1)*hp + z + 1], vertices[o + y*hp + z + 1], vertices[o + y*hp + z]);
							face.normalX = 1;
							face.offset = -wh;
						} else {
							face = addQuadFace(vertices[o + y*hp + z], vertices[o + y*hp + z + 1], vertices[o + (y + 1)*hp + z + 1], vertices[o + (y + 1)*hp + z]);
							face.normalX = -1;
							face.offset = wh;
						}
						face.normalY = 0;
						face.normalZ = 0;
					}
				}
			}
			o += lp*hp;
	
			// Правая грань
			for (y = 0; y < lp; y++) {
				for (z = 0; z < hp; z++) {
					vertices[v++] = addVertex(wh, y*ls - lh, z*hs - hh, y*ld, (heightSegments - z)*hd);
				}
			}
			for (y = 0; y < lp; y++) {
				for (z = 0; z < hp; z++) {
					if (y < lengthSegments && z < heightSegments) {
						if (reverse) {
							face = addQuadFace(vertices[o + y*hp + z + 1], vertices[o + (y + 1)*hp + z + 1], vertices[o + (y + 1)*hp + z], vertices[o + y*hp + z]);
							face.normalX = -1;
							face.offset = -wh;
						} else {
							face = addQuadFace(vertices[o + y*hp + z], vertices[o + (y + 1)*hp + z], vertices[o + (y + 1)*hp + z + 1], vertices[o + y*hp + z + 1]);
							face.normalX = 1;
							face.offset = wh;
						}
						face.normalY = 0;
						face.normalZ = 0;
					}
				}
			}
	
			// Установка границ
			boundMinX = -wh;
			boundMinY = -lh;
			boundMinZ = -hh;
			boundMaxX = wh;
			boundMaxY = lh;
			boundMaxZ = hh;
		}
	
	}
}
