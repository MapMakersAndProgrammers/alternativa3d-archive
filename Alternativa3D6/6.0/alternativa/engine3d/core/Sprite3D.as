package alternativa.engine3d.core {

	import alternativa.engine3d.*;
	import alternativa.engine3d.sorting.SortingLevel;
	import alternativa.engine3d.sorting.SpriteDistancePrimitive;
	import alternativa.engine3d.materials.SpriteMaterial;
	import alternativa.engine3d.sorting.DistanceNode;

	use namespace alternativa3d;

	public class Sprite3D extends Object3D {
		
		// Инкремент количества объектов
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
		alternativa3d var _material:SpriteMaterial;

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

		public function Sprite3D(name:String = null) {
			super(name);
		}

		override protected function transform():void {
			super.transform();
			
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
				primitive = SpriteDistancePrimitive.create();
				primitive.sprite = this;
			}
			
			// Добавляем примитив в уровень
			_sortingLevel.distancePrimitivesToAdd.push(primitive);
			
			// Устанавливаем координаты
			primitive.coords.x = spaceMatrix.d;
			primitive.coords.y = spaceMatrix.h;
			primitive.coords.z = spaceMatrix.l;
			
			// Снимаем пометки о смене уровня и материала
			delete _scene.spritesToChangeSortingLevel[this];
			delete _scene.spritesToChangeMaterial[this];
		}

		override protected function move():void {
			super.move();
			
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
			
			// Снимаем пометки о смене уровня и материала
			delete _scene.spritesToChangeSortingLevel[this];
			delete _scene.spritesToChangeMaterial[this];
		}
		
		alternativa3d function changeSortingLevel():void {
			trace(this, "changeSortingLevel");
			
			// Если уровень изменился
			if (_sortingLevel.index != sortingLevelIndex) {
				// Обновляем уровень
				_sortingLevel = space.getSortingLevel(sortingLevelIndex);
				
				// Удаляем примитив
				primitive.node.removePrimitive(primitive);
				
				// Добавляем примитив в уровень
				_sortingLevel.distancePrimitivesToAdd.push(primitive);
			}
			
			// Снимаем пометку о смене уровня
			delete _scene.spacesToChangeSortingLevel[this];
		}

		alternativa3d function changeSortingMode():void {
			trace(this, "changeSortingMode");
			
		}

		alternativa3d function changeMaterial():void {
			trace(this, "changeMaterial");
			
		}
		
		override protected function removeFromScene(scene:Scene3D):void {
			super.removeFromScene(scene);
			
			// Удаляем примитив
			if (primitive != null) {
				// Удаляем примитив из ноды
				primitive.node.removePrimitive(primitive);
				// Удаляем примитив
				SpriteDistancePrimitive.defer(primitive);
				primitive = null;
			}
			
			// Удаляем ссылку на уровень
			_sortingLevel = null;
			
			// Удаляем все пометки в сцене
			delete scene.spritesToChangeSortingLevel[this];
			delete scene.spritesToChangeMaterial[this];
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
					_scene.spritesToChangeSortingLevel[this] = true;
				}
			}
		}

		/**
		 * Режим сортировки спрайта. 
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
				if (_scene != null) {
					_scene.spritesToChangeSortingMode[this] = true;
				}
			}
		}

		/**
		 * Материал спрайта. При установке нового значения, устанавливаемый материал будет удалён из старого спрайта.
		 */
		public function get material():SpriteMaterial {
			return _material;
		}

		/**
		 * @private
		 */
		public function set material(value:SpriteMaterial):void {
			if (_material != value) {
				// Если был материал
				if (_material != null) {
					// Удалить материал
					_material._sprite = null;
				}
				// Если новый материал
				if (value != null) {
					// Если материал был в другом спрайте
					var oldSprite:Sprite3D = value._sprite; 
					if (oldSprite != null) {
						// Удалить его оттуда
						oldSprite._material = null;
						// Если есть сцена, помечаем смену материала
						if (oldSprite._scene != null) {
							oldSprite._scene.spritesToChangeMaterial[oldSprite] = true;
						}
						
					}
					// Добавить материал
					value._sprite = this;
				}
				// Если есть сцена, помечаем смену материала
				if (_scene != null) {
					_scene.spritesToChangeMaterial[this] = true;
				}
				// Сохраняем материал
				_material = value;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function defaultName():String {
			return "sprite" + ++counter;
		}
		
	}
}