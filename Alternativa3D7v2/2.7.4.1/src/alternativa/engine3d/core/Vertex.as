package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	
	use namespace alternativa3d;
	
	public class Vertex {
	
		public var x:Number = 0;
		public var y:Number = 0;
		public var z:Number = 0;
	
		public var u:Number = 0;
		public var v:Number = 0;
	
		alternativa3d var next:Vertex;
		alternativa3d var value:Vertex;
	
		alternativa3d var cameraX:Number;
		alternativa3d var cameraY:Number;
		alternativa3d var cameraZ:Number;
		alternativa3d var offset:Number;
	
		alternativa3d var transformID:int = 0;
		alternativa3d var drawID:int = 0;
		alternativa3d var index:int;
	
		static alternativa3d var collector:Vertex;
	
		static alternativa3d function createList(num:int):Vertex {
			var res:Vertex = collector;
			var last:Vertex;
			if (res != null) {
				for (last = res; num > 1; last = last.next,num--) {
					last.transformID = 0;
					last.drawID = 0;
					if (last.next == null) {
						//for (; num > 1; /*trace("new Vertex"), */last.next = new Vertex(), last = last.next, num--);
						while (num > 1) {
							//trace("new Vertex");
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
				//trace("new Vertex");
				res = new Vertex();
				last = res;
				while (num > 1) {
					//trace("new Vertex");
					last.next = new Vertex();
					last = last.next;
					num--;
				}
			}
			return res;
		}
	
		alternativa3d function create():Vertex {
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
