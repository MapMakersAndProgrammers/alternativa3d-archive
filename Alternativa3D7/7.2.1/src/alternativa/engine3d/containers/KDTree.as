package alternativa.engine3d.containers {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Node;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Occluder;
	import alternativa.engine3d.objects.Reference;
	
	import flash.geom.Utils3D;
	
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
		
		private var rootNode:Node;
		
		override alternativa3d function get canDraw():Boolean {
			return _numChildren > 0 || rootNode != null;
		}

		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Если есть корневая нода
			if (rootNode != null) {
				// Расчёт инверсной матрицы камеры и позицци камеры в контейнере
				calculateInverseCameraMatrix(object.cameraMatrix);
				// Расчёт плоскостей камеры в контейнере
				calculateCameraPlanes(camera);
				// Проверка на видимость рутовой ноды
				var culling:int = cullingInContainer(camera, rootNode.boundBox, object.culling);
				if (culling >= 0) {
					// Подготовка канваса
					var canvas:Canvas = parentCanvas.getChildCanvas(false, true, object.alpha, object.blendMode, object.colorTransform, object.filters);
					canvas.numDraws = 0;
					// Окклюдеры
					numOccluders = 0;
					if (camera.numOccluders > 0) {
						updateOccluders(camera);
					}
					// Сбор видимой геометрии
					var geometry:Geometry = getGeometry(camera, object);
					var current:Geometry = geometry;
					while (current != null) {
						current.vertices.length = current.verticesLength;
						inverseCameraMatrix.transformVectors(current.vertices, current.vertices);
						current.calculateAABB();
						current = current.next;
					}
					// Отрисовка дерева
					drawNode(rootNode, culling, camera, object, canvas, geometry);
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
		
		override alternativa3d function debug(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var debugResult:int = camera.checkInDebug(this);
			if (debugResult == 0) return;
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false);
			// Ноды
			if (debugResult & Debug.NODES) {
				if (rootNode != null) {
					var culling:int = cullingInContainer(camera, rootNode.boundBox, object.culling);
					if (culling >= 0) {
						debugNode(rootNode, culling, camera, object, canvas, 1);
					}
				}
			}
			// Оси, центры, имена, баунды
			if (debugResult & Debug.AXES) object.drawAxes(camera, canvas);
			if (debugResult & Debug.CENTERS) object.drawCenter(camera, canvas);
			if (debugResult & Debug.NAMES) object.drawName(camera, canvas);
			if (debugResult & Debug.BOUNDS) object.drawBoundBox(camera, canvas);
		}
		
		// Отрисовка ноды
		private function drawNode(node:Node, culling:int, camera:Camera3D, object:Object3D, canvas:Canvas, geometry:Geometry):void {
			var i:int;
			var next:Geometry;
			var negative:Geometry;
			var middle:Geometry;
			var positive:Geometry;
			var negativePart:Geometry;
			var positivePart:Geometry;
			if (camera.occludedAll) {
				while (geometry != null) {
					next = geometry.next;
					geometry.destroy();
					geometry = next;
				}
				return;
			}
			var nodeObjects:Vector.<Object3D> = node.objects;
			var nodeNumObjects:int = node.numObjects;
			var nodeNumNonOccluders:int = node.numNonOccluders;
			var staticChild:Object3D;
			// Узловая нода
			if (node.negative != null) {
				var negativeCulling:int = (culling > 0 || numOccluders > 0) ? cullingInContainer(camera, node.negative.boundBox, culling) : 0;
				var positiveCulling:int = (culling > 0 || numOccluders > 0) ? cullingInContainer(camera, node.positive.boundBox, culling) : 0;
				var axisX:Boolean = node.normalX != 0;
				var axisY:Boolean = node.normalY != 0;
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
							min = axisX ? geometry.minX : (axisY ? geometry.minY : geometry.minZ);
							max = axisX ? geometry.maxX : (axisY ? geometry.maxY : geometry.maxZ);
							if (max <= node.offsetMax) {
								if (min < node.offsetMin) {
									geometry.next = negative;
									negative = geometry;
								} else {
									geometry.next = middle;
									middle = geometry;
								}
							} else {
								if (min >= node.offsetMin) {
									geometry.next = positive;
									positive = geometry;
								} else {
									negativePart = geometry.create();
									positivePart = geometry.create();
									geometry.split(axisX, axisY, node.offset, threshold, negativePart, positivePart);
									geometry.destroy();
									// Если негативный не пустой
									if (negativePart.fragment != null) {
										negativePart.next = negative;
										negative = negativePart;
									} else {
										negativePart.destroy();
									}
									// Если позитивный не пустой
									if (positivePart.fragment != null) {
										positivePart.next = positive;
										positive = positivePart;
									} else {
										positivePart.destroy();
									}
								}
							}
						}
						geometry = next;
					}
					// Отрисовка дочерних нод и объектов в плоскости
					if (axisX && cameraX > node.offset || axisY && cameraY > node.offset || !axisX && !axisY && cameraZ > node.offset) {
						// Отрисовка позитивной ноды
						drawNode(node.positive, positiveCulling, camera, object, canvas, positive);
						// Отрисовка динамических объектов в ноде
						while (middle != null) {
							next = middle.next;
							// Проверка с окклюдерами и отрисовка
							if (middle.numOccluders >= numOccluders || !occludeGeometry(camera, middle)) {
								if (camera.debugMode) middle.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
								middle.draw(camera, canvas, threshold, object.cameraMatrix);
							}
							middle.destroy();
							middle = next;
						}
						// Отрисовка плоских статических объектов в ноде
						for (i = 0; i < nodeNumObjects; i++) {
							staticChild = nodeObjects[i]; 
							if (staticChild.visible && staticChild.canDraw && ((staticChild.culling = culling) == 0 && numOccluders == 0 || (staticChild.culling = cullingInContainer(camera, node.bounds[i], culling)) >= 0)) {
								staticChild.cameraMatrix.identity();
								staticChild.cameraMatrix.prepend(object.cameraMatrix);
								staticChild.cameraMatrix.prepend(staticChild.matrix);
								if (camera.debugMode) staticChild.debug(camera, staticChild, canvas);
								staticChild.draw(camera, staticChild, canvas);
							}
						}
						// Обновление окклюдеров
						if (nodeNumObjects > nodeNumNonOccluders) {
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
								if (camera.debugMode) middle.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
								middle.draw(camera, canvas, threshold, object.cameraMatrix);
							}
							middle.destroy();
							middle = next;
						}
						// Отрисовка статических объектов в ноде
						for (i = 0; i < nodeNumObjects; i++) {
							staticChild = nodeObjects[i]; 
							if (staticChild.visible && staticChild.canDraw && ((staticChild.culling = culling) == 0 && numOccluders == 0 || (staticChild.culling = cullingInContainer(camera, node.bounds[i], culling)) >= 0)) {
								staticChild.cameraMatrix.identity();
								staticChild.cameraMatrix.prepend(object.cameraMatrix);
								staticChild.cameraMatrix.prepend(staticChild.matrix);
								if (camera.debugMode) staticChild.debug(camera, staticChild, canvas);
								staticChild.draw(camera, staticChild, canvas);
							}
						}
						// Обновление окклюдеров
						if (nodeNumObjects > nodeNumNonOccluders) {
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
							min = axisX ? geometry.minX : (axisY ? geometry.minY : geometry.minZ);
							max = axisX ? geometry.maxX : (axisY ? geometry.maxY : geometry.maxZ);
							if (max <= node.offsetMax) {
								geometry.next = negative;
								negative = geometry;
							} else if (min < node.offsetMin) {
								negativePart = geometry.create();
								geometry.split(axisX, axisY, node.offset, threshold, negativePart, null);
								geometry.destroy();
								// Если негативный не пустой
								if (negativePart.fragment != null) {
									negativePart.next = negative;
									negative = negativePart;
								} else {
									negativePart.destroy();
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
							min = axisX ? geometry.minX : (axisY ? geometry.minY : geometry.minZ);
							max = axisX ? geometry.maxX : (axisY ? geometry.maxY : geometry.maxZ);
							if (min >= node.offsetMin) {
								geometry.next = positive;
								positive = geometry;
							} else if (max > node.offsetMax) {
								positivePart = geometry.create();
								geometry.split(axisX, axisY, node.offset, threshold, null, positivePart);
								geometry.destroy();
								// Если позитивный не пустой
								if (positivePart.fragment != null) {
									positivePart.next = positive;
									positive = positivePart;
								} else {
									positivePart.destroy();
								}
							}
						}
						geometry = next;
					}
					// Отрисовка позитивной ноды
					drawNode(node.positive, positiveCulling, camera, object, canvas, positive);
				}
			// Конечная нода
			} else {
				// Если есть статические объекты, не считая окклюдеры
				if (nodeNumNonOccluders > 0) {
					// Если есть конфликт
					if (nodeNumNonOccluders > 1 || geometry != null) {
						// Перебор динамиков
						while (geometry != null) {
							next = geometry.next;
							// Проверка с окклюдерами
							if (geometry.numOccluders < numOccluders && occludeGeometry(camera, geometry)) {
								geometry.destroy();
							} else {
								geometry.vertices.length = geometry.verticesLength;
								object.cameraMatrix.transformVectors(geometry.vertices, geometry.vertices);
								geometry.next = middle;
								middle = geometry;
							}
							geometry = next;
						}
						// Превращение статиков в геометрию
						for (i = 0; i < nodeNumNonOccluders; i++) {
							staticChild = nodeObjects[i];
							if (staticChild.visible && staticChild.canDraw && ((staticChild.culling = culling) == 0 && numOccluders == 0 || (staticChild.culling = cullingInContainer(camera, node.bounds[i], culling)) >= 0)) {
								staticChild.cameraMatrix.identity();
								staticChild.cameraMatrix.prepend(object.cameraMatrix);
								staticChild.cameraMatrix.prepend(staticChild.matrix);
								geometry = staticChild.getGeometry(camera, staticChild);
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
								if (camera.debugMode) middle.debug(camera, object, canvas, threshold, 1);
								middle.draw(camera, canvas, threshold);
								middle.destroy();
							}
						}
					} else {
						// Если только один статик
						staticChild = nodeObjects[i];
						if (staticChild.visible && staticChild.canDraw) {
							staticChild.cameraMatrix.identity();
							staticChild.cameraMatrix.prepend(object.cameraMatrix);
							staticChild.cameraMatrix.prepend(staticChild.matrix);
							staticChild.culling = culling;
							if (camera.debugMode) staticChild.debug(camera, staticChild, canvas);
							staticChild.draw(camera, staticChild, canvas);
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
											geometry = middle;
											while (geometry != null) {
												geometry.vertices.length = geometry.verticesLength;
												object.cameraMatrix.transformVectors(geometry.vertices, geometry.vertices);
												if (!geometry.viewAligned) {
													geometry.calculateOOBB();
												}
												geometry = geometry.next;
											}
											drawOOBBGeometry(camera, object, canvas, middle);
										} else {
											geometry = middle;
											while (geometry != null) {
												geometry.vertices.length = geometry.verticesLength;
												object.cameraMatrix.transformVectors(geometry.vertices, geometry.vertices);
												geometry = geometry.next;
											}
											drawConflictGeometry(camera, object, canvas, middle);
										}
									} else {
										if (camera.debugMode) middle.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
										middle.draw(camera, canvas, threshold, object.cameraMatrix);
										middle.destroy();
									}
								}
							} else {
								// Разруливание
								middle = geometry;
								if (resolveByAABB) {
									drawAABBGeometry(camera, object, canvas, middle);
								} else if (resolveByOOBB) {
									geometry = middle;
									while (geometry != null) {
										geometry.vertices.length = geometry.verticesLength;
										object.cameraMatrix.transformVectors(geometry.vertices, geometry.vertices);
										if (!geometry.viewAligned) {
											geometry.calculateOOBB();
										}
										geometry = geometry.next;
									}
									drawOOBBGeometry(camera, object, canvas, middle);
								} else {
									geometry = middle;
									while (geometry != null) {
										geometry.vertices.length = geometry.verticesLength;
										object.cameraMatrix.transformVectors(geometry.vertices, geometry.vertices);
										geometry = geometry.next;
									}
									drawConflictGeometry(camera, object, canvas, middle);
								}
							}
						} else {
							// Проверка с окклюдерами и отрисовка
							if (geometry.numOccluders >= numOccluders || !occludeGeometry(camera, geometry)) {
								if (camera.debugMode) geometry.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
								geometry.draw(camera, canvas, threshold, object.cameraMatrix);
							}
							geometry.destroy();
						}
					}
				}
				// Если в ноде есть окклюдеры
				if (nodeNumObjects > nodeNumNonOccluders) {
					for (i = nodeNumNonOccluders; i < nodeNumObjects; i++) {
						staticChild = nodeObjects[i];
						if (staticChild.visible && staticChild.canDraw && ((staticChild.culling = culling) == 0 && numOccluders == 0 || (staticChild.culling = cullingInContainer(camera, node.bounds[i], culling)) >= 0)) {
							staticChild.cameraMatrix.identity();
							staticChild.cameraMatrix.prepend(object.cameraMatrix);
							staticChild.cameraMatrix.prepend(staticChild.matrix);
							if (camera.debugMode) staticChild.debug(camera, staticChild, canvas);
							staticChild.draw(camera, staticChild, canvas);
						}
					}
					// Обновление окклюдеров
					updateOccluders(camera);
				}
			}
		}

		static private const nodeVertices:Vector.<Number> = new Vector.<Number>(12, true);
		static private const nodeProjectedVertices:Vector.<Number> = new Vector.<Number>(8, true);
		static private const nodeUVTs:Vector.<Number> = new Vector.<Number>(12, true);

		private function debugNode(node:Node, culling:int, camera:Camera3D, object:Object3D, canvas:Canvas, alpha:Number):void {
			if (node.negative != null) {
				var negativeCulling:int = (culling > 0) ? cullingInContainer(camera, node.negative.boundBox, culling) : 0;
				var positiveCulling:int = (culling > 0) ? cullingInContainer(camera, node.positive.boundBox, culling) : 0;
				if (negativeCulling >= 0) {
					debugNode(node.negative, negativeCulling, camera, object, canvas, alpha*debugAlphaFade);
				}
				if (positiveCulling >= 0) {
					debugNode(node.positive, positiveCulling, camera, object, canvas, alpha*debugAlphaFade);
				}
				
				if (node.normalX) {
					nodeVertices[0] = node.offset;
					nodeVertices[1] = node.boundBox.minY;
					nodeVertices[2] = node.boundBox.maxZ;
					
					nodeVertices[3] = node.offset;
					nodeVertices[4] = node.boundBox.maxY;
					nodeVertices[5] = node.boundBox.maxZ;
					
					nodeVertices[6] = node.offset;
					nodeVertices[7] = node.boundBox.maxY;
					nodeVertices[8] = node.boundBox.minZ;
					
					nodeVertices[9] = node.offset;
					nodeVertices[10] = node.boundBox.minY;
					nodeVertices[11] = node.boundBox.minZ;
				} else if (node.normalY) {
					nodeVertices[0] = node.boundBox.maxX;
					nodeVertices[1] = node.offset;
					nodeVertices[2] = node.boundBox.maxZ;
					
					nodeVertices[3] = node.boundBox.minX;
					nodeVertices[4] = node.offset;
					nodeVertices[5] = node.boundBox.maxZ;
					
					nodeVertices[6] = node.boundBox.minX;
					nodeVertices[7] = node.offset;
					nodeVertices[8] = node.boundBox.minZ;
					
					nodeVertices[9] = node.boundBox.maxX;
					nodeVertices[10] = node.offset;
					nodeVertices[11] = node.boundBox.minZ;
				} else {
					nodeVertices[0] = node.boundBox.minX;
					nodeVertices[1] = node.boundBox.minY;
					nodeVertices[2] = node.offset;
					
					nodeVertices[3] = node.boundBox.maxX;
					nodeVertices[4] = node.boundBox.minY;
					nodeVertices[5] = node.offset;
					
					nodeVertices[6] = node.boundBox.maxX;
					nodeVertices[7] = node.boundBox.maxY;
					nodeVertices[8] = node.offset;
					
					nodeVertices[9] = node.boundBox.minX;
					nodeVertices[10] = node.boundBox.maxY;
					nodeVertices[11] = node.offset;
				}
				object.cameraMatrix.transformVectors(nodeVertices, nodeVertices);
				var i:int;
				for (i = 0; i < 12; i += 3) {
					if (nodeVertices[int(i + 2)] <= 0) break;
				}
				if (i == 12) {
					Utils3D.projectVectors(camera.projectionMatrix, nodeVertices, nodeProjectedVertices, nodeUVTs);
					canvas.gfx.lineStyle(0, node.normalX ? 0xFF0000 : (node.normalY ? 0x00FF00 : 0x0000FF));
					canvas.gfx.moveTo(nodeProjectedVertices[0], nodeProjectedVertices[1]);
					canvas.gfx.lineTo(nodeProjectedVertices[2], nodeProjectedVertices[3]);
					canvas.gfx.lineTo(nodeProjectedVertices[4], nodeProjectedVertices[5]);
					canvas.gfx.lineTo(nodeProjectedVertices[6], nodeProjectedVertices[7]);
					canvas.gfx.lineTo(nodeProjectedVertices[0], nodeProjectedVertices[1]);
				}
			}
		}
		
		public function createTree(staticObjects:Vector.<Object3D>, boundBox:BoundBox = null):void {
			var numStaticChildren:int = staticObjects.length;
			if (numStaticChildren > 0) {
				// Создаём корневую ноду
				rootNode = new Node();
				rootNode.objects = new Vector.<Object3D>();
				rootNode.bounds = new Vector.<BoundBox>();
				rootNode.numObjects = 0;
				// Расчитываем баунды объектов и рутовой ноды
				rootNode.boundBox = (boundBox != null) ? boundBox : new BoundBox();
				// Сначала добавляем не окклюдеры
				var staticOccluders:Vector.<Object3D> = new Vector.<Object3D>();
				var staticOccludersLength:int = 0;
				var object:Object3D;
				var objectBoundBox:BoundBox;
				for (var i:int = 0; i < numStaticChildren; i++) {
					object = staticObjects[i];
					// Поиск оригинального объекта
					var source:Object3D = object;
					while (source is Reference) {
						source = (source as Reference).referenceObject;
					}
					// Если окклюдер
					if (source is Occluder) {
						staticOccluders[staticOccludersLength++] = object;
					} else {
						objectBoundBox = object.calculateBoundBox(object.matrix);
						rootNode.objects[rootNode.numObjects] = object;
						rootNode.bounds[rootNode.numObjects++] = objectBoundBox;
						rootNode.boundBox.addBoundBox(objectBoundBox);
					}
				}
				// Добавляем окклюдеры
				for (i = 0; i < staticOccludersLength; i++) {
					object = staticOccluders[i];
					objectBoundBox = object.calculateBoundBox(object.matrix);
					rootNode.objects[rootNode.numObjects] = object;
					rootNode.bounds[rootNode.numObjects++] = objectBoundBox;
					rootNode.boundBox.addBoundBox(objectBoundBox);
				}
				// Разделяем рутовую ноду
				splitNode(rootNode);
			}
		}
		
		private var splitAxis:int;
		private var splitCoord:Number;
		private var splitCost:Number;
		static private const nodeBoundBoxThreshold:BoundBox = new BoundBox();
		static private const splitCoordsX:Vector.<Number> = new Vector.<Number>();
		static private const splitCoordsY:Vector.<Number> = new Vector.<Number>();
		static private const splitCoordsZ:Vector.<Number> = new Vector.<Number>();
		private function splitNode(node:Node):void {

			var object:Object3D, boundBox:BoundBox, i:int, j:int, k:int, c1:Number, c2:Number, coordMin:Number, coordMax:Number, area:Number, areaNegative:Number, areaPositive:Number, numNegative:int, numPositive:int, conflict:Boolean, cost:Number;
			var nodeBoundBox:BoundBox = node.boundBox;

			// Подготовка баунда с погрешностями
			nodeBoundBoxThreshold.minX = nodeBoundBox.minX + threshold;
			nodeBoundBoxThreshold.minY = nodeBoundBox.minY + threshold;
			nodeBoundBoxThreshold.minZ = nodeBoundBox.minZ + threshold;
			nodeBoundBoxThreshold.maxX = nodeBoundBox.maxX - threshold;
			nodeBoundBoxThreshold.maxY = nodeBoundBox.maxY - threshold;
			nodeBoundBoxThreshold.maxZ = nodeBoundBox.maxZ - threshold;
			var doubleThreshold:Number = threshold + threshold;

			// Собираем опорные координаты
			var numSplitCoordsX:int = 0, numSplitCoordsY:int = 0, numSplitCoordsZ:int = 0;
			for (i = 0; i < node.numObjects; i++) {
				boundBox = node.bounds[i];
				if (boundBox.maxX - boundBox.minX <= doubleThreshold) {
					if (boundBox.minX <= nodeBoundBoxThreshold.minX) splitCoordsX[numSplitCoordsX++] = nodeBoundBox.minX;
					else if (boundBox.maxX >= nodeBoundBoxThreshold.maxX) splitCoordsX[numSplitCoordsX++] = nodeBoundBox.maxX;
					else splitCoordsX[numSplitCoordsX++] = (boundBox.minX + boundBox.maxX)*0.5;
				} else {
					if (boundBox.minX > nodeBoundBoxThreshold.minX) splitCoordsX[numSplitCoordsX++] = boundBox.minX;
					if (boundBox.maxX < nodeBoundBoxThreshold.maxX) splitCoordsX[numSplitCoordsX++] = boundBox.maxX;
				}
				if (boundBox.maxY - boundBox.minY <= doubleThreshold) {
					if (boundBox.minY <= nodeBoundBoxThreshold.minY) splitCoordsY[numSplitCoordsY++] = nodeBoundBox.minY;
					else if (boundBox.maxY >= nodeBoundBoxThreshold.maxY) splitCoordsY[numSplitCoordsY++] = nodeBoundBox.maxY;
					else splitCoordsY[numSplitCoordsY++] = (boundBox.minY + boundBox.maxY)*0.5;
				} else {
					if (boundBox.minY > nodeBoundBoxThreshold.minY) splitCoordsY[numSplitCoordsY++] = boundBox.minY;
					if (boundBox.maxY < nodeBoundBoxThreshold.maxY) splitCoordsY[numSplitCoordsY++] = boundBox.maxY;
				}
				if (boundBox.maxZ - boundBox.minZ <= doubleThreshold) {
					if (boundBox.minZ <= nodeBoundBoxThreshold.minZ) splitCoordsZ[numSplitCoordsZ++] = nodeBoundBox.minZ;
					else if (boundBox.maxZ >= nodeBoundBoxThreshold.maxZ) splitCoordsZ[numSplitCoordsZ++] = nodeBoundBox.maxZ;
					else splitCoordsZ[numSplitCoordsZ++] = (boundBox.minZ + boundBox.maxZ)*0.5;
				} else {
					if (boundBox.minZ > nodeBoundBoxThreshold.minZ) splitCoordsZ[numSplitCoordsZ++] = boundBox.minZ;
					if (boundBox.maxZ < nodeBoundBoxThreshold.maxZ) splitCoordsZ[numSplitCoordsZ++] = boundBox.maxZ;
				}
			}
			
			// Убираем дубликаты координат, ищем наилучший сплит
			splitAxis = -1; splitCost = Number.MAX_VALUE;
			i = 0; area = (nodeBoundBox.maxY - nodeBoundBox.minY)*(nodeBoundBox.maxZ - nodeBoundBox.minZ);
			while (i < numSplitCoordsX) {
				if (!isNaN(c1 = splitCoordsX[i++])) {
					coordMin = c1 - threshold;
					coordMax = c1 + threshold;
					areaNegative = area*(c1 - nodeBoundBox.minX);
					areaPositive = area*(nodeBoundBox.maxX - c1);
					numNegative = numPositive = 0;
					conflict = false;
					// Проверяем объекты
					for (j = 0; j < node.numObjects; j++) {
						boundBox = node.bounds[j];
						if (boundBox.maxX <= coordMax) {
							if (boundBox.minX < coordMin) numNegative++;
						} else {
							if (boundBox.minX >= coordMin) numPositive++; else {conflict = true; break;}
						}
					}
					// Если хороший сплит, сохраняем
					if (!conflict && (cost = areaNegative*numNegative + areaPositive*numPositive) < splitCost) {
						splitCost = cost;
						splitAxis = 0;
						splitCoord = c1;
					}
					j = i;
					while (++j < numSplitCoordsX) if ((c2 = splitCoordsX[j]) >= c1 - threshold && c2 <= c1 + threshold) splitCoordsX[j] = NaN;
				} 
			}
			i = 0; area = (nodeBoundBox.maxX - nodeBoundBox.minX)*(nodeBoundBox.maxZ - nodeBoundBox.minZ);
			while (i < numSplitCoordsY) {
				if (!isNaN(c1 = splitCoordsY[i++])) {
					coordMin = c1 - threshold;
					coordMax = c1 + threshold;
					areaNegative = area*(c1 - nodeBoundBox.minY);
					areaPositive = area*(nodeBoundBox.maxY - c1);
					numNegative = numPositive = 0;
					conflict = false;
					// Проверяем объекты
					for (j = 0; j < node.numObjects; j++) {
						boundBox = node.bounds[j];
						if (boundBox.maxY <= coordMax) {
							if (boundBox.minY < coordMin) numNegative++;
						} else {
							if (boundBox.minY >= coordMin) numPositive++; else {conflict = true; break;}
						}
					}
					// Если хороший сплит, сохраняем
					if (!conflict && (cost = areaNegative*numNegative + areaPositive*numPositive) < splitCost) {
						splitCost = cost;
						splitAxis = 1;
						splitCoord = c1;
					}
					j = i;
					while (++j < numSplitCoordsY) if ((c2 = splitCoordsY[j]) >= c1 - threshold && c2 <= c1 + threshold) splitCoordsY[j] = NaN;
				} 
			}
			i = 0; area = (nodeBoundBox.maxX - nodeBoundBox.minX)*(nodeBoundBox.maxY - nodeBoundBox.minY);
			while (i < numSplitCoordsZ) {
				if (!isNaN(c1 = splitCoordsZ[i++])) {
					coordMin = c1 - threshold;
					coordMax = c1 + threshold;
					areaNegative = area*(c1 - nodeBoundBox.minZ);
					areaPositive = area*(nodeBoundBox.maxZ - c1);
					numNegative = numPositive = 0;
					conflict = false;
					// Проверяем объекты
					for (j = 0; j < node.numObjects; j++) {
						boundBox = node.bounds[j];
						if (boundBox.maxZ <= coordMax) {
							if (boundBox.minZ < coordMin) numNegative++;
						} else {
							if (boundBox.minZ >= coordMin) numPositive++; else {conflict = true; break;}
						}
					}
					// Если хороший сплит, сохраняем
					if (!conflict && (cost = areaNegative*numNegative + areaPositive*numPositive) < splitCost) {
						splitCost = cost;
						splitAxis = 2;
						splitCoord = c1;
					}
					j = i;
					while (++j < numSplitCoordsZ) if ((c2 = splitCoordsZ[j]) >= c1 - threshold && c2 <= c1 + threshold) splitCoordsZ[j] = NaN;
				}
			}

			// Если сплит не найден, выходим
			if (splitAxis < 0) {
				// Находим, откуда начинаются окклюдеры
				for (i = 0; i < node.numObjects; i++) {
					object = node.objects[i];
					// Поиск оригинального объекта
					while (object is Reference) object = (object as Reference).referenceObject;
					if (object is Occluder) break;
				}
				node.numNonOccluders = i;
				return;
			}
			
			// Разделяем ноду
			if (splitAxis == 0) {
				node.normalX = 1;
				node.normalY = 0;
				node.normalZ = 0;
			} else if (splitAxis == 1) {
				node.normalX = 0;
				node.normalY = 1;
				node.normalZ = 0;
			} else {
				node.normalX = 0;
				node.normalY = 0;
				node.normalZ = 1;
			}
			node.offset = splitCoord;
			node.offsetMin = splitCoord - threshold;
			node.offsetMax = splitCoord + threshold;
			
			// Создаём дочерние ноды
			node.negative = new Node();
			node.positive = new Node();
			node.negative.boundBox = nodeBoundBox.clone();
			node.positive.boundBox = nodeBoundBox.clone();
			node.negative.numObjects = 0;
			node.positive.numObjects = 0;
			if (node.normalX) {
				node.negative.boundBox.maxX = node.positive.boundBox.minX = splitCoord;
			} else if (node.normalY) {
				node.negative.boundBox.maxY = node.positive.boundBox.minY = splitCoord;
			} else {
				node.negative.boundBox.maxZ = node.positive.boundBox.minZ = splitCoord;
			}
			// Распределяем объекты по дочерним нодам
			for (i = 0; i < node.numObjects; i++) {
				object = node.objects[i];
				boundBox = node.bounds[i];
				var min:Number = node.normalX ? boundBox.minX : (node.normalY ? boundBox.minY : boundBox.minZ);
				var max:Number = node.normalX ? boundBox.maxX : (node.normalY ? boundBox.maxY : boundBox.maxZ);
				if (max <= node.offsetMax) {
					if (min < node.offsetMin) {
						// Объект в негативной стороне
						if (node.negative.objects == null) node.negative.objects = new Vector.<Object3D>(), node.negative.bounds = new Vector.<BoundBox>();
						node.negative.objects[node.negative.numObjects] = object, node.negative.bounds[node.negative.numObjects++] = boundBox;
						node.objects[i] = null, node.bounds[i] = null;
					} else {
						// Остаётся в ноде
					}
				} else {
					if (min >= node.offsetMin) {
						// Объект в положительной стороне
						if (node.positive.objects == null) node.positive.objects = new Vector.<Object3D>(), node.positive.bounds = new Vector.<BoundBox>();
						node.positive.objects[node.positive.numObjects] = object, node.positive.bounds[node.positive.numObjects++] = boundBox;
						node.objects[i] = null, node.bounds[i] = null;
					} else {
						// Распилился
					}
				}
			}
			
			// Очистка списка объектов
			for (i = 0, j = 0; i < node.numObjects; i++) if (node.objects[i] != null) node.objects[j] = node.objects[i], node.bounds[j++] = node.bounds[i];
			if (j > 0) {
				node.numObjects = node.objects.length = node.bounds.length = j;
				// Находим, откуда начинаются окклюдеры
				for (i = 0; i < node.numObjects; i++) {
					object = node.objects[i];
					// Поиск оригинального объекта
					while (object is Reference) object = (object as Reference).referenceObject;
					if (object is Occluder) break;
				}
				node.numNonOccluders = i;
			} else {
				node.numObjects = node.numNonOccluders = 0, node.objects = null, node.bounds = null;
			}
			
			// Разделение дочерних нод
			if (node.negative.objects != null) splitNode(node.negative);
			if (node.positive.objects != null) splitNode(node.positive);
		}
		
	}
}
