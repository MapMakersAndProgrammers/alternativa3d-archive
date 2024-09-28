package alternativa.engine3d.objects {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	
	import flash.geom.Utils3D;
	
	use namespace alternativa3d;
	
	public class WireQuad extends Object3D {
		
		public var vertices:Vector.<Number>;
		static private const cameraVertices:Vector.<Number> = new Vector.<Number>(12, true);
		static private const projectedVertices:Vector.<Number> = new Vector.<Number>(8, true);
		static private const uvts:Vector.<Number> = new Vector.<Number>(12, true);
		public var thickness:Number = 0;
		public var color:uint = 0xFFFFFF;
		
		/**
		 * @private
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			object.cameraMatrix.transformVectors(vertices, cameraVertices);
			for (var i:int = 0; i < 4; i++) {
				if (cameraVertices[(i*3 + 2)] <= 0) return;
			}

			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, object.alpha, object.blendMode, object.colorTransform, object.filters);

			// Проецируем точки
			Utils3D.projectVectors(camera.projectionMatrix, cameraVertices, projectedVertices, uvts);
			
			// Отрисовка
			canvas.gfx.lineStyle(thickness, color);
			canvas.gfx.moveTo(projectedVertices[0], projectedVertices[1]);
			canvas.gfx.lineTo(projectedVertices[2], projectedVertices[3]);
			canvas.gfx.lineTo(projectedVertices[4], projectedVertices[5]);
			canvas.gfx.lineTo(projectedVertices[6], projectedVertices[7]);
			canvas.gfx.lineTo(projectedVertices[0], projectedVertices[1]);
		}
		
	}
}