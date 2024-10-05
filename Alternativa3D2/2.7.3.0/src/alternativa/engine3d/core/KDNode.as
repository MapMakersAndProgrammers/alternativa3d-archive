package alternativa.engine3d.core {
	
	public class KDNode	{
		
		public var negative:KDNode;
		public var positive:KDNode;
	
		public var axis:int;
		public var coord:Number;
		public var minCoord:Number;
		public var maxCoord:Number;
	
		public var boundMinX:Number;
		public var boundMinY:Number;
		public var boundMinZ:Number;
		public var boundMaxX:Number;
		public var boundMaxY:Number;
		public var boundMaxZ:Number;
	
		public var objects:Vector.<Object3D>;
		public var objectsLength:int = 0;
		public var occluders:Vector.<Object3D>;
		public var occludersLength:int = 0;
		
	}
}
