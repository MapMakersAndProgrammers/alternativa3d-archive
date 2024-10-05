package alternativa.engine3d.materials {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.display.Skin;
	
	import flash.display.BlendMode;
	import flash.display.Graphics;
	
	use namespace alternativa3d;
	
	/**
	 * Материал, заполняющий грань сплошной одноцветной заливкой.
	 */	
	public class FillMaterial extends SurfaceMaterial {
		/**
		 * @private
		 * Цвет
		 */
		alternativa3d var _color:uint;
		
		/**
		 * Создание экземпляра класса.
		 * 
		 * @param color цвет заливки
		 * @param alpha прозрачность
		 * @param blendMode режим наложения цвета
		 */		
		public function FillMaterial(color:uint, alpha:Number = 1, blendMode:String = BlendMode.NORMAL) {
			super(alpha, blendMode);
			_color = color;
		}
		
		/**
		 * @private
		 * 
		 * @param camera
		 * @param skin
		 * @param length
		 * @param points
		 */		
		override alternativa3d function draw(camera:Camera3D, skin:Skin, length:uint, points:Array):void {
			skin.alpha = _alpha;
			skin.blendMode = _blendMode;

			var i:uint;
			var point:DrawPoint;
			var gfx:Graphics = skin.gfx;
			
			if (camera._orthographic) {
				gfx.beginFill(_color);
				point = points[0];
				gfx.moveTo(point.x, point.y);
				for (i = 1; i < length; i++) {
					point = points[i];
					gfx.lineTo(point.x, point.y);
				}
			} else {
				gfx.beginFill(_color);
				//gfx.lineStyle(0, 0);
				point = points[0];
				var perspective:Number = camera.focalLength/point.z;
				gfx.moveTo(point.x*perspective, point.y*perspective);
				for (i = 1; i < length; i++) {
					point = points[i];
					perspective = camera.focalLength/point.z;
					gfx.lineTo(point.x*perspective, point.y*perspective);
				}
				//point = points[0];
				//perspective = camera.focalLength/point.z;
				//gfx.lineTo(point.x*perspective, point.y*perspective);
			}			
		}
		
		/**
		 * Цвет заливки.
		 */
		public function get color():uint {
			return _color;
		}

		/**
		 * @private
		 */
		public function set color(value:uint):void {
			if (_color != value) {
				_color = value;
				if (_surface != null) {
					_surface.addMaterialChangedOperationToScene();
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */		
		override public function clone():Material {
			return new FillMaterial(_color, _alpha, _blendMode);
		}
	}
}