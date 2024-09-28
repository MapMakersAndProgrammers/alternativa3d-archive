package alternativa.engine3d.materials {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Sprite3D;

	use namespace alternativa3d;
	
	/**
	 * Базовый класс для материалов спрайтов.
	 */	
	public class SpriteMaterial extends Material {
		/**
		 * @private
		 * Спрайт
		 */
		alternativa3d var _sprite:Sprite3D;

		/**
		 * @inheritDoc
		 */
		override protected function markToChange():void {
			if (_sprite != null && _sprite._scene != null) {
				_sprite._scene.spritesToChangeMaterial[_sprite] = true;
			}
		}
		
	}
}