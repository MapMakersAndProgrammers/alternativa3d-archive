package alternativa.engine3d.materials {
	import alternativa.engine3d.*;
	import alternativa.engine3d.display.Skin;
	
	import flash.display.BlendMode;
	import flash.geom.ColorTransform;
	import alternativa.engine3d.display.DisplayItem;

	use namespace alternativa3d;
	
	/**
	 * Базовый класс для материалов.
	 */	
	public class Material {
		
		/**
		 * @private
		 * Видимость
		 */
		alternativa3d var _visible:Boolean = true;
		
		/**
		 * @private
		 * Режим наложения
		 */
		alternativa3d var _blendMode:String = BlendMode.NORMAL;

		/**
		 * @private
		 * Трансформация цвета
		 */
		alternativa3d var _colorTransform:ColorTransform = new ColorTransform();
		
		// Флаг трансформации цвета по умолчанию
		private var defaultColorTransform:Boolean = true;


	
		/**
		 * Видимость.
		 */		
		public function get visible():Boolean {
			return _visible;
		}
		/**
		 * @private
		 */		
		public function set visible(value:Boolean):void {
			if (_visible != value) {
				_visible = value;
				markToChange();
			}
		}
		
		/**
		 * Прозрачность.
		 */		
		public function get alpha():Number {
			return _colorTransform.alphaMultiplier;
		}
		/**
		 * @private
		 */		
		public function set alpha(value:Number):void {
			if (_colorTransform.alphaMultiplier != value) {
				_colorTransform.alphaMultiplier = value;
				markToChange();
			}
		}
		
		/**
		 * Режим наложения.
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
				markToChange();
			}
		}
		
		/**
		 * Трансформация цвета.
		 */		
		public function get colorTransform():ColorTransform {
			return new ColorTransform(_colorTransform.redMultiplier, _colorTransform.greenMultiplier, _colorTransform.blueMultiplier, _colorTransform.alphaMultiplier, _colorTransform.redOffset, _colorTransform.greenOffset, _colorTransform.blueOffset, _colorTransform.alphaOffset);
		}
		/**
		 * @private
		 */		
		public function set colorTransform(value:ColorTransform):void {
			if (value == null) {
				throw new TypeError("Parameter colorTransform must be non-null.");
			}
			if (_colorTransform.redMultiplier != value.redMultiplier || _colorTransform.greenMultiplier != value.greenMultiplier || _colorTransform.blueMultiplier != value.blueMultiplier || _colorTransform.alphaMultiplier != value.alphaMultiplier || _colorTransform.redOffset != value.redOffset || _colorTransform.greenOffset != value.greenOffset || _colorTransform.blueOffset != value.blueOffset || _colorTransform.alphaOffset != value.alphaOffset) {
				_colorTransform.redMultiplier = value.redMultiplier;
				_colorTransform.greenMultiplier = value.greenMultiplier;
				_colorTransform.blueMultiplier = value.blueMultiplier;
				_colorTransform.alphaMultiplier = value.alphaMultiplier;
				_colorTransform.redOffset = value.redOffset;
				_colorTransform.greenOffset = value.greenOffset;
				_colorTransform.blueOffset = value.blueOffset;
				_colorTransform.alphaOffset = value.alphaOffset;
				defaultColorTransform = value.redMultiplier == 1 && value.greenMultiplier == 1 && value.blueMultiplier == 1 && value.redOffset == 0 && value.greenOffset == 0 && value.blueOffset == 0 && value.alphaOffset == 0;
				markToChange();
			}
		}
		
		/**
		 * Отметить изменение материала. 
		 */
		protected function markToChange():void {}
		
		
		alternativa3d function draw(item:DisplayItem):void {}

		alternativa3d function clear(item:DisplayItem):void {}
			
		/**
		 * Клонирование объекта. При расширении класса, в наследниках должны быть переопределены вспомогательные 
		 * методы <code>create()</code> и <code>cloneProperties()</code>.
		 * @return клон объекта
		 * @see #create()
		 * @see #cloneProperties()
		 */
		public function clone():Material {
			var res:Material = create();
			res.cloneProperties(this);
			return res;
		}
		
		/**
		 * Вспомогательный для клонирования метод. Создание нового экземпляра, который выступит в качестве клона после копирования в него свойств.
		 * Вызывается внутри метода <code>clone()</code>.
		 * При переопределении метод должен перекрываться полностью.
		 * @return новый материал
		 * @see #clone()
		 */
		protected function create():Material {
			return new Material();
		}
		
		/**
		 * Вспомогательный для клонирования метод. Копирование свойств из другого объекта. Вызывается внутри метода <code>clone()</code>
		 * объектом, который создан с помощью метода <code>create()</code>.
		 * При переопределении нужно вызывать <code>super.cloneProperties()</code>.
		 * @param source В качестве источника выступает клонируемый объект
		 * @see #clone()
		 * @see #create()
		 */
		protected function cloneProperties(source:Material):void {
			_visible = source._visible;
			_blendMode = source._blendMode;
			_colorTransform.redMultiplier = source._colorTransform.redMultiplier;
			_colorTransform.greenMultiplier = source._colorTransform.greenMultiplier;
			_colorTransform.blueMultiplier = source._colorTransform.blueMultiplier;
			_colorTransform.alphaMultiplier = source._colorTransform.alphaMultiplier;
			_colorTransform.redOffset = source._colorTransform.redOffset;
			_colorTransform.greenOffset = source._colorTransform.greenOffset;
			_colorTransform.blueOffset = source._colorTransform.blueOffset;
			_colorTransform.alphaOffset = source._colorTransform.alphaOffset;
		}
	}
}