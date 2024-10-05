package alternativa.engine3d.loaders.events {
	import flash.events.Event;
	
	/**
	 * Событие загрузчиков ресурсов, состоящих из нескольких частей.
	 */
	public class LoaderEvent extends Event {
		/**
		 * Событие начала загрузки очередной части ресурса.
		 */
		public static const PART_OPEN:String = "partOpen";
		/**
		 * Событие окончания загрузки очередной части ресурса.
		 */
		public static const PART_COMPLETE:String = "partComplete";
	
		private var _partsTotal:int;
		private var _currentPart:int;
		private var _target:Object;
	
		/**
		 * Создаёт новый экземпляр.
		 * @param type тип события
		 * @param partsTotal общее количество загружаемых частей
		 * @param currentPart номер части, к которому относится событие. Нумерация начинается с нуля
		 * @param target объект, к которому относится событие
		 */
		public function LoaderEvent(type:String, partsTotal:int, currentPart:int, target:Object = null) {
			super(type);
			_partsTotal = partsTotal;
			_currentPart = currentPart;
			_target = target;
		}
	
		/**
		 * Общее количество загружаемых частей.
		 */
		public function get partsTotal():int {
			return _partsTotal;
		}
	
		/**
		 * Номер части, к которому относится событие. Нумерация начинается с нуля
		 */
		public function get currentPart():int {
			return _currentPart;
		}
	
		/**
		 * Объект, содержащийся в событии
		 */
		override public function get target():Object {
			return _target;
		}
	
		/**
		 * Клонирует объект.
		 * @return клон объекта
		 */
		override public function clone():Event {
			return new LoaderEvent(type, _partsTotal, _currentPart, _target);
		}
	
		/**
		 * Создаёт строкове представление объекта.
		 * @return строкове представление объекта
		 */
		override public function toString():String {
			return "[LoaderEvent type=" + type + ", partsTotal=" + _partsTotal + ", currentPart=" + _currentPart + ", target=" + _target + "]";
		}
	
	}
}
