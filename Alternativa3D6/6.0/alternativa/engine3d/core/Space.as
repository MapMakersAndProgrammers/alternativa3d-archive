package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.engine3d.materials.SpaceMaterial;
	import alternativa.engine3d.sorting.DistanceNode;
	import alternativa.engine3d.sorting.SortingLevel;
	import alternativa.types.Matrix3D;
	import alternativa.types.Point3D;
	import alternativa.engine3d.errors.InvalidSortingModeError;
	
	use namespace alternativa3d;
	
	public final class Space extends Object3D {
		
		// Инкремент количества пространств
		private static var counter:uint = 0;
		
		/**
		 * @private
		 * Режим сортировки
		 */
		alternativa3d var _sortingMode:uint = 1;
		
		/**
		 * @private
		 * Материал
		 */
		alternativa3d var _material:SpaceMaterial;

		/**
		 * @private
		 * Матрица перевода из локальной системы координат объекта в глобальную
		 */	
		alternativa3d var globalMatrix:Matrix3D = new Matrix3D();

		/**
		 * @private
		 * Первый элемент списка уровней
		 */
		alternativa3d var firstLevel:SortingLevel;
		
		/**
		 * @private
		 * Номер уровня в пространстве
		 */
		private var sortingLevelIndex:int = 0;

		/**
		 * @private
		 * Ссылка на уровень в пространстве
		 */
		private var _sortingLevel:SortingLevel;

		/**
		 * @private
		 * Нода в которой находится спрайт
		 */		
		alternativa3d var node:DistanceNode;
		
		/**
		 * @private
		 * Вспомогательная матрица перевода из системы координат пространства в систему камеры
		 */		
		alternativa3d var cameraMatrix:Matrix3D = new Matrix3D();
		
		/**
		 * @private
		 * Вспомогательная матрица перевода из системы координат камеры в систему пространства
		 */		
		alternativa3d var inverseCameraMatrix:Matrix3D = new Matrix3D();

		// Синус половинчатого угла обзора камеры
		alternativa3d var viewAngle:Number;
		
		// Направление камеры
		alternativa3d var direction:Point3D = new Point3D(0, 0, 1);
		
		// Плоскости отсечения
		alternativa3d var leftPlane:Point3D = new Point3D();
		alternativa3d var rightPlane:Point3D = new Point3D();
		alternativa3d var topPlane:Point3D = new Point3D();
		alternativa3d var bottomPlane:Point3D = new Point3D();
		alternativa3d var leftOffset:Number;
		alternativa3d var rightOffset:Number;
		alternativa3d var topOffset:Number;
		alternativa3d var bottomOffset:Number;
		
		public function Space(name:String = null) {
			super(name);
		}

		override protected function transform():void {
			
			if (_parent != null) {
				
				super.transform();
			
				if (_material != null) {
					if (_sortingLevel != null) {
						// Несортируемый
						if (_sortingMode == 0) {
							// Остался несортируемый
							
							// Помечаем изменение в уровне
							_sortingLevel.changed[this] = true;
							_scene.levelsToClear[_sortingLevel] = true;
							
							// Если изменился уровень
							if (_sortingLevel.space != space || _sortingLevel.index != sortingLevelIndex) {
								// Удаляем из старого уровня
								delete _sortingLevel.spaces[this];
								// Обновляем уровень
								_sortingLevel = space.getSortingLevel(sortingLevelIndex);
								// Добавляем в новый уровень
								_sortingLevel.spaces[this] = true;
								// Помечаем изменение в новом уровне
								_sortingLevel.changed[this] = true;
								_scene.levelsToClear[_sortingLevel] = true;
							}
						} else {
							// Изменился на сортируемый
							
							// Удаляем из списка несортируемых пространств уровня
							delete _sortingLevel.spaces[this];
							// Помечаем изменение в уровне
							_sortingLevel.changed[this] = true;
							_scene.levelsToClear[_sortingLevel] = true;
							
							// Если изменился уровень
							if (_sortingLevel.space != space || _sortingLevel.index != sortingLevelIndex) {
								// Обновляем уровень
								_sortingLevel = space.getSortingLevel(sortingLevelIndex);
							}
							
							// Добавляем в список пространств на сортировку по дистанции
							_sortingLevel.spacesDistance[this] = true;
							_scene.levelsToCalculate[_sortingLevel] = true;
							// Удаляем ссылку на уровень
							_sortingLevel = null;
						}
					} else {
						if (node != null) {
							// Сортируемый


							
							
						} else {
							// Нет в уровне
							
							// Получаем уровень
							_sortingLevel = space.getSortingLevel(sortingLevelIndex);
							
							if (_sortingMode == 0) {
								// Появился несортируемый
								
								// Добавляем в уровень
								_sortingLevel.spaces[this] = true;
								// Помечаем изменение в уровне
								_sortingLevel.changed[this] = true;
								_scene.levelsToClear[_sortingLevel] = true;
								
							} else {
								// Появился сортируемый
								
								// Добавляем в список пространств на сортировку по дистанции
								_sortingLevel.spacesDistance[this] = true;
								_scene.levelsToCalculate[_sortingLevel] = true;
								// Удаляем ссылку на уровень
								_sortingLevel = null;
							}
						}
					}
				} else {
					
					
				}
				
				
				
				
/*			
				// Если есть примитив
				if (primitive != null) {
					// Если изменился уровень
					if (primitive.node.sortingLevel != _sortingLevel) {
						// Обновляем уровень
						_sortingLevel = space.getSortingLevel(sortingLevelIndex);
					}
					// Удаляем примитив
					primitive.node.removePrimitive(primitive);
				} else {
					// Обновляем уровень
					_sortingLevel = space.getSortingLevel(sortingLevelIndex);
					// Создаём примитив
					primitive = SpaceDistancePrimitive.create();
					primitive.space = this;
				}
				
				// Добавляем примитив в уровень
				_sortingLevel.distancePrimitivesToAdd.push(primitive);
				
				// Устанавливаем координаты
				primitive.coords.x = spaceMatrix.d;
				primitive.coords.y = spaceMatrix.h;
				primitive.coords.z = spaceMatrix.l;
*/			
				// Помечаем пространство на глобальную трансформацию
				_scene.spacesToGlobalTransform[this] = true;
				
			} else {
				// Если появился или изменился материал, помечаем на обновление материала
				if (_material != null && _scene.spacesToChangeMaterial[this]) {
					_scene.spacesToUpdateMaterial[this] = true;
				}
			}
			
			// Снимаем пометки пространства
			delete _scene.spacesToChangeSortingMode[this];
			delete _scene.spacesToChangeSortingLevel[this];
			delete _scene.spacesToChangeMaterial[this];
		}

		override protected function move():void {
			super.move();
/*			
			// Если изменился уровень
			if (_sortingLevel.index != sortingLevelIndex) {
				// Обновляем уровень
				_sortingLevel = space.getSortingLevel(sortingLevelIndex);
			}

			// Удаляем примитив
			primitive.node.removePrimitive(primitive);

			// Добавляем примитив в уровень
			_sortingLevel.distancePrimitivesToAdd.push(primitive);

			// Устанавливаем координаты
			primitive.coords.x = spaceMatrix.d;
			primitive.coords.y = spaceMatrix.h;
			primitive.coords.z = spaceMatrix.l;
*/			
			// Помечаем пространство на глобальную трансформацию
			_scene.spacesToGlobalTransform[this] = true;
			
			// Снимаем пометки пространства
			delete _scene.spacesToChangeSortingMode[this];
			delete _scene.spacesToChangeSortingLevel[this];
			delete _scene.spacesToChangeMaterial[this];
		}
/*		
		override alternativa3d function transformBranch():void {
			// Если не корневой объект
			if (_parent != null) {
				// Трансформируем дочернюю ветку
				super.transformBranch();
			} else {
				trace(this, "transformBranch sceneSpace");
				
				
				
				
				// Снимаем все отметки
				delete _scene.objectsToTransform[this];
				delete _scene.objectsToMove[this];
				delete _scene.spacesToChangeSortingMode[this];
				delete _scene.spacesToChangeSortingLevel[this];
				delete _scene.spacesToChangeMaterial[this];
				
			}
		}
		
		override alternativa3d function moveBranch():void {
			
			// Если не корневой объект
			if (_parent != null) {
				super.moveBranch();
			} else {
				trace(this, "moveBranch sceneSpace");

				// Снимаем отметку о перемещении
				delete _scene.objectsToMove[this];
			}
		}
*/		
		alternativa3d function changeSortingMode():void {
			trace(this, "changeSortingMode");
			
			if (parent != null) {
				
				// Снимаем пометку на смену материала
				delete _scene.spacesToChangeMaterial[this];
			}

			// Снимаем пометки пространства
			delete _scene.spacesToChangeSortingMode[this];
			delete _scene.spacesToChangeSortingLevel[this];
		}
		
		alternativa3d function changeSortingLevel():void {
			trace(this, "changeSortingLevel");

			if (parent != null) {
	/*			
				// Если уровень изменился
				if (_sortingLevel.index != sortingLevelIndex) {
					// Обновляем уровень
					_sortingLevel = space.getSortingLevel(sortingLevelIndex);
					
					// Удаляем примитив
					primitive.node.removePrimitive(primitive);
					
					// Добавляем примитив в уровень
					_sortingLevel.distancePrimitivesToAdd.push(primitive);
				}
	*/			
				// Снимаем пометку на смену материала
				delete _scene.spacesToChangeMaterial[this];
			}
			// Снимаем пометки пространства
			delete _scene.spacesToChangeSortingLevel[this];
		}
		
		alternativa3d function changeMaterial():void {
			trace(this, "changeMaterial");

			// Если не корневое пространство
			if (parent != null) {
				
				// Снимаем пометку на смену материала
				delete _scene.spacesToChangeMaterial[this];
			} else {
			}
		}
/*		
		alternativa3d function render():void {
			trace(this, "render");
			
			// Обрабатываем камеры не помеченные на полную отрисовку
			for (var key:* in _scene.cameras) {
				if (!_scene.camerasToRender[key]) {
					var camera:Camera3D = key;
					camera.updateSpaceMaterial(this);
				}
			}

			// Снимаем пометку об отрисовке пространства
			delete _scene.spacesToUpdate[this];
		}
*/
		alternativa3d function updateMaterial():void {
			trace(this, "updateMaterial");
			
			// Обрабатываем камеры не помеченные на полную отрисовку
			for (var key:* in _scene.cameras) {
				if (!_scene.camerasToRender[key]) {
					var camera:Camera3D = key;
					camera.updateSpaceMaterial(this);
				}
			}

			// Снимаем пометку об обновлении материала
			delete _scene.spacesToUpdateMaterial[this];
		}
		
		alternativa3d function globalTransform():void {
			trace(this, "globalTransform");
			
			// Расчитываем глобальную трансформацию
			globalMatrix.copy(spaceMatrix);
			globalMatrix.combine(space.globalMatrix);
			
			// Вызвать глобальную трансформацию в дочерних пространствах
			globalTransformChildSpaces(this);
			
			delete _scene.spacesToGlobalTransform[this];
		}
		
		private function globalTransformChildSpaces(object:Object3D):void {
			// Обрабатываем дочерние объекты
			for (var key:* in object._children) {
				if (key is Space) {
					(key as Space).globalTransform();
				} else {
					// Если камера с вьюпортом, помечаем её на отрисовку
					if ((key is Camera3D) && (key as Camera3D)._view != null) {
						_scene.camerasToRender[key] = true;
					}
					globalTransformChildSpaces(key);
				}
			}
		}
		
		/**
		 * @private
		 * Расчёт плоскостей отсечения для ортографической камеры 
		 */
		alternativa3d function calculateOrthographicPlanes(halfWidth:Number, halfHeight:Number, zoom:Number):void {
			var aw:Number = inverseCameraMatrix.a*halfWidth/zoom;
			var ew:Number = inverseCameraMatrix.e*halfWidth/zoom;
			var iw:Number = inverseCameraMatrix.i*halfWidth/zoom;
			var bh:Number = inverseCameraMatrix.b*halfHeight/zoom;
			var fh:Number = inverseCameraMatrix.f*halfHeight/zoom;
			var jh:Number = inverseCameraMatrix.j*halfHeight/zoom;
			
			// Левая плоскость
			leftPlane.x = inverseCameraMatrix.f*inverseCameraMatrix.k - inverseCameraMatrix.j*inverseCameraMatrix.g;
			leftPlane.y = inverseCameraMatrix.j*inverseCameraMatrix.c - inverseCameraMatrix.b*inverseCameraMatrix.k;
			leftPlane.z = inverseCameraMatrix.b*inverseCameraMatrix.g - inverseCameraMatrix.f*inverseCameraMatrix.c;
			leftOffset = (inverseCameraMatrix.d - aw)*leftPlane.x + (inverseCameraMatrix.h - ew)*leftPlane.y + (inverseCameraMatrix.l - iw)*leftPlane.z;
			
			// Правая плоскость
			rightPlane.x = -leftPlane.x;
			rightPlane.y = -leftPlane.y;
			rightPlane.z = -leftPlane.z;
			rightOffset = (inverseCameraMatrix.d + aw)*rightPlane.x + (inverseCameraMatrix.h + ew)*rightPlane.y + (inverseCameraMatrix.l + iw)*rightPlane.z;
			
			// Верхняя плоскость
			topPlane.x = inverseCameraMatrix.g*inverseCameraMatrix.i - inverseCameraMatrix.k*inverseCameraMatrix.e;
			topPlane.y = inverseCameraMatrix.k*inverseCameraMatrix.a - inverseCameraMatrix.c*inverseCameraMatrix.i;
			topPlane.z = inverseCameraMatrix.c*inverseCameraMatrix.e - inverseCameraMatrix.g*inverseCameraMatrix.a;
			topOffset = (inverseCameraMatrix.d - bh)*topPlane.x + (inverseCameraMatrix.h - fh)*topPlane.y + (inverseCameraMatrix.l - jh)*topPlane.z;
			
			// Нижняя плоскость
			bottomPlane.x = -topPlane.x;
			bottomPlane.y = -topPlane.y;
			bottomPlane.z = -topPlane.z;
			bottomOffset = (inverseCameraMatrix.d + bh)*bottomPlane.x + (inverseCameraMatrix.h + fh)*bottomPlane.y + (inverseCameraMatrix.l + jh)*bottomPlane.z;
		}
		
		/**
		 * @private
		 * Расчёт плоскостей отсечения для перспективной камеры 
		 */
		alternativa3d function calculatePerspectivePlanes(halfWidth:Number, halfHeight:Number, focalLength:Number):void {
			var aw:Number = inverseCameraMatrix.a*halfWidth;
			var ew:Number = inverseCameraMatrix.e*halfWidth;
			var iw:Number = inverseCameraMatrix.i*halfWidth;
			var bh:Number = inverseCameraMatrix.b*halfHeight;
			var fh:Number = inverseCameraMatrix.f*halfHeight;
			var jh:Number = inverseCameraMatrix.j*halfHeight;
			
			var cl:Number = inverseCameraMatrix.c*focalLength;
			var gl:Number = inverseCameraMatrix.g*focalLength;
			var kl:Number = inverseCameraMatrix.k*focalLength;
			
			// Угловые вектора пирамиды видимости
			var leftTopX:Number = -aw - bh + cl;
			var leftTopY:Number = -ew - fh + gl;
			var leftTopZ:Number = -iw - jh + kl;
			var rightTopX:Number = aw - bh + cl;
			var rightTopY:Number = ew - fh + gl;
			var rightTopZ:Number = iw - jh + kl;
			var leftBottomX:Number = -aw + bh + cl;
			var leftBottomY:Number = -ew + fh + gl;
			var leftBottomZ:Number = -iw + jh + kl;
			var rightBottomX:Number = aw + bh + cl;
			var rightBottomY:Number = ew + fh + gl;
			var rightBottomZ:Number = iw + jh + kl;
			
			// Левая плоскость
			leftPlane.x = leftBottomY*leftTopZ - leftBottomZ*leftTopY;
			leftPlane.y = leftBottomZ*leftTopX - leftBottomX*leftTopZ;
			leftPlane.z = leftBottomX*leftTopY - leftBottomY*leftTopX;
			leftOffset = inverseCameraMatrix.d*leftPlane.x + inverseCameraMatrix.h*leftPlane.y + inverseCameraMatrix.l*leftPlane.z;

			// Правая плоскость
			rightPlane.x = rightTopY*rightBottomZ - rightTopZ*rightBottomY;
			rightPlane.y = rightTopZ*rightBottomX - rightTopX*rightBottomZ;
			rightPlane.z = rightTopX*rightBottomY - rightTopY*rightBottomX;
			rightOffset = inverseCameraMatrix.d*rightPlane.x + inverseCameraMatrix.h*rightPlane.y + inverseCameraMatrix.l*rightPlane.z;

			// Верхняя плоскость
			topPlane.x = leftTopY*rightTopZ - leftTopZ*rightTopY;
			topPlane.y = leftTopZ*rightTopX - leftTopX*rightTopZ;
			topPlane.z = leftTopX*rightTopY - leftTopY*rightTopX;
			topOffset = inverseCameraMatrix.d*topPlane.x + inverseCameraMatrix.h*topPlane.y + inverseCameraMatrix.l*topPlane.z;

			// Нижняя плоскость
			bottomPlane.x = rightBottomY*leftBottomZ - rightBottomZ*leftBottomY;
			bottomPlane.y = rightBottomZ*leftBottomX - rightBottomX*leftBottomZ;
			bottomPlane.z = rightBottomX*leftBottomY - rightBottomY*leftBottomX;
			bottomOffset = inverseCameraMatrix.d*bottomPlane.x + inverseCameraMatrix.h*bottomPlane.y + inverseCameraMatrix.l*bottomPlane.z;
			
			// Расчёт угла конуса
			var length:Number = Math.sqrt(leftTopX*leftTopX + leftTopY*leftTopY + leftTopZ*leftTopZ);
			leftTopX /= length;
			leftTopY /= length;
			leftTopZ /= length;
			length = Math.sqrt(rightTopX*rightTopX + rightTopY*rightTopY + rightTopZ*rightTopZ);
			rightTopX /= length;
			rightTopY /= length;
			rightTopZ /= length;
			length = Math.sqrt(leftBottomX*leftBottomX + leftBottomY*leftBottomY + leftBottomZ*leftBottomZ);
			leftBottomX /= length;
			leftBottomY /= length;
			leftBottomZ /= length;
			length = Math.sqrt(rightBottomX*rightBottomX + rightBottomY*rightBottomY + rightBottomZ*rightBottomZ);
			rightBottomX /= length;
			rightBottomY /= length;
			rightBottomZ /= length;

			viewAngle = leftTopX*direction.x + leftTopY*direction.y + leftTopZ*direction.z;
			var dot:Number = rightTopX*direction.x + rightTopY*direction.y + rightTopZ*direction.z;
			viewAngle = (dot < viewAngle) ? dot : viewAngle;
			dot = leftBottomX*direction.x + leftBottomY*direction.y + leftBottomZ*direction.z;
			viewAngle = (dot < viewAngle) ? dot : viewAngle;
			dot = rightBottomX*direction.x + rightBottomY*direction.y + rightBottomZ*direction.z;
			viewAngle = (dot < viewAngle) ? dot : viewAngle;
			
			viewAngle = Math.sin(Math.acos(viewAngle));
		}

		override protected function removeFromScene():void {
			
			if (_sortingLevel != null) {
				// Удаляем пространства из уровня
				delete _sortingLevel.spaces[this];
				// Помечаем изменение в пространстве
				_sortingLevel.changed[this] = true;
				_scene.levelsToClear[_sortingLevel] = true;
				// Удаляем ссылку на уровень
				_sortingLevel = null;
			} else {
				if (node != null) {
					_scene.levelsToClear[_sortingLevel] = true;
					
				}
			}
			
/*			
			// Удаляем примитив
			if (primitive != null) {
				// Удаляем примитив из ноды
				primitive.node.removePrimitive(primitive);
				// Удаляем примитив
				SpaceDistancePrimitive.defer(primitive);
				primitive = null;
			}
*/			
			// Удаляем ссылку на уровень
			_sortingLevel = null;
			
			super.removeFromScene();

			// Удаляем все пометки в сцене
			delete _scene.spacesToGlobalTransform[this];
			delete _scene.spacesToChangeSortingLevel[this];
			delete _scene.spacesToChangeMaterial[this];
			//delete _scene.spacesToUpdate[this];
			delete _scene.spacesToUpdateMaterial[this];
		}
		
		/**
		 * @private 
		 * Получить уровень по индексу. Если уровня с таким индексом нет, он создаётся.
		 */
		alternativa3d function getSortingLevel(index:int):SortingLevel {
			var previous:SortingLevel = null;
			var current:SortingLevel = firstLevel;
			var level:SortingLevel;
			// Перебираем уровни
			while (true) {
				// Если есть текущий
				if (current != null) {
					// Если найден уровень с требуемым индексом
					if (current.index == index) {
						// Возвращаем его
						return current;
					} else {
						// Если найден уровень с большим индексом
						if (current.index > index) {
							// Создаём новый уровень
							level = new SortingLevel();
							level.space = this;
							level.index = index;
							if (previous != null) {
								previous.next = level;
							} else {
								firstLevel = level;
							}
							level.next = current;
							return level;
						} else {
							// Переключаемся на следующий уровень
							previous = current;
							current = current.next;
						}
					}
				} else {
					// Создаём новый уровень
					level = new SortingLevel();
					level.space = this;
					level.index = index;
					if (previous != null) {
						previous.next = level;
					} else {
						firstLevel = level;
					}
					return level;
				}
			}
			// null никогда не возвращается, т.к. возврат происходит из цикла
			return null;
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
				if (_scene != null) {
					_scene.spacesToChangeSortingLevel[this] = true;
				}
			}
		}

		/**
		 * Режим сортировки пространства. 
		 */
		public function get sortingMode():uint {
			return _sortingMode;
		}

		/**
		 * @private
		 */
		public function set sortingMode(value:uint):void {
			if (value > 1) {
				throw new InvalidSortingModeError(value, this);
			}
			if (_sortingMode != value) {
				_sortingMode = value;
				if (_scene != null) {
					_scene.spacesToChangeSortingMode[this] = true;
				}
			}
		}

		/**
		 * Материал пространства. При установке нового значения, устанавливаемый материал будет удалён из старого пространства.
		 */
		public function get material():SpaceMaterial {
			return _material;
		}

		/**
		 * @private
		 */
		public function set material(value:SpaceMaterial):void {
			if (_material != value) {
				// Если был материал
				if (_material != null) {
					// Удалить материал
					_material._space = null;
				}
				// Если новый материал
				if (value != null) {
					// Если материал был в другом пространстве
					var oldSpace:Space = value._space; 
					if (oldSpace != null) {
						// Удалить его оттуда
						oldSpace._material = null;
						// Если есть сцена, помечаем смену материала
						if (oldSpace._scene != null) {
							oldSpace._scene.spacesToChangeMaterial[oldSpace] = true;
						}
						
					}
					// Добавить материал
					value._space = this;
				}
				// Если есть сцена, помечаем смену материала
				if (_scene != null) {
					_scene.spacesToChangeMaterial[this] = true;
				}
				// Сохраняем материал
				_material = value;
			}
		}
		
		/**
		 * Имя пространства по умолчанию.
		 * 
		 * @return имя пространства по умолчанию
		 */		
		override protected function defaultName():String {
			return "space" + ++counter;
		}
		
	}
}