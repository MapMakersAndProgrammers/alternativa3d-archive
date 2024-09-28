package alternativa.engine3d.core {
	
	public class BackfaceCulling {
		
		/**
		 * Грань рисуется с обеих сторон. 
		 */
		static public const NONE:int = 0;
		/**
		 * Отсечение нативными механизмами на этапе отрисовки треугольников.  
		 */
		static public const NATIVE:int = 1;
		/**
		 * Отсечение по предрасчитанным нормалям. 
		 */
		static public const CALCULATED_NORMALS:int = 2;
		/**
		 * Отсечение по динамически расчитываемым нормалям. 
		 */
		static public const DYNAMIC_NORMALS:int = 3;
		
	}
}