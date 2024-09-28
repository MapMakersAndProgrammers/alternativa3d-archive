package alternativa.engine3d.sorting {

	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Space;
	
	use namespace alternativa3d;
	
	public class Node {
		
		// Уровень
		alternativa3d var sortingLevel:SortingLevel;
		
		// Родительская нода
		alternativa3d var parent:BSPNode;
		
	}
}