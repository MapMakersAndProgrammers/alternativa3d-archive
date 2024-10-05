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
	
		private var _filesTotal:int;
		private var _filesLoaded:int;
		private var _totalProgress:Number = 0;
	
		/**
		 * Создаёт новый экземпляр.
		 * @param type тип события
		 * @param filesTotal общее количество загружаемых файлов
		 * @param filesLoaded количество полностью загруженных файлов
		 * @param totalProgress общий прогресс загрузки, выраженный числом в интервале [0, 1]
		 * @param bytesLoaded количество загруженных байт загружаемого в данный момент файла
		 * @param bytesTotal объём загружаемого в данный момент файла
		 */
		public function LoaderProgressEvent(type:String, filesTotal:int, filesLoaded:int, totalProgress:Number = 0, bytesLoaded:uint = 0, bytesTotal:uint = 0) {
			super(type, false, false, bytesLoaded, bytesTotal);
			_filesTotal = filesTotal;
			_filesLoaded = filesLoaded;
			_totalProgress = totalProgress;
		}
	
		/**
		 * Общее количество загружаемых файлов.
		 */
		public function get filesTotal():int {
			return _filesTotal;
		}
	
		/**
		 * Количество полностью загруженных файлов.
		 */
		public function get filesLoaded():int {
			return _filesLoaded;
		}
	
		/**
		 * Общий прогресс загрузки, выраженный числом в интервале [0, 1].
		 */
		public function get totalProgress():Number {
			return _totalProgress;
		}
	
		/**
		 * Клонирует объект.
		 * @return клон объекта
		 */
		override public function clone():Event {
			return new LoaderProgressEvent(type, _filesTotal, _filesLoaded, _totalProgress, bytesLoaded, bytesTotal);
		}
	
		/**
		 * Создаёт строкове представление объекта.
		 * @return строкове представление объекта
		 */
		override public function toString():String {
			return "[LoaderProgressEvent filesTotal=" + _filesTotal + ", filesLoaded=" + _filesLoaded + ", totalProgress=" + _totalProgress.toFixed(2) + "]";
		}
	
	}
}
