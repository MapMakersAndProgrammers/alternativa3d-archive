package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;
	
	use namespace alternativa3d;

	/**
	 * Ключевой кадр вещественного типа. 
	 */
	public class ValueKey extends Key {

		/**
		 * Значение ключевого кадра. 
		 */
		public var value:Number;

		/**
		 * Создает ключевой кадр.
		 *  
		 * @param time время кадра.
		 * @param value значение кадра.
		 */
		public function ValueKey(time:Number, value:Number) {
			super(time);
			this.value = value;
		}

		/**
		 * @private 
		 */
		override alternativa3d function interpolate(time:Number, next:Key, key:Key = null):Key {
			var value:Number;
			if (next != null) {
				value = this.value + (ValueKey(next).value - this.value)*(time - this.time)/(next.time - this.time);
			} else {
				value = this.value;
			}
			if (key != null) {
				key.time = time;
				ValueKey(key).value = value;
				return key;
			} else {
				return new ValueKey(time, value);
			}
		}

		/**
		 * Строковое представление объекта. 
		 */
		public function toString():String {
			return "[ValueKey " + time + ":" + value + "]";
		}

	}
}
