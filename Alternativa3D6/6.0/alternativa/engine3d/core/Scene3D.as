package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.types.Set;
	import alternativa.utils.ObjectUtils;
	import alternativa.engine3d.sorting.SortingLevel;

	use namespace alternativa3d;

	/**
	 * Сцена является контейнером 3D-объектов, с которыми ведётся работа. Все взаимодействия объектов
	 * происходят в пределах одной сцены. Класс обеспечивает работу системы сигналов и реализует алгоритм построения
	 * BSP-дерева для содержимого сцены.
	 */
	public class Scene3D {
		
		// Инкремент количества сцен
		private static var counter:uint = 0;

		/**
		 * @private
		 * Наименование
		 */		
		alternativa3d var _name:String;

		/**
		 * @private
		 * Пространство сцены
		 */
		alternativa3d var _space:Space;

		/**
		 * @private
		 * Реестр камер сцены
		 */
		alternativa3d var cameras:Set = new Set();

		/**
		 * @private
		 * Списки сигналов
		 */
		 
		 
		alternativa3d var objectsToTransform:Set = new Set();
		alternativa3d var objectsToMove:Set = new Set();
//		alternativa3d var verticesToMove:Set = new Set();
		alternativa3d var spacesToGlobalTransform:Set = new Set();
		
		alternativa3d var spacesToChangeSortingMode:Set = new Set();
		alternativa3d var spacesToChangeSortingLevel:Set = new Set();
		alternativa3d var spacesToChangeMaterial:Set = new Set();
/*		
		alternativa3d var spritesToChangeSortingMode:Set = new Set();
		alternativa3d var spritesToChangeSortingLevel:Set = new Set();
		alternativa3d var spritesToChangeMaterial:Set = new Set();
		
		alternativa3d var surfacesToChangeSortingMode:Set = new Set();
		alternativa3d var surfacesToChangeSortingLevel:Set = new Set();
		alternativa3d var surfacesToChangeMaterial:Set = new Set();
		alternativa3d var surfacesToChangeBSPLevel:Set = new Set();
		
		alternativa3d var facesToChangeSurface:Set = new Set();
		alternativa3d var facesToTransform:Set = new Set();
*/
		//alternativa3d var spacesToCalculate:Set = new Set();
		alternativa3d var levelsToCalculate:Set = new Set();
		
		//alternativa3d var spacesToRender:Set = new Set();
		alternativa3d var spacesToUpdateMaterial:Set = new Set();

		alternativa3d var camerasToRender:Set = new Set();

		alternativa3d var levelsToClear:Set = new Set();

		/**
		 * Создание экземпляра сцены.
		 */
		public function Scene3D(name:String = null) {
			// Имя по-умолчанию
			_name = (name != null) ? name : defaultName();
		}
				
		/**
		 * Расчёт сцены. Метод анализирует все изменения, произошедшие с момента предыдущего расчёта, формирует список
		 * команд и исполняет их в необходимой последовательности. В результате расчёта происходит перерисовка во всех
		 * областях вывода, к которым подключены находящиеся в сцене камеры.
		 */
		public function calculate():void {
			trace("----------------------------- calculate -------------------------------------");

			var key:*;
			var object:Object3D;
			var method:Function;
//			var vertex:Vertex;
//			var face:Face;
//			var surface:Surface;
//			var sprite:Sprite3D;
			var space:Space;
			var level:SortingLevel;
			var camera:Camera3D;
			
			// Трансформация объектов
			if (!objectsToTransform.isEmpty()) {
				trace("objectsToTransform:", objectsToTransform.length);
			}
			while ((object = objectsToTransform.peek()) != null) {
				// Ищем, нет ли выше в пространстве объектов на трансформацию или перемещение
				method = object.transformBranch;
				while ((object = object._parent) != null && !(object is Space)) {
					method = objectsToTransform[object] ? object.transformBranch : (objectsToMove[object] ? object.moveBranch : method);
				}
				method();
			}
			
			// Перемещение объектов
			if (!objectsToMove.isEmpty()) {
				trace("objectsToMove:", objectsToMove.length);
			}
			while ((object = objectsToMove.peek()) != null) {
				// Ищем, нет ли выше в пространстве объектов на перемещение
				method = object.moveBranch;
				while ((object = object._parent) != null && !(object is Space)) {
					method = objectsToMove[object] ? object.moveBranch : method;
				}
				method();
			}
/*			
			// Перемещение вершин
			if (!verticesToMove.isEmpty()) {
				trace("verticesToMove:", verticesToMove.length);
			}
			for (key in verticesToMove) {
				vertex = key;
				vertex.move();
			}
*/
			// Глобальная трансформация пространств
			if (!spacesToGlobalTransform.isEmpty()) {
				trace("spacesToGlobalTransform:", spacesToGlobalTransform.length);
			}
			while ((space = spacesToGlobalTransform.peek()) != null) {
				method = space.globalTransform;
				// Ищем, нет ли выше пространства на глобальную трансформацию
				while ((space = space.space) != null) {
					method = spacesToGlobalTransform[space] ? space.globalTransform : method;
				}
				method();
			}

			// Изменение режима сортировки пространств
			if (!spacesToChangeSortingMode.isEmpty()) {
				trace("spacesToChangeSortingMode:", spacesToChangeSortingMode.length);
			}
			for (key in spacesToChangeSortingMode) {
				space = key;
				space.changeSortingMode();
			}

			// Изменение уровней пространств
			if (!spacesToChangeSortingLevel.isEmpty()) {
				trace("spacesToChangeSortingLevel:", spacesToChangeSortingLevel.length);
			}
			for (key in spacesToChangeSortingLevel) {
				space = key;
				space.changeSortingLevel();
			}

			// Изменение материалов пространств
			if (!spacesToChangeMaterial.isEmpty()) {
				trace("spacesToChangeMaterial:", spacesToChangeMaterial.length);
			}
			for (key in spacesToChangeMaterial) {
				space = key;
				space.changeMaterial();
			}
/*
			// Изменение режима сортировки спрайтов
			if (!spritesToChangeSortingMode.isEmpty()) {
				trace("spritesToChangeSortingMode:", spritesToChangeSortingMode.length);
			}
			for (key in spritesToChangeSortingMode) {
				sprite = key;
				sprite.changeSortingMode();
			}

			// Изменение уровней спрайтов
			if (!spritesToChangeSortingLevel.isEmpty()) {
				trace("spritesToChangeSortingLevel:", spritesToChangeSortingLevel.length);
			}
			for (key in spritesToChangeSortingLevel) {
				sprite = key;
				sprite.changeSortingLevel();
			}

			// Изменение материалов спрайтов
			if (!spritesToChangeMaterial.isEmpty()) {
				trace("spritesToChangeMaterial:", spritesToChangeMaterial.length);
			}
			for (key in spritesToChangeMaterial) {
				sprite = key;
				sprite.changeMaterial();
			}

			// Изменение режима сортировки поверхностей
			if (!surfacesToChangeSortingMode.isEmpty()) {
				trace("surfacesToChangeSortingMode:", surfacesToChangeSortingMode.length);
			}
			for (key in surfacesToChangeSortingMode) {
				surface = key;
				surface.changeSortingMode();
			}
			
			// Изменение уровней поверхностей
			if (!surfacesToChangeSortingLevel.isEmpty()) {
				trace("surfacesToChangeSortingLevel:", surfacesToChangeSortingLevel.length);
			}
			for (key in surfacesToChangeSortingLevel) {
				surface = key;
				surface.changeSortingLevel();
			}
			
			// Изменение материалов поверхностей
			if (!surfacesToChangeMaterial.isEmpty()) {
				trace("surfacesToChangeMaterial:", surfacesToChangeMaterial.length);
			}
			for (key in surfacesToChangeMaterial) {
				surface = key;
				surface.changeMaterial();
			}

			// Изменение мобильности поверхностей
			if (!surfacesToChangeBSPLevel.isEmpty()) {
				trace("surfacesToChangeBSPLevel:", surfacesToChangeBSPLevel.length);
			}
			for (key in surfacesToChangeBSPLevel) {
				surface = key;
				surface.changeBSPLevel();
			}

			// Изменение поверхности граней
			if (!facesToChangeSurface.isEmpty()) {
				trace("facesToChangeSurface:", facesToChangeSurface.length);
			}
			for (key in facesToChangeSurface) {
				face = key;
				face.changeSurface();
			}

			// Трансформация граней
			if (!facesToTransform.isEmpty()) {
				trace("facesToTransform:", facesToTransform.length);
			}
			for (key in facesToTransform) {
				face = key;
				face.transform();
			}
*/			
			// Расчёт BSP пространств
			if (!levelsToCalculate.isEmpty()) {
				trace("levelsToCalculate:", levelsToCalculate.length);
			}
			for (key in levelsToCalculate) {
				level = key;
				level.calculate();
			}
/*
			// Отрисовка пространств
			if (!spacesToRender.isEmpty()) {
				trace("spacesToRender:", spacesToRender.length);
			}
			while ((space = spacesToRender.peek()) != null) {
				var s:Space = space;
				// Ищем, нет ли выше пространства на отрисовку
				while ((space = space.space) != null) {
					s = spacesToRender[space] ? space : s;
				}
				// Отрисовка пространства
				s.render();
			}
*/
			// Обновление материалов пространств
			if (!spacesToUpdateMaterial.isEmpty()) {
				trace("spacesToUpdateMaterial:", spacesToUpdateMaterial.length);
			}
			for (key in spacesToUpdateMaterial) {
				space = key;
				space.updateMaterial();
			}
			

			// Отрисовка камер
			if (!camerasToRender.isEmpty()) {
				trace("camerasToRender:", camerasToRender.length);
			}
			for (key in camerasToRender) {
				camera = key;
				camera.render();
			}

			
			// Очистка изменений уровней
			if (!levelsToClear.isEmpty()) {
				trace("levelsToClear:", levelsToClear.length);
			}
			for (key in levelsToClear) {
				level = key;
				level.clear();
			}
			
			// Отложенное удаление примитивов в коллекторы
			//FaceNonePrimitive.destroyDeferred();
			//FaceDistancePrimitive.destroyDeferred();
			//FaceBSPPrimitive.destroyDeferred();
			//SpaceDistancePrimitive.destroyDeferred();
			//SpriteDistancePrimitive.destroyDeferred();

			trace("-----------------------------------------------------------------------------");
			
		}
		
		public function hasChanges():Boolean {
			//return !objectsToLocate.isEmpty() || !objectsToChangeMobility.isEmpty() || !objectsToTransform.isEmpty() || !objectsToMove.isEmpty() || !verticesToMove.isEmpty() || !facesToChangeSurface.isEmpty() || !facesToTransform.isEmpty();
			return true;
		}
		
		/**
		 * Имя сцены. 
		 */
		public function get name():String {
			return _name;
		}

		/**
		 * @private
		 */
		public function set name(value:String):void {
			_name = value;
		}
		
		/**
		 * Корневой объект сцены.
		 */
		public function get space():Space {
			return _space;
		}

		/**
		 * @private
		 */
		public function set space(value:Space):void {
			// Если ещё не является пространством сцены
			if (_space != value) {
				// Если у сцены было пространство
				if (_space != null) {
					// Удаляем у него ссылку на сцену
					_space.setScene(null);
				}
				
				// Если устанавливаем пространство
				if (value != null) {
					// Если пространство было в другом объекте
					if (value._parent != null) {
						// Удалить его оттуда
						value._parent._children.remove(value);
					} else {
						// Если пространство было пространством в другой сцене
						if (value._scene != null) {
							value._scene.space = null;
						}
					}
					
					// Удаляем ссылку на родителя
					value._parent = null;
					// Указываем сцену
					value.setScene(this);
					// Если у пространства есть материал, помечаем его на обновление
					if (value._material != null) {
						spacesToUpdateMaterial[value] = true;
					}
				}
				
				// Сохраняем пространство
				_space = value;
			}
		}

		/**
		 * Строковое представление сцены.
		 * 
		 * @return строковое представление сцены
		 */
		public function toString():String {
			return "[" + ObjectUtils.getClassName(this) + " " + _name + "]";
		}
				
		/**
		 * Имя сцены по умолчанию.
		 * 
		 * @return имя сцены по умолчанию
		 */		
		protected function defaultName():String {
			return "scene" + ++counter;
		}

	}
}