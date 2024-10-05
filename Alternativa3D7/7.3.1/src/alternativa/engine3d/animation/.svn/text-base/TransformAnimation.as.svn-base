package alternativa.engine3d.animation {
	public class TransformAnimation extends ObjectAnimation {
	
		public var translation:Track;
		public var rotation:Track;
		public var scale:Track;
	
		public var x:Track;
		public var y:Track;
		public var z:Track;
	
		public var rotationX:Track;
		public var rotationY:Track;
		public var rotationZ:Track;
	
		public var scaleX:Track;
		public var scaleY:Track;
		public var scaleZ:Track;
	
		private var valueKey:ValueKey = new ValueKey(0, 0);
		private var pointKey:PointKey = new PointKey(0, 0, 0, 0);
	
		override protected function control():void {
			if (translation != null) {
				translation.getKey(_position, pointKey);
				object.x = pointKey.x;
				object.y = pointKey.y;
				object.z = pointKey.z;
			} else {
				if (x != null) {
					x.getKey(_position, valueKey);
					object.x = valueKey.value;
				}
				if (y != null) {
					y.getKey(_position, valueKey);
					object.y = valueKey.value;
				}
				if (z != null) {
					z.getKey(_position, valueKey);
					object.z = valueKey.value;
				}
			}
			if (rotation != null) {
				rotation.getKey(_position, pointKey);
				object.rotationX = pointKey.x;
				object.rotationY = pointKey.y;
				object.rotationZ = pointKey.z;
			} else {
				if (rotationX != null) {
					rotationX.getKey(_position, valueKey);
					object.rotationX = valueKey.value;
				}
				if (rotationY != null) {
					rotationY.getKey(_position, valueKey);
					object.rotationY = valueKey.value;
				}
				if (rotationZ != null) {
					rotationZ.getKey(_position, valueKey);
					object.rotationZ = valueKey.value;
				}
			}
			if (scale != null) {
				scale.getKey(_position, pointKey);
				object.scaleX = pointKey.x;
				object.scaleY = pointKey.y;
				object.scaleZ = pointKey.z;
			} else {
				if (scaleX != null) {
					scaleX.getKey(_position, valueKey);
					object.scaleX = valueKey.value;
				}
				if (scaleY != null) {
					scaleY.getKey(_position, valueKey);
					object.scaleY = valueKey.value;
				}
				if (scaleZ != null) {
					scaleZ.getKey(_position, valueKey);
					object.scaleZ = valueKey.value;
				}
			}
		}
		
		override public function get length():Number {
			var len:Number;
			var maxLen:Number = 0;
			if (translation != null) {
				maxLen = translation.length;
			}
			if (rotation != null) {
				len = rotation.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (scale != null) {
				len = scale.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (x != null) {
				len = x.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (y != null) {
				len = y.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (z != null) {
				len = z.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (rotationX != null) {
				len = rotationX.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (rotationY != null) {
				len = rotationY.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (rotationZ != null) {
				len = rotationZ.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (scaleX != null) {
				len = scaleX.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (scaleY != null) {
				len = scaleY.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			if (scaleZ != null) {
				len = scaleZ.length;
				maxLen = (len > maxLen) ? len : maxLen;
			}
			return maxLen;
		}

	}
}
