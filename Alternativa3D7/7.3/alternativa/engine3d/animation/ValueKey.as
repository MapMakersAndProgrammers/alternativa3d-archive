package alternativa.engine3d.animation {
	import alternativa.engine3d.alternativa3d;
	
	use namespace alternativa3d;
	
	public class ValueKey extends Key {
		public var value:Number;
	
		public function ValueKey(time:Number, value:Number) {
			super(time);
			this.value = value;
		}
	
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
	
		public function toString():String {
			return "[ValueKey " + time + ":" + value + "]";
		}
	}
}