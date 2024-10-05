package alternativa.engine3d.materials {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.display.Skin;
	
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import alternativa.utils.ColorUtils;
	import alternativa.engine3d.core.PolyPrimitive;
	import alternativa.engine3d.core.BSPNode;
	
	use namespace alternativa3d;
	
	/**
	 * Материал, заполняющий грань сплошной заливкой цветом в соответствии с уровнем мобильности. Помимо заливки материал может рисовать границу
	 * полигона линией заданной толщины и цвета.
	 */	
	public class DevMaterial extends SurfaceMaterial {
		/**
		 * @private
		 * Цвет
		 */
		alternativa3d var _color:uint;

		/**
		 * @private
		 * Толщина линий обводки 
		 */
		alternativa3d var _wireThickness:Number;
		
		/**
		 * @private
		 * Цвет линий обводки 
		 */
		alternativa3d var _wireColor:uint;
		
		/**
		 * Создание экземпляра класса.
		 * 
		 * @param color цвет заливки
		 * @param alpha прозрачность
		 * @param blendMode режим наложения цвета
		 * @param wireThickness толщина линии обводки
		 * @param wireColor цвет линии обводки
		 */		
		public function DevMaterial(color:uint = 0xFFFFFF, alpha:Number = 1, blendMode:String = BlendMode.NORMAL, wireThickness:Number = -1, wireColor:uint = 0) {
			super(alpha, blendMode);
			_color = color;
			_wireThickness = wireThickness;
			_wireColor = wireColor;
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
			
			/*
			//Мобильность
			var param:int = skin.primitive.mobility*10;
			*/
			
			/*
			// Уровень распиленности
			var param:int = 0;
			var prm:PolyPrimitive = skin.primitive;
			while (prm != null) {
				prm = prm.parent;
				param++;
			}
			param *= 10;
			*/

			// Уровень в BSP-дереве
			var param:int = 0;
			var node:BSPNode = skin.primitive.node;
			while (node != null) {
				node = node.parent;
				param++;
			}
			param *= 5;
			
			var c:uint = ColorUtils.rgb(param, param, param);
			
			if (camera._orthographic) {
				gfx.beginFill(c);
				if (_wireThickness >= 0) {
					gfx.lineStyle(_wireThickness, _wireColor);
				}
				point = points[0];
				gfx.moveTo(point.x, point.y);
				for (i = 1; i < length; i++) {
					point = points[i];
					gfx.lineTo(point.x, point.y);
				}
				if (_wireThickness >= 0) {
					point = points[0];
					gfx.lineTo(point.x, point.y);
				}
			} else {
				gfx.beginFill(c);
				if (_wireThickness >= 0) {
					gfx.lineStyle(_wireThickness, _wireColor);
				}
				point = points[0];
				var perspective:Number = camera.focalLength/point.z;
				gfx.moveTo(point.x*perspective, point.y*perspective);
				for (i = 1; i < length; i++) {
					point = points[i];
					perspective = camera.focalLength/point.z;
					gfx.lineTo(point.x*perspective, point.y*perspective);
				}
				if (_wireThickness >= 0) {
					point = points[0];
					perspective = camera.focalLength/point.z;
					gfx.lineTo(point.x*perspective, point.y*perspective);
				}
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
		 * Толщина линии обводки. Если значение отрицательное, то отрисовка линии не выполняется.
		 */
		public function get wireThickness():Number {
			return _wireThickness;
		}
		
		/**
		 * @private
		 */		
		public function set wireThickness(value:Number):void {
			if (_wireThickness != value) {
				_wireThickness = value;
				if (_surface != null) {
					_surface.addMaterialChangedOperationToScene();
				}
			}
		}

		/**
		 * Цвет линии обводки.
		 */
		public function get wireColor():uint {
			return _wireColor;
		}
		
		/**
		 * @private
		 */		
		public function set wireColor(value:uint):void {
			if (_wireColor != value) {
				_wireColor = value;
				if (_surface != null) {
					_surface.addMaterialChangedOperationToScene();
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */		
		override public function clone():Material {
			var res:DevMaterial = new DevMaterial(_color, _alpha, _blendMode, _wireThickness, _wireColor); 
			return res;
		}
	}
}