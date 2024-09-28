package alternativa.engine3d.physics {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Face;
	import alternativa.types.Point3D;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class Collision {
		public var face:Face;
		public var normal:Point3D;
		public var offset:Number;
		public var point:Point3D;
	}
}