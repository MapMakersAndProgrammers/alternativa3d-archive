package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;

	/**
	 * Cостояние проигрывания анимации в контроллере. 
	 */
	public final class AnimationState {

		use namespace alternativa3d;

		/**
		 * Проигрываемая анимация. 
		 */
		public var animation:Animation;

		/**
		 * Зацикленность анимации. Зацикленная анимация будет проигрываться сначала после достижения конца. 
		 */
		public var loop:Boolean;

		/**
		 * Для незацикленной анимации задает время с отсчетом от конца анимации после которого начнется затухание анимации.
		 * 0 - без затухания, 1 - затухание с начала анимации. 
		 */
		public var endingFadeOut:Number = 0;

		private var fadeInTime:Number;
		private var fadedIn:Boolean;
		private var fadeInPosition:Number;
		private var fadeOutTime:Number;
		private var fadedOut:Boolean;
		private var fadeOutPosition:Number;

		private var manualControl:Boolean = false;

		private var _controller:AnimationController;

		private var _name:String;
		private var _played:Boolean = false;
		private var _position:Number = 0;

		/**
		 * Конструктор состояния анимации, вызывается в AnimationController.
		 * 
		 * @see AnimationController
		 */
		public function AnimationState(controller:AnimationController, animation:Animation, name:String, loop:Boolean) {
			this.animation = animation;
			this._controller = controller;
			this._name = name;
			this.loop = loop;
		}

		/**
		 * Проиграть анимацию сначала.
		 *  
		 * @param fade время в течение которого вес анимации должен увеличиться с нуля до максимального значения.
		 */
		public function replay(fade:Number = 0):void {
			_played = true;
			_position = 0;
			fadeInTime = fade;
			fadedIn = true;
			if (fadedOut) {
				fadeInPosition = fadeInTime*(1 - fadeOutPosition/fadeOutTime);
				fadedOut = false;
			}
			manualControl = false;
		}

		/**
		 * Продолжить проигрывание анимации с текущей позиции.
		 * 
		 * @param fade время в течение которого вес анимации должен увеличиться с нуля до максимального значения.
		 */
		public function play(fade:Number = 0):void {
			if (!_played) {
				_played = true;
				fadeInTime = fade;
				fadedIn = true;
				if (fadedOut) {
					fadeInPosition = fadeInTime*(1 - fadeOutPosition/fadeOutTime);
					fadedOut = false;
				} else {
					fadeInPosition = 0;
				}
				manualControl = false;
			}
		}

		/**
		 * Остановить проигрывание анимации.
		 * 
		 * @param fade время в течение которого вес анимации должен уменьшиться с максимального значения до 0.
		 */
		public function stop(fade:Number = 0):void {
			if (_played) {
				_played = false;
				fadeOutTime = fade;
				if (fadedIn) {
					fadeOutPosition = fadeOutTime*(1 - fadeInPosition/fadeInTime);
					fadedIn = false;
					fadedOut = true;
				} else {
					if (!fadedOut) {
						fadeOutPosition = 0;
						fadedOut = true;
					}
				}
				manualControl = false;
			}
		}

		/**
		 * @private 
		 */
		alternativa3d function prepareBlending():void {
			if (animation != null) {
				animation.prepareBlending();
			}
		}

		private function loopPosition():void {
			if (_position < 0) {
//				_position = (length <= 0) ? 0 : _position % length;
				_position = 0;
			} else {
				if (_position >= animation.length) {
					_position = (animation.length <= 0) ? 0 : _position % animation.length;
				}
			}
		}

		private function fading(position:Number):Number {
			if (position > 1) {
				return 1;
			}
			if (position < 0) {
				return 0;
			}
			return position;
		}

		/**
		 * @private 
		 */
		alternativa3d function update(interval:Number):void {
			if (animation == null) {
				return;
			}
			var weight:Number = animation.weight;
			if (_played) {
				_position += interval*animation.speed;
				if (loop) {
					loopPosition();
					if (fadedIn) {
						fadeInPosition += interval;
						if (fadeInPosition < fadeInTime) {
							weight *= fading(fadeInPosition/fadeInTime);
						} else {
							fadedIn = false;
						}
					}
				} else {
					if (_position < 0) {
						_position = 0;
						if (interval < 0) {
							_played = false;
						}
						weight = 0;
					} else {
						if (_position > animation.length) {
							if (interval > 0) {
								_position = 0;
								_played = false;
							} else {
								_position = animation.length;
							}
							weight = 0;
						} else {
							if ((_position/animation.length + endingFadeOut) > 1) {
								fadedOut = true;
								fadeOutTime = endingFadeOut;
								fadeOutPosition = _position/animation.length + endingFadeOut - 1;
							} else {
								fadedOut = false;
							}
							if (fadedIn) {
								fadeInPosition += interval;
							}
							if ((fadedIn && (fadeInPosition < fadeInTime)) && fadedOut) {
								var w1:Number = fading(fadeInPosition/fadeInTime);
								var w2:Number = fading(1 - fadeOutPosition/fadeOutTime);
								if (w1 < w2) {
									weight *= w1;
								} else {
									weight *= w2;
									fadedIn = false;
								}
							} else {
								if (fadedIn) {
									if (fadeInPosition < fadeInTime) {
										weight *= fading(fadeInPosition/fadeInTime);
									} else {
										fadedIn = false;
									}
								} else if (fadedOut) {
									weight *= fading(1 - fadeOutPosition/fadeOutTime);
								}
							}
						}
					}
				}
			} else {
				if (!manualControl) {
					if (fadedOut) {
						_position += interval*animation.speed;
						if (loop) {
							loopPosition();
						} else {
							if (_position < 0) {
								_position = 0;
							} else {
								if (_position >= animation.length) {
									_position = animation.length;
								}
							}
						}
						fadeOutPosition += interval;
						if (fadeOutPosition < fadeOutTime) {
							weight *= fading(1 - fadeOutPosition/fadeOutTime);
						} else {
							fadedOut = false;
							weight = 0;
						}
					} else {
						weight = 0;
					}
				}
			}
			if (weight != 0) {
				animation.blend(_position, weight);
			}
		}

		/**
		 * Контроллер, управляющий воспроизведением анимации.
		 */
		public function get controller():AnimationController {
			return _controller;
		}

		/**
		 * Имя анимации в контроллере. 
		 */
		public function get name():String {
			return _name;
		}

		/**
		 * Проигрывается анимация в данный момент или нет. 
		 */
		public function get played():Boolean {
			return _played;
		}

		/**
		 * Позиция проигрывания анимации. 
		 */
		public function get position():Number {
			return _position;
		}

		/**
		 * @private 
		 */
		public function set position(value:Number):void {
			_position = value;
			manualControl = true;
			_played = false;
			fadedIn = false;
			fadedOut = false;
		}

	}
}
