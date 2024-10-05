package alternativa.engine3d.core {
	import flash.events.Event;
	
	public class MouseEvent3D extends Event {
		/**
		 * Значение свойства <code>type</code> для объекта события <code>click</code>.
		 * @eventType click
		 */
		public static const CLICK:String = "click";
		/**
		 * Значение свойства <code>type</code> для объекта события <code>doubleClick</code>.
		 * @eventType doubleClick
		 */
		public static const DOUBLE_CLICK:String = "doubleClick";
		/**
		 * Значение свойства <code>type</code> для объекта события <code>mouseDown</code>.
		 * @eventType mouseDown
		 */
		public static const MOUSE_DOWN:String = "mouseDown";
		/**
		 * Значение свойства <code>type</code> для объекта события <code>mouseUp</code>.
		 * @eventType mouseUp
		 */
		public static const MOUSE_UP:String = "mouseUp";
		/**
		 * Значение свойства <code>type</code> для объекта события <code>mouseOver</code>.
		 * @eventType mouseOver
		 */
		public static const MOUSE_OVER:String = "mouseOver";
		/**
		 * Значение свойства <code>type</code> для объекта события <code>mouseOut</code>.
		 * @eventType mouseOut
		 */
		public static const MOUSE_OUT:String = "mouseOut";
		/**
		 * Значение свойства <code>type</code> для объекта события <code>rollOver</code>.
		 * @eventType rollOver
		 */
		public static const ROLL_OVER:String = "rollOver";
		/**
		 * Значение свойства <code>type</code> для объекта события <code>rollOut</code>.
		 * @eventType rollOut
		 */
		public static const ROLL_OUT:String = "rollOut";
		/**
		 * Значение свойства <code>type</code> для объекта события <code>mouseMove</code>.
		 * @eventType mouseMove
		 */
		public static const MOUSE_MOVE:String = "mouseMove";
		/**
		 * Значение свойства <code>type</code> для объекта события <code>mouseWheel</code>.
		 * @eventType mouseWheel
		 */
		public static const MOUSE_WHEEL:String = "mouseWheel";
	
		/**
		 * Объект, с которым связано событие.
		 */
		private var _target:Object3D;
		/**
		 * Индикатор нажатой (<code>true</code>) или отпущенной (<code>false</code>) клавиши Alt.
		 */
		public var altKey:Boolean;
		/**
		 * Индикатор нажатой (<code>true</code>) или отпущенной (<code>false</code>) клавиши Control.
		 */
		public var ctrlKey:Boolean;
		/**
		 * Индикатор нажатой (<code>true</code>) или отпущенной (<code>false</code>) клавиши Shift.
		 */
		public var shiftKey:Boolean;
		/**
		 * Количество линий прокрутки при вращении колеса мыши.
		 */
		public var delta:int;
	
		public function MouseEvent3D(type:String, target:Object3D, altKey:Boolean = false, ctrlKey:Boolean = false, shiftKey:Boolean = false, delta:int = 0) {
			super(type);
			_target = target;
		}
	
		override public function get target():Object {
			return _target;
		}
	
	}
}