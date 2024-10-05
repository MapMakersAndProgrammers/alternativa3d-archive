package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;
		
	/**
	 * Объект, имеющий набор объектов с разной детализацией.
	 * При отрисовке, он выбирает в зависимости от расстояния от камеры 
	 * объект с нужной детализацией и отрисовывает его вместо себя.
	 * Это позволяет получить лучший визуальный результат и большую производительность.
	 */
	public class LOD extends Object3D {

		/**
		 * Объекты с разной детализацией 
		 */
		public var lodObjects:Vector.<Object3D>;
		/**
		 * Расстояния до камеры соответствующие объектам с разной детализацией 
		 */
		public var lodDistances:Vector.<Number>;
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var cameraDistance:Number = object.cameraMatrix.position.length;
			
			// Поиск ближайшего лода
			var min:Number = Infinity;
			var length:uint = lodObjects.length;
			var lod:Object3D;
			for (var i:uint = 0; i < length; i++) {
				var d:Number = Math.abs(cameraDistance - lodDistances[i]); 
				if (d < min) {
					min = d;
					lod = lodObjects[i];
				}
			}
			if (camera.debugMode) lod.debug(camera, object, parentCanvas);
			lod.draw(camera, object, parentCanvas);
		}
		
		override public function calculateBoundBox(matrix:Matrix3D = null, boundBox:BoundBox = null):BoundBox {
			return (lodObjects[0] as Object3D).calculateBoundBox(matrix, boundBox);
		}
		
	}
}