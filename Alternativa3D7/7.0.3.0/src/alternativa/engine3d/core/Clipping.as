package alternativa.engine3d.core {
	
	public class Clipping {
				
		/**
		 * Объект отсекается целиком, если он полностью вне пирамиды видимости или пересекает nearClipping камеры. 
		 */
		static public const OBJECT_CULLING:int = 0;
		/**
		 * Грань отсекается целиком, если она полностью вне пирамиды видимости или пересекает nearClipping камеры. 
		 */
		static public const FACE_CULLING:int = 1;
		/**
		 * Грань подрезается пирамидой видимости камеры. 
		 */
		static public const FACE_CLIPPING:int = 2;

	}
}