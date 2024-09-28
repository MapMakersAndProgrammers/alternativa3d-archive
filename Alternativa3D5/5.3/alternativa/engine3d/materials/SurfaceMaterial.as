package alternativa.engine3d.materials {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.PolyPrimitive;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.core.Surface;
	import alternativa.engine3d.display.Skin;
	
	import flash.display.BlendMode;
	
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
		 * @private
		 * Альфа
		 */
		alternativa3d var _alpha:Number;
		/**
		 * @private
		 * Режим наложения
		 */
		alternativa3d var _blendMode:String = BlendMode.NORMAL;
		/**
		 * @private
		 * Материал использует информация об UV-координатах
		 */
		alternativa3d var useUV:Boolean = false;

		/**
		 * Создание экземпляра класса.
		 * 
		 * @param alpha прозрачность материала
		 * @param blendMode режим наложения цвета
		 */
		public function SurfaceMaterial(alpha:Number = 1, blendMode:String = BlendMode.NORMAL) {
			_alpha = alpha;
			_blendMode = blendMode;
		}

		/**
		 * Поверхность материала.
		 */
		public function get surface():Surface {
			return _surface;
		}
		
		/**
		 * @private
		 * Добавление на сцену
		 * 
		 * @param scene
		 */		
		alternativa3d function addToScene(scene:Scene3D):void {}
		
		/**
		 * @private
		 * Удаление из сцены
		 * 
		 * @param scene
		 */
		alternativa3d function removeFromScene(scene:Scene3D):void {}
		
		/**
		 * @private
		 * Добавление к мешу
		 * 
		 * @param mesh
		 */
		alternativa3d function addToMesh(mesh:Mesh):void {}
		
		/**
		 * @private
		 * Удаление из меша
		 * 
		 * @param mesh
		 */
		alternativa3d function removeFromMesh(mesh:Mesh):void {}
		
		/**
		 * @private
		 * Добавление на поверхность
		 * 
		 * @param surface
		 */
		alternativa3d function addToSurface(surface:Surface):void {
			// Сохраняем поверхность
			_surface = surface;
		}

		/**
		 * @private
		 * Удаление с поверхности
		 * 
		 * @param surface
		 */
		alternativa3d function removeFromSurface(surface:Surface):void {
			// Удаляем ссылку на поверхность
			_surface = null;
		}

		/**
		 * Прозрачность материала.
		 */		
		public function get alpha():Number {
			return _alpha;
		}

		/**
		 * @private
		 */		
		public function set alpha(value:Number):void {
			if (_alpha != value) {
				_alpha = value;
				if (_surface != null) {
					_surface.addMaterialChangedOperationToScene();
				}
			}
		}
		
		/**
		 * Режим наложения цвета.
		 */		
		public function get blendMode():String {
			return _blendMode;
		}
				
		/**
		 * @private
		 */		
		public function set blendMode(value:String):void {
			if (_blendMode != value) {
				_blendMode = value;
				if (_surface != null) {
					_surface.addMaterialChangedOperationToScene();
				}
			}
		}
		
		/**
		 * @private
		 */		
		alternativa3d function canDraw(primitive:PolyPrimitive):Boolean {
			return true;
		}

		/**
		 * @private
		 */
		alternativa3d function clear(skin:Skin):void {
			skin.gfx.clear();
		}
		
		/**
		 * @private
		 */		
		alternativa3d function draw(camera:Camera3D, skin:Skin, length:uint, points:Array):void {
			skin.alpha = _alpha;
			skin.blendMode = _blendMode;
		}
		
		/**
		 * @inheritDoc
		 */		
		override public function clone():Material {
			return new SurfaceMaterial(_alpha, _blendMode);
		}
	}
}