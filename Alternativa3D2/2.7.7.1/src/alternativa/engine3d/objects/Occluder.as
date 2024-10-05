package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.core.Geometry;
	import flash.utils.Dictionary;
	
	use namespace alternativa3d;
	
	/**
	 * Полигональный объект, состоящий из вершин и граней, построенных по этим вершинам.
	 * Это — объект-перекрытие.
	 * Объекты, которые он перекрывает от видимости камеры, исключаются из отрисовки.
	 * Сам окклюдер не отображается.
	 * Грани должны образовывать замкнутый выпуклый многогранник — конвекс.
	 * @see alternativa.engine3d.core.Vertex
	 * @see alternativa.engine3d.core.Face
	 */
	public class Occluder extends Object3D {
		
		/**
		 * @private 
		 */
		alternativa3d var faceList:Face;
		
		/**
		 * @private 
		 */
		alternativa3d var edgeList:Edge;
		
		/**
		 * @private 
		 */
		alternativa3d var vertexList:Vertex;
	
		/**
		 * Минимальное отношение площади перекрытия окклюдером вьюпорта к площади вьюпорта.
		 * Свойство может принимать значения от <code>0</code> до <code>1</code>.
		 * Если при отрисовке окклюдер перекрывает площадь равную или большую этого значения, он помещается в очередь и учитывается
		 * при дальнейшей отрисовке в пределах кадра, иначе игнорируется.
		 */
		public var minSize:Number = 0;
		
		/**
		 * Геометрия объекта.
		 * При получении и установке геометрии происходит клонирование вершин и граней.
		 * @see alternativa.engine3d.core.Geometry
		 * @see alternativa.engine3d.core.Vertex
		 * @see alternativa.engine3d.core.Face
		 */
		public function set geometry(value:Geometry):void {
			faceList = null;
			edgeList = null;
			vertexList = null;
			if (value != null) {
				var vertex:Vertex;
				// Клонирование вершин
				for each (vertex in value._vertices) {
					var newVertex:Vertex = new Vertex();
					newVertex.x = vertex.x;
					newVertex.y = vertex.y;
					newVertex.z = vertex.z;
					newVertex.u = vertex.u;
					newVertex.v = vertex.v;
					vertex.value = newVertex;
					newVertex.next = vertexList;
					vertexList = newVertex;
				}
				// Клонирование граней
				for each (var face:Face in value._faces) {
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
					newFace.next = faceList;
					faceList = newFace;
				}
				// Сброс после ремапа
				for each (vertex in value._vertices) {
					vertex.value = null;
				}
				// Расчёт рёбер и проверка на валидность
				var error:String = calculateEdges();
				if (error != null) {
					faceList = null;
					edgeList = null;
					vertexList = null;
					throw new ArgumentError(error);
				}
			}
		}
		
		/**
		 * Забирает экземпляры вершин и граней из предоставленного объекта класса <code>Geometry</code>.
		 * После переноса ассоциативные массивы вершин и граней переданного объекта остаются пустыми.
		 * @param geometry Объект класса <code>Geometry</code>.
		 * @see alternativa.engine3d.core.Geometry
		 * @see alternativa.engine3d.core.Vertex
		 * @see alternativa.engine3d.core.Face
		 */
		public function takeGeometryFrom(geometry:Geometry):void {
			faceList = null;
			edgeList = null;
			vertexList = null;
			// Перенос вершин
			for each (var vertex:Vertex in geometry._vertices) {
				vertex.next = vertexList;
				vertexList = vertex;
			}
			// Перенос граней
			for each (var face:Face in geometry._faces) {
				face.next = faceList;
				faceList = face;
			}
			// Расчёт рёбер и проверка на валидность
			var error:String = calculateEdges();
			if (error != null) {
				faceList = null;
				edgeList = null;
				vertexList = null;
				for each (var v:Vertex in geometry._vertices) v.next = null;
				for each (var f:Face in geometry._faces) f.next = null;
				throw new ArgumentError(error);
			} else {
				geometry._vertices = new Dictionary();
				geometry._faces = new Dictionary();
				geometry.vertexIdCounter = 0;
				geometry.faceIdCounter = 0;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Occluder = new Occluder();
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:Occluder = source as Occluder;
			minSize = src.minSize;
			// Клонирование вершин
			var vertex:Vertex;
			var face:Face;
			var lastVertex:Vertex;
			for (vertex = src.vertexList; vertex != null; vertex = vertex.next) {
				var newVertex:Vertex = new Vertex();
				newVertex.x = vertex.x;
				newVertex.y = vertex.y;
				newVertex.z = vertex.z;
				newVertex.u = vertex.u;
				newVertex.v = vertex.v;
				vertex.value = newVertex;
				if (lastVertex != null) {
					lastVertex.next = newVertex;
				} else {
					vertexList = newVertex;
				}
				lastVertex = newVertex;
			}
			// Клонирование граней
			var lastFace:Face;
			for (face = src.faceList; face != null; face = face.next) {
				var newFace:Face = new Face();
				newFace.material = face.material;
				newFace.normalX = face.normalX;
				newFace.normalY = face.normalY;
				newFace.normalZ = face.normalZ;
				newFace.offset = face.offset;
				face.processNext = newFace;
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
				if (lastFace != null) {
					lastFace.next = newFace;
				} else {
					faceList = newFace;
				}
				lastFace = newFace;
			}
			// Клонирование рёбер
			var lastEdge:Edge;
			for (var edge:Edge = src.edgeList; edge != null; edge = edge.next) {
				var newEdge:Edge = new Edge();
				newEdge.a = edge.a.value;
				newEdge.b = edge.b.value;
				newEdge.left = edge.left.processNext;
				newEdge.right = edge.right.processNext;
				if (lastEdge != null) {
					lastEdge.next = newEdge;
				} else {
					edgeList = newEdge;
				}
				lastEdge = newEdge;
			}
			// Сброс после ремапа
			for (vertex = src.vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
			for (face = src.faceList; face != null; face = face.next) {
				face.processNext = null;
			}
		}
		
		private function calculateEdges():String {
			var face:Face;
			var wrapper:Wrapper;
			var edge:Edge;
			// Построение рёбер
			for (face = faceList; face != null; face = face.next) {
				// Расчёт нормали
				face.calculateBestSequenceAndNormal();
				// Перебор отрезков грани
				var a:Vertex;
				var b:Vertex;
				for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next, a = b) {
					a = wrapper.vertex;
					b = (wrapper.next != null) ? wrapper.next.vertex : face.wrapper.vertex;
					// Перебор созданных рёбер
					for (edge = edgeList; edge != null; edge = edge.next) {
						// Если некорректная геометрия
						if (edge.a == a && edge.b == b) {
							return "The supplied geometry is not valid.";
						}
						// Если найдено созданное ребро с такими вершинами
						if (edge.a == b && edge.b == a) break;
					}
					if (edge != null) {
						edge.right = face;
					} else {
						edge = new Edge();
						edge.a = a;
						edge.b = b;
						edge.left = face;
						edge.next = edgeList;
						edgeList = edge;
					}
				}
			}
			// Проверка на валидность
			for (edge = edgeList; edge != null; edge = edge.next) {
				// Если ребро с одной гранью
				if (edge.left == null || edge.right == null) {
					return "The supplied geometry is non whole.";
				}
				var abx:Number = edge.b.x - edge.a.x;
				var aby:Number = edge.b.y - edge.a.y;
				var abz:Number = edge.b.z - edge.a.z;
				var crx:Number = edge.right.normalZ*edge.left.normalY - edge.right.normalY*edge.left.normalZ;
				var cry:Number = edge.right.normalX*edge.left.normalZ - edge.right.normalZ*edge.left.normalX;
				var crz:Number = edge.right.normalY*edge.left.normalX - edge.right.normalX*edge.left.normalY;
				// Если перегиб внутрь
				if (abx*crx + aby*cry + abz*crz < 0) {
					//return "The supplied geometry is non convex.";
					trace("Warning: " + this + ": geometry is non convex.");
				}
			}
			return null;
		}
	
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas):void {
			if (faceList == null || edgeList == null) return;
			var canvas:Canvas;
			var debug:int;
			// Расчёт инверсной матрицы камеры
			calculateInverseMatrix();
			// Определение видимости граней
			var cameraInside:Boolean = true;
			for (var face:Face = faceList; face != null; face = face.next) {
				if (face.normalX*imd + face.normalY*imh + face.normalZ*iml > face.offset) {
					face.distance = 1;
					cameraInside = false;
				} else {
					face.distance = 0;
				}
			}
			if (cameraInside) return;
			// Подготовка окклюдера в камере
			var occluder:Vertex;
			var num:int = 0;
			var occludeAll:Boolean = true;
			var viewSizeX:Number = camera.viewSizeX;
			var viewSizeY:Number = camera.viewSizeY;
			var a:Vertex;
			var b:Vertex;
			var ax:Number;
			var ay:Number;
			var az:Number;
			var bx:Number;
			var by:Number;
			var bz:Number;
			var t:Number;
			// Расчёт контура
			for (var edge:Edge = edgeList; edge != null; edge = edge.next) {
				// Если ребро в описывающем контуре
				if (edge.left.distance != edge.right.distance) {
					// Определение направления (против часовой)
					if (edge.left.distance > 0) {
						a = edge.a;
						b = edge.b;
					} else {
						a = edge.b;
						b = edge.a;
					}
					// Трансформация в камеру
					ax = ma*a.x + mb*a.y + mc*a.z + md;
					ay = me*a.x + mf*a.y + mg*a.z + mh;
					az = mi*a.x + mj*a.y + mk*a.z + ml;
					bx = ma*b.x + mb*b.y + mc*b.z + md;
					by = me*b.x + mf*b.y + mg*b.z + mh;
					bz = mi*b.x + mj*b.y + mk*b.z + ml;
					// Клиппинг
					if (culling > 0) {
						if (az <= -ax && bz <= -bx) {
							if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
							continue;
						} else if (bz > -bx && az <= -ax) {
							t = (ax + az)/(ax + az - bx - bz);
							ax += (bx - ax)*t;
							ay += (by - ay)*t;
							az += (bz - az)*t;
						} else if (bz <= -bx && az > -ax) {
							t = (ax + az)/(ax + az - bx - bz);
							bx = ax + (bx - ax)*t;
							by = ay + (by - ay)*t;
							bz = az + (bz - az)*t;
						}
						if (az <= ax && bz <= bx) {
							if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
							continue;
						} else if (bz > bx && az <= ax) {
							t = (az - ax)/(az - ax + bx - bz);
							ax += (bx - ax)*t;
							ay += (by - ay)*t;
							az += (bz - az)*t;
						} else if (bz <= bx && az > ax) {
							t = (az - ax)/(az - ax + bx - bz);
							bx = ax + (bx - ax)*t;
							by = ay + (by - ay)*t;
							bz = az + (bz - az)*t;
						}
						if (az <= -ay && bz <= -by) {
							if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
							continue;
						} else if (bz > -by && az <= -ay) {
							t = (ay + az)/(ay + az - by - bz);
							ax += (bx - ax)*t;
							ay += (by - ay)*t;
							az += (bz - az)*t;
						} else if (bz <= -by && az > -ay) {
							t = (ay + az)/(ay + az - by - bz);
							bx = ax + (bx - ax)*t;
							by = ay + (by - ay)*t;
							bz = az + (bz - az)*t;
						}
						if (az <= ay && bz <= by) {
							if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
							continue;
						} else if (bz > by && az <= ay) {
							t = (az - ay)/(az - ay + by - bz);
							ax += (bx - ax)*t;
							ay += (by - ay)*t;
							az += (bz - az)*t;
						} else if (bz <= by && az > ay) {
							t = (az - ay)/(az - ay + by - bz);
							bx = ax + (bx - ax)*t;
							by = ay + (by - ay)*t;
							bz = az + (bz - az)*t;
						}
						occludeAll = false;
					}
					// Создание новой плоскости
					a = a.create();
					a.next = occluder;
					num++;
					occluder = a;
					// Плоскость
					occluder.cameraX = bz*ay - by*az;
					occluder.cameraY = bx*az - bz*ax;
					occluder.cameraZ = by*ax - bx*ay;
					// Ребро (для перевода в систему контейнера)
					occluder.x = ax;
					occluder.y = ay;
					occluder.z = az;
					occluder.u = bx;
					occluder.v = by;
					occluder.offset = bz;
				}
			}
			// Если контур не нулевой
			if (occluder != null) {
				// Проверка размера на экране
				if (minSize > 0) {
					// Проецирование рёбер контура
					var projected:Vertex = Vertex.createList(num);
					for (a = occluder,b = projected; a != null; a = a.next,b = b.next) {
						// Проецтрование
						b.x = a.x*viewSizeX/a.z;
						b.y = a.y*viewSizeY/a.z;
						b.u = a.u*viewSizeX/a.offset;
						b.v = a.v*viewSizeY/a.offset;
						// Расчёт левой нормали
						b.cameraX = b.y - b.v;
						b.cameraY = b.u - b.x;
						b.offset = b.cameraX*b.x + b.cameraY*b.y;
					}
					// Клиппинг рамки вьюпорта по рёбрам контура
					var frame:Vertex;
					if (culling > 0) {
						if (culling & 4) {
							ax = -camera.viewSizeX;
							ay = -camera.viewSizeY;
							bx = -camera.viewSizeX;
							by = camera.viewSizeY;
							for (a = projected; a != null; a = a.next) {
								az = ax*a.cameraX + ay*a.cameraY - a.offset;
								bz = bx*a.cameraX + by*a.cameraY - a.offset;
								if (az < 0 || bz < 0) {
									if (az >= 0 && bz < 0) {
										t = az/(az - bz);
										ax += (bx - ax)*t;
										ay += (by - ay)*t;
									} else if (az < 0 && bz >= 0) {
										t = az/(az - bz);
										bx = ax + (bx - ax)*t;
										by = ay + (by - ay)*t;
									}
								} else break;
							}
							if (a == null) {
								b = occluder.create();
								b.next = frame;
								frame = b;
								frame.x = ax;
								frame.y = ay;
								frame.u = bx;
								frame.v = by;
							}
						}
						if (culling & 8) {
							ax = camera.viewSizeX;
							ay = camera.viewSizeY;
							bx = camera.viewSizeX;
							by = -camera.viewSizeY;
							for (a = projected; a != null; a = a.next) {
								az = ax*a.cameraX + ay*a.cameraY - a.offset;
								bz = bx*a.cameraX + by*a.cameraY - a.offset;
								if (az < 0 || bz < 0) {
									if (az >= 0 && bz < 0) {
										t = az/(az - bz);
										ax += (bx - ax)*t;
										ay += (by - ay)*t;
									} else if (az < 0 && bz >= 0) {
										t = az/(az - bz);
										bx = ax + (bx - ax)*t;
										by = ay + (by - ay)*t;
									}
								} else break;
							}
							if (a == null) {
								b = occluder.create();
								b.next = frame;
								frame = b;
								frame.x = ax;
								frame.y = ay;
								frame.u = bx;
								frame.v = by;
							}
						}
						if (culling & 16) {
							ax = camera.viewSizeX;
							ay = -camera.viewSizeY;
							bx = -camera.viewSizeX;
							by = -camera.viewSizeY;
							for (a = projected; a != null; a = a.next) {
								az = ax*a.cameraX + ay*a.cameraY - a.offset;
								bz = bx*a.cameraX + by*a.cameraY - a.offset;
								if (az < 0 || bz < 0) {
									if (az >= 0 && bz < 0) {
										t = az/(az - bz);
										ax += (bx - ax)*t;
										ay += (by - ay)*t;
									} else if (az < 0 && bz >= 0) {
										t = az/(az - bz);
										bx = ax + (bx - ax)*t;
										by = ay + (by - ay)*t;
									}
								} else break;
							}
							if (a == null) {
								b = occluder.create();
								b.next = frame;
								frame = b;
								frame.x = ax;
								frame.y = ay;
								frame.u = bx;
								frame.v = by;
							}
						}
						if (culling & 32) {
							ax = -camera.viewSizeX;
							ay = camera.viewSizeY;
							bx = camera.viewSizeX;
							by = camera.viewSizeY;
							for (a = projected; a != null; a = a.next) {
								az = ax*a.cameraX + ay*a.cameraY - a.offset;
								bz = bx*a.cameraX + by*a.cameraY - a.offset;
								if (az < 0 || bz < 0) {
									if (az >= 0 && bz < 0) {
										t = az/(az - bz);
										ax += (bx - ax)*t;
										ay += (by - ay)*t;
									} else if (az < 0 && bz >= 0) {
										t = az/(az - bz);
										bx = ax + (bx - ax)*t;
										by = ay + (by - ay)*t;
									}
								} else break;
							}
							if (a == null) {
								b = occluder.create();
								b.next = frame;
								frame = b;
								frame.x = ax;
								frame.y = ay;
								frame.u = bx;
								frame.v = by;
							}
						}
					}
					// Нахождение площади перекрытия
					var square:Number = 0;
					az = projected.x;
					bz = projected.y;
					a = projected;
					while (a.next != null) a = a.next;
					for (a.next = frame,a = projected; a != null; a = a.next) {
						square += (a.u - az)*(a.y - bz) - (a.v - bz)*(a.x - az);
						if (a.next == null) break;
					}
					// Зачистка
					a.next = Vertex.collector;
					Vertex.collector = projected;
					// Если площадь меньше заданной
					if (square/(camera.viewSizeX*camera.viewSizeY*8) < minSize) {
						// Зачистка
						a = occluder;
						while (a.next != null) a = a.next;
						a.next = Vertex.collector;
						Vertex.collector = occluder;
						return;
					}
				}
				// Дебаг
				if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
					canvas = parentCanvas.getChildCanvas(true, false);
					if (debug & Debug.EDGES) {
						for (a = occluder; a != null; a = a.next) {
							ax = a.x*viewSizeX/a.z;
							ay = a.y*viewSizeY/a.z;
							bx = a.u*viewSizeX/a.offset;
							by = a.v*viewSizeY/a.offset;
							canvas.gfx.moveTo(ax, ay);
							canvas.gfx.lineStyle(3, 0x0000FF);
							canvas.gfx.lineTo(ax + (bx - ax)*0.8, ay + (by - ay)*0.8);
							canvas.gfx.lineStyle(3, 0xFF0000);
							canvas.gfx.lineTo(bx, by);
						}
					}
					if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, this, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
				}
				// Добавление окклюдера в камеру
				camera.occluders[camera.numOccluders] = occluder;
				camera.numOccluders++;
				// Если окклюдер перекрывает весь экран
			} else if (occludeAll) {
				// Дебаг
				if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
					canvas = parentCanvas.getChildCanvas(true, false);
					if (debug & Debug.EDGES) {
						t = 1.5;
						canvas.gfx.moveTo(-viewSizeX + t, -viewSizeY + t);
						canvas.gfx.lineStyle(3, 0x0000FF);
						canvas.gfx.lineTo(-viewSizeX + t, viewSizeY*0.6);
						canvas.gfx.lineStyle(3, 0xFF0000);
						canvas.gfx.lineTo(-viewSizeX + t, viewSizeY - t);
						canvas.gfx.lineStyle(3, 0x0000FF);
						canvas.gfx.lineTo(viewSizeX*0.6, viewSizeY - t);
						canvas.gfx.lineStyle(3, 0xFF0000);
						canvas.gfx.lineTo(viewSizeX - t, viewSizeY - t);
						canvas.gfx.lineStyle(3, 0x0000FF);
						canvas.gfx.lineTo(viewSizeX - t, -viewSizeY*0.6);
						canvas.gfx.lineStyle(3, 0xFF0000);
						canvas.gfx.lineTo(viewSizeX - t, -viewSizeY + t);
						canvas.gfx.lineStyle(3, 0x0000FF);
						canvas.gfx.lineTo(-viewSizeX*0.6, -viewSizeY + t);
						canvas.gfx.lineStyle(3, 0xFF0000);
						canvas.gfx.lineTo(-viewSizeX + t, -viewSizeY + t);
					}
					if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, this, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
				}
				camera.clearOccluders();
				camera.occludedAll = true;
			}
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) {
				if (transformation != null) {
					vertex.cameraX = transformation.ma*vertex.x + transformation.mb*vertex.y + transformation.mc*vertex.z + transformation.md;
					vertex.cameraY = transformation.me*vertex.x + transformation.mf*vertex.y + transformation.mg*vertex.z + transformation.mh;
					vertex.cameraZ = transformation.mi*vertex.x + transformation.mj*vertex.y + transformation.mk*vertex.z + transformation.ml;
				} else {
					vertex.cameraX = vertex.x;
					vertex.cameraY = vertex.y;
					vertex.cameraZ = vertex.z;
				}
				if (vertex.cameraX < bounds.boundMinX) bounds.boundMinX = vertex.cameraX;
				if (vertex.cameraX > bounds.boundMaxX) bounds.boundMaxX = vertex.cameraX;
				if (vertex.cameraY < bounds.boundMinY) bounds.boundMinY = vertex.cameraY;
				if (vertex.cameraY > bounds.boundMaxY) bounds.boundMaxY = vertex.cameraY;
				if (vertex.cameraZ < bounds.boundMinZ) bounds.boundMinZ = vertex.cameraZ;
				if (vertex.cameraZ > bounds.boundMaxZ) bounds.boundMaxZ = vertex.cameraZ;
			}
		}
		
	}
}

import alternativa.engine3d.core.Face;
import alternativa.engine3d.core.Vertex;

class Edge {

	public var next:Edge;

	public var a:Vertex;
	public var b:Vertex;

	public var left:Face;
	public var right:Face;

}
