package alternativa.engine3d.loaders.events {
	import flash.events.ErrorEvent;
	import flash.events.Event;
	
	public class LoaderErrorEvent extends ErrorEvent {
	
		public static const LOADER_ERROR:String = "loaderError";
	
		private var _url:String;
	
		/**
		 * Создаёт новый экземпляр.
		 * @param type тип события
		 * @param url адрес файла, при загрузке которого произошла проблема
		 * @param text описание ошибки
		 */
		public function LoaderErrorEvent(type:String, url:String, text:String) {
			super(type);
			this.text = text;
			_url = url;
		}
	
		/**
		 * Адрес файла, при загрузке которого произошла проблема
		 */
		public function get url():String {
			return _url;
		}
	
		/**
		 * Клонирует объект.
		 * @return клон объекта
		 */
		override public function clone():Event {
			return new LoaderErrorEvent(type, _url, text);
		}
	
		/**
		 * Создаёт строковое представление объекта.
		 * @return строковое представление объекта
		 */
		override public function toString():String {
			return "[LoaderErrorEvent url=" + _url + ", text=" + text + "]";
		}
	
	}
}

