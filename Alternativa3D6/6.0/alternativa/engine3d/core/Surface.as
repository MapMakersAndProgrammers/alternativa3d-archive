package alternativa.engine3d.core {
	
	import alternativa.engine3d.*;
	import alternativa.engine3d.sorting.SortingLevel;
	import alternativa.engine3d.errors.FaceExistsError;
	import alternativa.engine3d.errors.FaceNotFoundError;
	import alternativa.engine3d.errors.InvalidIDError;
	import alternativa.engine3d.materials.SurfaceMaterial;
	import alternativa.types.Set;
	
	use namespace alternativa3d;
	
	/**
	 * Поверхность &mdash; набор граней, объединённых в группу. Поверхности используются для установки материалов,
	 * визуализирующих грани объекта.
	 */
	public class Surface {
		/**
		 * @private
		 * Меш
		 */
		alternativa3d var _mesh:Mesh;
		/**
		 * @private
		 * Грани
		 */
		alternativa3d var _faces:Set = new Set();
		
		/**
		 * @private
		 * Ссылка на уровень в пространстве
		 */
		alternativa3d var _sortingLevel:SortingLevel;
		
		/**
		 * @private
		 * Номер уровня в пространстве
		 */
		private var sortingLevelIndex:int = 0;
		/**
		 * @private
		 * Режим сортировки
		 */
		alternativa3d var _sortingMode:uint = 1;
		/**
		 * @private
		 * Материал
		 */
		alternativa3d var _material:SurfaceMaterial;
		/**
		 * @private
		 * Приоритет в BSP-дереве
		 */		
		alternativa3d var _bspLevel:int = 0;

		/**
		 * Создание экземпляра поверхности.
		 */		
		public function Surface() {}
		
		
		alternativa3d function changeSortingLevel():void {
			trace(this, "changeSortingLevel");
			
			// Если уровень изменился
			if (_sortingLevel.index != sortingLevelIndex) {
				// Обновляем уровень
				_sortingLevel = _mesh.space.getSortingLevel(sortingLevelIndex);
				
				
				
				
				// Помечаем пространство на пересчёт
				_mesh._scene.spacesToCalculate[_mesh.space] = true; 
				// Снимаем другие пометки поверхности
				delete _mesh._scene.surfacesToChangeSortingMode[this];
				delete _mesh._scene.surfacesToChangeMaterial[this];
				delete _mesh._scene.surfacesToChangeBSPLevel[this];
			}
			// Снимаем пометку о смене уровня
			delete _mesh._scene.surfacesToChangeSortingLevel[this];
		}
		
		alternativa3d function changeSortingMode():void {
			trace(this, "changeSortingMode");

			var surfacesToChangeMaterial:Set = _mesh._scene.surfacesToChangeMaterial;
			var facesToChangeSurface:Set = _mesh._scene.facesToChangeSurface;
			var facesToTransform:Set = _mesh._scene.facesToTransform;

			var key:*;
			var face:Face;
			// Если есть материал
			if (_material != null) {
				// Если BSP-сортировка
				if (_sortingMode == 2) {
					// Обрабатываем грани поверхности
					for (key in _faces) {
						face = key;
						// Если есть полигональный примитив
						if (face.polyPrimitive != null) {
							// Если грань помечена на трансформацию
							if (facesToTransform[face]) {
								// Расчитываем перпендикуляр грани
								face.calculatePerpendicular();
								// Обновление полигонального примитива
								face.updatePolyPrimitive();
								// Снимаем все пометки грани
								delete facesToChangeSurface[face];
								delete facesToTransform[face];
							} else {
								// Если изменилась мобильность
								if (face.polyPrimitive.bspLevel != _bspLevel) {
									// Обновляем мобильность примитива
									face.updatePolyPrimitiveBSPLevel();
									// Снимаем пометку грани на смену поверхности
									delete facesToChangeSurface[face];
								} else {
									// Если изменился материал поверхности или грань изменила поверхность
									if (surfacesToChangeMaterial[this] || facesToChangeSurface[face]) {
										// Отправить полигональный примитив на перерисовку
										face.redrawPolyPrimitive();
										// Снимаем пометку грани на смену поверхности
										delete facesToChangeSurface[face];
									}
								}
							}
						} else {
							// Если есть точечный примитив
							if (face.pointPrimitive != null) {
								// Если грань помечена на трансформацию
								if (facesToTransform[face]) {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Снимаем пометку на трансформацию
									delete facesToTransform[face];
								}
								// Смена типа примитива с точечного на полигональный
								face.changePointToPolyPrimitive();
							} else {
								// Расчитываем перпендикуляр грани
								face.calculatePerpendicular();
								// Создание полигонального примитива
								face.createPolyPrimitive();
							}
							// Снимаем пометку грани на смену поверхности
							delete facesToChangeSurface[face];
						}
					}
				} else {
					// Если сортировка по расстоянию
					if (_sortingMode == 1) {
						// Обрабатываем грани поверхности
						for (key in _faces) {
							face = key;
							// Если есть точечный примитив
							if (face.pointPrimitive != null) {
								// Если грань помечена на трансформацию
								if (facesToTransform[face]) {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Обновление точечного примитива
									face.updatePointPrimitive();
									// Снимаем все пометки грани
									delete facesToChangeSurface[face];
									delete facesToTransform[face];
								} else {
									// Если изменился материал поверхности или грань изменила поверхность
									if (surfacesToChangeMaterial[this] || facesToChangeSurface[face]) {
										// Отправить точечный примитив на перерисовку
										face.redrawPointPrimitive();
										// Снимаем пометку грани на смену поверхности
										delete facesToChangeSurface[face];
									}
								}
							} else {
								// Если есть полигональный примитив
								if (face.polyPrimitive != null) {
									// Если грань помечена на трансформацию
									if (facesToTransform[face]) {
										// Расчитываем перпендикуляр грани
										face.calculatePerpendicular();
										// Снимаем пометку на трансформацию
										delete facesToTransform[face];
									}
									// Смена типа примитива с полигонального на точечный
									face.changePolyToPointPrimitive();
								} else {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Создание точечного примитива
									face.createPointPrimitive();
								}
								// Снимаем пометку грани на смену поверхности
								delete facesToChangeSurface[face];
							}
						}
					} else {
						// Если нет сортировки
						
					}
				}
			} else {
				// Обрабатываем грани поверхности
				for (key in _faces) {
					face = key;
					// Если есть точечный примитив
					if (face.pointPrimitive != null) {
						// Удаляем точечный примитив
						face.destroyPointPrimitive();
						// Снимаем пометку на трансформацию
						delete facesToTransform[face];
					} else {
						// Если есть полигональный примитив
						if (face.polyPrimitive != null) {
							// Удаляем полигональный примитив
							face.destroyPolyPrimitive();
							// Снимаем пометку на трансформацию
							delete facesToTransform[face];
						}
					}
					// Снимаем пометку грани на смену поверхности
					delete facesToChangeSurface[face];
				}
			}
			// Помечаем пространство на пересчёт
			_mesh._scene.spacesToCalculate[_mesh.space] = true; 
			// Снимаем все пометки поверхности
			delete _mesh._scene.surfacesToChangeSortingMode[this];
			delete surfacesToChangeMaterial[this];
			delete _mesh._scene.surfacesToChangeBSPLevel[this];
		}

 		alternativa3d function changeMaterial():void {
  			trace(this, "changeMaterial");
	 		
			var facesToChangeSurface:Set = _mesh._scene.facesToChangeSurface;
			var facesToTransform:Set = _mesh._scene.facesToTransform;
	 		
			var key:*;
			var face:Face;
			// Если есть материал
			if (_material != null) {
				// Если BSP-сортировка
				if (_sortingMode == 2) {
					// Обрабатываем грани поверхности
					for (key in _faces) {
						face = key;
						// Если есть полигональный примитив
						if (face.polyPrimitive != null) {
							// Если грань помечена на трансформацию
							if (facesToTransform[face]) {
								// Расчитываем перпендикуляр грани
								face.calculatePerpendicular();
								// Обновление точечного примитива
								face.updatePolyPrimitive();
								// Снимаем пометку на трансформацию
								delete facesToTransform[face];
							} else {
								// Если изменилась мобильность
								if (face.polyPrimitive.bspLevel != _bspLevel) {
									// Обновляем мобильность примитива
									face.updatePolyPrimitiveBSPLevel();
								} else {
									// Отправить примитив на перерисовку
									face.redrawPolyPrimitive();
								}
							}
						} else {
							// Если есть точечный примитив
							if (face.pointPrimitive != null) {
								// Если грань помечена на трансформацию
								if (facesToTransform[face]) {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Снимаем пометку на трансформацию
									delete facesToTransform[face];
								}
								// Смена типа примитива с полигонального на точечный
								face.changePointToPolyPrimitive();
							} else {
								// Расчитываем перпендикуляр грани
								face.calculatePerpendicular();
								// Создание точечного примитива
								face.createPolyPrimitive();
							}
						}
						// Снимаем пометку грани на смену поверхности
						delete facesToChangeSurface[face];
					}					
				} else {
					// Если сортировка по расстоянию
					if (_sortingMode == 1) {
						// Обрабатываем грани поверхности
						for (key in _faces) {
							face = key;
							// Если есть точечный примитив
						 	if (face.pointPrimitive != null) {
								// Если грань помечена на трансформацию
								if (facesToTransform[face]) {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Обновление точечного примитива
									face.updatePointPrimitive();
									// Снимаем пометку на трансформацию
									delete facesToTransform[face];
								} else {
									// Отправить примитив на перерисовку
									face.redrawPointPrimitive();
								}
							} else {
								// Если есть полигональный примитив
								if (face.polyPrimitive != null) {
									// Если грань помечена на трансформацию
									if (facesToTransform[face]) {
										// Расчитываем перпендикуляр грани
										face.calculatePerpendicular();
										// Снимаем пометку на трансформацию
										delete facesToTransform[face];
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
							delete facesToChangeSurface[face];
						}
					} else {
						// Если нет сортировки
						
					}
				}
			} else {
				// Обрабатываем грани поверхности
				for (key in _faces) {
					face = key;
					// Если есть точечный примитив
					if (face.pointPrimitive != null) {
						// Удаляем точечный примитив
						face.destroyPointPrimitive();
						// Снимаем пометку на трансформацию
						delete facesToTransform[face];
					} else {
						// Если есть полигональный примитив
						if (face.polyPrimitive != null) {
							// Удаляем полигональный примитив
							face.destroyPolyPrimitive();
							// Снимаем пометку на трансформацию
							delete facesToTransform[face];
						}
					}
					// Снимаем пометку грани на смену поверхности
					delete facesToChangeSurface[face];
				}
			}
			// Помечаем пространство на пересчёт
			_mesh._scene.spacesToCalculate[_mesh.space] = true; 
			// Снимаем все пометки поверхности
			delete _mesh._scene.surfacesToChangeMaterial[this];
			delete _mesh._scene.surfacesToChangeBSPLevel[this];
		}
 		
		alternativa3d function changeBSPLevel():void {
			trace(this, "changeBSPLevel");
			
			var facesToChangeSurface:Set = _mesh._scene.facesToChangeSurface;
			var facesToTransform:Set = _mesh._scene.facesToTransform;
			
			var key:*;
			var face:Face;
			// Если есть материал
			if (_material != null) {
				// Если BSP-сортировка
				if (_sortingMode == 2) {
					// Обрабатываем грани поверхности
					for (key in _faces) {
						face = key;
						// Если есть полигональный примитив
						if (face.polyPrimitive != null) {
							// Если грань помечена на трансформацию
							if (facesToTransform[face]) {
								// Расчитываем перпендикуляр грани
								face.calculatePerpendicular();
								// Обновление полигонального примитива
								face.updatePolyPrimitive();
								// Снимаем все пометки грани
								delete facesToChangeSurface[face];
								delete facesToTransform[face];
							} else {
								// Если изменилась мобильность
								if (face.polyPrimitive.bspLevel != _bspLevel) {
									// Обновляем мобильность примитива
									face.updatePolyPrimitiveBSPLevel();
									// Снимаем пометку грани на смену поверхности
									delete facesToChangeSurface[face];
								} else {
									// Если грань изменила поверхность
									if (facesToChangeSurface[face]) {
										// Отправить полигональный примитив на перерисовку
										face.redrawPolyPrimitive();
										// Снимаем пометку грани на смену поверхности
										delete facesToChangeSurface[face];
									}
								}
							}
						} else {
							// Если есть точечный примитив
							if (face.pointPrimitive != null) {
								// Если грань помечена на трансформацию
								if (facesToTransform[face]) {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Снимаем пометку на трансформацию
									delete facesToTransform[face];
								}
								// Смена типа примитива с точечного на полигональный
								face.changePointToPolyPrimitive();
							} else {
								// Расчитываем перпендикуляр грани
								face.calculatePerpendicular();
								// Создание полигонального примитива
								face.createPolyPrimitive();
							}
							// Снимаем пометку грани на смену поверхности
							delete facesToChangeSurface[face];
						}
					}
				} else {
					// Если сортировка по расстоянию
					if (_sortingMode == 1) {
						// Обрабатываем грани поверхности
						for (key in _faces) {
							face = key;
							// Если есть точечный примитив
							if (face.pointPrimitive != null) {
								// Если грань помечена на трансформацию
								if (facesToTransform[face]) {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Обновление точечного примитива
									face.updatePointPrimitive();
									// Снимаем все пометки грани
									delete facesToChangeSurface[face];
									delete facesToTransform[face];
								} else {
									// Если грань изменила поверхность
									if (facesToChangeSurface[face]) {
										// Отправить точечный примитив на перерисовку
										face.redrawPointPrimitive();
										// Снимаем пометку грани на смену поверхности
										delete facesToChangeSurface[face];
									}
								}
							} else {
								// Если есть полигональный примитив
								if (face.polyPrimitive != null) {
									// Если грань помечена на трансформацию
									if (facesToTransform[face]) {
										// Расчитываем перпендикуляр грани
										face.calculatePerpendicular();
										// Снимаем пометку на трансформацию
										delete facesToTransform[face];
									}
									// Смена типа примитива с полигонального на точечный
									face.changePolyToPointPrimitive();
								} else {
									// Расчитываем перпендикуляр грани
									face.calculatePerpendicular();
									// Создание точечного примитива
									face.createPointPrimitive();
								}
								// Снимаем пометку грани на смену поверхности
								delete facesToChangeSurface[face];									
							}
						}
					} else {
						// Если нет сортировки

					}
				}
			} else {
				// Обрабатываем грани поверхности
				for (key in _faces) {
					face = key;
					// Если есть точечный примитив
					if (face.pointPrimitive != null) {
						// Удаляем точечный примитив
						face.destroyPointPrimitive();
						// Снимаем пометку на трансформацию
						delete facesToTransform[face];
					} else {
						// Если есть полигональный примитив
						if (face.polyPrimitive != null) {
							// Удаляем полигональный примитив
							face.destroyPolyPrimitive();
							// Снимаем пометку на трансформацию
							delete facesToTransform[face];
						}
					}
					// Снимаем пометку грани на смену поверхности
					delete facesToChangeSurface[face];
				}
			}
			// Помечаем пространство на пересчёт
			_mesh._scene.spacesToCalculate[_mesh.space] = true; 
			// Снимаем все пометки поверхности
			delete _mesh._scene.surfacesToChangeBSPLevel[this];
		}
		
		/**
		 * Добавление грани в поверхность.
		 *  
		 * @param face экземпляр класса <code>alternativa.engine3d.core.Face</code> или идентификатор грани полигонального объекта
		 * 
		 * @throws alternativa.engine3d.errors.FaceNotFoundError грань не найдена в полигональном объекте содержащем поверхность
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 * @throws alternativa.engine3d.errors.FaceExistsError поверхность уже содержит указанную грань
		 * 
		 * @see Face 
		 */
		public function addFace(face:Object):void {
			var byLink:Boolean = face is Face;
			
			// Проверяем на нахождение поверхности в меше
			if (_mesh == null) {
				throw new FaceNotFoundError(face, this);
			}
			
			// Проверяем на null
			if (face == null) {
				throw new FaceNotFoundError(null, this);
			}
			
			// Проверяем наличие грани в меше
			if (byLink) {
				// Если удаляем по ссылке
				if (Face(face)._mesh != _mesh) {
					// Если грань не в меше
					throw new FaceNotFoundError(face, this);
				}
			} else {
				// Если удаляем по ID
				if (_mesh._faces[face] == undefined) {
					// Если нет грани с таким ID
					throw new FaceNotFoundError(face, this);
				} else { 
					if (!(_mesh._faces[face] is Face)) {
						throw new InvalidIDError(face, this);
					}
				}
			}
			
			// Находим грань
			var f:Face = byLink ? Face(face) : _mesh._faces[face];
			
			// Проверяем наличие грани в поверхности
			if (_faces[f]) {
				// Если грань уже в поверхности
				throw new FaceExistsError(f, this);
			}
			
			// Проверяем грань на нахождение в другой поверхности
			if (f._surface != null) {
				// Удаляем её из той поверхности
				delete f._surface._faces[f];
			}
			
			// Добавляем грань в поверхность
			_faces[f] = true;
			// Указываем поверхность грани
			f._surface = this;
			
			// Помечаем грань на смену поверхности
			if (_mesh != null && _mesh._scene != null) {
				_mesh._scene.facesToChangeSurface[f] = true;
			}
		}

		/**
		 * Удаление грани из поверхности.
		 *  
		 * @param face экземпляр класса <code>alternativa.engine3d.core.Face</code> или идентификатор грани полигонального объекта
		 * 
		 * @throws alternativa.engine3d.errors.FaceNotFoundError поверхность не содержит указанную грань
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 * 
		 * @see Face
		 */
		public function removeFace(face:Object):void {
			var byLink:Boolean = face is Face;
			
			// Проверяем на нахождение поверхности в меше
			if (_mesh == null) {
				throw new FaceNotFoundError(face, this);
			}
			
			// Проверяем на null
			if (face == null) {
				throw new FaceNotFoundError(null, this);
			}
			
			// Проверяем наличие грани в меше
			if (byLink) {
				// Если удаляем по ссылке
				if (Face(face)._mesh != _mesh) {
					// Если грань не в меше
					throw new FaceNotFoundError(face, this);
				}
			} else {
				// Если удаляем по ID
				if (_mesh._faces[face] == undefined) {
					// Если нет грани с таким ID
					throw new FaceNotFoundError(face, this);
				} else {
					if (!(_mesh._faces[face] is Face)) {
						throw new InvalidIDError(face, this);
					}
				}
				
			}
			
			// Находим грань
			var f:Face = byLink ? Face(face) : _mesh._faces[face];
			
			// Проверяем наличие грани в поверхности
			if (!_faces[f]) {
				// Если грань не в поверхности
				throw new FaceNotFoundError(f, this);
			}
			
			// Удаляем грань из поверхности
			delete _faces[f];
			// Удаляем ссылку на поверхность грани
			f._surface = null;
			
			// Помечаем грань на смену поверхности
			if (_mesh != null && _mesh._scene != null) {
				_mesh._scene.facesToChangeSurface[f] = true;
			}
			
		}
		
		/**
		 * Полигональный объект, которому принадлежит поверхность.
		 */		
		public function get mesh():Mesh {
			return _mesh;
		}
		
		/**
		 * Набор граней поверхности.
		 */
		public function get faces():Set {
			return _faces.clone();
		}

		/**
		 * Уровень сортировки. 
		 */
		public function get sortingLevel():int {
			return sortingLevelIndex;
		}

		/**
		 * @private
		 */
		public function set sortingLevel(value:int):void {
			if (sortingLevelIndex != value) {
				sortingLevelIndex = value;
				if (_mesh != null && _mesh._scene != null) {
					_mesh._scene.surfacesToChangeSortingLevel[this] = true;
				}
			}
		}
		
		/**
		 * Режим сортировки граней поверхности. 
		 */
		public function get sortingMode():uint {
			return _sortingMode;
		}

		/**
		 * @private
		 */
		public function set sortingMode(value:uint):void {
			if (_sortingMode != value) {
				_sortingMode = value;
				if (_mesh != null && _mesh._scene != null) {
					_mesh._scene.surfacesToChangeSortingMode[this] = true;
				}
			}
		}
		
		/**
		 * Материал поверхности. При установке нового значения, устанавливаемый материал будет удалён из старой поверхности.
		 */
		public function get material():SurfaceMaterial {
			return _material;
		}

		/**
		 * @private
		 */
		public function set material(value:SurfaceMaterial):void {
			if (_material != value) {
				// Если был материал
				if (_material != null) {
					// Удалить материал из поверхности
					_material._surface = null;
				}
				// Если новый материал
				if (value != null) {
					// Если материал был в другой поверхности
					var oldSurface:Surface = value._surface; 
					if (oldSurface != null) {
						// Удалить его оттуда
						oldSurface._material = null;
						// Если есть сцена, помечаем смену материала
						if (oldSurface._mesh != null && oldSurface._mesh._scene != null) {
							oldSurface._mesh._scene.surfacesToChangeMaterial[oldSurface] = true;
						}
						
					}
					// Добавить материал в поверхность
					value._surface = this;
				}
				// Если есть сцена, помечаем смену материала
				if (_mesh != null && _mesh._scene != null) {
					_mesh._scene.surfacesToChangeMaterial[this] = true;
				}
				// Сохраняем материал
				_material = value;
			}
		}
		
		/**
		 * Приоритет BSP. Приоритет влияет на положение граней в BSP-дереве.
		 */
		public function get bspLevel():int {
			return _bspLevel;
		}
		
		/**
		 * @private
		 */
		public function set bspLevel(value:int):void {
			if (_bspLevel != value) {
				_bspLevel = value;
				if (_mesh != null && _mesh._scene != null) {
					_mesh._scene.surfacesToChangeBSPLevel[this] = true;
				}
			}
		}
		
		/**
		 * Идентификатор поверхности в полигональном объекте. Если поверхность не принадлежит ни одному объекту,
		 * значение идентификатора равно <code>null</code>.
		 */
		public function get id():Object {
			return (_mesh != null) ? _mesh.getSurfaceId(this) : null;
		}
		
		/**
		 * Строковое представление объекта.
		 * 
		 * @return строковое представление объекта
		 */
		public function toString():String {
			var length:uint = _faces.length;
			var res:String = "[Surface ID:" + id + ((length > 0) ? " faces:" : "");
			var i:uint = 0;
			for (var key:* in _faces) {
				var face:Face = key;
				res += face.id + ((i < length - 1) ? ", " : "");
				i++;
			}
			res += "]";
			return res;
		}		
	}
}