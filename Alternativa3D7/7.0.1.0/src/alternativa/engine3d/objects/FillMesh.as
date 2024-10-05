package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	
	use namespace alternativa3d;
	
	/**
	 * 
	 */
	public class FillMesh extends Mesh {
		
		public var fillColor:uint;
		public var wireColor:uint;
		public var wireThickness:int = -1;
		
		/**
		 * 
		 */
		public function FillMesh() {
			super();
		}
		
		/**
		 * @param indices
		 * @param int
		 * @param camera
		 * @param object
		 * @param canvas
		 */
		override protected function drawGraphics(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Подрезка
			resultIndices.length = resultIndicesLength;
			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, object.alpha, object.blendMode, object.colorTransform, object.filters);
			// Отрисовка
			wireThickness == -1 ? canvas.gfx.lineStyle() : canvas.gfx.lineStyle(wireThickness, wireColor);
			canvas.gfx.beginFill(fillColor, alpha);
			canvas.gfx.drawTriangles(projectedVertices, resultIndices, null, "positive");
		}
	
		/**
		 * @private 
		 */
		override alternativa3d function get canDraw():Boolean {
			return numFaces > 0;
		}
		
	}
}