package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	
	use namespace alternativa3d;

	public class BoundBoxKey extends Key {

		public var boundMinX:Number = -1e+22;
		public var boundMinY:Number = -1e+22;
		public var boundMinZ:Number = -1e+22;
		public var boundMaxX:Number = 1e+22;
		public var boundMaxY:Number = 1e+22;
		public var boundMaxZ:Number = 1e+22;

		public function BoundBoxKey(time:Number, object:Object3D = null) {
			super(time);
			if (object != null) {
				this.boundMinX = object.boundMinX;
				this.boundMinY = object.boundMinY;
				this.boundMinZ = object.boundMinZ;
				this.boundMaxX = object.boundMaxX;
				this.boundMaxY = object.boundMaxY;
				this.boundMaxZ = object.boundMaxZ;
			}
		}

		/**
		 * @private 
		 */
		alternativa3d override function interpolate(time:Number, next:Key, key:Key = null):Key {
			var boundBoxKey:BoundBoxKey;
			if (key == null) {
				boundBoxKey = new BoundBoxKey(time);
				key = boundBoxKey;
			} else {
				key.time = time;
				boundBoxKey = BoundBoxKey(key);
			}
			if (next != null) {
				var boundBoxNextKey:BoundBoxKey = BoundBoxKey(next);
				if (time == this.time) {
					boundBoxKey.boundMinX = this.boundMinX;
					boundBoxKey.boundMinY = this.boundMinY;
					boundBoxKey.boundMinZ = this.boundMinZ;
					boundBoxKey.boundMaxX = this.boundMaxX;
					boundBoxKey.boundMaxY = this.boundMaxY;
					boundBoxKey.boundMaxZ = this.boundMaxZ;
					return key;
				} else if (time == next.time) {
					boundBoxKey.boundMinX = boundBoxNextKey.boundMinX;
					boundBoxKey.boundMinY = boundBoxNextKey.boundMinY;
					boundBoxKey.boundMinZ = boundBoxNextKey.boundMinZ;
					boundBoxKey.boundMaxX = boundBoxNextKey.boundMaxX;
					boundBoxKey.boundMaxY = boundBoxNextKey.boundMaxY;
					boundBoxKey.boundMaxZ = boundBoxNextKey.boundMaxZ;
					return key;
				}
				boundBoxKey.boundMinX = (this.boundMinX < boundBoxNextKey.boundMinX) ? this.boundMinX : boundBoxNextKey.boundMinX;
				boundBoxKey.boundMinY = (this.boundMinY < boundBoxNextKey.boundMinY) ? this.boundMinY : boundBoxNextKey.boundMinY;
				boundBoxKey.boundMinZ = (this.boundMinZ < boundBoxNextKey.boundMinZ) ? this.boundMinZ : boundBoxNextKey.boundMinZ;
				boundBoxKey.boundMaxX = (this.boundMaxX > boundBoxNextKey.boundMaxX) ? this.boundMaxX : boundBoxNextKey.boundMaxX;
				boundBoxKey.boundMaxY = (this.boundMaxY > boundBoxNextKey.boundMaxY) ? this.boundMaxY : boundBoxNextKey.boundMaxY;
				boundBoxKey.boundMaxZ = (this.boundMaxZ > boundBoxNextKey.boundMaxZ) ? this.boundMaxZ : boundBoxNextKey.boundMaxZ;
			} else {
				boundBoxKey.boundMinX = this.boundMinX;
				boundBoxKey.boundMinY = this.boundMinY;
				boundBoxKey.boundMinZ = this.boundMinZ;
				boundBoxKey.boundMaxX = this.boundMaxX;
				boundBoxKey.boundMaxY = this.boundMaxY;
				boundBoxKey.boundMaxZ = this.boundMaxZ;
			}
			return key;
		}

		public function setBoundBox(object:Object3D):void {
			this.boundMinX = object.boundMinX;
			this.boundMinY = object.boundMinY;
			this.boundMinZ = object.boundMinZ;
			this.boundMaxX = object.boundMaxX;
			this.boundMaxY = object.boundMaxY;
			this.boundMaxZ = object.boundMaxZ;
		}

//		/**
//		 * Строковое представление объекта.
//		 */
//		public function toString():String {
//			return "[BoundBoxKey " + time + ":" +  + "]";
//		}

	}

}
