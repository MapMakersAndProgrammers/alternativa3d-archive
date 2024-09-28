package alternativa.engine3d.display {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Face;
	
	import flash.display.Sprite;
	import flash.geom.Point;
	
	use namespace alternativa3d;
	
	/**
	 * Область для вывода изображения с камеры.
	 */
	public class View extends Sprite {
		
		/**
		 * @private
		 * Область отрисовки спрайтов
		 */		
		alternativa3d var canvas:Sprite;
		
		private var _camera:Camera3D;
		
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
			canvas = new Sprite();
			canvas.mouseEnabled = false;
			canvas.mouseChildren = false;
			canvas.tabEnabled = false;
			canvas.tabChildren = false;
			addChild(canvas);
			
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
			if (_camera != value) {
				// Если была камера
				if (_camera != null) {
					// Удалить камеру
					_camera.removeFromView(this);
				}
				// Если новая камера
				if (value != null) {
					// Если камера была в другом вьюпорте
					if (value._view != null) {
						// Удалить её оттуда
						value._view.camera = null;
					}
					// Добавить камеру
					value.addToView(this);
				} else {
					// Зачистка скинов
					if (canvas.numChildren > 0) {
						var skin:Skin = Skin(canvas.getChildAt(0));
						while (skin != null) {
							// Сохраняем следующий
							var next:Skin = skin.nextSkin;
							// Удаляем из канваса
							canvas.removeChild(skin);
							// Очистка скина
							if (skin.material != null) {
								skin.material.clear(skin);
							}
							// Зачищаем ссылки
							skin.nextSkin = null;
							skin.primitive = null;
							skin.material = null;
							// Удаляем
							Skin.destroySkin(skin);
							// Следующий устанавливаем текущим
							skin = next;
						}
					}
				}
				// Сохраняем камеру
				_camera = value;
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
				canvas.x = _width*0.5;
				if (_camera != null) {
					camera.addOperationToScene(camera.calculatePlanesOperation);
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
				canvas.y = _height*0.5;
				if (_camera != null) {
					camera.addOperationToScene(camera.calculatePlanesOperation);
				}
			}
		}
		
		/**
		 * Метод возвращает грань, находящуюся под указанной точкой в области вывода.
		 * 
		 * @param viewPoint координаты точки относительно области вывода
		 * 
		 * @return ближайшая к камере грань под заданной точкой области вывода
		 */
		public function getFaceUnderPoint(viewPoint:Point):Face {
			var p:Point = localToGlobal(viewPoint);
			var objects:Array = canvas.getObjectsUnderPoint(p);
			var skin:Skin = objects.pop() as Skin;
			if (skin != null) {
				return skin.primitive.face;
			}
			return null;
		}

		/**
		 * Метод возвращает грани, находящиеся под указанной точкой в области вывода.
		 * 
		 * @param viewPoint координаты точки относительно области вывода
		 * 
		 * @return массив граней, расположенных под заданной точкой области вывода. Первым элементом массива является самая дальняя грань.
		 */
		public function getFacesUnderPoint(viewPoint:Point):Array {
			var p:Point = localToGlobal(viewPoint);
			var objects:Array = canvas.getObjectsUnderPoint(p);
			var res:Array = new Array();
			var length:uint = objects.length;
			for (var i:uint = 0; i < length; i++) {
				var skin:Skin = objects[i]; 
				res.push(skin.primitive.face);
			}
			return res;
		}
	}
}