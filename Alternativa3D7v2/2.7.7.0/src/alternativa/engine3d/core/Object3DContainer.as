package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	import __AS3__.vec.Vector;
	import flash.utils.Dictionary;
	
	use namespace alternativa3d;
	
	/**
	 * Базовый контейнер трёхмерных объектов.
	 * Логика контейнеров и child-parent-отношений идентична логике displayObject'ов во Flash.
	 * Дочерние объекты отрисовываются в том порядке, в котором находятся в списке.
	 */
	public class Object3DContainer extends Object3D {
		
		/**
		 * Определяет, включен ли переход между потомками объекта с помощью мыши.
		 * Если <code>false</code>, то в качестве <code>target</code> события будет сам контейнер, независимо от его содержимого.
		 * Значение по умолчанию — <code>true</code>.
		 * Примечание: для обработки событий мыши необходимо установить в <code>true</code> свойство <code>interactive</code> объекта <code>View</code>.
		 */
		public var mouseChildren:Boolean = true;
		
		/**
		 * @private 
		 */
		alternativa3d var childrenList:Object3D;
	
		/**
		 * @private 
		 */
		alternativa3d var visibleChildren:Vector.<Object3D> = new Vector.<Object3D>();
		
		/**
		 * @private 
		 */
		alternativa3d var numVisibleChildren:int = 0;
		
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
		 * Усианавливает позицию дочернего объекта.
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
			var childOrigin:Vector3D;
			var childDirection:Vector3D;
			var res:RayIntersectionData;
			var minTime:Number = 1e+22;
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				child.composeMatrix();
				child.invertMatrix();
				if (childOrigin == null) {
					childOrigin = new Vector3D();
					childDirection = new Vector3D();
				}
				childOrigin.x = child.ma*origin.x + child.mb*origin.y + child.mc*origin.z + child.md;
				childOrigin.y = child.me*origin.x + child.mf*origin.y + child.mg*origin.z + child.mh;
				childOrigin.z = child.mi*origin.x + child.mj*origin.y + child.mk*origin.z + child.ml;
				childDirection.x = child.ma*direction.x + child.mb*direction.y + child.mc*direction.z;
				childDirection.y = child.me*direction.x + child.mf*direction.y + child.mg*direction.z;
				childDirection.z = child.mi*direction.x + child.mj*direction.y + child.mk*direction.z;
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
			var res:Object3DContainer = new Object3DContainer();
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:Object3DContainer = source as Object3DContainer;
			mouseChildren = src.mouseChildren;
			for (var child:Object3D = src.childrenList, lastChild:Object3D; child != null; child = child.next) {
				var newChild:Object3D = child.clone();
				if (childrenList != null) {
					lastChild.next = newChild;
				} else {
					childrenList = newChild;
				}
				lastChild = newChild;
				newChild._parent = this;
			}
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas):void {
			var canvas:Canvas;
			var debug:int;
			// Сбор видимых объектов
			numVisibleChildren = 0;
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.visible) {
					child.composeAndAppend(this);
					if (child.cullingInCamera(camera, culling) >= 0) {
						visibleChildren[numVisibleChildren] = child;
						numVisibleChildren++;
					}
				}
			}
			// Если есть видимые объекты
			if (numVisibleChildren > 0) {
				// Дебаг
				if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
					canvas = parentCanvas.getChildCanvas(true, false);
					if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, this, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
				}
				// Отрисовка
				canvas = parentCanvas.getChildCanvas(false, true, this, alpha, blendMode, colorTransform, filters);
				canvas.numDraws = 0;
				// Отрисовка видимых объектов
				drawVisibleChildren(camera, canvas);
				// Если была отрисовка
				if (canvas.numDraws > 0) {
					canvas.removeChildren(canvas.numDraws);
				} else {
					parentCanvas.numDraws--;
				}
			}
		}
	
		/**
		 * @private 
		 */
		alternativa3d function drawVisibleChildren(camera:Camera3D, canvas:Canvas):void {
			for (var i:int = numVisibleChildren - 1; i >= 0; i--) {
				var child:Object3D = visibleChildren[i];
				child.draw(camera, canvas);
				visibleChildren[i] = null;
			}
		}
	
		/**
		 * @private 
		 */
		override alternativa3d function getVG(camera:Camera3D):VG {
			var res:VG = collectVG(camera);
			colorizeVG(res);
			return res;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function collectVG(camera:Camera3D):VG {
			var first:VG;
			var last:VG;
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.visible) {
					child.composeAndAppend(this);
					if (child.cullingInCamera(camera, culling) >= 0) {
						var geometry:VG = child.getVG(camera);
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
			return first;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function colorizeVG(vgList:VG):void {
			var geometry:VG;
			if (alpha != 1) {
				for (geometry = vgList; geometry != null; geometry = geometry.next) {
					geometry.alpha *= alpha;
				}
			}
			if (blendMode != "normal") {
				for (geometry = vgList; geometry != null; geometry = geometry.next) {
					if (geometry.blendMode == "normal") {
						geometry.blendMode = blendMode;
					}
				}
			}
			if (colorTransform != null) {
				for (geometry = vgList; geometry != null; geometry = geometry.next) {
					if (geometry.colorTransform != null) {
						var ct:ColorTransform = new ColorTransform(colorTransform.redMultiplier, colorTransform.greenMultiplier, colorTransform.blueMultiplier, colorTransform.alphaMultiplier, colorTransform.redOffset, colorTransform.greenOffset, colorTransform.blueOffset, colorTransform.alphaOffset);
						ct.concat(geometry.colorTransform);
						geometry.colorTransform = ct;
					} else {
						geometry.colorTransform = colorTransform;
					}
				}
			}
			if (filters != null) {
				for (geometry = vgList; geometry != null; geometry = geometry.next) {
					if (geometry.filters != null) {
						var i:int;
						var fs:Array = new Array();
						var fsLength:int = 0;
						var num:int = geometry.filters.length;
						for (i = 0; i < num; i++) {
							fs[fsLength] = geometry.filters[i];
							fsLength++;
						}
						num = filters.length;
						for (i = 0; i < num; i++) {
							fs[fsLength] = filters[i];
							fsLength++;
						}
						geometry.filters = fs;
					} else {
						geometry.filters = filters;
					}
				}
			}
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (transformation != null) {
					child.composeAndAppend(transformation);
				} else {
					child.composeMatrix();
				}
				child.updateBounds(bounds, child);
			}
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function split(a:Vector3D, b:Vector3D, c:Vector3D, threshold:Number):Vector.<Object3D> {
			var res:Vector.<Object3D> = new Vector.<Object3D>(2);
			// Расчёт плоскости
			var plane:Vector3D = calculatePlane(a, b, c);
			// Подготовка к разделению
			var childrenList:Object3D = this.childrenList;
			this.childrenList = null;
			// Разделение
			var negativeContainer:Object3DContainer = clone() as Object3DContainer;
			var positiveContainer:Object3DContainer = clone() as Object3DContainer;
			var negativeLast:Object3D;
			var positiveLast:Object3D;
			for (var object:Object3D = childrenList; object != null; object = next) {
				var next:Object3D = object.next;
				object.next = null;
				object._parent = null;
				object.composeMatrix();
				object.calculateInverseMatrix();
				var ca:Vector3D = new Vector3D(object.ima*a.x + object.imb*a.y + object.imc*a.z + object.imd, object.ime*a.x + object.imf*a.y + object.img*a.z + object.imh, object.imi*a.x + object.imj*a.y + object.imk*a.z + object.iml);
				var cb:Vector3D = new Vector3D(object.ima*b.x + object.imb*b.y + object.imc*b.z + object.imd, object.ime*b.x + object.imf*b.y + object.img*b.z + object.imh, object.imi*b.x + object.imj*b.y + object.imk*b.z + object.iml);
				var cc:Vector3D = new Vector3D(object.ima*c.x + object.imb*c.y + object.imc*c.z + object.imd, object.ime*c.x + object.imf*c.y + object.img*c.z + object.imh, object.imi*c.x + object.imj*c.y + object.imk*c.z + object.iml);
				var testSplitResult:int = object.testSplit(ca, cb, cc, threshold);
				if (testSplitResult < 0) {
					if (negativeLast != null) {
						negativeLast.next = object;
					} else {
						negativeContainer.childrenList = object;
					}
					negativeLast = object;
					object._parent = negativeContainer;
				} else if (testSplitResult > 0) {
					if (positiveLast != null) {
						positiveLast.next = object;
					} else {
						positiveContainer.childrenList = object;
					}
					positiveLast = object;
					object._parent = positiveContainer;
				} else {
					var splitResult:Vector.<Object3D> = object.split(ca, cb, cc, threshold);
					var distance:Number = object.distance;
					if (splitResult[0] != null) {
						object = splitResult[0];
						if (negativeLast != null) {
							negativeLast.next = object;
						} else {
							negativeContainer.childrenList = object;
						}
						negativeLast = object;
						object._parent = negativeContainer;
						object.distance = distance;
					}
					if (splitResult[1] != null) {
						object = splitResult[1];
						if (positiveLast != null) {
							positiveLast.next = object;
						} else {
							positiveContainer.childrenList = object;
						}
						positiveLast = object;
						object._parent = positiveContainer;
						object.distance = distance;
					}
				}
			}
			if (negativeLast != null) {
				negativeContainer.calculateBounds();
				res[0] = negativeContainer;
			}
			if (positiveLast != null) {
				positiveContainer.calculateBounds();
				res[1] = positiveContainer;
			}
			return res;
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
