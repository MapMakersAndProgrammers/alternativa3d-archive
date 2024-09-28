package alternativa.engine3d.primitives {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.objects.Mesh;

	use namespace alternativa3d;
	
	public class Box extends Mesh {
		
		public function Box(width:Number = 100, length:Number = 100, height:Number = 100, widthSegments:uint = 1, lengthSegments:uint = 1, heightSegments:uint = 1, reverse:Boolean = false) {
			
			var wp:uint = widthSegments + 1;
			var lp:uint = lengthSegments + 1;
			var hp:uint = heightSegments + 1;
			
			createEmptyGeometry((wp*(lp + hp) + lp*hp) << 1, (widthSegments*(lengthSegments + heightSegments) + lengthSegments*heightSegments) << 2);
			
			var wh:Number = width*0.5;
			var lh:Number = length*0.5;
			var hh:Number = height*0.5;
			var wd:Number = 1/widthSegments;
			var ld:Number = 1/lengthSegments;
			var hd:Number = 1/heightSegments;
			var ws:Number = width/widthSegments;
			var ls:Number = length/lengthSegments;
			var hs:Number = height/heightSegments;
			var x:uint;
			var y:uint;
			var z:uint;
			
			var v:uint = 0;
			var u:uint = 0;
			var f:uint = 0;
  			
			// Нижняя грань
			for (x = 0; x < wp; x++) {
				for (y = 0; y < lp; y++) {
					vertices[v] = x*ws - wh;
					uvts[v] = (widthSegments - x)*wd;
					uvs[u++] = uvts[v++];
					vertices[v] = y*ls - lh;
					uvts[v] = (lengthSegments - y)*ld;
					uvs[u++] = uvts[v++];
					vertices[v++] = -hh;
					
					if (x < widthSegments && y < lengthSegments) {
						if (reverse) {
							indices[f++] = (x + 1)*lp + y + 1;
							indices[f++] = x*lp + y + 1;
							indices[f++] = x*lp + y;

							indices[f++] = (x + 1)*lp + y;
							indices[f++] = (x + 1)*lp + y + 1;
							indices[f++] = x*lp + y;
						} else {
							indices[f++] = x*lp + y;
							indices[f++] = (x + 1)*lp + y + 1;
							indices[f++] = (x + 1)*lp + y;
							
							indices[f++] = x*lp + y;
							indices[f++] = x*lp + y + 1;
							indices[f++] = (x + 1)*lp + y + 1;
						}
					}
				}
			}
			var o:uint = wp*lp;

			// Верхняя грань
			for (x = 0; x < wp; x++) {
				for (y = 0; y < lp; y++) {
					vertices[v] = x*ws - wh;
					uvts[v] = x*wd;
					uvs[u++] = uvts[v++];
					vertices[v] = y*ls - lh;
					uvts[v] = (lengthSegments - y)*ld;
					uvs[u++] = uvts[v++];
					vertices[v++] = hh;
					
					if (x < widthSegments && y < lengthSegments) {
						if (reverse) {
							indices[f++] = o + x*lp + y + 1;
							indices[f++] = o + (x + 1)*lp + y + 1;
							indices[f++] = o + x*lp + y;

							indices[f++] = o + (x + 1)*lp + y + 1;
							indices[f++] = o + (x + 1)*lp + y;
							indices[f++] = o + x*lp + y;
						} else {
							indices[f++] = o + x*lp + y;
							indices[f++] = o + (x + 1)*lp + y;
							indices[f++] = o + (x + 1)*lp + y + 1;
							
							indices[f++] = o + x*lp + y;
							indices[f++] = o + (x + 1)*lp + y + 1;
							indices[f++] = o + x*lp + y + 1;
						}
					}
				}
			}
			o += wp*lp;

			// Передняя грань
			for (x = 0; x < wp; x++) {
				for (z = 0; z < hp; z++) {
					vertices[v] = x*ws - wh;
					uvts[v] = x*wd;
					uvs[u++] = uvts[v++];
					vertices[v] = -lh;
					uvts[v] = (heightSegments - z)*hd;
					uvs[u++] = uvts[v++];
					vertices[v++] = z*hs - hh;
					
					if (x < widthSegments && z < heightSegments) {
						if (reverse) {
							indices[f++] = o + x*hp + z + 1;
							indices[f++] = o + (x + 1)*hp + z + 1;
							indices[f++] = o + x*hp + z;

							indices[f++] = o + (x + 1)*hp + z + 1;
							indices[f++] = o + (x + 1)*hp + z;
							indices[f++] = o + x*hp + z;
						} else {
							indices[f++] = o + x*hp + z;
							indices[f++] = o + (x + 1)*hp + z;
							indices[f++] = o + (x + 1)*hp + z + 1;
							
							indices[f++] = o + x*hp + z;
							indices[f++] = o + (x + 1)*hp + z + 1;
							indices[f++] = o + x*hp + z + 1;
						}
					}
				}
			}
			o += wp*hp;

			// Задняя грань
			for (x = 0; x < wp; x++) {
				for (z = 0; z < hp; z++) {
					vertices[v] = x*ws - wh;
					uvts[v] = (widthSegments - x)*wd;
					uvs[u++] = uvts[v++];
					vertices[v] = lh;
					uvts[v] = (heightSegments - z)*hd;
					uvs[u++] = uvts[v++];
					vertices[v++] = z*hs - hh;
					
					if (x < widthSegments && z < heightSegments) {
						if (reverse) {
							indices[f++] = o + (x + 1)*hp + z;
							indices[f++] = o + (x + 1)*hp + z + 1;
							indices[f++] = o + x*hp + z + 1;

							indices[f++] = o + (x + 1)*hp + z;
							indices[f++] = o + x*hp + z + 1;
							indices[f++] = o + x*hp + z;
						} else {
							indices[f++] = o + x*hp + z;
							indices[f++] = o + x*hp + z + 1;
							indices[f++] = o + (x + 1)*hp + z;
							
							indices[f++] = o + x*hp + z + 1;
							indices[f++] = o + (x + 1)*hp + z + 1;
							indices[f++] = o + (x + 1)*hp + z;
						}
					}
				}
			}
			o += wp*hp;

			// Левая грань
			for (y = 0; y < lp; y++) {
				for (z = 0; z < hp; z++) {
					vertices[v] = -wh;
					uvts[v] = (lengthSegments - y)*ld;
					uvs[u++] = uvts[v++];
					vertices[v] = y*ls - lh;
					uvts[v] = (heightSegments - z)*hd;
					uvs[u++] = uvts[v++];
					vertices[v++] = z*hs - hh;
					
					if (y < lengthSegments && z < heightSegments) {
						if (reverse) {
							indices[f++] = o + (y + 1)*hp + z;
							indices[f++] = o + (y + 1)*hp + z + 1;
							indices[f++] = o + y*hp + z + 1;

							indices[f++] = o + (y + 1)*hp + z;
							indices[f++] = o + y*hp + z + 1;
							indices[f++] = o + y*hp + z;
						} else {
							indices[f++] = o + y*hp + z;
							indices[f++] = o + y*hp + z + 1;
							indices[f++] = o + (y + 1)*hp + z;
							
							indices[f++] = o + y*hp + z + 1;
							indices[f++] = o + (y + 1)*hp + z + 1;
							indices[f++] = o + (y + 1)*hp + z;
						}
					}
				}
			}
			o += lp*hp;

			// Правая грань
			for (y = 0; y < lp; y++) {
				for (z = 0; z < hp; z++) {
					vertices[v] = wh;
					uvts[v] = y*ld;
					uvs[u++] = uvts[v++];
					vertices[v] = y*ls - lh;
					uvts[v] = (heightSegments - z)*hd;
					uvs[u++] = uvts[v++];
					vertices[v++] = z*hs - hh;
					
					if (y < lengthSegments && z < heightSegments) {
						if (reverse) {
							indices[f++] = o + y*hp + z + 1;
							indices[f++] = o + (y + 1)*hp + z + 1;
							indices[f++] = o + y*hp + z;

							indices[f++] = o + (y + 1)*hp + z + 1;
							indices[f++] = o + (y + 1)*hp + z;
							indices[f++] = o + y*hp + z;
						} else {
							indices[f++] = o + y*hp + z;
							indices[f++] = o + (y + 1)*hp + z;
							indices[f++] = o + (y + 1)*hp + z + 1;
							
							indices[f++] = o + y*hp + z;
							indices[f++] = o + (y + 1)*hp + z + 1;
							indices[f++] = o + y*hp + z + 1;
						}
					}
				}
			}
			
		    // Установка границ
		    _boundBox = new BoundBox();
		    _boundBox.setSize(-wh, -lh, -hh, wh, lh, hh);
			
		}
		
	}
}