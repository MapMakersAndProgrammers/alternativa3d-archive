package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	
	use namespace alternativa3d;
	
	/**
	 * Полигональный объект-перекрытие.
	 * Объекты, которые он перекрывает от видимости камеры, исключаются из отрисовки.
	 * Сам окклюдер не отрисовывается.
	 * Должен быть конвексным
	 */
	public class Occluder extends Object3D {
	
		public var faceList:Face;
		public var edgeList:Edge;
		public var vertexList:Vertex;
	
		/**
		 * Минимальное отношение площади перекрытия окклюдером вьюпорта к площади вьюпорта (от 0 до 1)
		 * Если окклюдер перекрывает больше, он помещается в очередь и учитывается
		 * при дальнейшей отрисовке в пределах кадра, иначе игнорируется
		 */
		public var minSize:Number = 0;
	
		/**
		 * Копирование геометрии меша
		 * @param source Объект копирования
		 * Меш, геометрия которого копируется, обязан быть конвексным, иначе окклюдер будет некорректно работать
		 */
		public function copyFrom(source:Mesh):void {
			x = source.x;
			y = source.y;
			z = source.z;
			rotationX = source.rotationX;
			rotationY = source.rotationY;
			rotationZ = source.rotationZ;
			scaleX = source.scaleX;
			scaleY = source.scaleY;
			scaleZ = source.scaleZ;
			boundMinX = source.boundMinX;
			boundMinY = source.boundMinY;
			boundMinZ = source.boundMinZ;
			boundMaxX = source.boundMaxX;
			boundMaxY = source.boundMaxY;
			boundMaxZ = source.boundMaxZ;
	
			faceList = source.faceList;
			vertexList = source.vertexList;
		}
	
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
	
		/**
		 * Расчёт рёбер по имеющимся вершинам и граням
		 */
		public function calculateEdges():void {
			var face:Face;
			var wrapper:Wrapper;
			var edge:Edge;
			// Построение рёбер
			edgeList = null;
			for (face = faceList; face != null; face = face.next) {
				// Расчёт нормали
				face.calculateBestSequenceAndNormal();
				// Перебор отрезков грани
				var a:Vertex;
				var b:Vertex;
				for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next,a = b) {
					a = wrapper.vertex;
					b = (wrapper.next != null) ? wrapper.next.vertex : face.wrapper.vertex;
					// Перебор созданных рёбер
					for (edge = edgeList; edge != null; edge = edge.next) {
						// Если некорректная геометрия
						if (edge.a == a && edge.b == b) {
							trace("Incorrect face joint");
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
				var abx:Number = edge.b.x - edge.a.x;
				var aby:Number = edge.b.y - edge.a.y;
				var abz:Number = edge.b.z - edge.a.z;
				var crx:Number = edge.right.normalZ*edge.left.normalY - edge.right.normalY*edge.left.normalZ;
				var cry:Number = edge.right.normalX*edge.left.normalZ - edge.right.normalZ*edge.left.normalX;
				var crz:Number = edge.right.normalY*edge.left.normalX - edge.right.normalX*edge.left.normalY;
				// Если перегиб внутрь
				if (abx*crx + aby*cry + abz*crz < 0) {
					trace("Geometry is non convex");
				}
				// Если ребро с одной гранью
				if (edge.left == null || edge.right == null) {
					trace("Geometry is non whole");
				}
			}
		}
	
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			if (faceList == null || edgeList == null) return;
			var canvas:Canvas;
			var debug:int;
			// Расчёт инверсной матрицы камеры
			calculateInverseMatrix(object);
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
			var culling:int = object.culling;
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
					ax = object.ma*a.x + object.mb*a.y + object.mc*a.z + object.md;
					ay = object.me*a.x + object.mf*a.y + object.mg*a.z + object.mh;
					az = object.mi*a.x + object.mj*a.y + object.mk*a.z + object.ml;
					bx = object.ma*b.x + object.mb*b.y + object.mc*b.z + object.md;
					by = object.me*b.x + object.mf*b.y + object.mg*b.z + object.mh;
					bz = object.mi*b.x + object.mj*b.y + object.mk*b.z + object.ml;
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
					canvas = parentCanvas.getChildCanvas(object, true, false);
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
					if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
				}
				// Добавление окклюдера в камеру
				camera.occluders[camera.numOccluders] = occluder;
				camera.numOccluders++;
				// Если окклюдер перекрывает весь экран
			} else if (occludeAll) {
				// Дебаг
				if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
					canvas = parentCanvas.getChildCanvas(object, true, false);
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
					if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
				}
				camera.clearOccluders();
				camera.occludedAll = true;
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
