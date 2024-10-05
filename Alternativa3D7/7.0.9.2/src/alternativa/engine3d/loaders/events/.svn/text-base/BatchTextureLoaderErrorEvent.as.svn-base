package alternativa.engine3d.loaders.events {
	import flash.events.ErrorEvent;
	import flash.events.Event;

	/**
	 * Класс представляет событие ошибки, генерируемое пакетным загрузчиком текстур.
	 */
	public class BatchTextureLoaderErrorEvent extends ErrorEvent {
		
		/**
		 * 
		 */
		public static const LOADER_ERROR:String = "loaderError";
		
		// Имя текстуры, с которой произошла проблема
		private var _textureName:String;
		
		/**
		 * Создаёт новый экземпляр.
		 * 
		 * @param type тип события
		 * @param textureName имя текстуры, с которой произошла проблема
		 * @param text описание ошибки
		 */
		public function BatchTextureLoaderErrorEvent(type:String, textureName:String, text:String) {
			super(type);
			this.text = text;
			_textureName = textureName;
		}
		
		/**
		 * Имя текстуры, с которой произошла проблема.
		 */
		public function get textureName():String {
			return _textureName;
		}
		
		/**
		 * Клонирует объект.
		 * 
		 * @return клон объекта
		 */
		override public function clone():Event {
			return new BatchTextureLoaderErrorEvent(type, _textureName, text);
		}
		
		/**
		 * Создаёт строкове представление объекта.
		 * 
		 * @return строкове представление объекта
		 */
		override public function toString():String {
			return "[BatchTextureLoaderErrorEvent textureName=" + _textureName + ", text=" + text + "]";
		}
		
	}
}