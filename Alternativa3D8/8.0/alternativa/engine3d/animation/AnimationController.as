package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;

	/**
	 * Управляет проигрыванием и смешением анимаций.
	 */
	public class AnimationController {

		use namespace alternativa3d;

		/**
		 * Включение/выключение контроллера.
		 */
		public var enabled:Boolean = true;

		private var _animations:Object = new Object();

		/**
		 * Создает экземпляр контроллера. 
		 */
		public function AnimationController() {
		}

		/**
		 * Проиграть анимацию сначала.
		 *  
		 * @param name имя анимации для проигрывания
		 * @param fade время в течение которого вес анимации должен увеличиться с нуля до максимального значения.
		 */
		public function replay(name:String, fade:Number = 0):void {
			var state:AnimationState = _animations[name];
			if (state == null) {
				throw new ArgumentError('Animation with name "' + name + '" not found');
			}
			state.replay(fade);
		}

		/**
		 * Продолжить проигрывание анимации с текущей позиции.
		 *  
		 * @param name имя анимации для проигрывания
		 * @param fade время в течение которого вес анимации должен увеличиться с нуля до максимального значения.
		 */
		public function play(name:String, fade:Number = 0):void {
			var state:AnimationState = _animations[name];
			if (state == null) {
				throw new ArgumentError('Animation with name "' + name + '" not found');
			}
			state.play(fade);
		}

		/**
		 * Остановить анимацию.
		 *  
		 * @param name имя анимации для останова
		 * @param fade время в течение которого вес анимации должен уменьшиться с максимального значения до 0.
		 */
		public function stop(name:String, fade:Number = 0):void {
			var state:AnimationState = _animations[name];
			if (state == null) {
				throw new ArgumentError('Animation with name "' + name + '" not found');
			}
			state.stop(fade);
		}

		/**
		 * Проиграть все анимации сначала.
		 *  
		 * @param fade время в течение которого вес каждой анимации должен увеличиться с нуля до максимального значения.
		 */
		public function replayAll(fade:Number = 0):void {
			for each (var state:AnimationState in _animations) {
				state.replay(fade);
			}
		}

		/**
		 * Продолжить проигрывание всех анимаций с текущей позиции.
		 *  
		 * @param fade время в течение которого вес каждой анимации должен увеличиться с нуля до максимального значения.
		 */
		public function playAll(fade:Number = 0):void {
			for each (var state:AnimationState in _animations) {
				state.play(fade);
			}
		}

		/**
		 * Остановить все анимации.
		 *  
		 * @param fade время в течение которого вес каждой анимации должен уменьшиться с максимального значения до 0.
		 */
		public function stopAll(fade:Number = 0):void {
			for each (var state:AnimationState in _animations) {
				state.stop(fade);
			}
		}

		/**
		 * Проиграть анимации за прошедшее время и выполнить их смешение.
		 * Для автоматического ежекадрового обновления можно использовать класс AnimationTimer.
		 *  
		 * @param interval прошедшее время.
		 * 
		 * @see AnimationTimer
		 */
		public function update(interval:Number):void {
			if (!enabled) {
				return;
			}
			var state:AnimationState;
			for each (state in _animations) {
				state.prepareBlending();
			}
			for each (state in _animations) {
				state.update(interval);
			}
		}

		/**
		 * Добавляет анимацию в контроллер и возвращает объект состояния проигрывания анимации.
		 *  
		 * @param name имя анимации
		 * @param animation добавляемая анимация
		 * @param loop проиграть анимацию сначала после достижения конца
		 * @return экземляр класса AnimationState через который выполняется управление проигрыванием анимации.
		 * 
		 * @see AnimationState
		 */
		public function addAnimation(name:String, animation:Animation, loop:Boolean = true):AnimationState {
			var state:AnimationState = _animations[name];
			if (state != null) {
				throw new ArgumentError('Animation with this name "' + name + '" already exist');
			}
			state = new AnimationState(this, animation, name, loop);
			_animations[name] = state;
			return state;
		}

		/**
		 * Убирает анимацию из контроллера.
		 *  
		 * @param name имя анимации для удаления.
		 */
		public function removeAnimation(name:String):void {
			var state:AnimationState = _animations[name];
			if (state == null) {
				throw new ArgumentError('Animation with name"' + name + '" not exists');
			}
			delete _animations[name];
		}

		/**
		 * Возвращает объект состояния проигрывания анимации по имени.
		 *  
		 * @param name имя анимации.
		 * 
		 * @see AnimationState
		 */
		public function getAnimation(name:String):AnimationState {
			return _animations[name];
		}

		/**
		 * Возвращает словарь со всеми анимациями. Свойство - имя анимации, значение - экземпляр класса AnimationState.
		 * 
		 * @see AnimationState
		 */
		public function get animations():Object {
			var result:Object = new Object();
			for (var name:String in _animations) {
				result[name] = _animations[name];
			}
			return result;
		}

	}
}
