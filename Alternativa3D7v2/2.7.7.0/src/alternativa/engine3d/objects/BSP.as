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
	import flash.geom.Vector3D;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.RayIntersectionData;
	
	use namespace alternativa3d;

	/**
	 * Полигональный объект, состоящий из вершин и граней, построенных по этим вершинам.
	 * Грани образуют бинарную древовидную структуру — BSP-дерево.
	 * @see alternativa.engine3d.core.Vertex
	 * @see alternativa.engine3d.core.Face
	 */
	public class BSP extends Object3D {
		
		/**
		 * Режим отсечения объекта по пирамиде видимости камеры.
		 * Можно использовать следующие константы <code>Clipping</code> для указания свойства <code>clipping</code>: <code>Clipping.BOUND_CULLING</code>, <code>Clipping.FACE_CULLING</code>, <code>Clipping.FACE_CLIPPING</code>.
		 * Значение по умолчанию <code>Clipping.FACE_CLIPPING</code>.
		 * @see alternativa.engine3d.core.Clipping
		 */
		public var clipping:int = 2;
		
		/**
		 * Геометрическая погрешность.
		 * Это малая величина, в пределах которой разницей значений можно пренебречь.
		 * Учитывается при построении BSP-дерева.
		 * Значение по умолчанию — <code>0.01</code>.
		 */
		public var threshold:Number = 0.01;
		
		/**
		 * Флаг анализа геометрии при построении BSP-дерева.
		 * Если <code>true</code>, то дерево будет построено с минимальным количеством рассечений.
		 * Значение по умолчанию <code>true</code>.
		 */
		public var splitAnalysis:Boolean = true;
		
		/**
		 * @private 
		 */
		alternativa3d var vertexList:Vertex;
		
		/**
		 * @private 
		 */
		alternativa3d var root:Node;
		
		/**
		 * @private 
		 */
		alternativa3d var faces:Vector.<Face> = new Vector.<Face>();
		
		/**
		 * Геометрия объекта.
		 * При установке геометрии происходит построение BSP-дерева.
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
			var facesLength:int = faces.length;
			for (var i:int = 0; i < facesLength; i++) {
				var face:Face = faces[i];
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
			if (root != null) {
				destroyNode(root);
				root = null;
			}
			faces.length = 0;
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
				var faceList:Face;
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
					newFace.calculateBestSequenceAndNormal();
					if (lastFace != null) {
						lastFace.next = newFace;
					} else {
						faceList = newFace;
					}
					lastFace = newFace;
					faces[i] = newFace;
				}
				// Сброс после ремапа
				for (i = 0; i < orderedVerticesLength; i++) {
					vertex = orderedVertices[i];
					vertex.value = null;
				}
				// Построение дерева
				if (faceList != null) {
					root = createNode(faceList);
				}
			}
		}
		
		/**
		 * Переносит экземпляры вершин и граней в новый объект класса <code>Geometry</code>.
		 * После переноса списки вершин и граней остаются пустыми, а дерево разрушается.
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
			var facesLength:int = faces.length;
			for (var i:int = 0; i < facesLength; i++) {
				res._faces[res.faceIdCounter] = faces[i];
				res.faceIdCounter++;
			}
			if (root != null) {
				destroyNode(root);
				root = null;
			}
			faces.length = 0;
			return res;
		}
		
		/**
		 * Забирает экземпляры вершин и граней из предоставленного объекта класса <code>Geometry</code>.
		 * После переноса строится новое BSP-дерево, а ассоциативные массивы вершин и граней переданного объекта остаются пустыми.
		 * @param geometry Объект класса <code>Geometry</code>.
		 * @see alternativa.engine3d.core.Geometry
		 * @see alternativa.engine3d.core.Vertex
		 * @see alternativa.engine3d.core.Face
		 */
		public function takeGeometryFrom(geometry:Geometry):void {
			vertexList = null;
			if (root != null) {
				destroyNode(root);
				root = null;
			}
			faces.length = 0;
			var i:int;
			var orderedVertices:Vector.<Vertex> = geometry.orderedVertices;
			var orderedVerticesLength:int = orderedVertices.length;
			var orderedFaces:Vector.<Face> = geometry.orderedFaces;
			var orderedFacesLength:int = orderedFaces.length;
			geometry._vertices = new Dictionary()
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
			var faceList:Face;
			var lastFace:Face;
			for (i = 0; i < orderedFacesLength; i++) {
				var face:Face = orderedFaces[i];
				face.calculateBestSequenceAndNormal();
				if (lastFace != null) {
					lastFace.next = face;
				} else {
					faceList = face;
				}
				lastFace = face;
				faces[i] = face;
			}
			// Построение дерева
			if (faceList != null) {
				root = createNode(faceList);
			}
		}
		
		/**
		 * Устанавливает материал всем граням.
		 * @param material Устанавливаемы материал.
		 * @see alternativa.engine3d.materials.Material
		 * @see alternativa.engine3d.core.Face
		 */
		public function setMaterialToAllFaces(material:Material):void {
			var facesLength:int = faces.length;
			for (var i:int = 0; i < facesLength; i++) {
				var face:Face = faces[i];
				face.material = material;
			}
			if (root != null) setMaterialToNode(root, material);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function calculateResolution(textureWidth:int, textureHeight:int, type:int = 1, matrix:Matrix3D = null):Number {
			var facesLength:int = faces.length;
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
			for (var i:int = 0; i < facesLength; i++) {
				var face:Face = faces[i];
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
			if (root != null) {
				return intersectRayNode(root, origin.x, origin.y, origin.z, direction.x, direction.y, direction.z);
			} else {
				return null;
			}
		}
		
		private function intersectRayNode(node:Node, ox:Number, oy:Number, oz:Number, dx:Number, dy:Number, dz:Number):RayIntersectionData {
			var data:RayIntersectionData;
			var offset:Number = node.normalX*ox + node.normalY*oy + node.normalZ*oz - node.offset;
			if (offset > 0) {
				if (node.positive != null) {
					data = intersectRayNode(node.positive, ox, oy, oz, dx, dy, dz);
					if (data != null) return data;
				}
				var dot:Number = dx*node.normalX + dy*node.normalY + dz*node.normalZ;
				if (dot < 0) {
					var time:Number = -offset/dot;
					var cx:Number = ox + dx*time;
					var cy:Number = oy + dy*time;
					var cz:Number = oz + dz*time;
					for (var f:Face = node.faceList; f != null; f = f.next) {
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
							if ((acz*aby - acy*abz)*node.normalX + (acx*abz - acz*abx)*node.normalY + (acy*abx - acx*aby)*node.normalZ < 0) break;
						}
						if (wrapper == null) {
							data = new RayIntersectionData();
							data.object = this;
							data.face = f;
							data.point = new Vector3D(cx, cy, cz);
							data.time = time;
							return data;
						}
					}
					if (node.negative != null) {
						return intersectRayNode(node.negative, ox, oy, oz, dx, dy, dz);
					}
				}
			} else {
				if (node.negative != null) {
					data = intersectRayNode(node.negative, ox, oy, oz, dx, dy, dz);
					if (data != null) return data;
				}
				if (node.positive != null && dx*node.normalX + dy*node.normalY + dz*node.normalZ > 0) {
					return intersectRayNode(node.positive, ox, oy, oz, dx, dy, dz);
				}
			}
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:BSP = new BSP();
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:BSP = source as BSP;
			clipping = src.clipping;
			threshold = src.threshold;
			splitAnalysis = src.splitAnalysis;
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
			var map:Dictionary = new Dictionary();
			var facesLength:int = src.faces.length;
			for (var i:int = 0; i < facesLength; i++) {
				var face:Face = src.faces[i];
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
				faces[i] = newFace;
				map[face] = newFace;
			}
			// Клонирование дерева
			if (src.root != null) {
				root = src.cloneNode(src.root, map);
			}
			// Сброс после ремапа
			for (vertex = src.vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
		}
		
		private function cloneNode(node:Node, map:Dictionary):Node {
			var newNode:Node = new Node();
			var last:Face;
			for (var face:Face = node.faceList; face != null; face = face.next) {
				var newFace:Face = map[face];
				if (newFace == null) {
					newFace = new Face();
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
				}
				if (newNode.faceList != null) {
					last.next = newFace;
				} else {
					newNode.faceList = newFace;
				}
				last = newFace;
			}
			newNode.normalX = node.normalX;
			newNode.normalY = node.normalY;
			newNode.normalZ = node.normalZ;
			newNode.offset = node.offset;
			if (node.negative != null) newNode.negative = cloneNode(node.negative, map);
			if (node.positive != null) newNode.positive = cloneNode(node.positive, map);
			return newNode;
		}
		
		private function setMaterialToNode(node:Node, material:Material):void {
			for (var face:Face = node.faceList; face != null; face = face.next) {
				face.material = material;
			}
			if (node.negative != null) setMaterialToNode(node.negative, material);
			if (node.positive != null) setMaterialToNode(node.positive, material);
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas):void {
			if (root == null) return;
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
			var list:Face = collectNode(root);
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
			var canvas:Canvas;
			var debug:int;
			// Дебаг
			if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
				canvas = parentCanvas.getChildCanvas(true, false);
				if (debug & Debug.EDGES) Debug.drawEdges(camera, canvas, list, 0xFFFFFF);
				if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, this, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
			}
			// Отрисовка
			canvas = parentCanvas.getChildCanvas(true, false, this, alpha, blendMode, colorTransform, filters);
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
		override alternativa3d function getVG(camera:Camera3D):VG {
			if (root == null) return null;
			// Коррекция куллинга
			if (clipping == 0) {
				if (culling & 1) return null;
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
			// Получение видимой геометрии
			var tree:Face = prepareNode(root, culling, camera);
			// Создание геометрии
			if (tree != null) {
				return VG.create(this, tree, 3, camera.debug ? camera.checkInDebug(this) : 0, false);
			} else {
				return null;
			}
		}
	
		private function collectNode(node:Node, result:Face = null):Face {
			if (node.normalX*imd + node.normalY*imh + node.normalZ*iml > node.offset) {
				if (node.positive != null) result = collectNode(node.positive, result);
				for (var face:Face = node.faceList; face != null; face = face.next) {
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
					face.processNext = result;
					result = face;
				}
				if (node.negative != null) result = collectNode(node.negative, result);
			} else {
				if (node.negative != null) result = collectNode(node.negative, result);
				if (node.positive != null) result = collectNode(node.positive, result);
			}
			return result;
		}
		
		private function prepareNode(node:Node, culling:int, camera:Camera3D):Face {
			var list:Face;
			var w:Wrapper;
			if (imd*node.normalX + imh*node.normalY + iml*node.normalZ > node.offset) {
				list = node.faceList;
				for (var face:Face = list; face != null; face = face.next) {
					for (w = face.wrapper; w != null; w = w.next) {
						var v:Vertex = w.vertex;
						if (v.transformId != transformId) {
							var x:Number = v.x;
							var y:Number = v.y;
							var z:Number = v.z;
							v.cameraX = ma*x + mb*y + mc*z + md;
							v.cameraY = me*x + mf*y + mg*z + mh;
							v.cameraZ = mi*x + mj*y + mk*z + ml;
							v.transformId = transformId;
							v.drawId = 0;
						}
					}
					face.processNext = face.next;
				}
				if (culling > 0) {
					if (clipping == 1) {
						list = camera.cull(list, culling);
					} else {
						list = camera.clip(list, culling);
					}
				}
			}
			var negative:Face = (node.negative != null) ? prepareNode(node.negative, culling, camera) : null;
			var positive:Face = (node.positive != null) ? prepareNode(node.positive, culling, camera) : null;
			// Если нода видна или есть видимые дочерние ноды
			if (list != null || negative != null && positive != null) {
				if (list == null) {
					// Создание пустой ноды
					list = node.faceList.create();
					camera.lastFace.next = list;
					camera.lastFace = list;
				}
				// Расчёт нормали
				w = node.faceList.wrapper;
				var a:Vertex = w.vertex;
				w = w.next;
				var b:Vertex = w.vertex;
				w = w.next;
				var c:Vertex = w.vertex;
				if (a.transformId != transformId) {
					a.cameraX = ma*a.x + mb*a.y + mc*a.z + md;
					a.cameraY = me*a.x + mf*a.y + mg*a.z + mh;
					a.cameraZ = mi*a.x + mj*a.y + mk*a.z + ml;
					a.transformId = transformId;
					a.drawId = 0;
				}
				if (b.transformId != transformId) {
					b.cameraX = ma*b.x + mb*b.y + mc*b.z + md;
					b.cameraY = me*b.x + mf*b.y + mg*b.z + mh;
					b.cameraZ = mi*b.x + mj*b.y + mk*b.z + ml;
					b.transformId = transformId;
					b.drawId = 0;
				}
				if (c.transformId != transformId) {
					c.cameraX = ma*c.x + mb*c.y + mc*c.z + md;
					c.cameraY = me*c.x + mf*c.y + mg*c.z + mh;
					c.cameraZ = mi*c.x + mj*c.y + mk*c.z + ml;
					c.transformId = transformId;
					c.drawId = 0;
				}
				var abx:Number = b.cameraX - a.cameraX;
				var aby:Number = b.cameraY - a.cameraY;
				var abz:Number = b.cameraZ - a.cameraZ;
				var acx:Number = c.cameraX - a.cameraX;
				var acy:Number = c.cameraY - a.cameraY;
				var acz:Number = c.cameraZ - a.cameraZ;
				var nx:Number = acz*aby - acy*abz;
				var ny:Number = acx*abz - acz*abx;
				var nz:Number = acy*abx - acx*aby;
				var nl:Number = nx*nx + ny*ny + nz*nz;
				if (nl > 0) {
					nl = 1/Math.sqrt(length);
					nx *= nl;
					ny *= nl;
					nz *= nl;
				}
				list.normalX = nx;
				list.normalY = ny;
				list.normalZ = nz;
				list.offset = a.cameraX*nx + a.cameraY*ny + a.cameraZ*nz;
				list.processNegative = negative;
				list.processPositive = positive;
			} else {
				list = (negative != null) ? negative : positive;
			}
			return list;
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
			if (root != null) {
				destroyNode(root);
				root = null;
			}
			var faces:Vector.<Face> = this.faces;
			this.faces = new Vector.<Face>();
			// Разделение
			var negativeBSP:BSP = clone() as BSP;
			var positiveBSP:BSP = clone() as BSP;
			var negativeFirst:Face;
			var negativeLast:Face;
			var positiveFirst:Face;
			var positiveLast:Face;
			var negativeFacesLength:int = 0;
			var positiveFacesLength:int = 0;
			var facesLength:int = faces.length;
			for (var i:int = 0; i < facesLength; i++) {
				var face:Face = faces[i];
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
						positiveFirst = face;
					}
					positiveLast = face;
					positiveBSP.faces[positiveFacesLength] = face;
					positiveFacesLength++;
				} else if (!infront) {
					if (negativeLast != null) {
						negativeLast.next = face;
					} else {
						negativeFirst = face;
					}
					negativeLast = face;
					negativeBSP.faces[negativeFacesLength] = face;
					negativeFacesLength++;
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
						negativeFirst = negative;
					}
					negativeLast = negative;
					negativeBSP.faces[negativeFacesLength] = negative;
					negativeFacesLength++;
					positive.material = face.material;
					positive.calculateBestSequenceAndNormal();
					if (positiveLast != null) {
						positiveLast.next = positive;
					} else {
						positiveFirst = positive;
					}
					positiveLast = positive;
					positiveBSP.faces[positiveFacesLength] = positive;
					positiveFacesLength++;
				}
			}
			if (negativeLast != null) {
				negativeLast.next = null;
				negativeBSP.transformId++;
				negativeBSP.collectVertices();
				negativeBSP.root = negativeBSP.createNode(negativeFirst);
				negativeBSP.calculateBounds();
				res[0] = negativeBSP;
			}
			if (positiveLast != null) {
				positiveLast.next = null;
				positiveBSP.transformId++;
				positiveBSP.collectVertices();
				positiveBSP.root = positiveBSP.createNode(positiveFirst);
				positiveBSP.calculateBounds();
				res[1] = positiveBSP;
			}
			return res;
		}
		
		private function collectVertices():void {
			var facesLength:int = faces.length;
			for (var i:int = 0; i < facesLength; i++) {
				var face:Face = faces[i];
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
		
		private function createNode(list:Face):Node {
			var node:Node = new Node();
			var w:Wrapper;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var v:Vertex;
			var behind:Boolean;
			var infront:Boolean;
			var ao:Number;
			var bo:Number;
			var co:Number;
			var vo:Number;
			var normalX:Number;
			var normalY:Number;
			var normalZ:Number;
			var offset:Number;
			var offsetMin:Number;
			var offsetMax:Number;
			var splitter:Face = list;
			if (splitAnalysis && list.next != null) {
				var bestSplits:int = 2147483647;
				for (var face:Face = list; face != null; face = face.next) {
					normalX = face.normalX;
					normalY = face.normalY;
					normalZ = face.normalZ;
					offset = face.offset;
					offsetMin = offset - threshold;
					offsetMax = offset + threshold;
					var splits:int = 0;
					for (var f:Face = list; f != null; f = f.next) {
						if (f != face) {
							w = f.wrapper;
							a = w.vertex;
							w = w.next;
							b = w.vertex;
							w = w.next;
							c = w.vertex;
							w = w.next;
							ao = a.x*normalX + a.y*normalY + a.z*normalZ;
							bo = b.x*normalX + b.y*normalY + b.z*normalZ;
							co = c.x*normalX + c.y*normalY + c.z*normalZ;
							behind = ao < offsetMin || bo < offsetMin || co < offsetMin;
							infront = ao > offsetMax || bo > offsetMax || co > offsetMax;
							for (; w != null; w = w.next) {
								v = w.vertex;
								vo = v.x*normalX + v.y*normalY + v.z*normalZ;
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
			}
			var negativeFirst:Face;
			var negativeLast:Face;
			var splitterLast:Face = splitter;
			var splitterNext:Face = splitter.next;
			var positiveFirst:Face;
			var positiveLast:Face;
			normalX = splitter.normalX;
			normalY = splitter.normalY;
			normalZ = splitter.normalZ;
			offset = splitter.offset;
			offsetMin = offset - threshold;
			offsetMax = offset + threshold;
			while (list != null) {
				if (list != splitter) {
					var next:Face = list.next;
					w = list.wrapper;
					a = w.vertex;
					w = w.next;
					b = w.vertex;
					w = w.next;
					c = w.vertex;
					w = w.next;
					ao = a.x*normalX + a.y*normalY + a.z*normalZ;
					bo = b.x*normalX + b.y*normalY + b.z*normalZ;
					co = c.x*normalX + c.y*normalY + c.z*normalZ;
					behind = ao < offsetMin || bo < offsetMin || co < offsetMin;
					infront = ao > offsetMax || bo > offsetMax || co > offsetMax;
					for (; w != null; w = w.next) {
						v = w.vertex;
						vo = v.x*normalX + v.y*normalY + v.z*normalZ;
						if (vo < offsetMin) {
							behind = true;
						} else if (vo > offsetMax) {
							infront = true;
						}
						v.offset = vo;
					}
					if (!behind) {
						if (!infront) {
							if (list.normalX*normalX + list.normalY*normalY + list.normalZ*normalZ > 0) {
								splitterLast.next = list;
								splitterLast = list;
							} else {
								if (negativeFirst != null) {
									negativeLast.next = list;
								} else {
									negativeFirst = list;
								}
								negativeLast = list;
							}
						} else {
							if (positiveFirst != null) {
								positiveLast.next = list;
							} else {
								positiveFirst = list;
							}
							positiveLast = list;
						}
					} else if (!infront) {
						if (negativeFirst != null) {
							negativeLast.next = list;
						} else {
							negativeFirst = list;
						}
						negativeLast = list;
					} else {
						a.offset = ao;
						b.offset = bo;
						c.offset = co;
						var negative:Face = new Face();
						var positive:Face = new Face();
						var wNegative:Wrapper = null;
						var wPositive:Wrapper = null;
						var wNew:Wrapper;
						w = list.wrapper.next.next;
						while (w.next != null) {
							w = w.next;
						}
						a = w.vertex;
						ao = a.offset;
						for (w = list.wrapper; w != null; w = w.next) {
							b = w.vertex;
							bo = b.offset;
							if (ao < offsetMin && bo > offsetMax || ao > offsetMax && bo < offsetMin) {
								var t:Number = (offset - ao)/(bo - ao);
								v = new Vertex();
								v.next = vertexList;
								vertexList = v;
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
						negative.material = list.material;
						negative.calculateBestSequenceAndNormal();
						if (negativeFirst != null) {
							negativeLast.next = negative;
						} else {
							negativeFirst = negative;
						}
						negativeLast = negative;
						positive.material = list.material;
						positive.calculateBestSequenceAndNormal();
						if (positiveFirst != null) {
							positiveLast.next = positive;
						} else {
							positiveFirst = positive;
						}
						positiveLast = positive;
					}
					list = next;
				} else {
					list = splitterNext;
				}
			}
			if (negativeFirst != null) {
				negativeLast.next = null;
				node.negative = createNode(negativeFirst);
			}
			splitterLast.next = null;
			node.faceList = splitter;
			node.normalX = normalX;
			node.normalY = normalY;
			node.normalZ = normalZ;
			node.offset = offset;
			if (positiveFirst != null) {
				positiveLast.next = null;
				node.positive = createNode(positiveFirst);
			}
			return node;
		}
		
		private function destroyNode(node:Node):void {
			if (node.negative != null) {
				destroyNode(node.negative);
				node.negative = null;
			}
			if (node.positive != null) {
				destroyNode(node.positive);
				node.positive = null;
			}
			for (var face:Face = node.faceList; face != null; face = next) {
				var next:Face = face.next;
				face.next = null;
			}
		}
		
	}
}

import alternativa.engine3d.core.Face;

class Node {
	
	public var negative:Node;
	public var positive:Node;
	
	public var faceList:Face
	
	public var normalX:Number;
	public var normalY:Number;
	public var normalZ:Number;
	public var offset:Number;
	
}
