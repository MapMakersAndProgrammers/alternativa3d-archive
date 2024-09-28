package alternativa.engine3d.materials {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Space;
	
	import flash.filters.BitmapFilter;

	use namespace alternativa3d;
	
	/**
	 * Базовый класс для материалов пространства.
	 */	
	public class SpaceMaterial extends Material	{
		/**
		 * @private
		 * Пространство
		 */
		alternativa3d var _space:Space;
		
		/**
		 * @private
		 * Фильтры
		 */
		alternativa3d var _filters:Array = new Array();

		/**
		 * Фильтры.
		 */
		public function get filters():Array {
			return new Array().concat(_filters);
		}
		/**
		 * @private
		 */		
		public function set filters(value:Array):void {
			var i:uint;
			var length:uint;
			length = _filters.length;
			for (i = 0; i < length; i++) {
				_filters.pop();
			}
			if (value != null) {
				length = value.length;
				for (i = 0; i < length; i++) {
					if (value[i] is BitmapFilter) {
						_filters.push(value[i]);
					} else {
						throw new ArgumentError("Parameter 0 is of the incorrect type. Should be type Filter.");
					}
				}
			}
			markToChange();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function markToChange():void {
			if (_space != null && _space._scene != null) {
				_space._scene.spacesToChangeMaterial[_space] = true;
			}
		}
		
		
	}
}