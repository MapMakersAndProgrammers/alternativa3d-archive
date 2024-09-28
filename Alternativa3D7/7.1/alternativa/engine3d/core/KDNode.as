package alternativa.engine3d.core {
	
	import __AS3__.vec.Vector;

	public final class KDNode {
	
		public var axis:int; // 0 - x, 1 - y, 2 - z
		public var coord:Number;
		public var minCoord:Number;
		public var maxCoord:Number;

		public var positive:KDNode;
		public var negative:KDNode;

		public var boundBox:BoundBox;
	
		public var objects:Vector.<Object3D>;
		public var bounds:Vector.<BoundBox>;
		
		public var numObjects:int = 0;
		public var numNonOccluders:int = 0;
	}
}
