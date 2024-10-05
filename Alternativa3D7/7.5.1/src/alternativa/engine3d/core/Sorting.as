package alternativa.engine3d.core {
	
	/**
	 * Класс содержит значения, позволяющие задавать режим сортировки граней полигональным объектам.
	 */
	public class Sorting {
	
		/**
		 * Грани не сортируются.
		 */
		static public const NONE:int = 0;
		
		/**
		 * Грани сортируются по средним Z.
		 */
		static public const AVERAGE_Z:int = 1;
		
		/**
		 * Грани при отрисовке образуют временное BSP-дерево.
		 */
		static public const DYNAMIC_BSP:int = 2;
	
	}
}
