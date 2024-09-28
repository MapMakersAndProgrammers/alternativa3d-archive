package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Object3D;

	import flash.geom.Matrix3D;
	import flash.geom.Utils3D;
	
	use namespace alternativa3d;
	
	/**
	 * Полигональный объект-перекрытие.
	 * Объекты, которые он перекрывает от видимости камеры, исключаются из отрисовки.
	 * Сам окклюдер не отрисовывается.
	 * Должен быть конвексным
	 */
	public class Occluder extends Object3D {
		/**
		 * Режим представления полигонов. 
		 * Если false, в indices записаны треугольники (тройки индексов).
		 * Если true, в indices записаны многоугольники в виде: количество вершин грани, индексы вершин
		 */
		public var poly:Boolean = false;
		public var vertices:Vector.<Number>;
		public var edges:Vector.<int>; // Два индекса - вершины, два - грани
		public var indices:Vector.<int>;
		public var normals:Vector.<Number>;
		
		// Отношение площади перекрытия к площади вьюпорта (0 - 1)
		/**
		 * Минимальное отношение площади перекрытия окклюдером вьюпорта к площади вьюпорта (от 0 до 1)
		 * Если окклюдер перекрывает больше, он помещается в очередь и учитывается 
		 * при дальнейшей отрисовке в пределах кадра, иначе игнорируется
		 */
		public var minSize:Number = 0;
		
		private const cameraVertices:Vector.<Number> = new Vector.<Number>();
		private const visibilityMap:Vector.<Boolean> = new Vector.<Boolean>;
		
		/**
		 * Коприрование геометрии меша 
		 * @param mesh Объект копирования
		 * Меш, геометрия которого копируется, обязан быть конвексным, иначе окклюдер будет некорректно работать
		 */
		public function copyFrom(mesh:Mesh):void {
			poly = mesh.poly;
			vertices = mesh.vertices;
			indices = mesh.indices;
			normals = mesh.normals;
			
			matrix.identity();
			matrix.prepend(mesh.matrix);
			if (_boundBox != null) {
				_boundBox.copyFrom(mesh._boundBox);
			} else {
				_boundBox = mesh._boundBox;
			}
		}

		override public function calculateBoundBox(matrix:Matrix3D = null, boundBox:BoundBox = null):BoundBox {
			var v:Vector.<Number> = vertices;
			// Если указана матрица трансформации, переводим
			if (matrix != null) {
				matrix.transformVectors(vertices, cameraVertices);
				v = cameraVertices;
			}
			// Если указан баунд-бокс
			if (boundBox != null) {
				boundBox.infinity();
			} else {
				boundBox = new BoundBox();
			}
			// Ищем баунд-бокс
			for (var i:int = 0, length:int = vertices.length; i < length;) {
				boundBox.addPoint(v[i++], v[i++], v[i++]);
			}
			return boundBox;
		}
		
		/**
		 * Расчёт рёбер по имеющимся вершинам и граням 
		 */
		public function calculateEdges():void {
			// Подготавливаем массив рёбер
			if (edges == null) edges = new Vector.<int>();
			
			// Собираем рёбра
			for (var i:int = 0, j:int = 0, n:int = 0, k:int = 0, a:int, b:int, length:int = indices.length; i < length;) {
				if (i == k) {
					k = poly ? (indices[i++] + i) : (i + 3);
					a = indices[int(k - 1)];
				}
				b = indices[i];
				edges[j++] = a;
				edges[j++] = b;
				edges[j++] = n;
				edges[j++] = -1;
				if (++i == k) n++; else a = b;
			}
			edges.length = j;
			
			// Убираем дубли
			length = j, i = 0; k = 0;
			var ac:int, bc:int;
			while (i < length) {
				if ((a = edges[i++]) >= 0) {
					b = edges[i++];
					edges[k++] = a;
					edges[k++] = b;
					edges[k++] = edges[i++];
					j = ++i;
					while (j < length) {
						ac = edges[j++]; 
						bc = edges[j++];
						if (ac == a && bc == b || ac == b && bc == a) {
							edges[int(j - 2)] = -1;
							edges[k] = edges[j];
							break;
						}
						j += 2;
					}
					k++;
				} else i += 3;
			}
			edges.length = k;
		}
		
		static private const inverseCameraMatrix:Matrix3D = new Matrix3D();
		static private const center:Vector.<Number> = new Vector.<Number>(3, true);
		private var cameraX:Number;
		private var cameraY:Number;
		private var cameraZ:Number;
		static private const projectedEdges:Vector.<Number> = new Vector.<Number>();
		static private const uvts:Vector.<Number> = new Vector.<Number>();
		static private const viewEdges:Vector.<Number> = new Vector.<Number>();
		static private const debugEdges:Vector.<Number> = new Vector.<Number>();
		
		/**
		 * @private
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Перевод в координаты камеры
			object.cameraMatrix.transformVectors(vertices, cameraVertices);
			// Определение центра камеры в объекте
			inverseCameraMatrix.identity();
			inverseCameraMatrix.prepend(object.cameraMatrix);
			inverseCameraMatrix.invert();
			center[0] = center[1] = center[2] = 0;
			inverseCameraMatrix.transformVectors(center, center);
			cameraX = center[0], cameraY = center[1], cameraZ = center[2];
			// Расчёт карты видимости граней
			for (var i:int = 0, n:int = 0, normalsLength:int = normals.length >> 2, cameraInside:Boolean = true, infront:Boolean; i < normalsLength;) visibilityMap[i++] = infront = normals[n++]*cameraX + normals[n++]*cameraY + normals[n++]*cameraZ > normals[n++], cameraInside &&= !infront;
			// Если камера внутри окклюдера
			if (cameraInside) return;
			// Подготовка окклюдера в камере
			var occludeAll:Boolean = true, culling:int = object.culling, direction:Boolean, ax:Number, ay:Number, az:Number, bx:Number, by:Number, bz:Number, t:Number;
			var planeOccluder:Vector.<Number>, edgeOccluder:Vector.<Number>, planeOccluderLength:int = 0, edgeOccluderLength:int = 0, viewEdgesLength:int = 0;
			if (camera.occlusionPlanes.length > camera.numOccluders) {
				planeOccluder = camera.occlusionPlanes[camera.numOccluders];
				edgeOccluder = camera.occlusionEdges[camera.numOccluders];
			} else {
				planeOccluder = camera.occlusionPlanes[camera.numOccluders] = new Vector.<Number>();
				edgeOccluder = camera.occlusionEdges[camera.numOccluders] = new Vector.<Number>();
			}
			for (i = edges.length - 1; i > 0;) {
				if ((direction = visibilityMap[edges[i--]]) != visibilityMap[edges[i--]]) {
					// Определение порядка вершин (против часовой)
					if (direction) {
						ax = cameraVertices[n = int(edges[i--]*3)], ay = cameraVertices[++n], az = cameraVertices[++n], bx = cameraVertices[n = int(edges[i--]*3)], by = cameraVertices[++n], bz = cameraVertices[++n];
					} else {
						bx = cameraVertices[n = int(edges[i--]*3)], by = cameraVertices[++n], bz = cameraVertices[++n], ax = cameraVertices[n = int(edges[i--]*3)], ay = cameraVertices[++n], az = cameraVertices[++n];
					}
					// Клиппинг
					if (culling > 0) {
						if (az <= -ax && bz <= -bx) {
							if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
							continue;
						} else if (bz > -bx && az <= -ax) {
							t = (ax + az)/(ax + az - bx - bz), ax = ax + (bx - ax)*t, ay = ay + (by - ay)*t, az = az + (bz - az)*t;
						} else if (bz <= -bx && az > -ax) {
							t = (ax + az)/(ax + az - bx - bz), bx = ax + (bx - ax)*t, by = ay + (by - ay)*t, bz = az + (bz - az)*t;
						}
						if (az <= ax && bz <= bx) {
							if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
							continue;
						} else if (bz > bx && az <= ax) {
							t = (az - ax)/(az - ax + bx - bz), ax = ax + (bx - ax)*t, ay = ay + (by - ay)*t, az = az + (bz - az)*t;
						} else if (bz <= bx && az > ax) {
							t = (az - ax)/(az - ax + bx - bz), bx = ax + (bx - ax)*t, by = ay + (by - ay)*t, bz = az + (bz - az)*t;
						}
						if (az <= -ay && bz <= -by) {
							if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
							continue;
						} else if (bz > -by && az <= -ay) {
							t = (ay + az)/(ay + az - by - bz), ax = ax + (bx - ax)*t, ay = ay + (by - ay)*t, az = az + (bz - az)*t;
						} else if (bz <= -by && az > -ay) {
							t = (ay + az)/(ay + az - by - bz), bx = ax + (bx - ax)*t, by = ay + (by - ay)*t, bz = az + (bz - az)*t;
						}
						if (az <= ay && bz <= by) {
							if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
							continue;
						} else if (bz > by && az <= ay) {
							t = (az - ay)/(az - ay + by - bz), ax = ax + (bx - ax)*t, ay = ay + (by - ay)*t, az = az + (bz - az)*t;
						} else if (bz <= by && az > ay) {
							t = (az - ay)/(az - ay + by - bz), bx = ax + (bx - ax)*t, by = ay + (by - ay)*t, bz = az + (bz - az)*t;
						}
						occludeAll = false;
					}
					// Расчёт нормали плоскости отсечения
					planeOccluder[planeOccluderLength++] = bz*ay - by*az, planeOccluder[planeOccluderLength++] = bx*az - bz*ax, planeOccluder[planeOccluderLength++] = by*ax - bx*ay;
					// Сохранение рёбер
					edgeOccluder[edgeOccluderLength++] = ax, edgeOccluder[edgeOccluderLength++] = ay, edgeOccluder[edgeOccluderLength++] = az, edgeOccluder[edgeOccluderLength++] = bx, edgeOccluder[edgeOccluderLength++] = by, edgeOccluder[edgeOccluderLength++] = bz;
				} else i -= 2;
			}
			if (planeOccluderLength > 0) {
				// Проверка размера на экране
				if (minSize > 0) {
					// Проецирование рёбер контура 
					var projectedEdgesLength:int = projectedEdges.length = ((edgeOccluder.length = edgeOccluderLength)/3) << 1;
					Utils3D.projectVectors(camera.projectionMatrix, edgeOccluder, projectedEdges, uvts);
					// Клиппинг рамки вьюпорта
					if (culling > 0) {
						if (culling & 4) viewEdges[viewEdgesLength++] = -camera.viewSizeX, viewEdges[viewEdgesLength++] = -camera.viewSizeY, viewEdges[viewEdgesLength++] = -camera.viewSizeX, viewEdges[viewEdgesLength++] = camera.viewSizeY;
						if (culling & 8) viewEdges[viewEdgesLength++] = camera.viewSizeX, viewEdges[viewEdgesLength++] = camera.viewSizeY, viewEdges[viewEdgesLength++] = camera.viewSizeX, viewEdges[viewEdgesLength++] = -camera.viewSizeY;
						if (culling & 16) viewEdges[viewEdgesLength++] = camera.viewSizeX, viewEdges[viewEdgesLength++] = -camera.viewSizeY, viewEdges[viewEdgesLength++] = -camera.viewSizeX, viewEdges[viewEdgesLength++] = -camera.viewSizeY;
						if (culling & 32) viewEdges[viewEdgesLength++] = -camera.viewSizeX, viewEdges[viewEdgesLength++] = camera.viewSizeY, viewEdges[viewEdgesLength++] = camera.viewSizeX, viewEdges[viewEdgesLength++] = camera.viewSizeY;
						if (viewEdgesLength > 0) {
							for (i = 0; i < projectedEdgesLength;) {
								ax = projectedEdges[i++], ay = projectedEdges[i++], bx = projectedEdges[i++], by = projectedEdges[i++]; 
								var nx:Number = ay - by, ny:Number = bx - ax, no:Number = nx*ax + ny*ay;
								for (var j:int = 0, j2:int = 0; j < viewEdgesLength;) {
									ax = viewEdges[j++], ay = viewEdges[j++], bx = viewEdges[j++], by = viewEdges[j++], az = ax*nx + ay*ny - no, bz = bx*nx + by*ny - no;
									if (az < 0 || bz < 0) {
										if (az >= 0 && bz < 0) {
											t = az/(az - bz), viewEdges[j2++] = ax + (bx - ax)*t, viewEdges[j2++] = ay + (by - ay)*t, viewEdges[j2++] = bx, viewEdges[j2++] = by;
										} else if (az < 0 && bz >= 0) {
											t = az/(az - bz), viewEdges[j2++] = ax, viewEdges[j2++] = ay, viewEdges[j2++] = ax + (bx - ax)*t, viewEdges[j2++] = ay + (by - ay)*t;
										} else {
											viewEdges[j2++] = ax, viewEdges[j2++] = ay, viewEdges[j2++] = bx, viewEdges[j2++] = by;
										}
									}
								}
								viewEdgesLength = j2;
								if (viewEdgesLength == 0) break;
							}
						}
					}
					// Нахождение площади перекрытия
					var square:Number = 0;
					for (i = 0, az = projectedEdges[i++], bz = projectedEdges[i++], i += 2; i < projectedEdgesLength;) ax = projectedEdges[i++] - az, ay = projectedEdges[i++] - bz, bx = projectedEdges[i++] - az, by = projectedEdges[i++] - bz, square += bx*ay - by*ax;
					for (i = 0; i < viewEdgesLength;) ax = viewEdges[i++] - az, ay = viewEdges[i++] - bz, bx = viewEdges[i++] - az, by = viewEdges[i++] - bz, square += bx*ay - by*ax;
					if (square/(camera.viewSizeX*camera.viewSizeY*8) < minSize) return;
				}
				// Добавление окклюдера
				camera.numOccluders++;
				planeOccluder.length = planeOccluderLength;
				edgeOccluder.length = edgeOccluderLength;
			} else {
				if (occludeAll) {
					camera.numOccluders = 0, camera.occludedAll = true;
				} else {
					 return;
				}
			}
		}
		
		override alternativa3d function debug(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var inDebug:int = camera.checkInDebug(this);
			if (inDebug == 0) return;
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false);
			
			// Рёбра
			if (inDebug & Debug.EDGES) {
				object.cameraMatrix.transformVectors(vertices, cameraVertices);
				inverseCameraMatrix.identity();
				inverseCameraMatrix.prepend(object.cameraMatrix);
				inverseCameraMatrix.invert();
				center[0] = center[1] = center[2] = 0;
				inverseCameraMatrix.transformVectors(center, center);
				cameraX = center[0], cameraY = center[1], cameraZ = center[2];
				// Расчёт карты видимости граней
				for (var i:int = 0, n:int = 0, normalsLength:int = normals.length >> 2, cameraInside:Boolean = true, infront:Boolean; i < normalsLength;) visibilityMap[i++] = infront = normals[n++]*cameraX + normals[n++]*cameraY + normals[n++]*cameraZ > normals[n++], cameraInside &&= !infront;
				// Если камера внутри окклюдера
				if (!cameraInside) {
					// Подготовка окклюдера в камере
					var occludeAll:Boolean = true, culling:int = object.culling, direction:Boolean, ax:Number, ay:Number, az:Number, bx:Number, by:Number, bz:Number, t:Number;
					var debugEdgesLength:int = 0, viewEdgesLength:int = 0;
					for (i = edges.length - 1; i > 0;) {
						if ((direction = visibilityMap[edges[i--]]) != visibilityMap[edges[i--]]) {
							// Определение порядка вершин (против часовой)
							if (direction) {
								ax = cameraVertices[n = int(edges[i--]*3)], ay = cameraVertices[++n], az = cameraVertices[++n], bx = cameraVertices[n = int(edges[i--]*3)], by = cameraVertices[++n], bz = cameraVertices[++n];
							} else {
								 bx = cameraVertices[n = int(edges[i--]*3)], by = cameraVertices[++n], bz = cameraVertices[++n], ax = cameraVertices[n = int(edges[i--]*3)], ay = cameraVertices[++n], az = cameraVertices[++n];
							}
							// Клиппинг
							if (culling > 0) {
								if (az <= -ax && bz <= -bx) {
									if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
									continue;
								} else if (bz > -bx && az <= -ax) {
									t = (ax + az)/(ax + az - bx - bz), ax = ax + (bx - ax)*t, ay = ay + (by - ay)*t, az = az + (bz - az)*t;
								} else if (bz <= -bx && az > -ax) {
									t = (ax + az)/(ax + az - bx - bz), bx = ax + (bx - ax)*t, by = ay + (by - ay)*t, bz = az + (bz - az)*t;
								}
								if (az <= ax && bz <= bx) {
									if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
									continue;
								} else if (bz > bx && az <= ax) {
									t = (az - ax)/(az - ax + bx - bz), ax = ax + (bx - ax)*t, ay = ay + (by - ay)*t, az = az + (bz - az)*t;
								} else if (bz <= bx && az > ax) {
									t = (az - ax)/(az - ax + bx - bz), bx = ax + (bx - ax)*t, by = ay + (by - ay)*t, bz = az + (bz - az)*t;
								}
								if (az <= -ay && bz <= -by) {
									if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
									continue;
								} else if (bz > -by && az <= -ay) {
									t = (ay + az)/(ay + az - by - bz), ax = ax + (bx - ax)*t, ay = ay + (by - ay)*t, az = az + (bz - az)*t;
								} else if (bz <= -by && az > -ay) {
									t = (ay + az)/(ay + az - by - bz), bx = ax + (bx - ax)*t, by = ay + (by - ay)*t, bz = az + (bz - az)*t;
								}
								if (az <= ay && bz <= by) {
									if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
									continue;
								} else if (bz > by && az <= ay) {
									t = (az - ay)/(az - ay + by - bz), ax = ax + (bx - ax)*t, ay = ay + (by - ay)*t, az = az + (bz - az)*t;
								} else if (bz <= by && az > ay) {
									t = (az - ay)/(az - ay + by - bz), bx = ax + (bx - ax)*t, by = ay + (by - ay)*t, bz = az + (bz - az)*t;
								}
								occludeAll = false;
							}
							debugEdges[debugEdgesLength++] = ax;
							debugEdges[debugEdgesLength++] = ay;
							debugEdges[debugEdgesLength++] = az;
							debugEdges[debugEdgesLength++] = bx;
							debugEdges[debugEdgesLength++] = by;
							debugEdges[debugEdgesLength++] = bz;
						} else i -= 2;
					}
					if (debugEdgesLength > 0) {
						// Проецирование рёбер контура 
						var projectedEdgesLength:int = projectedEdges.length = ((debugEdges.length = debugEdgesLength)/3) << 1;
						Utils3D.projectVectors(camera.projectionMatrix, debugEdges, projectedEdges, uvts);
						// Проверка размера на экране
						var square:Number = Number.MAX_VALUE;
						if (minSize > 0) {
							// Клиппинг рамки вьюпорта
							if (culling > 0) {
								if (culling & 4) viewEdges[viewEdgesLength++] = -camera.viewSizeX, viewEdges[viewEdgesLength++] = -camera.viewSizeY, viewEdges[viewEdgesLength++] = -camera.viewSizeX, viewEdges[viewEdgesLength++] = camera.viewSizeY;
								if (culling & 8) viewEdges[viewEdgesLength++] = camera.viewSizeX, viewEdges[viewEdgesLength++] = camera.viewSizeY, viewEdges[viewEdgesLength++] = camera.viewSizeX, viewEdges[viewEdgesLength++] = -camera.viewSizeY;
								if (culling & 16) viewEdges[viewEdgesLength++] = camera.viewSizeX, viewEdges[viewEdgesLength++] = -camera.viewSizeY, viewEdges[viewEdgesLength++] = -camera.viewSizeX, viewEdges[viewEdgesLength++] = -camera.viewSizeY;
								if (culling & 32) viewEdges[viewEdgesLength++] = -camera.viewSizeX, viewEdges[viewEdgesLength++] = camera.viewSizeY, viewEdges[viewEdgesLength++] = camera.viewSizeX, viewEdges[viewEdgesLength++] = camera.viewSizeY;
								if (viewEdgesLength > 0) {
									for (i = 0; i < projectedEdgesLength;) {
										ax = projectedEdges[i++], ay = projectedEdges[i++], bx = projectedEdges[i++], by = projectedEdges[i++]; 
										var nx:Number = ay - by, ny:Number = bx - ax, no:Number = nx*ax + ny*ay;
										for (var j:int = 0, j2:int = 0; j < viewEdgesLength;) {
											ax = viewEdges[j++], ay = viewEdges[j++], bx = viewEdges[j++], by = viewEdges[j++], az = ax*nx + ay*ny - no, bz = bx*nx + by*ny - no;
											if (az < 0 || bz < 0) {
												if (az >= 0 && bz < 0) {
													t = az/(az - bz), viewEdges[j2++] = ax + (bx - ax)*t, viewEdges[j2++] = ay + (by - ay)*t, viewEdges[j2++] = bx, viewEdges[j2++] = by;
												} else if (az < 0 && bz >= 0) {
													t = az/(az - bz), viewEdges[j2++] = ax, viewEdges[j2++] = ay, viewEdges[j2++] = ax + (bx - ax)*t, viewEdges[j2++] = ay + (by - ay)*t;
												} else {
													viewEdges[j2++] = ax, viewEdges[j2++] = ay, viewEdges[j2++] = bx, viewEdges[j2++] = by;
												}
											}
										}
										viewEdgesLength = j2;
										if (viewEdgesLength == 0) break;
									}
								}
							}
							// Нахождение площади перекрытия
							square = 0;
							for (i = 0, az = projectedEdges[i++], bz = projectedEdges[i++], i += 2; i < projectedEdgesLength;) ax = projectedEdges[i++] - az, ay = projectedEdges[i++] - bz, bx = projectedEdges[i++] - az, by = projectedEdges[i++] - bz, square += bx*ay - by*ax;
							for (i = 0; i < viewEdgesLength;) ax = viewEdges[i++] - az, ay = viewEdges[i++] - bz, bx = viewEdges[i++] - az, by = viewEdges[i++] - bz, square += bx*ay - by*ax;
						}
						if (canvas == null) canvas = parentCanvas.getChildCanvas(true, false);
						var color:int, thickness:Number;
						if (square/(camera.viewSizeX*camera.viewSizeY*8) >= minSize) {
							color = 0x0000FF, thickness = 3;
						} else {
							color = 0x0077AA, thickness = 1;
						}
						for (i = 0; i < projectedEdges.length;) {
							ax = projectedEdges[i++], ay = projectedEdges[i++], bx = projectedEdges[i++], by = projectedEdges[i++];
							canvas.gfx.moveTo(ax, ay);
							canvas.gfx.lineStyle(thickness, color);
							canvas.gfx.lineTo(ax + (bx - ax)*0.8, ay + (by - ay)*0.8);
							canvas.gfx.lineStyle(thickness, 0xFF0000);
							canvas.gfx.lineTo(bx, by);
						}
						for (i = 0; i < viewEdgesLength;) {
							canvas.gfx.moveTo(viewEdges[i++], viewEdges[i++]);
							canvas.gfx.lineTo(viewEdges[i++], viewEdges[i++]);
						}
					} else {
						if (occludeAll) {
							if (canvas == null) canvas = parentCanvas.getChildCanvas(true, false);
							canvas.gfx.lineStyle(6, 0xFF0000);
							canvas.gfx.moveTo(-camera.viewSizeX, -camera.viewSizeY);
							canvas.gfx.lineTo(-camera.viewSizeX, camera.viewSizeY);
							canvas.gfx.lineTo(camera.viewSizeX, camera.viewSizeY);
							canvas.gfx.lineTo(camera.viewSizeX, -camera.viewSizeY);
							canvas.gfx.lineTo(-camera.viewSizeX, -camera.viewSizeY);
						}
					}
				}
			}
			// Оси, центры, имена, баунды
			if (inDebug & Debug.AXES) object.drawAxes(camera, canvas);
			if (inDebug & Debug.CENTERS) object.drawCenter(camera, canvas);
			if (inDebug & Debug.NAMES) object.drawName(camera, canvas);
			if (inDebug & Debug.BOUNDS) object.drawBoundBox(camera, canvas);
		}
	}
}
