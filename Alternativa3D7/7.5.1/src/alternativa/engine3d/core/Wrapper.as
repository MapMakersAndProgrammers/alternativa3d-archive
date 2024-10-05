package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class Wrapper {
	
		alternativa3d var next:Wrapper;
	
		alternativa3d var vertex:Vertex;
	
		static alternativa3d var collector:Wrapper;
	
		static alternativa3d function create():Wrapper {
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
	
		alternativa3d function create():Wrapper {
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
