package alternativa.engine3d.containers {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.VG;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.objects.Occluder;
	
	use namespace alternativa3d;
	
	/**
	 * Контейнер, который помимо дочерних объектов содержит бинарную древовидную структуру — KD-дерево.
	 * KD-дерево строится с помощью вызова метода <code>createTree()</code> по баунд-боксам переданных статических объектов.
	 * KD-дерево состоит из KD-нод, плоскости которых ориентированы по локальным осям контейнера.
	 * KD-ноды содержат переданные статические объекты.
	 * Статическим объектам в качестве <code>parent</code> назначается контейнер, то есть они в какой-то мере становятся дочерними, однако они не содержатся в списке дочерних объектов и их нельзя удалить.
	 * При отрисовке дочерние объекты контейнера отрисовываются с учётом KD-дерева, они как бы проваливаются в древовидную структуру.
	 * <code>KDContainer</code> наследован от <code>ConflictContainer</code>, поэтому в конечных нодах дерева действуют алгоритмы сортировки разделением.
	 * Если дерево не построено, <code>KDContainer</code> ведёт себя как <code>ConflictContainer</code>.
	 * @see alternativa.engine3d.containers.ConflictContainer
	 * @see #createTree()
	 * @see #destroyTree()
	 */
	public class KDContainer extends ConflictContainer {
	
		/**
		 * Параметр затухания изображения нод в режиме отладки.
		 * Значение по умолчанию — <code>0.8</code>.
		 * @see alternativa.engine3d.core.Debug
		 */
		public var debugAlphaFade:Number = 0.8;
	
		/**
		 * @private 
		 */
		alternativa3d var root:KDNode;
	
		// Плоскости отсечения камеры в контейнере
		private var nearPlaneX:Number;
		private var nearPlaneY:Number;
		private var nearPlaneZ:Number;
		private var nearPlaneOffset:Number;
		private var farPlaneX:Number;
		private var farPlaneY:Number;
		private var farPlaneZ:Number;
		private var farPlaneOffset:Number;
		private var leftPlaneX:Number;
		private var leftPlaneY:Number;
		private var leftPlaneZ:Number;
		private var leftPlaneOffset:Number;
		private var rightPlaneX:Number;
		private var rightPlaneY:Number;
		private var rightPlaneZ:Number;
		private var rightPlaneOffset:Number;
		private var topPlaneX:Number;
		private var topPlaneY:Number;
		private var topPlaneZ:Number;
		private var topPlaneOffset:Number;
		private var bottomPlaneX:Number;
		private var bottomPlaneY:Number;
		private var bottomPlaneZ:Number;
		private var bottomPlaneOffset:Number;
	
		// Перекрытия
		private var occluders:Vector.<Vertex> = new Vector.<Vertex>();
		private var numOccluders:int;
		
		/**
		 * Строит KD-дерево по баунд-боксам переданных статических объектов.
		 * Перед построением старое дерево разрушается.
		 * После построения статические объекты и окклюдеры остаются в дереве.
		 * @param staticObjects Статические объекты.
		 * @param staticOccluders Статические окклюдеры.
		 * @see alternativa.engine3d.objects.Occluder
		 * @see #destroyTree()
		 */
		public function createTree(staticObjects:Vector.<Object3D>, staticOccluders:Vector.<Occluder> = null):void {
			destroyTree();
			var i:int;
			var object:Object3D;
			var bound:Object3D;
			var staticObjectsLength:int = staticObjects.length;
			var staticOccludersLength:int = (staticOccluders != null) ? staticOccluders.length : 0;
			var objectList:Object3D;
			var objectBoundList:Object3D;
			var occluderList:Object3D;
			var occluderBoundList:Object3D;
			// Баунд корневой ноды
			var minX:Number = 1e+22;
			var minY:Number = 1e+22;
			var minZ:Number = 1e+22;
			var maxX:Number = -1e+22;
			var maxY:Number = -1e+22;
			var maxZ:Number = -1e+22;
			// Обработка объектов
			for (i = 0; i < staticObjectsLength; i++) {
				object = staticObjects[i];
				// Расчёт баунда в координатах дерева
				bound = createObjectBounds(object);
				// Если объект не пустой
				if (bound.boundMinX <= bound.boundMaxX) {
					if (object._parent != null) object._parent.removeChild(object);
					object._parent = this;
					object.next = objectList;
					objectList = object;
					bound.next = objectBoundList;
					objectBoundList = bound;
					// Коррекция баунда корневой ноды
					if (bound.boundMinX < minX) minX = bound.boundMinX;
					if (bound.boundMaxX > maxX) maxX = bound.boundMaxX;
					if (bound.boundMinY < minY) minY = bound.boundMinY;
					if (bound.boundMaxY > maxY) maxY = bound.boundMaxY;
					if (bound.boundMinZ < minZ) minZ = bound.boundMinZ;
					if (bound.boundMaxZ > maxZ) maxZ = bound.boundMaxZ;
				}
			}
			// Обработка окклюдеров
			for (i = 0; i < staticOccludersLength; i++) {
				object = staticOccluders[i];
				// Расчёт баунда в координатах дерева
				bound = createObjectBounds(object);
				// Если объект не пустой
				if (bound.boundMinX <= bound.boundMaxX) {
					// Проверка выхода окклюдера за границы ноды
					if (bound.boundMinX < minX || bound.boundMaxX > maxX || bound.boundMinY < minY || bound.boundMaxY > maxY || bound.boundMinZ < minZ || bound.boundMaxZ > maxZ) {
						trace("Incorrect occluder size or position");
					} else {
						if (object._parent != null) object._parent.removeChild(object);
						object._parent = this;
						object.next = occluderList;
						occluderList = object;
						bound.next = occluderBoundList;
						occluderBoundList = bound;
					}
				}
			}
			// Если есть непустые объекты
			if (objectList != null) {
				root = createNode(objectList, objectBoundList, occluderList, occluderBoundList, minX, minY, minZ, maxX, maxY, maxZ);
			}
		}
		
		/**
		 * Разрушает KD-дерево.
		 * После этого статические объекты становятся независимыми.
		 * @see #createTree()
		 */
		public function destroyTree():void {
			if (root != null) {
				destroyNode(root);
				root = null;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas):void {
			var canvas:Canvas;
			var debug:int;
			// Если есть корневая нода
			if (root != null) {
				// Расчёт инверсной матрицы камеры
				calculateInverseMatrix();
				// Расчёт плоскостей камеры в контейнере
				calculateCameraPlanes(camera.nearClipping, camera.farClipping);
				// Проверка на видимость рутовой ноды
				var rootCulling:int = cullingInContainer(culling, root.boundMinX, root.boundMinY, root.boundMinZ, root.boundMaxX, root.boundMaxY, root.boundMaxZ);
				if (rootCulling >= 0) {
					// Дебаг
					if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
						canvas = parentCanvas.getChildCanvas(true, false);
						if (debug & Debug.NODES) {
							debugNode(root, rootCulling, camera, canvas, 1);
							Debug.drawBounds(camera, canvas, this, root.boundMinX, root.boundMinY, root.boundMinZ, root.boundMaxX, root.boundMaxY, root.boundMaxZ, 0xDD33DD);
						}
						if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, this, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
					}
					// Отрисовка
					canvas = parentCanvas.getChildCanvas(false, true, this, alpha, blendMode, colorTransform, filters);
					canvas.numDraws = 0;
					// Окклюдеры
					numOccluders = 0;
					if (camera.numOccluders > 0) {
						updateOccluders(camera);
					}
					// Сбор видимой геометрии
					var geometry:VG = getVG(camera);
					for (var current:VG = geometry; current != null; current = current.next) {
						current.calculateAABB(ima, imb, imc, imd, ime, imf, img, imh, imi, imj, imk, iml);
					}
					// Отрисовка дерева
					drawNode(root, rootCulling, camera, canvas, geometry);
					// Зачиска окклюдеров
					for (var i:int = 0; i < numOccluders; i++) {
						var first:Vertex = occluders[i];
						for (var last:Vertex = first; last.next != null; last = last.next);
						last.next = Vertex.collector;
						Vertex.collector = first;
						occluders[i] = null;
					}
					numOccluders = 0;
					// Если была отрисовка
					if (canvas.numDraws > 0) {
						canvas.removeChildren(canvas.numDraws);
					} else {
						parentCanvas.numDraws--;
					}
				} else {
					super.draw(camera, parentCanvas);
				}
			} else {
				super.draw(camera, parentCanvas);
			}
		}
	
		private function debugNode(node:KDNode, culling:int, camera:Camera3D, canvas:Canvas, alpha:Number):void {
			if (node != null && node.negative != null) {
				var negativeCulling:int = (culling > 0) ? cullingInContainer(culling, node.negative.boundMinX, node.negative.boundMinY, node.negative.boundMinZ, node.negative.boundMaxX, node.negative.boundMaxY, node.negative.boundMaxZ) : 0;
				var positiveCulling:int = (culling > 0) ? cullingInContainer(culling, node.positive.boundMinX, node.positive.boundMinY, node.positive.boundMinZ, node.positive.boundMaxX, node.positive.boundMaxY, node.positive.boundMaxZ) : 0;
				if (negativeCulling >= 0) {
					debugNode(node.negative, negativeCulling, camera, canvas, alpha*debugAlphaFade);
				}
				Debug.drawKDNode(camera, canvas, this, node.axis, node.coord, node.boundMinX, node.boundMinY, node.boundMinZ, node.boundMaxX, node.boundMaxY, node.boundMaxZ, alpha);
				if (positiveCulling >= 0) {
					debugNode(node.positive, positiveCulling, camera, canvas, alpha*debugAlphaFade);
				}
			}
		}
	
		private function drawNode(node:KDNode, culling:int, camera:Camera3D, canvas:Canvas, geometry:VG):void {
			var i:int;
			var next:VG;
			var negative:VG;
			var middle:VG;
			var positive:VG;
			if (camera.occludedAll) {
				while (geometry != null) {
					next = geometry.next;
					geometry.destroy();
					geometry = next;
				}
				return;
			}
			var child:Object3D;
			var bound:Object3D;
			// Узловая нода
			if (node.negative != null) {
				var negativeCulling:int = (culling > 0 || numOccluders > 0) ? cullingInContainer(culling, node.negative.boundMinX, node.negative.boundMinY, node.negative.boundMinZ, node.negative.boundMaxX, node.negative.boundMaxY, node.negative.boundMaxZ) : 0;
				var positiveCulling:int = (culling > 0 || numOccluders > 0) ? cullingInContainer(culling, node.positive.boundMinX, node.positive.boundMinY, node.positive.boundMinZ, node.positive.boundMaxX, node.positive.boundMaxY, node.positive.boundMaxZ) : 0;
				var axisX:Boolean = node.axis == 0;
				var axisY:Boolean = node.axis == 1;
				var min:Number;
				var max:Number;
				// Если видны обе дочерние ноды
				if (negativeCulling >= 0 && positiveCulling >= 0) {
					// Перебор динамиков
					while (geometry != null) {
						next = geometry.next;
						// Проверка с окклюдерами
						if (geometry.numOccluders < numOccluders && occludeGeometry(camera, geometry)) {
							geometry.destroy();
						} else {
							min = axisX ? geometry.boundMinX : (axisY ? geometry.boundMinY : geometry.boundMinZ);
							max = axisX ? geometry.boundMaxX : (axisY ? geometry.boundMaxY : geometry.boundMaxZ);
							if (max <= node.maxCoord) {
								if (min < node.minCoord) {
									geometry.next = negative;
									negative = geometry;
								} else {
									geometry.next = middle;
									middle = geometry;
								}
							} else if (min >= node.minCoord) {
								geometry.next = positive;
								positive = geometry;
							} else {
								geometry.split(camera, (node.axis == 0) ? 1 : 0, (node.axis == 1) ? 1 : 0, (node.axis == 2) ? 1 : 0, node.coord, threshold);
								// Если негативный не пустой
								if (geometry.next != null) {
									geometry.next.next = negative;
									negative = geometry.next;
								}
								// Если позитивный не пустой
								if (geometry.faceStruct != null) {
									geometry.next = positive;
									positive = geometry;
								} else {
									geometry.destroy();
								}
							}
						}
						geometry = next;
					}
					// Отрисовка дочерних нод и объектов в плоскости
					if (axisX && imd > node.coord || axisY && imh > node.coord || !axisX && !axisY && iml > node.coord) {
						// Отрисовка позитивной ноды
						drawNode(node.positive, positiveCulling, camera, canvas, positive);
						// Отрисовка динамических объектов в ноде
						while (middle != null) {
							next = middle.next;
							// Проверка с окклюдерами и отрисовка
							if (middle.numOccluders >= numOccluders || !occludeGeometry(camera, middle)) {
								middle.draw(camera, canvas, threshold, this);
							}
							middle.destroy();
							middle = next;
						}
						// Отрисовка плоских статических объектов в ноде
						for (child = node.objectList, bound = node.objectBoundList; child != null; child = child.next, bound = bound.next) {
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, bound.boundMinX, bound.boundMinY, bound.boundMinZ, bound.boundMaxX, bound.boundMaxY, bound.boundMaxZ)) >= 0)) {
								child.composeAndAppend(this);
								child.draw(camera, canvas);
							}
						}
						for (child = node.occluderList, bound = node.occluderBoundList; child != null; child = child.next, bound = bound.next) {
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, bound.boundMinX, bound.boundMinY, bound.boundMinZ, bound.boundMaxX, bound.boundMaxY, bound.boundMaxZ)) >= 0)) {
								child.composeAndAppend(this);
								child.draw(camera, canvas);
							}
						}
						// Обновление окклюдеров
						if (node.occluderList != null) {
							updateOccluders(camera);
						}
						// Отрисовка негативной ноды
						drawNode(node.negative, negativeCulling, camera, canvas, negative);
					} else {
						// Отрисовка негативной ноды
						drawNode(node.negative, negativeCulling, camera, canvas, negative);
						// Отрисовка динамических объектов в ноде
						while (middle != null) {
							next = middle.next;
							// Проверка с окклюдерами и отрисовка
							if (middle.numOccluders >= numOccluders || !occludeGeometry(camera, middle)) {
								middle.draw(camera, canvas, threshold, this);
							}
							middle.destroy();
							middle = next;
						}
						// Отрисовка плоских статических объектов в ноде
						for (child = node.objectList, bound = node.objectBoundList; child != null; child = child.next, bound = bound.next) {
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, bound.boundMinX, bound.boundMinY, bound.boundMinZ, bound.boundMaxX, bound.boundMaxY, bound.boundMaxZ)) >= 0)) {
								child.composeAndAppend(this);
								child.draw(camera, canvas);
							}
						}
						for (child = node.occluderList, bound = node.occluderBoundList; child != null; child = child.next, bound = bound.next) {
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, bound.boundMinX, bound.boundMinY, bound.boundMinZ, bound.boundMaxX, bound.boundMaxY, bound.boundMaxZ)) >= 0)) {
								child.composeAndAppend(this);
								child.draw(camera, canvas);
							}
						}
						// Обновление окклюдеров
						if (node.occluderList != null) {
							updateOccluders(camera);
						}
						// Отрисовка позитивной ноды
						drawNode(node.positive, positiveCulling, camera, canvas, positive);
					}
				// Если видна только негативная
				} else if (negativeCulling >= 0) {
					// Перебор динамиков
					while (geometry != null) {
						next = geometry.next;
						// Проверка с окклюдерами
						if (geometry.numOccluders < numOccluders && occludeGeometry(camera, geometry)) {
							geometry.destroy();
						} else {
							min = axisX ? geometry.boundMinX : (axisY ? geometry.boundMinY : geometry.boundMinZ);
							max = axisX ? geometry.boundMaxX : (axisY ? geometry.boundMaxY : geometry.boundMaxZ);
							if (max <= node.maxCoord) {
								geometry.next = negative;
								negative = geometry;
							} else if (min >= node.minCoord) {
								geometry.destroy();
							} else {
								geometry.crop(camera, (node.axis == 0) ? -1 : 0, (node.axis == 1) ? -1 : 0, (node.axis == 2) ? -1 : 0, -node.coord, threshold);
								// Если негативный не пустой
								if (geometry.faceStruct != null) {
									geometry.next = negative;
									negative = geometry;
								} else {
									geometry.destroy();
								}
							}
						}
						geometry = next;
					}
					// Отрисовка негативной ноды
					drawNode(node.negative, negativeCulling, camera, canvas, negative);
				// Если видна только позитивная
				} else if (positiveCulling >= 0) {
					// Перебор динамиков
					while (geometry != null) {
						next = geometry.next;
						// Проверка с окклюдерами
						if (geometry.numOccluders < numOccluders && occludeGeometry(camera, geometry)) {
							geometry.destroy();
						} else {
							min = axisX ? geometry.boundMinX : (axisY ? geometry.boundMinY : geometry.boundMinZ);
							max = axisX ? geometry.boundMaxX : (axisY ? geometry.boundMaxY : geometry.boundMaxZ);
							if (max <= node.maxCoord) {
								geometry.destroy();
							} else if (min >= node.minCoord) {
								geometry.next = positive;
								positive = geometry;
							} else {
								geometry.crop(camera, (node.axis == 0) ? 1 : 0, (node.axis == 1) ? 1 : 0, (node.axis == 2) ? 1 : 0, node.coord, threshold);
								// Если позитивный не пустой
								if (geometry.faceStruct != null) {
									geometry.next = positive;
									positive = geometry;
								} else {
									geometry.destroy();
								}
							}
						}
						geometry = next;
					}
					// Отрисовка позитивной ноды
					drawNode(node.positive, positiveCulling, camera, canvas, positive);
				// Если обе ноды не видны
				} else {
					// Уничтожение динамиков
					while (geometry != null) {
						next = geometry.next;
						geometry.destroy();
						geometry = next;
					}
				}
			// Конечная нода
			} else {
				// Если есть статические объекты, не считая окклюдеры
				if (node.objectList != null) {
					// Если есть конфликт
					if (node.objectList.next != null || geometry != null) {
						// Перебор динамиков
						while (geometry != null) {
							next = geometry.next;
							// Проверка с окклюдерами
							if (geometry.numOccluders < numOccluders && occludeGeometry(camera, geometry)) {
								geometry.destroy();
							} else {
								geometry.next = middle;
								middle = geometry;
							}
							geometry = next;
						}
						// Превращение статиков в геометрию
						for (child = node.objectList, bound = node.objectBoundList; child != null; child = child.next, bound = bound.next) {
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, bound.boundMinX, bound.boundMinY, bound.boundMinZ, bound.boundMaxX, bound.boundMaxY, bound.boundMaxZ)) >= 0)) {
								child.composeAndAppend(this);
								geometry = child.getVG(camera);
								while (geometry != null) {
									next = geometry.next;
									geometry.next = middle;
									middle = geometry;
									geometry = next;
								}
							}
						}
						// Разруливаем конфликт
						if (middle != null) {
							if (middle.next != null) {
								drawConflictGeometry(camera, canvas, middle);
							} else {
								middle.draw(camera, canvas, threshold, this);
								middle.destroy();
							}
						}
					} else {
						// Если только один статик
						child = node.objectList;
						if (child.visible) {
							child.composeAndAppend(this);
							child.culling = culling;
							child.draw(camera, canvas);
						}
					}
				// Если нет статических объектов
				} else {
					// Если есть динамические объекты
					if (geometry != null) {
						// Если динамических объектов несколько
						if (geometry.next != null) {
							// Если есть окклюдеры
							if (numOccluders > 0) {
								// Перебор динамиков
								while (geometry != null) {
									next = geometry.next;
									// Проверка с окклюдерами
									if (geometry.numOccluders < numOccluders && occludeGeometry(camera, geometry)) {
										geometry.destroy();
									} else {
										geometry.next = middle;
										middle = geometry;
									}
									geometry = next;
								}
								// Если остались объекты
								if (middle != null) {
									if (middle.next != null) {
										// Разруливание
										if (resolveByAABB) {
											drawAABBGeometry(camera, canvas, middle);
										} else if (resolveByOOBB) {
											for (geometry = middle; geometry != null; geometry = geometry.next) {
												geometry.calculateOOBB(this);
											}
											drawOOBBGeometry(camera, canvas, middle);
										} else {
											drawConflictGeometry(camera, canvas, middle);
										}
									} else {
										middle.draw(camera, canvas, threshold, this);
										middle.destroy();
									}
								}
							} else {
								// Разруливание
								middle = geometry;
								if (resolveByAABB) {
									drawAABBGeometry(camera, canvas, middle);
								} else if (resolveByOOBB) {
									for (geometry = middle; geometry != null; geometry = geometry.next) {
										geometry.calculateOOBB(this);
									}
									drawOOBBGeometry(camera, canvas, middle);
								} else {
									drawConflictGeometry(camera, canvas, middle);
								}
							}
						} else {
							// Проверка с окклюдерами и отрисовка
							if (geometry.numOccluders >= numOccluders || !occludeGeometry(camera, geometry)) {
								geometry.draw(camera, canvas, threshold, this);
							}
							geometry.destroy();
						}
					}
				}
				// Отрисовка окклюдеров
				for (child = node.occluderList, bound = node.occluderBoundList; child != null; child = child.next, bound = bound.next) {
					if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, bound.boundMinX, bound.boundMinY, bound.boundMinZ, bound.boundMaxX, bound.boundMaxY, bound.boundMaxZ)) >= 0)) {
						child.composeAndAppend(this);
						child.draw(camera, canvas);
					}
				}
				// Обновление окклюдеров
				if (node.occluderList != null) {
					updateOccluders(camera);
				}
			}
		}
		
		private function createObjectBounds(object:Object3D):Object3D {
			var bound:Object3D = new Object3D();
			bound.boundMinX = 1e+22;
			bound.boundMinY = 1e+22;
			bound.boundMinZ = 1e+22;
			bound.boundMaxX = -1e+22;
			bound.boundMaxY = -1e+22;
			bound.boundMaxZ = -1e+22;
			object.composeMatrix();
			object.updateBounds(bound, object);
			return bound;
		}
		
		static private const splitCoordsX:Vector.<Number> = new Vector.<Number>();
		static private const splitCoordsY:Vector.<Number> = new Vector.<Number>();
		static private const splitCoordsZ:Vector.<Number> = new Vector.<Number>();
	
		private function createNode(objectList:Object3D, objectBoundList:Object3D, occluderList:Object3D, occluderBoundList:Object3D, minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number):KDNode {
			var node:KDNode = new KDNode();
			node.boundMinX = minX;
			node.boundMinY = minY;
			node.boundMinZ = minZ;
			node.boundMaxX = maxX;
			node.boundMaxY = maxY;
			node.boundMaxZ = maxZ;
			if (objectList == null) {
				if (occluderList != null) trace("Incorrect occluder size or position");
				return node;
			}
			var i:int;
			var j:int;
			var object:Object3D;
			var bound:Object3D;
			var coord:Number;
			// Сбор потенциальных координат сплита без дубликатов
			var numSplitCoordsX:int = 0;
			var numSplitCoordsY:int = 0;
			var numSplitCoordsZ:int = 0;
			for (bound = objectBoundList; bound != null; bound = bound.next) {
				if (bound.boundMaxX - bound.boundMinX <= threshold + threshold) {
					coord = (bound.boundMinX <= minX + threshold) ? minX : ((bound.boundMaxX >= maxX - threshold) ? maxX : (bound.boundMinX + bound.boundMaxX)*0.5);
					for (j = 0; j < numSplitCoordsX; j++) if (coord >= splitCoordsX[j] - threshold && coord <= splitCoordsX[j] + threshold) break;
					if (j == numSplitCoordsX) splitCoordsX[numSplitCoordsX++] = coord;
				} else {
					if (bound.boundMinX > minX + threshold) {
						for (j = 0; j < numSplitCoordsX; j++) if (bound.boundMinX >= splitCoordsX[j] - threshold && bound.boundMinX <= splitCoordsX[j] + threshold) break;
						if (j == numSplitCoordsX) splitCoordsX[numSplitCoordsX++] = bound.boundMinX;
					}
					if (bound.boundMaxX < maxX - threshold) {
						for (j = 0; j < numSplitCoordsX; j++) if (bound.boundMaxX >= splitCoordsX[j] - threshold && bound.boundMaxX <= splitCoordsX[j] + threshold) break;
						if (j == numSplitCoordsX) splitCoordsX[numSplitCoordsX++] = bound.boundMaxX;
					}
				}
				if (bound.boundMaxY - bound.boundMinY <= threshold + threshold) {
					coord = (bound.boundMinY <= minY + threshold) ? minY : ((bound.boundMaxY >= maxY - threshold) ? maxY : (bound.boundMinY + bound.boundMaxY)*0.5);
					for (j = 0; j < numSplitCoordsY; j++) if (coord >= splitCoordsY[j] - threshold && coord <= splitCoordsY[j] + threshold) break;
					if (j == numSplitCoordsY) splitCoordsY[numSplitCoordsY++] = coord;
				} else {
					if (bound.boundMinY > minY + threshold) {
						for (j = 0; j < numSplitCoordsY; j++) if (bound.boundMinY >= splitCoordsY[j] - threshold && bound.boundMinY <= splitCoordsY[j] + threshold) break;
						if (j == numSplitCoordsY) splitCoordsY[numSplitCoordsY++] = bound.boundMinY;
					}
					if (bound.boundMaxY < maxY - threshold) {
						for (j = 0; j < numSplitCoordsY; j++) if (bound.boundMaxY >= splitCoordsY[j] - threshold && bound.boundMaxY <= splitCoordsY[j] + threshold) break;
						if (j == numSplitCoordsY) splitCoordsY[numSplitCoordsY++] = bound.boundMaxY;
					}
				}
				if (bound.boundMaxZ - bound.boundMinZ <= threshold + threshold) {
					coord = (bound.boundMinZ <= minZ + threshold) ? minZ : ((bound.boundMaxZ >= maxZ - threshold) ? maxZ : (bound.boundMinZ + bound.boundMaxZ)*0.5);
					for (j = 0; j < numSplitCoordsZ; j++) if (coord >= splitCoordsZ[j] - threshold && coord <= splitCoordsZ[j] + threshold) break;
					if (j == numSplitCoordsZ) splitCoordsZ[numSplitCoordsZ++] = coord;
				} else {
					if (bound.boundMinZ > minZ + threshold) {
						for (j = 0; j < numSplitCoordsZ; j++) if (bound.boundMinZ >= splitCoordsZ[j] - threshold && bound.boundMinZ <= splitCoordsZ[j] + threshold) break;
						if (j == numSplitCoordsZ) splitCoordsZ[numSplitCoordsZ++] = bound.boundMinZ;
					}
					if (bound.boundMaxZ < maxZ - threshold) {
						for (j = 0; j < numSplitCoordsZ; j++) if (bound.boundMaxZ >= splitCoordsZ[j] - threshold && bound.boundMaxZ <= splitCoordsZ[j] + threshold) break;
						if (j == numSplitCoordsZ) splitCoordsZ[numSplitCoordsZ++] = bound.boundMaxZ;
					}
				}
			}
			// Поиск лучшего сплита
			var splitAxis:int = -1;
			var splitCoord:Number;
			var bestCost:Number = 1e+22;
			var numNegative:int;
			var numPositive:int;
			var area:Number;
			var areaNegative:Number;
			var areaPositive:Number;
			var cost:Number;
			area = (maxY - minY)*(maxZ - minZ);
			for (i = 0; i < numSplitCoordsX; i++) {
				coord = splitCoordsX[i];
				areaNegative = area*(coord - minX);
				areaPositive = area*(maxX - coord);
				numNegative = 0;
				numPositive = 0;
				for (bound = objectBoundList; bound != null; bound = bound.next) {
					if (bound.boundMaxX <= coord + threshold) {
						if (bound.boundMinX < coord - threshold) numNegative++;
					} else {
						if (bound.boundMinX >= coord - threshold) numPositive++; else break;
					}
				}
				if (bound == null) {
					cost = areaNegative*numNegative + areaPositive*numPositive;
					if (cost < bestCost) {
						bestCost = cost;
						splitAxis = 0;
						splitCoord = coord;
					}
				}
			}
			area = (node.boundMaxX - node.boundMinX)*(node.boundMaxZ - node.boundMinZ);
			for (i = 0; i < numSplitCoordsY; i++) {
				coord = splitCoordsY[i];
				areaNegative = area*(coord - minY);
				areaPositive = area*(maxY - coord);
				numNegative = 0;
				numPositive = 0;
				for (bound = objectBoundList; bound != null; bound = bound.next) {
					if (bound.boundMaxY <= coord + threshold) {
						if (bound.boundMinY < coord - threshold) numNegative++;
					} else {
						if (bound.boundMinY >= coord - threshold) numPositive++; else break;
					}
				}
				if (bound == null) {
					cost = areaNegative*numNegative + areaPositive*numPositive;
					if (cost < bestCost) {
						bestCost = cost;
						splitAxis = 1;
						splitCoord = coord;
					}
				}
			}
			area = (maxX - minX)*(maxY - minY);
			for (i = 0; i < numSplitCoordsZ; i++) {
				coord = splitCoordsZ[i];
				areaNegative = area*(coord - minZ);
				areaPositive = area*(maxZ - coord);
				numNegative = 0;
				numPositive = 0;
				for (bound = objectBoundList; bound != null; bound = bound.next) {
					if (bound.boundMaxZ <= coord + threshold) {
						if (bound.boundMinZ < coord - threshold) numNegative++;
					} else {
						if (bound.boundMinZ >= coord - threshold) numPositive++; else break;
					}
				}
				if (bound == null) {
					cost = areaNegative*numNegative + areaPositive*numPositive;
					if (cost < bestCost) {
						bestCost = cost;
						splitAxis = 2;
						splitCoord = coord;
					}
				}
			}
			// Если сплит не найден
			if (splitAxis < 0) {
				node.objectList = objectList;
				node.objectBoundList = objectBoundList;
				node.occluderList = occluderList;
				node.occluderBoundList = occluderBoundList;
			} else {
				node.axis = splitAxis;
				node.coord = splitCoord;
				node.minCoord = splitCoord - threshold;
				node.maxCoord = splitCoord + threshold;
				// Списки разделения
				var negativeObjectList:Object3D;
				var negativeObjectBoundList:Object3D;
				var negativeOccluderList:Object3D;
				var negativeOccluderBoundList:Object3D;
				var positiveObjectList:Object3D;
				var positiveObjectBoundList:Object3D;
				var positiveOccluderList:Object3D;
				var positiveOccluderBoundList:Object3D;
				var min:Number;
				var max:Number;
				// Разделение объектов
				var nextObject:Object3D;
				var nextBound:Object3D;
				for (object = objectList, bound = objectBoundList; object != null; object = nextObject, bound = nextBound) {
					nextObject = object.next;
					nextBound = bound.next;
					object.next = null;
					bound.next = null;
					min = (splitAxis == 0) ? bound.boundMinX : ((splitAxis == 1) ? bound.boundMinY : bound.boundMinZ);
					max = (splitAxis == 0) ? bound.boundMaxX : ((splitAxis == 1) ? bound.boundMaxY : bound.boundMaxZ);
					if (max <= splitCoord + threshold) {
						if (min < splitCoord - threshold) {
							// Объект в негативной стороне
							object.next = negativeObjectList;
							negativeObjectList = object;
							bound.next = negativeObjectBoundList;
							negativeObjectBoundList = bound;
						} else {
							// Остаётся в ноде
							object.next = node.objectList;
							node.objectList = object;
							bound.next = node.objectBoundList;
							node.objectBoundList = bound;
						}
					} else {
						if (min >= splitCoord - threshold) {
							// Объект в положительной стороне
							object.next = positiveObjectList;
							positiveObjectList = object;
							bound.next = positiveObjectBoundList;
							positiveObjectBoundList = bound;
						} else {
							// Распилился
						}
					}
				}
				// Разделение окклюдеров
				for (object = occluderList, bound = occluderBoundList; object != null; object = nextObject, bound = nextBound) {
					nextObject = object.next;
					nextBound = bound.next;
					object.next = null;
					bound.next = null;
					min = (splitAxis == 0) ? bound.boundMinX : ((splitAxis == 1) ? bound.boundMinY : bound.boundMinZ);
					max = (splitAxis == 0) ? bound.boundMaxX : ((splitAxis == 1) ? bound.boundMaxY : bound.boundMaxZ);
					if (max <= splitCoord + threshold) {
						if (min < splitCoord - threshold) {
							// Объект в негативной стороне
							object.next = negativeOccluderList;
							negativeOccluderList = object;
							bound.next = negativeOccluderBoundList;
							negativeOccluderBoundList = bound;
						} else {
							// Остаётся в ноде
							object.next = node.occluderList;
							node.occluderList = object;
							bound.next = node.occluderBoundList;
							node.occluderBoundList = bound;
						}
					} else {
						if (min >= splitCoord - threshold) {
							// Объект в положительной стороне
							object.next = positiveOccluderList;
							positiveOccluderList = object;
							bound.next = positiveOccluderBoundList;
							positiveOccluderBoundList = bound;
						} else {
							// Распилился
							trace("Incorrect occluder size or position");
						}
					}
				}
				// Создание дочерних нод
				var negativeMinX:Number = node.boundMinX;
				var negativeMinY:Number = node.boundMinY;
				var negativeMinZ:Number = node.boundMinZ;
				var negativeMaxX:Number = node.boundMaxX;
				var negativeMaxY:Number = node.boundMaxY;
				var negativeMaxZ:Number = node.boundMaxZ;
				var positiveMinX:Number = node.boundMinX;
				var positiveMinY:Number = node.boundMinY;
				var positiveMinZ:Number = node.boundMinZ;
				var positiveMaxX:Number = node.boundMaxX;
				var positiveMaxY:Number = node.boundMaxY;
				var positiveMaxZ:Number = node.boundMaxZ;
				// Коррекция
				if (splitAxis == 0) {
					negativeMaxX = splitCoord;
					positiveMinX = splitCoord;
				} else if (splitAxis == 1) {
					negativeMaxY = splitCoord;
					positiveMinY = splitCoord;
				} else {
					negativeMaxZ = splitCoord;
					positiveMinZ = splitCoord;
				}
				// Разделение дочерних нод
				node.negative = createNode(negativeObjectList, negativeObjectBoundList, negativeOccluderList, negativeOccluderBoundList, negativeMinX, negativeMinY, negativeMinZ, negativeMaxX, negativeMaxY, negativeMaxZ);
				node.positive = createNode(positiveObjectList, positiveObjectBoundList, positiveOccluderList, positiveOccluderBoundList, positiveMinX, positiveMinY, positiveMinZ, positiveMaxX, positiveMaxY, positiveMaxZ);
			}
			return node;
		}
		
		private function destroyNode(node:KDNode):void {
			if (node.negative != null) {
				destroyNode(node.negative);
				node.negative = null;
			}
			if (node.positive != null) {
				destroyNode(node.positive);
				node.positive = null;
			}
			var object:Object3D;
			var nextObject:Object3D;
			for (object = node.objectList; object != null; object = nextObject) {
				nextObject = object.next;
				object._parent = null;
				object.next = null;
			}
			for (object = node.objectBoundList; object != null; object = nextObject) {
				nextObject = object.next;
				object.next = null;
			}
			for (object = node.occluderList; object != null; object = nextObject) {
				nextObject = object.next;
				object._parent = null;
				object.next = null;
			}
			for (object = node.occluderBoundList; object != null; object = nextObject) {
				nextObject = object.next;
				object.next = null;
			}
			node.objectList = null;
			node.objectBoundList = null;
			node.occluderList = null;
			node.occluderBoundList = null;
		}
		
		private function calculateCameraPlanes(near:Number, far:Number):void {
			// Ближняя плоскость
			nearPlaneX = imc;
			nearPlaneY = img;
			nearPlaneZ = imk;
			nearPlaneOffset = (imc*near + imd)*nearPlaneX + (img*near + imh)*nearPlaneY + (imk*near + iml)*nearPlaneZ;
			// Дальняя плоскость
			farPlaneX = -imc;
			farPlaneY = -img;
			farPlaneZ = -imk;
			farPlaneOffset = (imc*far + imd)*farPlaneX + (img*far + imh)*farPlaneY + (imk*far + iml)*farPlaneZ;
			// Верхняя плоскость
			var ax:Number = -ima - imb + imc;
			var ay:Number = -ime - imf + img;
			var az:Number = -imi - imj + imk;
			var bx:Number = ima - imb + imc;
			var by:Number = ime - imf + img;
			var bz:Number = imi - imj + imk;
			topPlaneX = bz*ay - by*az;
			topPlaneY = bx*az - bz*ax;
			topPlaneZ = by*ax - bx*ay;
			topPlaneOffset = imd*topPlaneX + imh*topPlaneY + iml*topPlaneZ;
			// Правая плоскость
			ax = bx;
			ay = by;
			az = bz;
			bx = ima + imb + imc;
			by = ime + imf + img;
			bz = imi + imj + imk;
			rightPlaneX = bz*ay - by*az;
			rightPlaneY = bx*az - bz*ax;
			rightPlaneZ = by*ax - bx*ay;
			rightPlaneOffset = imd*rightPlaneX + imh*rightPlaneY + iml*rightPlaneZ;
			// Нижняя плоскость
			ax = bx;
			ay = by;
			az = bz;
			bx = -ima + imb + imc;
			by = -ime + imf + img;
			bz = -imi + imj + imk;
			bottomPlaneX = bz*ay - by*az;
			bottomPlaneY = bx*az - bz*ax;
			bottomPlaneZ = by*ax - bx*ay;
			bottomPlaneOffset = imd*bottomPlaneX + imh*bottomPlaneY + iml*bottomPlaneZ;
			// Левая плоскость
			ax = bx;
			ay = by;
			az = bz;
			bx = -ima - imb + imc;
			by = -ime - imf + img;
			bz = -imi - imj + imk;
			leftPlaneX = bz*ay - by*az;
			leftPlaneY = bx*az - bz*ax;
			leftPlaneZ = by*ax - bx*ay;
			leftPlaneOffset = imd*leftPlaneX + imh*leftPlaneY + iml*leftPlaneZ;
		}
	
		private function updateOccluders(camera:Camera3D):void {
			for (var i:int = numOccluders; i < camera.numOccluders; i++) {
				var occluder:Vertex = null;
				for (var cameraOccluder:Vertex = camera.occluders[i]; cameraOccluder != null; cameraOccluder = cameraOccluder.next) {
					var newOccluder:Vertex = cameraOccluder.create();
					newOccluder.next = occluder;
					occluder = newOccluder;
					var ax:Number = ima*cameraOccluder.x + imb*cameraOccluder.y + imc*cameraOccluder.z;
					var ay:Number = ime*cameraOccluder.x + imf*cameraOccluder.y + img*cameraOccluder.z;
					var az:Number = imi*cameraOccluder.x + imj*cameraOccluder.y + imk*cameraOccluder.z;
					var bx:Number = ima*cameraOccluder.u + imb*cameraOccluder.v + imc*cameraOccluder.offset;
					var by:Number = ime*cameraOccluder.u + imf*cameraOccluder.v + img*cameraOccluder.offset;
					var bz:Number = imi*cameraOccluder.u + imj*cameraOccluder.v + imk*cameraOccluder.offset;
					occluder.x = bz*ay - by*az;
					occluder.y = bx*az - bz*ax;
					occluder.z = by*ax - bx*ay;
					occluder.offset = imd*occluder.x + imh*occluder.y + iml*occluder.z;
				}
				occluders[numOccluders] = occluder;
				numOccluders++;
			}
		}
	
		private function cullingInContainer(culling:int, boundMinX:Number, boundMinY:Number, boundMinZ:Number, boundMaxX:Number, boundMaxY:Number, boundMaxZ:Number):int {
			if (culling > 0) {
				// Отсечение по ниар
				if (culling & 1) {
					if (nearPlaneX >= 0) if (nearPlaneY >= 0) if (nearPlaneZ >= 0) {
						if (boundMaxX*nearPlaneX + boundMaxY*nearPlaneY + boundMaxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundMinX*nearPlaneX + boundMinY*nearPlaneY + boundMinZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundMaxX*nearPlaneX + boundMaxY*nearPlaneY + boundMinZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundMinX*nearPlaneX + boundMinY*nearPlaneY + boundMaxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else if (nearPlaneZ >= 0) {
						if (boundMaxX*nearPlaneX + boundMinY*nearPlaneY + boundMaxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundMinX*nearPlaneX + boundMaxY*nearPlaneY + boundMinZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundMaxX*nearPlaneX + boundMinY*nearPlaneY + boundMinZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundMinX*nearPlaneX + boundMaxY*nearPlaneY + boundMaxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else if (nearPlaneY >= 0) if (nearPlaneZ >= 0) {
						if (boundMinX*nearPlaneX + boundMaxY*nearPlaneY + boundMaxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundMaxX*nearPlaneX + boundMinY*nearPlaneY + boundMinZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundMinX*nearPlaneX + boundMaxY*nearPlaneY + boundMinZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundMaxX*nearPlaneX + boundMinY*nearPlaneY + boundMaxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else if (nearPlaneZ >= 0) {
						if (boundMinX*nearPlaneX + boundMinY*nearPlaneY + boundMaxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundMaxX*nearPlaneX + boundMaxY*nearPlaneY + boundMinZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundMinX*nearPlaneX + boundMinY*nearPlaneY + boundMinZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundMaxX*nearPlaneX + boundMaxY*nearPlaneY + boundMaxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					}
				}
				// Отсечение по фар
				if (culling & 2) {
					if (farPlaneX >= 0) if (farPlaneY >= 0) if (farPlaneZ >= 0) {
						if (boundMaxX*farPlaneX + boundMaxY*farPlaneY + boundMaxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundMinX*farPlaneX + boundMinY*farPlaneY + boundMinZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundMaxX*farPlaneX + boundMaxY*farPlaneY + boundMinZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundMinX*farPlaneX + boundMinY*farPlaneY + boundMaxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else if (farPlaneZ >= 0) {
						if (boundMaxX*farPlaneX + boundMinY*farPlaneY + boundMaxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundMinX*farPlaneX + boundMaxY*farPlaneY + boundMinZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundMaxX*farPlaneX + boundMinY*farPlaneY + boundMinZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundMinX*farPlaneX + boundMaxY*farPlaneY + boundMaxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else if (farPlaneY >= 0) if (farPlaneZ >= 0) {
						if (boundMinX*farPlaneX + boundMaxY*farPlaneY + boundMaxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundMaxX*farPlaneX + boundMinY*farPlaneY + boundMinZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundMinX*farPlaneX + boundMaxY*farPlaneY + boundMinZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundMaxX*farPlaneX + boundMinY*farPlaneY + boundMaxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else if (farPlaneZ >= 0) {
						if (boundMinX*farPlaneX + boundMinY*farPlaneY + boundMaxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundMaxX*farPlaneX + boundMaxY*farPlaneY + boundMinZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundMinX*farPlaneX + boundMinY*farPlaneY + boundMinZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundMaxX*farPlaneX + boundMaxY*farPlaneY + boundMaxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					}
				}
				// Отсечение по левой стороне
				if (culling & 4) {
					if (leftPlaneX >= 0) if (leftPlaneY >= 0) if (leftPlaneZ >= 0) {
						if (boundMaxX*leftPlaneX + boundMaxY*leftPlaneY + boundMaxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundMinX*leftPlaneX + boundMinY*leftPlaneY + boundMinZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundMaxX*leftPlaneX + boundMaxY*leftPlaneY + boundMinZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundMinX*leftPlaneX + boundMinY*leftPlaneY + boundMaxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else if (leftPlaneZ >= 0) {
						if (boundMaxX*leftPlaneX + boundMinY*leftPlaneY + boundMaxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundMinX*leftPlaneX + boundMaxY*leftPlaneY + boundMinZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundMaxX*leftPlaneX + boundMinY*leftPlaneY + boundMinZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundMinX*leftPlaneX + boundMaxY*leftPlaneY + boundMaxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else if (leftPlaneY >= 0) if (leftPlaneZ >= 0) {
						if (boundMinX*leftPlaneX + boundMaxY*leftPlaneY + boundMaxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundMaxX*leftPlaneX + boundMinY*leftPlaneY + boundMinZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundMinX*leftPlaneX + boundMaxY*leftPlaneY + boundMinZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundMaxX*leftPlaneX + boundMinY*leftPlaneY + boundMaxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else if (leftPlaneZ >= 0) {
						if (boundMinX*leftPlaneX + boundMinY*leftPlaneY + boundMaxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundMaxX*leftPlaneX + boundMaxY*leftPlaneY + boundMinZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundMinX*leftPlaneX + boundMinY*leftPlaneY + boundMinZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundMaxX*leftPlaneX + boundMaxY*leftPlaneY + boundMaxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					}
				}
				// Отсечение по правой стороне
				if (culling & 8) {
					if (rightPlaneX >= 0) if (rightPlaneY >= 0) if (rightPlaneZ >= 0) {
						if (boundMaxX*rightPlaneX + boundMaxY*rightPlaneY + boundMaxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundMinX*rightPlaneX + boundMinY*rightPlaneY + boundMinZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundMaxX*rightPlaneX + boundMaxY*rightPlaneY + boundMinZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundMinX*rightPlaneX + boundMinY*rightPlaneY + boundMaxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else if (rightPlaneZ >= 0) {
						if (boundMaxX*rightPlaneX + boundMinY*rightPlaneY + boundMaxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundMinX*rightPlaneX + boundMaxY*rightPlaneY + boundMinZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundMaxX*rightPlaneX + boundMinY*rightPlaneY + boundMinZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundMinX*rightPlaneX + boundMaxY*rightPlaneY + boundMaxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else if (rightPlaneY >= 0) if (rightPlaneZ >= 0) {
						if (boundMinX*rightPlaneX + boundMaxY*rightPlaneY + boundMaxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundMaxX*rightPlaneX + boundMinY*rightPlaneY + boundMinZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundMinX*rightPlaneX + boundMaxY*rightPlaneY + boundMinZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundMaxX*rightPlaneX + boundMinY*rightPlaneY + boundMaxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else if (rightPlaneZ >= 0) {
						if (boundMinX*rightPlaneX + boundMinY*rightPlaneY + boundMaxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundMaxX*rightPlaneX + boundMaxY*rightPlaneY + boundMinZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundMinX*rightPlaneX + boundMinY*rightPlaneY + boundMinZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundMaxX*rightPlaneX + boundMaxY*rightPlaneY + boundMaxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					}
				}
				// Отсечение по верхней стороне
				if (culling & 16) {
					if (topPlaneX >= 0) if (topPlaneY >= 0) if (topPlaneZ >= 0) {
						if (boundMaxX*topPlaneX + boundMaxY*topPlaneY + boundMaxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundMinX*topPlaneX + boundMinY*topPlaneY + boundMinZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundMaxX*topPlaneX + boundMaxY*topPlaneY + boundMinZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundMinX*topPlaneX + boundMinY*topPlaneY + boundMaxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else if (topPlaneZ >= 0) {
						if (boundMaxX*topPlaneX + boundMinY*topPlaneY + boundMaxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundMinX*topPlaneX + boundMaxY*topPlaneY + boundMinZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundMaxX*topPlaneX + boundMinY*topPlaneY + boundMinZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundMinX*topPlaneX + boundMaxY*topPlaneY + boundMaxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else if (topPlaneY >= 0) if (topPlaneZ >= 0) {
						if (boundMinX*topPlaneX + boundMaxY*topPlaneY + boundMaxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundMaxX*topPlaneX + boundMinY*topPlaneY + boundMinZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundMinX*topPlaneX + boundMaxY*topPlaneY + boundMinZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundMaxX*topPlaneX + boundMinY*topPlaneY + boundMaxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else if (topPlaneZ >= 0) {
						if (boundMinX*topPlaneX + boundMinY*topPlaneY + boundMaxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundMaxX*topPlaneX + boundMaxY*topPlaneY + boundMinZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundMinX*topPlaneX + boundMinY*topPlaneY + boundMinZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundMaxX*topPlaneX + boundMaxY*topPlaneY + boundMaxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					}
				}
				// Отсечение по нижней стороне
				if (culling & 32) {
					if (bottomPlaneX >= 0) if (bottomPlaneY >= 0) if (bottomPlaneZ >= 0) {
						if (boundMaxX*bottomPlaneX + boundMaxY*bottomPlaneY + boundMaxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundMinX*bottomPlaneX + boundMinY*bottomPlaneY + boundMinZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundMaxX*bottomPlaneX + boundMaxY*bottomPlaneY + boundMinZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundMinX*bottomPlaneX + boundMinY*bottomPlaneY + boundMaxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else if (bottomPlaneZ >= 0) {
						if (boundMaxX*bottomPlaneX + boundMinY*bottomPlaneY + boundMaxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundMinX*bottomPlaneX + boundMaxY*bottomPlaneY + boundMinZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundMaxX*bottomPlaneX + boundMinY*bottomPlaneY + boundMinZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundMinX*bottomPlaneX + boundMaxY*bottomPlaneY + boundMaxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else if (bottomPlaneY >= 0) if (bottomPlaneZ >= 0) {
						if (boundMinX*bottomPlaneX + boundMaxY*bottomPlaneY + boundMaxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundMaxX*bottomPlaneX + boundMinY*bottomPlaneY + boundMinZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundMinX*bottomPlaneX + boundMaxY*bottomPlaneY + boundMinZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundMaxX*bottomPlaneX + boundMinY*bottomPlaneY + boundMaxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else if (bottomPlaneZ >= 0) {
						if (boundMinX*bottomPlaneX + boundMinY*bottomPlaneY + boundMaxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundMaxX*bottomPlaneX + boundMaxY*bottomPlaneY + boundMinZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundMinX*bottomPlaneX + boundMinY*bottomPlaneY + boundMinZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundMaxX*bottomPlaneX + boundMaxY*bottomPlaneY + boundMaxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					}
				}
			}
			// Отсечение по окклюдерам
			for (var i:int = 0; i < numOccluders; i++) {
				for (var occluder:Vertex = occluders[i]; occluder != null; occluder = occluder.next) {
					if (occluder.x >= 0) if (occluder.y >= 0) if (occluder.z >= 0) {
						if (boundMaxX*occluder.x + boundMaxY*occluder.y + boundMaxZ*occluder.z > occluder.offset) break;
					} else {
						if (boundMaxX*occluder.x + boundMaxY*occluder.y + boundMinZ*occluder.z > occluder.offset) break;
					} else if (occluder.z >= 0) {
						if (boundMaxX*occluder.x + boundMinY*occluder.y + boundMaxZ*occluder.z > occluder.offset) break;
					} else {
						if (boundMaxX*occluder.x + boundMinY*occluder.y + boundMinZ*occluder.z > occluder.offset) break;
					} else if (occluder.y >= 0) if (occluder.z >= 0) {
						if (boundMinX*occluder.x + boundMaxY*occluder.y + boundMaxZ*occluder.z > occluder.offset) break;
					} else {
						if (boundMinX*occluder.x + boundMaxY*occluder.y + boundMinZ*occluder.z > occluder.offset) break;
					} else if (occluder.z >= 0) {
						if (boundMinX*occluder.x + boundMinY*occluder.y + boundMaxZ*occluder.z > occluder.offset) break;
					} else {
						if (boundMinX*occluder.x + boundMinY*occluder.y + boundMinZ*occluder.z > occluder.offset) break;
					}
				}
				if (occluder == null) return -1;
			}
			return culling;
		}
	
		private function occludeGeometry(camera:Camera3D, geometry:VG):Boolean {
			for (var i:int = geometry.numOccluders; i < numOccluders; i++) {
				for (var occluder:Vertex = occluders[i]; occluder != null; occluder = occluder.next) {
					if (occluder.x >= 0) if (occluder.y >= 0) if (occluder.z >= 0) {
						if (geometry.boundMaxX*occluder.x + geometry.boundMaxY*occluder.y + geometry.boundMaxZ*occluder.z > occluder.offset) break;
					} else {
						if (geometry.boundMaxX*occluder.x + geometry.boundMaxY*occluder.y + geometry.boundMinZ*occluder.z > occluder.offset) break;
					} else if (occluder.z >= 0) {
						if (geometry.boundMaxX*occluder.x + geometry.boundMinY*occluder.y + geometry.boundMaxZ*occluder.z > occluder.offset) break;
					} else {
						if (geometry.boundMaxX*occluder.x + geometry.boundMinY*occluder.y + geometry.boundMinZ*occluder.z > occluder.offset) break;
					} else if (occluder.y >= 0) if (occluder.z >= 0) {
						if (geometry.boundMinX*occluder.x + geometry.boundMaxY*occluder.y + geometry.boundMaxZ*occluder.z > occluder.offset) break;
					} else {
						if (geometry.boundMinX*occluder.x + geometry.boundMaxY*occluder.y + geometry.boundMinZ*occluder.z > occluder.offset) break;
					} else if (occluder.z >= 0) {
						if (geometry.boundMinX*occluder.x + geometry.boundMinY*occluder.y + geometry.boundMaxZ*occluder.z > occluder.offset) break;
					} else {
						if (geometry.boundMinX*occluder.x + geometry.boundMinY*occluder.y + geometry.boundMinZ*occluder.z > occluder.offset) break;
					}
				}
				if (occluder == null) return true;
			}
			geometry.numOccluders = numOccluders;
			return false;
		}
		
	}
}

import alternativa.engine3d.core.Object3D;

class KDNode	{
		
	public var negative:KDNode;
	public var positive:KDNode;

	public var axis:int;
	public var coord:Number;
	public var minCoord:Number;
	public var maxCoord:Number;

	public var boundMinX:Number;
	public var boundMinY:Number;
	public var boundMinZ:Number;
	public var boundMaxX:Number;
	public var boundMaxY:Number;
	public var boundMaxZ:Number;

	public var objectList:Object3D;
	public var objectBoundList:Object3D;
	public var occluderList:Object3D;
	public var occluderBoundList:Object3D;
	
}