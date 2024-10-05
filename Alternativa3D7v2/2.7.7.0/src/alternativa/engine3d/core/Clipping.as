package alternativa.engine3d.core {
	
	/**
	 * Класс содержит значения, позволяющие задавать режим отсечения полигональным объектам.
	 */
	public class Clipping {
	
		/**
		 * Объект отсекается целиком, если он полностью вне пирамиды видимости камеры или пересекает <code>nearClipping</code> камеры.
		 */
		static public const BOUND_CULLING:int = 0;
		
		/**
		 * Грань отсекается целиком, если она полностью вне пирамиды видимости камеры или пересекает <code>nearClipping</code> камеры.
		 */
		static public const FACE_CULLING:int = 1;
		
		/**
		 * Грань подрезается пирамидой видимости камеры.
		 */
		static public const FACE_CLIPPING:int = 2;
	
	}
}
