package alternativa.engine3d.loaders.events {
	import flash.events.ErrorEvent;
	import flash.events.Event;
	
	/**
	 * Событие, рассылаемое при ошибке загрузки.
	 */
	public class LoaderErrorEvent extends ErrorEvent {
	
		/**
		 * Событие рассылается, когда происходит ошибка загрузки.
		 */
		public static const LOADER_ERROR:String = "loaderError";
	
		private var _url:String;
	
		/**
		 * Создаёт новый экземпляр.
		 * @param type Тип события.
		 * @param url Адрес файла, при загрузке которого произошла проблема.
		 * @param text Описание ошибки.
		 */
		public function LoaderErrorEvent(type:String, url:String, text:String) {
			super(type);
			this.text = text;
			_url = url;
		}
	
		/**
		 * Адрес файла, при загрузке которого произошла проблема.
		 */
		public function get url():String {
			return _url;
		}
	
		/**
		 * Клонирует объект.
		 * @return Точная копия объекта.
		 */
		override public function clone():Event {
			return new LoaderErrorEvent(type, _url, text);
		}
	
		/**
		 * Создаёт строковое представление объекта.
		 * @return Строковое представление объекта.
		 */
		override public function toString():String {
			return "[LoaderErrorEvent url=" + _url + ", text=" + text + "]";
		}
	
	}
}

