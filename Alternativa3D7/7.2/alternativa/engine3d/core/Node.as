package alternativa.engine3d.core {
	
	import __AS3__.vec.Vector;

	public final class Node {
	
		public var positive:Node;
		public var negative:Node;

		public var normalX:Number;
		public var normalY:Number;
		public var normalZ:Number;

		public var offset:Number;
		public var offsetMin:Number;
		public var offsetMax:Number;
		
		public var boundBox:BoundBox;
	
		public var objects:Vector.<Object3D>;
		public var bounds:Vector.<BoundBox>;
		
		public var numObjects:int = 0;
		public var numNonOccluders:int = 0;
		
	}
}
