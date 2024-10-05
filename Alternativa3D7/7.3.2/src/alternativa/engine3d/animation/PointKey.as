package alternativa.engine3d.animation {
	import alternativa.engine3d.alternativa3d;
	
	use namespace alternativa3d;
	
	public class PointKey extends Key {
		public var x:Number;
		public var y:Number;
		public var z:Number;
	
		public function PointKey(time:Number, x:Number, y:Number, z:Number) {
			super(time);
			this.x = x;
			this.y = y;
			this.z = z;
		}
	
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
	
		public function toString():String {
			return "[PointKey " + time.toFixed(3) + ":" + x + "," + y + "," + z + "]";
		}
	
	}
}