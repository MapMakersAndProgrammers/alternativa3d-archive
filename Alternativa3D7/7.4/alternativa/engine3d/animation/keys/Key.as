package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;
	
	use namespace alternativa3d;
	
	/**
	 * Ключевой кадр. 
	 */
	public class Key {

		/**
		 * Время кадра. 
		 */
		public var time:Number;
		/**
		 * Ссылка на следующий ключевой кадр на верменной шкале.
		 * 
		 * @see alternativa.engine3d.animation.Track
		 */
		public var next:Key;

		/**
		 * Создает экземпляр ключевого кадра.
		 *  
		 * @param time время кадра.
		 */
		public function Key(time:Number) {
			this.time = time;
		}

		/**
		 * @private 
		 */
		alternativa3d function interpolate(time:Number, next:Key, key:Key = null):Key {
			return key;
		}

	}
}
