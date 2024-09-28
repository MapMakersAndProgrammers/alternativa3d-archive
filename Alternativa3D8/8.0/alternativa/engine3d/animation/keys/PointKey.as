package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;
	
	use namespace alternativa3d;

	/**
	 * Ключевой кадр точечного типа. 
	 */
	public class PointKey extends Key {

		/**
		 * Координата по оси X.
		 */
		public var x:Number;
		/**
		 * Координата по оси Y.
		 */
		public var y:Number;
		/**
		 * Координата по оси Z.
		 */
		public var z:Number;

		/**
		 * Создает экземпляр ключевого кадра.
		 *  
		 * @param time время кадра.
		 * @param x координата по оси X
		 * @param y координата по оси Y
		 * @param z координата по оси Z
		 */
		public function PointKey(time:Number, x:Number, y:Number, z:Number) {
			super(time);
			this.x = x;
			this.y = y;
			this.z = z;
		}

		/**
		 * @private 
		 */
		override alternativa3d function interpolate(time:Number, next:Key, key:Key = null):Key {
			var x:Number;
			var y:Number;
			var z:Number;
			if (next != null) {
				var t:Number = (time - this.time)/(next.time - this.time);
				x = this.x + (PointKey(next).x - this.x)*t;
				y = this.y + (PointKey(next).y - this.y)*t;
				z = this.z + (PointKey(next).z - this.z)*t;
			} else {
				x = this.x;
				y = this.y;
				z = this.z;
			}
			if (key != null) {
				key.time = time;
				PointKey(key).x = x;
				PointKey(key).y = y;
				PointKey(key).z = z;
				return key;
			} else {
				return new PointKey(time, x, y, z);
			}
		}

		/**
		 * Строковое представление объекта.
		 */
		public function toString():String {
			return "[PointKey " + time.toFixed(3) + ":" + x + "," + y + "," + z + "]";
		}

	}
}
