package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	
	use namespace alternativa3d;
	
	/**
	 * Вершина в трёхмерном пространстве. Вершины являются составными частями полигональных объектов. На базе вершин строятся грани.
	 * @see alternativa.engine3d.core.Geometry
	 * @see alternativa.engine3d.core.Face
	 */
	public class Vertex {
	
		/**
		 * Координата X.
		 */
		public var x:Number = 0;
		
		/**
		 * Координата Y.
		 */
		public var y:Number = 0;
		
		/**
		 * Координата Z.
		 */
		public var z:Number = 0;
	
		/**
		 * Текстурная координата по горизонтали.
		 */
		public var u:Number = 0;
		
		/**
		 * Текстурная координата по вертикали.
		 */
		public var v:Number = 0;
	
		/**
		 * @private 
		 */
		alternativa3d var next:Vertex;
		
		/**
		 * @private 
		 */
		alternativa3d var value:Vertex;
	
		/**
		 * @private 
		 */
		alternativa3d var cameraX:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var cameraY:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var cameraZ:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var offset:Number;
	
		/**
		 * @private 
		 */
		alternativa3d var transformId:int = 0;
		
		/**
		 * @private 
		 */
		alternativa3d var drawId:int = 0;
		
		/**
		 * @private 
		 */
		alternativa3d var index:int;
	
		/**
		 * @private 
		 */
		static alternativa3d var collector:Vertex;
	
		/**
		 * @private 
		 */
		static alternativa3d function createList(num:int):Vertex {
			var res:Vertex = collector;
			var last:Vertex;
			if (res != null) {
				for (last = res; num > 1; last = last.next,num--) {
					last.transformId = 0;
					last.drawId = 0;
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
				last.transformId = 0;
				last.drawId = 0;
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
	
		/**
		 * @private 
		 */
		alternativa3d function create():Vertex {
			if (collector != null) {
				var res:Vertex = collector;
				collector = res.next;
				res.next = null;
				res.transformId = 0;
				res.drawId = 0;
				return res;
			} else {
				//trace("new Vertex");
				return new Vertex();
			}
		}
		
		/**
		 * Возвращает строковое представление заданного объекта.
		 * @return Строковое представление объекта.
		 */		
		public function toString():String {
			return "[Vertex " + x.toFixed(2) + ", " + y.toFixed(2) + ", " + z.toFixed(2) + ", " + u.toFixed(3) + ", " + v.toFixed(3) + "]";
		}
		
	}
}
