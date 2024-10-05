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

		// Общее количество загружаемых частей
		private var _partsTotal:int;
		// Номер загружаемой в настоящий момент части. Нумерация начинается с нуля.
		private var _currentPart:int;
		
		/**
		 * Создаёт новый экземпляр.
		 * 
		 * @param type тип события
		 * @param totalParts общее количество загружаемых частей
		 * @param currentPart номер части, к которой относится событие. Нумерация начинается с нуля
		 */
		public function LoaderEvent(type:String, partsTotal:int, currentPart:int) {
			super(type);
			_partsTotal = partsTotal;
			_currentPart= currentPart;
		}

		/**
		 * Общее количество загружаемых частей.
		 */
		public function get partsTotal():int {
			return _partsTotal;
		}

		/**
		 * Номер загружаемой в настоящий момент части. Нумерация начинается с нуля.
		 */
		public function get currentPart():int {
			return _currentPart;
		}
		
		/**
		 * Клонирует объект.
		 * 
		 * @return клон объекта
		 */
		override public function clone():Event {
			return new LoaderEvent(type, _partsTotal, _currentPart);
		}
		
		/**
		 * Создаёт строкове представление объекта.
		 * 
		 * @return строкове представление объекта
		 */
		override public function toString():String {
			return "[LoaderEvent type=" + type + ", partsTotal=" + _partsTotal + ", currentPart=" + _currentPart + "]";
		}
		
	}
}