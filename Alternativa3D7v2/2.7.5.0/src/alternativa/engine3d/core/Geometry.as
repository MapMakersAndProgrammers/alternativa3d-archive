package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.Material;
	import flash.utils.Dictionary;
	import __AS3__.vec.Vector;
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;
	
	/**
	 * Полигональный объект, содержащий в себе вершины и грани, зацепленные за них.
	 * Вершины и грани содержатся в ассоциативных массивах <code>flash.utils.Dictionary</code>, где ключами являются идентификаторы любого типа, а значениями вершины и грани.
	 * @see alternativa.engine3d.core.Vertex
	 * @see alternativa.engine3d.core.Face
	 */
	public class Geometry {
		
		/**
		 * @private 
		 */
		alternativa3d var vertexIdCounter:uint = 0;

		/**
		 * @private 
		 */
		alternativa3d var faceIdCounter:uint = 0;
		
		/**
		 * @private 
		 */
		alternativa3d var _vertices:Dictionary = new Dictionary();

		/**
		 * @private 
		 */
		alternativa3d var _faces:Dictionary = new Dictionary();
		
		/**
		 * Создаёт и добавляет вершину. 
		 * @param x Координата X.
		 * @param y Координата Y.
		 * @param z Координата Z.
		 * @param u Текстурная координата по горизонтали.
		 * @param v Текстурная координата по вертикали.
		 * @param id Идентификатор вершины. Если идентификатор не указан, он будет сформирован автоматически.
		 * @return Новая вершина.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function addVertex(x:Number, y:Number, z:Number, u:Number = 0, v:Number = 0, id:Object = null):Vertex {
			if (id != null) {
				if (_vertices[id]) {
					if (_vertices[id] is Vertex) {
						// Идентификатор занят
						throw new ArgumentError("Identifier " + id + " already exists.");
					} else {
						// Идентификатор зарезервирован
						throw new ArgumentError("Identifier " + id + " is reserved and cannot be used.");
					}
				}
			} else {
				// Поиск свободного id
				while (_vertices[vertexIdCounter]) vertexIdCounter++;
				id = vertexIdCounter;
			}
			var newVertex:Vertex = new Vertex();
			newVertex.x = x;
			newVertex.y = y;
			newVertex.z = z;
			newVertex.u = u;
			newVertex.v = v;
			_vertices[id] = newVertex;
			return newVertex;
		}
	
		/**
		 * Удаляет вершину по экземпляру. 
		 * @param vertex Вершина.
		 * @return Удаляемая вершина.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function removeVertex(vertex:Vertex):Vertex {
			if (vertex == null) throw new TypeError("Parameter vertex must be non-null.");
			if (!hasVertex(vertex)) throw new ArgumentError("Vertex not found.");
			delete _vertices[getVertexId(vertex)];
			// Удаление граней
			for (var key:* in _faces) {
				for (var wrapper:Wrapper = Face(key).wrapper; wrapper != null; wrapper = wrapper.next) {
					if (wrapper.vertex == vertex) {
						delete _faces[key];
						break;
					}
				}
			}
			return vertex;
		}
		
		/**
		 * Удаляет вершину по идентификатору. 
		 * @param id Идентификатор.
		 * @return Удаляемая вершина.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function removeVertexById(id:Object):Vertex {
			if (id == null) throw new TypeError("Parameter id must be non-null.");
			if (!(_vertices[id] is Vertex)) throw new ArgumentError("Vertex not found.");
			var vertex:Vertex = _vertices[id];
			// Удаление вершины
			delete _vertices[id];
			// Удаление граней
			for (var key:* in _faces) {
				for (var wrapper:Wrapper = Face(key).wrapper; wrapper != null; wrapper = wrapper.next) {
					if (wrapper.vertex == vertex) {
						delete _faces[key];
						break;
					}
				}
			}
			return vertex;
		}
		
		/**
		 * Проверяет наличие вершины в объекте. 
		 * @param vertex Вершина.
		 * @return <code>true</code>, если вершина содержится в этом объекте, иначе <code>false</code>.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function hasVertex(vertex:Vertex):Boolean {
			if (vertex == null) throw new TypeError("Parameter vertex must be non-null.");
			for (var key:* in _vertices) {
				if (_vertices[key] == vertex) return true;
			}
			return false;
		}
		
		/**
		 * Проверяет наличие вершины в объекте по идентификатору. 
		 * @param id Идентификатор.
		 * @return <code>true</code>, если вершина содержится в этом объекте, иначе <code>false</code>.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function hasVertexById(id:Object):Boolean {
			if (id == null) throw new TypeError("Parameter id must be non-null.");
			if (_vertices[id] is Vertex) return true;
			return false;
		}
		
		/**
		 * Возвращает идентификатор вершины.
		 * @param vertex Вершина.
		 * @return Идентификатор вершины.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function getVertexId(vertex:Vertex):Object {
			if (vertex == null) throw new TypeError("Parameter vertex must be non-null.");
			var key:*;
			var exists:Boolean = false;
			for (key in _vertices) {
				if (_vertices[key] == vertex) {
					exists = true;
					break;
				}
			}
			if (!exists) throw new ArgumentError("Vertex not found.");
			return key;
		}
		
		/**
		 * Возвращает вершину по идентификатору. 
		 * @param id Идентификатор.
		 * @return Вершина.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function getVertexById(id:Object):Vertex {
			if (id == null) throw new TypeError("Parameter id must be non-null.");
			if (!(_vertices[id] is Vertex)) throw new ArgumentError("Vertex not found.");
			return _vertices[id];
		}
		
		/**
		 * Создаёт и добавляет грань.
		 * @param vertices Вектор экземпляров вершин.
		 * @param material Материал, назначаемый грани.
		 * @param id Идентификатор грани. Если идентификатор не указан, он будет сформирован автоматически.
		 * @return Новая грань.
		 * @see alternativa.engine3d.core.Face
		 * @see alternativa.engine3d.materials.Material
		 */
		public function addFace(vertices:Vector.<Vertex>, material:Material = null, id:Object = null):Face {
			if (id != null) {
				if (_faces[id]) {
					if (_faces[id] is Face) {
						// Идентификатор занят
						throw new ArgumentError("Identifier " + id + " already exists.");
					} else {
						// Идентификатор зарезервирован
						throw new ArgumentError("Identifier " + id + " is reserved and cannot be used.");
					}
				}
			} else {
				// Поиск свободного id
				while (_faces[faceIdCounter]) faceIdCounter++;
				id = faceIdCounter;
			}
			if (vertices == null) throw new TypeError("Parameter vertices must be non-null.");
			var verticesLength:int = vertices.length;
			if (verticesLength < 3) throw new ArgumentError(verticesLength + " vertices not enough.");
			var newFace:Face = new Face();
			newFace.material = material;
			var last:Wrapper = null;
			for (var i:int = 0; i < verticesLength; i++) {
				var newWrapper:Wrapper = new Wrapper();
				var vertex:Vertex = vertices[i];
				if (vertex == null) throw new ArgumentError("Null vertex in vector.");
				if (!hasVertex(vertex)) throw new ArgumentError("Vertex not found.");
				newWrapper.vertex = vertex;
				if (last != null) {
					last.next = newWrapper;
				} else {
					newFace.wrapper = newWrapper;
				}
				last = newWrapper;
			}
			_faces[id] = newFace;
			return newFace;
		}
		
		/**
		 * Создаёт и добавляет грань по идентификаторам вершин.
		 * @param vertices Массив идентификаторов вершин.
		 * @param material Материал, назначаемый грани.
		 * @param id Идентификатор грани. Если идентификатор не указан, он будет сформирован автоматически.
		 * @return Новая грань.
		 * @see alternativa.engine3d.core.Face
		 * @see alternativa.engine3d.materials.Material
		 */
		public function addFaceByIds(vertexIds:Array, material:Material = null, id:Object = null):Face {
			if (id != null) {
				if (_faces[id]) {
					if (_faces[id] is Face) {
						// Идентификатор занят
						throw new ArgumentError("Identifier " + id + " already exists.");
					} else {
						// Идентификатор зарезервирован
						throw new ArgumentError("Identifier " + id + " is reserved and cannot be used.");
					}
				}
			} else {
				// Поиск свободного id
				while (_faces[faceIdCounter]) faceIdCounter++;
				id = faceIdCounter;
			}
			if (vertexIds == null) throw new TypeError("Parameter vertices must be non-null.");
			var verticesLength:int = vertexIds.length;
			if (verticesLength < 3) throw new ArgumentError(verticesLength + " vertices not enough.");
			var newFace:Face = new Face();
			newFace.material = material;
			var last:Wrapper = null;
			for (var i:int = 0; i < verticesLength; i++) {
				var newWrapper:Wrapper = new Wrapper();
				var vId:Object = vertexIds[i];
				if (vId == null) throw new ArgumentError("Null id in array.");
				if (!hasVertexById(vId)) throw new ArgumentError("Vertex not found.");
				newWrapper.vertex = _vertices[vId];
				if (last != null) {
					last.next = newWrapper;
				} else {
					newFace.wrapper = newWrapper;
				}
				last = newWrapper;
			}
			_faces[id] = newFace;
			return newFace;
		}
		
		/**
		 * Создаёт и добавляет треугольную грань.
		 * @param a Вершина.
		 * @param b Вершина.
		 * @param c Вершина.
		 * @param material Материал, назначаемый грани.
		 * @param id Идентификатор грани. Если идентификатор не указан, он будет сформирован автоматически.
		 * @return Новая грань.
		 * @see alternativa.engine3d.core.Face
		 * @see alternativa.engine3d.materials.Material
		 */
		public function addTriFace(a:Vertex, b:Vertex, c:Vertex, material:Material = null, id:Object = null):Face {
			if (id != null) {
				if (_faces[id]) {
					if (_faces[id] is Face) {
						// Идентификатор занят
						throw new ArgumentError("Identifier " + id + " already exists.");
					} else {
						// Идентификатор зарезервирован
						throw new ArgumentError("Identifier " + id + " is reserved and cannot be used.");
					}
				}
			} else {
				// Поиск свободного id
				while (_faces[faceIdCounter]) faceIdCounter++;
				id = faceIdCounter;
			}
			if (a == null) throw new TypeError("Parameter v1 must be non-null.");
			if (b == null) throw new TypeError("Parameter v2 must be non-null.");
			if (c == null) throw new TypeError("Parameter v3 must be non-null.");
			if (!hasVertex(a)) throw new ArgumentError("Vertex not found.");
			if (!hasVertex(b)) throw new ArgumentError("Vertex not found.");
			if (!hasVertex(c)) throw new ArgumentError("Vertex not found.");
			var newFace:Face = new Face();
			newFace.material = material;
			newFace.wrapper = new Wrapper();
			newFace.wrapper.vertex = a;
			newFace.wrapper.next = new Wrapper();
			newFace.wrapper.next.vertex = b;
			newFace.wrapper.next.next = new Wrapper();
			newFace.wrapper.next.next.vertex = c;
			_faces[id] = newFace;
			return newFace;
		}
		
		/**
		 * Создаёт и добавляет четырёхугольную грань.
		 * @param a Вершина.
		 * @param b Вершина.
		 * @param c Вершина.
		 * @param d Вершина.
		 * @param material Материал, назначаемый грани.
		 * @param id Идентификатор грани. Если идентификатор не указан, он будет сформирован автоматически.
		 * @return Новая грань.
		 * @see alternativa.engine3d.core.Face
		 * @see alternativa.engine3d.materials.Material
		 */
		public function addQuadFace(a:Vertex, b:Vertex, c:Vertex, d:Vertex, material:Material = null, id:Object = null):Face {
			if (id != null) {
				if (_faces[id]) {
					if (_faces[id] is Face) {
						// Идентификатор занят
						throw new ArgumentError("Identifier " + id + " already exists.");
					} else {
						// Идентификатор зарезервирован
						throw new ArgumentError("Identifier " + id + " is reserved and cannot be used.");
					}
				}
			} else {
				// Поиск свободного id
				while (_faces[faceIdCounter]) faceIdCounter++;
				id = faceIdCounter;
			}
			if (a == null) throw new TypeError("Parameter v1 must be non-null.");
			if (b == null) throw new TypeError("Parameter v2 must be non-null.");
			if (c == null) throw new TypeError("Parameter v3 must be non-null.");
			if (d == null) throw new TypeError("Parameter v4 must be non-null.");
			if (!hasVertex(a)) throw new ArgumentError("Vertex not found.");
			if (!hasVertex(b)) throw new ArgumentError("Vertex not found.");
			if (!hasVertex(c)) throw new ArgumentError("Vertex not found.");
			if (!hasVertex(d)) throw new ArgumentError("Vertex not found.");
			var newFace:Face = new Face();
			newFace.material = material;
			newFace.wrapper = new Wrapper();
			newFace.wrapper.vertex = a;
			newFace.wrapper.next = new Wrapper();
			newFace.wrapper.next.vertex = b;
			newFace.wrapper.next.next = new Wrapper();
			newFace.wrapper.next.next.vertex = c;
			newFace.wrapper.next.next.next = new Wrapper();
			newFace.wrapper.next.next.next.vertex = d;
			_faces[id] = newFace;
			return newFace;
		}
	
		/**
		 * Удаляет грань по экземпляру. 
		 * @param face Грань.
		 * @return Удаляемая грань.
		 * @see alternativa.engine3d.core.Face
		 */
		public function removeFace(face:Face):Face {
			if (face == null) throw new TypeError("Parameter face must be non-null.");
			if (!hasFace(face)) throw new ArgumentError("Face not found.");
			delete _faces[getFaceId(face)];
			return face;
		}
		
		/**
		 * Удаляет грань по идентификатору. 
		 * @param id Идентификатор.
		 * @return Удаляемая грань.
		 * @see alternativa.engine3d.core.Face
		 */
		public function removeFaceById(id:Object):Face {
			if (id == null) throw new TypeError("Parameter id must be non-null.");
			if (!(_faces[id] is Face)) throw new ArgumentError("Face not found.");
			var face:Face = _faces[id];
			delete _faces[id];
			return face;
		}
		
		/**
		 * Проверяет наличие грани в объекте. 
		 * @param vertex Грань.
		 * @return <code>true</code>, если грань содержится в этом объекте, иначе <code>false</code>.
		 * @see alternativa.engine3d.core.Face
		 */
		public function hasFace(face:Face):Boolean {
			if (face == null) throw new TypeError("Parameter face must be non-null.");
			for (var key:* in _faces) {
				if (_faces[key] == face) return true;
			}
			return false;
		}
		
		/**
		 * Проверяет наличие грани в объекте по идентификатору. 
		 * @param id Идентификатор.
		 * @return <code>true</code>, если грань содержится в этом объекте, иначе <code>false</code>.
		 * @see alternativa.engine3d.core.Face
		 */
		public function hasFaceById(id:Object):Boolean {
			if (id == null) throw new TypeError("Parameter id must be non-null.");
			if (_faces[id] is Face) return true;
			return false;
		}
		
		/**
		 * Возвращает идентификатор грани.
		 * @param vertex Грань.
		 * @return Идентификатор грани.
		 * @see alternativa.engine3d.core.Face
		 */
		public function getFaceId(face:Face):Object {
			if (face == null) throw new TypeError("Parameter face must be non-null.");
			var key:*;
			var exists:Boolean = false;
			for (key in _faces) {
				if (_faces[key] == face) {
					exists = true;
					break;
				}
			}
			if (!exists) throw new ArgumentError("Face not found.");
			return key;
		}
		
		/**
		 * Возвращает грань по идентификатору. 
		 * @param id Идентификатор.
		 * @return Грань.
		 * @see alternativa.engine3d.core.Face
		 */
		public function getFaceById(id:Object):Face {
			if (id == null) throw new TypeError("Parameter id must be non-null.");
			if (!(_faces[id] is Face)) throw new ArgumentError("Face not found.");
			return _faces[id];
		}
		
		/**
		 * Добавляет вершины и грани, созданные по значениям переданных векторов. 
		 * @param vertices Вектор координат вершин в виде x1, y1, z1, x2, y2, z2 и т.д.
		 * @param uvs Вектор текстурных координат, соответственно вектору вершин, в виде u1, v1, u2, v2 и т.д. 
		 * @param indices Вектор индексов граней.
		 * @param poly Флаг, отвечающий за представление граней в виде треугольников или в виде многоугольников.
		 * Если <code>false</code>, то индексы будут восприниматься как последовательность треугольников, например 1,2,3, 4,3,2.
		 * Если <code>true</code>, то как последовательность многоугольников с указанием количества вершин, например, 3, 1,2,3, 4, 5,4,3,2.
		 * @param material Материал, назначаемый всем создаваемым граням.
		 * @see alternativa.engine3d.core.Vertex
		 * @see alternativa.engine3d.core.Face
		 * @see alternativa.engine3d.materials.Material
		 */
		public function addVerticesAndFaces(vertices:Vector.<Number>, uvs:Vector.<Number>, indices:Vector.<int>, poly:Boolean = false, material:Material = null):void {
			if (vertices == null) throw new TypeError("Parameter vertices must be non-null.");
			if (uvs == null) throw new TypeError("Parameter uvs must be non-null.");
			if (indices == null) throw new TypeError("Parameter indices must be non-null.");
			var i:int, j:int, k:int;
			var vertsLength:int = vertices.length/3;
			if (vertsLength != uvs.length/2) throw new ArgumentError("Vertices count and uvs count doesn't match.");
			var indicesLength:int = indices.length;
			if (!poly && indicesLength % 3) throw new ArgumentError("Incorrect indices.");
			for (i = 0, k = 0; i < indicesLength; i++) {
				if (i == k) {
					var num:int = poly ? indices[i] : 3;
					if (num < 3) throw new ArgumentError(num + " vertices not enough.");
					k = poly ? (num + ++i) : (i + num);
					if (k > indicesLength) throw new ArgumentError("Incorrect indices.");
				}
				var index:int = indices[i];
				if (index < 0 || index >= vertsLength) throw new RangeError("Index is out of bounds.");
			}
			// Добавление вершин
			var verts:Vector.<Vertex> = new Vector.<Vertex>(vertsLength);
			for (i = 0, j = 0, k = 0; i < vertsLength; i++) {
				var newVertex:Vertex = new Vertex();
				newVertex.x = vertices[j]; j++;
				newVertex.y = vertices[j]; j++;
				newVertex.z = vertices[j]; j++;
				if (uvs != null) {
					newVertex.u = uvs[k]; k++;
					newVertex.v = uvs[k]; k++;
				}
				verts[i] = newVertex;
				// Поиск свободного id
				while (_vertices[vertexIdCounter]) vertexIdCounter++;
				_vertices[vertexIdCounter] = newVertex;
			}
			// Добавление граней
			var newFace:Face;
			var lastWrapper:Wrapper;
			for (i = 0, k = 0; i < indicesLength; i++) {
				if (i == k) {
					k = poly ? (indices[i] + ++i) : (i + 3);
					lastWrapper = null;
					newFace = new Face();
					newFace.material = material;
					// Поиск свободного id
					while (_faces[faceIdCounter]) faceIdCounter++;
					_faces[faceIdCounter] = newFace;
				}
				var newWrapper:Wrapper = new Wrapper();
				newWrapper.vertex = verts[indices[i]];
				if (lastWrapper != null) {
					lastWrapper.next = newWrapper;
				} else {
					newFace.wrapper = newWrapper;
				}
				lastWrapper = newWrapper;
			}
		}
		
		/**
		 * Возвращает ассоциативный массив вершин, в котором ключами являются идентификаторы, а значениями экземпляры вершин.
		 * @return Объект <code>flash.utils.Dictionary</code>.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function get vertices():Dictionary {
			var res:Dictionary = new Dictionary();
			for (var key:* in _vertices) {
				res[key] = _vertices[key];
			}
			return res;
		}
		
		/**
		 * Возвращает ассоциативный массив граней, в котором ключами являются идентификаторы, а значениями экземпляры граней.
		 * @return Объект <code>flash.utils.Dictionary</code>.
		 * @see alternativa.engine3d.core.Face
		 */
		public function get faces():Dictionary {
			var res:Dictionary = new Dictionary();
			for (var key:* in _faces) {
				res[key] = _faces[key];
			}
			return res;
		}
		
		/**
		 * Возвращает вектор вершин, упорядоченных по идентификаторам.
		 * В начале вектора содержатся вершины, идентификаторами которых являются целые положительные числа, отсортированные в порядке возрастания.
		 * В конце вектора вершины, которые не удалось отсортировать.
		 * @return Вектор экземпляров вершин.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function get orderedVertices():Vector.<Vertex> {
			// Целочисленные идентификаторы
			var ids:Vector.<int> = new Vector.<int>();
			var idsLength:int = 0;
			// Вершины с остальными идентификаторами
			var disordered:Vector.<Vertex> = new Vector.<Vertex>();
			var disorderedLength:int = 0;
			for (var key:* in _vertices) {
				if (key is uint) {
					ids[idsLength] = key;
					idsLength++;
				} else {
					disordered[disorderedLength] = _vertices[key];
					disorderedLength++;
				}
			}
			if (idsLength > 1) sort(ids, idsLength);
			var res:Vector.<Vertex> = new Vector.<Vertex>();
			var resLength:int = 0;
			var i:int;
			for (i = idsLength - 1; i >= 0; i--) {
				res[resLength] = _vertices[ids[i]];
				resLength++;
			}
			for (i = 0; i < disorderedLength; i++) {
				res[resLength] = disordered[i];
				resLength++;
			}
			return res;
		}
		
		/**
		 * Возвращает вектор граней, упорядоченных по идентификаторам.
		 * В начале вектора содержатся грани, идентификаторами которых являются целые положительные числа, отсортированные в порядке возрастания.
		 * В конце вектора грани, которые не удалось отсортировать.
		 * @return Вектор экземпляров граней.
		 * @see alternativa.engine3d.core.Face
		 */
		public function get orderedFaces():Vector.<Face> {
			// Целочисленные идентификаторы
			var ids:Vector.<int> = new Vector.<int>();
			var idsLength:int = 0;
			// Грани с остальными идентификаторами
			var disordered:Vector.<Face> = new Vector.<Face>();
			var disorderedLength:int = 0;
			for (var key:* in _faces) {
				if (key is uint) {
					ids[idsLength] = key;
					idsLength++;
				} else {
					disordered[disorderedLength] = _faces[key];
					disorderedLength++;
				}
			}
			if (idsLength > 1) sort(ids, idsLength);
			var res:Vector.<Face> = new Vector.<Face>();
			var resLength:int = 0;
			var i:int;
			for (i = idsLength - 1; i >= 0; i--) {
				res[resLength] = _faces[ids[i]];
				resLength++;
			}
			for (i = 0; i < disorderedLength; i++) {
				res[resLength] = disordered[i];
				resLength++;
			}
			return res;
		}
		
		/**
		 * Сливает вершины с одинаковыми координатами и UV. Равенство координат проверяется с учётом погрешности.
		 * После слияния вершинам назначаются новые цифровые идентификаторы.
		 * <code>weldVertices()</code> нужно вызывать пред <code>weldFaces()</code>.
		 * @param distanceThreshold Погрешность, в пределах которой координаты считаются одинаковыми.
		 * @param uvThreshold Погрешность, в пределах которой UV-координаты считаются одинаковыми.
		 * @see alternativa.engine3d.core.Vertex
		 * @see #weldFaces()
		 */
		public function weldVertices(distanceThreshold:Number = 0, uvThreshold:Number = 0):void {
			var vertex:Vertex;
			// Заполнение массива вершин
			var verts:Vector.<Vertex> = new Vector.<Vertex>();
			var vertsLength:int = 0;
			for each (vertex in _vertices) {
				verts[vertsLength] = vertex;
				vertsLength++;
			}
			// Группировка
			group(verts, 0, vertsLength, 0, distanceThreshold, uvThreshold, new Vector.<int>());
			// Замена вершин
			for each (var face:Face in _faces) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					if (wrapper.vertex.value != null) {
						wrapper.vertex = wrapper.vertex.value;
					}
				}
			}
			// Создание нового списка вершин
			_vertices = new Dictionary();
			vertexIdCounter = 0;
			for (var i:int = 0; i < vertsLength; i++) {
				vertex = verts[i];
				if (vertex.value == null) {
					_vertices[vertexIdCounter] = vertex;
					vertexIdCounter++;
				}
			}
		}

		/**
		 * Объединяет соседние грани, образующие плоский выпуклый многоугольник.
		 * После объединения граням назначаются новые цифровые идентификаторы.
		 * <code>weldFaces()</code> нужно вызывать после <code>weldVertices()</code>.
		 * @param angleThreshold Допустимый угол в радианах между нормалями, чтобы считать, что объединяемые грани в одной плоскости.
		 * @param uvThreshold Допустимая разница uv-координат, чтобы считать, что объединяемые грани состыковываются по UV.
		 * @param convexThreshold Величина, уменьшающая допустимый угол между смежными рёбрами объединяемых граней.
		 * @param pairWeld Флаг объединения попарно.
		 * @see alternativa.engine3d.core.Face
		 * @see #weldVertices()
		 */
		public function weldFaces(angleThreshold:Number = 0, uvThreshold:Number = 0, convexThreshold:Number = 0, pairWeld:Boolean = false):void {
			var i:int;
			var j:int;
			var key:*;
			var sibling:Face;
			var face:Face;
			var wp:Wrapper;
			var sp:Wrapper;
			var w:Wrapper;
			var s:Wrapper;
			var wn:Wrapper;
			var sn:Wrapper;
			var wm:Wrapper;
			var sm:Wrapper;
			var vertex:Vertex;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var abx:Number;
			var aby:Number;
			var abz:Number;
			var abu:Number;
			var abv:Number;
			var acx:Number;
			var acy:Number;
			var acz:Number;
			var acu:Number;
			var acv:Number;
			var nx:Number;
			var ny:Number;
			var nz:Number;
			var nl:Number;
			var dictionary:Dictionary;
			// Погрешность
			var digitThreshold:Number = 0.001;
			angleThreshold = Math.cos(angleThreshold) - digitThreshold;
			uvThreshold += digitThreshold;
			convexThreshold = Math.cos(Math.PI - convexThreshold) - digitThreshold;
			// Грани
			var faceSet:Dictionary = new Dictionary();
			// Карта соответствий vertex:faces(dictionary)
			var map:Dictionary = new Dictionary();
			for each (face in _faces) {
				// Расчёт нормали
				a = face.wrapper.vertex;
				b = face.wrapper.next.vertex;
				c = face.wrapper.next.next.vertex;
				abx = b.x - a.x;
				aby = b.y - a.y;
				abz = b.z - a.z;
				acx = c.x - a.x;
				acy = c.y - a.y;
				acz = c.z - a.z;
				nx = acz*aby - acy*abz;
				ny = acx*abz - acz*abx;
				nz = acy*abx - acx*aby;
				nl = nx*nx + ny*ny + nz*nz;
				if (nl > digitThreshold) {
					nl = 1/Math.sqrt(nl);
					nx *= nl;
					ny *= nl;
					nz *= nl;
					face.normalX = nx;
					face.normalY = ny;
					face.normalZ = nz;
					face.offset = a.x*nx + a.y*ny + a.z*nz;
					faceSet[face] = true;
					for (wn = face.wrapper; wn != null; wn = wn.next) {
						vertex = wn.vertex;
						dictionary = map[vertex];
						if (dictionary == null) {
							dictionary = new Dictionary();
							map[vertex] = dictionary;
						}
						dictionary[face] = true;
					}
				}
			}
			_faces = new Dictionary();
			faceIdCounter = 0;
			// Остров
			var island:Vector.<Face> = new Vector.<Face>();
			// Соседи текущей грани
			var siblings:Dictionary = new Dictionary();
			// Грани, которые точно не входят в текущий остров
			var unfit:Dictionary = new Dictionary();
			while (true) {
				// Получение первой попавшейся грани
				face = null;
				for (key in faceSet) {
					face = key;
					delete faceSet[key];
					break;
				}
				if (face == null) break;
				// Создани острова
				var num:int = 0;
				island[num] = face;
				num++;
				a = face.wrapper.vertex;
				b = face.wrapper.next.vertex;
				c = face.wrapper.next.next.vertex;
				abx = b.x - a.x;
				aby = b.y - a.y;
				abz = b.z - a.z;
				abu = b.u - a.u;
				abv = b.v - a.v;
				acx = c.x - a.x;
				acy = c.y - a.y;
				acz = c.z - a.z;
				acu = c.u - a.u;
				acv = c.v - a.v;
				nx = face.normalX;
				ny = face.normalY;
				nz = face.normalZ;
				// Нахождение матрицы uv-трансформации
				var det:Number = -nx*acy*abz + acx*ny*abz + nx*aby*acz - abx*ny*acz - acx*aby*nz + abx*acy*nz;
				var ima:Number = (-ny*acz + acy*nz)/det;
				var imb:Number = (nx*acz - acx*nz)/det;
				var imc:Number = (-nx*acy + acx*ny)/det;
				var imd:Number = (a.x*ny*acz - nx*a.y*acz - a.x*acy*nz + acx*a.y*nz + nx*acy*a.z - acx*ny*a.z)/det;
				var ime:Number = (ny*abz - aby*nz)/det;
				var imf:Number = (-nx*abz + abx*nz)/det;
				var img:Number = (nx*aby - abx*ny)/det;
				var imh:Number = (nx*a.y*abz - a.x*ny*abz + a.x*aby*nz - abx*a.y*nz - nx*aby*a.z + abx*ny*a.z)/det;
				var ma:Number = abu*ima + acu*ime;
				var mb:Number = abu*imb + acu*imf;
				var mc:Number = abu*imc + acu*img;
				var md:Number = abu*imd + acu*imh + a.u;
				var me:Number = abv*ima + acv*ime;
				var mf:Number = abv*imb + acv*imf;
				var mg:Number = abv*imc + acv*img;
				var mh:Number = abv*imd + acv*imh + a.v;
				for (key in unfit) {
					delete unfit[key];
				}
				for (i = 0; i < num; i++) {
					face = island[i];
					for (key in siblings) {
						delete siblings[key];
					}
					// Сбор потенциальных соседей грани
					for (w = face.wrapper; w != null; w = w.next) {
						for (key in map[w.vertex]) {
							if (faceSet[key] && !unfit[key]) {
								siblings[key] = true;
							}
						}
					}
					for (key in siblings) {
						sibling = key;
						// Если совпадают по нормалям
						if (nx*sibling.normalX + ny*sibling.normalY + nz*sibling.normalZ >= angleThreshold) {
							for (s = sibling.wrapper; s != null; s = s.next) {
								vertex = s.vertex;
								var du:Number = ma*vertex.x + mb*vertex.y + mc*vertex.z + md - vertex.u;
								var dv:Number = me*vertex.x + mf*vertex.y + mg*vertex.z + mh - vertex.v;
								if (du > uvThreshold || du < -uvThreshold || dv > uvThreshold || dv < -uvThreshold) break;
							}
							// Если совпадают по UV
							if (s == null) {
								// Проверка на соседство
								for (w = face.wrapper; w != null; w = w.next) {
									wn = (w.next != null) ? w.next : face.wrapper;
									for (s = sibling.wrapper; s != null; s = s.next) {
										sn = (s.next != null) ? s.next : sibling.wrapper;
										if (w.vertex == sn.vertex && wn.vertex == s.vertex) break;
									}
									if (s != null) break;
								}
								// Добавление в остров
								if (w != null) {
									island[num] = sibling;
									num++;
									delete faceSet[sibling];
								}
							} else {
								unfit[sibling] = true;
							}
						} else {
							unfit[sibling] = true;
						}
					}
				}
				// Если в острове только одна грань
				if (num == 1) {
					_faces[faceIdCounter] = island[0];
					faceIdCounter++;
					// Объединение острова
				} else {
					while (true) {
						var weld:Boolean = false;
						// Перебор граней острова
						for (i = 0; i < num - 1; i++) {
							face = island[i];
							if (face != null) {
								// Попытки объединить текущую грань с остальными
								for (j = 1; j < num; j++) {
									sibling = island[j];
									if (sibling != null) {
										// Поиск общего ребра
										for (w = face.wrapper; w != null; w = w.next) {
											wn = (w.next != null) ? w.next : face.wrapper;
											for (s = sibling.wrapper; s != null; s = s.next) {
												sn = (s.next != null) ? s.next : sibling.wrapper;
												if (w.vertex == sn.vertex && wn.vertex == s.vertex) break;
											}
											if (s != null) break;
										}
										// Если ребро найдено
										if (w != null) {
											// Расширение граней объединеия
											while (true) {
												wm = (wn.next != null) ? wn.next : face.wrapper;
												//for (sp = sibling.wrapper; sp.next != s && sp.next != null; sp = sp.next);
												sp = sibling.wrapper;
												while (sp.next != s && sp.next != null) sp = sp.next;
												if (wm.vertex == sp.vertex) {
													wn = wm;
													s = sp;
												} else break;
											}
											while (true) {
												//for (wp = face.wrapper; wp.next != w && wp.next != null; wp = wp.next);
												wp = face.wrapper;
												while (wp.next != w && wp.next != null) wp = wp.next;
												sm = (sn.next != null) ? sn.next : sibling.wrapper;
												if (wp.vertex == sm.vertex) {
													w = wp;
													sn = sm;
												} else break;
											}
											// Первый перегиб
											a = w.vertex;
											b = sm.vertex;
											c = wp.vertex;
											abx = b.x - a.x;
											aby = b.y - a.y;
											abz = b.z - a.z;
											acx = c.x - a.x;
											acy = c.y - a.y;
											acz = c.z - a.z;
											nx = acz*aby - acy*abz;
											ny = acx*abz - acz*abx;
											nz = acy*abx - acx*aby;
											if (nx < digitThreshold && nx > -digitThreshold && ny < digitThreshold && ny > -digitThreshold && nz < digitThreshold && nz > -digitThreshold) {
												if (abx*acx + aby*acy + abz*acz > 0) continue;
											} else {
												if (face.normalX*nx + face.normalY*ny + face.normalZ*nz < 0) continue;
											}
											nl = 1/Math.sqrt(abx*abx + aby*aby + abz*abz);
											abx *= nl;
											aby *= nl;
											abz *= nl;
											nl = 1/Math.sqrt(acx*acx + acy*acy + acz*acz);
											acx *= nl;
											acy *= nl;
											acz *= nl;
											if (abx*acx + aby*acy + abz*acz < convexThreshold) continue;
											// Второй перегиб
											a = s.vertex;
											b = wm.vertex;
											c = sp.vertex;
											abx = b.x - a.x;
											aby = b.y - a.y;
											abz = b.z - a.z;
											acx = c.x - a.x;
											acy = c.y - a.y;
											acz = c.z - a.z;
											nx = acz*aby - acy*abz;
											ny = acx*abz - acz*abx;
											nz = acy*abx - acx*aby;
											if (nx < digitThreshold && nx > -digitThreshold && ny < digitThreshold && ny > -digitThreshold && nz < digitThreshold && nz > -digitThreshold) {
												if (abx*acx + aby*acy + abz*acz > 0) continue;
											} else {
												if (face.normalX*nx + face.normalY*ny + face.normalZ*nz < 0) continue;
											}
											nl = 1/Math.sqrt(abx*abx + aby*aby + abz*abz);
											abx *= nl;
											aby *= nl;
											abz *= nl;
											nl = 1/Math.sqrt(acx*acx + acy*acy + acz*acz);
											acx *= nl;
											acy *= nl;
											acz *= nl;
											if (abx*acx + aby*acy + abz*acz < convexThreshold) continue;
											// Объединение
											weld = true;
											var newFace:Face = new Face();
											newFace.material = face.material;
											newFace.normalX = face.normalX;
											newFace.normalY = face.normalY;
											newFace.normalZ = face.normalZ;
											newFace.offset = face.offset;
											wm = null;
											for (; wn != w; wn = (wn.next != null) ? wn.next : face.wrapper) {
												sm = new Wrapper();
												sm.vertex = wn.vertex;
												if (wm != null) {
													wm.next = sm;
												} else {
													newFace.wrapper = sm;
												}
												wm = sm;
											}
											for (; sn != s; sn = (sn.next != null) ? sn.next : sibling.wrapper) {
												sm = new Wrapper();
												sm.vertex = sn.vertex;
												if (wm != null) {
													wm.next = sm;
												} else {
													newFace.wrapper = sm;
												}
												wm = sm;
											}
											island[i] = newFace;
											island[j] = null;
											face = newFace;
											// Если, то собираться будет парами, иначе к одной прицепляется максимально (это чуть бустрее)
											if (pairWeld) break;
										}
									}
								}
							}
						}
						if (!weld) break;
					}
					// Сбор объединённых граней
					for (i = 0; i < num; i++) {
						face = island[i];
						if (face != null) {
							// Определение лучшей последовательности вершин
							face.calculateBestSequenceAndNormal();
							// Добавление
							_faces[faceIdCounter] = face;
							faceIdCounter++;
						}
					}
				}
			}
		}
		
		/**
		 * Трансформирует вершины.
		 * @param matrix Матрица трансформации.
		 */
		public function transform(matrix:Matrix3D):void {
			if (matrix == null) throw new TypeError("Parameter matrix must be non-null.");
			var i:int;
			var j:int;
			var vertex:Vertex;
			var verts:Vector.<Vertex> = new Vector.<Vertex>();
			var vertsLen:int = 0;
			for each (vertex in _vertices) {
				verts[vertsLen] = vertex;
				vertsLen++;
			}
			var coords:Vector.<Number> = new Vector.<Number>();
			for (i = 0, j = 0; i < vertsLen; i++) {
				vertex = verts[i];
				coords[j] = vertex.x; j++;
				coords[j] = vertex.y; j++;
				coords[j] = vertex.z; j++;
			}
			matrix.transformVectors(coords, coords);
			for (i = 0, j = 0; i < vertsLen; i++) {
				vertex = verts[i];
				vertex.x = coords[j]; j++;
				vertex.y = coords[j]; j++;
				vertex.z = coords[j]; j++;
			}
		}
		
		/**
		 * Возвращает объект Geometry, являющийся точной копией исходного объекта Geometry. 
		 * @return Объект Geometry.
		 */
		public function clone():Geometry {
			var res:Geometry = new Geometry();
			res.vertexIdCounter = vertexIdCounter;
			res.faceIdCounter = faceIdCounter;
			var key:*;
			var vertex:Vertex;
			// Клонирование вершин
			for (key in _vertices) {
				vertex = _vertices[key];
				var newVertex:Vertex = new Vertex();
				newVertex.x = vertex.x;
				newVertex.y = vertex.y;
				newVertex.z = vertex.z;
				newVertex.u = vertex.u;
				newVertex.v = vertex.v;
				vertex.value = newVertex;
				res._vertices[key] = newVertex;
			}
			// Клонирование граней
			for (key in _faces) {
				var face:Face = _faces[key];
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
				res._faces[key] = newFace;
			}
			// Сброс после ремапа
			for each (vertex in _vertices) {
				vertex.value = null;
			}
			return res;
		}
		
		private function sort(ids:Vector.<int>, idsLength:int):void {
			var stack:Vector.<int> = new Vector.<int>();
			stack[0] = 0;
			stack[1] = idsLength - 1;
			var index:int = 2;
			while (index > 0) {
				index--;
				var r:int = stack[index];
				var j:int = r;
				index--;
				var l:int = stack[index];
				var i:int = l;
				var median:int = ids[(r + l) >> 1];
				while (i <= j) {
					var left:int = ids[i];
					while (left > median) {
						i++;
						left = ids[i];
					}
					var right:int = ids[j];
					while (right < median) {
						j--;
						right = ids[j];
					}
					if (i <= j) {
						ids[i] = right;
						ids[j] = left;
						i++;
						j--;
					}
				}
				if (l < j) {
					stack[index] = l;
					index++;
					stack[index] = j;
					index++;
				}
				if (i < r) {
					stack[index] = i;
					index++;
					stack[index] = r;
					index++;
				}
			}
		}
		
		private function group(verts:Vector.<Vertex>, begin:int, end:int, depth:int, distanceThreshold:Number, uvThreshold:Number, stack:Vector.<int>):void {
			var i:int;
			var j:int;
			var vertex:Vertex;
			var threshold:Number;
			switch (depth) {
				case 0: // x
					for (i = begin; i < end; i++) {
						vertex = verts[i];
						vertex.offset = vertex.x;
					}
					threshold = distanceThreshold;
					break;
				case 1: // y
					for (i = begin; i < end; i++) {
						vertex = verts[i];
						vertex.offset = vertex.y;
					}
					threshold = distanceThreshold;
					break;
				case 2: // z
					for (i = begin; i < end; i++) {
						vertex = verts[i];
						vertex.offset = vertex.z;
					}
					threshold = distanceThreshold;
					break;
				case 3: // u
					for (i = begin; i < end; i++) {
						vertex = verts[i];
						vertex.offset = vertex.u;
					}
					threshold = uvThreshold;
					break;
				case 4: // v
					for (i = begin; i < end; i++) {
						vertex = verts[i];
						vertex.offset = vertex.v;
					}
					threshold = uvThreshold;
					break;
			}
			// Сортировка
			stack[0] = begin;
			stack[1] = end - 1;
			var index:int = 2;
			while (index > 0) {
				index--;
				var r:int = stack[index];
				j = r;
				index--;
				var l:int = stack[index];
				i = l;
				vertex = verts[(r + l) >> 1];
				var median:Number = vertex.offset;
				while (i <= j) {
					var left:Vertex = verts[i];
					while (left.offset > median) {
						i++;
						left = verts[i];
					}
					var right:Vertex = verts[j];
					while (right.offset < median) {
						j--;
						right = verts[j];
					}
					if (i <= j) {
						verts[i] = right;
						verts[j] = left;
						i++;
						j--;
					}
				}
				if (l < j) {
					stack[index] = l;
					index++;
					stack[index] = j;
					index++;
				}
				if (i < r) {
					stack[index] = i;
					index++;
					stack[index] = r;
					index++;
				}
			}
			// Разбиение на группы дальше
			i = begin;
			vertex = verts[i];
			for (j = i + 1; j < end; j++) {
				var compared:Vertex = verts[j];
				if (vertex.offset - compared.offset > threshold) {
					if (depth < 4 && j - i > 1) {
						group(verts, i, j, depth + 1, distanceThreshold, uvThreshold, stack);
					}
					i = j;
					vertex = verts[i];
				} else if (depth == 4) {
					compared.value = vertex;
				}
			}
			if (depth < 4 && j - i > 1) {
				group(verts, i, j, depth + 1, distanceThreshold, uvThreshold, stack);
			}
		}
		
	}
}
