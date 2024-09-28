package alternativa.engine3d.materials {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.core.Surface;
	
	import flash.display.BlendMode;
	import alternativa.types.Point3D;
	
	use namespace alternativa3d;

	/**
	 * Базовый класс для материалов поверхности.
	 */	
	public class SurfaceMaterial extends Material {
		/**
		 * @private
		 * Поверхность
		 */
		alternativa3d var _surface:Surface;

		/**
		 * Поверхность материала.
		 */
		public function get surface():Surface {
			return _surface;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function markToChange():void {
			if (_surface != null && _surface._mesh != null && _surface._mesh._scene != null) {
				_surface._mesh._scene.surfacesToChangeMaterial[_surface] = true;
			}
		}
		
		/**
		 * @private
		 * Отсечение полигона плоскостью.
		 */
		protected function clip(length:uint, source:Array, target:Array, plane:Point3D, offset:Number):uint {
			return 0;
		}
	}
}