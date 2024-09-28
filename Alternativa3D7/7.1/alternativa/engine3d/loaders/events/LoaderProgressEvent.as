package alternativa.engine3d.loaders.events {
	import flash.events.Event;
	import flash.events.ProgressEvent;

	/**
	 * Событие прогресса загрузки ресурсов, состоящих из нескольких частей.
	 */
	public class LoaderProgressEvent extends ProgressEvent {
		
		/**
		 * Событие прогресса загрузки очередной части ресурса.
		 */
		public static const LOADER_PROGRESS:String = "loaderProgress";
		
		// Общее количество загружаемых частей
		private var _partsTotal:int;
		// Номер загружаемой в настоящий момент части. Нумерация начинается с нуля.
		private var _currentPart:int;
		// Общий прогресс загрузки, выраженный числом в интервале [0, 1] 
		private var _totalProgress:Number = 0;
		
		/**
		 * Создаёт новый экземпляр.
		 * 
		 * @param type тип события
		 * @param totalParts общее количество загружаемых частей
		 * @param currentPart номер загружаемой в настоящий момент части. Нумерация начинается с нуля
		 * @param totalProgress общий прогресс загрузки, выраженный числом в интервале [0, 1]
		 * @param bytesLoaded количество загруженных байт текущей части
		 * @param bytesTotal объём текущей части
		 */
		public function LoaderProgressEvent(type:String, partsTotal:int, currentPart:int, totalProgress:Number = 0, bytesLoaded:uint=0, bytesTotal:uint=0) {
			super(type, false, false, bytesLoaded, bytesTotal);
			_partsTotal = partsTotal;
			_currentPart= currentPart;
			_totalProgress = totalProgress;
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
		 * Общий прогресс загрузки, выраженный числом в интервале [0, 1]. 
		 */
		public function get totalProgress():Number {
			return _totalProgress;
		}
		
		/**
		 * Клонирует объект.
		 * 
		 * @return клон объекта
		 */
		override public function clone():Event {
			return new LoaderProgressEvent(type, _partsTotal, _currentPart, _totalProgress, bytesLoaded, bytesTotal);
		}
		
		/**
		 * Создаёт строкове представление объекта.
		 * 
		 * @return строкове представление объекта
		 */
		override public function toString():String {
			return "[LoaderProgressEvent partsTotal=" + _partsTotal + ", currentPart=" + _currentPart + ", totalProgress=" + _totalProgress.toFixed(2) + "]";
		}
		
	}
}