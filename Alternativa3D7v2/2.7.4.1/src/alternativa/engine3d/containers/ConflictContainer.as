package alternativa.engine3d.containers {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	
	use namespace alternativa3d;
	
	public class ConflictContainer extends Object3DContainer {
	
		public var resolveByAABB:Boolean = true;
		public var resolveByOOBB:Boolean = true;
	
		//public var isolateAABBConflicts:Boolean = false;
		//public var isolateOOBBConflicts:Boolean = false;
	
		public var threshold:Number = 0.1;
	
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var canvas:Canvas;
			var debug:int;
			// Сбор видимой геометрии
			var geometry:Geometry = getGeometry(camera, object);
			// Если есть видимая геометрия
			if (geometry != null) {
				// Дебаг
				if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
					canvas = parentCanvas.getChildCanvas(object, true, false);
					if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
				}
				// Отрисовка
				canvas = parentCanvas.getChildCanvas(object, false, true, object.alpha, object.blendMode, object.colorTransform, object.filters);
				canvas.numDraws = 0;
				// Если объектов несколько
				if (geometry.next != null) {
					var current:Geometry;
					// Расчёт инверсной матрицы камеры и позиции камеры в контейнере
					calculateInverseMatrix(object);
					// AABB
					if (resolveByAABB) {
						for (current = geometry; current != null; current = current.next) {
							current.calculateAABB(ima, imb, imc, imd, ime, imf, img, imh, imi, imj, imk, iml);
						}
						drawAABBGeometry(camera, object, canvas, geometry);
						// OOBB
					} else if (resolveByOOBB) {
						for (current = geometry; current != null; current = current.next) {
							current.calculateOOBB();
						}
						drawOOBBGeometry(camera, object, canvas, geometry);
						// Конфликт
					} else {
						drawConflictGeometry(camera, object, canvas, geometry);
					}
				} else {
					geometry.draw(camera, object, canvas, threshold);
					geometry.destroy();
				}
				// Если была отрисовка
				if (canvas.numDraws > 0) {
					canvas.removeChildren(canvas.numDraws);
				} else {
					parentCanvas.numDraws--;
				}
			}
		}
	
		protected function drawAABBGeometry(camera:Camera3D, object:Object3D, canvas:Canvas, geometry:Geometry):void {
			var coord:Number;
			var coordMin:Number;
			var coordMax:Number;
			var axisX:Boolean;
			var axisY:Boolean;
			var current:Geometry = geometry;
			var compared:Geometry;
			// Поиск сплита
			while (current != null) {
				// Сплиты по оси X
				coord = current.boundMinX;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				var outside:Boolean = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.boundMaxX <= coordMax) {
							outside = true;
						} else if (compared.boundMinX < coordMin) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = true;
					axisY = false;
					break;
				}
				coord = current.boundMaxX;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.boundMinX >= coordMin) {
							outside = true;
						} else if (compared.boundMaxX > coordMax) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = true;
					axisY = false;
					break;
				}
				// Сплиты по оси Y
				coord = current.boundMinY;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.boundMaxY <= coordMax) {
							outside = true;
						} else if (compared.boundMinY < coordMin) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = false;
					axisY = true;
					break;
				}
				coord = current.boundMaxY;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.boundMinY >= coordMin) {
							outside = true;
						} else if (compared.boundMaxY > coordMax) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = false;
					axisY = true;
					break;
				}
				// Сплиты по оси Z
				coord = current.boundMinZ;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.boundMaxZ <= coordMax) {
							outside = true;
						} else if (compared.boundMinZ < coordMin) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = false;
					axisY = false;
					break;
				}
				coord = current.boundMaxZ;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.boundMinZ >= coordMin) {
							outside = true;
						} else if (compared.boundMaxZ > coordMax) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = false;
					axisY = false;
					break;
				}
				current = current.next;
			}
			// Если найден сплит
			if (current != null) {
				var next:Geometry;
				var negative:Geometry;
				var middle:Geometry;
				var positive:Geometry;
				while (geometry != null) {
					next = geometry.next;
					var min:Number = axisX ? geometry.boundMinX : (axisY ? geometry.boundMinY : geometry.boundMinZ);
					var max:Number = axisX ? geometry.boundMaxX : (axisY ? geometry.boundMaxY : geometry.boundMaxZ);
					if (max > coordMax) {
						geometry.next = positive;
						positive = geometry;
					} else if (min < coordMin) {
						geometry.next = negative;
						negative = geometry;
					} else {
						geometry.next = middle;
						middle = geometry;
					}
					geometry = next;
				}
				// Определение положения камеры
				if (axisX && imd > coord || axisY && imh > coord || !axisX && !axisY && iml > coord) {
					// Отрисовка объектов спереди
					if (positive != null) {
						if (positive.next != null) {
							drawAABBGeometry(camera, object, canvas, positive);
						} else {
							positive.draw(camera, object, canvas, threshold);
							positive.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					while (middle != null) {
						next = middle.next;
						middle.draw(camera, object, canvas, threshold);
						middle.destroy();
						middle = next;
					}
					// Отрисовка объектов сзади
					if (negative != null) {
						if (negative.next != null) {
							drawAABBGeometry(camera, object, canvas, negative);
						} else {
							negative.draw(camera, object, canvas, threshold);
							negative.destroy();
						}
					}
				} else {
					// Отрисовка объектов сзади
					if (negative != null) {
						if (negative.next != null) {
							drawAABBGeometry(camera, object, canvas, negative);
						} else {
							negative.draw(camera, object, canvas, threshold);
							negative.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					while (middle != null) {
						next = middle.next;
						middle.draw(camera, object, canvas, threshold);
						middle.destroy();
						middle = next;
					}
					// Отрисовка объектов спереди
					if (positive != null) {
						if (positive.next != null) {
							drawAABBGeometry(camera, object, canvas, positive);
						} else {
							positive.draw(camera, object, canvas, threshold);
							positive.destroy();
						}
					}
				}
				// Если не найден сплит
			} else if (resolveByOOBB) {
				for (current = geometry; current != null; current = current.next) {
					current.calculateOOBB();
				}
				drawOOBBGeometry(camera, object, canvas, geometry);
				// Конфликт
			} else {
				drawConflictGeometry(camera, object, canvas, geometry);
			}
		}
	
		protected function drawOOBBGeometry(camera:Camera3D, object:Object3D, canvas:Canvas, geometry:Geometry):void {
			var vertex:Vertex;
			var plane:Vertex;
			var wrapper:Wrapper;
			var o:Number;
			var planeX:Number;
			var planeY:Number;
			var planeZ:Number;
			var planeOffset:Number;
			var behind:Boolean;
			var infront:Boolean;
			var current:Geometry;
			var compared:Geometry;
			// Поиск сплита
			for (current = geometry; current != null; current = current.next) {
				if (current.viewAligned) {
					planeOffset = current.ml;
					for (compared = geometry; compared != null; compared = compared.next) {
						if (!compared.viewAligned) {
							behind = false;
							infront = false;
							// Перебор точек
							for (vertex = compared.boundVertexList; vertex != null; vertex = vertex.next) {
								if (vertex.cameraZ > planeOffset) {
									if (behind) {
										break;
									} else {
										infront = true;
									}
								} else if (infront) {
									break;
								} else {
									behind = true;
								}
							}
							// Если встретилось препятствие
							if (vertex != null) break;
						}
					}
					// Если не встретилось препятствий
					if (compared == null) break;
				} else {
					// Перебор плоскостей
					for (plane = current.boundPlaneList; plane != null; plane = plane.next) {
						planeX = plane.cameraX;
						planeY = plane.cameraY;
						planeZ = plane.cameraZ;
						planeOffset = plane.offset;
						var outside:Boolean = false;
						for (compared = geometry; compared != null; compared = compared.next) {
							if (current != compared) {
								behind = false;
								infront = false;
								// Перебор точек
								if (compared.viewAligned) {
									for (wrapper = compared.faceStruct.wrapper; wrapper != null; wrapper = wrapper.next) {
										vertex = wrapper.vertex;
										if (vertex.cameraX*planeX + vertex.cameraY*planeY + vertex.cameraZ*planeZ >= planeOffset - threshold) {
											if (behind) {
												break;
											} else {
												outside = true;
												infront = true;
											}
										} else if (infront) {
											break;
										} else {
											behind = true;
										}
									}
									if (wrapper != null) break;
								} else {
									for (vertex = compared.boundVertexList; vertex != null; vertex = vertex.next) {
										if (vertex.cameraX*planeX + vertex.cameraY*planeY + vertex.cameraZ*planeZ >= planeOffset - threshold) {
											if (behind) {
												break;
											} else {
												outside = true;
												infront = true;
											}
										} else if (infront) {
											break;
										} else {
											behind = true;
										}
									}
									if (vertex != null) break;
								}
							}
						}
						// Если не встретилось препятствий и есть объекты по обе стороны
						if (compared == null && outside) break;
					}
					// Если найдена разделяющая плоскость
					if (plane != null) break;
				}
			}
			// Если найден сплит
			if (current != null) {
				var next:Geometry;
				var negative:Geometry;
				var middle:Geometry;
				var positive:Geometry;
				if (current.viewAligned) {
					while (geometry != null) {
						next = geometry.next;
						if (geometry.viewAligned) {
							o = geometry.ml - planeOffset;
							if (o < -threshold) {
								geometry.next = positive;
								positive = geometry;
							} else if (o > threshold) {
								geometry.next = negative;
								negative = geometry;
							} else {
								geometry.next = middle;
								middle = geometry;
							}
						} else {
							for (vertex = geometry.boundVertexList; vertex != null; vertex = vertex.next) {
								o = vertex.cameraZ - planeOffset;
								if (o < -threshold) {
									geometry.next = positive;
									positive = geometry;
									break;
								} else if (o > threshold) {
									geometry.next = negative;
									negative = geometry;
									break;
								}
							}
							if (vertex == null) {
								geometry.next = middle;
								middle = geometry;
							}
						}
						geometry = next;
					}
				} else {
					while (geometry != null) {
						next = geometry.next;
						if (geometry.viewAligned) {
							for (wrapper = geometry.faceStruct.wrapper; wrapper != null; wrapper = wrapper.next) {
								vertex = wrapper.vertex;
								o = vertex.cameraX*planeX + vertex.cameraY*planeY + vertex.cameraZ*planeZ - planeOffset;
								if (o < -threshold) {
									geometry.next = negative;
									negative = geometry;
									break;
								} else if (o > threshold) {
									geometry.next = positive;
									positive = geometry;
									break;
								}
							}
							if (wrapper == null) {
								geometry.next = middle;
								middle = geometry;
							}
						} else {
							for (vertex = geometry.boundVertexList; vertex != null; vertex = vertex.next) {
								o = vertex.cameraX*planeX + vertex.cameraY*planeY + vertex.cameraZ*planeZ - planeOffset;
								if (o < -threshold) {
									geometry.next = negative;
									negative = geometry;
									break;
								} else if (o > threshold) {
									geometry.next = positive;
									positive = geometry;
									break;
								}
							}
							if (vertex == null) {
								geometry.next = middle;
								middle = geometry;
							}
						}
						geometry = next;
					}
				}
				// Определение положения камеры
				if (current.viewAligned || planeOffset < 0) {
					// Отрисовка объектов спереди
					if (positive != null) {
						if (positive.next != null) {
							drawOOBBGeometry(camera, object, canvas, positive);
						} else {
							positive.draw(camera, object, canvas, threshold);
							positive.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					while (middle != null) {
						next = middle.next;
						middle.draw(camera, object, canvas, threshold);
						middle.destroy();
						middle = next;
					}
					// Отрисовка объектов сзади
					if (negative != null) {
						if (negative.next != null) {
							drawOOBBGeometry(camera, object, canvas, negative);
						} else {
							negative.draw(camera, object, canvas, threshold);
							negative.destroy();
						}
					}
				} else {
					// Отрисовка объектов сзади
					if (negative != null) {
						if (negative.next != null) {
							drawOOBBGeometry(camera, object, canvas, negative);
						} else {
							negative.draw(camera, object, canvas, threshold);
							negative.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					while (middle != null) {
						next = middle.next;
						middle.draw(camera, object, canvas, threshold);
						middle.destroy();
						middle = next;
					}
					// Отрисовка объектов спереди
					if (positive != null) {
						if (positive.next != null) {
							drawOOBBGeometry(camera, object, canvas, positive);
						} else {
							positive.draw(camera, object, canvas, threshold);
							positive.destroy();
						}
					}
				}
				// Если не найден сплит	
			} else {
				drawConflictGeometry(camera, object, canvas, geometry);
			}
		}
	
		protected function drawConflictGeometry(camera:Camera3D, object:Object3D, parentCanvas:Canvas, geometry:Geometry):void {
			var canvas:Canvas;
			var face:Face;
			var next:Face;
			var nextGeometry:Geometry;
			// Геометрия с сортировкой предрасчитанное BSP
			var bspGeometry:Geometry;
			// Геометрия, которая присутствует в конфликте
			var conflict:Geometry;
			// Грани с сортировкой динамическое BSP
			var dynamicBSPFirst:Face;
			var dynamicBSPLast:Face;
			// Грани с сортировкой по средним Z
			var averageZFirst:Face;
			var averageZLast:Face;
			// Перебор геометрических объектов
			for (; geometry != null; geometry = nextGeometry) {
				nextGeometry = geometry.next;
				// Сортировка по предрасчитанному BSP
				if (geometry.sorting == 3) {
					geometry.next = bspGeometry;
					bspGeometry = geometry;
				} else {
					// Сортировка по динамическому BSP
					if (geometry.sorting == 2) {
						if (dynamicBSPFirst != null) {
							dynamicBSPLast.processNext = geometry.faceStruct;
						} else {
							dynamicBSPFirst = geometry.faceStruct;
						}
						dynamicBSPLast = geometry.faceStruct;
						dynamicBSPLast.geometry = geometry;
						while (dynamicBSPLast.processNext != null) {
							dynamicBSPLast = dynamicBSPLast.processNext;
							dynamicBSPLast.geometry = geometry;
						}
						// Сортировка по средним Z
					} else {
						if (averageZFirst != null) {
							averageZLast.processNext = geometry.faceStruct;
						} else {
							averageZFirst = geometry.faceStruct;
						}
						averageZLast = geometry.faceStruct;
						averageZLast.geometry = geometry;
						while (averageZLast.processNext != null) {
							averageZLast = averageZLast.processNext;
							averageZLast.geometry = geometry;
						}
					}
					geometry.faceStruct = null;
					geometry.next = conflict;
					conflict = geometry;
				}
			}
			// Соединение списков
			if (conflict != null) {
				geometry = conflict;
				while (geometry.next != null) {
					geometry = geometry.next;
				}
				geometry.next = bspGeometry;
			} else {
				conflict = bspGeometry;
			}
			// Сбор первоначальной кучи граней
			var list:Face;
			if (dynamicBSPFirst != null) {
				list = dynamicBSPFirst;
				dynamicBSPLast.processNext = averageZFirst;
			} else {
				list = averageZFirst;
			}
			// Если есть статические BSP
			if (bspGeometry != null) {
				// Встройка кучи в первый bsp с внутренней сортировкой
				bspGeometry.faceStruct.geometry = bspGeometry;
				list = collectNode(bspGeometry.faceStruct, list, camera, threshold, true);
				bspGeometry.faceStruct = null;
				// Встройка кучи в остальные bsp без внутренней сортировки
				for (bspGeometry = bspGeometry.next; bspGeometry != null; bspGeometry = bspGeometry.next) {
					bspGeometry.faceStruct.geometry = bspGeometry;
					list = collectNode(bspGeometry.faceStruct, list, camera, threshold, false);
					bspGeometry.faceStruct = null;
				}
				// Если есть динамические BSP
			} else if (dynamicBSPFirst != null) {
				list = collectNode(null, list, camera, threshold, true);
				// Если есть сортировка по средним Z
			} else if (averageZFirst != null) {
				list = sortByAverageZ(list);
			}
			// Сбор отрисовочных вызовов
			var first:Face;
			var last:Face;
			var drawList:Face;
			for (face = list; face != null; face = next) {
				next = face.processNext;
				geometry = face.geometry;
				face.geometry = null;
				var changeGeometry:Boolean = next == null || geometry != next.geometry;
				// Если сменилась геометрия или материал
				if (changeGeometry || face.material != next.material) {
					// Разрыв на стыке
					face.processNext = null;
					// Если сменилась геометрия
					if (changeGeometry) {
						if (first != null) {
							last.negative = list;
							first = null;
							last = null;
						} else {
							list.positive = drawList;
							drawList = list;
							drawList.geometry = geometry;
						}
						// Если сменился материал
					} else {
						if (first != null) {
							last.negative = list;
						} else {
							list.positive = drawList;
							drawList = list;
							drawList.geometry = geometry;
							first = list;
						}
						last = list;
					}
					list = next;
				}
			}
			// Дебаг
			if (camera.debug) {
				canvas = parentCanvas.getChildCanvas(object, true, false);
				for (list = drawList; list != null; list = list.positive) {
					if (list.geometry.debug & Debug.EDGES) {
						for (face = list; face != null; face = face.negative) {
							Debug.drawEdges(camera, canvas, face, 0xFF0000);
						}
					}
				}
			}
			// Отрисовка
			while (drawList != null) {
				list = drawList;
				drawList = list.positive;
				list.positive = null;
				geometry = list.geometry;
				list.geometry = null;
				canvas = parentCanvas.getChildCanvas(geometry.interactiveObject, true, false, geometry.alpha, geometry.blendMode, geometry.colorTransform, geometry.filters);
				for (; list != null; list = next) {
					next = list.negative;
					list.negative = null;
					if (list.material != null) {
						// Отрисовка
						if (geometry.viewAligned) {
							list.material.drawViewAligned(camera, canvas, list, geometry.ml, geometry.tma, geometry.tmb, geometry.tmc, geometry.tmd, geometry.tmtx, geometry.tmty);
						} else {
							list.material.draw(camera, canvas, list, geometry.ml);
						}
					} else {
						// Разрыв связей
						while (list != null) {
							face = list.processNext;
							list.processNext = null;
							list = face;
						}
					}
				}
			}
			// Зачистка
			for (geometry = conflict; geometry != null; geometry = nextGeometry) {
				nextGeometry = geometry.next;
				geometry.destroy();
			}
		}
	
		private function collectNode(splitter:Face, list:Face, camera:Camera3D, threshold:Number, sort:Boolean, result:Face = null):Face {
			var w:Wrapper;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var v:Vertex;
			var normalX:Number;
			var normalY:Number;
			var normalZ:Number;
			var offset:Number;
			var splitterLast:Face;
			var negativeNode:Face;
			var positiveNode:Face;
			var geometry:Geometry;
			// Статическая нода
			if (splitter != null) {
				geometry = splitter.geometry;
				if (splitter.offset < 0) {
					negativeNode = splitter.negative;
					positiveNode = splitter.positive;
					normalX = splitter.normalX;
					normalY = splitter.normalY;
					normalZ = splitter.normalZ;
					offset = splitter.offset;
				} else {
					negativeNode = splitter.positive;
					positiveNode = splitter.negative;
					normalX = -splitter.normalX;
					normalY = -splitter.normalY;
					normalZ = -splitter.normalZ;
					offset = -splitter.offset;
				}
				splitter.negative = null;
				splitter.positive = null;
				if (splitter.wrapper != null) {
					splitterLast = splitter;
					while (splitterLast.processNext != null) {
						splitterLast = splitterLast.processNext;
						splitterLast.geometry = geometry;
					}
				} else {
					splitter.geometry = null;
					splitter = null;
				}
				// Динамическая грань
			} else {
				splitter = list;
				list = splitter.processNext;
				splitterLast = splitter;
				// Поиск удовлетворяющей нормали
				w = splitter.wrapper;
				a = w.vertex;
				w = w.next;
				b = w.vertex;
				var ax:Number = a.cameraX;
				var ay:Number = a.cameraY;
				var az:Number = a.cameraZ;
				var abx:Number = b.cameraX - ax;
				var aby:Number = b.cameraY - ay;
				var abz:Number = b.cameraZ - az;
				normalX = 0;
				normalY = 0;
				normalZ = 1;
				offset = az;
				var length:Number = 0;
				for (w = w.next; w != null; w = w.next) {
					v = w.vertex;
					var acx:Number = v.cameraX - ax;
					var acy:Number = v.cameraY - ay;
					var acz:Number = v.cameraZ - az;
					var nx:Number = acz*aby - acy*abz;
					var ny:Number = acx*abz - acz*abx;
					var nz:Number = acy*abx - acx*aby;
					var nl:Number = nx*nx + ny*ny + nz*nz;
					if (nl > threshold) {
						nl = 1/Math.sqrt(nl);
						normalX = nx*nl;
						normalY = ny*nl;
						normalZ = nz*nl;
						offset = ax*normalX + ay*normalY + az*normalZ;
						break;
					} else if (nl > length) {
						nl = 1/Math.sqrt(nl);
						normalX = nx*nl;
						normalY = ny*nl;
						normalZ = nz*nl;
						offset = ax*normalX + ay*normalY + az*normalZ;
						length = nl;
					}
				}
			}
			var offsetMin:Number = offset - threshold;
			var offsetMax:Number = offset + threshold;
			var negativeFirst:Face;
			var negativeLast:Face;
			var positiveFirst:Face;
			var positiveLast:Face;
			var next:Face;
			for (var face:Face = list; face != null; face = next) {
				next = face.processNext;
				w = face.wrapper;
				a = w.vertex;
				w = w.next;
				b = w.vertex;
				w = w.next;
				c = w.vertex;
				w = w.next;
				var ao:Number = a.cameraX*normalX + a.cameraY*normalY + a.cameraZ*normalZ;
				var bo:Number = b.cameraX*normalX + b.cameraY*normalY + b.cameraZ*normalZ;
				var co:Number = c.cameraX*normalX + c.cameraY*normalY + c.cameraZ*normalZ;
				var behind:Boolean = ao < offsetMin || bo < offsetMin || co < offsetMin;
				var infront:Boolean = ao > offsetMax || bo > offsetMax || co > offsetMax;
				for (; w != null; w = w.next) {
					v = w.vertex;
					var vo:Number = v.cameraX*normalX + v.cameraY*normalY + v.cameraZ*normalZ;
					if (vo < offsetMin) {
						behind = true;
					} else if (vo > offsetMax) {
						infront = true;
					}
					v.offset = vo;
				}
				if (!behind) {
					if (!infront) {
						if (splitter != null) {
							splitterLast.processNext = face;
						} else {
							splitter = face;
						}
						splitterLast = face;
					} else {
						if (positiveFirst != null) {
							positiveLast.processNext = face;
						} else {
							positiveFirst = face;
						}
						positiveLast = face;
					}
				} else if (!infront) {
					if (negativeFirst != null) {
						negativeLast.processNext = face;
					} else {
						negativeFirst = face;
					}
					negativeLast = face;
				} else {
					a.offset = ao;
					b.offset = bo;
					c.offset = co;
					var negative:Face = face.create();
					negative.material = face.material;
					negative.geometry = face.geometry;
					camera.lastFace.next = negative;
					camera.lastFace = negative;
					var positive:Face = face.create();
					positive.material = face.material;
					positive.geometry = face.geometry;
					camera.lastFace.next = positive;
					camera.lastFace = positive;
					var wNegative:Wrapper = null;
					var wPositive:Wrapper = null;
					var wNew:Wrapper;
					for (w = face.wrapper.next.next; w.next != null; w = w.next);
					a = w.vertex;
					ao = a.offset;
					for (w = face.wrapper; w != null; w = w.next) {
						b = w.vertex;
						bo = b.offset;
						if (ao < offsetMin && bo > offsetMax || ao > offsetMax && bo < offsetMin) {
							var t:Number = (offset - ao)/(bo - ao);
							v = b.create();
							camera.lastVertex.next = v;
							camera.lastVertex = v;
							v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
							v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
							v.cameraZ = a.cameraZ + (b.cameraZ - a.cameraZ)*t;
							v.u = a.u + (b.u - a.u)*t;
							v.v = a.v + (b.v - a.v)*t;
							wNew = w.create();
							wNew.vertex = v;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
							wNew = w.create();
							wNew.vertex = v;
							if (wPositive != null) {
								wPositive.next = wNew;
							} else {
								positive.wrapper = wNew;
							}
							wPositive = wNew;
						}
						if (bo <= offsetMax) {
							wNew = w.create();
							wNew.vertex = b;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
						}
						if (bo >= offsetMin) {
							wNew = w.create();
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
					if (negativeFirst != null) {
						negativeLast.processNext = negative;
					} else {
						negativeFirst = negative;
					}
					negativeLast = negative;
					if (positiveFirst != null) {
						positiveLast.processNext = positive;
					} else {
						positiveFirst = positive;
					}
					positiveLast = positive;
					face.processNext = null;
					face.geometry = null;
				}
			}
			// Передняя часть
			if (positiveNode != null) {
				positiveNode.geometry = geometry;
				if (positiveLast != null) positiveLast.processNext = null;
				result = collectNode(positiveNode, positiveFirst, camera, threshold, sort, result);
			} else if (positiveFirst != null) {
				// Если нужно сортировать
				if (sort && positiveFirst != positiveLast) {
					if (positiveLast != null) positiveLast.processNext = null;
					if (positiveFirst.geometry.sorting == 2) {
						result = collectNode(null, positiveFirst, camera, threshold, sort, result);
					} else {
						positiveFirst = sortByAverageZ(positiveFirst);
						// Не красиво
						for (positiveLast = positiveFirst.processNext; positiveLast.processNext != null; positiveLast = positiveLast.processNext);
						positiveLast.processNext = result;
						result = positiveFirst;
					}
				} else {
					positiveLast.processNext = result;
					result = positiveFirst;
				}
			}
			// Средння часть
			if (splitter != null) {
				splitterLast.processNext = result;
				result = splitter;
			}
			// Задняя часть
			if (negativeNode != null) {
				negativeNode.geometry = geometry;
				if (negativeLast != null) negativeLast.processNext = null;
				result = collectNode(negativeNode, negativeFirst, camera, threshold, sort, result);
			} else if (negativeFirst != null) {
				// Если нужно сортировать
				if (sort && negativeFirst != negativeLast) {
					if (negativeLast != null) negativeLast.processNext = null;
					if (negativeFirst.geometry.sorting == 2) {
						result = collectNode(null, negativeFirst, camera, threshold, sort, result);
					} else {
						negativeFirst = sortByAverageZ(negativeFirst);
						// Не красиво
						for (negativeLast = negativeFirst.processNext; negativeLast.processNext != null; negativeLast = negativeLast.processNext);
						negativeLast.processNext = result;
						result = negativeFirst;
					}
				} else {
					negativeLast.processNext = result;
					result = negativeFirst;
				}
			}
			return result;
		}
	
		private function sortByAverageZ(list:Face):Face {
			var num:int;
			var sum:Number;
			var wrapper:Wrapper;
			var left:Face = list;
			var right:Face = list.processNext;
			while (right != null && right.processNext != null) {
				list = list.processNext;
				right = right.processNext.processNext;
			}
			right = list.processNext;
			list.processNext = null;
			if (left.processNext != null) {
				left = sortByAverageZ(left);
			} else {
				num = 0;
				sum = 0;
				for (wrapper = left.wrapper; wrapper != null; wrapper = wrapper.next) {
					num++;
					sum += wrapper.vertex.cameraZ;
				}
				left.distance = sum/num;
			}
			if (right.processNext != null) {
				right = sortByAverageZ(right);
			} else {
				num = 0;
				sum = 0;
				for (wrapper = right.wrapper; wrapper != null; wrapper = wrapper.next) {
					num++;
					sum += wrapper.vertex.cameraZ;
				}
				right.distance = sum/num;
			}
			var flag:Boolean = left.distance > right.distance;
			if (flag) {
				list = left;
				left = left.processNext;
			} else {
				list = right;
				right = right.processNext;
			}
			var last:Face = list;
			while (true) {
				if (left == null) {
					last.processNext = right;
					return list;
				} else if (right == null) {
					last.processNext = left;
					return list;
				}
				if (flag) {
					if (left.distance > right.distance) {
						last = left;
						left = left.processNext;
					} else {
						last.processNext = right;
						last = right;
						right = right.processNext;
						flag = false;
					}
				} else {
					if (right.distance > left.distance) {
						last = right;
						right = right.processNext;
					} else {
						last.processNext = left;
						last = left;
						left = left.processNext;
						flag = true;
					}
				}
			}
			return null;
		}
	
	}
}
