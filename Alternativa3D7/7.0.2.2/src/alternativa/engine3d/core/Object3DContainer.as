package alternativa.engine3d.core {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.Matrix3D;

	use namespace alternativa3d;
	
	/**
	 * Базовый контейнер трёхмерных объектов.
	 * Логика контейнеров и child-parent-отношений идентична логике 
	 * displayObject'ов во Flash.
	 */
	public class Object3DContainer extends Object3D {
		
		static public var debug:Boolean = false;
		
		/**
		 * @private 
		 */
		alternativa3d var _numChildren:int = 0;
		/**
		 * @private 
		 */
		alternativa3d var children:Vector.<Object3D> = new Vector.<Object3D>();

		protected var numVisibleChildren:int = 0;
		protected var visibleChildren:Vector.<Object3D> = new Vector.<Object3D>();
		
		/**
		 * @private 
		 */
		override alternativa3d function get canDraw():Boolean {
			return _numChildren > 0;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Определяем видимые объекты
			numVisibleChildren = 0;
			calculateVisibleChildren(camera, object);
			// Если нет видимых дочерних объектов выходим без отрисовки
			if (numVisibleChildren == 0) return;
			// Расчёт порядка вывода видимых объектов
			calculateOrder(camera, object);
			// Отрисовка видимых объектов
			drawVisibleChildren(camera, object, parentCanvas);
		}
		
		protected function calculateVisibleChildren(camera:Camera3D, object:Object3D):void {
			var i:int = 0, child:Object3D;
			while (i < _numChildren) {
				child = children[i++];
				if (child.visible && child.canDraw) {
					child.cameraMatrix.identity();
					child.cameraMatrix.prepend(object.cameraMatrix);
					child.cameraMatrix.prepend(child.matrix);
					if (child.cullingInCamera(camera, object.culling) >= 0) {
						visibleChildren[numVisibleChildren++] = child;
					}
				}
			}
			// Подрезаем список видимых детей
			visibleChildren.length = numVisibleChildren;
		}
		
		protected function calculateOrder(camera:Camera3D, object:Object3D):void {}
		
		// Отрисовка сзади детей
		protected function drawBack(camera:Camera3D, object:Object3D, canvas:Canvas):void {}

		// Отрисовка перед детьми
		protected function drawFront(camera:Camera3D, object:Object3D, canvas:Canvas):void {}

		// Отрисовка видимых детей
		protected function drawVisibleChildren(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {

			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(debug, true, object.alpha, object.blendMode, object.colorTransform, object.filters);
			canvas.numDraws = 0;
			
			// Отрисовываем перед детьми
			drawFront(camera, object, canvas);
			
			// Отрисовываем видимые дочерние объекты от ближних к дальним 
			var child:Object3D;
			for (var i:int = numVisibleChildren - 1; i >= 0; i--) {
				(child = visibleChildren[i]).draw(camera, child, canvas);
			}

			// Отрисовываем после детей
			drawBack(camera, object, canvas);

			// Если не было отрисовки
			if (canvas.numDraws == 0) {
				parentCanvas.numDraws--;
				return;
			}

			// Зачищаем остатки
			canvas.removeChildren(canvas.numDraws);
			
			if (debug) object.drawBoundBox(camera, canvas);
		}

		override public function calculateBoundBox(matrix:Matrix3D = null, boundBox:BoundBox = null):BoundBox {
			var m:Matrix3D = matrix != null ? matrix.clone() : new Matrix3D();
			// Если указан баунд-бокс
			if (boundBox != null) {
				boundBox.infinity();
			} else {
				boundBox = new BoundBox();
			}			
			// Расчитываем баунды объектов
			var childBoundBox:BoundBox = new BoundBox();
			var childMatrix:Matrix3D = new Matrix3D();
			for (var i:int = 0; i < _numChildren; i++) {
				var child:Object3D = children[i];
				childMatrix.identity();
				childMatrix.prepend(m);
				childMatrix.prepend(child.matrix);
				child.calculateBoundBox(childMatrix, childBoundBox);
				boundBox.minX = (childBoundBox.minX < boundBox.minX) ? childBoundBox.minX : boundBox.minX;
				boundBox.minY = (childBoundBox.minY < boundBox.minY) ? childBoundBox.minY : boundBox.minY;
				boundBox.minZ = (childBoundBox.minZ < boundBox.minZ) ? childBoundBox.minZ : boundBox.minZ;
				boundBox.maxX = (childBoundBox.maxX > boundBox.maxX) ? childBoundBox.maxX : boundBox.maxX;
				boundBox.maxY = (childBoundBox.maxY > boundBox.maxY) ? childBoundBox.maxY : boundBox.maxY;
				boundBox.maxZ = (childBoundBox.maxZ > boundBox.maxZ) ? childBoundBox.maxZ : boundBox.maxZ;
			}
			return boundBox;
		}
		
		public function addChild(child:Object3D):void {
			children[_numChildren++] = child;
			child._parent = this;
		}

		public function removeChild(child:Object3D):void {
			var i:int = children.indexOf(child);
			if (i < 0) throw new ArgumentError("Child not found");
			_numChildren--;
			for (; i < _numChildren; i++) children[i] = children[int(i + 1)];
			children.length = _numChildren;
			child._parent = null;
		}
		
		public function hasChild(child:Object3D):Boolean {
			return children.indexOf(child) > -1;
		}
		
		public function getChildAt(index:uint):Object3D {
			return children[index];
		}

		public function get numChildren():uint {
			return _numChildren;
		}
		
	}
}