package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.WireMaterial;
	import alternativa.types.*;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	use namespace alternativa3d;
	use namespace alternativatypes;
	
	/**
	 * Сцена является контейнером 3D-объектов, с которыми ведётся работа. Все взаимодействия объектов
	 * происходят в пределах одной сцены. Класс обеспечивает работу системы сигналов и реализует алгоритм построения
	 * BSP-дерева для содержимого сцены.
	 */
	public class Scene3D {
		// Операции
		/**
		 * @private
		 * Полное обновление BSP-дерева
		 */
		alternativa3d var updateBSPOperation:Operation = new Operation("updateBSP", this);
		/**
		 * @private
		 * Изменение примитивов
		 */
		alternativa3d var changePrimitivesOperation:Operation = new Operation("changePrimitives", this);
		/**
		 * @private
		 * Расчёт BSP-дерева
		 */
		alternativa3d var calculateBSPOperation:Operation = new Operation("calculateBSP", this, calculateBSP, Operation.SCENE_CALCULATE_BSP);
		/**
		 * @private
		 * Очистка списков изменений
		 */
		alternativa3d var clearPrimitivesOperation:Operation = new Operation("clearPrimitives", this, clearPrimitives, Operation.SCENE_CLEAR_PRIMITIVES);
		
		/**
		 * @private
		 * Корневой объект
		 */
		alternativa3d var _root:Object3D;
		
		/**
		 * @private
		 * Список операций на выполнение
		 */ 
		alternativa3d var operations:Array = new Array();
		//protected var operationSort:Array = ["priority"];
		//protected var operationSortOptions:Array = [Array.NUMERIC];
		/**
		 * @private
		 * Вспомогательная пустая операция, используется при удалении операций из списка
		 */ 
		alternativa3d var dummyOperation:Operation = new Operation("removed", this);
		
		/**
		 * @private
		 * Флаг анализа сплиттеров
		 */ 
		alternativa3d var _splitAnalysis:Boolean = true;
		/**
		 * @private
		 * Cбалансированность дерева
		 */ 
		alternativa3d var _splitBalance:Number = 0;
		/**
		 * @private
		 * Список изменённых примитивов
		 */
		alternativa3d var changedPrimitives:Set = new Set();
		
		// Вспомогательный список для сборки дочерних примитивов
		private var childPrimitives:Set = new Set();
		/**
		 * @private
		 * Список примитивов на добавление/удаление
		 */
		alternativa3d var addPrimitives:Array = new Array();
		
//		alternativa3d var addSort:Array = ["mobility"];
//		alternativa3d var addSortOptions:Array = [Array.NUMERIC | Array.DESCENDING];
//		alternativa3d var addSplitQualitySort:Array = ["mobility", "splitQuality"];
//		alternativa3d var addSplitQualitySortOptions:Array = [Array.NUMERIC | Array.DESCENDING, Array.NUMERIC | Array.DESCENDING];
		/**
		 * @private
		 * Погрешность при определении точек на плоскости
		 */
		alternativa3d const planeOffsetThreshold:Number = 0.01;
		/**
		 * @private
		 * BSP-дерево
		 */
		alternativa3d var bsp:BSPNode;
		
		/**
		 * @private
		 * Список нод на удаление
		 */
		alternativa3d var removeNodes:Set = new Set();
		/**
		 * @private
		 * Вспомогательная пустая нода, используется при удалении нод из дерева
		 */
		alternativa3d var dummyNode:BSPNode = new BSPNode();

		/**
		 * Создание экземпляра сцены.
		 */
		public function Scene3D() {
			// Обновление BSP-дерева требует его пересчёта
			updateBSPOperation.addSequel(calculateBSPOperation);
			// После пересчёта дерева необходимо очистить списки изменений
			calculateBSPOperation.addSequel(clearPrimitivesOperation);
			// Изменение примитивов в случае пересчёта дерева
			calculateBSPOperation.addSequel(changePrimitivesOperation);
		}
		
		/**
		 * Расчёт сцены. Метод анализирует все изменения, произошедшие с момента предыдущего расчёта, формирует список
		 * команд и исполняет их в необходимой последовательности. В результате расчёта происходит перерисовка во всех
		 * областях вывода, к которым подключены находящиеся в сцене камеры.
		 */
		public function calculate():void {
			if (operations[0] != undefined) {
				// Формируем последствия
				var operation:Operation;
				var length:uint = operations.length;
				var i:uint;
				for (i = 0; i < length; i++) {
					operation = operations[i];
					operation.collectSequels(operations);
				}
				// Сортируем операции
				length = operations.length;
				//operations.sortOn(operationSort, operationSortOptions);
				sortOperations(0, length - 1);
				// Запускаем операции
				//trace("----------------------------------------");
				for (i = 0; i < length; i++) {
					operation = operations[i];
					if (operation.method != null) {
						//trace("EXECUTE:", operation);
						operation.method();
					} else {
						/*if (operation == dummyOperation) {
							trace("REMOVED");
						} else {
							trace(operation);
						}*/
					}
				}
				// Очищаем список операций
				for (i = 0; i < length; i++) {
					operation = operations.pop();
					operation.queued = false;
				}
			}
		}

		/**
		 * @private
		 * Сортировка операций, если массив operations пуст будет ошибка
		 *  
		 * @param l начальный элемент
		 * @param r конечный элемент
		 */
		alternativa3d function sortOperations(l:int, r:int):void {
			var i:int = l;
			var j:int = r;
			var left:Operation;
			var mid:uint = operations[(r + l) >>> 1].priority;
			var right:Operation;
			do {
 				while ((left = operations[i]).priority < mid) {i++};
 				while (mid < (right = operations[j]).priority) {j--};
 				if (i <= j) {
					operations[i++] = right;
					operations[j--] = left;
 				}
			} while (i <= j)
			if (l < j) {
				sortOperations(l, j);
			}
			if (i < r) {
				sortOperations(i, r);
			}
		}

		/**
		 * @private
		 * Добавление операции в список
		 * 
		 * @param operation добавляемая операция
		 */
		alternativa3d function addOperation(operation:Operation):void {
			if (!operation.queued) {
				operations.push(operation);
				operation.queued = true;
			}
		}

		/**
		 * @private
		 * удаление операции из списка
		 * 
		 * @param operation удаляемая операция
		 */
		alternativa3d function removeOperation(operation:Operation):void {
			if (operation.queued) {
				operations[operations.indexOf(operation)] = dummyOperation;
				operation.queued = false;
			}
		}
		
		/**
		 * @private
		 * Расчёт изменений в BSP-дереве.
		 * Обработка удалённых и добавленных примитивов.
		 */
		protected function calculateBSP():void {
			if (updateBSPOperation.queued) {
				
				// Удаление списка нод, помеченных на удаление
				removeNodes.clear();

				// Удаление BSP-дерева, перенос примитивов в список дочерних
				childBSP(bsp);
				bsp = null;
				
				// Собираем дочерние примитивы в список нижних
				assembleChildPrimitives();
				
			} else {

				var key:*;
				var primitive:PolyPrimitive;

				// Удаляем ноды из дерева
				if (!removeNodes.isEmpty()) {
					var node:BSPNode;
					while ((node = removeNodes.peek()) != null) {
						
						// Ищем верхнюю удаляемую ноду
						var removeNode:BSPNode = node;
						while ((node = node.parent) != null) {
							if (removeNodes[node]) {
								removeNode = node;
							}
						}
						
						// Удаляем ветку
						var parent:BSPNode = removeNode.parent;
						var replace:BSPNode = removeBSPNode(removeNode);
						
						// Если вернулась вспомогательная нода, игнорируем её 
						if (replace == dummyNode) {
							replace = null;
						}
						
						// Если есть родительская нода
						if (parent != null) {
							// Заменяем себя на указанную ноду
							if (parent.front == removeNode) {
								parent.front = replace;
							} else {
								parent.back = replace;
							}
						} else {
							// Если нет родительской ноды, значит заменяем корень на указанную ноду
							bsp = replace;
						}
						
						// Устанавливаем связь с родителем для заменённой ноды
						if (replace != null) {
							replace.parent = parent;
						}
					}
					
					// Собираем дочерние примитивы в список на добавление
					assembleChildPrimitives();
				}
			}
			
			// Если есть примитивы на добавление
			if (addPrimitives[0] != undefined) {
				
				// Если включен анализ сплиттеров
				if (_splitAnalysis) {
					// Рассчитываем качество рассечения примитивов
					splitQualityAnalise();
					// Сортируем массив примитивов c учётом качества
					//addPrimitives.sortOn(addSplitQualitySort, addSplitQualitySortOptions);
					sortPrimitives(0, addPrimitives.length - 1);
				} else {
					// Сортируем массив по мобильности
					///addPrimitives.sortOn(addSort, addSortOptions);
					sortPrimitivesByMobility(0, addPrimitives.length - 1);
				}
				
				// Если корневого нода ещё нет, создаём
				if (bsp == null) {
					primitive = addPrimitives.pop();
					bsp = BSPNode.createBSPNode(primitive);
					changedPrimitives[primitive] = true;
				}
				
				// Встраиваем примитивы в дерево
				while ((primitive = addPrimitives.pop()) != null) {
					addBSP(bsp, primitive);
				}
			}
		}
		
		/**
		 * @private
		 * Сортировка граней, если массив addPrimitives пуст будет ошибка
		 *
		 * @param l начальный элемент
		 * @param r конечный элемент
		 */
 		alternativa3d function sortPrimitives(l:int, r:int):void {
			var i:int = l;
			var j:int = r;
			var left:PolyPrimitive;
			var mid:PolyPrimitive = addPrimitives[(r + l)>>>1];
			var midMobility:Number = mid.mobility;
			var midSplitQuality:Number = mid.splitQuality;
			var right:PolyPrimitive;
			do {
 				while (((left = addPrimitives[i]).mobility > midMobility) || ((left.mobility == midMobility) && (left.splitQuality > midSplitQuality))) {i++};
 				while ((midMobility > (right = addPrimitives[j]).mobility) || ((midMobility == right.mobility) && (midSplitQuality > right.splitQuality))) {j--};
 				if (i <= j) {
					addPrimitives[i++] = right;
					addPrimitives[j--] = left;
 				}
			} while (i <= j)
			if (l < j) {
				sortPrimitives(l, j);
			}
			if (i < r) {
				sortPrimitives(i, r);
			}
		}

		/**
		 * @private
		 * Сортировка только по мобильности 
		 * 
		 * @param l начальный элемент
		 * @param r конечный элемент
		 */
		alternativa3d function sortPrimitivesByMobility(l:int, r:int):void {
			var i:int = l;
			var j:int = r;
			var left:PolyPrimitive;
			var mid:int = addPrimitives[(r + l)>>>1].mobility;
			var right:PolyPrimitive;
			do {
 				while ((left = addPrimitives[i]).mobility > mid) {i++};
 				while (mid > (right = addPrimitives[j]).mobility) {j--};
 				if (i <= j) {
					addPrimitives[i++] = right;
					addPrimitives[j--] = left;
 				}
			} while (i <= j)
			if (l < j) {
				sortPrimitivesByMobility(l, j);
			}
			if (i < r) {
				sortPrimitivesByMobility(i, r);
			}
		}

		
		/**
		 * @private
		 * Анализ качества сплиттеров
		 */
		private function splitQualityAnalise():void {
			// Перебираем примитивы на добавление
			var i:uint;
			var length:uint = addPrimitives.length;
			var maxSplits:uint = 0;
			var maxDisbalance:uint = 0;
			var splitter:PolyPrimitive;
			for (i = 0; i < length; i++) {
				splitter = addPrimitives[i];
				splitter.splits = 0;
				splitter.disbalance = 0;
				var normal:Point3D = splitter.face.globalNormal;
				var offset:Number = splitter.face.globalOffset;
				// Проверяем соотношение с другими примитивами не меньшей мобильности на добавление
				for (var j:uint = 0; j < length; j++) {
					if (i != j) { 
						var primitive:PolyPrimitive = addPrimitives[j];
						if (splitter.mobility <= primitive.mobility) {
							// Проверяем наличие точек спереди и сзади сплиттера
							var pointsFront:Boolean = false;
							var pointsBack:Boolean = false;
							for (var k:uint = 0; k < primitive.num; k++) {
								var point:Point3D = primitive.points[k];
								var pointOffset:Number = point.x*normal.x + point.y*normal.y + point.z*normal.z - offset;
								if (pointOffset > planeOffsetThreshold) {
									if (!pointsFront) {
										splitter.disbalance++;
										pointsFront = true;
									}
									if (pointsBack) {
										splitter.splits++;
										break;
									}
								} else {
									if (pointOffset < -planeOffsetThreshold) {
										if (!pointsBack) {
											splitter.disbalance--;
											pointsBack = true;
										}
										if (pointsFront) {
											splitter.splits++;
											break;
										}
									}
								}
							}
						}
					} 
				}
				// Абсолютное значение дисбаланса
				splitter.disbalance = (splitter.disbalance > 0) ? splitter.disbalance : -splitter.disbalance;
				// Ищем максимальное количество рассечений и значение дисбаланса
				maxSplits = (maxSplits > splitter.splits) ? maxSplits : splitter.splits;
				maxDisbalance = (maxDisbalance > splitter.disbalance) ? maxDisbalance : splitter.disbalance;
			}
			// Расчитываем качество сплиттеров
			for (i = 0; i < length; i++) {
				splitter = addPrimitives[i];
				splitter.splitQuality = (1 - _splitBalance)*splitter.splits/maxSplits + _splitBalance*splitter.disbalance/maxDisbalance;
			}
		}
		
		/**
		 * @private
		 * Добавление примитива в BSP-дерево
		 * 
		 * @param node текущий узел дерева, в который добавляется примитив
		 * @param primitive добавляемый примитив
		 */
		protected function addBSP(node:BSPNode, primitive:PolyPrimitive):void {
			var point:Point3D;
			var normal:Point3D;
			var key:*;

			// Сравниваем мобильности ноды и примитива
			if (primitive.mobility < node.mobility) {
				
				// Формируем список содержимого ноды и всех примитивов ниже
				if (node.primitive != null) {
					childPrimitives[node.primitive] = true;
					changedPrimitives[node.primitive] = true;
					node.primitive.node = null;
				} else {
					var p:PolyPrimitive;
					for (key in node.backPrimitives) {
						p = key;
						childPrimitives[p] = true;
						changedPrimitives[p] = true;
						p.node = null;
					}
					for (key in node.frontPrimitives) {
						p = key;
						childPrimitives[p] = true;
						changedPrimitives[p] = true;
						p.node = null;
					}
				}
				childBSP(node.back);
				childBSP(node.front);
				
				// Собираем дочерние примитивы в список нижних
				assembleChildPrimitives();
				
				// Если включен анализ сплиттеров
				if (_splitAnalysis) {
					// Рассчитываем качество рассечения примитивов
					splitQualityAnalise();
					// Сортируем массив примитивов c учётом качества
					sortPrimitives(0, addPrimitives.length - 1);
				} else {
					// Сортируем массив по мобильности
					sortPrimitivesByMobility(0, addPrimitives.length - 1);
				}
				
				// Добавляем примитив в ноду
				node.primitive = primitive;
				
				// Пометка об изменении примитива
				changedPrimitives[primitive] = true;

				// Сохраняем ноду
				primitive.node = node;

				// Сохраняем плоскость
				node.normal.copy(primitive.face.globalNormal);
				node.offset = primitive.face.globalOffset;

				// Сохраняем мобильность
				node.mobility = primitive.mobility;

				// Чистим списки примитивов
				node.backPrimitives = null;
				node.frontPrimitives = null;

				// Удаляем дочерние ноды
				node.back = null;
				node.front = null;

			} else {
				// Получаем нормаль из ноды
				normal = node.normal;
			
				var points:Array = primitive.points;
				var uvs:Array = primitive.uvs;

				// Собирательные флаги 
				var pointsFront:Boolean = false;
				var pointsBack:Boolean = false;
				
				// Собираем расстояния точек до плоскости
				for (var i:uint = 0; i < primitive.num; i++) {
					point = points[i];
					var pointOffset:Number = point.x*normal.x + point.y*normal.y + point.z*normal.z - node.offset;
					if (pointOffset > planeOffsetThreshold) {
						pointsFront = true;
						if (pointsBack) {
							break;
						}
					} else {
						if (pointOffset < -planeOffsetThreshold) {
							pointsBack = true;
							if (pointsFront) {
								break;
							}
						}
					}
				}

				if (!pointsFront && !pointsBack) {
					// Сохраняем ноду
					primitive.node = node;

					// Если был только базовый примитив, переносим его в список  
					if (node.primitive != null) {
						node.frontPrimitives = new Set(true);
						node.frontPrimitives[node.primitive] = true;
						node.primitive = null;
					}

					// Примитив находится в плоскости ноды
					if (Point3D.dot(primitive.face.globalNormal, normal) > 0) {
						node.frontPrimitives[primitive] = true;
					} else {
						if (node.backPrimitives == null) {
							node.backPrimitives = new Set(true);
						}
						node.backPrimitives[primitive] = true;
					}
					
					// Пометка об изменении примитива
					changedPrimitives[primitive] = true;
				} else {
					if (!pointsBack) {
						// Примитив спереди плоскости ноды
						if (node.front == null) {
							// Создаём переднюю ноду
							node.front = BSPNode.createBSPNode(primitive);
							node.front.parent = node;
							changedPrimitives[primitive] = true;
						} else {
							// Добавляем примитив в переднюю ноду
							addBSP(node.front, primitive);
						}
					} else {
						if (!pointsFront) {
							// Примитив сзади плоскости ноды
							if (node.back == null) {
								// Создаём заднюю ноду
								node.back = BSPNode.createBSPNode(primitive);
								node.back.parent = node;
								changedPrimitives[primitive] = true;
							} else {
								// Добавляем примитив в заднюю ноду
								addBSP(node.back, primitive);
							}
						} else {
							// Рассечение
							var backFragment:PolyPrimitive = PolyPrimitive.createPolyPrimitive();
							var frontFragment:PolyPrimitive = PolyPrimitive.createPolyPrimitive();
							
							var firstSplit:Boolean = true;
							
							point = points[0];
							var offset0:Number = point.x*normal.x + point.y*normal.y + point.z*normal.z - node.offset;
							var offset1:Number = offset0;
							var offset2:Number;
							for (i = 0; i < primitive.num; i++) {
								var j:uint;
								if (i < primitive.num - 1) {
									j = i + 1;
									point = points[j];
									offset2 = point.x*normal.x + point.y*normal.y + point.z*normal.z - node.offset;
								} else {
									j = 0;
									offset2 = offset0;
								}
								
								if (offset1 > planeOffsetThreshold) {
									// Точка спереди плоскости ноды
									frontFragment.points.push(points[i]);
									frontFragment.uvs.push(primitive.uvs[i]);
								} else {
									if (offset1 < -planeOffsetThreshold) {
										// Точка сзади плоскости ноды
										backFragment.points.push(points[i]);
										backFragment.uvs.push(primitive.uvs[i]);
									} else {
										// Рассечение по точке примитива
										backFragment.points.push(points[i]);
										backFragment.uvs.push(primitive.uvs[i]);
										frontFragment.points.push(points[i]);
										frontFragment.uvs.push(primitive.uvs[i]);
									}
								}
								
								// Рассечение ребра
								if (offset1 > planeOffsetThreshold && offset2 < -planeOffsetThreshold || offset1 < -planeOffsetThreshold && offset2 > planeOffsetThreshold) {
									// Находим точку рассечения
									var t:Number = offset1/(offset1 - offset2);
									point = Point3D.interpolate(points[i], points[j], t);
									backFragment.points.push(point);
									frontFragment.points.push(point);
									// Находим UV в точке рассечения
									var uv:Point;
									if (primitive.face.uvMatrixBase != null) {
									 	uv = Point.interpolate(uvs[j], uvs[i], t);
									} else {
										uv = null;
									}
									backFragment.uvs.push(uv);
									frontFragment.uvs.push(uv);
									// Отмечаем рассечённое ребро
									if (firstSplit) {
										primitive.splitTime1 = t;
										firstSplit = false;
									} else {
										primitive.splitTime2 = t;
									}
								}
								
								offset1 = offset2;
							}
							backFragment.num = backFragment.points.length;
							frontFragment.num = frontFragment.points.length;
							
							// Назначаем мобильность
							backFragment.mobility = primitive.mobility;
							frontFragment.mobility = primitive.mobility;

							// Устанавливаем связи рассечённых примитивов
							backFragment.face = primitive.face;
							frontFragment.face = primitive.face;
							backFragment.parent = primitive;
							frontFragment.parent = primitive;
							backFragment.sibling = frontFragment;
							frontFragment.sibling = backFragment;
							primitive.backFragment = backFragment;
							primitive.frontFragment = frontFragment;
							
							// Добавляем фрагменты в дочерние ноды 
							if (node.back == null) {
								node.back = BSPNode.createBSPNode(backFragment);
								node.back.parent = node;
								changedPrimitives[backFragment] = true;
							} else {
								addBSP(node.back, backFragment);
							}
							if (node.front == null) {
								node.front = BSPNode.createBSPNode(frontFragment);
								node.front.parent = node;
								changedPrimitives[frontFragment] = true;
							} else {
								addBSP(node.front, frontFragment);
							}
						}
					}
				}
			}
		}

		/**
		 * @private
		 * Удаление узла BSP-дерева, включая все дочерние узлы, помеченные для удаления.
		 * 
		 * @param node удаляемый узел
		 * @return корневой узел поддерева, оставшегося после операции удаления
		 */
		protected function removeBSPNode(node:BSPNode):BSPNode {
			var replaceNode:BSPNode;
			if (node != null) {
				// Удаляем дочерние
				node.back = removeBSPNode(node.back);
				node.front = removeBSPNode(node.front);

				if (!removeNodes[node]) {
					// Если нода не удаляется, возвращает себя 
					replaceNode = node;
					
					// Проверяем дочерние ноды
					if (node.back != null) {
						if (node.back != dummyNode) {
							node.back.parent = node;
						} else {
							node.back = null;
						}
					}
					if (node.front != null) {
						if (node.front != dummyNode) {
							node.front.parent = node;
						} else {
							node.front = null;
						}
					}
				} else {
					// Проверяем дочерние ветки
					if (node.back == null) {
						if (node.front != null) {
							// Есть только передняя ветка
							replaceNode = node.front;
							node.front = null;
						}
					} else {
						if (node.front == null) {
							// Есть только задняя ветка
							replaceNode = node.back;
							node.back = null;
						} else {
							// Есть обе ветки - собираем дочерние примитивы
							childBSP(node.back);
							childBSP(node.front);
							// Используем вспомогательную ноду
							replaceNode = dummyNode;
							// Удаляем связи с дочерними нодами
							node.back = null;
							node.front = null;
						}
					}

					// Удаляем ноду из списка на удаление
					delete removeNodes[node];
					// Удаляем ноду
					node.parent = null;
					BSPNode.destroyBSPNode(node);
				}
			}
			return replaceNode;
		}

		/**
		 * @private
		 * Удаление примитива из узла дерева
		 * 
		 * @param primitive удаляемый примитив
		 */
		alternativa3d function removeBSPPrimitive(primitive:PolyPrimitive):void {
			var node:BSPNode = primitive.node;
			primitive.node = null;
			
			var single:Boolean = false;
			var key:*;
			
			// Пометка об изменении примитива
			changedPrimitives[primitive] = true;
			
			// Если нода единичная
			if (node.primitive == primitive) {
				removeNodes[node] = true;
				node.primitive = null;
			} else {
				// Есть передние примитивы
				if (node.frontPrimitives[primitive]) {
					// Удаляем примитив спереди
					delete node.frontPrimitives[primitive];
					
					// Проверяем количество примитивов спереди
					for (key in node.frontPrimitives) {
						if (single) {
							single = false;
							break;
						}
						single = true;
					}
					
					if (key == null) {
						// Передняя пуста, значит сзади кто-то есть
						
						// Переворачиваем дочерние ноды
						var t:BSPNode = node.back;
						node.back = node.front;
						node.front = t;
						
						// Переворачиваем плоскость ноды
						node.normal.invert();
						node.offset = -node.offset;
						
						// Проверяем количество примитивов сзади
						for (key in node.backPrimitives) {
							if (single) {
								single = false;
								break;
							}
							single = true;
						}

						// Если сзади один примитив
						if (single) {
							// Устанавливаем базовый примитив ноды
							node.primitive = key;
							// Устанавливаем мобильность
							node.mobility = node.primitive.mobility;
							// Стираем список передних примитивов
							node.frontPrimitives = null;
						} else {
							// Если сзади несколько примитивов, переносим их в передние
							node.frontPrimitives = node.backPrimitives;
							// Пересчитываем мобильность ноды по передним примитивам
							if (primitive.mobility == node.mobility) {
								node.mobility = int.MAX_VALUE;
								for (key in node.frontPrimitives) {
									primitive = key;
									node.mobility = (node.mobility > primitive.mobility) ? primitive.mobility : node.mobility;
								}
							}
						}
						
						// Стираем список задних примитивов
						node.backPrimitives = null;
						
					} else {
						// Если остался один примитив и сзади примитивов нет
						if (single && node.backPrimitives == null) {
							// Устанавливаем базовый примитив ноды
							node.primitive = key;
							// Устанавливаем мобильность
							node.mobility = node.primitive.mobility;
							// Стираем список передних примитивов
							node.frontPrimitives = null;
						} else {
							// Пересчитываем мобильность ноды
							if (primitive.mobility == node.mobility) {
								node.mobility = int.MAX_VALUE;
								for (key in node.backPrimitives) {
									primitive = key;
									node.mobility = (node.mobility > primitive.mobility) ? primitive.mobility : node.mobility;
								}
								for (key in node.frontPrimitives) {
									primitive = key;
									node.mobility = (node.mobility > primitive.mobility) ? primitive.mobility : node.mobility;
								}
							}
						}
					}
				} else {
					// Удаляем примитив сзади
					delete node.backPrimitives[primitive];

					// Проверяем количество примитивов сзади
					for (key in node.backPrimitives) {
						break;
					}
					
					// Если сзади примитивов больше нет
					if (key == null) {
						// Проверяем количество примитивов спереди
						for (key in node.frontPrimitives) {
							if (single) {
								single = false;
								break;
							}
							single = true;
						}
						
						// Если спереди один примитив
						if (single) {
							// Устанавливаем базовый примитив ноды
							node.primitive = key;
							// Устанавливаем мобильность
							node.mobility = node.primitive.mobility;
							// Стираем список передних примитивов
							node.frontPrimitives = null;
						} else {
							// Пересчитываем мобильность ноды по передним примитивам
							if (primitive.mobility == node.mobility) {
								node.mobility = int.MAX_VALUE;
								for (key in node.frontPrimitives) {
									primitive = key;
									node.mobility = (node.mobility > primitive.mobility) ? primitive.mobility : node.mobility;
								}
							}
						}
						
						// Стираем список задних примитивов
						node.backPrimitives = null;
					} else {
						// Пересчитываем мобильность ноды
						if (primitive.mobility == node.mobility) {
							node.mobility = int.MAX_VALUE;
							for (key in node.backPrimitives) {
								primitive = key;
								node.mobility = (node.mobility > primitive.mobility) ? primitive.mobility : node.mobility;
							}
							for (key in node.frontPrimitives) {
								primitive = key;
								node.mobility = (node.mobility > primitive.mobility) ? primitive.mobility : node.mobility;
							}
						}
					}
				}
			}
		}
		
		/**
		 * @private
		 * Удаление и перевставка ветки
		 * 
		 * @param node
		 */
		protected function childBSP(node:BSPNode):void {
			if (node != null && node != dummyNode) {
				var primitive:PolyPrimitive = node.primitive;
				if (primitive != null) {
					childPrimitives[primitive] = true;
					changedPrimitives[primitive] = true;
					node.primitive = null;
					primitive.node = null;
				} else {
					for (var key:* in node.backPrimitives) {
						primitive = key;
						childPrimitives[primitive] = true;
						changedPrimitives[primitive] = true;
						primitive.node = null;
					}
					for (key in node.frontPrimitives) {
						primitive = key;
						childPrimitives[primitive] = true;
						changedPrimitives[primitive] = true;
						primitive.node = null;
					}
					node.backPrimitives = null;
					node.frontPrimitives = null;
				}
				childBSP(node.back);
				childBSP(node.front);
				// Удаляем ноду
				node.parent = null;
				node.back = null;
				node.front = null;
				BSPNode.destroyBSPNode(node);
			}
		}

		/**
		 * @private
		 * Сборка списка дочерних примитивов в коллектор
		 */
		protected function assembleChildPrimitives():void {
			var primitive:PolyPrimitive;
			while ((primitive = childPrimitives.take()) != null) {
				assemblePrimitive(primitive);
			}
		}
		
		/**
		 * @private
		 * Сборка примитивов и разделение на добавленные и удалённые
		 * 
		 * @param primitive
		 */
		private function assemblePrimitive(primitive:PolyPrimitive):void {
			// Если есть соседний примитив и он может быть собран
			if (primitive.sibling != null && canAssemble(primitive.sibling)) {
				// Собираем их в родительский
				assemblePrimitive(primitive.parent);
				// Зачищаем связи между примитивами
				primitive.sibling.sibling = null;
				primitive.sibling.parent = null;
				PolyPrimitive.destroyPolyPrimitive(primitive.sibling);
				primitive.sibling = null;
				primitive.parent.backFragment = null;
				primitive.parent.frontFragment = null;
				primitive.parent = null;
				PolyPrimitive.destroyPolyPrimitive(primitive);
			} else {
				// Если собраться не получилось или родительский
				addPrimitives.push(primitive);
			}
		}
		
		/**
		 * @private
		 * Проверка, может ли примитив в списке дочерних быть собран
		 * 
		 * @param primitive
		 * @return 
		 */
		private function canAssemble(primitive:PolyPrimitive):Boolean {
			if (childPrimitives[primitive]) {
				delete childPrimitives[primitive];
				return true;
			} else {
				var backFragment:PolyPrimitive = primitive.backFragment;
				var frontFragment:PolyPrimitive = primitive.frontFragment;
				if (backFragment != null) {
					var assembleBack:Boolean = canAssemble(backFragment);
					var assembleFront:Boolean = canAssemble(frontFragment);
					if (assembleBack && assembleFront) {
						backFragment.parent = null;
						frontFragment.parent = null;
						backFragment.sibling = null;
						frontFragment.sibling = null;
						primitive.backFragment = null;
						primitive.frontFragment = null;
						PolyPrimitive.destroyPolyPrimitive(backFragment);
						PolyPrimitive.destroyPolyPrimitive(frontFragment);
						return true;
					} else {
						if (assembleBack) {
							addPrimitives.push(backFragment);
						}
						if (assembleFront) {
							addPrimitives.push(frontFragment);
						}
					}
				}
			}
			return false;
		}
		
		/**
		 * @private
		 * Очистка списков
		 */
		private function clearPrimitives():void {
			changedPrimitives.clear();
		}
		
		/**
		 * Корневой объект сцены.
		 */
		public function get root():Object3D {
			return _root;
		}

		/**
		 * @private
		 */
		public function set root(value:Object3D):void {
			// Если ещё не является корневым объектом
			if (_root != value) {
				// Если устанавливаем не пустой объект
				if (value != null) {
					// Если объект был в другом объекте
					if (value._parent != null) {
						// Удалить его оттуда
						value._parent._children.remove(value);
					} else {
						// Если объект был корневым в сцене
						if (value._scene != null && value._scene._root == value) {
							value._scene.root = null;
						}
					}
					// Удаляем ссылку на родителя
					value.setParent(null);
					// Указываем сцену
					value.setScene(this);
					// Устанавливаем уровни
					value.setLevel(0);
				}
				
				// Если был корневой объект
				if (_root != null) {
					// Удаляем ссылку на родителя
					_root.setParent(null);
					// Удаляем ссылку на камеру
					_root.setScene(null);
				}
				
				// Сохраняем корневой объект
				_root = value;
			}
		}

		/**
		 * Флаг активности анализа сплиттеров. 
		 * В режиме анализа для каждого добавляемого в BSP-дерево полигона выполняется его оценка в качестве разделяющей
		 * плоскости (сплиттера). Наиболее качественные сплиттеры добавляются в BSP-дерево первыми.
		 * 
		 * <p> Изменением свойства <code>splitBalance</code> можно влиять на конечный вид BSP-дерева.
		 * 
		 * @see #splitBalance
		 * @default true
		 */
		public function get splitAnalysis():Boolean {
			return _splitAnalysis;
		}

		/**
		 * @private
		 */
		public function set splitAnalysis(value:Boolean):void {
			if (_splitAnalysis != value) {
				_splitAnalysis = value;
				addOperation(updateBSPOperation);
			}
		}

		/**
		 * Параметр балансировки BSP-дерева при влюченном режиме анализа сплиттеров.
		 * Может принимать значения от 0 (минимизация фрагментирования полигонов) до 1 (максимальный баланс BSP-дерева).
		 * 
		 * @see #splitAnalysis
 		 * @default 0
		 */
		public function get splitBalance():Number {
			return _splitBalance;
		}

		/**
		 * @private
		 */
		public function set splitBalance(value:Number):void {
			value = (value < 0) ? 0 : ((value > 1) ? 1 : value);
			if (_splitBalance != value) {
				_splitBalance = value;
				if (_splitAnalysis) {
					addOperation(updateBSPOperation);
				}
			}
		}
		
		/**
		 * Визуализация BSP-дерева. Дерево рисуется в заданном контейнере. Каждый узел дерева обозначается точкой, имеющей
		 * цвет материала (в случае текстурного материала показывается цвет первой точки текстуры) первого полигона из этого
		 * узла. Задние узлы рисуются слева-снизу от родителя, передние справа-снизу. 
		 * 
		 * @param container контейнер для отрисовки дерева 
		 */
		public function drawBSP(container:Sprite):void {
			
			container.graphics.clear();
			while (container.numChildren > 0) {
				container.removeChildAt(0);
			}
			if (bsp != null) {
				drawBSPNode(bsp, container, 0, 0, 1);
			}
		}
		
		/**
		 * @private
		 * Отрисовка узла BSP-дерева при визуализации
		 * 
		 * @param node
		 * @param container
		 * @param x
		 * @param y
		 * @param size
		 */
		private function drawBSPNode(node:BSPNode, container:Sprite, x:Number, y:Number, size:Number):void {
			var s:Shape = new Shape();
			container.addChild(s);
			s.x = x;
			s.y = y;
			var color:uint = 0xFF0000;
			var primitive:PolyPrimitive;
			if (node.primitive != null) {
				primitive = node.primitive;
			} else {
				if (node.frontPrimitives != null) {
					primitive = node.frontPrimitives.peek();
				}
			}
			if (primitive != null) {
				if (primitive.face._surface != null && primitive.face._surface._material != null) {
					if (primitive.face._surface._material is FillMaterial) { 
						color = FillMaterial(primitive.face._surface._material)._color;
					}
					if (primitive.face._surface._material is WireMaterial) { 
						color = WireMaterial(primitive.face._surface._material)._color;
					}
					if (primitive.face._surface._material is TextureMaterial) { 
						color = TextureMaterial(primitive.face._surface._material).texture._bitmapData.getPixel(0, 0);
					}
				}
			}

			if (node == dummyNode) {
				color = 0xFF00FF;
			}

			s.graphics.beginFill(color);
			s.graphics.drawCircle(0, 0, 3);
			s.graphics.endFill();

			var xOffset:Number = 100;
			var yOffset:Number = 20;
			if (node.back != null) {
				container.graphics.lineStyle(0, 0x660000);
				container.graphics.moveTo(x, y);
				container.graphics.lineTo(x - xOffset*size, y + yOffset);
				drawBSPNode(node.back, container, x - xOffset*size, y + yOffset, size*0.8);
			}
			if (node.front != null) {
				container.graphics.lineStyle(0, 0x006600);
				container.graphics.moveTo(x, y);
				container.graphics.lineTo(x + xOffset*size, y + yOffset);
				drawBSPNode(node.front, container, x + xOffset*size, y + yOffset, size*0.8);
			}
		}
		
	}
}