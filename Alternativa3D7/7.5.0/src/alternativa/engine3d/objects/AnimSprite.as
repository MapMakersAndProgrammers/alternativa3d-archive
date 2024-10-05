package alternativa.engine3d.objects {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.VG;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.Material;
	import __AS3__.vec.Vector;
	
	use namespace alternativa3d;
	
	/**
	 * Анимированный спрайт.
	 * Анимация осуществляется путём установки свойства <code>frame</code>.
	 */
	public class AnimSprite extends Sprite3D {
	
		private var _materials:Vector.<Material>;
		
		private var _frame:int = 0;
	
		private var _loop:Boolean = false;
	
		/**
		 * Создаёт новый экземпляр.
		 * @param width Ширина спрайта.
		 * @param height Вычота спрайта.
		 * @param materials Список материалов.
		 * @param loop Флаг циклического проигрывания.
		 * @param frame Текущий кадр.
		 * @see alternativa.engine3d.materials.Material
		 */
		public function AnimSprite(width:Number, height:Number, materials:Vector.<Material> = null, loop:Boolean = false, frame:int = 0) {
			super(width, height);
			_materials = materials;
			_loop = loop;
			this.frame = frame;
		}
		
		/**
		 * Список материалов.
		 */
		public function get materials():Vector.<Material> {
			return _materials;
		}
		
		/**
		 * @private
		 */
		public function set materials(value:Vector.<Material>):void {
			_materials = value;
			if (value != null) {
				frame = _frame;
			} else {
				material = null;
			}
		}
		
		/**
		 * Флаг циклического проигрывания.
		 * Если <code>true</code>, то при установке свойства <code>frame</code> больше длины списка материалов произойдёт перенос, иначе возьмётся последний материал.
		 * @see #frame
		 * @see #materials
		 */
		public function get loop():Boolean {
			return _loop;
		}
		
		/**
		 * @private
		 */
		public function set loop(value:Boolean):void {
			_loop = value;
			frame = _frame;
		}
		
		/**
		 * Устанавливаемый кадр.
		 * В зависимости от кадра, для отрисовки будет взят материал из списка материалов.
		 * Кадр соответствует индексу в списке материалов.
		 * @see #loop
		 * @see #materials
		 */
		public function get frame():int {
			return _frame;
		}
		
		/**
		 * @private
		 */
		public function set frame(value:int):void {
			_frame = value;
			if (_materials != null) {
				var materialsLength:int = _materials.length;
				var index:int = _frame;
				if (_frame < 0) {
					var mod:int = _frame % materialsLength;
					index = (_loop && mod != 0) ? (mod + materialsLength) : 0;
				} else if (_frame > materialsLength - 1) {
					index = _loop ? (_frame % materialsLength) : (materialsLength - 1);
				}
				material = _materials[index];
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var animSprite:AnimSprite = new AnimSprite(width, height, _materials, _loop, _frame);
			animSprite.cloneBaseProperties(this);
			animSprite.clipping = clipping;
			animSprite.sorting = sorting;
			animSprite.originX = originX;
			animSprite.originY = originY;
			animSprite.rotation = rotation;
			animSprite.perspectiveScale = perspectiveScale;
			return animSprite;
		}
		
	}
}
