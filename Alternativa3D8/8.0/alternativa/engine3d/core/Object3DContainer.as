package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.lights.DirectionalLight;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	use namespace alternativa3d;
	
	/**
	 * Базовый контейнер трёхмерных объектов.
	 * Логика контейнеров и child-parent-отношений идентична логике displayObject'ов во Flash.
	 * Дочерние объекты отрисовываются в том порядке, в котором находятся в списке.
	 */
	public class Object3DContainer extends Object3D {
		
		/**
		 * @private 
		 */
		alternativa3d var childrenList:Object3D;
	
		/**
		 * Добавляет дочерний объект. Объект добавляется в конец списка.
		 * Если добавляется объект, предком которого уже является другой контейнер, то объект удаляется из списка потомков старого контейнера.
		 * @param child Добавляемый дочерний объект.
		 * @return Экземпляр Object3D, передаваемый в параметре <code>child</code>.
		 */
		public function addChild(child:Object3D):Object3D {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child == this) throw new ArgumentError("An object cannot be added as a child of itself.");
			for (var container:Object3DContainer = _parent; container != null; container = container._parent) {
				if (container == child) throw new ArgumentError("An object cannot be added as a child to one of it's children (or children's children, etc.).");
			}
			// Удаление из старого родителя
			if (child._parent != null) child._parent.removeChild(child);
			// Добавление
			addToList(child);
			return child;
		}
		
		/**
		 * Удаляет дочерний объект. Свойство <code>parent</code> удаленного объекта получает значение <code>null</code>.
		 * @param child Удаляемый дочерний объект.
		 * @return Экземпляр Object3D, передаваемый в параметре <code>child</code>.
		 */
		public function removeChild(child:Object3D):Object3D {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Удаление
			var prev:Object3D;
			var current:Object3D;
			for (current = childrenList; current != null; current = current.next) {
				if (current == child) {
					if (prev != null) {
						prev.next = current.next;
					} else {
						childrenList = current.next;
					}
					current.next = null;
					current._parent = null;
					return child;
				}
				prev = current;
			}
			throw new ArgumentError("Cannot remove child.");
		}
		
		/**
		 * Добавляет дочерний объект. Объект добавляется в указанную позицию в списке.
		 * @param child Добавляемый дочерний объект.
		 * @param index Позиция, в которую добавляется дочерний объект.
		 * @return Экземпляр Object3D, передаваемый в параметре <code>child</code>.
		 */
		public function addChildAt(child:Object3D, index:int):Object3D {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child == this) throw new ArgumentError("An object cannot be added as a child of itself.");
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			for (var container:Object3DContainer = _parent; container != null; container = container._parent) {
				if (container == child) throw new ArgumentError("An object cannot be added as a child to one of it's children (or children's children, etc.).");
			}
			// Поиск элемента по индексу
			var current:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (current == null) throw new RangeError("The supplied index is out of bounds.");
				current = current.next;
			}
			// Удаление из старого родителя
			if (child._parent != null) child._parent.removeChild(child);
			// Добавление
			addToList(child, current);
			return child;
		}

		/**
		 * Удаляет дочерний объект из заданной позиции. Свойство <code>parent</code> удаленного объекта получает значение <code>null</code>.
		 * @param index Позиция, из которой удаляется дочерний объект.
		 * @return Удаленный экземпляр Object3D.
		 */
		public function removeChildAt(index:int):Object3D {
			// Проверка на ошибки
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			// Поиск элемента по индексу
			var current:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (current == null) throw new RangeError("The supplied index is out of bounds.");
				current = current.next;
			}
			if (current == null) throw new RangeError("The supplied index is out of bounds.");
			// Удаление
			removeChild(current);
			return current;
		}
		
		/**
		 * Возвращает экземпляр дочернего объекта, существующий в заданной позиции.
		 * @param index Позиция дочернего объекта.
		 * @return Дочерний объект с заданной позицией.
		 */
		public function getChildAt(index:int):Object3D {
			// Проверка на ошибки
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			// Поиск элемента по индексу
			var current:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (current == null) throw new RangeError("The supplied index is out of bounds.");
				current = current.next;
			}
			if (current == null) throw new RangeError("The supplied index is out of bounds.");
			return current;
		}
		
		/**
		 * Возвращает позицию дочернего объекта.
		 * @param child Дочерний объект.
		 * @return Позиция заданного дочернего объекта.
		 */
		public function getChildIndex(child:Object3D):int {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Поиск индекса элемента
			var index:int = 0;
			for (var current:Object3D = childrenList; current != null; current = current.next) {
				if (current == child) return index;
				index++;
			}
			throw new ArgumentError("Cannot get child index.");
		}
		
		/**
		 * Устанавливает позицию дочернего объекта.
		 * @param child Дочерний объект.
		 * @param index Устанавливаемая позиция объекта.
		 */
		public function setChildIndex(child:Object3D, index:int):void {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			// Поиск элемента по индексу
			var current:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (current == null) throw new RangeError("The supplied index is out of bounds.");
				current = current.next;
			}
			// Удаление
			removeChild(child);
			// Добавление
			addToList(child, current);
		}
		
		/**
		 * Меняет местами два дочерних объекта в списке.
		 * @param child1 Первый дочерний объект.
		 * @param child2 Второй дочерний объект.
		 */
		public function swapChildren(child1:Object3D, child2:Object3D):void {
			// Проверка на ошибки
			if (child1 == null || child2 == null) throw new TypeError("Parameter child must be non-null.");
			if (child1._parent != this || child2._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Перестановка
			if (child1 != child2) {
				if (child1.next == child2) {
					removeChild(child2);
					addToList(child2, child1);
				} else if (child2.next == child1) {
					removeChild(child1);
					addToList(child1, child2);
				} else {
					var nxt:Object3D = child1.next;
					removeChild(child1);
					addToList(child1, child2);
					removeChild(child2);
					addToList(child2, nxt);
				}
			}
		}
		
		/**
		 * Меняет местами два дочерних объекта в списке по указанным позициям.
		 * @param index1 Позиция первого дочернего объекта.
		 * @param index2 Позиция второго дочернего объекта.
		 */
		public function swapChildrenAt(index1:int, index2:int):void {
			// Проверка на ошибки
			if (index1 < 0 || index2 < 0) throw new RangeError("The supplied index is out of bounds.");
			// Перестановка
			if (index1 != index2) {
				// Поиск элементов по индексам
				var i:int;
				var child1:Object3D = childrenList;
				for (i = 0; i < index1; i++) {
					if (child1 == null) throw new RangeError("The supplied index is out of bounds.");
					child1 = child1.next;
				}
				if (child1 == null) throw new RangeError("The supplied index is out of bounds.");
				var child2:Object3D = childrenList;
				for (i = 0; i < index2; i++) {
					if (child2 == null) throw new RangeError("The supplied index is out of bounds.");
					child2 = child2.next;
				}
				if (child2 == null) throw new RangeError("The supplied index is out of bounds.");
				if (child1 != child2) {
					if (child1.next == child2) {
						removeChild(child2);
						addToList(child2, child1);
					} else if (child2.next == child1) {
						removeChild(child1);
						addToList(child1, child2);
					} else {
						var nxt:Object3D = child1.next;
						removeChild(child1);
						addToList(child1, child2);
						removeChild(child2);
						addToList(child2, nxt);
					}
				}
			}
		}
		
		/**
		 * Возвращает дочерний объект с заданным именем.
		 * Если объектов с заданным именем несколько, возвратится первый попавшийся.
		 * Если объект с заданным именем не содержится в контейнере, возвратится <code>null</code>.
		 * @param name Имя дочернего объекта.
		 * @return Дочерний объект с заданным именем.
		 */
		public function getChildByName(name:String):Object3D {
			// Проверка на ошибки
			if (name == null) throw new TypeError("Parameter name must be non-null.");
			// Поиск объекта
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.name == name) return child;
			}
			return null;
		}
		
		/**
		 * Определяет, содержится ли заданный объект среди дочерних объектов.
		 * Область поиска охватывает часть иерархии, начиная с данного Object3DContainer.
		 * @param child Дочерний объект.
		 * @return Значение <code>true</code>, если заданный объект является самим контейнером или одним из его потомков, в противном случае значение <code>false</code>.
		 */
		public function contains(child:Object3D):Boolean {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			// Поиск объекта
			if (child == this) return true;
			for (var object:Object3D = childrenList; object != null; object = object.next) {
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
		
		/**
		 * Возвращает количество дочерних объектов.
		 */
		public function get numChildren():int {
			var num:int = 0;
			for (var current:Object3D = childrenList; current != null; current = current.next) num++;
			return num;
		}
		
		/**
		 * @inheritDoc
		 */
		 override public function intersectRay(origin:Vector3D, direction:Vector3D, exludedObjects:Dictionary = null, camera:Camera3D = null):RayIntersectionData {
		 	if (exludedObjects != null && exludedObjects[this]) return null;
			if (!boundIntersectRay(origin, direction, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ)) return null;
			var res:RayIntersectionData;
			var minTime:Number = 1e+22;
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				child.composeMatrix();
				child.cameraMatrix.invert();
				var childOrigin:Vector3D = child.cameraMatrix.transformVector(origin);
				var childDirection:Vector3D = child.cameraMatrix.deltaTransformVector(direction);
				var data:RayIntersectionData = child.intersectRay(childOrigin, childDirection, exludedObjects, camera);
				if (data != null && data.time < minTime) {
					minTime = data.time;
					res = data;
				}
			}
			return res;
		 }
		 
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var container:Object3DContainer = new Object3DContainer();
			container.cloneBaseProperties(this);
			for (var child:Object3D = childrenList, lastChild:Object3D; child != null; child = child.next) {
				var newChild:Object3D = child.clone();
				if (container.childrenList != null) {
					lastChild.next = newChild;
				} else {
					container.childrenList = newChild;
				}
				lastChild = newChild;
				newChild._parent = container;
			}
			return container;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D):void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.visible) {
					child.composeMatrix();
					child.cameraMatrix.append(cameraMatrix);
					if (child.cullingInCamera(camera, culling) >= 0) {
						if (child.isTransparent) {
							camera.transparentObjects[int(camera.numTransparent++)] = child;
						} else {
							child.draw(camera);
						}
					}
				}
			}
		}

		/**
		 * @private 
		 */
		override alternativa3d function drawInShadowMap(camera:Camera3D, light:DirectionalLight):void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.visible && !child.isTransparent && child.useShadows) {
					child.composeMatrix();
					child.cameraMatrix.append(cameraMatrix);
					if (child.cullingInLight(light, culling) >= 0) {
						child.drawInShadowMap(camera, light);
					}
				}
			}
		}

		/**
		 * @private 
		 */
		override alternativa3d function updateBounds(bounds:Object3D, matrix:Matrix3D = null):void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				child.composeMatrix();
				if (matrix != null) child.cameraMatrix.append(matrix);
				child.updateBounds(bounds, child.cameraMatrix);
			}
		}
		
		/**
		 * @private 
		 */
		alternativa3d function addToList(child:Object3D, item:Object3D = null):void {
			child.next = item;
			child._parent = this;
			if (item == childrenList) {
				childrenList = child;
			} else {
				for (var current:Object3D = childrenList; current != null; current = current.next) {
					if (current.next == item) {
						current.next = child;
						break;
					}
				}
			}
		}
		
	}
}
