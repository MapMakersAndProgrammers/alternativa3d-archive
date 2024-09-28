package alternativa.engine3d.display {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Camera3D;
	
	import flash.display.Sprite;
	
	use namespace alternativa3d;
	
	/**
	 * Область для вывода изображения с камеры.
	 */
	public class View extends Sprite {
		
		/**
		 * @private
		 * Область отрисовки пространства сцены
		 */		
		alternativa3d var canvas:Canvas;
		
		alternativa3d var _camera:Camera3D;
		
		/**
		 * @private
		 * Ширина области вывода
		 */		
		alternativa3d var _width:Number;
		/**
		 * @private
		 * Высота области вывода
		 */		
		alternativa3d var _height:Number;
		
		/**
		 * Создание экземпляра области вывода.
		 * 
		 * @param camera камера, изображение с которой должно выводиться 
		 * @param width ширина области вывода
		 * @param height высота области вывода
		 */
		public function View(camera:Camera3D = null, width:Number = 0, height:Number = 0) {
			mouseChildren = false;
			tabChildren = false;
			
			this.camera = camera;
			this.width = width;
			this.height = height;
		}
		
		/**
		 * Камера с которой ведётся отображение. 
		 */
		public function get camera():Camera3D {
			return _camera;
		}

		/**
		 * @private
		 */
		public function set camera(value:Camera3D):void {
			if (value != _camera) {
				if (_camera != null) {
					_camera.view = null;
				}
				if (value != null) {
					value.view = this;
				}
			}
		}
		
		/**
		 * Ширина области вывода в пикселях.
		 */
		override public function get width():Number {
			return _width;
		}

		/**
		 * @private
		 */
		override public function set width(value:Number):void {
			if (_width != value) {
				_width = value;
				if (canvas != null) {
					canvas.x = _width*0.5;
				}
				if (_camera != null) {
					// Отправляем сигнал об изменении плоскостей отсечения
					// ...
				}
			}
		}

		/**
		 * Высота области вывода в пикселях.
		 */
		override public function get height():Number {
			return _height;
		}

		/**
		 * @private
		 */
		override public function set height(value:Number):void {
			if (_height != value) {
				_height = value;
				if (canvas != null) {
					canvas.y = _height*0.5;
				}
				if (_camera != null) {
					// Отправляем сигнал об изменении плоскостей отсечения
					// ...
				}
			}
		}
		
	}
}