package alternativa.engine3d.animation {

	import flash.utils.getTimer;

	/**
	 * Выполняет ежекадровое обновление контроллеров.
	 */
	public class AnimationTimer {

		/**
		 * Соотношение виртуального времени реальному 
		 */
		public var timeScale:Number = 1.0;

		private var _numControllers:int;
		private var _controllers:Vector.<AnimationController> = new Vector.<AnimationController>();

		private var lastTime:int = -1;

		/**
		 * Создает экземпляр контроллера. 
		 */
		public function AnimationTimer() {
		}

		/**
		 * Начинает отсчет времени. 
		 */
		public function start():void {
			lastTime = getTimer();
		}

		/**
		 * Обновляет контроллеры с времени последнего вызова start() или update().
		 * 
		 * @see #start()
		 */
		public function update():void {
			if (lastTime >= 0) {
				var time:int = getTimer();
				var interval:Number = 0.001*timeScale*(time - lastTime);
				for (var i:int = 0; i < _numControllers; i++) {
					var controller:AnimationController = _controllers[i];
					if (controller.enabled) {
						controller.update(interval);
					}
				}
				lastTime = time;
			}
		}

		/**
		 * Приостанавливает отсчет времени. 
		 */
		public function stop():void {
			lastTime = -1;
		}

		/**
		 * Возвращает <code>true</code> если таймер в данный момент остановлен. 
		 */
		public function get stoped():Boolean {
			return lastTime == -1;
		}

		/**
		 * Добавляет контроллер.
		 */
		public function addController(controller:AnimationController):AnimationController {
			if (controller == null) {
				throw new Error("Controller cannot be null");
			}
			_controllers[_numControllers++] = controller;
			return controller;
		}

		/**
		 * Убирает контроллер. 
		 */
		public function removeController(controller:AnimationController):AnimationController {
			var index:int = _controllers.indexOf(controller);
			if (index < 0) throw new ArgumentError("Controller not found");
			_numControllers--;
			var j:int = index + 1;
			while (index < _numControllers) {
				_controllers[index] = _controllers[j];
				index++;
				j++;
			}
			_controllers.length = _numControllers;
			return controller;
		}

		/**
		 * Возвращает количество контроллеров. 
		 */
		public function get numControllers():int {
			return _numControllers;
		}

		/**
		 * Возвращает контроллер по индексу.
		 *  
		 * @param index индекс контроллера.
		 */
		public function getControllerAt(index:int):AnimationController {
			return _controllers[index];
		}

	}
}
