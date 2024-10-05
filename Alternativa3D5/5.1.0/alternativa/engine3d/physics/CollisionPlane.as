package alternativa.engine3d.physics {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.BSPNode;

	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class CollisionPlane {
		public var sourceOffset:Number;
		public var destinationOffset:Number;
		public var infront:Boolean;
		public var node:BSPNode;
	}
}