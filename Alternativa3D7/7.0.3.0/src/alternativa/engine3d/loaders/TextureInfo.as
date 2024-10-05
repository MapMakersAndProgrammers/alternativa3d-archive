package alternativa.engine3d.loaders {

	/**
	 * Структура для хранения имён файла диффузной текстуры и файла карты прозрачности.
	 */
	public class TextureInfo {
		/**
		 * Имя файла диффузной текстуры.
		 */		
		public var diffuseMapFileName:String;
		/**
		 * Имя файла карты прозрачности.
		 */
		public var opacityMapFileName:String;
		
		/**
		 * Создаёт новый экземпляр.
		 * 
		 * @param diffuseMapFileName имя файла диффузной текстуры
		 * @param opacityMapFileName имя файла карты прозрачности
		 */
		public function TextureInfo(diffuseMapFileName:String = null, opacityMapFileName:String = null) {
			this.diffuseMapFileName = diffuseMapFileName;
			this.opacityMapFileName = opacityMapFileName;
		}
		
		/**
		 * Создаёт строковое представление объекта.
		 * 
		 * @return строковое представление объекта
		 */
		public function toString():String {
			return "[TextureInfo diffuseMapFileName=" + diffuseMapFileName + ", opacityMapFileName=" + opacityMapFileName + "]";
		}
	}
}