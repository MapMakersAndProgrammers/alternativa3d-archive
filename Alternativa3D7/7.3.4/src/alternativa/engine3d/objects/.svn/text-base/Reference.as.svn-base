package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	
	use namespace alternativa3d;
	
	/**
	 * Объект-ссылка.
	 * Может ссылаться на любой трёхмерный объект, в том числе контейнер с любой вложенностью или Reference.
	 * При отрисовке он отрисовывает вместо себя объект,
	 * на который ссылается, подставляя только свою трансформацию, alpha, blendMode, colorTransform и filters.
	 */
	public class Reference extends Object3D {
	
		/**
		 * Объект, который подставляется при отрисовке вместо себя
		 */
		public var referenceObject:Object3D;
	
		public function Reference(referenceObject:Object3D = null) {
			this.referenceObject = referenceObject;
		}
	
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			referenceObject.draw(camera, object, parentCanvas);
		}
	
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			return referenceObject.getGeometry(camera, object);
		}
	
		override alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			referenceObject.updateBounds(bounds, transformation);
		}
	
		override alternativa3d function cullingInCamera(camera:Camera3D, object:Object3D, culling:int):int {
			object.culling = referenceObject.cullingInCamera(camera, object, culling);
			return object.culling;
		}
	
	}
}
