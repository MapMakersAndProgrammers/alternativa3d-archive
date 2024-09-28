package alternativa.engine3d.errors {

	import alternativa.utils.TextUtils;
	
	/**
	 * Базовый класс для ошибок 3d-engine.
	 */
	public class Alternativa3DError extends Error {
		
		/**
		 * Источник ошибки - объект в котором произошла ошибка.
		 */
		public var source:Object;
		
		/**
		 * Создание экземпляра класса.
		 *  
		 * @param message описание ошибки
		 * @param source источник ошибки
		 */
		public function Alternativa3DError(message:String = "", source:Object = null) {
			super(message);
			this.source = source;
			this.name = "Alternativa3DError";
		}
	}
}
