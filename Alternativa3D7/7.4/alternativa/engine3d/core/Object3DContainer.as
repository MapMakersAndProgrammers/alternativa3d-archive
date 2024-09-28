package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.ColorTransform;
	
	use namespace alternativa3d;
	
	/**
	 * Базовый контейнер трёхмерных объектов.
	 * Логика контейнеров и child-parent-отношений идентична логике
	 * displayObject'ов во Flash.
	 */
	public class Object3DContainer extends Object3D {
	
		alternativa3d var firstChild:Object3D;
		alternativa3d var lastChild:Object3D;
		alternativa3d var _numChildren:int = 0;
	
		protected var visibleChildren:Vector.<Object3D> = new Vector.<Object3D>();
		protected var numVisibleChildren:int = 0;
	
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var canvas:Canvas;
			var debug:int;
			// Сбор видимых объектов
			numVisibleChildren = 0;
			for (var child:Object3D = firstChild; child != null; child = child.next) {
				if (child.visible) {
					child.composeAndAppend(object);
					if (child.cullingInCamera(camera, child, object.culling) >= 0) {
						visibleChildren[numVisibleChildren] = child;
						numVisibleChildren++;
					}
				}
			}
			// Если есть видимые объекты
			if (numVisibleChildren > 0) {
				// Дебаг
				if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
					canvas = parentCanvas.getChildCanvas(object, true, false);
					if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
				}
				// Отрисовка
				canvas = parentCanvas.getChildCanvas(object, false, true, object.alpha, object.blendMode, object.colorTransform, object.filters);
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
				child.draw(camera, child, canvas);
				visibleChildren[i] = null;
			}
		}
	
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			var i:int;
			var first:Geometry;
			var last:Geometry;
			var geometry:Geometry;
			for (var child:Object3D = firstChild; child != null; child = child.next) {
				if (child.visible) {
					child.composeAndAppend(object);
					if (child.cullingInCamera(camera, child, object.culling) >= 0) {
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
							fs[fsLength] = geometry.filters[i];
							fsLength++;
						}
						num = object.filters.length;
						for (i = 0; i < num; i++) {
							fs[fsLength] = object.filters[i];
							fsLength++;
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
	
		override alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			for (var child:Object3D = firstChild; child != null; child = child.next) {
				if (transformation != null) {
					child.composeAndAppend(transformation);
				} else {
					child.composeMatrix();
				}
				child.updateBounds(bounds, child);
			}
		}
	
		public function get numChildren():int {
			return _numChildren;
		}
		
		public function addChild(child:Object3D):Object3D {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child == this) throw new ArgumentError("An object cannot be added as a child of itself.");
			for (var container:Object3DContainer = _parent; container != null; container = container._parent) {
				if (container == child) throw new ArgumentError("An object cannot be added as a child to one of it's children (or children's children, etc.).");
			}
			// Удаление из старого родителя
			if (child._parent != null) {
				child._parent.removeFromList(child);
			}
			// Добавление
			addToList(child);
			return child;
		}
		
		public function removeChild(child:Object3D):Object3D {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Удаление
			removeFromList(child);
			return child;
		}
		
		public function addChildAt(child:Object3D, index:int):Object3D {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child == this) throw new ArgumentError("An object cannot be added as a child of itself.");
			if (index < 0 || index > _numChildren || child._parent == this && index == _numChildren) throw new RangeError("The supplied index is out of bounds.");
			for (var container:Object3DContainer = _parent; container != null; container = container._parent) {
				if (container == child) throw new ArgumentError("An object cannot be added as a child to one of it's children (or children's children, etc.).");
			}
			// Удаление из старого родителя
			if (child._parent != null) {
				child._parent.removeFromList(child);
			}
			// Поиск элемента по индексу
			var item:Object3D = firstChild;
			for (var i:int = 0; i < index; i++) {
				item = item.next;
			}
			// Добавление
			addToList(child, item);
			return child;
		}
		
		public function removeChildAt(index:int):Object3D {
			// Проверка на ошибки
			if (index < 0 || index >= _numChildren) throw new RangeError("The supplied index is out of bounds.");
			// Поиск элемента по индексу
			var child:Object3D = firstChild;
			for (var i:int = 0; i < index; i++) {
				child = child.next;
			}
			// Удаление
			removeFromList(child);
			return child;
		}
		
		public function getChildAt(index:int):Object3D {
			// Проверка на ошибки
			if (index < 0 || index >= _numChildren) throw new RangeError("The supplied index is out of bounds.");
			// Поиск элемента по индексу
			var child:Object3D = firstChild;
			for (var i:int = 0; i < index; i++) {
				child = child.next;
			}
			return child;
		}
		
		public function getChildIndex(child:Object3D):int {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Поиск индекса элемента
			var index:int = 0;
			for (var object:Object3D = firstChild; object != null; object = object.next) {
				if (object == child) break;
				index++;
			}
			return index;
		}
		
		public function setChildIndex(child:Object3D, index:int):void {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			if (index < 0 || index >= _numChildren) throw new RangeError("The supplied index is out of bounds.");
			// Удаление
			removeFromList(child);
			// Поиск элемента по индексу
			var item:Object3D = firstChild;
			for (var i:int = 0; i < index; i++) {
				item = item.next;
			}
			// Добавление
			addToList(child, item);
		}
		
		public function swapChildren(child1:Object3D, child2:Object3D):void {
			// Проверка на ошибки
			if (child1 == null || child2 == null) throw new TypeError("Parameter child must be non-null.");
			if (child1._parent != this || child2._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Перестановка
			if (child1 != child2) {
				if (child1.next == child2) {
					removeFromList(child2);
					addToList(child2, child1);
				} else if (child2.next == child1) {
					removeFromList(child1);
					addToList(child1, child2);
				} else {
					var item:Object3D = child1.next;
					removeFromList(child1);
					addToList(child1, child2);
					removeFromList(child2);
					addToList(child2, item);
				}
			}
		}
		
		public function swapChildrenAt(index1:int, index2:int):void {
			// Проверка на ошибки
			if (index1 < 0 || index1 >= _numChildren || index2 < 0 || index2 >= _numChildren) throw new RangeError("The supplied index is out of bounds.");
			// Перестановка
			if (index1 != index2) {
				// Поиск элементов по индексам
				var i:int;
				var child1:Object3D = firstChild;
				for (i = 0; i < index1; i++) {
					child1 = child1.next;
				}
				var child2:Object3D = firstChild;
				for (i = 0; i < index2; i++) {
					child2 = child2.next;
				}
				if (child1 != child2) {
					if (child1.next == child2) {
						removeFromList(child2);
						addToList(child2, child1);
					} else if (child2.next == child1) {
						removeFromList(child1);
						addToList(child1, child2);
					} else {
						var item:Object3D = child1.next;
						removeFromList(child1);
						addToList(child1, child2);
						removeFromList(child2);
						addToList(child2, item);
					}
				}
			}
		}
		
		public function getChildByName(name:String):Object3D {
			// Проверка на ошибки
			if (name == null) throw new TypeError("Parameter name must be non-null.");
			// Поиск объекта
			for (var child:Object3D = firstChild; child != null; child = child.next) {
				if (child.name == name) return child;
			}
			return null;
		}
		
		public function contains(child:Object3D):Boolean {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			// Поиск объекта
			if (child == this) return true;
			for (var object:Object3D = firstChild; object != null; object = object.next) {
				if (object is Object3DContainer) {
					if ((object as Object3DContainer).contains(child)) {
						return true;
					}
				} else if (object == child) {
					return true;
				}
			}
			return false;
		}
		
		private function removeFromList(child:Object3D):void {
			if (child.prev != null) {
				child.prev.next = child.next;
			} else {
				firstChild = child.next;
			}
			if (child.next != null) {
				child.next.prev = child.prev;
			} else {
				lastChild = child.prev;
			}
			child.prev = null;
			child.next = null;
			child._parent = null;
			_numChildren--;
		}
		
		private function addToList(child:Object3D, item:Object3D = null):void {
			if (item != null) {
				// Добавление перед элементом
				if (item.prev != null) {
					item.prev.next = child;
				} else {
					firstChild = child;
				}
				child.prev = item.prev;
				child.next = item;
				item.prev = child;
			} else {
				// Добавление в конец
				if (lastChild != null) {
					lastChild.next = child;
					child.prev = lastChild;
				} else {
					firstChild = child;
				}
				lastChild = child;
			}
			child._parent = this;
			_numChildren++;
		}
		
	}
}
