package alternativa.engine3d.animation {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;

	/**
	 * Анимация объекта
	 */
	public class Animation {

		use namespace alternativa3d;

		protected static const WEIGHTS_X:uint = 0;
		protected static const WEIGHTS_Y:uint = 1;
		protected static const WEIGHTS_Z:uint = 2;
		protected static const WEIGHTS_ROT_X:uint = 3;
		protected static const WEIGHTS_ROT_Y:uint = 4;
		protected static const WEIGHTS_ROT_Z:uint = 5;
		protected static const WEIGHTS_SCALE_X:uint = 6;
		protected static const WEIGHTS_SCALE_Y:uint = 7;
		protected static const WEIGHTS_SCALE_Z:uint = 8;

		/**
		 * Анимируемый объект.
		 */
		public var object:Object3D = null;

		/**
		 * Вес анимации по отношению к другим анимациям этого параметра.
		 * Анимация с более высоким весом оказывает большее влияние на конечное значение параметра.
		 * Вес наследуется на дочерние анимации.
		 */
		public var weight:Number = 1.0;

		/**
		 * Скорость проигрывания анимации. Скорость наследуется на дочерние анимации. 
		 */
		public var speed:Number = 1.0;

		/**
		 * Длина анимации, включая дочерние анимации.
		 * После изменения длины треков и длины дочерних анимаций необходимо вызвать updateLength().
		 * @see #updateLength()
		 */
		public var length:Number = 0.0;

		/**
		 * Создает анимацию 
		 * 
		 * @param object анимируемый объект
		 * @param weight вес анимации
		 * @param speed скорость проигрывания анимации
		 */
		public function Animation(object:Object3D = null, weight:Number = 1.0, speed:Number = 1.0) {
			this.object = object;
			this.weight = weight;
			this.speed = speed;
		}

		/**
		 * Пересчитывает длину анимации.
		 */
		public function updateLength():void {
			var maxLen:Number = 0;
			for (var i:int = 0; i < _numAnimations; i++) {
				var animation:Animation = _animations[i];
				animation.updateLength();
				var len:Number = animation.length;
				if (len > maxLen) {
					maxLen = len;
				}
			}
			length = maxLen;
		}

		/**
		 * Подготавливает объект к выполнению смешения анимаций.
		 * Для смешения нескольких анимаций, необходимо на каждой из них вызвать prepareBlending() и затем blend().
		 * 
		 * @see #blend()
		 */
		public function prepareBlending():void {
			if (object != null) {
				if (object.weightsSum != null) {
					object.weightsSum[0] = 0; object.weightsSum[1] = 0;	object.weightsSum[2] = 0;
					object.weightsSum[3] = 0; object.weightsSum[4] = 0;	object.weightsSum[5] = 0;
					object.weightsSum[6] = 0; object.weightsSum[7] = 0;	object.weightsSum[8] = 0;
				} else {
					object.weightsSum = new Vector.<Number>(9);
				}
			}
			for (var i:int = 0; i < _numAnimations; i++) {
				_animations[i].prepareBlending();
			}
		}

		/**
		 * Выполняет смешение анимации с другими анимациями этого параметра.
		 * Перед вызовом этого метода, на всех анимациях которые требуется смешать, нужно вызвать метод prepareBlending().
		 * 
		 * @param position время анимации
		 * @param weight вес анимации
		 * 
		 * @see #prepareBlending()
		 */
		public function blend(position:Number, weight:Number):void {
			position = (position < 0) ? 0 : (position > length) ? length : position;
			control(position, weight);
			for (var i:int = 0; i < _numAnimations; i++) {
				var animation:Animation = _animations[i];
				if (animation.weight != 0) {
					animation.blend(position*animation.speed, weight*animation.weight); 
				}
			}
		}

		protected function calculateBlendInterpolation(param:int, weight:Number):Number {
			var sum:Number = object.weightsSum[param];
/*
			if (sum > 0 && weight < 0) {
				// Предыдущая анимация была на переднем слое, а текущая на нижнем
				if (sum > 1) {
					return 0;
				} else {
					// Смешиваем на оставшееся значение
					sum = weight;
				}
			}
			if (sum == 0) {
				// Текущая анимация первая
				sum = weight;
				weight = 1;
			} else if (sum > 0) {
				// Предыдущая анимация на верхнем слое, текущая тоже на верхнем, потому что остальные варианты уже отмели
				sum += weight;
				weight /= sum;
			} else {
				// Предыдущая анимация на нижнем слое
				if (weight > 0) {
					// Текущая анимация на верхнем слое
					sum = weight;
					weight = 1;
				} else {
					// Текущая анимация на нижнем слое тоже
					sum += weight;
					weight /= sum;
				}
			}
*/
			sum += weight;
			weight /= sum;

			object.weightsSum[param] = sum;
			return weight;
		}

		protected function control(position:Number, weight:Number):void {
		}

		private var _numAnimations:int;
		private var _animations:Vector.<Animation>;

		/**
		 * Добавляет дочернюю анимацию.
		 * Для пересчета длины вызовите updateLength().
		 *  
		 * @see #updateLength()
		 */
		public function addAnimation(animation:Animation):Animation {
			if (animation == null) {
				throw new Error("Animation cannot be null");
			}
			if (_animations == null) {
				_animations = new Vector.<Animation>();
			}
			_animations[_numAnimations++] = animation;
			return animation;
		}

		/**
		 * Убирает дочернюю анимацию.
		 * Для пересчета длины вызовите updateLength().
		 *  
		 * @see #updateLength()
		 */
		public function removeAnimation(animation:Animation):Animation {
			var index:int = (_animations != null) ? _animations.indexOf(animation) : -1;
			if (index < 0) throw new ArgumentError("Animation not found");
			_numAnimations--;
			var j:int = index + 1;
			while (index < _numAnimations) {
				_animations[index] = _animations[j];
				index++;
				j++;
			}
			if (_numAnimations <= 0) {
				_animations = null;
			} else {
				_animations.length = _numAnimations;
			}
			return animation;
		}

		/**
		 * Количество дочерних анимаций. 
		 */
		public function get numAnimations():int {
			return _numAnimations;
		}

		/**
		 * Возвращает анимацию по индексу.
		 */
		public function getAnimationAt(index:int):Animation {
			return (_animations != null) ? _animations[index] : null;
		}

		protected function interpolateAngle(angle1:Number, angle2:Number, weight1:Number):Number {
			const PI2:Number = 2*Math.PI;
			angle1 = (angle1 > Math.PI) ? angle1%PI2 - PI2 : (angle1 <= -Math.PI) ? (angle1%PI2) + PI2 : angle1;
			angle2 = (angle2 > Math.PI) ? angle2%PI2 - PI2 : (angle2 <= -Math.PI) ? (angle2%PI2) + PI2 : angle2;
			var delta:Number = angle2 - angle1;
			delta = (delta > Math.PI) ? delta - PI2 : (delta < -Math.PI) ? delta + PI2 : delta;
			return angle1 + weight1 * delta;
		}

	}
}
