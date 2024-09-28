package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.engine3d.errors.Object3DHierarchyError;
	import alternativa.engine3d.errors.Object3DNotFoundError;
	import alternativa.types.Matrix3D;
	import alternativa.types.Point3D;
	import alternativa.types.Set;
	import alternativa.utils.ObjectUtils;
	
	use namespace alternativa3d;
	
	/**
	 * Базовый класс для объектов, находящихся в сцене. Класс реализует иерархию объектов сцены, а также содержит сведения
	 * о трансформации объекта как единого целого.
	 * 
	 * <p> Масштабирование, ориентация и положение объекта задаются в родительской системе координат. Результирующая
	 * локальная трансформация является композицией операций масштабирования, поворотов объекта относительно осей
	 * <code>X</code>, <code>Y</code>, <code>Z</code> и параллельного переноса центра объекта из начала координат.
	 * Операции применяются в порядке их перечисления.
	 * 
	 * <p> Глобальная трансформация (в системе координат корневого объекта сцены) является композицией трансформаций
	 * самого объекта и всех его предков по иерархии объектов сцены.
	 */
	public class Object3D {
		
		// Инкремент количества объектов
		private static var counter:uint = 0;

		/**
		 * @private
		 * Наименование
		 */
		alternativa3d var _name:String;
		/**
		 * @private
		 * Сцена
		 */
		alternativa3d var _scene:Scene3D;
		/**
		 * @private
		 * Родительский объект
		 */
		alternativa3d var _parent:Object3D;
		/**
		 * @private
		 * Дочерние объекты
		 */		
		alternativa3d var _children:Set = new Set();
		/**
		 * @private
		 * Пространство
		 */
		alternativa3d var space:Space;
		/**
		 * @private
		 * Координаты объекта относительно родителя
		 */
		alternativa3d var _coords:Point3D = new Point3D();
		/**
		 * @private
		 * Поворот объекта по оси X относительно родителя. Угол измеряется в радианах.
		 */		
		alternativa3d var _rotationX:Number = 0;
		/**
		 * @private
		 * Поворот объекта по оси Y относительно родителя. Угол измеряется в радианах.
		 */		
		alternativa3d var _rotationY:Number = 0;
		/**
		 * @private
		 * Поворот объекта по оси Z относительно родителя. Угол измеряется в радианах.
		 */		
		alternativa3d var _rotationZ:Number = 0;
		/**
		 * @private
		 * Мастшаб объекта по оси X относительно родителя
		 */		
		alternativa3d var _scaleX:Number = 1;
		/**
		 * @private
		 * Мастшаб объекта по оси Y относительно родителя
		 */		
		alternativa3d var _scaleY:Number = 1;
		/**
		 * @private
		 * Мастшаб объекта по оси Z относительно родителя
		 */		
		alternativa3d var _scaleZ:Number = 1;
		/**
		 * @private
		 * Матрица перевода из локальной системы координат объекта в систему пространства
		 */		
		alternativa3d var spaceMatrix:Matrix3D = new Matrix3D();
		/**
		 * Создание экземпляра класса.
		 * 
		 * @param name имя экземпляра
		 */
		public function Object3D(name:String = null) {
			// Имя по-умолчанию
			_name = (name != null) ? name : defaultName();
		}
		
		protected function transform():void {
			trace(this, "- transform");

			// Если объект был в пространстве, помечаем пространство на пересчет
			//if (space != null) {
			//	_scene.spacesToCalculate[space] = true;
			//}
			// Обновляем пространство
			space = (_parent is Space) ? Space(_parent) : _parent.space;
			// Помечаем пространство на пересчет
			//_scene.spacesToCalculate[space] = true;
			
			// Локальная матрица трансформации
			spaceMatrix.toTransform(_coords.x, _coords.y, _coords.z, _rotationX, _rotationY, _rotationZ, _scaleX, _scaleY, _scaleZ);
			// Если родитель не является пространством
			if (!(_parent is Space)) {
				// Наследуем трансформацию у родителя
				spaceMatrix.combine(_parent.spaceMatrix);
			}
		}
		
		protected function move():void {
			trace("- move");

			// Помечаем пространство на пересчет
			//_scene.spacesToCalculate[space] = true;

			// Если родитель является пространством
			if (_parent is Space) {
				// Смещение равно локальным координатам
				spaceMatrix.d = _coords.x;
				spaceMatrix.h = _coords.y;
				spaceMatrix.l = _coords.z;
			} else {
				// Расчитываем новое смещение c учётом трансформации родителя
				var x:Number = _coords.x;
				var y:Number = _coords.y;
				var z:Number = _coords.z;
				var parentTransformation:Matrix3D = _parent.spaceMatrix; 
				spaceMatrix.d = parentTransformation.a*x + parentTransformation.b*y + parentTransformation.c*z + parentTransformation.d;
				spaceMatrix.h = parentTransformation.e*x + parentTransformation.f*y + parentTransformation.g*z + parentTransformation.h;
				spaceMatrix.l = parentTransformation.i*x + parentTransformation.j*y + parentTransformation.k*z + parentTransformation.l;
			}
		}
		
		alternativa3d function transformBranch():void {
			trace(this, "transformBranch");
			
			// Трансформация
			transform();
			// Если объект не пространство, наследуем трансформацию
			if (!(this is Space)) {
				// Обрабатываем дочерние объекты
				for (var key:* in _children) {
					var child:Object3D = key;
					child.transformBranch();
				}
			}
			
			// Снимаем отметки о перемещении, трансформации и мобильности
			delete _scene.objectsToTransform[this];
			delete _scene.objectsToMove[this];
		}
		
		alternativa3d function moveBranch():void {
			trace(this, "moveBranch");
			
			// Перемещение
			move();
			// Если объект не пространство, наследуем перемещение
			if (!(this is Space)) {
				// Обрабатываем дочерние объекты
				for (var key:* in _children) {
					var child:Object3D = key;
					_scene.objectsToTransform[child] ? child.transformBranch() : child.moveBranch();
				}
			}
			
			// Снимаем отметку о перемещении
			delete _scene.objectsToMove[this];
		}

		/**
		 * Добавление дочернего объекта. Добавляемый объект удаляется из списка детей предыдущего родителя.
		 * Новой сценой дочернего объекта становится сцена родителя.
		 * 
		 * @param child добавляемый объект
		 * 
		 * @throws alternativa.engine3d.errors.Object3DHierarchyError нарушение иерархии объектов сцены
		 */	
		public function addChild(child:Object3D):void {
			
			// Проверка на null
			if (child == null) {
				throw new Object3DHierarchyError(null, this);
			}
			
			// Проверка на наличие
			if (child._parent == this) {
				return;
			}
			
			// Проверка на добавление к самому себе
			if (child == this) {
				throw new Object3DHierarchyError(this, this);
			}
			
			// Проверка на добавление родительского объекта
			if (child._scene == _scene) {
				// Если объект был в той же сцене, либо оба не были в сцене
				var parentObject:Object3D = _parent;
				while (parentObject != null) {
					if (child == parentObject) {
						throw new Object3DHierarchyError(child, this);
						return;
					}
					parentObject = parentObject._parent;
				}
			}

			// Если объект был в другом объекте
			if (child._parent != null) {
				// Удалить его оттуда
				child._parent._children.remove(child);
			} else {
				// Если объект был корневым в сцене
				if (child._scene != null) {
					child._scene.space = null;
				}
			}
			// Добавляем в список
			_children.add(child);
			
			// Указываем себя как родителя
			child._parent = this;
			
			// Указываем сцену
			child.setScene(_scene);
		}
		
		/**
		 * Удаление дочернего объекта.
		 * 
		 * @param child удаляемый дочерний объект
		 * 
		 * @throws alternativa.engine3d.errors.Object3DNotFoundError указанный объект не содержится в списке детей текущего объекта
		 */
		public function removeChild(child:Object3D):void {
			// Проверка на null
			if (child == null) {
				throw new Object3DNotFoundError(null, this);
			}
			// Проверка на наличие
			if (child._parent != this) {
				throw new Object3DNotFoundError(child, this);
			}
			// Убираем из списка
			_children.remove(child);
			// Удаляем ссылку на родителя
			child._parent = null;
			// Удаляем ссылку на сцену
			child.setScene(null);
		}

		/**
		 * @private
		 * Установка новой сцены для объекта.
		 * 
		 * @param value сцена
		 */
		alternativa3d function setScene(value:Scene3D):void {
			if (_scene != value) {
				// Если была сцена
				if (_scene != null) {
					// Удалиться из сцены
					removeFromScene();
				}
				// Сохранить сцену
				_scene = value;
				// Если новая сцена
				if (value != null) {
					// Добавиться на сцену
					addToScene();
				}
				// Установить эту сцену у дочерних объектов
				for (var key:* in _children) {
					var object:Object3D = key;
					object.setScene(value);
				}
			} else {
				// При перемещении в пределах сцены пересчёт
				if (_scene != null) {
					_scene.objectsToTransform[this] = true;
				}
			}
		}
		
		/**
		 * Метод вызывается при добавлении объекта на сцену. Наследники могут переопределять метод для выполнения
		 * специфических действий.
		 */		
		protected function addToScene():void {
			_scene.objectsToTransform[this] = true;
		}

		/**
		 * Метод вызывается при удалении объекта со сцены. Наследники могут переопределять метод для выполнения
		 * специфических действий.
		 */		
		protected function removeFromScene():void {
			
/*			// Если объект был в пространстве
			if (space != null) {
				// Помечаем пространство на пересчет
				_scene.spacesToCalculate[space] = true;
				// Удаляем ссылку на пространство
				space = null;
			}
*/			
			// Удаляем ссылку на пространство
			space = null;

			// Удаляем все пометки в сцене
			delete _scene.objectsToTransform[this];
			delete _scene.objectsToMove[this];
		}
		
		/**
		 * Имя объекта. 
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
		 * Сцена, которой принадлежит объект.
		 */
		public function get scene():Scene3D {
			return _scene;
		}

		/**
		 * Родительский объект.
		 */
		public function get parent():Object3D {
			return _parent;
		}
		
		/**
		 * Набор дочерних объектов.
		 */
		public function get children():Set {
			return _children.clone();
		}
		
		/**
		 * Координата X.
		 */
		public function get x():Number {
			return _coords.x;
		}

		/**
		 * Координата Y.
		 */
		public function get y():Number {
			return _coords.y;
		}

		/**
		 * Координата Z.
		 */
		public function get z():Number {
			return _coords.z;
		}

		/**
		 * @private
		 */
		public function set x(value:Number):void {
			if (_coords.x != value) {
				_coords.x = value;
				if (_scene != null) { 
					_scene.objectsToMove[this] = true;
				}
			}
		}

		/**
		 * @private
		 */
		public function set y(value:Number):void {
			if (_coords.y != value) {
				_coords.y = value;
				if (_scene != null) {
					_scene.objectsToMove[this] = true;
				}
			}
		}

		/**
		 * @private
		 */
		public function set z(value:Number):void {
			if (_coords.z != value) {
				_coords.z = value;
				if (_scene != null) {
					_scene.objectsToMove[this] = true;
				}
			}
		}

		/**
		 * Координаты объекта.
		 */
		public function get coords():Point3D {
			return _coords.clone();
		}
		
		/**
		 * @private
		 */
		public function set coords(value:Point3D):void {
			if (!_coords.equals(value)) {
				_coords.copy(value);
				if (_scene != null) {
					_scene.objectsToMove[this] = true;
				}
			}
		}
		
		/**
		 * Угол поворота вокруг оси X, заданный в радианах.
		 */
		public function get rotationX():Number {
			return _rotationX;
		}

		/**
		 * Угол поворота вокруг оси Y, заданный в радианах.
		 */
		public function get rotationY():Number {
			return _rotationY;
		}

		/**
		 * Угол поворота вокруг оси Z, заданный в радианах.
		 */
		public function get rotationZ():Number {
			return _rotationZ;
		}

		/**
		 * @private
		 */
		public function set rotationX(value:Number):void {
			if (_rotationX != value) {
				_rotationX = value;
				if (_scene != null) {
					_scene.objectsToTransform[this] = true;
				}
			}
		}		

		/**
		 * @private
		 */
		public function set rotationY(value:Number):void {
			if (_rotationY != value) {
				_rotationY = value;
				if (_scene != null) {
					_scene.objectsToTransform[this] = true;
				}
			}
		}		

		/**
		 * @private
		 */
		public function set rotationZ(value:Number):void {
			if (_rotationZ != value) {
				_rotationZ = value;
				if (_scene != null) {
					_scene.objectsToTransform[this] = true;
				}
			}
		}
		
		/**
		 * Коэффициент масштабирования вдоль оси X.
		 */
		public function get scaleX():Number {
			return _scaleX;
		}

		/**
		 * Коэффициент масштабирования вдоль оси Y.
		 */
		public function get scaleY():Number {
			return _scaleY;
		}

		/**
		 * Коэффициент масштабирования вдоль оси Z.
		 */
		public function get scaleZ():Number {
			return _scaleZ;
		}

		/**
		 * @private
		 */
		public function set scaleX(value:Number):void {
			if (_scaleX != value) {
				_scaleX = value;
				if (_scene != null) {
					_scene.objectsToTransform[this] = true;
				}
			}
		}

		/**
		 * @private
		 */
		public function set scaleY(value:Number):void {
			if (_scaleY != value) {
				_scaleY = value;
				if (_scene != null) {
					_scene.objectsToTransform[this] = true;
				}
			}
		}

		/**
		 * @private
		 */
		public function set scaleZ(value:Number):void {
			if (_scaleZ != value) {
				_scaleZ = value;
				if (_scene != null) {
					_scene.objectsToTransform[this] = true;
				}
			}
		}
		
		/**
		 * Строковое представление объекта.
		 * 
		 * @return строковое представление объекта
		 */
		public function toString():String {
			return "[" + ObjectUtils.getClassName(this) + " " + _name + "]";
		}
				
		/**
		 * Имя объекта по умолчанию.
		 * 
		 * @return имя объекта по умолчанию
		 */		
		protected function defaultName():String {
			return "object" + ++counter;
		}
		
		/**
		 * Создание пустого объекта без какой-либо внутренней структуры. Например, если некоторый геометрический примитив при
		 * своём создании формирует набор вершин, граней и поверхностей, то этот метод не должен создавать вершины, грани и
		 * поверхности. Данный метод используется в методе clone() и должен быть переопределён в потомках для получения
		 * правильного объекта.
		 * 
		 * @return новый пустой объект
		 */
		protected function createEmptyObject():Object3D {
			return new Object3D();
		}
		
		/**
		 * Копирование свойств объекта-источника. Данный метод используется в методе clone() и должен быть переопределён в
		 * потомках для получения правильного объекта. Каждый потомок должен в переопределённом методе копировать только те
		 * свойства, которые добавлены к базовому классу именно в нём. Копирование унаследованных свойств выполняется
		 * вызовом super.clonePropertiesFrom(source).
		 * 
		 * @param source объект, свойства которого копируются
		 */
		protected function clonePropertiesFrom(source:Object3D):void {
			_name = source._name;
			_coords.x = source._coords.x;
			_coords.y = source._coords.y;
			_coords.z = source._coords.z;
			_rotationX = source._rotationX;
			_rotationY = source._rotationY;
			_rotationZ = source._rotationZ;
			_scaleX = source._scaleX;
			_scaleY = source._scaleY;
			_scaleZ = source._scaleZ;
		}
		
		/**
		 * Клонирование объекта. Для реализации собственного клонирования наследники должны переопределять методы
		 * <code>createEmptyObject()</code> и <code>clonePropertiesFrom()</code>.
		 * 
		 * @return клонированный экземпляр объекта
		 * 
		 * @see #createEmptyObject()
		 * @see #clonePropertiesFrom()
		 */
		public function clone():Object3D {
			var copy:Object3D = createEmptyObject();
			copy.clonePropertiesFrom(this);
			
			// Клонирование детей
			for (var key:* in _children) {
				var child:Object3D = key;
				copy.addChild(child.clone());
			}
			
			return copy;
		}
		
		/**
		 * Получение дочернего объекта с заданным именем.
		 * 
		 * @param name имя дочернего объекта
		 * @return любой дочерний объект с заданным именем или <code>null</code> в случае отсутствия таких объектов
		 */
		public function getChildByName(name:String):Object3D {
			for (var key:* in _children) {
				var child:Object3D = key;
				if (child._name == name) {
					return child;
				}
			}
			return null;
		}
	}
}