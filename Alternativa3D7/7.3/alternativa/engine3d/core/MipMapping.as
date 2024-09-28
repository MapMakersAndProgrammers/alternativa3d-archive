package alternativa.engine3d.core {
	
	public class MipMapping {
	
		/**
		 * Нет мипмаппинга.
		 */
		static public const NONE:int = 0;
		/**
		 * Мипмаппинг по удалённости объекта от камеры.
		 */
		static public const OBJECT_DISTANCE:int = 1;
		/**
		 * Мипмаппинг для каждой грани по удалённости от камеры.
		 */
		static public const PER_POLYGON_BY_DISTANCE:int = 2;
		/**
		 * Мипмаппинг для каждой грани по перспективному искажению рёбер.
		 */
		static public const PER_POLYGON_BY_DISTORTION:int = 3;
		/**
		 * Мипмаппинг для каждого пиксела по удалённости от камеры.
		 */
		static public const PER_PIXEL:int = 4;
	
	}
}
