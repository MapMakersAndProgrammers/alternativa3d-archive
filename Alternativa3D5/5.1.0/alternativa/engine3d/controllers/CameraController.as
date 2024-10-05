package alternativa.engine3d.controllers {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.physics.SphereCollider;
	import alternativa.types.Map;
	import alternativa.types.Matrix3D;
	import alternativa.types.Point3D;
	import alternativa.utils.KeyboardUtils;
	import alternativa.utils.MathUtils;
	
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	use namespace alternativa3d;

	/**
	 * Контроллер камеры. Контроллер обеспечивает управление движением и поворотами камеры с использованием
	 * клавиатуры и мыши, а также реализует простую проверку столкновений камеры с объектами сцены.
	 */	
	public class CameraController	{
		/**
		 * Имя действия для привязки клавиш движения вперёд.
		 */
		public static const ACTION_FORWARD:String = "ACTION_FORWARD";
		/**
		 * Имя действия для привязки клавиш движения назад.
		 */
		public static const ACTION_BACK:String = "ACTION_BACK";
		/**
		 * Имя действия для привязки клавиш движения влево.
		 */
		public static const ACTION_LEFT:String = "ACTION_LEFT";
		/**
		 * Имя действия для привязки клавиш движения вправо.
		 */
		public static const ACTION_RIGHT:String = "ACTION_RIGHT";
		/**
		 * Имя действия для привязки клавиш движения вверх.
		 */
		public static const ACTION_UP:String = "ACTION_UP";
		/**
		 * Имя действия для привязки клавиш движения вниз.
		 */
		public static const ACTION_DOWN:String = "ACTION_DOWN";
//		public static const ACTION_ROLL_LEFT:String = "ACTION_ROLL_LEFT";
//		public static const ACTION_ROLL_RIGHT:String = "ACTION_ROLL_RIGHT";
		/**
		 * Имя действия для привязки клавиш увеличения угла тангажа.
		 */
		public static const ACTION_PITCH_UP:String = "ACTION_PITCH_UP";
		/**
		 * Имя действия для привязки клавиш уменьшения угла тангажа.
		 */
		public static const ACTION_PITCH_DOWN:String = "ACTION_PITCH_DOWN";
		/**
		 * Имя действия для привязки клавиш уменьшения угла рысканья (поворота налево).
		 */
		public static const ACTION_YAW_LEFT:String = "ACTION_YAW_LEFT";
		/**
		 * Имя действия для привязки клавиш увеличения угла рысканья (поворота направо).
		 */
		public static const ACTION_YAW_RIGHT:String = "ACTION_YAW_RIGHT";
		/**
		 * Имя действия для привязки клавиш увеличения скорости.
		 */
		public static const ACTION_ACCELERATE:String = "ACTION_ACCELERATE";

		// флаги действий
		private var _forward:Boolean;
		private var _back:Boolean;
		private var _left:Boolean;
		private var _right:Boolean;
		private var _up:Boolean;
		private var _down:Boolean;
		private var _pitchUp:Boolean;
		private var _pitchDown:Boolean;
		private var _yawLeft:Boolean;
		private var _yawRight:Boolean;
		private var _accelerate:Boolean;
		
		private var _moveLocal:Boolean = true;

		// Флаг включения управления камерой
		private var _controlsEnabled:Boolean = false;

		// Значение таймера в начале прошлого кадра
		private var lastFrameTime:uint;
		
		// Чувствительность обзора мышью. Коэффициент умножения базовых коэффициентов поворотов.
		private var _mouseSensitivity:Number = 1;
		// Коэффициент поворота камеры по тангажу. Значение угла в радианах на один пиксель перемещения мыши по вертикали.
		private var _mousePitch:Number = Math.PI / 360;
		// Результирующий коэффициент поворота камеры мышью по тангажу
		private var _mousePitchCoeff:Number = _mouseSensitivity * _mousePitch;
		// Коэффициент поворота камеры по рысканью. Значение угла в радианах на один пиксель перемещения мыши по горизонтали.
		private var _mouseYaw:Number = Math.PI / 360;
		// Результирующий коэффициент поворота камеры мышью по расканью
		private var _mouseYawCoeff:Number = _mouseSensitivity * _mouseYaw;
		
		// Вспомогательные переменные для обзора мышью
		private var mouseLookActive:Boolean;
		private var startDragCoords:Point = new Point();
		private var currentDragCoords:Point = new Point();
		private var prevDragCoords:Point = new Point();
		private var startRotX:Number;
		private var startRotZ:Number;

		// Скорость изменения тангажа в радианах за секунду при управлении с клавиатуры
		private var _pitchSpeed:Number = 1;
		// Скорость изменения рысканья в радианах за секунду при управлении с клавиатуры
		private var _yawSpeed:Number = 1;
		// Скорость изменения крена в радианах за секунду при управлении с клавиатуры
//		public var bankSpeed:Number = 2;
//		private var bankMatrix:Matrix3D = new Matrix3D();

		// Скорость поступательного движения в единицах за секунду
		private var _speed:Number = 100;
		// Коэффициент увеличения скорости при соответствующей нажатой клавише
		private var _speedMultiplier:Number = 2;
		
		private var velocity:Point3D = new Point3D();
		private var destination:Point3D = new Point3D();
		
		private var _fovStep:Number = Math.PI / 180;
		private var _zoomMultiplier:Number = 0.1;
		
		// Привязка клавиш к действиям
		private var keyBindings:Map = new Map();
		// Привязка действий к обработчикам
		private var actionBindings:Map = new Map();
		
		// Источник событий клавиатуры и мыши
		private var _eventsSource:DisplayObject;
		// Управляемая камера
		private var _camera:Camera3D; 

		// Класс реализации определния столкновений
		private var _collider:SphereCollider;
		// Флаг необходимости проверки столкновений
		private var _checkCollisions:Boolean;
		// Радиус сферы для определения столкновений
		private var _collisionRadius:Number = 0;
		
		/**
		 * Создание экземпляра класса.
		 * 
		 * @param eventsSourceObject объект, используемый для получения событий мыши и клавиатуры
		 */
		public function CameraController(eventsSourceObject:DisplayObject) {
			if (eventsSourceObject == null) {
				throw new ArgumentError("CameraController: eventsSource is null");
			}
			_eventsSource = eventsSourceObject;
			
			actionBindings[ACTION_FORWARD] = setForwardFlag;
			actionBindings[ACTION_BACK] = setBackFlag;
			actionBindings[ACTION_LEFT] = setLeftFlag;
			actionBindings[ACTION_RIGHT] = setRightFlag;
			actionBindings[ACTION_UP] = setUpFlag;
			actionBindings[ACTION_DOWN] = setDownFlag;
			actionBindings[ACTION_PITCH_UP] = setPitchUpFlag;
			actionBindings[ACTION_PITCH_DOWN] = setPitchDownFlag;
			actionBindings[ACTION_YAW_LEFT] = setYawLeftFlag;
			actionBindings[ACTION_YAW_RIGHT] = setYawRightFlag;
			actionBindings[ACTION_ACCELERATE] = setAccelerateFlag;
		}
		
		/**
		 * Установка привязки клавиш по умолчанию. Данный метод очищает все существующие привязки клавиш и устанавливает следующие:
		 * <ul>
		 * <li> W &mdash; ACTION_FORWARD
		 * <li> S &mdash; ACTION_BACK
		 * <li> A &mdash; ACTION_LEFT
		 * <li> D &mdash; ACTION_RIGHT
		 * <li> SPACE &mdash; ACTION_UP
		 * <li> CONTROL &mdash; ACTION_DOWN
		 * <li> UP &mdash; ACTION_PITCH_UP
		 * <li> DOWN &mdash; ACTION_PITCH_DOWN
		 * <li> LEFT &mdash; ACTION_YAW_LEFT
		 * <li> RIGHT &mdash; ACTION_YAW_RIGHT
		 * <li> SHIFT &mdash; ACTION_ACCELERATE
		 * </ul>
		 */
		public function setDefaultBindings():void {
			unbindAll();
			bindKey(KeyboardUtils.W, ACTION_FORWARD);
			bindKey(KeyboardUtils.S, ACTION_BACK);
			bindKey(KeyboardUtils.A, ACTION_LEFT);
			bindKey(KeyboardUtils.D, ACTION_RIGHT);
			bindKey(KeyboardUtils.SPACE, ACTION_UP);
			bindKey(KeyboardUtils.CONTROL, ACTION_DOWN);
			bindKey(KeyboardUtils.UP, ACTION_PITCH_UP);
			bindKey(KeyboardUtils.DOWN, ACTION_PITCH_DOWN);
			bindKey(KeyboardUtils.LEFT, ACTION_YAW_LEFT);
			bindKey(KeyboardUtils.RIGHT, ACTION_YAW_RIGHT);
			bindKey(KeyboardUtils.SHIFT, ACTION_ACCELERATE);
		}
		
		/**
		 * Направление камеры на точку.
		 * 
		 * @param point координаты точки направления камеры
		 */
		public function lookAt(point:Point3D):void {
			var dx:Number = point.x - _camera.x;
			var dy:Number = point.y - _camera.y;
			var dz:Number = point.z - _camera.z;
			_camera.rotationZ = -Math.atan2(dx, dy);
			_camera.rotationX = Math.atan2(dz, Math.sqrt(dx * dx + dy * dy)) - MathUtils.DEG90;
		}
		
		/**
		 * Источник событий клавиатуры и мыши.
		 */
		public function get eventsSource():DisplayObject {
			return _eventsSource;
		}
		
		/**
		 * @private
		 */
		public function set eventsSource(value:DisplayObject):void {
			if (value == null) {
				throw new ArgumentError("CameraController: eventsSource is null");
			}
			if (_eventsSource != value) {
				if (_controlsEnabled) {
					unregisterEventsListeners();
				}
				_eventsSource = value;
				if (_controlsEnabled) {
					registerEventListeners();
				}
			}
		}

		/**
		 * Текущая управляемая камера.
		 */
		public function get camera():Camera3D {
			return _camera;
		}
		
		/**
		 * @private
		 */
		public function set camera(value:Camera3D):void {
			if (value == null) {
				controlsEnabled = false;
			}
			_camera = value;
		}
		
		/**
		 * Режим движения камеры. Если значение равно <code>true</code>, то перемещения камеры происходят относительно
		 * локальной системы координат, иначе относительно глобальной.
		 * 
		 * @default true 
		 */
		public function get moveLocal():Boolean {
			return _moveLocal;
		}
		
		/**
		 * @private
		 */		
		public function set moveLocal(value:Boolean):void {
			_moveLocal = value;
		}
		
		/**
		 * Включение режима проверки столкновений. Установка значения невозможна, пока камера не добавлена на сцену.
		 */
		public function get checkCollisions():Boolean {
			return _checkCollisions;
		}

		/**
		 * @private
		 */
		public function set checkCollisions(value:Boolean):void {
			if (_camera.scene == null) {
				return;
			}
			if (_checkCollisions != value) {
				_checkCollisions = value;
				if (_checkCollisions && _collider == null) {
					_collider = new SphereCollider(_camera.scene, _collisionRadius);
					_collider.offsetThreshold = 0.01;
				}
			}
		}
		
		/**
		 * Радиус сферы для определения столкновений.
		 * 
		 * @default 0
		 */
		public function get collisionRadius():Number {
			return _collisionRadius;
		}
		
		/**
		 * @private
		 */
		public function set collisionRadius(value:Number):void {
			_collisionRadius = value;
			if (_collider != null) {
				_collider.sphereRadius = _collisionRadius;
			}
		}
		
		/**
		 * Связывание клавиши с действием.
		 * 
		 * @param keyCode код клавиши
		 * @param action наименование действия
		 */
		public function bindKey(keyCode:uint, action:String):void {
			var method:Function = actionBindings[action];
			if (method != null) {
				keyBindings[keyCode] = method;
			}
		}
		
		/**
		 * Очистка привязки клавиши.
		 * 
		 * @param keyCode код клавиши
		 */
		public function unbindKey(keyCode:uint):void {
			keyBindings.remove(keyCode);
		}

		/**
		 * Очистка привязки всех клавиш.
		 */
		public function unbindAll():void {
			keyBindings.clear();
		}

		/**
		 * @private
		 * @param value
		 */
		private function setForwardFlag(value:Boolean):void {
			_forward = value;
		}

		/**
		 * @private
		 * @param value
		 */
		private function setBackFlag(value:Boolean):void {
			_back = value;
		}
		
		/**
		 * @private
		 * @param value
		 */
		private function setLeftFlag(value:Boolean):void {
			_left = value;
		}

		/**
		 * @private
		 * @param value
		 */
		private function setRightFlag(value:Boolean):void {
			_right = value;
		}

		/**
		 * @private
		 * @param value
		 */
		private function setUpFlag(value:Boolean):void {
			_up = value;
		}

		/**
		 * @private
		 * @param value
		 */
		private function setDownFlag(value:Boolean):void {
			_down = value;
		}

		/**
		 * @private
		 * @param value
		 */
		private function setPitchUpFlag(value:Boolean):void {
			_pitchUp = value;
		}

		/**
		 * @private
		 * @param value
		 */
		private function setPitchDownFlag(value:Boolean):void {
			_pitchDown = value;
		}

		/**
		 * @private
		 * @param value
		 */
		private function setYawLeftFlag(value:Boolean):void {
			_yawLeft = value;
		}

		/**
		 * @private
		 * @param value
		 */
		private function setYawRightFlag(value:Boolean):void {
			_yawRight = value;
		}
		
		
		/**
		 * @private
		 */
		private function setAccelerateFlag(value:Boolean):void {
			_accelerate = value;
		}
		
		/**
		 * Чувствительность мыши.
		 * 
		 * @default 1
		 */		
		public function get mouseSensitivity():Number {
			return _mouseSensitivity;
		}
		
		/**
		 * @private
		 */		
		public function set mouseSensitivity(sensitivity:Number):void {
			_mouseSensitivity = sensitivity;
			_mousePitchCoeff = _mouseSensitivity * _mousePitch;
			_mouseYawCoeff = _mouseSensitivity * _mouseYaw;
		}
		
		/**
		 * Скорость изменения тангажа при управлении мышью (радианы на пиксель).
		 * 
		 * @default Math.PI / 360
		 */		
		public function get mousePitch():Number {
			return _mousePitch;
		}

		/**
		 * @private
		 */		
		public function set mousePitch(pitch:Number):void {
			_mousePitch = pitch;
			_mousePitchCoeff = _mouseSensitivity * _mousePitch;
		}
		
		/**
		 * Скорость изменения рысканья при управлении мышью (радианы на пиксель).
		 * 
		 * @default Math.PI / 360
		 */		
		public function get mouseYaw():Number {
			return _mouseYaw;
		}
		
		/**
		 * @private
		 */		
		public function set mouseYaw(yaw:Number):void {
			_mouseYaw = yaw;
			_mouseYawCoeff = _mouseSensitivity * _mouseYaw;
		}
		
		/**
		 * Угловая скорость по тангажу при управлении с клавиатуры (радианы в секунду).
		 * 
		 * @default 1
		 */		
		public function get pitchSpeed():Number {
			return _pitchSpeed;
		}

		/**
		 * @private
		 */		
		public function set pitchSpeed(spd:Number):void {
			_pitchSpeed = spd;
		}

		/**
		 * Угловая скорость по рысканью при управлении с клавиатуры (радианы в секунду).
		 * 
		 * @default 1
		 */		
		public function get yawSpeed():Number {
			return _yawSpeed;
		}

		/**
		 * @private
		 */		
		public function set yawSpeed(spd:Number):void {
			_yawSpeed = spd;
		}

		/**
		 * Скорость поступательного движения (единицы в секунду).
		 */		
		public function get speed():Number {
			return _speed;
		}

		/**
		 * @private
		 */		
		public function set speed(spd:Number):void {
			_speed = spd;
		}
		
		/**
		 * Коэффициент увеличения скорости при соотвествующей нажатой клавише.
		 * 
		 * @default 2
		 */
		public function get speedMultiplier():Number {
			return _speedMultiplier;
		}

		/**
		 * @private
		 */
		public function set speedMultiplier(value:Number):void {
			_speedMultiplier = value;
		}

		/**
		 * Активность управления камеры.
		 * 
		 * @default false
		 */
		public function get controlsEnabled():Boolean {
			return _controlsEnabled;
		}
		
		/**
		 * @private
		 */		
		public function set controlsEnabled(state:Boolean):void {
			if (_camera == null || _controlsEnabled == state) return;
			if (state) {
				lastFrameTime = getTimer();
				registerEventListeners();
			}
			else {
				unregisterEventsListeners();
			}
			_controlsEnabled = state;
		}
		
		/**
		 * Базовый шаг изменения угла зрения в радианах. Реальный шаг получаеся умножением этого значения на величину
		 * <code>MouseEvent.delta</code>.
		 * 
		 * @default Math.PI / 180 
		 */
		public function get fovStep():Number {
			return _fovStep;
		}
		
		/**
		 * @private
		 */
		public function set fovStep(value:Number):void {
			_fovStep = value;
		}
		
		/**
		 * Коэффициент изменения коэффициента увеличения.
		 * 
		 * @default 0.1 
		 */
		public function get zoomMultiplier():Number {
			return _zoomMultiplier;
		}
		
		/**
		 * @private
		 */
		public function set zoomMultiplier(value:Number):void {
			_zoomMultiplier = value;
		}
		
		/**
		 * @private
		 */
		private function registerEventListeners():void {
			_eventsSource.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			_eventsSource.addEventListener(KeyboardEvent.KEY_UP, onKey);
			_eventsSource.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			_eventsSource.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}

		/**
		 * @private
		 */
		private function unregisterEventsListeners():void {
			_eventsSource.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
			_eventsSource.removeEventListener(KeyboardEvent.KEY_UP, onKey);
			_eventsSource.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			_eventsSource.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_eventsSource.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}

		/**
		 * @private
		 * @param e
		 */
		private function onKey(e:KeyboardEvent):void {
			var method:Function = keyBindings[e.keyCode];
			if (method != null) {
				method.call(this, e.type == KeyboardEvent.KEY_DOWN);
			}
		}
		
		/**
		 * @private
		 * @param e
		 */		
		private function onMouseDown(e:MouseEvent):void {
			mouseLookActive = true; 
			currentDragCoords.x = startDragCoords.x = _eventsSource.stage.mouseX;
			currentDragCoords.y = startDragCoords.y = _eventsSource.stage.mouseY;
			startRotX = _camera.rotationX;
			startRotZ = _camera.rotationZ;
			_eventsSource.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}

		/**
		 * @private
		 * @param e
		 */		
		private function onMouseUp(e:MouseEvent):void {
			mouseLookActive = false;
			_eventsSource.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		/**
		 * @private
		 * @param e
		 */		
		private function onMouseWheel(e:MouseEvent):void {
			if (_camera.orthographic) {
				_camera.zoom = _camera.zoom * (1 + e.delta * _zoomMultiplier);
			} else {
				_camera.fov -= _fovStep * e.delta;
			}
		}
		
		/**
		 * Обработка управляющих воздействий.
		 * Метод должен вызываться каждый кадр перед вызовом <code>Scene3D.calculate()</code>.
		 * 
		 * @see alternativa.engine3d.core.Scene3D#calculate()
		 */		
		public function processInput(): void {
			if (!_controlsEnabled || _camera == null) return;
			
			// Время в секундах от начала предыдущего кадра
			var frameTime:Number = getTimer() - lastFrameTime;
			lastFrameTime += frameTime;
			frameTime /= 1000;
			
			// Обработка mouselook
			if (mouseLookActive) {
				prevDragCoords.x = currentDragCoords.x;
				prevDragCoords.y = currentDragCoords.y;
				currentDragCoords.x = _eventsSource.stage.mouseX;
				currentDragCoords.y = _eventsSource.stage.mouseY;
				if (!prevDragCoords.equals(currentDragCoords)) {
					_camera.rotationZ = startRotZ + (startDragCoords.x - currentDragCoords.x) * _mouseYawCoeff;
					var rotX:Number = startRotX + (startDragCoords.y - currentDragCoords.y) * _mousePitchCoeff;
					_camera.rotationX = (rotX > 0) ? 0 : (rotX < -MathUtils.DEG180) ? -MathUtils.DEG180 : rotX;
				}
			}

			// Поворот относительно вертикальной оси (рысканье, yaw)
			if (_yawLeft) {
				_camera.rotationZ += _yawSpeed * frameTime;
			} else if (_yawRight) {
				_camera.rotationZ -= _yawSpeed * frameTime;
			}
			
			// Поворот относительно поперечной оси (тангаж, pitch)
			if (_pitchUp) {
				rotX = _camera.rotationX + _pitchSpeed * frameTime;
				_camera.rotationX = (rotX > 0) ? 0 : (rotX < -MathUtils.DEG180) ? -MathUtils.DEG180 : rotX;
			} else if (_pitchDown) {
				rotX = _camera.rotationX - _pitchSpeed * frameTime;
				_camera.rotationX = (rotX > 0) ? 0 : (rotX < -MathUtils.DEG180) ? -MathUtils.DEG180 : rotX;
			}

			// TODO: Поворот относительно продольной оси (крен, roll)
			
			var frameDistance:Number = _speed * frameTime;
			if (_accelerate) {
				frameDistance *= _speedMultiplier;
			}
			velocity.x = 0;
			velocity.y = 0;
			velocity.z = 0;
			var transformation:Matrix3D = _camera.transformation;
			
			if (_moveLocal) {
				// Режим относительных пермещений
				// Движение вперед-назад
				if (_forward) {
					velocity.x += frameDistance * transformation.c;
					velocity.y += frameDistance * transformation.g;
					velocity.z += frameDistance * transformation.k;
				} else if (_back) {
					velocity.x -= frameDistance * transformation.c;
					velocity.y -= frameDistance * transformation.g;
					velocity.z -= frameDistance * transformation.k;
				}
				// Движение влево-вправо
				if (_left) {
					velocity.x -= frameDistance * transformation.a;
					velocity.y -= frameDistance * transformation.e;
					velocity.z -= frameDistance * transformation.i;
				} else if (_right) {
					velocity.x += frameDistance * transformation.a;
					velocity.y += frameDistance * transformation.e;
					velocity.z += frameDistance * transformation.i;
				}
				// Движение вверх-вниз
				if (_up) {
					velocity.x -= frameDistance * transformation.b;
					velocity.y -= frameDistance * transformation.f;
					velocity.z -= frameDistance * transformation.j;
				} else if (_down) {
					velocity.x += frameDistance * transformation.b;
					velocity.y += frameDistance * transformation.f;
					velocity.z += frameDistance * transformation.j;
				}
			}
			else {
				// Режим глобальных перемещений
				var cosZ:Number = Math.cos(_camera.rotationZ);
				var sinZ:Number = Math.sin(_camera.rotationZ);
				// Движение вперед-назад
				if (_forward) {
					velocity.x -= frameDistance * sinZ;
					velocity.y += frameDistance * cosZ;
				} else if (_back) {
					velocity.x += frameDistance * sinZ;
					velocity.y -= frameDistance * cosZ;
				}
				// Движение влево-вправо
				if (_left) {
					velocity.x -= frameDistance * cosZ;
					velocity.y -= frameDistance * sinZ;
				} else if (_right) {
					velocity.x += frameDistance * cosZ;
					velocity.y += frameDistance * sinZ;
				}
				// Движение вверх-вниз
				if (_up) {
					velocity.z += frameDistance;
				} else if (_down) {
					velocity.z -= frameDistance;
				}
			}
			
			// Коррекция модуля вектора скорости
			if (velocity.x != 0 || velocity.y != 0 || velocity.z != 0) {
				velocity.length = frameDistance;
			}
			
			if (_checkCollisions) {
				_collider.calculateDestination(_camera.coords, velocity, destination);
				_camera.x = destination.x;
				_camera.y = destination.y;
				_camera.z = destination.z;
			} else {
				_camera.x += velocity.x;
				_camera.y += velocity.y;
				_camera.z += velocity.z;
			}
		}
	}
}