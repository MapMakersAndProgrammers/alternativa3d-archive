package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.engine3d.sorting.FaceDistancePrimitive;
	import alternativa.engine3d.sorting.FaceBSPPrimitive;
	import alternativa.types.Point3D;
	import alternativa.types.Set;
	import alternativa.engine3d.sorting.FaceNonePrimitive;

	use namespace alternativa3d;

	/**
	 * Грань, образованная тремя или более вершинами. Грани являются составными частями полигональных объектов. Каждая грань
	 * содержит информацию об объекте и поверхности, которым она принадлежит. Для обеспечения возможности наложения
	 * текстуры на грань, первым трём её вершинам могут быть заданы UV-координаты, на основании которых расчитывается
	 * матрица трансформации текстуры.
	 */
	final public class Face {
		/**
		 * @private
		 * Меш
		 */
		alternativa3d var _mesh:Mesh;
		/**
		 * @private
		 * Поверхность
		 */		
		alternativa3d var _surface:Surface;
		/**
		 * @private
		 * Вершины грани
		 */
		alternativa3d var _vertices:Array = new Array();
		/**
		 * @private
		 * Количество вершин
		 */
		alternativa3d var _verticesCount:uint;
		/**
		 * @private
		 * Нормаль плоскости в пространстве
		 */
		alternativa3d var spacePerpendicular:Point3D = new Point3D();
		/**
		 * @private
		 * Примитив грани
		 */		
		alternativa3d var primitive:FaceNonePrimitive;
		alternativa3d var pointPrimitive:FaceDistancePrimitive;
		alternativa3d var polyPrimitive:FaceBSPPrimitive;
		
		alternativa3d function calculatePerpendicular():void {
			trace(this, "- calculatePerpendicular");
			
			// Вектор AB
			var vertex:Vertex = _vertices[0];
			var av:Point3D = vertex.spaceCoords;
			vertex = _vertices[1];
			var bv:Point3D = vertex.spaceCoords;
			var abx:Number = bv.x - av.x;
			var aby:Number = bv.y - av.y;
			var abz:Number = bv.z - av.z;
			// Вектор AC
			vertex = _vertices[2];
			var cv:Point3D = vertex.spaceCoords;
			var acx:Number = cv.x - av.x;
			var acy:Number = cv.y - av.y;
			var acz:Number = cv.z - av.z;
			// Перпендикуляр к плоскости
			spacePerpendicular.x = acz*aby - acy*abz;
			spacePerpendicular.y = acx*abz - acz*abx;
			spacePerpendicular.z = acy*abx - acx*aby;
			
			//TODO: проверить на нулевой перпендикуляр
		}
		
		private function preparePointPrimitive():void {
			// Расчёт центра грани
			pointPrimitive.coords.x = 0;
			pointPrimitive.coords.y = 0;
			pointPrimitive.coords.z = 0;
			for each (var vertex:Vertex in _vertices) {
				pointPrimitive.coords.x += vertex.spaceCoords.x;
				pointPrimitive.coords.y += vertex.spaceCoords.y;
				pointPrimitive.coords.z += vertex.spaceCoords.z;
			}
			pointPrimitive.coords.x /= _verticesCount;
			pointPrimitive.coords.y /= _verticesCount;
			pointPrimitive.coords.z /= _verticesCount;
		}
		
		private function preparePolyPrimitive():void {
			// Расчёт смещения плоскости
			
			// Установка приоритета
			polyPrimitive.bspLevel = _surface._bspLevel;
		}







		alternativa3d function createPointPrimitive():void {
			trace(this, "- createPointPrimitive");

			// Создание точечного примитива
			pointPrimitive = FaceDistancePrimitive.create();
			// Подготовка точечного примитива
			preparePointPrimitive();
			// Добавление примитива в уровень
			_surface._sortingLevel.distancePrimitivesToAdd.push(pointPrimitive);
		}
		
		alternativa3d function createPolyPrimitive():void {
			trace(this, "- createPolyPrimitive");

			// Создание полигонального примитива
			polyPrimitive = FaceBSPPrimitive.create();
			// Подготовка полигонального примитива
			preparePolyPrimitive();
			// Добавление примитива в уровень
			_surface._sortingLevel.bspPrimitivesToAdd.push(polyPrimitive);
		}





		
		alternativa3d function updatePointPrimitive():void {
			trace(this, "- updatePointPrimitive");

			// Удаляем примитив
			pointPrimitive.node.removePrimitive(pointPrimitive);
			// Подготовка точечного примитива
			preparePointPrimitive();
			// Добавление примитива в уровень
			_surface._sortingLevel.distancePrimitivesToAdd.push(pointPrimitive);
		}
		
		alternativa3d function updatePolyPrimitive():void {
			trace(this, "- updatePolyPrimitive");

			// Удаляем примитив
			polyPrimitive.node.removePrimitive(polyPrimitive);
			// Подготовка полигонального примитива
			preparePolyPrimitive();
			// Добавление примитива в уровень
			_surface._sortingLevel.bspPrimitivesToAdd.push(polyPrimitive);
		}




		
		alternativa3d function redrawPointPrimitive():void {
			trace(this, "- redrawPointPrimitive");
			
			// Помечаем примитив на перерисовку
			_surface._sortingLevel.changedPrimitives[pointPrimitive] = true;
		}

		alternativa3d function redrawPolyPrimitive():void {
			trace(this, "- redrawPolyPrimitive");
			
			_surface._sortingLevel.changedPrimitives[polyPrimitive] = true;
		}









		alternativa3d function changePolyToPointPrimitive():void {
			trace(this, "- changePolyToPointPrimitive");

			// Удаляем примитив
			polyPrimitive.node.removePrimitive(polyPrimitive);
			// Смена типа примитива с полигонального на точечный
			FaceBSPPrimitive.defer(polyPrimitive);
			polyPrimitive = null;
			pointPrimitive = FaceDistancePrimitive.create();
			// Подготовка точечного примитива
			preparePointPrimitive();
			// Добавление примитива в уровень
			_surface._sortingLevel.distancePrimitivesToAdd.push(pointPrimitive);
		}

		alternativa3d function changePointToPolyPrimitive():void {
			trace(this, "- changePointToPolyPrimitive");

			// Удаляем примитив
			pointPrimitive.node.removePrimitive(pointPrimitive);
			// Смена типа примитива с точечного на полигональный
			FaceDistancePrimitive.defer(pointPrimitive);
			pointPrimitive = null;
			polyPrimitive = FaceBSPPrimitive.create();
			// Подготовка полигонального примитива
			preparePolyPrimitive();
			// Добавление примитива в уровень
			_surface._sortingLevel.bspPrimitivesToAdd.push(polyPrimitive);
		}




		

		alternativa3d function destroyPointPrimitive():void {
			trace(this, "- destroyPointPrimitive");

			// Удаляем примитив
			pointPrimitive.node.removePrimitive(pointPrimitive);
			// Удаляем примитив
			FaceDistancePrimitive.defer(pointPrimitive);
			pointPrimitive = null;
		}

		alternativa3d function destroyPolyPrimitive():void {
			trace(this, "- destroyPolyPrimitive");

			// Удаляем примитив
			polyPrimitive.node.removePrimitive(polyPrimitive);
			// Разрушаем примитив
			FaceBSPPrimitive.defer(polyPrimitive);
			polyPrimitive = null;
		}
		
		
		
		
		
		
		alternativa3d function updatePolyPrimitiveBSPLevel():void {
			trace(this, "- updatePolyPrimitiveBSPLevel");

			// Удаляем примитив
			polyPrimitive.node.removePrimitive(polyPrimitive);
			// Обновляем приоритет примитива
			polyPrimitive.bspLevel = _surface._bspLevel;
			// Отправляем примитив на добавление в уровень
			_surface._sortingLevel.bspPrimitivesToAdd.push(polyPrimitive);
		}
		
		alternativa3d function changeSurface():void {
			trace(this, "changeSurface");
			
			// Если есть поверхность и материал
			if (_surface != null && _surface._material != null) {
				// Если BSP-сортировка
				if (_surface._sortingMode == 2) {
					// Если есть полигональный примитив
					if (polyPrimitive != null) {
						// Если грань помечена на трансформацию
						if (_mesh._scene.facesToTransform[this]) {
							// Расчитываем перпендикуляр грани
							calculatePerpendicular();
							// Обновление полигонального примитива
							updatePolyPrimitive();
							// Снимаем пометку на трансформацию
							delete _mesh._scene.facesToTransform[this];
						} else {
							// Если изменилась мобильность
							if (polyPrimitive.bspLevel != _surface._bspLevel) {
								// Обновляем мобильность примитива
								updatePolyPrimitiveBSPLevel();
							} else {
								// Отправить полигональный примитив на перерисовку
								redrawPolyPrimitive();
							}
						}
					} else {
						// Если есть точечный примитив
						if (pointPrimitive != null) {
							// Если грань помечена на трансформацию
							if (_mesh._scene.facesToTransform[this]) {
								// Расчитываем перпендикуляр грани
								calculatePerpendicular();
								// Снимаем пометку на трансформацию
								delete _mesh._scene.facesToTransform[this];
							}
							// Смена типа примитива с точечного на полигональный
							changePointToPolyPrimitive();
						} else {
							// Расчитываем перпендикуляр грани
							calculatePerpendicular();
							// Создание полигонального примитива
							createPolyPrimitive();
						}
					}
				} else {
					// Если точечная сортировка
					if (_surface._sortingMode == 1) {
						// Если есть точечный примитив
						if (pointPrimitive != null) {
							// Если грань помечена на трансформацию
							if (_mesh._scene.facesToTransform[this]) {
								// Расчитываем перпендикуляр грани
								calculatePerpendicular();
								// Обновление точечного примитива
								updatePointPrimitive();
								// Снимаем пометку на трансформацию
								delete _mesh._scene.facesToTransform[this];
							} else {
								// Отправить точечный примитив на перерисовку
								redrawPointPrimitive();
							}
						} else {
							// Если есть полигональный примитив
							if (polyPrimitive != null) {
								// Если грань помечена на трансформацию
								if (_mesh._scene.facesToTransform[this]) {
									// Расчитываем перпендикуляр грани
									calculatePerpendicular();
									// Снимаем пометку на трансформацию
									delete _mesh._scene.facesToTransform[this];
								}
								// Смена типа примитива с полигонального на точечный
								changePolyToPointPrimitive();
							} else {
								// Расчитываем перпендикуляр грани
								calculatePerpendicular();
								// Создание точечного примитива
								createPointPrimitive();
							}
						}
					} else {
						// Если нет сортировки
						
					}
				}
			} else {
				// Если был точечный примитив
				if (pointPrimitive != null) {
					// Удаляем точечный примитив
					destroyPointPrimitive();
					// Снимаем пометку на трансформацию
					delete _mesh._scene.facesToTransform[this];
				} else {
					// Если был полигональный примитив
					if (polyPrimitive != null) {
						// Удаляем полигональный примитив
						destroyPolyPrimitive();
						// Снимаем пометку на трансформацию
						delete _mesh._scene.facesToTransform[this];
					}
				}
			}
			// Помечаем пространство на пересчёт
			_mesh._scene.spacesToCalculate[_mesh.space] = true; 
			// Снимаем пометку на смену поверхности
			delete _mesh._scene.facesToChangeSurface[this];
		}

		// Вызывается только при изменении координат хотя бы одной из вершин
		alternativa3d function transform():void {
			trace(this, "transform");
			
			// Расчитываем перпендикуляр
			calculatePerpendicular();
			
			if (pointPrimitive != null) {
				updatePointPrimitive();
			} else {
				updatePolyPrimitive();
			}

			// Помечаем пространство на пересчёт
			_mesh._scene.spacesToCalculate[_mesh.space] = true; 
			// Снимаем пометку на трансформацию
			delete _mesh._scene.facesToTransform[this];
		}

		/**
		 * Массив вершин грани, представленных объектами класса <code>alternativa.engine3d.core.Vertex</code>.
		 * 
		 * @see Vertex
		 */
		public function get vertices():Array {
			return new Array().concat(_vertices);
		}
		
		/**
		 * Количество вершин грани. 
		 */
		public function get verticesCount():uint {
			return _verticesCount;
		}
		
		/**
		 * Полигональный объект, которому принадлежит грань.
		 */
		public function get mesh():Mesh {
			return _mesh;
		}
		
		/**
		 * Поверхность, которой принадлежит грань.
		 */
		public function get surface():Surface {
			return _surface;
		}
		
		/**
		 * Идентификатор грани в полигональном объекте. В случае, если грань не принадлежит ни одному объекту, идентификатор
		 * имеет значение <code>null</code>.
		 */
		public function get id():Object {
			return (_mesh != null) ? _mesh.getFaceId(this) : null;
		}
		
		/**
		 * Нормаль в локальной системе координат.
		 */
		public function get normal():Point3D {
			var res:Point3D = new Point3D();
			var vertex:Vertex = _vertices[0];
			var av:Point3D = vertex.coords;
			vertex = _vertices[1];
			var bv:Point3D = vertex.coords;
			var abx:Number = bv.x - av.x;
			var aby:Number = bv.y - av.y;
			var abz:Number = bv.z - av.z;
			vertex = _vertices[2];
			var cv:Point3D = vertex.coords;
			var acx:Number = cv.x - av.x;
			var acy:Number = cv.y - av.y;
			var acz:Number = cv.z - av.z;
			res.x = acz*aby - acy*abz;
			res.y = acx*abz - acz*abx;
			res.z = acy*abx - acx*aby;
			if (res.x != 0 || res.y != 0 || res.z != 0) {
				var k:Number = Math.sqrt(res.x*res.x + res.y*res.y + res.z*res.z);
				res.x /= k;
				res.y /= k;
				res.z /= k;
			}
			return res;
		}
		
		/**
		 * Множество граней, имеющих общие рёбра с текущей гранью.
		 */
		public function get edgeJoinedFaces():Set {
			var res:Set = new Set(true);
			// Перебираем точки грани
			for (var i:uint = 0; i < _verticesCount; i++) {
				var a:Vertex = _vertices[i];
				var b:Vertex = _vertices[(i < _verticesCount - 1) ? (i + 1) : 0];
				
				// Перебираем грани текущей точки
				for (var key:* in a._faces) {
					var face:Face = key;
					// Если это другая грань и у неё также есть следующая точка
					if (face != this && face._vertices.indexOf(b) >= 0) {
						// Значит у граней общее ребро
						res[face] = true;
					}
				}
			}
			return res;
		}

		/**
		 * Строковое представление грани.
		 * 
		 * @return строковое представление грани
		 */
		public function toString():String {
			var res:String = "[Face ID:" + id + ((_verticesCount > 0) ? " vertices:" : "");
			for (var i:uint = 0; i < _verticesCount; i++) {
				var vertex:Vertex = _vertices[i];
				res += vertex.id + ((i < _verticesCount - 1) ? ", " : "");
			}
			res += "]";
			return res;
		}
	}
}