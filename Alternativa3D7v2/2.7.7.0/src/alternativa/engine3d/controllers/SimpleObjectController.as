package alternativa.engine3d.controllers {
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	
	import flash.display.InteractiveObject;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	/**
	 * Базовый контроллер для <code>Object3D</code>.
	 * @see Object3D
	 */
	public class SimpleObjectController {
	
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
		
		/**
		 * Имя действия для привязки клавиш поворота вверх.
		 */
		public static const ACTION_PITCH_UP:String = "ACTION_PITCH_UP";
		
		/**
		 * Имя действия для привязки клавиш поворота вниз.
		 */
		public static const ACTION_PITCH_DOWN:String = "ACTION_PITCH_DOWN";
		
		/**
		 * Имя действия для привязки клавиш поворота налево.
		 */
		public static const ACTION_YAW_LEFT:String = "ACTION_YAW_LEFT";
		
		/**
		 * Имя действия для привязки клавиш поворота направо.
		 */
		public static const ACTION_YAW_RIGHT:String = "ACTION_YAW_RIGHT";
		
		/**
		 * Имя действия для привязки клавиш увеличения скорости.
		 */
		public static const ACTION_ACCELERATE:String = "ACTION_ACCELERATE";
		
		/**
		 * Имя действия для привязки клавиш активации обзора мышью.
		 */
		public static const ACTION_MOUSE_LOOK:String = "ACTION_MOUSE_LOOK";
	
		/**
		 * Скорость в метрах в секунду.
		 */
		public var speed:Number;
		
		/**
		 * Величина, на которую домножается скорость в режиме ускорения.
		 */
		public var speedMultiplier:Number;
		
		/**
		 * Чувствительность мыши.
		 */
		public var mouseSensitivity:Number;
		
		/**
		 * Максимальный наклон.
		 */
		public var maxPitch:Number = 1e+22;
		
		/**
		 * Минимальный наклон.
		 */
		public var minPitch:Number = -1e+22;
	
		private var eventSource:InteractiveObject;
		private var _object:Object3D;
	
		private var _up:Boolean;
		private var _down:Boolean;
		private var _forward:Boolean;
		private var _back:Boolean;
		private var _left:Boolean;
		private var _right:Boolean;
		private var _accelerate:Boolean;
	
		private var displacement:Vector3D = new Vector3D();
		private var mousePoint:Point = new Point();
		private var mouseLook:Boolean;
		private var objectTransform:Vector.<Vector3D>;
	
		private var time:int;
	
		/**
		 * Ассоциативный массив, связывающий имена команд с реализующими их функциями. Функции должны иметь вид
		 * function(value:Boolean):void. Значение параметра <code>value</code> указывает, нажата или отпущена соответствующая команде.
		 * клавиша.
		 */
		private var actionBindings:Object = {};
		
		/**
		 * Ассоциативный массив, связывающий коды клавиатурных клавиш с именами команд.
		 */
		protected var keyBindings:Object = {};
	
		/**
		 * Создаёт новый экземпляр.
		 * @param eventSource Источник событий для контроллера.
		 * @param speed Скорость поступательного перемещения объекта.
		 * @param mouseSensitivity Чувствительность мыши — количество градусов поворота на один пиксель перемещения мыши.
		 */
		public function SimpleObjectController(eventSource:InteractiveObject, object:Object3D, speed:Number, speedMultiplier:Number = 3, mouseSensitivity:Number = 1) {
			this.eventSource = eventSource;
			this.object = object;
			this.speed = speed;
			this.speedMultiplier = speedMultiplier;
			this.mouseSensitivity = mouseSensitivity;
	
			actionBindings[ACTION_FORWARD] = moveForward;
			actionBindings[ACTION_BACK] = moveBack;
			actionBindings[ACTION_LEFT] = moveLeft;
			actionBindings[ACTION_RIGHT] = moveRight;
			actionBindings[ACTION_UP] = moveUp;
			actionBindings[ACTION_DOWN] = moveDown;
			actionBindings[ACTION_ACCELERATE] = accelerate;
	
			setDefaultBindings();
	
			enable();
		}
	
		/**
		 * Активирует контроллер.
		 */
		public function enable():void {
			eventSource.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			eventSource.addEventListener(KeyboardEvent.KEY_UP, onKey);
			eventSource.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			eventSource.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
	
		/**
		 * Деактивирует контроллер.
		 */
		public function disable():void {
			eventSource.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
			eventSource.removeEventListener(KeyboardEvent.KEY_UP, onKey);
			eventSource.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			eventSource.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stopMouseLook();
		}
	
		private function onMouseDown(e:MouseEvent):void {
			startMouseLook();
		}
	
		private function onMouseUp(e:MouseEvent):void {
			stopMouseLook();
		}
	
		/**
		 * Включает режим взгляда мышью.
		 */
		public function startMouseLook():void {
			mousePoint.x = eventSource.mouseX;
			mousePoint.y = eventSource.mouseY;
			mouseLook = true;
		}
	
		/**
		 * Отключает режим взгляда мышью.
		 */
		public function stopMouseLook():void {
			mouseLook = false;
		}
	
		private function onKey(e:KeyboardEvent):void {
			var method:Function = keyBindings[e.keyCode];
			if (method != null) method.call(this, e.type == KeyboardEvent.KEY_DOWN);
		}
	
		/**
		 * Управляемый объект.
		 */
		public function get object():Object3D {
			return _object;
		}
	
		/**
		 * @private
		 */
		public function set object(value:Object3D):void {
			_object = value;
			updateObjectTransform();
		}
	
		/**
		 * Обновляет инофрмацию о трансформации объекта. Метод следует вызывать после изменения матрицы объекта вне контролллера.
		 */
		public function updateObjectTransform():void {
			if (_object != null) objectTransform = _object.matrix.decompose();
		}
	
		/**
		 * Вычисляет новое положение объекта, используя внутренний счётчик времени.
		 */
		public function update():void {
			if (_object == null) return;
	
			var frameTime:Number = time;
			time = getTimer();
			frameTime = 0.001*(time - frameTime);
			if (frameTime > 0.1) frameTime = 0.1;
	
			var moved:Boolean = false;
	
			if (mouseLook) {
				var dx:Number = eventSource.mouseX - mousePoint.x;
				var dy:Number = eventSource.mouseY - mousePoint.y;
				mousePoint.x = eventSource.mouseX;
				mousePoint.y = eventSource.mouseY;
				var v:Vector3D = objectTransform[1];
				v.x -= dy*Math.PI/180*mouseSensitivity;
				if (v.x > maxPitch) v.x = maxPitch;
				if (v.x < minPitch) v.x = minPitch;
				v.z -= dx*Math.PI/180*mouseSensitivity;
				moved = true;
			}
	
			displacement.x = _right ? 1 : (_left ? -1 : 0);
			displacement.y = _forward ? 1 : (_back ? -1 : 0);
			displacement.z = _up ? 1 : (_down ? -1 : 0);
			if (displacement.lengthSquared > 0) {
				if (_object is Camera3D) {
					var tmp:Number = displacement.z;
					displacement.z = displacement.y;
					displacement.y = -tmp;
				}
				deltaTransformVector(displacement);
				if (_accelerate) displacement.scaleBy(speedMultiplier*speed*frameTime/displacement.length);
				else displacement.scaleBy(speed*frameTime/displacement.length);
				(objectTransform[0] as Vector3D).incrementBy(displacement);
				moved = true;
			}
	
			if (moved) {
				var m:Matrix3D = new Matrix3D();
				m.recompose(objectTransform);
				_object.matrix = m;
			}
		}
	
		/**
		 * Устанавливает позицию объекта.
		 * @param pos Объект <code>Vector3D</code>.
		 */
		public function setObjectPos(pos:Vector3D):void {
			if (_object != null) {
				var v:Vector3D = objectTransform[0];
				v.x = pos.x;
				v.y = pos.y;
				v.z = pos.z;
			}
		}
	
		/**
		 * Устанавливает позицию объекта.
		 * @param x Координата X.
		 * @param y Координата Y.
		 * @param z Координата Z.
		 */
		public function setObjectPosXYZ(x:Number, y:Number, z:Number):void {
			if (_object != null) {
				var v:Vector3D = objectTransform[0];
				v.x = x;
				v.y = y;
				v.z = z;
			}
		}
	
		/**
		 * Устанавливает направление камеры в заданную точку.
		 * @param point Объект <code>Vector3D</code>.
		 */
		public function lookAt(point:Vector3D):void {
			lookAtXYZ(point.x, point.y, point.z);
		}
	
		/**
		 * Устанавливает направление камеры в заданную точку.
		 * @param x Координата X.
		 * @param y Координата Y.
		 * @param z Координата Z.
		 */
		public function lookAtXYZ(x:Number, y:Number, z:Number):void {
			if (_object == null) return;
			var v:Vector3D = objectTransform[0];
			var dx:Number = x - v.x;
			var dy:Number = y - v.y;
			var dz:Number = z - v.z;
			v = objectTransform[1];
			v.x = Math.atan2(dz, Math.sqrt(dx*dx + dy*dy));
			if (_object is Camera3D) v.x -= 0.5*Math.PI;
			v.y = 0;
			v.z = -Math.atan2(dx, dy);
			var m:Matrix3D = _object.matrix;
			m.recompose(objectTransform);
			_object.matrix = m;
		}
	
		private var _vin:Vector.<Number> = new Vector.<Number>(3);
		private var _vout:Vector.<Number> = new Vector.<Number>(3);
	
		private function deltaTransformVector(v:Vector3D):void {
			_vin[0] = v.x;
			_vin[1] = v.y;
			_vin[2] = v.z;
			_object.matrix.transformVectors(_vin, _vout);
			var c:Vector3D = objectTransform[0];
			v.x = _vout[0] - c.x;
			v.y = _vout[1] - c.y;
			v.z = _vout[2] - c.z;
		}
	
		/**
		 * Активация движения вперёд.
		 * @param value <code>true</code> для начала движения, <code>false</code> для окончания.
		 */
		public function moveForward(value:Boolean):void {
			_forward = value;
		}
	
		/**
		 * Активация движения назад.
		 * @param value <code>true</code> для начала движения, <code>false</code> для окончания.
		 */
		public function moveBack(value:Boolean):void {
			_back = value;
		}
	
		/**
		 * Активация движения влево.
		 * @param value <code>true</code> для начала движения, <code>false</code> для окончания.
		 */
		public function moveLeft(value:Boolean):void {
			_left = value;
		}
	
		/**
		 * Активация движения вправо.
		 * @param value <code>true</code> для начала движения, <code>false</code> для окончания.
		 */
		public function moveRight(value:Boolean):void {
			_right = value;
		}
	
		/**
		 * Активация движения вверх.
		 * @param value <code>true</code> для начала движения, <code>false</code> для окончания.
		 */
		public function moveUp(value:Boolean):void {
			_up = value;
		}
	
		/**
		 * Активация движения вниз.
		 * @param value <code>true</code> для начала движения, <code>false</code> для окончания.
		 */
		public function moveDown(value:Boolean):void {
			_down = value;
		}
	
		/**
		 * Активация режима увеличенной скорости.
		 * @param value <code>true</code> для включения ускорения, <code>false</code> для выключения.
		 */
		public function accelerate(value:Boolean):void {
			_accelerate = value;
		}
	
		/**
		 * Метод выполняет привязку клавиши к действию. Одной клавише может быть назначено только одно действие.
		 * @param keyCode Код клавиши.
		 * @param action Наименование действия.
		 * @see #unbindKey()
		 * @see #unbindAll()
		 */
		public function bindKey(keyCode:uint, action:String):void {
			var method:Function = actionBindings[action];
			if (method != null) keyBindings[keyCode] = method;
		}
	
		/**
		 * Метод выполняет привязку клавиш к действиям. Одной клавише может быть назначено только одно действие.
		 * @param bindings Массив, в котором поочерёдно содержатся коды клавиш и действия.
		 */
		public function bindKeys(bindings:Array):void {
			for (var i:int = 0; i < bindings.length; i += 2) bindKey(bindings[i], bindings[i + 1]);
		}
	
		/**
		 * Очистка привязки клавиши.
		 * @param keyCode Код клавиши.
		 * @see #bindKey()
		 * @see #unbindAll()
		 */
		public function unbindKey(keyCode:uint):void {
			delete keyBindings[keyCode];
		}
	
		/**
		 * Очистка привязки всех клавиш.
		 * @see #bindKey()
		 * @see #unbindKey()
		 */
		public function unbindAll():void {
			for (var key:String in keyBindings) delete keyBindings[key];
		}
	
		/**
		 * Метод устанавливает привязки клавиш по умолчанию. Реализация по умолчанию не делает ничего.
		 * @see #bindKey()
		 * @see #unbindKey()
		 * @see #unbindAll()
		 */
		public function setDefaultBindings():void {
			bindKey(87, ACTION_FORWARD);
			bindKey(83, ACTION_BACK);
			bindKey(65, ACTION_LEFT);
			bindKey(68, ACTION_RIGHT);
			bindKey(69, ACTION_UP);
			bindKey(67, ACTION_DOWN);
			bindKey(Keyboard.SHIFT, ACTION_ACCELERATE);
	
			bindKey(Keyboard.UP, ACTION_FORWARD);
			bindKey(Keyboard.DOWN, ACTION_BACK);
			bindKey(Keyboard.LEFT, ACTION_LEFT);
			bindKey(Keyboard.RIGHT, ACTION_RIGHT);
		}
	
	}
}