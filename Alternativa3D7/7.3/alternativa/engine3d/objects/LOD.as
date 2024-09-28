package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	
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
		private function getLODObject(object:Object3D):Object3D {
			//var cameraDistance:Number = object.cameraMatrix.position.length;
			var cameraDistance:Number = object.ml;
			// Поиск ближайшего лода
			var min:Number = Infinity;
			var length:uint = lodObjects.length;
			var lod:Object3D;
			for (var i:int = 0; i < length; i++) {
				var d:Number = Math.abs(cameraDistance - lodDistances[i]);
				if (d < min) {
					min = d;
					lod = lodObjects[i];
				}
			}
			return lod;
		}
	
		/**
		 * @private
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			getLODObject(object).draw(camera, object, parentCanvas);
		}
	
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			return getLODObject(object).getGeometry(camera, object);
		}
	
		override alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			var length:uint = lodObjects.length;
			for (var i:int = 0; i < length; i++) {
				(lodObjects[i] as Object3D).updateBounds(bounds, transformation);
			}
		}
	
		override alternativa3d function cullingInCamera(camera:Camera3D, object:Object3D, culling:int):int {
			object.culling = getLODObject(object).cullingInCamera(camera, object, culling);
			return object.culling;
		}
	
	}
}
