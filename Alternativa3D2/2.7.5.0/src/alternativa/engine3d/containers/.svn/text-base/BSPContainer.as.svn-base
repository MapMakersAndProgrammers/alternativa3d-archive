package alternativa.engine3d.containers {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	import alternativa.engine3d.core.VG;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	/**
	 * Контейнер, который помимо дочерних объектов содержит бинарную древовидную структуру — BSP-дерево.
	 * BSP-дерево строится с помощью вызова метода <code>createTree()</code> из полигонов переданной статической геометрии.
	 * BSP-дерево состоит из BSP-нод. Узловые ноды содержат полигоны. Листовые ноды содержат статические объекты.
	 * Статическим объектам в качестве <code>parent</code> назначается контейнер, то есть они в какой-то мере становятся дочерними, однако они не содержатся в списке дочерних объектов и их нельзя удалить.
	 * При отрисовке дочерние объекты контейнера отрисовываются с учётом KD-дерева, они как бы проваливаются в древовидную структуру.
	 * <code>BSPContainer</code> наследован от <code>ConflictContainer</code>, поэтому в конечных нодах дерева действуют алгоритмы сортировки разделением.
	 * Если дерево не построено, <code>BSPContainer</code> ведёт себя как <code>ConflictContainer</code>.
	 * @see ConflictContainer
	 * @see #createTree()
	 * @see #destroyTree()
	 */
	public class BSPContainer extends ConflictContainer	{
		
		/**
		 * Режим отсечения объекта по пирамиде видимости камеры.
		 * Можно использовать следующие константы <code>Clipping</code> для указания свойства <code>clipping</code>: <code>Clipping.BOUND_CULLING</code>, <code>Clipping.FACE_CULLING</code>, <code>Clipping.FACE_CLIPPING</code>.
		 * Значение по умолчанию <code>Clipping.FACE_CLIPPING</code>.
		 * @see Clipping
		 */
		public var clipping:int = 2;
		
		/**
		 * Параметр затухания изображения нод в режиме отладки.
		 * Значение по умолчанию — <code>0.8</code>.
		 * @see alternativa.engine3d.core.Debug
		 */
		public var debugAlphaFade:Number = 0.8;
		
		/**
		 * @private 
		 */
		alternativa3d var root:BSPNode;
		
		//private var vertexList:Vertex;
		
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
		
		// Направление камеры в контейнере
		private var directionX:Number;
		private var directionY:Number;
		private var directionZ:Number;
		private var viewAngle:Number;
		
		/**
		 * Строит BSP-дерево из полигонов переданной статической геометрии.
		 * Перед построением старое дерево разрушается.
		 * После построения статические объекты остаются в дереве.
		 * @param staticGeometry Экземпляры класса <code>Geometry</code>, из полигонов которых строится дерево.
		 * @param staticObjects Статические объекты.
		 * @param splitters Экземпляры класса <code>Geometry</code>, полигоны которых выступают в качестве сплиттеров. Они имеют приоритет перед статической геометрией. Эти полигоны не отображаются.
		 * @see Geometry
		 * @see #destroyTree()
		 */
		public function createTree(staticGeometry:Vector.<Geometry>, staticObjects:Vector.<Object3D> = null, splitters:Vector.<Geometry> = null):void {
			destroyTree();
			var i:int;
			var len:int;
			var splitterList:Face;
			var faceList:Face;
			var objectList:Object3D;
			var boundList:Object3D;
			// Обработка сплиттеров
			if (splitters != null) {
				len = splitters.length;
				for (i = len - 1; i >= 0; i--) {
					faceList = calculateFaceList(splitters[i], splitterList);
				}
			}
			// Обработка геометрии
			len = staticGeometry.length;
			for (i = len - 1; i >= 0; i--) {
				faceList = calculateFaceList(staticGeometry[i], faceList);
			}
			// Обработка объектов
			if (staticObjects != null) {
				len = staticObjects.length;
				for (i = 0; i < len; i++) {
					var object:Object3D = staticObjects[i];
					// TODO: не клонировать
					object = object.clone();
					object._parent = this;
					// Расчёт локального баунда
					calculateObjectBounds(object);
					// Расчёт баунда в координатах дерева
					var bound:Object3D = createObjectBounds(object);
					// Если объект не пустой
					if (bound.boundMinX <= bound.boundMaxX) {
						object.next = objectList;
						objectList = object;
						bound.next = boundList;
						boundList = bound;
					}
				}
			}
			// Если есть непустые объекты
			if (faceList != null || objectList != null || splitterList != null) {
				root = createNode(splitterList, faceList, objectList, boundList, new Vector.<Face>(3), new Vector.<Object3D>(4));
			}
		}
		
		/**
		 * Разрушает BSP-дерево.
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
				// Итератор трансформаций
				/*if (transformID > 500000000) {
					transformID = 0;
					for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) vertex.transformId = 0;
				}*/
				transformId++;
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
						if (debug & Debug.NODES) debugNode(root, rootCulling, camera, canvas, 1);
						if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, this, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
					}
					// Отрисовка
					canvas = parentCanvas.getChildCanvas(false, true, this, alpha, blendMode, colorTransform, filters);
					canvas.numDraws = 0;
					// Сбор видимой геометрии
					var geometry:VG = getVG(camera);
					for (var current:VG = geometry; current != null; current = current.next) {
						current.calculateAABB(ima, imb, imc, imd, ime, imf, img, imh, imi, imj, imk, iml);
					}
					// Отрисовка дерева
					var result:Face = drawNode(root, rootCulling, camera, canvas, geometry);
					if (result != null) {
						drawFaces(camera, canvas, result);
					}
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
		
		private function debugNode(node:BSPNode, culling:int, camera:Camera3D, canvas:Canvas, alpha:Number):void {
			if (node != null) {
				var negativeCulling:int = -1;
				var positiveCulling:int = -1;
				if (node.negative != null) negativeCulling = (culling > 0) ? cullingInContainer(culling, node.negative.boundMinX, node.negative.boundMinY, node.negative.boundMinZ, node.negative.boundMaxX, node.negative.boundMaxY, node.negative.boundMaxZ) : 0;
				if (node.positive != null) positiveCulling = (culling > 0) ? cullingInContainer(culling, node.positive.boundMinX, node.positive.boundMinY, node.positive.boundMinZ, node.positive.boundMaxX, node.positive.boundMaxY, node.positive.boundMaxZ) : 0;
				if (negativeCulling >= 0) {
					debugNode(node.negative, negativeCulling, camera, canvas, alpha*debugAlphaFade);
				}
				Debug.drawBounds(camera, canvas, this, node.boundMinX, node.boundMinY, node.boundMinZ, node.boundMaxX, node.boundMaxY, node.boundMaxZ, 0xDD33DD, alpha);
				if (positiveCulling >= 0) {
					debugNode(node.positive, positiveCulling, camera, canvas, alpha*debugAlphaFade);
				}
			}
		}
		
		private function drawNode(node:BSPNode, culling:int, camera:Camera3D, canvas:Canvas, geometry:VG, result:Face = null):Face {
			var next:VG;
			var negative:VG;
			var positive:VG;
			// Узловая нода
			if (node.objectList == null) {
				var checkBoundsResult:int;
				var negativeCulling:int = -1;
				var positiveCulling:int = -1;
				var normalX:Number = node.normalX;
				var normalY:Number = node.normalY;
				var normalZ:Number = node.normalZ;
				var offset:Number = node.offset;
				// Камера спереди
				if (imd*normalX + imh*normalY + iml*normalZ > offset) {
					// Если негативная часть попадает в конус
					if (directionX*normalX + directionY*normalY + directionZ*normalZ < viewAngle) {
						// Разделение динамиков
						while (geometry != null) {
							next = geometry.next;
							checkBoundsResult = checkBounds(normalX, normalY, normalZ, offset, geometry.boundMinX, geometry.boundMinY, geometry.boundMinZ, geometry.boundMaxX, geometry.boundMaxY, geometry.boundMaxZ);
							if (checkBoundsResult < 0) {
								geometry.next = negative;
								negative = geometry;
							} else if (checkBoundsResult > 0) {
								geometry.next = positive;
								positive = geometry;
							} else {
								geometry.split(camera, normalX, normalY, normalZ, offset, threshold);
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
							geometry = next;
						}
						// Отрисовка передней части
						if (node.positive != null) positiveCulling = (culling > 0) ? cullingInContainer(culling, node.positive.boundMinX, node.positive.boundMinY, node.positive.boundMinZ, node.positive.boundMaxX, node.positive.boundMaxY, node.positive.boundMaxZ) : 0;
						if (positiveCulling >= 0) {
							result = drawNode(node.positive, positiveCulling, camera, canvas, positive, result);
						} else if (positive != null) {
							if (result != null) {
								drawFaces(camera, canvas, result);
								result = null;
							}
							if (positive.next != null) {
								if (resolveByAABB) {
									drawAABBGeometry(camera, canvas, positive);
								} else if (resolveByOOBB) {
									for (geometry = positive; geometry != null; geometry = geometry.next) {
										geometry.calculateOOBB(this);
									}
									drawOOBBGeometry(camera, canvas, positive);
								} else {
									drawConflictGeometry(camera, canvas, positive);
								}
							} else {
								positive.draw(camera, canvas, threshold, this);
								positive.destroy();
							}
						}
						// Отрисовка граней ноды
						var list:Face;
						var face:Face;
						for (face = node.faceList; face != null; face = face.next) {
							for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
								var vertex:Vertex = wrapper.vertex;
								if (vertex.transformId != transformId) {
									var x:Number = vertex.x;
									var y:Number = vertex.y;
									var z:Number = vertex.z;
									vertex.cameraX = ma*x + mb*y + mc*z + md;
									vertex.cameraY = me*x + mf*y + mg*z + mh;
									vertex.cameraZ = mi*x + mj*y + mk*z + ml;
									vertex.transformId = transformId;
									vertex.drawId = 0;
								}
							}
							face.processNext = list;
							list = face;
						}
						if (list != null) {
							if (culling > 0) {
								if (clipping == 2) {
									list = camera.clip(list, culling);
								} else {
									list = camera.cull(list, culling);
								}
								if (list != null) {
									for (face = list; face.processNext != null; face = face.processNext);
									face.processNext = result;
									result = list;
								}
							} else {
								for (face = list; face.processNext != null; face = face.processNext);
								face.processNext = result;
								result = list;
							}
						}
						// Отрисовка задней части
						if (node.negative != null) negativeCulling = (culling > 0) ? cullingInContainer(culling, node.negative.boundMinX, node.negative.boundMinY, node.negative.boundMinZ, node.negative.boundMaxX, node.negative.boundMaxY, node.negative.boundMaxZ) : 0;
						if (negativeCulling >= 0) {
							result = drawNode(node.negative, negativeCulling, camera, canvas, negative, result);
						} else if (negative != null) {
							if (result != null) {
								drawFaces(camera, canvas, result);
								result = null;
							}
							if (negative.next != null) {
								if (resolveByAABB) {
									drawAABBGeometry(camera, canvas, negative);
								} else if (resolveByOOBB) {
									for (geometry = negative; geometry != null; geometry = geometry.next) {
										geometry.calculateOOBB(this);
									}
									drawOOBBGeometry(camera, canvas, negative);
								} else {
									drawConflictGeometry(camera, canvas, negative);
								}
							} else {
								negative.draw(camera, canvas, threshold, this);
								negative.destroy();
							}
						}
					// Если негативная часть не попадает в конус	
					} else {
						// Подрезка динамиков
						while (geometry != null) {
							next = geometry.next;
							checkBoundsResult = checkBounds(normalX, normalY, normalZ, offset, geometry.boundMinX, geometry.boundMinY, geometry.boundMinZ, geometry.boundMaxX, geometry.boundMaxY, geometry.boundMaxZ);
							if (checkBoundsResult < 0) {
								geometry.destroy();
							} else if (checkBoundsResult > 0) {
								geometry.next = positive;
								positive = geometry;
							} else {
								geometry.crop(camera, normalX, normalY, normalZ, offset, threshold);
								// Если позитивный не пустой
								if (geometry.faceStruct != null) {
									geometry.next = positive;
									positive = geometry;
								} else {
									geometry.destroy();
								}
							}
							geometry = next;
						}
						// Отрисовка передней части
						if (node.positive != null) positiveCulling = (culling > 0) ? cullingInContainer(culling, node.positive.boundMinX, node.positive.boundMinY, node.positive.boundMinZ, node.positive.boundMaxX, node.positive.boundMaxY, node.positive.boundMaxZ) : 0;
						if (positiveCulling >= 0) {
							result = drawNode(node.positive, positiveCulling, camera, canvas, positive, result);
						} else if (positive != null) {
							if (result != null) {
								drawFaces(camera, canvas, result);
								result = null;
							}
							if (positive.next != null) {
								if (resolveByAABB) {
									drawAABBGeometry(camera, canvas, positive);
								} else if (resolveByOOBB) {
									for (geometry = positive; geometry != null; geometry = geometry.next) {
										geometry.calculateOOBB(this);
									}
									drawOOBBGeometry(camera, canvas, positive);
								} else {
									drawConflictGeometry(camera, canvas, positive);
								}
							} else {
								positive.draw(camera, canvas, threshold, this);
								positive.destroy();
							}
						}
					}
				// Камера сзади
				} else {
					// Если позитивная часть попадает в конус
					if (directionX*normalX + directionY*normalY + directionZ*normalZ > -viewAngle) {
						// Разделение динамиков
						while (geometry != null) {
							next = geometry.next;
							checkBoundsResult = checkBounds(normalX, normalY, normalZ, offset, geometry.boundMinX, geometry.boundMinY, geometry.boundMinZ, geometry.boundMaxX, geometry.boundMaxY, geometry.boundMaxZ);
							if (checkBoundsResult < 0) {
								geometry.next = negative;
								negative = geometry;
							} else if (checkBoundsResult > 0) {
								geometry.next = positive;
								positive = geometry;
							} else {
								geometry.split(camera, normalX, normalY, normalZ, offset, threshold);
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
							geometry = next;
						}
						// Отрисовка задней части
						if (node.negative != null) negativeCulling = (culling > 0) ? cullingInContainer(culling, node.negative.boundMinX, node.negative.boundMinY, node.negative.boundMinZ, node.negative.boundMaxX, node.negative.boundMaxY, node.negative.boundMaxZ) : 0;
						if (negativeCulling >= 0) {
							result = drawNode(node.negative, negativeCulling, camera, canvas, negative, result);
						} else if (negative != null) {
							if (result != null) {
								drawFaces(camera, canvas, result);
								result = null;
							}
							if (negative.next != null) {
								if (resolveByAABB) {
									drawAABBGeometry(camera, canvas, negative);
								} else if (resolveByOOBB) {
									for (geometry = negative; geometry != null; geometry = geometry.next) {
										geometry.calculateOOBB(this);
									}
									drawOOBBGeometry(camera, canvas, negative);
								} else {
									drawConflictGeometry(camera, canvas, negative);
								}
							} else {
								negative.draw(camera, canvas, threshold, this);
								negative.destroy();
							}
						}
						// Отрисовка передней части
						if (node.positive != null) positiveCulling = (culling > 0) ? cullingInContainer(culling, node.positive.boundMinX, node.positive.boundMinY, node.positive.boundMinZ, node.positive.boundMaxX, node.positive.boundMaxY, node.positive.boundMaxZ) : 0;
						if (positiveCulling >= 0) {
							result = drawNode(node.positive, positiveCulling, camera, canvas, positive, result);
						} else if (positive != null) {
							if (result != null) {
								drawFaces(camera, canvas, result);
								result = null;
							}
							if (positive.next != null) {
								if (resolveByAABB) {
									drawAABBGeometry(camera, canvas, positive);
								} else if (resolveByOOBB) {
									for (geometry = positive; geometry != null; geometry = geometry.next) {
										geometry.calculateOOBB(this);
									}
									drawOOBBGeometry(camera, canvas, positive);
								} else {
									drawConflictGeometry(camera, canvas, positive);
								}
							} else {
								positive.draw(camera, canvas, threshold, this);
								positive.destroy();
							}
						}
					// Если позитивная часть не попадает в конус	
					} else {
						// Подрезка динамиков
						while (geometry != null) {
							next = geometry.next;
							checkBoundsResult = checkBounds(normalX, normalY, normalZ, offset, geometry.boundMinX, geometry.boundMinY, geometry.boundMinZ, geometry.boundMaxX, geometry.boundMaxY, geometry.boundMaxZ);
							if (checkBoundsResult < 0) {
								geometry.next = negative;
								negative = geometry;
							} else if (checkBoundsResult > 0) {
								geometry.destroy();
							} else {
								geometry.crop(camera, -normalX, -normalY, -normalZ, -offset, threshold);
								// Если позитивный не пустой
								if (geometry.faceStruct != null) {
									geometry.next = negative;
									negative = geometry;
								} else {
									geometry.destroy();
								}
							}
							geometry = next;
						}
						// Отрисовка задней части
						if (node.negative != null) negativeCulling = (culling > 0) ? cullingInContainer(culling, node.negative.boundMinX, node.negative.boundMinY, node.negative.boundMinZ, node.negative.boundMaxX, node.negative.boundMaxY, node.negative.boundMaxZ) : 0;
						if (negativeCulling >= 0) {
							result = drawNode(node.negative, negativeCulling, camera, canvas, negative, result);
						} else if (negative != null) {
							if (result != null) {
								drawFaces(camera, canvas, result);
								result = null;
							}
							if (negative.next != null) {
								if (resolveByAABB) {
									drawAABBGeometry(camera, canvas, negative);
								} else if (resolveByOOBB) {
									for (geometry = negative; geometry != null; geometry = geometry.next) {
										geometry.calculateOOBB(this);
									}
									drawOOBBGeometry(camera, canvas, negative);
								} else {
									drawConflictGeometry(camera, canvas, negative);
								}
							} else {
								negative.draw(camera, canvas, threshold, this);
								negative.destroy();
							}
						}
					}
				}
			// Конечная нода
			} else {
				if (result != null) {
					drawFaces(camera, canvas, result);
					result = null;
				}
				var child:Object3D;
				var bound:Object3D;
				// Если статиков несколько или есть геометрия
				if (node.objectList.next != null || geometry != null) {
					// Превращение статиков в геометрию
					for (child = node.objectList, bound = node.boundList; child != null; child = child.next, bound = bound.next) {
						if (child.visible && ((child.culling = culling) == 0 || (child.culling = cullingInContainer(culling, bound.boundMinX, bound.boundMinY, bound.boundMinZ, bound.boundMaxX, bound.boundMaxY, bound.boundMaxZ)) >= 0)) {
							child.composeAndAppend(this);
							var newGeometry:VG = child.getVG(camera);
							while (newGeometry != null) {
								next = newGeometry.next;
								newGeometry.next = geometry;
								geometry = newGeometry;
								if (resolveByAABB) {
									newGeometry.calculateAABB(ima, imb, imc, imd, ime, imf, img, imh, imi, imj, imk, iml);
								}
								newGeometry = next;
							}
						}
					}
					// Отрисовка
					if (geometry != null) {
						// Если динамических объектов несколько
						if (geometry.next != null) {
							// Разруливание
							drawConflictGeometry(camera, canvas, geometry);
						} else {
							geometry.draw(camera, canvas, threshold, this);
							geometry.destroy();
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
			}
			return result;
		}
		
		private function drawFaces(camera:Camera3D, parentCanvas:Canvas, list:Face):void {
			// Дебаг
			if (camera.debug && (camera.checkInDebug(this) & Debug.EDGES)) {
				Debug.drawEdges(camera, parentCanvas.getChildCanvas(true, false), list, 0xFFFFFF);
			}
			// Отрисовка
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, this);
			for (var face:Face = list; face != null; face = next) {
				var next:Face = face.processNext;
				// Если конец списка или смена материала
				if (next == null || next.material != list.material) {
					// Разрыв на стыке разных материалов
					face.processNext = null;
					// Если материал для части списка не пустой
					if (list.material != null) {
						// Отрисовка
						list.material.draw(camera, canvas, list, ml);
					} else {
						// Разрыв связей
						while (list != null) {
							face = list.processNext;
							list.processNext = null;
							list = face;
						}
					}
					list = next;
				}
			}
		}
		
		private function checkBounds(normalX:Number, normalY:Number, normalZ:Number, offset:Number, boundMinX:Number, boundMinY:Number, boundMinZ:Number, boundMaxX:Number, boundMaxY:Number, boundMaxZ:Number):int {
			if (normalX >= 0) if (normalY >= 0) if (normalZ >= 0) {
				if (boundMaxX*normalX + boundMaxY*normalY + boundMaxZ*normalZ <= offset + threshold) return -1;
				if (boundMinX*normalX + boundMinY*normalY + boundMinZ*normalZ >= offset - threshold) return 1;
			} else {
				if (boundMaxX*normalX + boundMaxY*normalY + boundMinZ*normalZ <= offset + threshold) return -1;
				if (boundMinX*normalX + boundMinY*normalY + boundMaxZ*normalZ >= offset - threshold) return 1;
			} else if (normalZ >= 0) {
				if (boundMaxX*normalX + boundMinY*normalY + boundMaxZ*normalZ <= offset + threshold) return -1;
				if (boundMinX*normalX + boundMaxY*normalY + boundMinZ*normalZ >= offset - threshold) return 1;
			} else {
				if (boundMaxX*normalX + boundMinY*normalY + boundMinZ*normalZ <= offset + threshold) return -1;
				if (boundMinX*normalX + boundMaxY*normalY + boundMaxZ*normalZ >= offset - threshold) return 1;
			} else if (normalY >= 0) if (normalZ >= 0) {
				if (boundMinX*normalX + boundMaxY*normalY + boundMaxZ*normalZ <= offset + threshold) return -1;
				if (boundMaxX*normalX + boundMinY*normalY + boundMinZ*normalZ >= offset - threshold) return 1;
			} else {
				if (boundMinX*normalX + boundMaxY*normalY + boundMinZ*normalZ <= offset + threshold) return -1;
				if (boundMaxX*normalX + boundMinY*normalY + boundMaxZ*normalZ >= offset - threshold) return 1;
			} else if (normalZ >= 0) {
				if (boundMinX*normalX + boundMinY*normalY + boundMaxZ*normalZ <= offset + threshold) return -1;
				if (boundMaxX*normalX + boundMaxY*normalY + boundMinZ*normalZ >= offset - threshold) return 1;
			} else {
				if (boundMinX*normalX + boundMinY*normalY + boundMinZ*normalZ <= offset + threshold) return -1;
				if (boundMaxX*normalX + boundMaxY*normalY + boundMaxZ*normalZ >= offset - threshold) return 1;
			}
			return 0;
		}
		
		private function calculateCameraPlanes(near:Number, far:Number):void {
			// Направление
			directionX = imc;
			directionY = img;
			directionZ = imk;
			var len:Number = 1/Math.sqrt(directionX*directionX + directionY*directionY + directionZ*directionZ);
			directionX *= len;
			directionY *= len;
			directionZ *= len;
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
			len = 1/Math.sqrt(ax*ax + ay*ay + az*az);
			ax *= len;
			ay *= len;
			az *= len;
			var va:Number = ax*directionX + ay*directionY + az*directionZ;
			viewAngle = va;
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
			len = 1/Math.sqrt(ax*ax + ay*ay + az*az);
			ax *= len;
			ay *= len;
			az *= len;
			va = ax*directionX + ay*directionY + az*directionZ;
			if (va < viewAngle) viewAngle = va;
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
			len = 1/Math.sqrt(ax*ax + ay*ay + az*az);
			ax *= len;
			ay *= len;
			az *= len;
			va = ax*directionX + ay*directionY + az*directionZ;
			if (va < viewAngle) viewAngle = va;
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
			len = 1/Math.sqrt(ax*ax + ay*ay + az*az);
			ax *= len;
			ay *= len;
			az *= len;
			va = ax*directionX + ay*directionY + az*directionZ;
			if (va < viewAngle) viewAngle = va;
			// Расчёт угла конуса
			viewAngle = Math.sin(Math.acos(viewAngle));
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
			return culling;
		}
		
		private function calculateFaceList(geometry:Geometry, result:Face = null):Face {
			var faceList:Face;
			var lastFace:Face;
			var i:int;
			var vertex:Vertex;
			var orderedVertices:Vector.<Vertex> = geometry.orderedVertices;
			var orderedVerticesLength:int = orderedVertices.length;
			var orderedFaces:Vector.<Face> = geometry.orderedFaces;
			var orderedFacesLength:int = orderedFaces.length;
			// Клонирование вершин
			var lastVertex:Vertex;
			for (i = 0; i < orderedVerticesLength; i++) {
				vertex = orderedVertices[i];
				var newVertex:Vertex = new Vertex();
				newVertex.x = vertex.x;
				newVertex.y = vertex.y;
				newVertex.z = vertex.z;
				newVertex.u = vertex.u;
				newVertex.v = vertex.v;
				vertex.value = newVertex;
				/*if (lastVertex != null) {
					lastVertex.next = newVertex;
				} else {
					vertexList = newVertex;
				}
				lastVertex = newVertex;*/
			}
			// Клонирование граней
			for (i = 0; i < orderedFacesLength; i++) {
				var face:Face = orderedFaces[i];
				var newFace:Face = new Face();
				newFace.material = face.material;
				// Клонирование обёрток
				var lastWrapper:Wrapper = null;
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var newWrapper:Wrapper = new Wrapper();
					newWrapper.vertex = wrapper.vertex.value;
					if (lastWrapper != null) {
						lastWrapper.next = newWrapper;
					} else {
						newFace.wrapper = newWrapper;
					}
					lastWrapper = newWrapper;
				}
				newFace.calculateBestSequenceAndNormal();
				if (lastFace != null) {
					lastFace.next = newFace;
				} else {
					faceList = newFace;
				}
				lastFace = newFace;
			}
			// Сброс после ремапа
			for (i = 0; i < orderedVerticesLength; i++) {
				vertex = orderedVertices[i];
				vertex.value = null;
			}
			lastFace.next = result;
			return faceList;
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
		
		private function calculateObjectBounds(object:Object3D):void {
			object.calculateBounds();
			if (object is Object3DContainer) {
				for (var child:Object3D = Object3DContainer(object).childrenList; child != null; child = child.next) {
					calculateObjectBounds(child);
				}
			}
		}
		
		private function createNode(splitterList:Face, faceList:Face, objectList:Object3D, boundList:Object3D, faceSplitResult:Vector.<Face>, objectSplitResult:Vector.<Object3D>, parentSplitter:Face = null):BSPNode {
			var node:BSPNode = new BSPNode();
			calculateNodeBounds(node, faceList, boundList);
			var splitter:Face;
			var negativeSplitterList:Face;
			var positiveSplitterList:Face;
			var negativeFaceList:Face;
			var positiveFaceList:Face;
			var negativeObjectList:Object3D;
			var positiveObjectList:Object3D;
			var negativeBoundList:Object3D;
			var positiveBoundList:Object3D;
			// Поиск сплиттера
			if (splitterList != null) {
				splitter = (splitterList.next != null) ? findSplitter(splitterList) : splitterList;
			} else {
				var face:Face;
				var boundFaceList:Face;
				if (objectList != null) {
					boundFaceList = createBoundFaces(boundList);
					for (face = parentSplitter; face != null; face = face.next) {
						boundFaceList = cropFaceList(boundFaceList, face.normalX, face.normalY, face.normalZ, face.offset);
						if (boundFaceList == null) break;
					}
				}
				if (boundFaceList != null) {
					for (face = boundFaceList; face.next != null; face = face.next);
					face.next = faceList;
					splitter = (boundFaceList.next != null) ? findSplitter(boundFaceList) : boundFaceList;
				} else if (faceList != null) {
					splitter = (faceList.next != null) ? findSplitter(faceList) : faceList;
				}
			}
			// Разделение
			if (splitter != null) {
				node.normalX = splitter.normalX;
				node.normalY = splitter.normalY;
				node.normalZ = splitter.normalZ;
				node.offset = splitter.offset;
				if (splitterList != null) {
					splitFaceList(splitter, splitterList, faceSplitResult);
					negativeSplitterList = faceSplitResult[0];
					positiveSplitterList = faceSplitResult[2];
				}
				if (faceList != null) {
					splitFaceList(splitter, faceList, faceSplitResult);
					negativeFaceList = faceSplitResult[0];
					node.faceList = faceSplitResult[1];
					positiveFaceList = faceSplitResult[2];
				}
				if (objectList != null) {
					splitObjectList(splitter, objectList, boundList, objectSplitResult);
					negativeObjectList = objectSplitResult[0];
					negativeBoundList = objectSplitResult[1];
					positiveObjectList = objectSplitResult[2];
					positiveBoundList = objectSplitResult[3];
				}
				// Создание дочерних нод
				var nodeSplitter:Face = new Face();
				nodeSplitter.next = parentSplitter;
				if (negativeFaceList != null || negativeObjectList != null) {
					nodeSplitter.normalX = -node.normalX;
					nodeSplitter.normalY = -node.normalY;
					nodeSplitter.normalZ = -node.normalZ;
					nodeSplitter.offset = -node.offset;
					node.negative = createNode(negativeSplitterList, negativeFaceList, negativeObjectList, negativeBoundList, faceSplitResult, objectSplitResult, nodeSplitter);
				}
				if (positiveFaceList != null || positiveObjectList != null) {
					nodeSplitter.normalX = node.normalX;
					nodeSplitter.normalY = node.normalY;
					nodeSplitter.normalZ = node.normalZ;
					nodeSplitter.offset = node.offset;
					node.positive = createNode(positiveSplitterList, positiveFaceList, positiveObjectList, positiveBoundList, faceSplitResult, objectSplitResult, nodeSplitter);
				}
			} else {
				node.objectList = objectList;
				node.boundList = boundList;
			}
			return node;
		}
		
		private function calculateNodeBounds(node:BSPNode, faceList:Face, boundList:Object3D):void {
			node.boundMinX = 1e+22;
			node.boundMinY = 1e+22;
			node.boundMinZ = 1e+22;
			node.boundMaxX = -1e+22;
			node.boundMaxY = -1e+22;
			node.boundMaxZ = -1e+22;
			for (var bound:Object3D = boundList; bound != null; bound = bound.next) {
				if (bound.boundMinX < node.boundMinX) node.boundMinX = bound.boundMinX;
				if (bound.boundMaxX > node.boundMaxX) node.boundMaxX = bound.boundMaxX;
				if (bound.boundMinY < node.boundMinY) node.boundMinY = bound.boundMinY;
				if (bound.boundMaxY > node.boundMaxY) node.boundMaxY = bound.boundMaxY;
				if (bound.boundMinZ < node.boundMinZ) node.boundMinZ = bound.boundMinZ;
				if (bound.boundMaxZ > node.boundMaxZ) node.boundMaxZ = bound.boundMaxZ;
			}
			for (var face:Face = faceList; face != null; face = face.next) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					if (vertex.x < node.boundMinX) node.boundMinX = vertex.x;
					if (vertex.x > node.boundMaxX) node.boundMaxX = vertex.x;
					if (vertex.y < node.boundMinY) node.boundMinY = vertex.y;
					if (vertex.y > node.boundMaxY) node.boundMaxY = vertex.y;
					if (vertex.z < node.boundMinZ) node.boundMinZ = vertex.z;
					if (vertex.z > node.boundMaxZ) node.boundMaxZ = vertex.z;
				}
			}
		}
		
		private function findSplitter(faceList:Face):Face {
			var splitter:Face;
			var bestSplits:int = 2147483647;
			for (var face:Face = faceList; face != null; face = face.next) {
				var normalX:Number = face.normalX;
				var normalY:Number = face.normalY;
				var normalZ:Number = face.normalZ;
				var offset:Number = face.offset;
				var offsetMin:Number = offset - threshold;
				var offsetMax:Number = offset + threshold;
				var splits:int = 0;
				for (var f:Face = faceList; f != null; f = f.next) {
					if (f != face) {
						var w:Wrapper = f.wrapper;
						var a:Vertex = w.vertex;
						w = w.next;
						var b:Vertex = w.vertex;
						w = w.next;
						var c:Vertex = w.vertex;
						var ao:Number = a.x*normalX + a.y*normalY + a.z*normalZ;
						var bo:Number = b.x*normalX + b.y*normalY + b.z*normalZ;
						var co:Number = c.x*normalX + c.y*normalY + c.z*normalZ;
						var behind:Boolean = ao < offsetMin || bo < offsetMin || co < offsetMin;
						var infront:Boolean = ao > offsetMax || bo > offsetMax || co > offsetMax;
						for (w = w.next; w != null; w = w.next) {
							var v:Vertex = w.vertex;
							var vo:Number = v.x*normalX + v.y*normalY + v.z*normalZ;
							if (vo < offsetMin) {
								behind = true;
								if (infront) break;
							} else if (vo > offsetMax) {
								infront = true;
								if (behind) break;
							}
						}
						if (infront && behind) {
							splits++;
							if (splits >= bestSplits) break;
						}
					}
				}
				if (splits < bestSplits) {
					splitter = face;
					bestSplits = splits;
					if (bestSplits == 0) break;
				}
			}
			return splitter;
		}
		
		private function createBoundFaces(boundList:Object3D):Face {
			var res:Face;
			for (var bound:Object3D = boundList; bound != null; bound = bound.next) {
				var a:Vertex = new Vertex();
				a.x = bound.boundMinX;
				a.y = bound.boundMinY;
				a.z = bound.boundMinZ;
				var b:Vertex = new Vertex();
				b.x = bound.boundMaxX;
				b.y = bound.boundMinY;
				b.z = bound.boundMinZ;
				var c:Vertex = new Vertex();
				c.x = bound.boundMinX;
				c.y = bound.boundMaxY;
				c.z = bound.boundMinZ;
				var d:Vertex = new Vertex();
				d.x = bound.boundMaxX;
				d.y = bound.boundMaxY;
				d.z = bound.boundMinZ;
				var e:Vertex = new Vertex();
				e.x = bound.boundMinX;
				e.y = bound.boundMinY;
				e.z = bound.boundMaxZ;
				var f:Vertex = new Vertex();
				f.x = bound.boundMaxX;
				f.y = bound.boundMinY;
				f.z = bound.boundMaxZ;
				var g:Vertex = new Vertex();
				g.x = bound.boundMinX;
				g.y = bound.boundMaxY;
				g.z = bound.boundMaxZ;
				var h:Vertex = new Vertex();
				h.x = bound.boundMaxX;
				h.y = bound.boundMaxY;
				h.z = bound.boundMaxZ;
				
				var face:Face = new Face();
				face.normalX = -1;
				face.normalY = 0;
				face.normalZ = 0;
				face.offset = -bound.boundMinX;
				face.wrapper = new Wrapper();
				face.wrapper.vertex = a;
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = e;
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = g;
				face.wrapper.next.next.next = new Wrapper();
				face.wrapper.next.next.next.vertex = c;
				face.next = res;
				res = face;
				
				face = new Face();
				face.normalX = 1;
				face.normalY = 0;
				face.normalZ = 0;
				face.offset = bound.boundMaxX;
				face.wrapper = new Wrapper();
				face.wrapper.vertex = b;
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = d;
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = h;
				face.wrapper.next.next.next = new Wrapper();
				face.wrapper.next.next.next.vertex = f;
				face.next = res;
				res = face;
				
				face = new Face();
				face.normalX = 0;
				face.normalY = -1;
				face.normalZ = 0;
				face.offset = -bound.boundMinY;
				face.wrapper = new Wrapper();
				face.wrapper.vertex = a;
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = b;
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = f;
				face.wrapper.next.next.next = new Wrapper();
				face.wrapper.next.next.next.vertex = e;
				face.next = res;
				res = face;
				
				face = new Face();
				face.normalX = 0;
				face.normalY = 1;
				face.normalZ = 0;
				face.offset = bound.boundMaxY;
				face.wrapper = new Wrapper();
				face.wrapper.vertex = c;
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = g;
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = h;
				face.wrapper.next.next.next = new Wrapper();
				face.wrapper.next.next.next.vertex = d;
				face.next = res;
				res = face;
				
				face = new Face();
				face.normalX = 0;
				face.normalY = 0;
				face.normalZ = -1;
				face.offset = -bound.boundMinZ;
				face.wrapper = new Wrapper();
				face.wrapper.vertex = a;
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = c;
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = d;
				face.wrapper.next.next.next = new Wrapper();
				face.wrapper.next.next.next.vertex = b;
				face.next = res;
				res = face;
				
				face = new Face();
				face.normalX = 0;
				face.normalY = 0;
				face.normalZ = 1;
				face.offset = bound.boundMaxZ;
				face.wrapper = new Wrapper();
				face.wrapper.vertex = e;
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = f;
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = h;
				face.wrapper.next.next.next = new Wrapper();
				face.wrapper.next.next.next.vertex = g;
				face.next = res;
				res = face;
			}
			return res;
		}
		
		private function cropFaceList(faceList:Face, normalX:Number, normalY:Number, normalZ:Number, offset:Number):Face {
			var res:Face;
			var offsetMin:Number = offset - threshold;
			var offsetMax:Number = offset + threshold;
			for (var face:Face = faceList; face != null; face = next) {
				var next:Face = face.next;
				face.next = null;
				var v:Vertex;
				var w:Wrapper = face.wrapper;
				var a:Vertex = w.vertex;
				w = w.next;
				var b:Vertex = w.vertex;
				w = w.next;
				var c:Vertex = w.vertex;
				w = w.next;
				var ao:Number = a.x*normalX + a.y*normalY + a.z*normalZ;
				var bo:Number = b.x*normalX + b.y*normalY + b.z*normalZ;
				var co:Number = c.x*normalX + c.y*normalY + c.z*normalZ;
				var behind:Boolean = ao < offsetMin || bo < offsetMin || co < offsetMin;
				var infront:Boolean = ao > offsetMax || bo > offsetMax || co > offsetMax;
				for (; w != null; w = w.next) {
					v = w.vertex;
					var vo:Number = v.x*normalX + v.y*normalY + v.z*normalZ;
					if (vo < offsetMin) {
						behind = true;
					} else if (vo > offsetMax) {
						infront = true;
					}
					v.offset = vo;
				}
				if (infront) {
					if (!behind) {
						face.next = res;
						res = face;
					} else {
						a.offset = ao;
						b.offset = bo;
						c.offset = co;
						var wLast:Wrapper = null;
						var wNew:Wrapper;
						w = face.wrapper.next.next;
						while (w.next != null) w = w.next;
						a = w.vertex;
						ao = a.offset;
						for (w = face.wrapper, face.wrapper = null; w != null; w = w.next) {
							b = w.vertex;
							bo = b.offset;
							if (ao < offsetMin && bo > offsetMax || ao > offsetMax && bo < offsetMin) {
								var t:Number = (offset - ao)/(bo - ao);
								v = new Vertex();
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								wNew = w.create();
								wNew.vertex = v;
								if (wLast != null) {
									wLast.next = wNew;
								} else {
									face.wrapper = wNew;
								}
								wLast = wNew;
							}
							if (bo >= offsetMin) {
								wNew = w.create();
								wNew.vertex = b;
								if (wLast != null) {
									wLast.next = wNew;
								} else {
									face.wrapper = wNew;
								}
								wLast = wNew;
							}
							a = b;
							ao = bo;
						}
						face.next = res;
						res = face;
					}
				}
			}
			return res;
		}
		
		private function splitFaceList(splitter:Face, faceList:Face, faceSplitResult:Vector.<Face>):void {
			var normalX:Number = splitter.normalX;
			var normalY:Number = splitter.normalY;
			var normalZ:Number = splitter.normalZ;
			var offset:Number = splitter.offset;
			var offsetMin:Number = offset - threshold;
			var offsetMax:Number = offset + threshold;
			var negativeFirst:Face;
			var negativeLast:Face;
			var splitterFirst:Face;
			var splitterLast:Face;
			var positiveFirst:Face;
			var positiveLast:Face;
			while (faceList != null) {
				var next:Face = faceList.next;
				faceList.next = null;
				if (faceList == splitter) {
					if (splitterFirst != null) {
						splitterLast.next = faceList;
					} else {
						splitterFirst = faceList;
					}
					splitterLast = faceList;
					faceList = next;
					continue;
				}
				var w:Wrapper = faceList.wrapper;
				var a:Vertex = w.vertex;
				w = w.next;
				var b:Vertex = w.vertex;
				w = w.next;
				var c:Vertex = w.vertex;
				var ao:Number = a.x*normalX + a.y*normalY + a.z*normalZ;
				var bo:Number = b.x*normalX + b.y*normalY + b.z*normalZ;
				var co:Number = c.x*normalX + c.y*normalY + c.z*normalZ;
				var behind:Boolean = ao < offsetMin || bo < offsetMin || co < offsetMin;
				var infront:Boolean = ao > offsetMax || bo > offsetMax || co > offsetMax;
				for (w = w.next; w != null; w = w.next) {
					var v:Vertex = w.vertex;
					var vo:Number = v.x*normalX + v.y*normalY + v.z*normalZ;
					if (vo < offsetMin) {
						behind = true;
					} else if (vo > offsetMax) {
						infront = true;
					}
					v.offset = vo;
				}
				if (!behind) {
					if (!infront) {
						if (faceList.normalX*normalX + faceList.normalY*normalY + faceList.normalZ*normalZ > 0) {
							if (splitterFirst != null) {
								splitterLast.next = faceList;
							} else {
								splitterFirst = faceList;
							}
							splitterLast = faceList;
						} else {
							if (negativeFirst != null) {
								negativeLast.next = faceList;
							} else {
								negativeFirst = faceList;
							}
							negativeLast = faceList;
						}
					} else {
						if (positiveFirst != null) {
							positiveLast.next = faceList;
						} else {
							positiveFirst = faceList;
						}
						positiveLast = faceList;
					}
				} else if (!infront) {
					if (negativeFirst != null) {
						negativeLast.next = faceList;
					} else {
						negativeFirst = faceList;
					}
					negativeLast = faceList;
				} else {
					a.offset = ao;
					b.offset = bo;
					c.offset = co;
					var negative:Face = new Face();
					var positive:Face = new Face();
					var wNegative:Wrapper = null;
					var wPositive:Wrapper = null;
					var wNew:Wrapper;
					w = faceList.wrapper.next.next;
					while (w.next != null) {
						w = w.next;
					}
					a = w.vertex;
					ao = a.offset;
					for (w = faceList.wrapper; w != null; w = w.next) {
						b = w.vertex;
						bo = b.offset;
						if (ao < offsetMin && bo > offsetMax || ao > offsetMax && bo < offsetMin) {
							var t:Number = (offset - ao)/(bo - ao);
							v = new Vertex();
							//v.next = vertexList;
							//vertexList = v;
							v.x = a.x + (b.x - a.x)*t;
							v.y = a.y + (b.y - a.y)*t;
							v.z = a.z + (b.z - a.z)*t;
							v.u = a.u + (b.u - a.u)*t;
							v.v = a.v + (b.v - a.v)*t;
							wNew = new Wrapper();
							wNew.vertex = v;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
							wNew = new Wrapper();
							wNew.vertex = v;
							if (wPositive != null) {
								wPositive.next = wNew;
							} else {
								positive.wrapper = wNew;
							}
							wPositive = wNew;
						}
						if (bo <= offsetMax) {
							wNew = new Wrapper();
							wNew.vertex = b;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
						}
						if (bo >= offsetMin) {
							wNew = new Wrapper();
							wNew.vertex = b;
							if (wPositive != null) {
								wPositive.next = wNew;
							} else {
								positive.wrapper = wNew;
							}
							wPositive = wNew;
						}
						a = b;
						ao = bo;
					}
					negative.material = faceList.material;
					negative.calculateBestSequenceAndNormal();
					if (negativeFirst != null) {
						negativeLast.next = negative;
					} else {
						negativeFirst = negative;
					}
					negativeLast = negative;
					positive.material = faceList.material;
					positive.calculateBestSequenceAndNormal();
					if (positiveFirst != null) {
						positiveLast.next = positive;
					} else {
						positiveFirst = positive;
					}
					positiveLast = positive;
				}
				faceList = next;
			}
			faceSplitResult[0] = negativeFirst;
			faceSplitResult[1] = splitterFirst;
			faceSplitResult[2] = positiveFirst;
		}
		
		private function splitObjectList(splitter:Face, objectList:Object3D, boundList:Object3D, objectSplitResult:Vector.<Object3D>):void {
			var negativeObjectList:Object3D;
			var negativeBoundList:Object3D;
			var positiveObjectList:Object3D;
			var positiveBoundList:Object3D;
			var object:Object3D;
			var bound:Object3D;
			for (object = objectList, bound = boundList; object != null; object = nextObject, bound = nextBound) {
				var nextObject:Object3D = object.next;
				var nextBound:Object3D = bound.next;
				object.next = null;
				bound.next = null;
				var checkBoundsResult:int = checkBounds(splitter.normalX, splitter.normalY, splitter.normalZ, splitter.offset, bound.boundMinX, bound.boundMinY, bound.boundMinZ, bound.boundMaxX, bound.boundMaxY, bound.boundMaxZ);
				if (checkBoundsResult < 0) {
					object.next = negativeObjectList;
					negativeObjectList = object;
					bound.next = negativeBoundList;
					negativeBoundList = bound;
				} else if (checkBoundsResult > 0) {
					object.next = positiveObjectList;
					positiveObjectList = object;
					bound.next = positiveBoundList;
					positiveBoundList = bound;
				} else {
					object.composeMatrix();
					object.calculateInverseMatrix();
					var vertex:Vertex = splitter.wrapper.vertex;
					var a:Vector3D = new Vector3D(object.ima*vertex.x + object.imb*vertex.y + object.imc*vertex.z + object.imd, object.ime*vertex.x + object.imf*vertex.y + object.img*vertex.z + object.imh, object.imi*vertex.x + object.imj*vertex.y + object.imk*vertex.z + object.iml);
					vertex = splitter.wrapper.next.vertex;
					var b:Vector3D = new Vector3D(object.ima*vertex.x + object.imb*vertex.y + object.imc*vertex.z + object.imd, object.ime*vertex.x + object.imf*vertex.y + object.img*vertex.z + object.imh, object.imi*vertex.x + object.imj*vertex.y + object.imk*vertex.z + object.iml);
					vertex = splitter.wrapper.next.next.vertex;
					var c:Vector3D = new Vector3D(object.ima*vertex.x + object.imb*vertex.y + object.imc*vertex.z + object.imd, object.ime*vertex.x + object.imf*vertex.y + object.img*vertex.z + object.imh, object.imi*vertex.x + object.imj*vertex.y + object.imk*vertex.z + object.iml);
					var testSplitResult:int = object.testSplit(a, b, c, threshold);
					if (testSplitResult < 0) {
						object.next = negativeObjectList;
						negativeObjectList = object;
						bound.next = negativeBoundList;
						negativeBoundList = bound;
					} else if (testSplitResult > 0) {
						object.next = positiveObjectList;
						positiveObjectList = object;
						bound.next = positiveBoundList;
						positiveBoundList = bound;
					} else {
						var splitResult:Vector.<Object3D> = object.split(a, b, c, threshold);
						if (splitResult[0] != null) {
							object = splitResult[0];
							object._parent = this;
							object.next = negativeObjectList;
							negativeObjectList = object;
							bound = createObjectBounds(object);
							bound.next = negativeBoundList;
							negativeBoundList = bound;
						}
						if (splitResult[1] != null) {
							object = splitResult[1];
							object._parent = this;
							object.next = positiveObjectList;
							positiveObjectList = object;
							bound = createObjectBounds(object);
							bound.next = positiveBoundList;
							positiveBoundList = bound;
						}
					}
				}
			}
			objectSplitResult[0] = negativeObjectList;
			objectSplitResult[1] = negativeBoundList;
			objectSplitResult[2] = positiveObjectList;
			objectSplitResult[3] = positiveBoundList;
		}
		
		private function destroyNode(node:BSPNode):void {
			if (node.negative != null) {
				destroyNode(node.negative);
				node.negative = null;
			}
			if (node.positive != null) {
				destroyNode(node.positive);
				node.positive = null;
			}
			for (var face:Face = node.faceList; face != null; face = nextFace) {
				var nextFace:Face = face.next;
				face.next = null;
			}
			var object:Object3D;
			var nextObject:Object3D;
			for (object = node.objectList; object != null; object = nextObject) {
				nextObject = object.next;
				object._parent = null;
				object.next = null;
			}
			for (object = node.boundList; object != null; object = nextObject) {
				nextObject = object.next;
				object.next = null;
			}
			node.faceList = null;
			node.objectList = null;
			node.boundList = null;
		}
		
	}
}

import alternativa.engine3d.core.Face;
import alternativa.engine3d.core.Object3D;

class BSPNode {
		
	public var faceList:Face;
	
	public var negative:BSPNode;
	public var positive:BSPNode;
	
	public var normalX:Number;
	public var normalY:Number;
	public var normalZ:Number;
	public var offset:Number;
	
	public var boundMinX:Number;
	public var boundMinY:Number;
	public var boundMinZ:Number;
	public var boundMaxX:Number;
	public var boundMaxY:Number;
	public var boundMaxZ:Number;
	
	public var objectList:Object3D;
	public var boundList:Object3D;
	
}
