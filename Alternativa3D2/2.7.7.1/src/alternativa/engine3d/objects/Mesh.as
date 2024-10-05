package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.VG;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.materials.Material;
	
	import flash.utils.Dictionary;
	import flash.geom.Matrix3D;
	import __AS3__.vec.Vector;
	import alternativa.engine3d.core.Geometry;
	import flash.geom.Vector3D;
	import alternativa.engine3d.core.RayIntersectionData;
	
	use namespace alternativa3d;
	
	/**
	 * Полигональный объект, состоящий из вершин и граней, построенных по этим вершинам.
	 * @see alternativa.engine3d.core.Vertex
	 * @see alternativa.engine3d.core.Face
	 */
	public class Mesh extends Object3D {
	
		/**
		 * Режим отсечения объекта по пирамиде видимости камеры.
		 * Можно использовать следующие константы <code>Clipping</code> для указания свойства <code>clipping</code>: <code>Clipping.BOUND_CULLING</code>, <code>Clipping.FACE_CULLING</code>, <code>Clipping.FACE_CLIPPING</code>.
		 * Значение по умолчанию <code>Clipping.FACE_CLIPPING</code>.
		 * @see alternativa.engine3d.core.Clipping
		 */
		public var clipping:int = 2;
		
		/**
		 * Режим сортировки граней.
		 * Можно использовать следующие константы <code>Sorting</code> для указания свойства <code>sorting</code>: <code>Sorting.NONE</code>, <code>Sorting.AVERAGE_Z</code>, <code>Sorting.DYNAMIC_BSP</code>.
		 * Значение по умолчанию <code>Sorting.AVERAGE_Z</code>.
		 * @see alternativa.engine3d.core.Sorting
		 */
		public var sorting:int = 1;
		
		/**
		 * Геометрическая погрешность.
		 * Это малая величина, в пределах которой разницей значений можно пренебречь.
		 * Учитывается при построении временного BSP-дерева в режиме сортировки <code>Sorting.DYNAMIC_BSP</code>.
		 * Значение по умолчанию — <code>0.01</code>.
		 * @see alternativa.engine3d.core.Sorting
		 */
		public var threshold:Number = 0.01;
	
		/**
		 * @private 
		 */
		alternativa3d var vertexList:Vertex;
		
		/**
		 * @private 
		 */
		alternativa3d var faceList:Face;
	
		/**
		 * Список экземпляров вершин.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function get vertices():Vector.<Vertex> {
			var res:Vector.<Vertex> = new Vector.<Vertex>();
			var len:int = 0;
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) {
				res[len] = vertex;
				len++;
			}
			return res;
		}
		
		/**
		 * Список экземпляров граней.
		 * @see alternativa.engine3d.core.Face
		 */
		public function get faces():Vector.<Face> {
			var res:Vector.<Face> = new Vector.<Face>();
			var len:int = 0;
			for (var face:Face = faceList; face != null; face = face.next) {
				res[len] = face;
				len++;
			}
			return res;
		}
		
		/**
		 * Геометрия объекта.
		 * При получении и установке геометрии происходит клонирование вершин и граней.
		 * @see alternativa.engine3d.core.Geometry
		 * @see alternativa.engine3d.core.Vertex
		 * @see alternativa.engine3d.core.Face
		 */
		public function get geometry():Geometry {
			var res:Geometry = new Geometry();
			var vertex:Vertex;
			// Клонирование вершин
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				var newVertex:Vertex = new Vertex();
				newVertex.x = vertex.x;
				newVertex.y = vertex.y;
				newVertex.z = vertex.z;
				newVertex.u = vertex.u;
				newVertex.v = vertex.v;
				vertex.value = newVertex;
				res._vertices[res.vertexIdCounter] = newVertex;
				res.vertexIdCounter++;
			}
			// Клонирование граней
			for (var face:Face = faceList; face != null; face = face.next) {
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
				res._faces[res.faceIdCounter] = newFace;
				res.faceIdCounter++;
			}
			// Сброс после ремапа
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
			return res;
		}
		
		/**
		 * @private
		 */
		public function set geometry(value:Geometry):void {
			vertexList = null;
			faceList = null;
			if (value != null) {
				var i:int;
				var vertex:Vertex;
				var orderedVertices:Vector.<Vertex> = value.orderedVertices;
				var orderedVerticesLength:int = orderedVertices.length;
				var orderedFaces:Vector.<Face> = value.orderedFaces;
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
					if (lastVertex != null) {
						lastVertex.next = newVertex;
					} else {
						vertexList = newVertex;
					}
					lastVertex = newVertex;
				}
				// Клонирование граней
				var lastFace:Face;
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
					if (lastFace != null) {
						lastFace.next = newFace;
					} else {
						faceList = newFace;
					}
					lastFace = newFace;
				}
				// Расчёт нормалей
				calculateNormals(true);
				// Сброс после ремапа
				for (i = 0; i < orderedVerticesLength; i++) {
					vertex = orderedVertices[i];
					vertex.value = null;
				}
			}
		}
		
		/**
		 * Переносит экземпляры вершин и граней в новый объект класса <code>Geometry</code>.
		 * После переноса списки вершин и граней остаются пустыми.
		 * @return Новый объект класса <code>Geometry</code>, содержащий оригинальные экземпляры вершин и граней.
		 * @see alternativa.engine3d.core.Geometry
		 * @see alternativa.engine3d.core.Vertex
		 * @see alternativa.engine3d.core.Face
		 */
		public function removeGeometry():Geometry {
			var res:Geometry = new Geometry();
			// Перенос вершин
			for (var vertex:Vertex = vertexList; vertex != null; vertex = nextVertex) {
				var nextVertex:Vertex = vertex.next;
				vertex.next = null;
				res._vertices[res.vertexIdCounter] = vertex;
				res.vertexIdCounter++;
			}
			vertexList = null;
			// Перенос граней
			for (var face:Face = faceList; face != null; face = nextFace) {
				var nextFace:Face = face.next;
				face.next = null;
				res._faces[res.faceIdCounter] = face;
				res.faceIdCounter++;
			}
			faceList = null;
			return res;
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
			vertexList = null;
			faceList = null;
			var i:int;
			var orderedVertices:Vector.<Vertex> = geometry.orderedVertices;
			var orderedVerticesLength:int = orderedVertices.length;
			var orderedFaces:Vector.<Face> = geometry.orderedFaces;
			var orderedFacesLength:int = orderedFaces.length;
			geometry._vertices = new Dictionary();
			geometry._faces = new Dictionary();
			geometry.vertexIdCounter = 0;
			geometry.faceIdCounter = 0;
			// Перенос вершин
			var lastVertex:Vertex;
			for (i = 0; i < orderedVerticesLength; i++) {
				var vertex:Vertex = orderedVertices[i];
				vertex.transformId = 0;
				if (lastVertex != null) {
					lastVertex.next = vertex;
				} else {
					vertexList = vertex;
				}
				lastVertex = vertex;
			}
			// Перенос граней
			var lastFace:Face;
			for (i = 0; i < orderedFacesLength; i++) {
				var face:Face = orderedFaces[i];
				if (lastFace != null) {
					lastFace.next = face;
				} else {
					faceList = face;
				}
				lastFace = face;
			}
			// Расчёт нормалей
			calculateNormals(true);
		}
		
		/**
		 * Сливает вершины с одинаковыми координатами и UV и объединяет соседние грани, образующие плоский выпуклый многоугольник.
		 * @param distanceThreshold Погрешность, в пределах которой координаты считаются одинаковыми.
		 * @param uvThreshold Погрешность, в пределах которой UV-координаты считаются одинаковыми.
		 * @param angleThreshold Допустимый угол в радианах между нормалями, чтобы считать, что объединяемые грани в одной плоскости.
		 * @param convexThreshold Величина, уменьшающая допустимый угол между смежными рёбрами объединяемых граней.
		 * @param pairWeld Флаг объединения попарно.
		 * @see alternativa.engine3d.core.Vertex
		 * @see alternativa.engine3d.core.Face
		 */
		public function weldVerticesAndFaces(distanceThreshold:Number = 0, uvThreshold:Number = 0, angleThreshold:Number = 0, convexThreshold:Number = 0, pairWeld:Boolean = false):void {
			var geometry:Geometry = removeGeometry();
			geometry.weldVertices(distanceThreshold, uvThreshold);
			geometry.weldFaces(angleThreshold, uvThreshold, convexThreshold, pairWeld);
			takeGeometryFrom(geometry);
		}
		
		/**
		 * Устанавливает материал всем граням.
		 * @param material Устанавливаемы материал.
		 * @see alternativa.engine3d.materials.Material
		 * @see alternativa.engine3d.core.Face
		 */
		public function setMaterialToAllFaces(material:Material):void {
			for (var face:Face = faceList; face != null; face = face.next) {
				face.material = material;
			}
		}
		
		/**
		 * Расчитывает нормали граней.
		 * @param normalize Флаг нормализации. Если <code>true</code>, то длины нормалей будут равны единице.
		 * @see alternativa.engine3d.core.Face
		 */
		public function calculateNormals(normalize:Boolean = true):void {
			for (var face:Face = faceList; face != null; face = face.next) {
				var w:Wrapper = face.wrapper;
				var a:Vertex = w.vertex;
				w = w.next;
				var b:Vertex = w.vertex;
				w = w.next;
				var c:Vertex = w.vertex;
				var abx:Number = b.x - a.x;
				var aby:Number = b.y - a.y;
				var abz:Number = b.z - a.z;
				var acx:Number = c.x - a.x;
				var acy:Number = c.y - a.y;
				var acz:Number = c.z - a.z;
				var nx:Number = acz*aby - acy*abz;
				var ny:Number = acx*abz - acz*abx;
				var nz:Number = acy*abx - acx*aby;
				if (normalize) {
					var length:Number = nx*nx + ny*ny + nz*nz;
					if (length > 0.001) {
						length = 1/Math.sqrt(length);
						nx *= length;
						ny *= length;
						nz *= length;
					}
				}
				face.normalX = nx;
				face.normalY = ny;
				face.normalZ = nz;
				face.offset = a.x*nx + a.y*ny + a.z*nz;
			}
		}
	
		/**
		 * Выстраивает грани в определённую последовательность, чтобы минимизировать количество рассечений в режиме сортировки <code>Sorting.DYNAMIC_BSP</code>.
		 * @param iterations Параметр, влияющий на качество анализа. Чем больше это число, тем лучше последовательность, но и тем больше время выполнения метода. Нет смысла указывать число, больше, чем количество граней.
		 * @see alternativa.engine3d.core.Face
		 * @see alternativa.engine3d.core.Sorting
		 */
		public function optimizeForDynamicBSP(iterations:int = 1):void {
			var list:Face = faceList;
			var last:Face;
			for (var i:int = 0; i < iterations; i++) {
				var prev:Face = null;
				for (var face:Face = list; face != null; face = face.next) {
					var normalX:Number = face.normalX;
					var normalY:Number = face.normalY;
					var normalZ:Number = face.normalZ;
					var offset:Number = face.offset;
					var offsetMin:Number = offset - threshold;
					var offsetMax:Number = offset + threshold;
					var splits:int = 0;
					for (var f:Face = list; f != null; f = f.next) {
						if (f != face) {
							var w:Wrapper = f.wrapper;
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
								if (splits > i) break;
							}
						}
					}
					if (f == null) {
						if (prev != null) {
							prev.next = face.next;
						} else {
							list = face.next;
						}
						if (last != null) {
							last.next = face;
						} else {
							faceList = face;
						}
						last = face;
					} else {
						prev = face;
					}
				}
				if (list == null) break;
			}
			if (last != null) {
				last.next = list;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function calculateResolution(textureWidth:int, textureHeight:int, type:int = 1, matrix:Matrix3D = null):Number {
			var object:Object3D;
			if (matrix != null) {
				object = new Object3D();
				object.matrix = matrix;
				object.composeMatrix();
			}
			var min:Number = 1e+22;
			var max:Number = 0;
			var sum:Number = 0;
			var num:int = 0;
			for (var face:Face = faceList; face != null; face = face.next) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var a:Vertex = wrapper.vertex;
					var b:Vertex = wrapper.next != null ? wrapper.next.vertex : face.wrapper.vertex;
					var dx:Number = (object != null) ? (object.ma*(b.x - a.x) + object.mb*(b.y - a.y) + object.mc*(b.z - a.z)) : (b.x - a.x);
					var dy:Number = (object != null) ? (object.me*(b.x - a.x) + object.mf*(b.y - a.y) + object.mg*(b.z - a.z)) : (b.y - a.y);
					var dz:Number = (object != null) ? (object.mi*(b.x - a.x) + object.mj*(b.y - a.y) + object.mk*(b.z - a.z)) : (b.z - a.z);
					var du:Number = (b.u - a.u)*textureWidth;
					var dv:Number = (b.v - a.v)*textureHeight;
					var xyz:Number = dx*dx + dy*dy + dz*dz;
					var uv:Number = du*du + dv*dv;
					if (xyz > 0.001 && uv > 0.001) {
						var res:Number = Math.sqrt(xyz/uv);
						if (res < min) min = res;
						if (res > max) max = res;
						sum += res;
						num++;
						if (type == 0) break;
					}
				}
			}
			if (num == 0) return 1;
			return (type < 2) ? sum/num : ((type == 2) ? min : max);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function intersectRay(origin:Vector3D, direction:Vector3D, exludedObjects:Dictionary = null, camera:Camera3D = null):RayIntersectionData {
			if (exludedObjects != null && exludedObjects[this]) return null;
			if (!boundIntersectRay(origin, direction, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ)) return null;
			var ox:Number = origin.x;
			var oy:Number = origin.y;
			var oz:Number = origin.z;
			var dx:Number = direction.x;
			var dy:Number = direction.y;
			var dz:Number = direction.z;
			var point:Vector3D;
			var face:Face;
			var minTime:Number = 1e+22;
			for (var f:Face = faceList; f != null; f = f.next) {
				var normalX:Number = f.normalX;
				var normalY:Number = f.normalY;
				var normalZ:Number = f.normalZ;
				var dot:Number = dx*normalX + dy*normalY + dz*normalZ;
				if (dot < 0) {
					var offset:Number = ox*normalX + oy*normalY + oz*normalZ - f.offset;
					if (offset > 0) {
						var time:Number = -offset/dot;
						if (point == null || time < minTime) {
							var cx:Number = ox + dx*time;
							var cy:Number = oy + dy*time;
							var cz:Number = oz + dz*time;
							var wrapper:Wrapper;
							for (wrapper = f.wrapper; wrapper != null; wrapper = wrapper.next) {
								var a:Vertex = wrapper.vertex;
								var b:Vertex = (wrapper.next != null) ? wrapper.next.vertex : f.wrapper.vertex;
								var abx:Number = b.x - a.x;
								var aby:Number = b.y - a.y;
								var abz:Number = b.z - a.z;
								var acx:Number = cx - a.x;
								var acy:Number = cy - a.y;
								var acz:Number = cz - a.z;
								if ((acz*aby - acy*abz)*normalX + (acx*abz - acz*abx)*normalY + (acy*abx - acx*aby)*normalZ < 0) break;
							}
							if (wrapper == null) {
								if (time < minTime) {
									minTime = time;
									if (point == null) point = new Vector3D();
									point.x = cx;
									point.y = cy;
									point.z = cz;
									face = f;
								}
							}
						}
					}
				}
			}
			if (point != null) {
				var res:RayIntersectionData = new RayIntersectionData();
				res.object = this;
				res.face = face;
				res.point = point;
				res.time = minTime;
				return res;
			} else {
				return null;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Mesh = new Mesh();
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:Mesh = source as Mesh;
			clipping = src.clipping;
			sorting = src.sorting;
			threshold = src.threshold;
			// Клонирование вершин
			var vertex:Vertex;
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
			for (var face:Face = src.faceList; face != null; face = face.next) {
				var newFace:Face = new Face();
				newFace.material = face.material;
				newFace.normalX = face.normalX;
				newFace.normalY = face.normalY;
				newFace.normalZ = face.normalZ;
				newFace.offset = face.offset;
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
			// Сброс после ремапа
			for (vertex = src.vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas):void {
			if (faceList == null) return;
			// Коррекция куллинга
			if (clipping == 0) {
				if (culling & 1) return;
				culling = 0;
			}
			// Итератор трансформаций
			if (transformId > 500000000) {
				transformId = 0;
				for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) vertex.transformId = 0;
			}
			transformId++;
			// Расчёт инверсной матрицы камеры
			calculateInverseMatrix();
			// Подготовка граней
			var list:Face = prepareFaces(camera);
			if (list == null) return;
			// Отсечение по пирамиде видимости
			if (culling > 0) {
				if (clipping == 1) {
					list = camera.cull(list, culling);
				} else {
					list = camera.clip(list, culling);
				}
				if (list == null) return;
			}
			// Сортировка
			if (list.processNext != null) {
				if (sorting == 1) {
					list = camera.sortByAverageZ(list);
				} else if (sorting == 2) {
					list = camera.sortByDynamicBSP(list, threshold);
				}
			}
			// Дебаг
			if (camera.debug) {
				var debug:int = camera.checkInDebug(this);
				if (debug > 0) drawDebug(camera, parentCanvas.getChildCanvas(true, false), list, debug);
			}
			// Отрисовка
			drawFaces(camera, parentCanvas.getChildCanvas(true, false, this, alpha, blendMode, colorTransform, filters), list);
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function getVG(camera:Camera3D):VG {
			if (faceList == null) return null;
			// Сброс итератора трансформаций
			if (transformId > 500000000) {
				transformId = 0;
				for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) vertex.transformId = 0;
			}
			transformId++;
			// Коррекция куллинга
			if (clipping == 0) {
				if (culling & 1) return null;
				culling = 0;
			}
			// Расчёт инверсной матрицы камеры
			calculateInverseMatrix();
			// Подготовка граней
			var list:Face = prepareFaces(camera);
			if (list == null) return null;
			// Отсечение по пирамиде видимости
			if (culling > 0) {
				if (clipping == 1) {
					list = camera.cull(list, culling);
				} else {
					list = camera.clip(list, culling);
				}
				if (list == null) return null;
			}
			// Создание геометрии
			return VG.create(this, list, sorting, camera.debug ? camera.checkInDebug(this) : 0, false);
		}
		
		/**
		 * @private 
		 */
		alternativa3d function prepareFaces(camera:Camera3D):Face {
			var first:Face;
			var last:Face;
			for (var face:Face = faceList; face != null; face = face.next) {
				// Отсечение по видимости
				if (face.normalX*imd + face.normalY*imh + face.normalZ*iml > face.offset) {
					for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
						var vertex:Vertex = wrapper.vertex;
						// Трансформация
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
					if (first != null) {
						last.processNext = face;
					} else {
						first = face;
					}
					last = face;
				}
			}
			if (last != null) last.processNext = null;
			return first;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function drawDebug(camera:Camera3D, canvas:Canvas, list:Face, debug:int):void {
			if (debug & Debug.EDGES) Debug.drawEdges(camera, canvas, list, 0xFFFFFF);
			if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, this, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
		}
		
		/**
		 * @private 
		 */
		alternativa3d function drawFaces(camera:Camera3D, canvas:Canvas, list:Face):void {
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
		
		/**
		 * @private 
		 */
		override alternativa3d function split(a:Vector3D, b:Vector3D, c:Vector3D, threshold:Number):Vector.<Object3D> {
			var res:Vector.<Object3D> = new Vector.<Object3D>(2);
			// Расчёт плоскости
			var plane:Vector3D = calculatePlane(a, b, c);
			var offsetMin:Number = plane.w - threshold;
			var offsetMax:Number = plane.w + threshold;
			// Подготовка к разделению
			var v:Vertex;
			var	nextVertex:Vertex;
			for (v = vertexList; v != null; v = nextVertex) {
				nextVertex = v.next;
				v.next = null;
				v.offset = v.x*plane.x + v.y*plane.y + v.z*plane.z;
				if (v.offset >= offsetMin && v.offset <= offsetMax) {
					v.value = new Vertex();
					v.value.x = v.x;
					v.value.y = v.y;
					v.value.z = v.z;
					v.value.u = v.u;
					v.value.v = v.v;
				}
				v.transformId = 0;
			}
			vertexList = null;
			var faceList:Face = this.faceList;
			this.faceList = null;
			// Разделение
			var negativeMesh:Mesh = clone() as Mesh;
			var positiveMesh:Mesh = clone() as Mesh;
			var negativeLast:Face;
			var positiveLast:Face;
			for (var face:Face = faceList; face != null; face = next) {
				var next:Face = face.next;
				var w:Wrapper = face.wrapper;
				var va:Vertex = w.vertex;
				w = w.next;
				var vb:Vertex = w.vertex;
				w = w.next;
				var vc:Vertex = w.vertex;
				var behind:Boolean = va.offset < offsetMin || vb.offset < offsetMin || vc.offset < offsetMin;
				var infront:Boolean = va.offset > offsetMax || vb.offset > offsetMax || vc.offset > offsetMax;
				for (w = w.next; w != null; w = w.next) {
					v = w.vertex;
					if (v.offset < offsetMin) {
						behind = true;
					} else if (v.offset > offsetMax) {
						infront = true;
					}
				}
				if (!behind) {
					if (positiveLast != null) {
						positiveLast.next = face;
					} else {
						positiveMesh.faceList = face;
					}
					positiveLast = face;
				} else if (!infront) {
					if (negativeLast != null) {
						negativeLast.next = face;
					} else {
						negativeMesh.faceList = face;
					}
					negativeLast = face;
					for (w = face.wrapper; w != null; w = w.next) {
						if (w.vertex.value != null) {
							w.vertex = w.vertex.value;
						}
					}
				} else {
					var negative:Face = new Face();
					var positive:Face = new Face();
					var wNegative:Wrapper = null;
					var wPositive:Wrapper = null;
					var wNew:Wrapper;
					w = face.wrapper.next.next;
					while (w.next != null) {
						w = w.next;
					}
					va = w.vertex;
					for (w = face.wrapper; w != null; w = w.next) {
						vb = w.vertex;
						if (va.offset < offsetMin && vb.offset > offsetMax || va.offset > offsetMax && vb.offset < offsetMin) {
							var t:Number = (plane.w - va.offset)/(vb.offset - va.offset);
							v = new Vertex();
							v.x = va.x + (vb.x - va.x)*t;
							v.y = va.y + (vb.y - va.y)*t;
							v.z = va.z + (vb.z - va.z)*t;
							v.u = va.u + (vb.u - va.u)*t;
							v.v = va.v + (vb.v - va.v)*t;
							wNew = new Wrapper();
							wNew.vertex = v;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
							var v2:Vertex = new Vertex();
							v2.x = v.x;
							v2.y = v.y;
							v2.z = v.z;
							v2.u = v.u;
							v2.v = v.v;
							wNew = new Wrapper();
							wNew.vertex = v2;
							if (wPositive != null) {
								wPositive.next = wNew;
							} else {
								positive.wrapper = wNew;
							}
							wPositive = wNew;
						}
						if (vb.offset < offsetMin) {
							wNew = w.create();
							wNew.vertex = vb;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
						} else if (vb.offset > offsetMax) {
							wNew = w.create();
							wNew.vertex = vb;
							if (wPositive != null) {
								wPositive.next = wNew;
							} else {
								positive.wrapper = wNew;
							}
							wPositive = wNew;
						} else {
							wNew = w.create();
							wNew.vertex = vb.value;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
							wNew = w.create();
							wNew.vertex = vb;
							if (wPositive != null) {
								wPositive.next = wNew;
							} else {
								positive.wrapper = wNew;
							}
							wPositive = wNew;
						}
						va = vb;
					}
					negative.material = face.material;
					negative.calculateBestSequenceAndNormal();
					if (negativeLast != null) {
						negativeLast.next = negative;
					} else {
						negativeMesh.faceList = negative;
					}
					negativeLast = negative;
					positive.material = face.material;
					positive.calculateBestSequenceAndNormal();
					if (positiveLast != null) {
						positiveLast.next = positive;
					} else {
						positiveMesh.faceList = positive;
					}
					positiveLast = positive;
				}
			}
			if (negativeLast != null) {
				negativeLast.next = null;
				negativeMesh.transformId++;
				negativeMesh.collectVertices();
				negativeMesh.calculateBounds();
				res[0] = negativeMesh;
			}
			if (positiveLast != null) {
				positiveLast.next = null;
				positiveMesh.transformId++;
				positiveMesh.collectVertices();
				positiveMesh.calculateBounds();
				res[1] = positiveMesh;
			}
			return res;
		}
		
		private function collectVertices():void {
			for (var face:Face = faceList; face != null; face = face.next) {
				for (var w:Wrapper = face.wrapper; w != null; w = w.next) {
					var v:Vertex = w.vertex;
					if (v.transformId != transformId) {
						v.next = vertexList;
						vertexList = v;
						v.transformId = transformId;
						v.value = null;
					}
				}
			}
		}
		
	}
}
