package alternativa.engine3d.objects {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	
	import flash.geom.Matrix3D;
	
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
		
		/**
		 * @private
		 */
		override alternativa3d function get canDraw():Boolean {
			return referenceObject.canDraw;
		}

		/**
		 * @private
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			referenceObject.draw(camera, object, parentCanvas);
		}
		
		override public function get boundBox():BoundBox {
			return referenceObject.boundBox;
		}
		
		override public function calculateBoundBox(matrix:Matrix3D = null, boundBox:BoundBox = null):BoundBox {
			return referenceObject.calculateBoundBox(matrix, boundBox);
		}
		
	}
}