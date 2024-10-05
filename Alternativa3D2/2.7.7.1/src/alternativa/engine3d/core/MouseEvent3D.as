package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
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
		 * Индикатор нажатой (<code>true</code>) или отпущенной (<code>false</code>) клавиши Control.
		 */
		public var ctrlKey:Boolean;
		/**
		 * Индикатор нажатой (<code>true</code>) или отпущенной (<code>false</code>) клавиши Alt.
		 */
		public var altKey:Boolean;
		/**
		 * Индикатор нажатой (<code>true</code>) или отпущенной (<code>false</code>) клавиши Shift.
		 */
		public var shiftKey:Boolean;
		/**
		 * Индикатор нажатой (<code>true</code>) или отпущенной (<code>false</code>) основной кнопки мыши.
		 */
		public var buttonDown:Boolean;
		/**
		 * Количество линий прокрутки при вращении колеса мыши.
		 */
		public var delta:int;
	
		/**
		 * Ссылка на объект, связанный с событием. Например, когда происходит событие <code>mouseOut</code>, <code>relatedObject</code> представляет объект, на который теперь показывает указатель.
		 * Это свойство применяется к событиям <code>mouseOut</code>, <code>mouseOver</code>, <code>rollOut</code> и <code>rollOver</code>.
		 */
		public var relatedObject:Object3D;
		
		/**
		 * Начало луча в локальных координатах объекта, связанного с событием.
		 * Луч может быть использован в методе <code>intersectRay()</code> трёхмерных объектов.
		 */
		public var localOrigin:Vector3D = new Vector3D();

		/**
		 * Направление луча в локальных координатах объекта, связанного с событием.
		 * Луч может быть использован в методе <code>intersectRay()</code> трёхмерных объектов.
		 */
		public var localDirection:Vector3D = new Vector3D();
		
		/**
		 * @private 
		 */
		alternativa3d var _target:Object3D;
		
		/**
		 * @private 
		 */
		alternativa3d var _currentTarget:Object3D;
		
		/**
		 * @private 
		 */
		alternativa3d var _bubbles:Boolean;
		
		/**
		 * @private 
		 */
		alternativa3d var _eventPhase:uint = 3;
		
		/**
		 * @private 
		 */
		alternativa3d var stop:Boolean = false;
		
		/**
		 * @private 
		 */
		alternativa3d var stopImmediate:Boolean = false;
		
		/**
		 * Создаёт новый экземпляр трёхмерного события мыши.
		 * @param type Тип события.
		 * @param bubbles Определяет, участвует ли событие в фазе восходящей цепочки процесса события.
		 * @param relatedObject Дополняющий экземпляр <code>Object3D</code>, на который влияет событие.
		 * @param altKey Указывает, активирована ли клавиша Alt.
		 * @param ctrlKey Указывает, активирована ли клавиша Control.
		 * @param shiftKey Указывает, активирована ли клавиша Shift.
		 * @param buttonDown Указывает, нажата ли основная кнопка мыши.
		 * @param delta Показывает расстояние прокрутки в строках на единицу вращения колесика мыши.
		 */
		public function MouseEvent3D(type:String, bubbles:Boolean = true, relatedObject:Object3D = null, altKey:Boolean = false, ctrlKey:Boolean = false, shiftKey:Boolean = false, buttonDown:Boolean = false, delta:int = 0) {
			super(type, bubbles);
			this.relatedObject = relatedObject;
			this.altKey = altKey;
			this.ctrlKey = ctrlKey;
			this.shiftKey = shiftKey;
			this.buttonDown = buttonDown;
			this.delta = delta;
		}
		
		/**
		 * @private
		 */
		alternativa3d function calculateLocalRay(mouseX:Number, mouseY:Number, object:Object3D, camera:Camera3D):void {
			// Расчёт глобального луча камеры
			camera.calculateRay(localOrigin, localDirection, mouseX, mouseY);
			// Расчёт инверсной матрицы объекта
			object.composeMatrix();
			var root:Object3D = object;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				object.appendMatrix(root);
			}
			object.invertMatrix();
			// Перевод луча в объект
			var ox:Number = localOrigin.x;
			var oy:Number = localOrigin.y;
			var oz:Number = localOrigin.z;
			var dx:Number = localDirection.x;
			var dy:Number = localDirection.y;
			var dz:Number = localDirection.z;
			localOrigin.x = object.ma*ox + object.mb*oy + object.mc*oz + object.md;
			localOrigin.y = object.me*ox + object.mf*oy + object.mg*oz + object.mh;
			localOrigin.z = object.mi*ox + object.mj*oy + object.mk*oz + object.ml;
			localDirection.x = object.ma*dx + object.mb*dy + object.mc*dz;
			localDirection.y = object.me*dx + object.mf*dy + object.mg*dz;
			localDirection.z = object.mi*dx + object.mj*dy + object.mk*dz;
		}
		
		/**
		 * Определяет, является ли событие "событием на цепочке". Если событие может переходить пузырем вверх по цепочке, то значение — <code>true</code>; иначе — <code>false</code>.
		 */
		override public function get bubbles():Boolean {
			return _bubbles;
		}
		
		/**
		 * Текущая фаза в потоке событий. Это свойство может содержать следующие численные значения: фаза захвата (<code>EventPhase.CAPTURING_PHASE</code>), фаза цели (<code>EventPhase.AT_TARGET</code>), фаза пузырей (<code>EventPhase.BUBBLING_PHASE</code>).
		 */
		override public function get eventPhase():uint {
			return _eventPhase;
		}
		
		/**
		 * Объект, с которым связано событие.
		 */
		override public function get target():Object {
			return _target;
		}
	
		/**
		 * Объект в цепочке иерархии, обрабатывающий событие в данный момент.
		 */
		override public function get currentTarget():Object {
			return _currentTarget;
		}
		
		/**
		 * Отменяет обработку прослушивателей событий в узлах, которые следуют в потоке событий за текущим узлом.
		 * Этот метод не влияет на прослушивателей событий в текущем узле (<code>currentTarget</code>).
		 */
		override public function stopPropagation():void {
			stop = true;
		}
		
		/**
		 * Отменяет обработку прослушивателей событий в текущем узле, а также во всех узлах, которые следуют в потоке событий за текущим узлом.
		 */
		override public function stopImmediatePropagation():void {
			stopImmediate = true;
		}
		
		/**
		 * Создает копию объекта MouseEvent3D и задает значение каждого свойства, совпадающее с оригиналом.
		 * @return Новый объект MouseEvent3D, значения свойств которого соответствуют значениям оригинала.
		 */
		override public function clone():Event {
			return new MouseEvent3D(type, _bubbles, relatedObject, altKey, ctrlKey, shiftKey, buttonDown, delta);
		}
		
		/**
		 * Возвращает строку, содержащую все свойства объекта MouseEvent3D.
		 * @return Строка, содержащая все свойства объекта MouseEvent3D.
		 */
		override public function toString():String {
			return formatToString("MouseEvent3D", "type", "bubbles", "eventPhase", "relatedObject", "altKey", "ctrlKey", "shiftKey", "buttonDown", "delta");
		}
		
	}
}