package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;

	/**
	 * Анимация объекта.
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
//		protected static const WEIGHTS_BOUND_BOX:uint = 9;

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
			length = 0;
		}

		/**
		 * Расчет кадра анимации.
		 * 
		 * @param position время кадра
		 */
		public function sample(position:Number):void {
			prepareBlending();
			blend(position, 1.0);
		}

		/**
		 * Подготавливает объект к выполнению смешения анимаций.
		 * Для смешения нескольких анимаций, необходимо на каждой из них вызвать prepareBlending() и затем blend().
		 * Для смешения и проигрывания нескольких анимаций может быть удобнее использовать класс AnimationController.
		 * 
		 * @see #blend()
		 * @see AnimationController
		 */
		public function prepareBlending():void {
			if (object != null) {
				if (object.weightsSum != null) {
					object.weightsSum[0] = 0; object.weightsSum[1] = 0;	object.weightsSum[2] = 0;
					object.weightsSum[3] = 0; object.weightsSum[4] = 0;	object.weightsSum[5] = 0;
					object.weightsSum[6] = 0; object.weightsSum[7] = 0;	object.weightsSum[8] = 0;
//					object.weightsSum[9] = 0;
				} else {
					object.weightsSum = new Vector.<Number>(10);
				}
			}
		}

		/**
		 * Выполняет смешение анимации с другими анимациями этого параметра.
		 * Перед вызовом этого метода, на всех анимациях которые требуется смешать, нужно вызвать метод prepareBlending().
		 * Не вызывать метод, если вес меньше нуля.
		 * Для смешения и проигрывания нескольких анимаций может быть удобнее использовать класс AnimationController.
		 * 
		 * @param position время анимации
		 * @param weight вес анимации
		 * 
		 * @see #prepareBlending()
		 * @see AnimationController
		 */
		public function blend(position:Number, weight:Number):void {
			position = (position < 0) ? 0 : (position > length) ? length : position;
			control(position, weight);
		}

		/**
		 * Расчитывает значение интерполяции параметра для текущей анимации и заданного веса.
		 * @param param индекс параметра
		 * @param weight вес анимации
		 */
		protected function calculateBlendInterpolation(param:int, weight:Number):Number {
			var sum:Number = object.weightsSum[param];
			sum += weight;
			object.weightsSum[param] = sum;
			return weight/sum;
		}

		/**
		 * Реализация расчета кадра анимации.
		 * @param position время кадра анимации
		 * @param weight вес анимации
		 */
		protected function control(position:Number, weight:Number):void {
		}

		/**
		 * Возвращает копию анимации. Копия анимации использует общие ключевые кадры с исходной анимацией.
		 */
		public function clone():Animation {
			var cloned:Animation = new Animation(object, weight, speed);
			cloned.length = length;
			return cloned;
		}

		/**
		 * Создает копию анимации, которая будет анимировать указанный объект.
		 *
		 * @param object объект, который должен анимироваться копией текущей анимации
		 * @return копия анимации
		 */
		public function copyTo(object:Object3D):Animation {
			var result:Animation = clone();
			result.object = object;
			return result;
		}

		/**
		 * Возвращает часть анимации в промежутке времени между start и end.
		 * @param start начало части анимации
		 * @param end конец части анимации
		 * @return часть анимации
		 */
		public function slice(start:Number, end:Number = Number.MAX_VALUE):Animation {
			return new Animation(object, weight, speed);
		}

		/**
		 * Интерполяция между двумя ненормализованными углами.
		 */
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
