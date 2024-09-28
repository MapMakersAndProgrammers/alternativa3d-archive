package alternativa.engine3d.core {
	
	public class Vertex {
	
		public var next:Vertex;
	
		public var x:Number = 0;
		public var y:Number = 0;
		public var z:Number = 0;
	
		public var u:Number = 0;
		public var v:Number = 0;
	
		public var cameraX:Number;
		public var cameraY:Number;
		public var cameraZ:Number;
	
		public var offset:Number;
	
		public var transformID:int = 0;
		public var drawID:int = 0;
	
		public var index:int;
	
		public var value:Vertex;
	
		static public var collector:Vertex;
	
		static public function createList(num:int):Vertex {
			var res:Vertex = collector;
			var last:Vertex;
			if (res != null) {
				for (last = res; num > 1; last = last.next,num--) {
					last.transformID = 0;
					last.drawID = 0;
					if (last.next == null) {
						//for (; num > 1; /*trace("new Vertex"), */last.next = new Vertex(), last = last.next, num--);
						while (num > 1) {
							last.next = new Vertex();
							last = last.next;
							num--;
						}
						break;
					}
				}
				collector = last.next;
				last.transformID = 0;
				last.drawID = 0;
				last.next = null;
			} else {
				//for (res = new Vertex(), /*trace("new Vertex"), */last = res; num > 1; /*trace("new Vertex"), */last.next = new Vertex(), last = last.next, num--);
				res = new Vertex();
				last = res;
				while (num > 1) {
					last.next = new Vertex();
					last = last.next;
					num--;
				}
			}
			return res;
		}
	
		public function create():Vertex {
			if (collector != null) {
				var res:Vertex = collector;
				collector = res.next;
				res.next = null;
				res.transformID = 0;
				res.drawID = 0;
				return res;
			} else {
				//trace("new Vertex");
				return new Vertex();
			}
		}
	
	}
}
