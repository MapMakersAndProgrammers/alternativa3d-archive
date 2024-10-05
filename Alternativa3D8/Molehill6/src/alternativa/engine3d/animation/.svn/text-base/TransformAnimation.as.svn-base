package alternativa.engine3d.animation {

	import alternativa.engine3d.animation.keys.PointKey;
	import alternativa.engine3d.animation.keys.ValueKey;
	import alternativa.engine3d.core.Object3D;
	
	import flash.geom.Vector3D;

	/**
	 * Анимация компонентов положения и ориентации объекта. 
	 */
	public class TransformAnimation extends Animation {

		/**
		 * Временная шкала с ключевыми кадрами положения объекта. 
		 */
		public var translation:Track;
		/**
		 * Временная шкала с ключевыми кадрами вращения объекта. 
		 */
		public var rotation:Track;
		/**
		 * Временная шкала с ключевыми кадрами масштаба объекта.
		 */
		public var scale:Track;

		/**
		 * Временная шкала с ключевыми кадрами перемещения объекта по оси X.
		 */
		public var x:Track;
		/**
		 * Временная шкала с ключевыми кадрами перемещения объекта по оси Y.
		 */
		public var y:Track;
		/**
		 * Временная шкала с ключевыми кадрами перемещения объекта по оси Z. 
		 */
		public var z:Track;

		/**
		 * Временная шкала с ключевыми кадрами вращения объекта по оси X.
		 */
		public var rotationX:Track;
		/**
		 * Временная шкала с ключевыми кадрами вращения объекта по оси Y. 
		 */
		public var rotationY:Track;
		/**
		 * Временная шкала с ключевыми кадрами вращения объекта по оси Z.
		 */
		public var rotationZ:Track;

		/**
		 * Временная шкала с ключевыми кадрами масштаба объекта по оси X. 
		 */
		public var scaleX:Track;
		/**
		 * Временная шкала с ключевыми кадрами масштаба объекта по оси Y.
		 */
		public var scaleY:Track;
		/**
		 * Временная шкала с ключевыми кадрами масштаба объекта по оси Z.
		 */
		public var scaleZ:Track;

		private var valueKey:ValueKey = new ValueKey(0, 0);
		private var pointKey:PointKey = new PointKey(0, 0, 0, 0);

		/**
		 * Конструктор анимации.
		 *  
		 * @param object анимируемый объект.
		 * @param weight вес анимации.
		 * @param speed скорость проигрывания анимации.
		 */
		public function TransformAnimation(object:Object3D = null, weight:Number = 1.0, speed:Number = 1.0) {
			super(object, weight, speed);
		}

		/**
		 * @inheritDoc 
		 */
		override protected function control(position:Number, weight:Number):void {
			if (object == null) {
				return;
			}
			var c:Number;
			//var t:Vector3D = object.translation;
			//var r:Vector3D = object.rotation;
			//var s:Vector3D = object.scale;
			if (translation != null) {
				translation.getKey(position, pointKey);
				c = calculateBlendInterpolation(WEIGHTS_X, weight);
				object.x = (1 - c)*object.x + c*pointKey.x;
				c = calculateBlendInterpolation(WEIGHTS_Y, weight);
				object.y = (1 - c)*object.y + c*pointKey.y;
				c = calculateBlendInterpolation(WEIGHTS_Z, weight);
				object.z = (1 - c)*object.z + c*pointKey.z;
			} else {
				if (x != null) {
					x.getKey(position, valueKey);
					c = calculateBlendInterpolation(WEIGHTS_X, weight);
					object.x = (1 - c)*object.x + c*valueKey.value;
				}
				if (y != null) {
					y.getKey(position, valueKey);
					c = calculateBlendInterpolation(WEIGHTS_Y, weight);
					object.y = (1 - c)*object.y + c*valueKey.value;
				}
				if (z != null) {
					z.getKey(position, valueKey);
					c = calculateBlendInterpolation(WEIGHTS_Z, weight);
					object.z = (1 - c)*object.z + c*valueKey.value;
				}
			}
			if (rotation != null) {
				rotation.getKey(position, pointKey);
				c = calculateBlendInterpolation(WEIGHTS_ROT_X, weight);
				object.rotationX = interpolateAngle(object.rotationX, pointKey.x, c);
				c = calculateBlendInterpolation(WEIGHTS_ROT_Y, weight);
				object.rotationY = interpolateAngle(object.rotationY, pointKey.y, c);
				c = calculateBlendInterpolation(WEIGHTS_ROT_Z, weight);
				object.rotationZ = interpolateAngle(object.rotationZ, pointKey.z, c);
			} else {
				if (rotationX != null) {
					rotationX.getKey(position, valueKey);
					c = calculateBlendInterpolation(WEIGHTS_ROT_X, weight);
					object.rotationX = interpolateAngle(object.rotationX, valueKey.value, c);
				}
				if (rotationY != null) {
					rotationY.getKey(position, valueKey);
					c = calculateBlendInterpolation(WEIGHTS_ROT_Y, weight);
					object.rotationY = interpolateAngle(object.rotationY, valueKey.value, c);
				}
				if (rotationZ != null) {
					rotationZ.getKey(position, valueKey);
					c = calculateBlendInterpolation(WEIGHTS_ROT_Z, weight);
					object.rotationZ = interpolateAngle(object.rotationZ, valueKey.value, c);
				}
			}
			if (scale != null) {
				scale.getKey(position, pointKey);
				c = calculateBlendInterpolation(WEIGHTS_SCALE_X, weight);
				object.scaleX = (1 - c)*object.scaleX + c*pointKey.x;
				c = calculateBlendInterpolation(WEIGHTS_SCALE_Y, weight);
				object.scaleY = (1 - c)*object.scaleY + c*pointKey.y;
				c = calculateBlendInterpolation(WEIGHTS_SCALE_Z, weight);
				object.scaleZ = (1 - c)*object.scaleZ + c*pointKey.z;
			} else {
				if (scaleX != null) {
					scaleX.getKey(position, valueKey);
					c = calculateBlendInterpolation(WEIGHTS_SCALE_X, weight);
					object.scaleX = (1 - c)*object.scaleX + c*valueKey.value;
				}
				if (scaleY != null) {
					scaleY.getKey(position, valueKey);
					c = calculateBlendInterpolation(WEIGHTS_SCALE_Y, weight);
					object.scaleY = (1 - c)*object.scaleY + c*valueKey.value;
				}
				if (scaleZ != null) {
					scaleZ.getKey(position, valueKey);
					c = calculateBlendInterpolation(WEIGHTS_SCALE_Z, weight);
					object.scaleZ = (1 - c)*object.scaleZ + c*valueKey.value;
				}
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function slice(start:Number, end:Number = Number.MAX_VALUE):Animation {
			var animation:TransformAnimation = new TransformAnimation(object, weight, speed);
			animation.translation = (translation != null) ? translation.slice(start, end) : null;
			animation.rotation = (rotation != null) ? rotation.slice(start, end) : null;
			animation.scale = (scale != null) ? scale.slice(start, end) : null;
			animation.x = (x != null) ? x.slice(start, end) : null;
			animation.y = (y != null) ? y.slice(start, end) : null;
			animation.z = (z != null) ? z.slice(start, end) : null;
			animation.rotationX = (rotationX != null) ? rotationX.slice(start, end) : null;
			animation.rotationY = (rotationY != null) ? rotationY.slice(start, end) : null;
			animation.rotationZ = (rotationZ != null) ? rotationZ.slice(start, end) : null;
			animation.scaleX = (scaleX != null) ? scaleX.slice(start, end) : null;
			animation.scaleY = (scaleY != null) ? scaleY.slice(start, end) : null;
			animation.scaleZ = (scaleZ != null) ? scaleZ.slice(start, end) : null;
			animation.updateLength();
			return animation;
		}

		/**
		 * @inheritDoc 
		 */
		override public function updateLength():void {
			super.updateLength();
			var len:Number;
			if (translation != null) {
				len = translation.length;
				length =  (len > length) ? len : length;
			}
			if (rotation != null) {
				len = rotation.length;
				length =  (len > length) ? len : length;
			}
			if (scale != null) {
				len = scale.length;
				length =  (len > length) ? len : length;
			}
			if (x != null) {
				len = x.length;
				length =  (len > length) ? len : length;
			}
			if (y != null) {
				len = y.length;
				length =  (len > length) ? len : length;
			}
			if (z != null) {
				len = z.length;
				length =  (len > length) ? len : length;
			}
			if (rotationX != null) {
				len = rotationX.length;
				length =  (len > length) ? len : length;
			}
			if (rotationY != null) {
				len = rotationY.length;
				length =  (len > length) ? len : length;
			}
			if (rotationZ != null) {
				len = rotationZ.length;
				length =  (len > length) ? len : length;
			}
			if (scaleX != null) {
				len = scaleX.length;
				length =  (len > length) ? len : length;
			}
			if (scaleY != null) {
				len = scaleY.length;
				length =  (len > length) ? len : length;
			}
			if (scaleZ != null) {
				len = scaleZ.length;
				length =  (len > length) ? len : length;
			}
		}

		/**
		 * @inheritDoc 
		 */
		override public function clone():Animation {
			var cloned:TransformAnimation = new TransformAnimation(object, weight, speed);
			cloned.translation = translation;
			cloned.rotation = rotation;
			cloned.scale = scale;
			cloned.x = x;
			cloned.y = y;
			cloned.z = z;
			cloned.rotationX = rotationX;
			cloned.rotationY = rotationY;
			cloned.rotationZ = rotationZ;
			cloned.scaleX = scaleX;
			cloned.scaleY = scaleY;
			cloned.scaleZ = scaleZ;
			cloned.length = length;
			return cloned;
		}

	}
}
