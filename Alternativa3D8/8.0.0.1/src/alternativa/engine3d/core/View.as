package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	
	import flash.display.Bitmap3D;
	
	use namespace alternativa3d;
	
	/**
	 * Вьюпорт, в который камера отрисовывает графику.
	 * <code>View</code> — это <code>Bitmap3D</code>.
	 * @see alternativa.engine3d.core.Camera3D
	 */
	public class View extends Bitmap3D {
		
		public var backgroundColor:int = 0;
		public var backgroundAlpha:Number = 1;
		
		/**
		 * @private 
		 */
		alternativa3d var _width:Number = 0;
		
		/**
		 * @private 
		 */
		alternativa3d var _height:Number = 0;
		
		/**
		 * @private 
		 */
		alternativa3d var _antialias:int;
		
		/**
		 * @private 
		 */
		alternativa3d var _depthdtencil:Boolean;
		
		/**
		 * @private 
		 */
		alternativa3d var cachedPrograms:Object = new Object();
		
		/**
		 * Создаёт новый вьюпорт.
		 * @param width Ширина вьюпорта.
		 * @param height Высота вьюпорта.
		 */
		public function View(width:Number, height:Number, rendermode:String = "AUTO", antialias:uint = 0, depthstencil:Boolean = true) {
			super(rendermode);
			setupBackbuffer(width, height, antialias, depthstencil);
		}
		
		override public function setupBackbuffer(width:uint, height:uint, antialias:uint, depthstencil:Boolean):void {
			if (_width != width || _height != height || _antialias != antialias || _depthdtencil != depthstencil) {
				super.setupBackbuffer(width, height, antialias, depthstencil);
				_width = width;
				_height = height;
				_antialias = antialias;
				_depthdtencil = depthstencil;
			}
		}
		
	}
}
