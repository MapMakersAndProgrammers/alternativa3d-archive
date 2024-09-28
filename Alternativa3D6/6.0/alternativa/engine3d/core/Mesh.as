package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.engine3d.errors.FaceExistsError;
	import alternativa.engine3d.errors.FaceNeedMoreVerticesError;
	import alternativa.engine3d.errors.FaceNotFoundError;
	import alternativa.engine3d.errors.InvalidIDError;
	import alternativa.engine3d.errors.SurfaceExistsError;
	import alternativa.engine3d.errors.SurfaceNotFoundError;
	import alternativa.engine3d.errors.VertexExistsError;
	import alternativa.engine3d.errors.VertexNotFoundError;
	import alternativa.types.Map;
	import alternativa.utils.ObjectUtils;
	
	use namespace alternativa3d;
	
	/**
	 * Полигональный объект &mdash; базовый класс для трёхмерных объектов, состоящих из граней-полигонов. Объект
	 * содержит в себе наборы вершин, граней и поверхностей.
	 */
	public class Mesh extends Object3D {
		
		// Инкремент количества объектов
		private static var counter:uint = 0;
		
		// Инкременты для идентификаторов вершин, граней и поверхностей
		private var vertexIDCounter:uint = 0;
		private var faceIDCounter:uint = 0;
		private var surfaceIDCounter:uint = 0;
		
		/**
		 * @private
		 * Список вершин
		 */
		alternativa3d var _vertices:Map = new Map();
		/**
		 * @private
		 * Список граней
		 */
		alternativa3d var _faces:Map = new Map();
		/**
		 * @private
		 * Список поверхностей
		 */
		alternativa3d var _surfaces:Map = new Map();
		
		/**
		 * Создание экземпляра полигонального объекта.
		 * 
		 * @param name имя экземпляра
		 */
		public function Mesh(name:String = null) {
			super(name);
		}
		
		override protected function transform():void {
			super.transform();
			
			// Перемещаем вершины
			for each (var vertex:Vertex in _vertices) {
				vertex.move();
			}
			
			// Трансформируем поверхности
			for each (var surface:Surface in _surfaces) {
				// Если у поверхности есть материал
				if (surface._material != null) {
					var key:*;
					var face:Face;
					
					// Если полигональная сортировка
					if (surface._sortingMode == 0) {
						// Обрабатываем грани поверхности
						for (key in surface._faces) {
							face = key;
							// Если есть полигональный примитив
							if (face.polyPrimitive != null) {
								// Расчитываем перпендикуляр грани
								face.calculatePerpendicular();
								// Обновление полигонального примитива
								face.updatePolyPrimitive();
								// Снимаем пометку на трансформацию
								delete _scene.facesToTransform[face];
							} else {
								// Если есть точечный примитив
								if (face.pointPrimitive != null) {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Смена типа примитива с точечного на полигональный
									face.changePointToPolyPrimitive();
									// Снимаем пометку на трансформацию
									delete _scene.facesToTransform[face];
								} else {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Создание полигонального примитива
									face.createPolyPrimitive();
								}
							}
							// Снимаем пометку грани на смену поверхности
							delete _scene.facesToChangeSurface[face];
						}
					} else {
						// Если точечная сортировка
						if (surface._sortingMode == 1) {
							// Обрабатываем грани поверхности
							for (key in surface._faces) {
								face = key;
								// Если есть точечный примитив
								if (face.pointPrimitive != null) {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Обновление точечного примитива
									face.updatePointPrimitive();
									// Снимаем пометку на трансформацию
									delete _scene.facesToTransform[face];
								} else {
									// Если есть полигональный примитив
									if (face.polyPrimitive != null) {
										// Расчитываем перпендикуляр грани
										face.calculatePerpendicular();
										// Смена типа примитива с полигонального на точечный
										face.changePolyToPointPrimitive();
										// Снимаем пометку на трансформацию
										delete _scene.facesToTransform[face];
									} else {
										// Расчитываем перпендикуляр грани
										face.calculatePerpendicular();
										// Создание точечного примитива
										face.createPointPrimitive();
									}
								}
								// Снимаем пометку грани на смену поверхности
								delete _scene.facesToChangeSurface[face];
							}
						} else {
							// Если нет сортировки
	
						}
					}
					// Снимаем все пометки поверхности
					delete _scene.surfacesToChangeMaterial[surface];
					delete _scene.surfacesToChangeSortingMode[surface];
					delete _scene.surfacesToChangeBSPLevel[surface];
				}
			}
		}

		override protected function move():void {
			super.move();
			
			// Перемещаем вершины
			for each (var vertex:Vertex in _vertices) {
				vertex.move();
			}
			
			// Перемещаем поверхности
			for each (var surface:Surface in _surfaces) {
				// Если у поверхности есть материал
				if (surface._material != null) {
					var key:*;
					var face:Face;
					
					// Если полигональная сортировка
					if (surface._sortingMode == 0) {
						// Обрабатываем грани поверхности
						for (key in surface._faces) {
							face = key;
							// Если есть полигональный примитив
							if (face.polyPrimitive != null) {
								// Если грань помечена на трансформацию
								if (_scene.facesToTransform[face]) {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Снимаем пометку на трансформацию
									delete _scene.facesToTransform[face];
								}
								// Обновление полигонального примитива
								face.updatePolyPrimitive();
							} else {
								// Если есть точечный примитив
								if (face.pointPrimitive != null) {
									// Если грань помечена на трансформацию
									if (_scene.facesToTransform[face]) {
										// Расчитываем перпендикуляр грани
										face.calculatePerpendicular();
										// Снимаем пометку на трансформацию
										delete _scene.facesToTransform[face];
									}
									// Смена типа примитива с точечного на полигональный
									face.changePointToPolyPrimitive();
								} else {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Создание полигонального примитива
									face.createPolyPrimitive();
								}
							}
							// Снимаем пометку грани на смену поверхности
							delete _scene.facesToChangeSurface[face];
						}
					} else {
						// Если точечная сортировка
						if (surface._sortingMode == 1) {
							// Обрабатываем грани поверхности
							for (key in surface._faces) {
								face = key;
								// Если есть точечный примитив
								if (face.pointPrimitive != null) {
									// Если грань помечена на трансформацию
									if (_scene.facesToTransform[face]) {
										// Расчитываем перпендикуляр грани
										face.calculatePerpendicular();
										// Снимаем пометку на трансформацию
										delete _scene.facesToTransform[face];
									}
									// Обновление точечного примитива
									face.updatePointPrimitive();
								} else {
									// Если есть полигональный примитив
									if (face.polyPrimitive != null) {
										// Если грань помечена на трансформацию
										if (_scene.facesToTransform[face]) {
											// Расчитываем перпендикуляр грани
											face.calculatePerpendicular();
											// Снимаем пометку на трансформацию
											delete _scene.facesToTransform[face];
										}
										// Смена типа примитива с полигонального на точечный
										face.changePolyToPointPrimitive();
									} else {
										// Расчитываем перпендикуляр грани
										face.calculatePerpendicular();
										// Создание точечного примитива
										face.createPointPrimitive();
									}
								}
								// Снимаем пометку грани на смену поверхности
								delete _scene.facesToChangeSurface[face];
							}
						} else {
							// Если нет сортировки
	
						}
					}
					// Снимаем все пометки поверхности
					delete _scene.surfacesToChangeMaterial[surface];
					delete _scene.surfacesToChangeSortingMode[surface];
					delete _scene.surfacesToChangeBSPLevel[surface];
				}
			}
		}
		
		override protected function removeFromScene(scene:Scene3D):void {
			super.removeFromScene(scene);
			
			// Удаляем все пометки вершин
			for each (var vertex:Vertex in _vertices) {
				delete scene.verticesToMove[vertex];
			}

			// Удаляем все пометки граней
			for each (var face:Face in _faces) {
				// Если у грани есть точечный примитив
				if (face.pointPrimitive != null) {
					// Удаляем точечный примитив
					face.destroyPointPrimitive();
				} else {
					// Если у грани есть полигональный примитив
					if (face.polyPrimitive != null) {
						// Удаляем полигональный примитив
						face.destroyPolyPrimitive();
					}
				}
				delete scene.facesToChangeSurface[face];
				delete scene.facesToTransform[face];
			}

			// Удаляем все пометки поверхностей
			for each (var surface:Surface in _surfaces) {
				delete scene.surfacesToChangeSortingMode[surface];
				delete scene.surfacesToChangeMaterial[surface];
				delete scene.surfacesToChangeBSPLevel[surface];
			}
		}
		
		/**
		 * Добавление новой вершины к объекту.
		 *  
		 * @param x координата X в локальной системе координат объекта  
		 * @param y координата Y в локальной системе координат объекта
		 * @param z координата Z в локальной системе координат объекта
		 * @param id идентификатор вершины. Если указано значение <code>null</code>, идентификатор будет
		 * сформирован автоматически.
		 * 
		 * @return экземпляр добавленной вершины
		 * 
		 * @throws alternativa.engine3d.errors.VertexExistsError объект уже содержит вершину с указанным идентификатором
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 */
		public function createVertex(x:Number = 0, y:Number = 0, z:Number = 0, id:Object = null):Vertex {
			// Проверяем ID
			if (id != null) {
				// Если уже есть вершина с таким ID
				if (_vertices[id] != undefined) {
					if (_vertices[id] is Vertex) {
						throw new VertexExistsError(id, this);
					} else {
						// ID некорректный
						throw new InvalidIDError(id, this);
					}
				}
			} else {
				// Ищем первый свободный
				while (_vertices[vertexIDCounter] != undefined) {
					vertexIDCounter++;
				}
				id = vertexIDCounter;
			}
			
			// Создаём вершину
			var v:Vertex = new Vertex();
			v._coords.x = x;
			v._coords.y = y;
			v._coords.z = z;
			
			// Добавляем вершину в меш
			_vertices[id] = v;
			// Указываем меш вершине
			v._mesh = this;
			
			// Помечаем вершину на перемещение
			if (_scene != null) {
				_scene.verticesToMove[v] = true;
			}
			
			return v;
		}
		
		/**
		 * Удаление вершины из объекта. При удалении вершины из объекта также удаляются все грани, которым принадлежит данная вершина.
		 *  
		 * @param vertex экземпляр класса <code>alternativa.engine3d.core.Vertex</code> или идентификатор удаляемой вершины
		 *  
		 * @return экземпляр удалённой вершины
		 * 
		 * @throws alternativa.engine3d.errors.VertexNotFoundError объект не содержит указанную вершину
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 */
		public function removeVertex(vertex:Object):Vertex {
			var byLink:Boolean = vertex is Vertex;
			
			// Проверяем на null
			if (vertex == null) {
				throw new VertexNotFoundError(null, this);
			}
			
			// Проверяем наличие вершины в меше
			if (byLink) {
				// Если удаляем по ссылке
				if (Vertex(vertex)._mesh != this) {
					// Если вершина не в меше
					throw new VertexNotFoundError(vertex, this);
				}
			} else {
				// Если удаляем по ID
				if (_vertices[vertex] == undefined) {
					// Если нет вершины с таким ID
					throw new VertexNotFoundError(vertex, this);
				} else {
					if (!(_vertices[vertex] is Vertex)) {
						// ID некорректный
						throw new InvalidIDError(vertex, this);
					}
				}
			}
			
			// Находим вершину и её ID
			var v:Vertex = byLink ? Vertex(vertex) : _vertices[vertex];
			var id:Object = byLink ? getVertexId(Vertex(vertex)) : vertex;
			
			// Удаляем все пометки вершины в сцене
			if (_scene != null) {
				delete _scene.verticesToMove[v];
			}
			
			// Удаляем зависимые грани
			for (var key:* in v._faces) {
				removeFace(key);
				delete v._faces[key];
			}

			// Удаляем вершину из меша
			delete _vertices[id];
			// Удаляем ссылку на меш в вершине
			v._mesh = null;
			
			return v;
		}
		
		/**
		 * Добавление грани к объекту. В результате выполнения метода в объекте появляется новая грань, не привязанная
		 * ни к одной поверхности.
		 *   
		 * @param vertices массив вершин грани, указанных в порядке обхода лицевой стороны грани против часовой
		 * стрелки. Каждый элемент массива может быть либо экземпляром класса <code>alternativa.engine3d.core.Vertex</code>,
		 * либо идентификатором в наборе вершин объекта. В обоих случаях объект должен содержать указанную вершину.
		 * @param id идентификатор грани. Если указано значение <code>null</code>, идентификатор будет
		 * сформирован автоматически.
		 * 
		 * @return экземпляр добавленной грани 
		 * 
		 * @throws alternativa.engine3d.errors.FaceNeedMoreVerticesError в качестве массива вершин был передан
		 * <code>null</code>, либо количество вершин в массиве меньше трёх
		 * @throws alternativa.engine3d.errors.FaceExistsError объект уже содержит грань с заданным идентификатором
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 * @throws alternativa.engine3d.errors.VertexNotFoundError объект не содержит какую-либо вершину из входного массива
		 * 
		 * @see Vertex
		 */ 
		public function createFace(vertices:Array, id:Object = null):Face {

			// Проверяем на null
			if (vertices == null) {
				throw new FaceNeedMoreVerticesError(this);
			} 
			
			// Проверяем ID
			if (id != null) {
				// Если уже есть грань с таким ID
				if (_faces[id] != undefined) {
					if (_faces[id] is Face) {
						throw new FaceExistsError(id, this);
					} else {
						// ID некорректный
						throw new InvalidIDError(id, this);
					}
				}
			} else {
				// Ищем первый свободный ID
				while (_faces[faceIDCounter] != undefined) {
					faceIDCounter++;
				}
				id = faceIDCounter;
			}
			
			// Проверяем количество точек
			var length:uint = vertices.length;
			if (length < 3) {
				throw new FaceNeedMoreVerticesError(this, length);
			}
			
			// Создаём грань
			var f:Face = new Face();

			// Добавляем грань в меш
			_faces[id] = f;
			// Указываем меш грани
			f._mesh = this;
			
			// Проверяем и формируем список вершин
			f._verticesCount = length;
			var v:Array = f._vertices;
			var vertex:Vertex;
			for (var i:uint = 0; i < length; i++) {
				if (vertices[i] is Vertex) {
					// Если работаем со ссылками
					vertex = vertices[i];
					if (vertex._mesh != this) {
						// Если вершина не в меше
						throw new VertexNotFoundError(vertices[i], this);
					}
				} else {
					// Если работаем с ID
					if (_vertices[vertices[i]] == null) {
						// Если нет вершины с таким ID
						throw new VertexNotFoundError(vertices[i], this);
					} else { 
						if (!(_vertices[vertices[i]] is Vertex)) {
							// ID некорректный
							throw new InvalidIDError(vertices[i],this);
						}
					}
					vertex = _vertices[vertices[i]];
				}
				// Добавляем вершину в список грани
				v.push(vertex);
				// Указываем грань вершине
				vertex._faces[f] = true;
			}
			
			return f;
		}

		/**
		 * Удаление грани из объекта. Грань также удаляется из поверхности объекта, которой она принадлежит.
		 *  
		 * @param экземпляр класса <code>alternativa.engine3d.core.Face</code> или идентификатор удаляемой грани
		 * 
		 * @return экземпляр удалённой грани
		 *  
		 * @throws alternativa.engine3d.errors.FaceNotFoundError объект не содержит указанную грань
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 */
		public function removeFace(face:Object):Face {
			var byLink:Boolean = face is Face;
			
			// Проверяем на null
			if (face == null) {
				throw new FaceNotFoundError(null, this);
			}
			
			// Проверяем наличие грани в меше
			if (byLink) {
				// Если удаляем по ссылке
				if (Face(face)._mesh != this) {
					// Если грань не в меше
					throw new FaceNotFoundError(face, this);
				}
			} else {
				// Если удаляем по ID
				if (_faces[face] == undefined) {
					// Если нет грани с таким ID
					throw new FaceNotFoundError(face, this);
				} else {
					if (!(_faces[face] is Face)) {
						// ID некорректный
						throw new InvalidIDError(face, this);
					}
				}
			}
			
			// Находим грань и её ID
			var f:Face = byLink ? Face(face) : _faces[face] ;
			var id:Object = byLink ? getFaceId(Face(face)) : face;
			
			// Если в сцене
			if (_scene != null) {
				// Удаляем примитив
				if (f.pointPrimitive != null) {
					// Удаляем точечный примитив
					f.destroyPointPrimitive();
					// Помечаем пространство на пересчёт
					_scene.spacesToCalculate[space] = true;
				} else {
					// Если у грани есть полигональный примитив
					if (f.polyPrimitive != null) {
						// Удаляем полигональный примитив
						f.destroyPolyPrimitive();
						// Помечаем пространство на пересчёт
						_scene.spacesToCalculate[space] = true;
					}
				}
				
				// Удаляем все пометки грани в сцене
				delete _scene.facesToChangeSurface[f];
				delete _scene.facesToTransform[f];
			}
			
			// Удаляем грань из поверхности
			if (f._surface != null) {
				delete f._surface._faces[f];
				f._surface = null;
			}
			
			// Удаляем вершины из грани
			for (var i:uint = 0; i < f._verticesCount; i++) {
				var vertex:Vertex = f._vertices.pop();
				delete vertex._faces[f];
			}
			f._verticesCount = 0;

			// Удаляем грань из меша
			delete _faces[id];
			// Удаляем ссылку на меш в грани
			f._mesh = null;
			
			return f;
		}
		
		/**
		 * Добавление новой поверхности к объекту.
		 *    
		 * @param faces набор граней, составляющих поверхность. Каждый элемент массива должен быть либо экземпляром класса
		 * <code>alternativa.engine3d.core.Face</code>, либо идентификатором грани. В обоих случаях объект должен содержать
		 * указанную грань. Если значение параметра равно <code>null</code>, то будет создана пустая поверхность. Если
		 * какая-либо грань содержится в другой поверхности, она будет перенесена в новую поверхность. 
		 * @param id идентификатор новой поверхности. Если указано значение <code>null</code>, идентификатор будет
		 * сформирован автоматически.
		 * 
		 * @return экземпляр добавленной поверхности
		 *   
		 * @throws alternativa.engine3d.errors.SurfaceExistsError объект уже содержит поверхность с заданным идентификатором
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 * 
		 * @see Face
		 */
		public function createSurface(faces:Array = null, id:Object = null):Surface {
			// Проверяем ID
			if (id != null) {
				// Если уже есть поверхность с таким ID
				if (_surfaces[id] != undefined) {
					if (_surfaces[id] is Surface) {
						throw new SurfaceExistsError(id, this);
					} else {
						// ID некорректный
						throw new InvalidIDError(id, this);
					}
				}
			} else {
				// Ищем первый свободный ID
				while (_surfaces[surfaceIDCounter] != undefined) {
					surfaceIDCounter++;
				}
				id = surfaceIDCounter;
			}
			
			// Создаём поверхность
			var s:Surface = new Surface();

			// Добавляем поверхность в меш
			_surfaces[id] = s;
			// Указываем меш поверхности
			s._mesh = this;

			// Добавляем грани, если есть
			if (faces != null) {
				var length:uint = faces.length;
				for (var i:uint = 0; i < length; i++) {
					s.addFace(faces[i]);
				}
			}
			
			return s;
		}
		
		/**
		 * Удаление поверхности объекта. Из удаляемой поверхности также удаляются все содержащиеся в ней грани.
		 *  
		 * @param surface экземпляр класса <code>alternativa.engine3d.core.Face</code> или идентификатор удаляемой поверхности
		 *  
		 * @return экземпляр удалённой поверхности
		 *  
		 * @throws alternativa.engine3d.errors.SurfaceNotFoundError объект не содержит указанную поверхность 
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора 
		 */
		public function removeSurface(surface:Object):Surface {
			var byLink:Boolean = surface is Surface;
			
			// Проверяем на null
			if (surface == null) {
				throw new SurfaceNotFoundError(null, this);
			}
			
			// Проверяем наличие поверхности в меше
			if (byLink) {
				// Если удаляем по ссылке
				if (Surface(surface)._mesh != this) {
					// Если поверхность не в меше
					throw new SurfaceNotFoundError(surface, this);
				}
			} else {
				// Если удаляем по ID
				if (_surfaces[surface] == undefined) {
					// Если нет поверхности с таким ID
					throw new SurfaceNotFoundError(surface, this);
				} else { 
					if (!(_surfaces[surface] is Surface)) {
						// ID некорректный
						throw new InvalidIDError(surface, this);
					}
				}
			}
			
			// Находим поверхность и её ID
			var s:Surface = byLink ? Surface(surface) : _surfaces[surface];
			var id:Object = byLink ? getSurfaceId(Surface(surface)) : surface;
			
			
			var key:*;
			var face:Face;
			if (_scene != null) {
				// Удаляем грани из поверхности и помечаем их на смену поверхности
				for (key in s._faces) {
					face = key;
					_scene.facesToChangeSurface[face] = true;
					delete s._faces[face];
					face._surface = null;
				}
				// Удаляем все пометки поверхности в сцене
				delete _scene.surfacesToChangeSortingLevel[s];
				delete _scene.surfacesToChangeSortingMode[s];
				delete _scene.surfacesToChangeMaterial[s];
				delete _scene.surfacesToChangeBSPLevel[s];
			} else {
				// Удаляем грани из поверхности
				for (key in s._faces) {
					face = key;
					delete s._faces[face];
					face._surface = null;
				}
			}
			
			// Удаляем поверхность из меша
			delete _surfaces[id];
			// Удаляем ссылку на меш в поверхности
			s._mesh = null;	
			
			return s;
		}

		/**
		 * Добавление всех граней объекта в указанную поверхность.
		 *
		 * @param surface экземпляр класса <code>alternativa.engine3d.core.Surface</code> или идентификатор поверхности, в
		 * которую добавляются грани. Если задан идентификатор, и объект не содержит поверхность с таким идентификатором,
		 * будет создана новая поверхность.
		 * 
		 * @param removeSurfaces удалять или нет пустые поверхности после переноса граней 
		 * 
		 * @return экземпляр поверхности, в которую перенесены грани
		 *  
		 * @throws alternativa.engine3d.errors.SurfaceNotFoundError объект не содержит указанный экземпляр поверхности
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 */
		public function moveAllFacesToSurface(surface:Object = null, removeSurfaces:Boolean = false):Surface {
			var byLink:Boolean = surface is Surface;
			
			if (byLink) {
				// Если работаем по ссылке
				if (Surface(surface)._mesh != this) {
					// Если поверхность не в меше
					throw new SurfaceNotFoundError(surface, this);
				}
			} else {
				// Если работаем по ID
				if (surface != null) {
					// Если ID задан
					if (_surfaces[surface] == undefined) {
						// Если нет поверхности с таким ID
						throw new SurfaceNotFoundError(surface, this);
					} else {
						if (!(_surfaces[surface] is Surface)) {
							// ID некорректный
							throw new InvalidIDError(surface, this);
						}
					}
				}
			}
			
			// Находим поверхность и её ID
			var s:Surface = byLink ? Surface(surface) : ((surface != null) ? _surfaces[surface] : createSurface(null, surface));
			var id:Object = byLink ? getSurfaceId(Surface(surface)) : ((surface != null) ? surface : surfaceIDCounter);
			
			// Перемещаем грани в поверхность
			for each (var face:Face in _faces) {
				if (face._surface != s) {
					s.addFace(face);
				}
			}
			
			if (removeSurfaces) {
				// Удаляем оставшиеся поверхности
				for (var key:* in _surfaces) {
					if (key != id) {
						_surfaces[key]._mesh = null;
						delete _surfaces[key];
						
						// Удаляем все пометки поверхности в сцене
						if (_scene != null) {
							delete _scene.surfacesToChangeSortingMode[key];			
							delete _scene.surfacesToChangeMaterial[key];
							delete _scene.surfacesToChangeBSPLevel[key];
						}
					}
				}
			}
			
			return s;
		}

		/**
		 * Набор вершин объекта. Ключами ассоциативного массива являются идентификаторы вершин, значениями - экземпляры вершин.
		 */
		public function get vertices():Map {
			return _vertices.clone();
		}
		
		/**
		 * Набор граней объекта. Ключами ассоциативного массива являются идентификаторы граней, значениями - экземпляры граней.
		 */
		public function get faces():Map {
			return _faces.clone();
		}
		
		/**
		 * Набор поверхностей объекта. Ключами ассоциативного массива являются идентификаторы поверхностей, значениями - экземпляры поверхностей.
		 */		
		public function get surfaces():Map {
			return _surfaces.clone();
		}
		
		/**
		 * Получение вершины объекта по её идентификатору.
		 *  
		 * @param id идентификатор вершины
		 * 
		 * @return экземпляр вершины с указанным идентификатором
		 * 
		 * @throws alternativa.engine3d.errors.VertexNotFoundError объект не содержит вершину с указанным идентификатором
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 */
		public function getVertexById(id:Object):Vertex {
			if (id == null) {
				throw new VertexNotFoundError(null, this);
			}
			if (_vertices[id] == undefined) {
				// Если нет вершины с таким ID
				throw new VertexNotFoundError(id, this);
			} else {
				if (_vertices[id] is Vertex) {
					return _vertices[id];
				} else {
					// ID некорректный
					throw new InvalidIDError(id, this);
				}
			}
		}

		/**
		 * Получение идентификатора вершины объекта. 
		 *
		 * @param экземпляр вершины
		 *
		 * @return идентификатор указанной вершины
		 * 
		 * @throws alternativa.engine3d.errors.VertexNotFoundError объект не содержит указанную вершину
		 */
		public function getVertexId(vertex:Vertex):Object {
			if (vertex == null) {
				throw new VertexNotFoundError(null, this);
			}
			if (vertex._mesh != this) {
				// Если вершина не в меше
				throw new VertexNotFoundError(vertex, this);
			}
			for (var i:Object in _vertices) {
				if (_vertices[i] == vertex) {
					return i;
				}
			}
			throw new VertexNotFoundError(vertex, this);
		}
		
		/**
		 * Проверка наличия вершины в объекте.
		 * 
		 * @param vertex экземпляр класса <code>alternativa.engine3d.core.Vertex</code> или идентификатор вершины
		 * 
		 * @return <code>true</code>, если объект содержит указанную вершину, иначе <code>false</code>  
		 * 
		 * @throws alternativa.engine3d.errors.VertexNotFoundError в качестве vertex был передан null
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 * 
		 * @see Vertex
		 */
		public function hasVertex(vertex:Object):Boolean {
			if (vertex == null) {
				throw new VertexNotFoundError(null, this);
			}
			if (vertex is Vertex) {
				// Проверка вершины
				return vertex._mesh == this;
			} else {
				// Проверка ID вершины
				if (_vertices[vertex] != undefined) {
					// По этому ID есть объект
					if (_vertices[vertex] is Vertex) {
						// Объект является вершиной
						return true;
					} else {
						// ID некорректный
						throw new InvalidIDError(vertex, this);
					}
				} else {
					return false;
				}
			}
		}
		
		/**
		 * Получение грани объекта по ее идентификатору.
		 *  
		 * @param id идентификатор грани
		 * 
		 * @return экземпляр грани с указанным идентификатором
		 *
		 * @throws alternativa.engine3d.errors.FaceNotFoundError объект не содержит грань с указанным идентификатором
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 */
		public function getFaceById(id:Object):Face {
			if (id == null) {
				throw new FaceNotFoundError(null, this);
			}
			if (_faces[id] == undefined) {
				// Если нет грани с таким ID
				throw new FaceNotFoundError(id, this);
			} else {
				if (_faces[id] is Face) {
					return _faces[id];
				} else {
					// ID некорректный
					throw new InvalidIDError(id, this);
				}
			}
		}

		/**
		 * Получение идентификатора грани объекта.
		 *  
		 * @param face экземпляр грани
		 * 
		 * @return идентификатор указанной грани 
		 * 
		 * @throws alternativa.engine3d.errors.FaceNotFoundError объект не содержит указанную грань
		 */
		public function getFaceId(face:Face):Object {
			if (face == null) {
				throw new FaceNotFoundError(null, this);
			}
			if (face._mesh != this) {
				// Если грань не в меше
				throw new FaceNotFoundError(face, this);
			}
			for (var i:Object in _faces) {
				if (_faces[i] == face) {
					return i;
				}
			}
			throw new FaceNotFoundError(face, this);
		}
		
		/**
		 * Проверка наличия грани в объекте.
		 * 
		 * @param face экземпляр класса <code>Face</code> или идентификатор грани
		 * 
		 * @return <code>true</code>, если объект содержит указанную грань, иначе <code>false</code> 
		 * 
		 * @throws alternativa.engine3d.errors.FaceNotFoundError в качестве face был указан null
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 */
		public function hasFace(face:Object):Boolean {
			if (face == null) {
				throw new FaceNotFoundError(null, this);
			}
			if (face is Face) {
				// Проверка грани
				return face._mesh == this;
			} else {
				// Проверка ID грани
				if (_faces[face] != undefined) {
					// По этому ID есть объект
					if (_faces[face] is Face) {
						// Объект является гранью
						return true;
					} else {
						// ID некорректный
						throw new InvalidIDError(face, this);
					}
				} else {
					return false;
				}
			}
		}
		
		/**
		 * Получение поверхности объекта по ее идентификатору
		 *  
		 * @param id идентификатор поверхности
		 * 
		 * @return экземпляр поверхности с указанным идентификатором
		 * 
		 * @throws alternativa.engine3d.errors.SurfaceNotFoundError объект не содержит поверхность с указанным идентификатором
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора 
		 */
		public function getSurfaceById(id:Object):Surface {
			if (id == null) {
				throw new SurfaceNotFoundError(null, this);
			}
			if (_surfaces[id] == undefined) {
				// Если нет поверхности с таким ID
				throw new SurfaceNotFoundError(id, this);
			} else {
				if (_surfaces[id] is Surface) {
					return _surfaces[id];
				} else {
					// ID некорректный
					throw new InvalidIDError(id, this);
				}
			}
		}

		/**
		 * Получение идентификатора поверхности объекта.
		 *  
		 * @param surface экземпляр поверхности
		 * 
		 * @return идентификатор указанной поверхности
		 * 
		 * @throws alternativa.engine3d.errors.SurfaceNotFoundError объект не содержит указанную поверхность 
		 */
		public function getSurfaceId(surface:Surface):Object {
			if (surface == null) {
				throw new SurfaceNotFoundError(null, this);
			}
			if (surface._mesh != this) {
				// Если поверхность не в меше
				throw new SurfaceNotFoundError(surface, this);
			}
			for (var i:Object in _surfaces) {
				if (_surfaces[i] == surface) {
					return i;
				}
			}
			return null;
		}
		
		/**
		 * Проверка наличия поверхности в объекте.
		 *  
		 * @param surface экземпляр класса <code>Surface</code> или идентификатор поверхности
		 *  
		 * @return <code>true</true>, если объект содержит указанную поверхность, иначе <code>false</code>
		 *  
		 * @throws alternativa.engine3d.errors.SurfaceNotFoundError в качестве surface был передан null 
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора 
 		 */
		public function hasSurface(surface:Object):Boolean {
			if (surface == null) {
				throw new SurfaceNotFoundError(null, this);
			}
			if (surface is Surface) {
				// Проверка поверхности
				return surface._mesh == this;
			} else {
				// Проверка ID поверхности
				if (_surfaces[surface] != undefined) {
					// По этому ID есть объект
					if (_surfaces[surface] is Surface) {
						// Объект является поверхностью
						return true;
					} else {
						// ID некорректный
						throw new InvalidIDError(surface, this);
					}
				} else {
					return false;
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function defaultName():String {
			return "mesh" + ++counter;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function toString():String {
			return "[" + ObjectUtils.getClassName(this) + " " + _name + " vertices: " + _vertices.length + " faces: " + _faces.length + "]";
		}

		/**
		 * @inheritDoc
		 */		
		protected override function createEmptyObject():Object3D {
			return new Mesh();
		}
		
	}
}