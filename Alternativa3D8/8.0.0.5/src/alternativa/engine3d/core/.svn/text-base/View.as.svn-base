package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.display.BitmapData;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.geom.Rectangle;
	import flash.display3D.Context3DClearMask;
	
	use namespace alternativa3d;
	
	public class View {
		
		public var backgroundColor:int = 0;
		public var backgroundAlpha:Number = 1;
		public var clearMask:uint = Context3DClearMask.ALL;
		
		alternativa3d var _width:Number = 0;
		alternativa3d var _height:Number = 0;
		
		/**
		 * @private 
		 */
		alternativa3d var _context3d:Context3D;
		 
		/**
		 * @private 
		 */
		alternativa3d var _stage3d:Stage3D;
		 
		/**
		 * @private 
		 */
		alternativa3d var cachedPrograms:Object = new Object();
		
		public function View(width:Number, height:Number, renderMode:String = "auto", stage3d:Stage3D = null, antialias:uint = 0, depthstencil:Boolean = true) {
			_context3d = new Context3D(renderMode);
			this.stage3d = stage3d;
			setupBackBuffer(width, height, antialias, depthstencil);
		}
		
		public function get stage3d():Stage3D {
			return stage3d;
		}
		
		public function set stage3d(value:Stage3D):void {
			_stage3d = value;
			if (_stage3d != null) {
				_stage3d.attachContext3D(_context3d);
			}
		}
		
		public function get renderMode():String {
			return _context3d.renderMode;
		}
		
		public function clear(red:Number, green:Number, blue:Number, alpha:Number = 1.0, depth:Number = 1.0, stencil:int = 0, clearMask:uint = 7):void {
			_context3d.clear(red, green, blue, alpha, depth, stencil, clearMask);
		}
		
		public function drawToBitmapData(destination:BitmapData):void {
			_context3d.drawToBitmapData(destination);
		}
		
		public function setColorWriteMask(writeRed:Boolean, writeGreen:Boolean, writeBlue:Boolean, writeAlpha:Boolean):void {
			_context3d.setColorWriteMask(writeRed, writeGreen, writeBlue, writeAlpha);
		}
		
		public function setScissor(rectangle:Rectangle):void {
			_context3d.setScissor(rectangle);
		}
		
		public function get width():Number {
			return _width;
		}

		public function get height():Number {
			return _height;
		}
		
		public function get context3d():Context3D {
			return _context3d;
		}
		
		public function setupBackBuffer(width:uint, height:uint, antialias:uint = 0, depthStencil:Boolean = true):void {
			if (_stage3d != null) _stage3d.viewPort = new Rectangle(0, 0, width, height);
			_context3d.setupBackBuffer(width, height, antialias, depthStencil);
			_width = width;
			_height = height;
		}
		
	}
}
