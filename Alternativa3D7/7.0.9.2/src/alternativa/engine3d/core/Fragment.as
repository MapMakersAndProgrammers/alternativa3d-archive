package alternativa.engine3d.core {

	public class Fragment {
		
		static public var collector:Fragment;
		
		public var next:Fragment;
		
		public var negative:Fragment;
		public var positive:Fragment;
		
		public var geometry:Geometry;
		
		public var indices:Vector.<int> = new Vector.<int>();
		public var num:int = 0;
		
		public var normalX:Number;
		public var normalY:Number;
		public var normalZ:Number;
		public var offset:Number;
		
		static public function create():Fragment {
			if (collector != null) {
				var res:Fragment = collector;
				collector = collector.next;
				res.next = null;
				res.num = 0;
				return res;
			} else {
				return new Fragment();
			}
		}
		
		public function create():Fragment {
			if (collector != null) {
				var res:Fragment = collector;
				collector = collector.next;
				res.next = null;
				res.num = 0;
				return res;
			} else {
				return new Fragment();
			}
		}
		
	}
}
