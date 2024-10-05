package alternativa.engine3d.containers {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	
	use namespace alternativa3d;
	
	/**
	 * Контейнер, дочерние объекты которого помещены в бинарную древовидную структуру.
	 * Для построения дерева нужно добавить статические дочерние объекты
	 * с помощью addStaticChild(), затем вызвать createTree(). По баундам статических объектов
	 * построится ориентированная по осям бинарная древовидная структура (KD - частный случай BSP).
	 * Динамические объекты, можно в любое время добавлять addDynamicChild() и удалять removeDynamicChild().
	 * Объекты, добавленные с помощью addChild() будут отрисовываться поверх всего в порядке добавления.
	 */
	public class KDTree extends ConflictContainer {
	
		public var debugAlphaFade:Number = 0.8;
	
		private var root:KDNode;
	
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
	
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var canvas:Canvas;
			var debug:int;
			// Если есть корневая нода
			if (root != null) {
				// Расчёт инверсной матрицы камеры
				calculateInverseMatrix(object);
				// Расчёт плоскостей камеры в контейнере
				calculateCameraPlanes(camera.nearClipping, camera.farClipping);
				// Проверка на видимость рутовой ноды
				var culling:int = cullingInContainer(object.culling, root.boundMinX, root.boundMinY, root.boundMinZ, root.boundMaxX, root.boundMaxY, root.boundMaxZ);
				if (culling >= 0) {
					// Дебаг
					if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
						canvas = parentCanvas.getChildCanvas(object, true, false);
						if (debug & Debug.NODES) {
							debugNode(root, culling, camera, object, canvas, 1);
							Debug.drawBounds(camera, canvas, object, root.boundMinX, root.boundMinY, root.boundMinZ, root.boundMaxX, root.boundMaxY, root.boundMaxZ, 0xDD33DD);
						}
						if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
					}
					// Отрисовка
					canvas = parentCanvas.getChildCanvas(object, false, true, object.alpha, object.blendMode, object.colorTransform, object.filters);
					canvas.numDraws = 0;
					// Окклюдеры
					numOccluders = 0;
					if (camera.numOccluders > 0) {
						updateOccluders(camera);
					}
					// Сбор видимой геометрии
					var geometry:Geometry = getGeometry(camera, object);
					for (var current:Geometry = geometry; current != null; current = current.next) {
						current.calculateAABB(ima, imb, imc, imd, ime, imf, img, imh, imi, imj, imk, iml);
					}
					// Отрисовка дерева
					drawNode(root, culling, camera, object, canvas, geometry);
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
					super.draw(camera, object, parentCanvas);
				}
			} else {
				super.draw(camera, object, parentCanvas);
			}
		}
	
		private function debugNode(node:KDNode, culling:int, camera:Camera3D, object:Object3D, canvas:Canvas, alpha:Number):void {
			if (node.negative != null) {
				var negativeCulling:int = (culling > 0) ? cullingInContainer(culling, node.negative.boundMinX, node.negative.boundMinY, node.negative.boundMinZ, node.negative.boundMaxX, node.negative.boundMaxY, node.negative.boundMaxZ) : 0;
				var positiveCulling:int = (culling > 0) ? cullingInContainer(culling, node.positive.boundMinX, node.positive.boundMinY, node.positive.boundMinZ, node.positive.boundMaxX, node.positive.boundMaxY, node.positive.boundMaxZ) : 0;
				if (negativeCulling >= 0) {
					debugNode(node.negative, negativeCulling, camera, object, canvas, alpha*debugAlphaFade);
				}
				Debug.drawKDNode(camera, canvas, object, node.axis, node.coord, node.boundMinX, node.boundMinY, node.boundMinZ, node.boundMaxX, node.boundMaxY, node.boundMaxZ, alpha);
				if (positiveCulling >= 0) {
					debugNode(node.positive, positiveCulling, camera, object, canvas, alpha*debugAlphaFade);
				}
			}
		}
	
		private function drawNode(node:KDNode, culling:int, camera:Camera3D, object:Object3D, canvas:Canvas, geometry:Geometry):void {
			var i:int;
			var next:Geometry;
			var negative:Geometry;
			var middle:Geometry;
			var positive:Geometry;
			if (camera.occludedAll) {
				while (geometry != null) {
					next = geometry.next;
					geometry.destroy();
					geometry = next;
				}
				return;
			}
			var nodeObjects:Vector.<Object3D> = node.objects;
			var nodeObjectsLength:int = node.objectsLength;
			var nodeOccluders:Vector.<Object3D> = node.occluders;
			var nodeOccludersLength:int = node.occludersLength;
			var child:Object3D;
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
						drawNode(node.positive, positiveCulling, camera, object, canvas, positive);
						// Отрисовка динамических объектов в ноде
						while (middle != null) {
							next = middle.next;
							// Проверка с окклюдерами и отрисовка
							if (middle.numOccluders >= numOccluders || !occludeGeometry(camera, middle)) {
								middle.draw(camera, object, canvas, threshold);
							}
							middle.destroy();
							middle = next;
						}
						// Отрисовка плоских статических объектов в ноде
						for (i = 0; i < nodeObjectsLength; i++) {
							child = nodeObjects[i];
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, child.boundMinX, child.boundMinY, child.boundMinZ, child.boundMaxX, child.boundMaxY, child.boundMaxZ)) >= 0)) {
								child.composeAndAppend(object);
								child.draw(camera, child, canvas);
							}
						}
						for (i = 0; i < nodeOccludersLength; i++) {
							child = nodeOccluders[i];
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, child.boundMinX, child.boundMinY, child.boundMinZ, child.boundMaxX, child.boundMaxY, child.boundMaxZ)) >= 0)) {
								child.composeAndAppend(object);
								child.draw(camera, child, canvas);
							}
						}
						// Обновление окклюдеров
						if (nodeOccludersLength > 0) {
							updateOccluders(camera);
						}
						// Отрисовка негативной ноды
						drawNode(node.negative, negativeCulling, camera, object, canvas, negative);
					} else {
						// Отрисовка негативной ноды
						drawNode(node.negative, negativeCulling, camera, object, canvas, negative);
						// Отрисовка динамических объектов в ноде
						while (middle != null) {
							next = middle.next;
							// Проверка с окклюдерами и отрисовка
							if (middle.numOccluders >= numOccluders || !occludeGeometry(camera, middle)) {
								middle.draw(camera, object, canvas, threshold);
							}
							middle.destroy();
							middle = next;
						}
						// Отрисовка плоских статических объектов в ноде
						for (i = 0; i < nodeObjectsLength; i++) {
							child = nodeObjects[i];
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, child.boundMinX, child.boundMinY, child.boundMinZ, child.boundMaxX, child.boundMaxY, child.boundMaxZ)) >= 0)) {
								child.composeAndAppend(object);
								child.draw(camera, child, canvas);
							}
						}
						for (i = 0; i < nodeOccludersLength; i++) {
							child = nodeOccluders[i];
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, child.boundMinX, child.boundMinY, child.boundMinZ, child.boundMaxX, child.boundMaxY, child.boundMaxZ)) >= 0)) {
								child.composeAndAppend(object);
								child.draw(camera, child, canvas);
							}
						}
						// Обновление окклюдеров
						if (nodeOccludersLength > 0) {
							updateOccluders(camera);
						}
						// Отрисовка позитивной ноды
						drawNode(node.positive, positiveCulling, camera, object, canvas, positive);
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
					drawNode(node.negative, negativeCulling, camera, object, canvas, negative);
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
					drawNode(node.positive, positiveCulling, camera, object, canvas, positive);
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
				if (nodeObjectsLength > 0) {
					// Если есть конфликт
					if (nodeObjectsLength > 1 || geometry != null) {
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
						for (i = 0; i < nodeObjectsLength; i++) {
							child = nodeObjects[i];
							if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, child.boundMinX, child.boundMinY, child.boundMinZ, child.boundMaxX, child.boundMaxY, child.boundMaxZ)) >= 0)) {
								child.composeAndAppend(object);
								geometry = child.getGeometry(camera, child);
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
								drawConflictGeometry(camera, object, canvas, middle);
							} else {
								middle.draw(camera, object, canvas, threshold);
								middle.destroy();
							}
						}
					} else {
						// Если только один статик
						child = nodeObjects[i];
						if (child.visible) {
							child.composeAndAppend(object);
							child.culling = culling;
							child.draw(camera, child, canvas);
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
											drawAABBGeometry(camera, object, canvas, middle);
										} else if (resolveByOOBB) {
											for (geometry = middle; geometry != null; geometry = geometry.next) {
												geometry.calculateOOBB();
											}
											drawOOBBGeometry(camera, object, canvas, middle);
										} else {
											drawConflictGeometry(camera, object, canvas, middle);
										}
									} else {
										middle.draw(camera, object, canvas, threshold);
										middle.destroy();
									}
								}
							} else {
								// Разруливание
								middle = geometry;
								if (resolveByAABB) {
									drawAABBGeometry(camera, object, canvas, middle);
								} else if (resolveByOOBB) {
									for (geometry = middle; geometry != null; geometry = geometry.next) {
										geometry.calculateOOBB();
									}
									drawOOBBGeometry(camera, object, canvas, middle);
								} else {
									drawConflictGeometry(camera, object, canvas, middle);
								}
							}
						} else {
							// Проверка с окклюдерами и отрисовка
							if (geometry.numOccluders >= numOccluders || !occludeGeometry(camera, geometry)) {
								geometry.draw(camera, object, canvas, threshold);
							}
							geometry.destroy();
						}
					}
				}
				// Отрисовка окклюдеров
				for (i = 0; i < nodeOccludersLength; i++) {
					child = nodeOccluders[i];
					if (child.visible && ((child.culling = culling) == 0 && numOccluders == 0 || (child.culling = cullingInContainer(culling, child.boundMinX, child.boundMinY, child.boundMinZ, child.boundMaxX, child.boundMaxY, child.boundMaxZ)) >= 0)) {
						child.composeAndAppend(object);
						child.draw(camera, child, canvas);
					}
				}
				// Обновление окклюдеров
				if (nodeOccludersLength > 0) {
					updateOccluders(camera);
				}
			}
		}
	
		public function createTree(staticObjects:Vector.<Object3D>, staticOccluders:Vector.<Object3D> = null):void {
			var i:int;
			var object:Object3D;
			var staticObjectsLength:int = staticObjects.length;
			var staticOccludersLength:int = (staticOccluders != null) ? staticOccluders.length : 0;
			var objects:Vector.<Object3D>;
			var objectsLength:int = 0;
			var occluders:Vector.<Object3D>;
			var occludersLength:int = 0;
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
				object.composeMatrix();
				// Расчёт баунда в координатах дерева
				object.boundMinX = 1e+22;
				object.boundMinY = 1e+22;
				object.boundMinZ = 1e+22;
				object.boundMaxX = -1e+22;
				object.boundMaxY = -1e+22;
				object.boundMaxZ = -1e+22;
				object.updateBounds(object, object);
				// Если объект не пустой
				if (object.boundMinX <= object.boundMaxX) {
					if (objects == null) objects = new Vector.<Object3D>();
					objects[objectsLength++] = object;
					// Коррекция баунда корневой ноды
					if (object.boundMinX < minX) minX = object.boundMinX;
					if (object.boundMaxX > maxX) maxX = object.boundMaxX;
					if (object.boundMinY < minY) minY = object.boundMinY;
					if (object.boundMaxY > maxY) maxY = object.boundMaxY;
					if (object.boundMinZ < minZ) minZ = object.boundMinZ;
					if (object.boundMaxZ > maxZ) maxZ = object.boundMaxZ;
				}
			}
			// Обработка окклюдеров
			for (i = 0; i < staticOccludersLength; i++) {
				object = staticOccluders[i];
				object.composeMatrix();
				// Расчёт баунда в координатах дерева
				object.boundMinX = 1e+22;
				object.boundMinY = 1e+22;
				object.boundMinZ = 1e+22;
				object.boundMaxX = -1e+22;
				object.boundMaxY = -1e+22;
				object.boundMaxZ = -1e+22;
				object.updateBounds(object, object);
				// Если объект не пустой
				if (object.boundMinX <= object.boundMaxX) {
					// Проверка выхода окклюдера за границы ноды
					if (object.boundMinX < minX || object.boundMaxX > maxX || object.boundMinY < minY || object.boundMaxY > maxY || object.boundMinZ < minZ || object.boundMaxZ > maxZ) {
						trace("Incorrect occluder size or position");
					} else {
						if (occluders == null) occluders = new Vector.<Object3D>();
						occluders[occludersLength++] = object;
					}
				}
			}
			// Если есть непустые объекты
			if (objectsLength > 0) {
				root = new KDNode();
				root.boundMinX = minX;
				root.boundMinY = minY;
				root.boundMinZ = minZ;
				root.boundMaxX = maxX;
				root.boundMaxY = maxY;
				root.boundMaxZ = maxZ;
				createNode(root, objects, objectsLength, occluders, occludersLength);
			} else {
				root = null;
			}
		}
	
		static private const splitCoordsX:Vector.<Number> = new Vector.<Number>();
		static private const splitCoordsY:Vector.<Number> = new Vector.<Number>();
		static private const splitCoordsZ:Vector.<Number> = new Vector.<Number>();
	
		private function createNode(node:KDNode, objects:Vector.<Object3D>, numObjects:int, occluders:Vector.<Object3D>, numOccluders:int):void {
			var i:int;
			var j:int;
			var object:Object3D;
			var coord:Number;
			// Сбор потенциальных координат сплита без дубликатов
			var numSplitCoordsX:int = 0;
			var numSplitCoordsY:int = 0;
			var numSplitCoordsZ:int = 0;
			for (i = 0; i < numObjects; i++) {
				object = objects[i];
				if (object.boundMaxX - object.boundMinX <= threshold + threshold) {
					coord = (object.boundMinX <= node.boundMinX + threshold) ? node.boundMinX : ((object.boundMaxX >= node.boundMaxX - threshold) ? node.boundMaxX : (object.boundMinX + object.boundMaxX)*0.5);
					for (j = 0; j < numSplitCoordsX; j++) if (coord >= splitCoordsX[j] - threshold && coord <= splitCoordsX[j] + threshold) break;
					if (j == numSplitCoordsX) splitCoordsX[numSplitCoordsX++] = coord;
				} else {
					if (object.boundMinX > node.boundMinX + threshold) {
						for (j = 0; j < numSplitCoordsX; j++) if (object.boundMinX >= splitCoordsX[j] - threshold && object.boundMinX <= splitCoordsX[j] + threshold) break;
						if (j == numSplitCoordsX) splitCoordsX[numSplitCoordsX++] = object.boundMinX;
					}
					if (object.boundMaxX < node.boundMaxX - threshold) {
						for (j = 0; j < numSplitCoordsX; j++) if (object.boundMaxX >= splitCoordsX[j] - threshold && object.boundMaxX <= splitCoordsX[j] + threshold) break;
						if (j == numSplitCoordsX) splitCoordsX[numSplitCoordsX++] = object.boundMaxX;
					}
				}
				if (object.boundMaxY - object.boundMinY <= threshold + threshold) {
					coord = (object.boundMinY <= node.boundMinY + threshold) ? node.boundMinY : ((object.boundMaxY >= node.boundMaxY - threshold) ? node.boundMaxY : (object.boundMinY + object.boundMaxY)*0.5);
					for (j = 0; j < numSplitCoordsY; j++) if (coord >= splitCoordsY[j] - threshold && coord <= splitCoordsY[j] + threshold) break;
					if (j == numSplitCoordsY) splitCoordsY[numSplitCoordsY++] = coord;
				} else {
					if (object.boundMinY > node.boundMinY + threshold) {
						for (j = 0; j < numSplitCoordsY; j++) if (object.boundMinY >= splitCoordsY[j] - threshold && object.boundMinY <= splitCoordsY[j] + threshold) break;
						if (j == numSplitCoordsY) splitCoordsY[numSplitCoordsY++] = object.boundMinY;
					}
					if (object.boundMaxY < node.boundMaxY - threshold) {
						for (j = 0; j < numSplitCoordsY; j++) if (object.boundMaxY >= splitCoordsY[j] - threshold && object.boundMaxY <= splitCoordsY[j] + threshold) break;
						if (j == numSplitCoordsY) splitCoordsY[numSplitCoordsY++] = object.boundMaxY;
					}
				}
				if (object.boundMaxZ - object.boundMinZ <= threshold + threshold) {
					coord = (object.boundMinZ <= node.boundMinZ + threshold) ? node.boundMinZ : ((object.boundMaxZ >= node.boundMaxZ - threshold) ? node.boundMaxZ : (object.boundMinZ + object.boundMaxZ)*0.5);
					for (j = 0; j < numSplitCoordsZ; j++) if (coord >= splitCoordsZ[j] - threshold && coord <= splitCoordsZ[j] + threshold) break;
					if (j == numSplitCoordsZ) splitCoordsZ[numSplitCoordsZ++] = coord;
				} else {
					if (object.boundMinZ > node.boundMinZ + threshold) {
						for (j = 0; j < numSplitCoordsZ; j++) if (object.boundMinZ >= splitCoordsZ[j] - threshold && object.boundMinZ <= splitCoordsZ[j] + threshold) break;
						if (j == numSplitCoordsZ) splitCoordsZ[numSplitCoordsZ++] = object.boundMinZ;
					}
					if (object.boundMaxZ < node.boundMaxZ - threshold) {
						for (j = 0; j < numSplitCoordsZ; j++) if (object.boundMaxZ >= splitCoordsZ[j] - threshold && object.boundMaxZ <= splitCoordsZ[j] + threshold) break;
						if (j == numSplitCoordsZ) splitCoordsZ[numSplitCoordsZ++] = object.boundMaxZ;
					}
				}
			}
			// Поиск лучшего сплита
			var splitAxis:int = -1;
			var splitCoord:Number;
			var bestCost:Number = Number.MAX_VALUE;
			var numNegative:int;
			var numPositive:int;
			var area:Number;
			var areaNegative:Number;
			var areaPositive:Number;
			var cost:Number;
			area = (node.boundMaxY - node.boundMinY)*(node.boundMaxZ - node.boundMinZ);
			for (i = 0; i < numSplitCoordsX; i++) {
				coord = splitCoordsX[i];
				areaNegative = area*(coord - node.boundMinX);
				areaPositive = area*(node.boundMaxX - coord);
				numNegative = 0;
				numPositive = 0;
				for (j = 0; j < numObjects; j++) {
					object = objects[j];
					if (object.boundMaxX <= coord + threshold) {
						if (object.boundMinX < coord - threshold) numNegative++;
					} else {
						if (object.boundMinX >= coord - threshold) numPositive++; else break;
					}
				}
				if (j == numObjects) {
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
				areaNegative = area*(coord - node.boundMinY);
				areaPositive = area*(node.boundMaxY - coord);
				numNegative = 0;
				numPositive = 0;
				for (j = 0; j < numObjects; j++) {
					object = objects[j];
					if (object.boundMaxY <= coord + threshold) {
						if (object.boundMinY < coord - threshold) numNegative++;
					} else {
						if (object.boundMinY >= coord - threshold) numPositive++; else break;
					}
				}
				if (j == numObjects) {
					cost = areaNegative*numNegative + areaPositive*numPositive;
					if (cost < bestCost) {
						bestCost = cost;
						splitAxis = 1;
						splitCoord = coord;
					}
				}
			}
			area = (node.boundMaxX - node.boundMinX)*(node.boundMaxY - node.boundMinY);
			for (i = 0; i < numSplitCoordsZ; i++) {
				coord = splitCoordsZ[i];
				areaNegative = area*(coord - node.boundMinZ);
				areaPositive = area*(node.boundMaxZ - coord);
				numNegative = 0;
				numPositive = 0;
				for (j = 0; j < numObjects; j++) {
					object = objects[j];
					if (object.boundMaxZ <= coord + threshold) {
						if (object.boundMinZ < coord - threshold) numNegative++;
					} else {
						if (object.boundMinZ >= coord - threshold) numPositive++; else break;
					}
				}
				if (j == numObjects) {
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
				node.objects = objects;
				node.objectsLength = numObjects;
				node.occluders = occluders;
				node.occludersLength = numOccluders;
			} else {
				node.axis = splitAxis;
				node.coord = splitCoord;
				node.minCoord = splitCoord - threshold;
				node.maxCoord = splitCoord + threshold;
				// Списки разделения
				var negativeObjects:Vector.<Object3D>;
				var negativeObjectsLength:int = 0;
				var negativeOccluders:Vector.<Object3D>;
				var negativeOccludersLength:int = 0;
				var positiveObjects:Vector.<Object3D>;
				var positiveObjectsLength:int = 0;
				var positiveOccluders:Vector.<Object3D>;
				var positiveOccludersLength:int = 0;
				var min:Number;
				var max:Number;
				// Разделение объектов
				for (i = 0; i < numObjects; i++) {
					object = objects[i];
					min = (splitAxis == 0) ? object.boundMinX : ((splitAxis == 1) ? object.boundMinY : object.boundMinZ);
					max = (splitAxis == 0) ? object.boundMaxX : ((splitAxis == 1) ? object.boundMaxY : object.boundMaxZ);
					if (max <= splitCoord + threshold) {
						if (min < splitCoord - threshold) {
							// Объект в негативной стороне
							if (negativeObjects == null) negativeObjects = new Vector.<Object3D>();
							negativeObjects[negativeObjectsLength++] = object;
						} else {
							// Остаётся в ноде
							if (node.objects == null) node.objects = new Vector.<Object3D>();
							node.objects[node.objectsLength++] = object;
						}
					} else {
						if (min >= splitCoord - threshold) {
							// Объект в положительной стороне
							if (positiveObjects == null) positiveObjects = new Vector.<Object3D>();
							positiveObjects[positiveObjectsLength++] = object;
						} else {
							// Распилился
						}
					}
				}
				// Разделение окклюдеров
				for (i = 0; i < numOccluders; i++) {
					object = occluders[i];
					min = (splitAxis == 0) ? object.boundMinX : ((splitAxis == 1) ? object.boundMinY : object.boundMinZ);
					max = (splitAxis == 0) ? object.boundMaxX : ((splitAxis == 1) ? object.boundMaxY : object.boundMaxZ);
					if (max <= splitCoord + threshold) {
						if (min < splitCoord - threshold) {
							// Объект в негативной стороне
							if (negativeOccluders == null) negativeOccluders = new Vector.<Object3D>();
							negativeOccluders[negativeOccludersLength++] = object;
						} else {
							// Остаётся в ноде
							if (node.occluders == null) node.occluders = new Vector.<Object3D>();
							node.occluders[node.occludersLength++] = object;
						}
					} else {
						if (min >= splitCoord - threshold) {
							// Объект в положительной стороне
							if (positiveOccluders == null) positiveOccluders = new Vector.<Object3D>();
							positiveOccluders[positiveOccludersLength++] = object;
						} else {
							// Распилился
							trace("Incorrect occluder size or position");
						}
					}
				}
				// Создание дочерних нод
				node.negative = new KDNode();
				node.positive = new KDNode();
				// Назначение баундов
				node.negative.boundMinX = node.boundMinX;
				node.negative.boundMinY = node.boundMinY;
				node.negative.boundMinZ = node.boundMinZ;
				node.negative.boundMaxX = node.boundMaxX;
				node.negative.boundMaxY = node.boundMaxY;
				node.negative.boundMaxZ = node.boundMaxZ;
				node.positive.boundMinX = node.boundMinX;
				node.positive.boundMinY = node.boundMinY;
				node.positive.boundMinZ = node.boundMinZ;
				node.positive.boundMaxX = node.boundMaxX;
				node.positive.boundMaxY = node.boundMaxY;
				node.positive.boundMaxZ = node.boundMaxZ;
				// Коррекция
				if (splitAxis == 0) {
					node.negative.boundMaxX = splitCoord;
					node.positive.boundMinX = splitCoord;
				} else if (splitAxis == 1) {
					node.negative.boundMaxY = splitCoord;
					node.positive.boundMinY = splitCoord;
				} else {
					node.negative.boundMaxZ = splitCoord;
					node.positive.boundMinZ = splitCoord;
				}
				// Разделение дочерних нод
				if (negativeObjectsLength > 0) {
					createNode(node.negative, negativeObjects, negativeObjectsLength, negativeOccluders, negativeOccludersLength);
				} else if (negativeOccludersLength > 0) {
					trace("Incorrect occluder size or position");
				}
				if (positiveObjectsLength > 0) {
					createNode(node.positive, positiveObjects, positiveObjectsLength, positiveOccluders, positiveOccludersLength);
				} else if (positiveOccludersLength > 0) {
					trace("Incorrect occluder size or position");
				}
			}
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
	
		private function occludeGeometry(camera:Camera3D, geometry:Geometry):Boolean {
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

class KDNode {

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

	public var objects:Vector.<Object3D>;
	public var objectsLength:int = 0;
	public var occluders:Vector.<Object3D>;
	public var occludersLength:int = 0;

}
