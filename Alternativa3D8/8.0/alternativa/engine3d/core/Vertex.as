package alternativa.engine3d.core {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	/**
	 * Вершина в трёхмерном пространстве. Вершины являются составными частями полигональных объектов. На базе вершин строятся грани.
	 * @see alternativa.engine3d.core.Geometry
	 * @see alternativa.engine3d.core.Face
	 */
	public class Vertex {
	
		alternativa3d var geometry:Geometry;
	
		/**
		 * Координата X.
		 */
		public var _x:Number = 0;
		
		/**
		 * Координата Y.
		 */
		public var _y:Number = 0;
		
		/**
		 * Координата Z.
		 */
		public var _z:Number = 0;
	
		/**
		 * Текстурная координата по горизонтали.
		 */
		public var _u:Number = 0;
		
		/**
		 * Текстурная координата по вертикали.
		 */
		public var _v:Number = 0;
		
		public var normal:Vector3D;
		public var tangent:Vector3D;
		
		/**
		 * Индексы костей, влияющих на эту вершину 
		 */
		public var _jointsIndices:Vector.<uint>;

		/**
		 * Веса костей, влияющих на эту вершину. 
		 */
		public var _jointsWeights:Vector.<Number>;

		/**
		 * Дополнительные аттрибуты в вершине для шейдера
		 */
		public var _attributes:Vector.<Number>;

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
		alternativa3d var offset:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var index:int;
	
		/**
		 * @private 
		 */
		static alternativa3d var collector:Vertex;
	
		public function get x():Number {
			return _x;
		}
		public function set x(value:Number):void {
			_x = value;
			geometry.reset();
		}
		public function get y():Number {
			return _y;
		}
		public function set y(value:Number):void {
			_y = value;
			geometry.reset();
		}
		public function get z():Number {
			return _z;
		}
		public function set z(value:Number):void {
			_z = value;
			geometry.reset();
		}
		public function get u():Number {
			return _u;
		}
		public function set u(value:Number):void {
			_u = value;
			geometry.reset();
		}
		public function get v():Number {
			return _v;
		}
		public function set v(value:Number):void {
			_v = value;
			geometry.reset();
		}
		public function get jointsIndices():Vector.<uint> {
			return _jointsIndices;
		}
		public function set jointsIndices(value:Vector.<uint>):void {
			_jointsIndices = value;
			geometry.reset();
		}
		public function get jointsWeights():Vector.<Number> {
			return _jointsWeights;
		}
		public function set jointsWeights(value:Vector.<Number>):void {
			_jointsWeights = value;
			geometry.reset();
		}
		public function get attributes():Vector.<Number> {
			return _attributes;
		}
		public function set attributes(value:Vector.<Number>):void {
			_attributes = value;
			geometry.reset();
		}
	
		/**
		 * @private 
		 */
		static alternativa3d function createList(num:int):Vertex {
			var res:Vertex = collector;
			var last:Vertex;
			if (res != null) {
				for (last = res; num > 1; last = last.next,num--) {
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
				return res;
			} else {
				//trace("new Vertex");
				return new Vertex();
			}
		}
	
		alternativa3d function clone():Vertex {
			var res:Vertex = new Vertex();
			res._x = _x;
			res._y = _y;
			res._z = _z;
			res._u = _u;
			res._v = _v;
			var i:int, count:int;
			if (_attributes != null) {
				count = _attributes.length;
				res._attributes = new Vector.<Number>(count);
				for (i = 0; i < count; i++) {
					res._attributes[i] = _attributes[i];
				}
			}
			if (_jointsIndices != null) {
				count = _jointsIndices.length;
				res._jointsIndices = new Vector.<uint>(count);
				for (i = 0; i < count; i++) {
					res._jointsIndices[i] = _jointsIndices[i];
				}
			}
			if (_jointsWeights != null) {
				count = _jointsWeights.length;
				res._jointsWeights = new Vector.<Number>(count);
				for (i = 0; i < count; i++) {
					res._jointsWeights[i] = _jointsWeights[i];
				}
			}
			return res;
		}
	
	}
}
