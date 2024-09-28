package alternativa.engine3d.materials {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.BSPNode;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.PolyPrimitive;
	import alternativa.engine3d.display.Skin;
	import alternativa.types.Matrix3D;
	import alternativa.types.Point3D;
	import alternativa.utils.ColorUtils;
	
	import flash.display.BlendMode;
	import flash.display.Graphics;
	
	use namespace alternativa3d;
	
	/**
	 * Материал, раскрашивающий грани оттенками заданного цвета в зависимости от значения свойства <code>parameterType</code>.
	 */	
	public class DevMaterial extends SurfaceMaterial {
		/**
		 * Значение свойства <code>parameterType</code> для отображения глубины полигона в BSP-дереве. Глубина кодируется оттенком базового цвета материала. Оттенок
		 * получается покомпонентным умножением базового цвета на отношение значения уровня полигона в дереве к максимальному значению, задаваемому
		 * свойством <code>maxParameterValue</code>. Уровни нумеруются начиная от корня дерева, таким образом, чем глубже в дереве расположен
		 * полигон, тем он будет светлее.
		 */		
		public static const BSP_DEPTH:int = 0;
		/**
		 * Значение свойства <code>parameterType</code> для отображения мобильности полигона. Мобильность кодируется оттенком базового цвета материала. Оттенок
		 * получается покомпонентным умножением базового цвета на коэффициент, характеризующий положение мобильности полигона на отрезке,
		 * задаваемом свойствами <code>minMobility</code> и <code>maxMobility</code>. Более мобильные полигоны имеют более светлый оттенок.
		 */		
		public static const MOBILITY:int = 1;
		/**
		 * Значение свойства <code>parameterType</code> для отображения количества фрагментов грани, которой принадлежит отрисовываемый полигон. Количество фрагментов кодируется
		 * оттенком базового цвета материала. Оттенок получается покомпонентным умножением базового цвета на отношние количества фрагментов текущей грани
		 * к максимальному значению, задаваемому свойством <code>maxParameterValue</code>. Чем больше грань фрагментирована, тем она светлее.
		 */		
		public static const FRAGMENTATION:int = 2;
		/**
		 * Значение свойства <code>parameterType</code> для отображения граней с отсутствующими UV-координатами. Такие грани отображаются красной заливкой.
		 */		
		public static const NO_UV_MAPPING:int = 3;
		/**
		 * Значение свойства <code>parameterType</code> для отображения вырожденных полигонов. Вырожденные полигоны отображаются красной заливкой с красной обводкой толщиной пять
		 * пикселей. Для лучшей видимости таких полигонов можно сделать материал полупрозрачным.
		 */		
		public static const DEGENERATE_POLY:int = 4;
		
		private static const point1:Point3D = new Point3D();
		private static const point2:Point3D = new Point3D();

		private var _parameterType:int = BSP_DEPTH;
		
		private var _showNormals:Boolean;
		private var _normalsColor:uint = 0x00FFFF;
		private var _minMobility:int = 0;
		private var _maxMobility:int = 255;
		private var _maxParameterValue:Number = 20;
		private var currentColor:int;
		private var currentWireThickness:Number;
		private var currentWireColor:uint;
		
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
		 * @param parameterType тип отображаемого параметра
		 * @param color цвет заливки
		 * @param maxParameterValue максимальное значение отображаемого параметра
		 * @param showNormals включение режима отображения нормалей
		 * @param normalsColor цвет нормалей
		 * @param minMobility начало интервала мобильности
		 * @param maxMobility окончание интервала мобильности
		 * @param alpha прозрачность
		 * @param blendMode режим наложения цвета
		 * @param wireThickness толщина линии обводки
		 * @param wireColor цвет линии обводки
		 */
		public function DevMaterial(parameterType:uint = 0, color:uint = 0xFFFFFF, maxParameterValue:Number = 20, showNormals:Boolean = false, normalsColor:uint = 0x00FFFF, minMobility:int = 0, maxMobility:int = 255, alpha:Number = 1, blendMode:String = BlendMode.NORMAL, wireThickness:Number = -1, wireColor:uint = 0) {
			super(alpha, blendMode);
			_parameterType = parameterType;
			_color = color;
			_maxParameterValue = maxParameterValue;
			_showNormals = showNormals;
			_normalsColor = normalsColor;
			_minMobility = minMobility;
			_maxMobility = maxMobility;
			_wireThickness = wireThickness;
			_wireColor = wireColor;
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
			var gfx:Graphics = skin.gfx;
			var perspective:Number;
			
			setDrawingParameters(skin);

			if (currentColor > -1) {
				gfx.beginFill(currentColor);
			}
			if (currentWireThickness >= 0) {
				gfx.lineStyle(currentWireThickness, currentWireColor);
			}
			point = points[0];
			
			if (camera._orthographic) {
				gfx.moveTo(point.x, point.y);
				for (i = 1; i < length; i++) {
					point = points[i];
					gfx.lineTo(point.x, point.y);
				}
				if (currentWireThickness >= 0) {
					point = points[0];
					gfx.lineTo(point.x, point.y);
				}
			} else {
				perspective = camera.focalLength/point.z;
				gfx.moveTo(point.x*perspective, point.y*perspective);
				for (i = 1; i < length; i++) {
					point = points[i];
					perspective = camera.focalLength/point.z;
					gfx.lineTo(point.x*perspective, point.y*perspective);
				}
				if (currentWireThickness >= 0) {
					point = points[0];
					perspective = camera.focalLength/point.z;
					gfx.lineTo(point.x*perspective, point.y*perspective);
				}
			}
			
			// Отрисовка нормали
			if (_showNormals) {
				point1.reset();
				for (i = 0; i < length; i++) {
					point = points[i];
					point1.x += point.x;
					point1.y += point.y;
					point1.z += point.z;
				}
				point1.multiply(1 / length);

				var multiplyer:Number = 10;
				var normal:Point3D = skin.primitive.face.globalNormal;
				var m:Matrix3D = camera.cameraMatrix;
				point2.x = (normal.x * m.a + normal.y * m.b + normal.z * m.c) * multiplyer + point1.x;
				point2.y = (normal.x * m.e + normal.y * m.f + normal.z * m.g) * multiplyer + point1.y;
				point2.z = (normal.x * m.i + normal.y * m.j + normal.z * m.k) * multiplyer + point1.z;

				if (camera._orthographic) {
					gfx.moveTo(point1.x, point1.y);
					gfx.lineStyle(0, _normalsColor);
					gfx.lineTo(point2.x, point2.y);
				} else {
					perspective = camera.focalLength / point1.z;
					gfx.moveTo(point1.x * perspective, point1.y * perspective);
					gfx.lineStyle(0, _normalsColor);
					perspective = camera.focalLength / point2.z;
					gfx.lineTo(point2.x * perspective, point2.y * perspective);
				}
				gfx.lineStyle();
			}
		}
		
		/**
		 * Установка параметров отрисовки.
		 */
		private function setDrawingParameters(skin:Skin):void {
			currentColor = _color;
			currentWireColor = _wireColor;
			currentWireThickness = _wireThickness;
			
			var param:int = 0;
			switch (_parameterType) {
				case BSP_DEPTH:
					// Глубина вложенности в BSP-tree
					var node:BSPNode = skin.primitive.node;
					while (node != null) {
						node = node.parent;
						param++;
					}
					currentColor = ColorUtils.multiply(_color, param / _maxParameterValue);
					break;
				case MOBILITY:
					// Мобильность
					var value:Number = (skin.primitive.mobility - _minMobility) / (_maxMobility - _minMobility);
					if (value < 0) {
						value = 0;
					}
					currentColor = ColorUtils.multiply(_color, value);
					break;
				case FRAGMENTATION:
					// Степень фрагментирования
					currentColor = ColorUtils.multiply(_color, calculateFragments(skin.primitive.face.primitive) / _maxParameterValue);
					break;
				case NO_UV_MAPPING:
					// Отсутствие UV
					if (skin.primitive.face.uvMatrix == null) {
						currentColor = 0xFF0000;
					}
					break;
				case DEGENERATE_POLY:
					// Вырожденные полигоны
					var face:Face = skin.primitive.face;
					point1.copy(face._vertices[1]._coords);
					point2.copy(face._vertices[2]._coords);
					point2.subtract(point1);
					point1.subtract(face._vertices[0]._coords);
					var crossX:Number = point1.y * point2.z - point1.z * point2.y;
					var crossY:Number = point1.z * point2.x - point1.x * point2.z;
					var crossZ:Number = point1.x * point2.y - point1.y * point2.x;
					if (crossX * crossX + crossY * crossY + crossZ * crossZ < 0.001) {
						currentColor = 0xFF0000;
						currentWireColor = 0xFF0000;
						currentWireThickness = 5;
					}
					break;
			}
		}
		
		/**
		 * Расчёт количества фрагментов грани примитива.
		 */
		private function calculateFragments(primitive:PolyPrimitive):int {
			if (primitive.frontFragment == null) {
				return 1;
			}
			return calculateFragments(primitive.frontFragment) + calculateFragments(primitive.backFragment);
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
				markToChange();
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
				markToChange();
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
				markToChange();
			}
		}
		
		/**
		 * @inheritDoc
		 */		
		override public function clone():Material {
			var res:DevMaterial = new DevMaterial(_parameterType, _color, _maxParameterValue, _showNormals, _normalsColor, _minMobility, _maxMobility, _alpha, _blendMode, _wireThickness, _wireColor);
			return res;
		}
		
		/**
		 * Тип отображаемого параметра.
		 */
		public function set parameterType(value:int):void {
			if (_parameterType != value) {
				_parameterType = value;
				markToChange();
			}
		}

		/**
		 * @private
		 */
		public function get parameterType():int {
			return _parameterType;
		}
		
		/**
		 * Включение режима отображения нормалей.
		 */
		public function set showNormals(value:Boolean):void {
			if (_showNormals != value) {
				_showNormals = value;
				markToChange();
			}
		}

		/**
		 * @private
		 */
		public function get showNormals():Boolean {
			return _showNormals;
		}
		
		/**
		 * Цвет нормалей.
		 * 
		 * @default 0x00FFFF
		 */
		public function set normalsColor(value:uint):void {
			if (_normalsColor != value) {
				_normalsColor = value;
				markToChange();
			}
		}

		/**
		 * @private
		 */
		public function get normalsColor():uint {
			return _normalsColor;
		}

		/**
		 * Начало интервала мобильности.
		 */
		public function set minMobility(value:int):void {
			if (_minMobility != value) {
				_minMobility = value;
				markToChange();
			}
		}
		
		/**
		 * @private
		 */
		public function get minMobility():int {
			return _minMobility;
		}
		
		/**
		 * Окончание интервала мобильности.
		 */
		public function set maxMobility(value:int):void {
			if (_maxMobility != value) {
				_maxMobility = value;
				markToChange();
			}
		}
		
		/**
		 * @private
		 */
		public function get maxMobility():int {
			return _maxMobility;
		}
		
		/**
		 * Максимальное значение отображаемого параметра.
		 */
		public function set maxParameterValue(value:Number):void {
			if (_maxParameterValue != value) {
				_maxParameterValue = value;
				markToChange();
			}
		}

		/**
		 * @private
		 */
		public function get maxParameterValue():Number {
			return _maxParameterValue;
		}
	}
}