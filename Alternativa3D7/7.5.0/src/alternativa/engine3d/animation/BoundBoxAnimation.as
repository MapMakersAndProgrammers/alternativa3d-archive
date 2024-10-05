package alternativa.engine3d.animation {
	import alternativa.engine3d.animation.keys.BoundBoxKey;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;
	

	public class BoundBoxAnimation extends Animation {

		/**
		 * Временная шкала с ключевыми кадрами анимации баунд-бокса. 
		 */
		public var boundBox:Track;

		private var boundBoxKey:BoundBoxKey = new BoundBoxKey(0);

		/**
		 * Конструктор анимации.
		 *  
		 * @param object анимируемый объект.
		 * @param weight вес анимации.
		 * @param speed скорость проигрывания анимации.
		 */
		public function BoundBoxAnimation(object:Transform3D = null, weight:Number = 1.0, speed:Number = 1.0) {
			super(object, weight, speed);
		}

		override public function updateLength():void {
			super.updateLength();
			if (boundBox != null) {
				var len:Number = boundBox.length;
				length = (len > length) ? len : length;
			}
		}

		override protected function control(position:Number, weight:Number):void {
			if (boundBox != null && object != null) {
				var object3D:Object3D = Object3D(object);
				boundBox.getKey(position, boundBoxKey);
				var c:Number = calculateBlendInterpolation(WEIGHTS_BOUND_BOX, weight);
				if (c >= 1) {
					// Анимация влияет полностью
					object3D.boundMinX = boundBoxKey.boundMinX;
					object3D.boundMinY = boundBoxKey.boundMinY;
					object3D.boundMinZ = boundBoxKey.boundMinZ;
					object3D.boundMaxX = boundBoxKey.boundMaxX;
					object3D.boundMaxY = boundBoxKey.boundMaxY;
					object3D.boundMaxZ = boundBoxKey.boundMaxZ;
				} else {
					// Иначе добавляем анимацию к объекту
					object3D.boundMinX = (object3D.boundMinX < boundBoxKey.boundMinX) ? object3D.boundMinX : boundBoxKey.boundMinX;
					object3D.boundMinY = (object3D.boundMinY < boundBoxKey.boundMinY) ? object3D.boundMinY : boundBoxKey.boundMinY;
					object3D.boundMinZ = (object3D.boundMinZ < boundBoxKey.boundMinZ) ? object3D.boundMinZ : boundBoxKey.boundMinZ;
					object3D.boundMaxX = (object3D.boundMaxX > boundBoxKey.boundMaxX) ? object3D.boundMaxX : boundBoxKey.boundMaxX;
					object3D.boundMaxY = (object3D.boundMaxY > boundBoxKey.boundMaxY) ? object3D.boundMaxY : boundBoxKey.boundMaxY;
					object3D.boundMaxZ = (object3D.boundMaxZ > boundBoxKey.boundMaxZ) ? object3D.boundMaxZ : boundBoxKey.boundMaxZ;
				}
			}
		}

		override public function clone():Animation {
			var cloned:BoundBoxAnimation = new BoundBoxAnimation(object, weight, speed);
			cloned.boundBox = boundBox;
			cloned.length = length;
			return cloned;
		}

		override public function slice(start:Number, end:Number = Number.MAX_VALUE):Animation {
			var animation:BoundBoxAnimation = new BoundBoxAnimation(object, weight, speed);
			animation.boundBox = (boundBox != null) ? boundBox.slice(start, end) : null;
			animation.updateLength();
			return animation;
		}

	}
}
