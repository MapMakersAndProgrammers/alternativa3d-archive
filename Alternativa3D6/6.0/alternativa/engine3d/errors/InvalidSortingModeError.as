package alternativa.engine3d.errors {
	import alternativa.engine3d.core.Space;
	import alternativa.utils.TextUtils;
	import alternativa.engine3d.sorting.SortingMode;
	
	
	/**
	 * Ошибка, обозначающая, что режим сортировки не может быть использован. 
	 */
	public class InvalidSortingModeError extends Alternativa3DError {
		/**
		 * Режим сортировки 
		 */
		public var sortingMode:uint;
		
		/**
		 * Создание экземпляра класса.
		 *  
		 * @param sortingMode режим сортировки
		 * @param source объект, в котором произошла ошибка
		 */
		public function InvalidSortingModeError(sortingMode:uint = 0, source:Object = null) {
			var message:String;
			if (source is Space) {
				message = "Space %2. ";
			} else {
/*
				if (source is Sprite3D) {
					message = "Sprite3D %2. ";
				} else {
					if (source is Sprite3D) {
						message = "Surface %2. ";
					}
				}
*/				
			}
			
			super(TextUtils.insertVars(message + "Sorting mode %1 cannot be used", sortingMode, source));
			this.sortingMode = sortingMode;
			this.name = "InvalidSortingModeError";
		}
	}
}
