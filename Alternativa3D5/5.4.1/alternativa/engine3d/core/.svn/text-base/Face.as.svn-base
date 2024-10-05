package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.types.Point3D;
	import alternativa.types.Set;

	import flash.geom.Matrix;
	import flash.geom.Point;

	use namespace alternativa3d;

	/**
	 * Грань, образованная тремя или более вершинами. Грани являются составными частями полигональных объектов. Каждая грань
	 * содержит информацию об объекте и поверхности, которым она принадлежит. Для обеспечения возможности наложения
	 * текстуры на грань, первым трём её вершинам могут быть заданы UV-координаты, на основании которых расчитывается
	 * матрица трансформации текстуры.
	 */
	final public class Face {
		// Операции
		/**
		 * @private
		 * Расчёт глобальной нормали плоскости грани.
		 */		
		alternativa3d var calculateNormalOperation:Operation = new Operation("calculateNormal", this, calculateNormal, Operation.FACE_CALCULATE_NORMAL);
		/**
		 * @private
		 * Расчёт UV-координат (выполняется до трансформации, чтобы UV корректно разбились при построении BSP).
		 */		 
		alternativa3d var calculateUVOperation:Operation = new Operation("calculateUV", this, calculateUV, Operation.FACE_CALCULATE_UV);
		/**
		 * @private
		 * Обновление примитива в сцене.
		 */		 
		alternativa3d var updatePrimitiveOperation:Operation = new Operation("updatePrimitive", this, updatePrimitive, Operation.FACE_UPDATE_PRIMITIVE);
		/**
		 * @private
		 * Обновление материала.
		 */		 
		alternativa3d var updateMaterialOperation:Operation = new Operation("updateMaterial", this, updateMaterial, Operation.FACE_UPDATE_MATERIAL);
		/**
		 * @private
		 * Расчёт UV для фрагментов (выполняется после трансформации, если её не было).
		 */
		alternativa3d var calculateFragmentsUVOperation:Operation = new Operation("calculateFragmentsUV", this, calculateFragmentsUV, Operation.FACE_CALCULATE_FRAGMENTS_UV);
		
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
		alternativa3d var _vertices:Array;
		/**
		 * @private
		 * Количество вершин
		 */
		alternativa3d var _verticesCount:uint;
		/**
		 * @private
		 * Примитив
		 */
		alternativa3d var primitive:PolyPrimitive;

		// UV-координаты
		/**
		 * @private
		 */		
		alternativa3d var _aUV:Point;
		/**
		 * @private
		 */		
		alternativa3d var _bUV:Point;
		/**
		 * @private
		 */		
		alternativa3d var _cUV:Point;
		
		/**
		 * @private
		 * Коэффициенты базовой UV-матрицы
		 */
		alternativa3d var uvMatrixBase:Matrix;
		
		/**
		 * @private
		 * UV Матрица перевода текстурных координат в изометрическую камеру. 
		 */
		alternativa3d var uvMatrix:Matrix;
		/**
		 * @private
		 * Нормаль плоскости
		 */
		alternativa3d var globalNormal:Point3D = new Point3D();
		/**
		 * @private
		 * Смещение плоскости
		 */		
		alternativa3d var globalOffset:Number;

		/**
		 * Создание экземпляра грани.
		 * 
		 * @param vertices массив объектов типа <code>alternativa.engine3d.core.Vertex</code>, задающий вершины грани в
		 * порядке обхода лицевой стороны грани против часовой стрелки.
		 * 
		 * @see Vertex
		 */				
		public function Face(vertices:Array) {
			// Сохраняем вершины
			_vertices = vertices;
			_verticesCount = vertices.length;

			// Создаём оригинальный примитив
			primitive = PolyPrimitive.createPolyPrimitive();
			primitive.face = this;
			primitive.num = _verticesCount;
			
			// Обрабатываем вершины
			for (var i:uint = 0; i < _verticesCount; i++) {
				var vertex:Vertex = vertices[i];
				// Добавляем координаты вершины в примитив
				primitive.points.push(vertex.globalCoords);
				// Добавляем пустые UV-координаты в примитив
				primitive.uvs.push(null);
				// Добавляем вершину в грань
				vertex.addToFace(this);
			}

			// Расчёт нормали
			calculateNormalOperation.addSequel(updatePrimitiveOperation);
			
			// Расчёт UV грани инициирует расчёт UV фрагментов и перерисовку
			calculateUVOperation.addSequel(calculateFragmentsUVOperation);
			calculateUVOperation.addSequel(updateMaterialOperation);
		}
		
		/**
		 * @private
		 * Расчёт нормали в глобальных координатах
		 */
		private function calculateNormal():void {
			// Вектор AB
			var vertex:Vertex = _vertices[0];
			var av:Point3D = vertex.globalCoords;
			vertex = _vertices[1];
			var bv:Point3D = vertex.globalCoords;
			var abx:Number = bv.x - av.x;
			var aby:Number = bv.y - av.y;
			var abz:Number = bv.z - av.z;
			// Вектор AC
			vertex = _vertices[2];
			var cv:Point3D = vertex.globalCoords;
			var acx:Number = cv.x - av.x;
			var acy:Number = cv.y - av.y;
			var acz:Number = cv.z - av.z;
			// Перпендикуляр к плоскости
			globalNormal.x = acz*aby - acy*abz;
			globalNormal.y = acx*abz - acz*abx;
			globalNormal.z = acy*abx - acx*aby;
			// Нормализация перпендикуляра
			globalNormal.normalize();
		}
		
		/**
		 * @private
		 * Расчитывает глобальное смещение плоскости грани.
		 * Помечает конечные примитивы на удаление, а базовый на добавление в сцене.  
		 */
		private function updatePrimitive():void {
			// Расчёт смещения
			var vertex:Vertex = _vertices[0];
			globalOffset = vertex.globalCoords.x*globalNormal.x + vertex.globalCoords.y*globalNormal.y + vertex.globalCoords.z*globalNormal.z;

			removePrimitive(primitive);
			primitive.mobility = _mesh.inheritedMobility;
			_mesh._scene.addPrimitives.push(primitive);
		}

		/**
		 * @private
		 * Рекурсивно проходит по фрагментам примитива и отправляет конечные фрагменты на удаление из сцены 
		 */
		private function removePrimitive(primitive:PolyPrimitive):void {
			if (primitive.backFragment != null) {
				removePrimitive(primitive.backFragment);
				removePrimitive(primitive.frontFragment);
				primitive.backFragment = null;
				primitive.frontFragment = null;
				if (primitive != this.primitive) {
					primitive.parent = null;
					primitive.sibling = null;
					PolyPrimitive.destroyPolyPrimitive(primitive);
				}
			} else {
				// Если примитив в BSP-дереве
				if (primitive.node != null) {
					// Удаление примитива
					_mesh._scene.removeBSPPrimitive(primitive);
				}
			}
		}

		/**
		 * @private
		 * Пометка на перерисовку фрагментов грани.
		 */
		private function updateMaterial():void {
			if (!updatePrimitiveOperation.queued) {
				changePrimitive(primitive);
			}
		}
		
		/**
		 * @private
		 * Рекурсивно проходит по фрагментам примитива и отправляет конечные фрагменты на перерисовку
		 */
		private function changePrimitive(primitive:PolyPrimitive):void {
			if (primitive.backFragment != null) {
				changePrimitive(primitive.backFragment);
				changePrimitive(primitive.frontFragment);
			} else {
				_mesh._scene.changedPrimitives[primitive] = true;
			}
		}
		
		/**
		 * @private
		 * Расчёт UV-матрицы на основании первых трёх UV-координат.
		 * Расчёт UV-координат для оставшихся точек. 
		 */
		private function calculateUV():void {
			var i:uint;
			// Расчёт UV-матрицы
			if (_aUV != null && _bUV != null && _cUV != null) {
				var abu:Number = _bUV.x - _aUV.x;
				var abv:Number = _bUV.y - _aUV.y;
				var acu:Number = _cUV.x - _aUV.x;
				var acv:Number = _cUV.y - _aUV.y;
				var det:Number = abu*acv - abv*acu;
				if (det != 0) {
					if (uvMatrixBase == null) {
						uvMatrixBase = new Matrix();
						uvMatrix = new Matrix();
					}
					uvMatrixBase.a = acv/det;
					uvMatrixBase.b = -abv/det;
					uvMatrixBase.c = -acu/det;
					uvMatrixBase.d = abu/det;
					uvMatrixBase.tx = -(uvMatrixBase.a*_aUV.x + uvMatrixBase.c*_aUV.y);
					uvMatrixBase.ty = -(uvMatrixBase.b*_aUV.x + uvMatrixBase.d*_aUV.y);
					
					// Заполняем UV в базовом примитиве
					primitive.uvs[0] = _aUV;
					primitive.uvs[1] = _bUV;
					primitive.uvs[2] = _cUV;
					
					// Расчёт недостающих UV
					if (_verticesCount > 3) {
						var a:Point3D = primitive.points[0];
						var b:Point3D = primitive.points[1];
						var c:Point3D = primitive.points[2];

						var ab1:Number;
						var ab2:Number;
						var ac1:Number;
						var ac2:Number;
						var ad1:Number;
						var ad2:Number;
						var abk:Number;
						var ack:Number;
						
						var uv:Point;
						var point:Point3D;
						
						// Выбор наиболее подходящих осей для расчёта
						if (((globalNormal.x < 0) ? -globalNormal.x : globalNormal.x) > ((globalNormal.y < 0) ? -globalNormal.y : globalNormal.y)) {
							if (((globalNormal.x < 0) ? -globalNormal.x : globalNormal.x) > ((globalNormal.z < 0) ? -globalNormal.z : globalNormal.z)) {
								// Ось X
								ab1 = b.y - a.y;
								ab2 = b.z - a.z;
								ac1 = c.y - a.y;
								ac2 = c.z - a.z;
								det = ab1*ac2 - ac1*ab2;
								for (i = 3; i < _verticesCount; i++) {
									point = primitive.points[i];
									ad1 = point.y - a.y;
									ad2 = point.z - a.z;
									abk = (ad1*ac2 - ac1*ad2)/det;
									ack = (ab1*ad2 - ad1*ab2)/det;
									uv = primitive.uvs[i];
									if (uv == null) {
										uv = new Point();
										primitive.uvs[i] = uv;
									}
									uv.x = _aUV.x + abu*abk + acu*ack;
									uv.y = _aUV.y + abv*abk + acv*ack;
								}
							} else {
								// Ось Z
								ab1 = b.x - a.x;
								ab2 = b.y - a.y;
								ac1 = c.x - a.x;
								ac2 = c.y - a.y;
								det = ab1*ac2 - ac1*ab2;
								for (i = 3; i < _verticesCount; i++) {
									point = primitive.points[i];
									ad1 = point.x - a.x;
									ad2 = point.y - a.y;
									abk = (ad1*ac2 - ac1*ad2)/det;
									ack = (ab1*ad2 - ad1*ab2)/det;
									uv = primitive.uvs[i];
									if (uv == null) {
										uv = new Point();
										primitive.uvs[i] = uv;
									}
									uv.x = _aUV.x + abu*abk + acu*ack;
									uv.y = _aUV.y + abv*abk + acv*ack;
								}
							}
						} else {
							if (((globalNormal.y < 0) ? -globalNormal.y : globalNormal.y) > ((globalNormal.z < 0) ? -globalNormal.z : globalNormal.z)) {
								// Ось Y
								ab1 = b.x - a.x;
								ab2 = b.z - a.z;
								ac1 = c.x - a.x;
								ac2 = c.z - a.z;
								det = ab1*ac2 - ac1*ab2;
								for (i = 3; i < _verticesCount; i++) {
									point = primitive.points[i];
									ad1 = point.x - a.x;
									ad2 = point.z - a.z;
									abk = (ad1*ac2 - ac1*ad2)/det;
									ack = (ab1*ad2 - ad1*ab2)/det;
									uv = primitive.uvs[i];
									if (uv == null) {
										uv = new Point();
										primitive.uvs[i] = uv;
									}
									uv.x = _aUV.x + abu*abk + acu*ack;
									uv.y = _aUV.y + abv*abk + acv*ack;
								}
							} else {
								// Ось Z
								ab1 = b.x - a.x;
								ab2 = b.y - a.y;
								ac1 = c.x - a.x;
								ac2 = c.y - a.y;
								det = ab1*ac2 - ac1*ab2;
								for (i = 3; i < _verticesCount; i++) {
									point = primitive.points[i];
									ad1 = point.x - a.x;
									ad2 = point.y - a.y;
									abk = (ad1*ac2 - ac1*ad2)/det;
									ack = (ab1*ad2 - ad1*ab2)/det;
									uv = primitive.uvs[i];
									if (uv == null) {
										uv = new Point();
										primitive.uvs[i] = uv;
									}
									uv.x = _aUV.x + abu*abk + acu*ack;
									uv.y = _aUV.y + abv*abk + acv*ack;
								}
							}
						}
					}
				} else {
					// Удаляем UV-матрицу
					uvMatrixBase = null;
					uvMatrix = null;
					// Удаляем UV-координаты из базового примитива
					for (i = 0; i < _verticesCount; i++) {
						primitive.uvs[i] = null;
					}
				}
			} else {
				// Удаляем UV-матрицу
				uvMatrixBase = null;
				uvMatrix = null;
				// Удаляем UV-координаты из базового примитива
				for (i = 0; i < _verticesCount; i++) {
					primitive.uvs[i] = null;
				}
			}
		}

		/**
		 * @private 
		 * Расчёт UV-координат для фрагментов примитива, если не было трансформации
		 */
		private function calculateFragmentsUV():void {
			// Если в этом цикле не было трансформации 
			if (!updatePrimitiveOperation.queued) {
				if (uvMatrixBase != null) {
					// Рассчитываем UV в примитиве 
					calculatePrimitiveUV(primitive);
				} else {
					// Удаляем UV в примитиве
					removePrimitiveUV(primitive);
				}
			}
		}
		
		/**
		 * @private
		 * Расчёт UV для точек базового примитива.
		 * 
		 * @param primitive
		 */
		private function calculatePrimitiveUV(primitive:PolyPrimitive):void {
			if (primitive.backFragment	!= null) {
				var points:Array = primitive.points;
				var backPoints:Array = primitive.backFragment.points;
				var frontPoints:Array = primitive.frontFragment.points;
				var uvs:Array = primitive.uvs;
				var backUVs:Array = primitive.backFragment.uvs;
				var frontUVs:Array = primitive.frontFragment.uvs;
				var index1:uint = 0;
				var index2:uint = 0;
				var point:Point3D;
				var uv:Point;
				var uv1:Point;
				var uv2:Point;
				var t:Number;
				var firstSplit:Boolean = true;
				for (var i:uint = 0; i < primitive.num; i++) {
					var split:Boolean = true;
					point = points[i];
					if (point == frontPoints[index2]) {
						if (frontUVs[index2] == null) {
							frontUVs[index2] = uvs[i];
						}
						split = false;
						index2++;
					}
					if (point == backPoints[index1]) {
						if (backUVs[index1] == null) {
							backUVs[index1] = uvs[i];
						}
						split = false;
						index1++;
					}
					
 					if (split) {
						uv1 = uvs[(i == 0) ? (primitive.num - 1) : (i - 1)];
						uv2 = uvs[i];
						t = (firstSplit) ? primitive.splitTime1 : primitive.splitTime2;
						uv = frontUVs[index2];
						if (uv == null) {
							uv = new Point(uv1.x + (uv2.x - uv1.x)*t, uv1.y + (uv2.y - uv1.y)*t);
							frontUVs[index2] = uv;
							backUVs[index1] = uv;
						} else {
							uv.x = uv1.x + (uv2.x - uv1.x)*t;
							uv.y = uv1.y + (uv2.y - uv1.y)*t;
						}
						firstSplit = false;
						index2++;
						index1++;
						if (point == frontPoints[index2]) {
							if (frontUVs[index2] == null) {
								frontUVs[index2] = uvs[i];
							}
							index2++;
						}
						if (point == backPoints[index1]) {
							if (backUVs[index1] == null) {
								backUVs[index1] = uvs[i];
							}
							index1++;
						}
					}
				}
				// Проверяем рассечение последнего ребра
				if (index2 < primitive.frontFragment.num) {
					uv1 = uvs[primitive.num - 1];
					uv2 = uvs[0];
					t = (firstSplit) ? primitive.splitTime1 : primitive.splitTime2;
					uv = frontUVs[index2];
					if (uv == null) {
						uv = new Point(uv1.x + (uv2.x - uv1.x)*t, uv1.y + (uv2.y - uv1.y)*t);
						frontUVs[index2] = uv;
						backUVs[index1] = uv;
					} else {
						uv.x = uv1.x + (uv2.x - uv1.x)*t;
						uv.y = uv1.y + (uv2.y - uv1.y)*t;
					}
				}
				
				calculatePrimitiveUV(primitive.backFragment);
				calculatePrimitiveUV(primitive.frontFragment);
			}
		}
		
		/**
		 * @private
		 * Удаление UV в примитиве и его фрагментах
		 * @param primitive
		 */
		private function removePrimitiveUV(primitive:PolyPrimitive):void {
			// Очищаем список UV
			for (var i:uint = 0; i < primitive.num; i++) {
				primitive.uvs[i] = null;
			}
			// Если есть фрагменты, удаляем UV в них
			if (primitive.backFragment != null) {
				removePrimitiveUV(primitive.backFragment);
				removePrimitiveUV(primitive.frontFragment);
			}
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
		 * UV-координаты, соответствующие первой вершине грани.
		 */
		public function get aUV():Point {
			return (_aUV != null) ? _aUV.clone() : null;
		}
		
		/**
		 * UV-координаты, соответствующие второй вершине грани.
		 */
		public function get bUV():Point {
			return (_bUV != null) ? _bUV.clone() : null;
		}
		
		/**
		 * UV-координаты, соответствующие третьей вершине грани.
		 */
		public function get cUV():Point {
			return (_cUV != null) ? _cUV.clone() : null;
		}
		
		/**
		 * @private
		 */
		public function set aUV(value:Point):void {
			if (_aUV != null) {
				if (value != null) {
					if (!_aUV.equals(value)) {  
						_aUV.x = value.x;
						_aUV.y = value.y;
						if (_mesh != null) {
							_mesh.addOperationToScene(calculateUVOperation);
						}
					}
				} else {
					_aUV = null;
					if (_mesh != null) {
						_mesh.addOperationToScene(calculateUVOperation);
					}
				}
			} else {
				if (value != null) {
					_aUV = value.clone();
					if (_mesh != null) {
						_mesh.addOperationToScene(calculateUVOperation);
					}
				}
			}
		}
		
		/**
		 * @private
		 */
		public function set bUV(value:Point):void {
			if (_bUV != null) {
				if (value != null) {
					if (!_bUV.equals(value)) {  
						_bUV.x = value.x;
						_bUV.y = value.y;
						if (_mesh != null) {
							_mesh.addOperationToScene(calculateUVOperation);
						}
					}
				} else {
					_bUV = null;
					if (_mesh != null) {
						_mesh.addOperationToScene(calculateUVOperation);
					}
				}
			} else {
				if (value != null) {
					_bUV = value.clone();
					if (_mesh != null) {
						_mesh.addOperationToScene(calculateUVOperation);
					}
				}
			}
		}
		
		/**
		 * @private
		 */
		public function set cUV(value:Point):void {
			if (_cUV != null) {
				if (value != null) {
					if (!_cUV.equals(value)) {  
						_cUV.x = value.x;
						_cUV.y = value.y;
						if (_mesh != null) {
							_mesh.addOperationToScene(calculateUVOperation);
						}
					}
				} else {
					_cUV = null;
					if (_mesh != null) {
						_mesh.addOperationToScene(calculateUVOperation);
					}
				}
			} else {
				if (value != null) {
					_cUV = value.clone();
					if (_mesh != null) {
						_mesh.addOperationToScene(calculateUVOperation);
					}
				}
			}
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
		 * Расчёт UV-координат для произвольной точки в системе координат объекта, которому принадлежит грань.
		 * 
		 * @param point точка в плоскости грани, для которой производится расчёт UV-координат
		 * @return UV-координаты заданной точки
		 */		
		public function getUV(point:Point3D):Point {
			return getUVFast(point, normal);
		}

		/**
		 * @private
		 * Расчёт UV-координат для произвольной точки в локальной системе координат без расчёта 
		 * локальной нормали грани. Используется для оптимизации.
		 * 
		 * @param point точка в плоскости грани, для которой производится расчёт UV-координат
		 * @param normal нормаль плоскости грани в локальной системе координат
		 * @return UV-координаты заданной точки
		 */
		alternativa3d function getUVFast(point:Point3D, normal:Point3D):Point {
			if (_aUV == null || _bUV == null || _cUV == null) {
				return null;
			}

			// Выбор наиболее длинной оси нормали
			var dir:uint; 
			if (((normal.x < 0) ? -normal.x : normal.x) > ((normal.y < 0) ? -normal.y : normal.y)) {
				if (((normal.x < 0) ? -normal.x : normal.x) > ((normal.z < 0) ? -normal.z : normal.z)) {
					dir = 0;
				} else {
					dir = 2;
				}
			} else {
				if (((normal.y < 0) ? -normal.y : normal.y) > ((normal.z < 0) ? -normal.z : normal.z)) {
					dir = 1;
				} else {
					dir = 2;
				}
			}
			
			// Расчёт соотношения по векторам AB и AC
			var v:Vertex = _vertices[0];
			var a:Point3D = v._coords;
			v = _vertices[1];
			var b:Point3D = v._coords;
			v = _vertices[2];
			var c:Point3D = v._coords;
						
			var ab1:Number = (dir == 0) ? (b.y - a.y) : (b.x - a.x);
			var ab2:Number = (dir == 2) ? (b.y - a.y) : (b.z - a.z);
			var ac1:Number = (dir == 0) ? (c.y - a.y) : (c.x - a.x);
			var ac2:Number = (dir == 2) ? (c.y - a.y) : (c.z - a.z);
			var det:Number = ab1*ac2 - ac1*ab2;
				
			var ad1:Number = (dir == 0) ? (point.y - a.y) : (point.x - a.x);
			var ad2:Number = (dir == 2) ? (point.y - a.y) : (point.z - a.z);
			var abk:Number = (ad1*ac2 - ac1*ad2)/det;
			var ack:Number = (ab1*ad2 - ad1*ab2)/det;
			
			// Интерполяция по UV первых точек
			var abu:Number = _bUV.x - _aUV.x;
			var abv:Number = _bUV.y - _aUV.y;
			var acu:Number = _cUV.x - _aUV.x;
			var acv:Number = _cUV.y - _aUV.y;
							
			return new Point(_aUV.x + abu*abk + acu*ack, _aUV.y + abv*abk + acv*ack);
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
		 * @private
		 * Удаление всех вершин из грани.
		 * Очистка базового примитива. 
		 */
		alternativa3d function removeVertices():void {
			// Удалить вершины
			for (var i:uint = 0; i < _verticesCount; i++) {
				// Удаляем из списка
				var vertex:Vertex = _vertices.pop();
				// Удаляем координаты вершины из примитива
				primitive.points.pop();
				// Удаляем вершину из грани
				vertex.removeFromFace(this);
			}
			// Обнуляем количество вершин
			_verticesCount = 0;
		}
		
		/**
		 * @private
		 * Добавление грани на сцену 
		 * @param scene
		 */
		alternativa3d function addToScene(scene:Scene3D):void {
			// При добавлении на сцену рассчитываем плоскость и UV
			scene.addOperation(calculateNormalOperation);
			scene.addOperation(calculateUVOperation);
			
			// Подписываем сцену на операции
			updatePrimitiveOperation.addSequel(scene.calculateBSPOperation);
			updateMaterialOperation.addSequel(scene.changePrimitivesOperation);
		}
		
		/**
		 * @private
		 * Удаление грани из сцены
		 * @param scene
		 */
		alternativa3d function removeFromScene(scene:Scene3D):void {
			// Удаляем все операции из очереди
			scene.removeOperation(calculateUVOperation);
			scene.removeOperation(calculateFragmentsUVOperation);
			scene.removeOperation(calculateNormalOperation);
			scene.removeOperation(updatePrimitiveOperation);
			scene.removeOperation(updateMaterialOperation);

			// Удаляем примитивы из сцены
			removePrimitive(primitive);

			// Посылаем операцию сцены на расчёт BSP
			scene.addOperation(scene.calculateBSPOperation);
					
			// Отписываем сцену от операций
			updatePrimitiveOperation.removeSequel(scene.calculateBSPOperation);
			updateMaterialOperation.removeSequel(scene.changePrimitivesOperation);
		}
		
		/**
		 * @private
		 * Добавление грани в меш
		 * @param mesh
		 */
		alternativa3d function addToMesh(mesh:Mesh):void {
			// Подписка на операции меша
			mesh.changeCoordsOperation.addSequel(updatePrimitiveOperation);
			mesh.changeRotationOrScaleOperation.addSequel(calculateNormalOperation);
			mesh.calculateMobilityOperation.addSequel(updatePrimitiveOperation);
			// Сохранить меш
			_mesh = mesh;
		}
		
		/**
		 * @private
		 * Удаление грани из меша
		 * @param mesh
		 */
		alternativa3d function removeFromMesh(mesh:Mesh):void {
			// Отписка от операций меша
			mesh.changeCoordsOperation.removeSequel(updatePrimitiveOperation);
			mesh.changeRotationOrScaleOperation.removeSequel(calculateNormalOperation);
			mesh.calculateMobilityOperation.removeSequel(updatePrimitiveOperation);
			// Удалить ссылку на меш
			_mesh = null;
		}

		/**
		 * @private
		 * Добавление к поверхности
		 * 
		 * @param surface
		 */		
		alternativa3d function addToSurface(surface:Surface):void {
			// Подписка поверхности на операции
			surface.changeMaterialOperation.addSequel(updateMaterialOperation);
			// Если при смене поверхности изменился материал
			if (_mesh != null && (_surface != null && _surface._material != surface._material || _surface == null && surface._material != null)) {
				// Отправляем сигнал смены материала
				_mesh.addOperationToScene(updateMaterialOperation);
			}
			// Сохранить поверхность
			_surface = surface;
		}
		
		/**
		 * @private
		 * Удаление из поверхности
		 * 
		 * @param surface
		 */		
		alternativa3d function removeFromSurface(surface:Surface):void {
			// Отписка поверхности от операций
			surface.changeMaterialOperation.removeSequel(updateMaterialOperation);
			// Если был материал
			if (surface._material != null) {
				// Отправляем сигнал смены материала
				_mesh.addOperationToScene(updateMaterialOperation);
			}
			// Удалить ссылку на поверхность
			_surface = null;
		}

		/**
		 * Строковое представление объекта.
		 * 
		 * @return строковое представление объекта
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