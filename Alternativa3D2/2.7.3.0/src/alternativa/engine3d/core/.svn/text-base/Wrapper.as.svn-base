package alternativa.engine3d.core {
	
	public class Wrapper {
	
		public var next:Wrapper;
	
		public var vertex:Vertex;
	
		static public var collector:Wrapper;
	
		static public function create():Wrapper {
			if (collector != null) {
				var res:Wrapper = collector;
				collector = collector.next;
				res.next = null;
				return res;
			} else {
				//trace("new Wrapper");
				return new Wrapper();
			}
		}
	
		public function create():Wrapper {
			if (collector != null) {
				var res:Wrapper = collector;
				collector = collector.next;
				res.next = null;
				return res;
			} else {
				//trace("new Wrapper");
				return new Wrapper();
			}
		}
	
	}
}
