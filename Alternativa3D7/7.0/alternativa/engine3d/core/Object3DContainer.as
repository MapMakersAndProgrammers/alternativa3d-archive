package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;

	import flash.geom.ColorTransform;
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;
	
	/**
	 * Базовый контейнер трёхмерных объектов.
	 * Логика контейнеров и child-parent-отношений идентична логике 
	 * displayObject'ов во Flash.
	 */
	public class Object3DContainer extends Object3D {
		
		protected var children:Vector.<Object3D> = new Vector.<Object3D>();
		protected var _numChildren:int = 0;
		
		protected var visibleChildren:Vector.<Object3D> = new Vector.<Object3D>();
		protected var numVisibleChildren:int = 0;
		
		override alternativa3d function get canDraw():Boolean {
			return _numChildren > 0;
		}
		
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Сбор видимых объектов
			numVisibleChildren = 0;
			for (var i:int = 0; i < _numChildren; i++) {
				var child:Object3D = children[i];
				if (child.visible && child.canDraw) {
					child.cameraMatrix.identity();
					child.cameraMatrix.prepend(object.cameraMatrix);
					child.cameraMatrix.prepend(child.matrix);
					if (child.cullingInCamera(camera, object.culling) >= 0) {
						visibleChildren[numVisibleChildren] = child;
						numVisibleChildren++;
					}
				}
			}
			// Если есть видимые объекты
			if (numVisibleChildren > 0) {
				// Подготовка канваса
				var canvas:Canvas = parentCanvas.getChildCanvas(false, true, object.alpha, object.blendMode, object.colorTransform, object.filters);
				canvas.numDraws = 0;
				// Отрисовка видимых объектов
				drawVisibleChildren(camera, object, canvas);
				// Если была отрисовка
				if (canvas.numDraws > 0) {
					canvas.removeChildren(canvas.numDraws);
				} else {
					parentCanvas.numDraws--;
				}
			}
		}
		
		protected function drawVisibleChildren(camera:Camera3D, object:Object3D, canvas:Canvas):void {
			for (var i:int = numVisibleChildren - 1; i >= 0; i--) {
				var child:Object3D = visibleChildren[i];
				if (camera.debugMode) child.debug(camera, child, canvas);
				child.draw(camera, child, canvas);
				visibleChildren[i] = null;
			}
		}
		
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			var i:int;
			var first:Geometry;
			var last:Geometry;
			var geometry:Geometry;
			for (i = 0; i < _numChildren; i++) {
				var child:Object3D = children[i];
				if (child.visible && child.canDraw) {
					child.cameraMatrix.identity();
					child.cameraMatrix.prepend(object.cameraMatrix);
					child.cameraMatrix.prepend(child.matrix);
					if (child.cullingInCamera(camera, object.culling) >= 0) {
						geometry = child.getGeometry(camera, child);
						if (geometry != null) {
							if (first != null) {
								last.next = geometry;
							} else {
								first = geometry;
								last = geometry;
							}
							while (last.next != null) {
								last = last.next;
							}
						}
					}
				}
			}
			if (object.alpha != 1) {
				geometry = first;
				while (geometry != null) {
					geometry.alpha *= object.alpha;
					geometry = geometry.next;
				}
			}
			if (object.blendMode != "normal") {
				geometry = first;
				while (geometry != null) {
					if (geometry.blendMode == "normal") {
						geometry.blendMode = object.blendMode;
					}
					geometry = geometry.next;
				}
			}
			if (object.colorTransform != null) {
				geometry = first;
				while (geometry != null) {
					if (geometry.colorTransform != null) {
						var ct:ColorTransform = new ColorTransform(object.colorTransform.redMultiplier, object.colorTransform.greenMultiplier, object.colorTransform.blueMultiplier, object.colorTransform.alphaMultiplier, object.colorTransform.redOffset, object.colorTransform.greenOffset, object.colorTransform.blueOffset, object.colorTransform.alphaOffset);
						ct.concat(geometry.colorTransform);
						geometry.colorTransform = ct;
					} else {
						geometry.colorTransform = object.colorTransform;
					}
					geometry = geometry.next;
				}
			}
			if (object.filters != null) {
				geometry = first;
				while (geometry != null) {
					if (geometry.filters != null) {
						var fs:Array = new Array();
						var fsLength:int = 0;
						var num:int = geometry.filters.length;
						for (i = 0; i < num; i++) {
							fs[fsLength] = geometry.filters[i]; fsLength++;
						}
						num = object.filters.length;
						for (i = 0; i < num; i++) {
							fs[fsLength] = object.filters[i]; fsLength++;
						}
						geometry.filters = fs;
					} else {
						geometry.filters = object.filters;
					}
					geometry = geometry.next;
				}
			}
			return first;
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
