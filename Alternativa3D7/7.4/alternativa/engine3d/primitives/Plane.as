package alternativa.engine3d.primitives {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.objects.Mesh;

	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class Plane extends Mesh {
	
		/**
		 *
		 * @param width
		 * @param length
		 * @param widthSegments
		 * @param lengthSegments
		 */
		public function Plane(width:Number = 100, length:Number = 100, widthSegments:uint = 1, lengthSegments:uint = 1) {
			/*
			 var wp:uint = widthSegments + 1;
			 var lp:uint = lengthSegments + 1;
	
			 createEmptyGeometry(wp*lp, (widthSegments*lengthSegments) << 2);
	
			 var wh:Number = width*0.5;
			 var lh:Number = length*0.5;
			 var wd:Number = 1/widthSegments;
			 var ld:Number = 1/lengthSegments;
			 var ws:Number = width/widthSegments;
			 var ls:Number = length/lengthSegments;
			 var x:uint;
			 var y:uint;
			 var z:uint;
	
			 var v:uint = 0;
			 var f:uint = 0;
	
			 // Верхняя грань
			 for (x = 0; x < wp; x++) {
			 for (y = 0; y < lp; y++) {
			 vertices[v] = x*ws - wh;
			 uvts[v++] = x*wd;
			 vertices[v] = y*ls - lh;
			 uvts[v++] = (lengthSegments - y)*ld;
			 vertices[v++] = 0;
	
			 if (x < widthSegments && y < lengthSegments) {
			 indices[f++] = x*lp + y;
			 indices[f++] = (x + 1)*lp + y;
			 indices[f++] = (x + 1)*lp + y + 1;
	
			 indices[f++] = x*lp + y;
			 indices[f++] = (x + 1)*lp + y + 1;
			 indices[f++] = x*lp + y + 1;
			 }
			 }
			 }
			 // Установка границ
			 _boundBox = new BoundBox();
			 _boundBox.setSize(-wh, -lh, 0, wh, lh, 0);
			 */
		}
	
	}
}
