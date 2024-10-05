package alternativa.engine3d.materials {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.PolyPrimitive;
	import alternativa.engine3d.display.Skin;
	import alternativa.types.*;
	
	import flash.display.BlendMode;
	import flash.geom.Matrix;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	
	use namespace alternativa3d;
	use namespace alternativatypes;
	
	/**
	 * Материал, заполняющий грань текстурой. Помимо наложения текстуры, материал может рисовать границу грани линией
	 * заданной толщины и цвета.
	 */	
	public class TextureMaterial extends SurfaceMaterial {

		private static var stubBitmapData:BitmapData;
		private static var stubMatrix:Matrix;
		
		private var gfx:Graphics;
		private var textureMatrix:Matrix = new Matrix();
		private var focalLength:Number;
		private var distortion:Number;
		
		/**
		 * @private
		 * Текстура
		 */		
		alternativa3d var _texture:Texture;
		/**
		 * @private
		 * Повтор текстуры
		 */		
		alternativa3d var _repeat:Boolean;
		/**
		 * @private
		 * Сглаженность текстуры
		 */		
		alternativa3d var _smooth:Boolean;
		/**
		 * @private
		 * Точность перспективной коррекции
		 */		
		alternativa3d var _precision:Number;
		
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
		 * Создание экземпляра текстурного материала.
		 * 
		 * @param texture текстура материала
		 * @param alpha коэффициент непрозрачности материала. Значение 1 соответствует полной непрозрачности, значение 0 соответствует полной прозрачности.
		 * @param repeat повтор текстуры при заполнении
		 * @param smooth сглаживание текстуры при увеличении масштаба
		 * @param blendMode режим наложения цвета
		 * @param wireThickness толщина линии обводки
		 * @param wireColor цвет линии обводки
		 * @param precision точность перспективной коррекции. Может быть задана одной из констант класса
		 *   <code>TextureMaterialPrecision</code> или числом типа Number. Во втором случае, чем ближе заданное значение к единице, тем более
		 *   качественная перспективная коррекция будет выполнена, и тем больше времени будет затрачено на расчёт кадра.
		 * 
		 * @see TextureMaterialPrecision
		 */
		public function TextureMaterial(texture:Texture, alpha:Number = 1, repeat:Boolean = true, smooth:Boolean = false, blendMode:String = BlendMode.NORMAL, wireThickness:Number = -1, wireColor:uint = 0, precision:Number = TextureMaterialPrecision.MEDIUM) {
			super(alpha, blendMode);
			_texture = texture;
			_repeat = repeat;
			_smooth = smooth;
			_wireThickness = wireThickness;
			_wireColor = wireColor;
			_precision = precision;
			useUV = true;
		}

		/**
		 * @private
		 * Метод определяет, может ли материал нарисовать указанный примитив. Метод используется в системе отрисовки сцены и должен использоваться
		 * наследниками для указания видимости связанной с материалом поверхности или отдельного примитива.
		 * 
		 * @param primitive примитив для проверки
		 * 
		 * @return <code>true</code>, если материал может отрисовать указанный примитив, иначе <code>false</code>
		 */
		override alternativa3d function canDraw(primitive:PolyPrimitive):Boolean {
			return _texture != null;
		}

		/**
		 * @private
		 * @inheritDoc
		 */
		override alternativa3d function draw(camera:Camera3D, skin:Skin, length:uint, points:Array):void {
			skin.alpha = _alpha;
			skin.blendMode = _blendMode;
			
			var i:uint;
			var point:DrawPoint;
			gfx = skin.gfx;
			
			// Проверка на нулевую UV-матрицу
			if (skin.primitive.face.uvMatrixBase == null) {
				if (stubBitmapData == null) {
					// Создание текстуры-заглушки
					stubBitmapData = new BitmapData(2, 2, false, 0);
					stubBitmapData.setPixel(0, 0, 0xFF00FF);
					stubBitmapData.setPixel(1, 1, 0xFF00FF);
					stubMatrix = new Matrix(10, 0, 0, 10, 0, 0);
				}				
				gfx.beginBitmapFill(stubBitmapData, stubMatrix);
				if (camera._orthographic) {
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
				return;
			}
			
			if (camera._orthographic) {
				// Расчитываем матрицу наложения текстуры
				var face:Face = skin.primitive.face;
				// Если матрица не расчитана, считаем
				if (!camera.uvMatricesCalculated[face]) {
					camera.calculateUVMatrix(face, _texture._width, _texture._height);
				}
				gfx.beginBitmapFill(_texture._bitmapData, face.uvMatrix, _repeat, _smooth);
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
				// Отрисовка
				focalLength = camera.focalLength;
				//distortion = camera.focalDistortion*_precision;
				
				var front:int = 0;
				var back:int = length - 1;

				var newFront:int = 1;
				var newBack:int = (back > 0) ? (back - 1) : (length - 1);
				var direction:Boolean = true;
				
				var a:DrawPoint = points[back];
				var b:DrawPoint;
				var c:DrawPoint = points[front];
				
				var drawVertices:Vector.<Number> = new Vector.<Number>();
				var drawUVTs:Vector.<Number> = new Vector.<Number>();
				
				for (i = 0; i < length; i++) {
					var p:DrawPoint = points[i];
					var t:Number = focalLength/p.z;
					drawVertices[i << 1] = p.x*t;
					drawVertices[(i << 1) + 1] = p.y*t;
					drawUVTs.push(p.u, 1 - p.v, t);
				}
				
				var drawIndices:Vector.<int> = new Vector.<int>();

				while (front != newBack) {
					if (direction) {
/* 						a = points[front];
						b = points[newFront];
						c = points[back];
 */
						drawIndices.push(front, newFront, back);

						front = newFront;
						newFront = (front < length - 1) ? (front + 1) : 0;
					} else {
/* 						a = points[newBack];
						b = points[back];
						c = points[front];
 */
						drawIndices.push(newBack, back, front);

						back = newBack;
						newBack = (back > 0) ? (back - 1) : (length - 1);
					}

					direction = !direction;
				}
				gfx.beginBitmapFill(_texture.bitmapData, null, _repeat, _smooth);
				if (_wireThickness >= 0) {
					gfx.lineStyle(_wireThickness, _wireColor);
				}
				gfx.drawTriangles(drawVertices, drawIndices, drawUVTs);
				
			}
		}
		
		
		/**
		 * Текстура материала. Материал не выполняет никаких действий по отрисовке, если не задана текстура.
		 */
		public function get texture():Texture {
			return _texture;
		}

		/**
		 * @private
		 */
		public function set texture(value:Texture):void {
			if (_texture != value) {
				_texture = value;
				if (_surface != null) {
					_surface.addMaterialChangedOperationToScene();
				}
			}
		}

		/**
		 * Повтор текстуры при заливке. Более подробную информацию можно найти в описании метода
		 * <code>flash.display.Graphics#beginBitmapFill()</code>.
		 */
		public function get repeat():Boolean {
			return _repeat;
		}

		/**
		 * @private
		 */
		public function set repeat(value:Boolean):void {
			if (_repeat != value) {
				_repeat = value;
				if (_surface != null) {
					_surface.addMaterialChangedOperationToScene();
				}
			}
		}

		/**
		 * Сглаживание текстуры при увеличении масштаба. Более подробную информацию можно найти в описании метода
		 * <code>flash.display.Graphics#beginBitmapFill()</code>.
		 */
		public function get smooth():Boolean {
			return _smooth;
		}
		
		/**
		 * @private
		 */		
		public function set smooth(value:Boolean):void {
			if (_smooth != value) {
				_smooth = value;
				if (_surface != null) {
					_surface.addMaterialChangedOperationToScene();
				}
			}
		}

		/**
		 * Толщина линии обводки полигона. Если значение отрицательное, то обводка не рисуется.
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
		 * Цвет линии обводки полигона.
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
		 * Точность перспективной коррекции.
		 */
		public function get precision():Number {
			return _precision;
		}

		/**
		 * @private
		 */		
		public function set precision(value:Number):void {
			if (_precision != value) {
				_precision = value;
				if (_surface != null) {
					_surface.addMaterialChangedOperationToScene();
				}
			}
		}

		/**
		 * @inheritDoc 
		 */
		override public function clone():Material {
			var res:TextureMaterial = new TextureMaterial(_texture, _alpha, _repeat, _smooth, _blendMode, _wireThickness, _wireColor, _precision);
			return res;
		}
	}
}