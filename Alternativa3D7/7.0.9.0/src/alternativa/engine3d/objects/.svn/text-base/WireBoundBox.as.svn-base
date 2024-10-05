package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;

	import flash.geom.Utils3D;
	
	use namespace alternativa3d;
	
	public class WireBoundBox extends Object3D {
		
		static private const cameraVertices:Vector.<Number> = new Vector.<Number>(24, true);
		static private const projectedVertices:Vector.<Number> = new Vector.<Number>(16, true);
		static private const uvts:Vector.<Number> = new Vector.<Number>(24, true);
		public var thickness:Number = 0;
		public var color:uint = 0xFFFFFF;
		
		/**
		 * @private
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			
			cameraVertices[0] = _boundBox.minX;
			cameraVertices[1] = _boundBox.minY;
			cameraVertices[2] = _boundBox.minZ;
			
			cameraVertices[3] = _boundBox.minX;
			cameraVertices[4] = _boundBox.minY;
			cameraVertices[5] = _boundBox.maxZ;
			
			cameraVertices[6] = _boundBox.minX;
			cameraVertices[7] = _boundBox.maxY;
			cameraVertices[8] = _boundBox.minZ;
			
			cameraVertices[9] = _boundBox.minX;
			cameraVertices[10] = _boundBox.maxY;
			cameraVertices[11] = _boundBox.maxZ;
			
			cameraVertices[12] = _boundBox.maxX;
			cameraVertices[13] = _boundBox.minY;
			cameraVertices[14] = _boundBox.minZ;
			
			cameraVertices[15] = _boundBox.maxX;
			cameraVertices[16] = _boundBox.minY;
			cameraVertices[17] = _boundBox.maxZ;

			cameraVertices[18] = _boundBox.maxX;
			cameraVertices[19] = _boundBox.maxY;
			cameraVertices[20] = _boundBox.minZ;

			cameraVertices[21] = _boundBox.maxX;
			cameraVertices[22] = _boundBox.maxY;
			cameraVertices[23] = _boundBox.maxZ;
			
			object.cameraMatrix.transformVectors(cameraVertices, cameraVertices);
			for (var i:int = 0; i < 8; i++) {
				if (cameraVertices[int(i*3 + 2)] <= 0) return;
			}

			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, object.alpha, object.blendMode, object.colorTransform, object.filters);
			
			// Проецируем точки
			Utils3D.projectVectors(camera.projectionMatrix, cameraVertices, projectedVertices, uvts);
			
			// Отрисовка
			canvas.gfx.lineStyle(thickness, color);
			canvas.gfx.moveTo(projectedVertices[0], projectedVertices[1]);
			canvas.gfx.lineTo(projectedVertices[2], projectedVertices[3]);
			canvas.gfx.lineTo(projectedVertices[6], projectedVertices[7]);
			canvas.gfx.lineTo(projectedVertices[4], projectedVertices[5]);
			canvas.gfx.lineTo(projectedVertices[0], projectedVertices[1]);
			canvas.gfx.moveTo(projectedVertices[8], projectedVertices[9]);
			canvas.gfx.lineTo(projectedVertices[10], projectedVertices[11]);
			canvas.gfx.lineTo(projectedVertices[14], projectedVertices[15]);
			canvas.gfx.lineTo(projectedVertices[12], projectedVertices[13]);
			canvas.gfx.lineTo(projectedVertices[8], projectedVertices[9]);
			canvas.gfx.moveTo(projectedVertices[0], projectedVertices[1]);
			canvas.gfx.lineTo(projectedVertices[8], projectedVertices[9]);
			canvas.gfx.moveTo(projectedVertices[2], projectedVertices[3]);
			canvas.gfx.lineTo(projectedVertices[10], projectedVertices[11]);
			canvas.gfx.moveTo(projectedVertices[4], projectedVertices[5]);
			canvas.gfx.lineTo(projectedVertices[12], projectedVertices[13]);
			canvas.gfx.moveTo(projectedVertices[6], projectedVertices[7]);
			canvas.gfx.lineTo(projectedVertices[14], projectedVertices[15]);
		}
		
	}
}
