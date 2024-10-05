package alternativa.engine3d.containers {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.VG;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	import __AS3__.vec.Vector;
	import alternativa.engine3d.core.Debug;
	import flash.geom.ColorTransform;
	import flash.utils.Dictionary;
	
	use namespace alternativa3d;
	
	/**
	 * Контейнер, имеющий набор дочерних объектов с разной детализацией.
	 * Каждому дочернему объекту соответствует дистанция, в пределах которой он виден.
	 * При отрисовке расчитывается расстояние до камеры и выбирается дочерний объект с наиболее подходящей дистанцией. Остальные дочерние объекты не отрисовываются.
	 */
	public class LODContainer extends Object3DContainer {
	
		/**
		 * Возвращает дистанцию, соответствующую заданному объекту.
		 * @param child Дочерний объект.
		 * @return Дистанция, соответствующая заданному дочернему объекту.
		 */
		public function getChildDistance(child:Object3D):Number {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			return child.distance;
		}
		
		/**
		 * Устанавливает соответствие дистанции дочернему объекту.
		 * @param child Дочерний объект.
		 * @param distance Устанавливаемая дистанция.
		 */
		public function setChildDistance(child:Object3D, distance:Number):void {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			child.distance = distance;
		}
		
		/**
		 * Добавляет дочерний объект и устанавливает для него дистанцию.
		 * Если добавляется объект, предком которого уже является другой контейнер, то объект удаляется из списка потомков старого контейнера. 
		 * @param lod Добавляемый дочерний объект.
		 * @param distance Устанавливаемая дистанция.
		 * @return Экземпляр Object3D, передаваемый в параметре <code>lod</code>.
		 */
		public function addLOD(lod:Object3D, distance:Number):Object3D {
			addChild(lod);
			lod.distance = distance;
			return lod;
		}
		
		/**
		 * @private
		 */
		override public function addChild(child:Object3D):Object3D {
			// Проверка на ошибки
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child == this) throw new ArgumentError("An object cannot be added as a child of itself.");
			for (var container:Object3DContainer = _parent; container != null; container = container._parent) {
				if (container == child) throw new ArgumentError("An object cannot be added as a child to one of it's children (or children's children, etc.).");
			}
			// Сброс дистанции
			if (child._parent != this) child.distance = 0;
			// Удаление из старого родителя
			if (child._parent != null) child._parent.removeChild(child);
			// Добавление
			addToList(child);
			return child;
		}
		
		/**
		 * @private
		 */
		override public function addChildAt(child:Object3D, index:int):Object3D {
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
			// Сброс дистанции
			if (child._parent != this) child.distance = 0;
			// Удаление из старого родителя
			if (child._parent != null) child._parent.removeChild(child);
			// Добавление
			addToList(child, current);
			return child;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var container:LODContainer = new LODContainer();
			container.cloneBaseProperties(this);
			container.mouseChildren = mouseChildren;
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
		override alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas):void {
			var lod:Object3D = getLODObject(camera);
			if (lod != null && lod.visible) {
				lod.composeAndAppend(this);
				if (lod.cullingInCamera(camera, culling) >= 0) {
					var canvas:Canvas;
					// Дебаг
					var debug:int;
					if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
						canvas = parentCanvas.getChildCanvas(true, false);
						if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, this, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
					}
					// Отрисовка
					canvas = parentCanvas.getChildCanvas(false, true, this, alpha, blendMode, colorTransform, filters);
					canvas.numDraws = 0;
					lod.draw(camera, canvas);
					// Если была отрисовка
					if (canvas.numDraws > 0) {
						canvas.removeChildren(canvas.numDraws);
					} else {
						parentCanvas.numDraws--;
					}
				}
			}
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function getVG(camera:Camera3D):VG {
			var geometry:VG;
			var lod:Object3D = getLODObject(camera);
			if (lod != null && lod.visible) {
				lod.composeAndAppend(this);
				if (lod.cullingInCamera(camera, culling) >= 0) {
					geometry = lod.getVG(camera);
					if (alpha != 1) {
						geometry.alpha *= alpha;
					}
					if (blendMode != "normal") {
						if (geometry.blendMode == "normal") {
							geometry.blendMode = blendMode;
						}
					}
					if (colorTransform != null) {
						if (geometry.colorTransform != null) {
							var ct:ColorTransform = new ColorTransform(colorTransform.redMultiplier, colorTransform.greenMultiplier, colorTransform.blueMultiplier, colorTransform.alphaMultiplier, colorTransform.redOffset, colorTransform.greenOffset, colorTransform.blueOffset, colorTransform.alphaOffset);
							ct.concat(geometry.colorTransform);
							geometry.colorTransform = ct;
						} else {
							geometry.colorTransform = colorTransform;
						}
					}
					if (filters != null) {
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
			return geometry;
		}
		
		private function getLODObject(camera:Camera3D):Object3D {
			var dx:Number = md*camera.viewSizeX/camera.focalLength;
			var dy:Number = mh*camera.viewSizeY/camera.focalLength;
			var distance:Number = Math.sqrt(dx*dx + dy*dy + ml*ml);
			var min:Number = 1e+22;
			var lod:Object3D;
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				var d:Number = child.distance - distance;
				if (d > 0 && d < min) {
					min = d;
					lod = child;
				}
			}
			return lod;
		}
		
	}
}
