package alternativa.engine3d.materials {
	import alternativa.engine3d.*;
	import flash.display.BlendMode;
	import alternativa.engine3d.core.Space;
	import alternativa.engine3d.display.Skin;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.sorting.Primitive;
	import alternativa.types.Point3D;
	
	use namespace alternativa3d;
	
	/**
	 * Материал, заполняющий полигон сплошной одноцветной заливкой.
	 */	
	public class FillMaterial extends SurfaceMaterial {
		/**
		 * @private
		 * Цвет
		 */
		alternativa3d var _color:uint;

		// Вспомогательные массивы точек для отрисовки
		private var points1:Array = new Array();
		private var points2:Array = new Array();

		/**
		 * Создание экземпляра класса.
		 * 
		 * @param color цвет заливки
		 * @param alpha коэффициент непрозрачности материала. Значение 1 соответствует полной непрозрачности, значение 0 соответствует полной прозрачности.
		 * @param blendMode режим наложения цвета
		 */		
		public function FillMaterial(color:uint, alpha:Number = 1, blendMode:String = BlendMode.NORMAL) {
			_color = color;
			_colorTransform.alphaMultiplier = alpha;
			_blendMode = blendMode;
		}
		
		
		alternativa3d function draw(space:Space, camera:Camera3D, skin:Skin, primitive:Primitive):Boolean {
			
 			/*var i:uint;
 			var length:uint = primitive.num;
 			var point:Point3D;
			
 			// Формируем список точек полигона
			for (i = 0; i < length; i++) {	
				primitivePoint = primitive.points[i];
				point = points1[i];
				if (point == null) {
					points1[i] = new DrawPoint(primitivePoint.x, primitivePoint.y, primitivePoint.z);
				} else {
					point.x = primitivePoint.x;
					point.y = primitivePoint.y;
					point.z = primitivePoint.z;
				}
 			}*/
			
			
			return false;
		}

		/**
		 * @private
		 * @inheritDoc
		 */
		override protected function clip(length:uint, source:Array, target:Array, plane:Point3D, offset:Number):uint {
			var k:Number;
			var point:Point3D;
			var index:uint = 0;
			
			var point1:Point3D = source[length - 1];
			var offset1:Number = plane.x*point1.x + plane.y*point1.y + plane.z*point1.z - offset;
			
			for (var i:uint = 0; i < length; i++) {
				var point2:Point3D = source[i];
				var offset2:Number = plane.x*point2.x + plane.y*point2.y + plane.z*point2.z - offset;
				
				if (offset2 > 0) {
					if (offset1 <= 0) {
						k = offset2/(offset2 - offset1);
						point = target[index];
						if (point == null) {
							point = new Point3D(point2.x - (point2.x - point1.x)*k, point2.y - (point2.y - point1.y)*k, point2.z - (point2.z - point1.z)*k);
							target[index] = point;
						} else {
							point.x = point2.x - (point2.x - point1.x)*k;
							point.y = point2.y - (point2.y - point1.y)*k;
							point.z = point2.z - (point2.z - point1.z)*k;
						}
						index++;
					}
					point = target[index];
					if (point == null) {
						point = new Point3D(point2.x, point2.y, point2.z);
						target[index] = point;
					} else {
						point.x = point2.x;
						point.y = point2.y;
						point.z = point2.z;
					}
					index++;
				} else {
					if (offset1 > 0) {
						k = offset2/(offset2 - offset1);
						point = target[index];
						if (point == null) {
							point = new Point3D(point2.x - (point2.x - point1.x)*k, point2.y - (point2.y - point1.y)*k, point2.z - (point2.z - point1.z)*k);
							target[index] = point;
						} else {
							point.x = point2.x - (point2.x - point1.x)*k;
							point.y = point2.y - (point2.y - point1.y)*k;
							point.z = point2.z - (point2.z - point1.z)*k;
						}
						index++;
					}
				}
				offset1 = offset2;
				point1 = point2;
			}
				
			return index;
		}
		
		/**
		 * @private
		 * @inheritDoc
		 */		
		/*override alternativa3d function draw(camera:Camera3D, skin:Skin, length:uint, points:Array):void {
			skin.alpha = _alpha;
			skin.blendMode = _blendMode;

			var i:uint;
			var point:DrawPoint;
			var gfx:Graphics = skin.gfx;
			
			if (camera._orthographic) {
				gfx.beginFill(_color);
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
				gfx.beginFill(_color);
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
		}*/
		
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
				markToChange();
			}
		}
		
		/**
		 * @inheritDoc
		 */		
		override protected function create():Material {
			return new FillMaterial(_color);
		}
	}
}