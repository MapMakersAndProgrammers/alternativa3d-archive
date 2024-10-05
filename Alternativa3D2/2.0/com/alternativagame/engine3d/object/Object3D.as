package com.alternativagame.engine3d.object {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.Matrix3D;
	import com.alternativagame.engine3d.View3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.object.light.Light3D;
	import com.alternativagame.type.Set;
	import com.alternativagame.type.Vector;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.utils.Dictionary;
		
	use namespace engine3d;

	public class Object3D extends EventDispatcher {

		use namespace engine3d;

		// Название 
		private var _name:String;
		
		// Инкремент количества объектов
		private static var num:uint = 0;

		// Флаг сплошного объекта
		private var _solid:Boolean = false;
		
		// Все объекты внутри солида
		engine3d var solidObjects:Set;
		
		// Все источники света внутри солида
		engine3d var solidLights:Set;
		
		// Вершина солида
		engine3d var solidParent:Object3D;
		
		// Ссылка на родителя
		engine3d var parent:Object3D = null;
		
		// Ссылка на камеру
		engine3d var view:View3D = null;
		
		// Флаг интерактивности
		private var _interactive:Boolean = false;
		
		// Смещение объекта относительно родителя
		private var _x:Number = 0;
		private var _y:Number = 0;
		private var _z:Number = 0;

		// Поворот объекта относительно родителя
		private var _rotX:Number = 0;
		private var _rotY:Number = 0;
		private var _rotZ:Number = 0;

		// Мастшаб объекта относительно родителя
		private var _scaleX:Number = 1;
		private var _scaleY:Number = 1;
		private var _scaleZ:Number = 1;
		
		// Списки дочерних объектов
		private var _objects:Set;

		// Глобальная трансформация
		engine3d var transform:Matrix3D;

		// Изменилась позиция объекта
		engine3d var positionChanged:Boolean = true;

		// Изменилась геометрия объекта (поворот, масштаб, параметры)
		engine3d var geometryChanged:Boolean = true;
		
		// Изменилось освещение объекта
		engine3d var lightChanged:Set = new Set();
		
		public function Object3D() {
			_objects = new Set();
			
			transform = new Matrix3D();
			
			solidObjects = new Set();
			solidLights = new Set();

			solidParent = this;
			solidObjects.add(this);

			num++;
			_name = "Object" + num;
		}
		
		// Пересчитать трансформацию объекта и его детей
		engine3d function calculateTransform():void {
			if (geometryChanged || positionChanged) { // Если позиция или геометрия изменилась
				var topTransform:Matrix3D = (this === view.object) ? view.transformation : parent.transform;
				// Если изменилась геометрия - Пересчитать трансформацию
				if (geometryChanged) {
					transform = Math3D.combineMatrix(topTransform, new Matrix3D(x, y, z, rotX, rotY, rotZ, scaleX, scaleY, scaleZ));
				// Если изменилась только позиция - Скорректировать трансформацию
				} else {
					transform.d = topTransform.a*x + topTransform.b*y + topTransform.c*z + topTransform.d;
					transform.h = topTransform.e*x + topTransform.f*y + topTransform.g*z + topTransform.h;
					transform.l = topTransform.i*x + topTransform.j*y + topTransform.k*z + topTransform.l;
				}
				
				// Обновить скины
				updateTransform();
				
				// Сбрасываем флаги изменений
				positionChanged = false;
				geometryChanged = false;
			}
			// Расчитать трансформацию у дочерних объектов
			for each (var object:Object3D in objects) {
				object.calculateTransform();
			}
		}

		// Пересчитать освещение объекта и его детей
		engine3d function calculateLight():void {
			
			// Обновить освещение
			updateLight();
			
			// Удалить источники света
			clearLightChanged();
			
			// Расчитать освещение у дочерних объектов
			for each (var object:Object3D in objects) {
				object.calculateLight();
			}
		}
		
		// Обновиться после трансформации
		protected function updateTransform():void {}
		
		// Обновиться после освещения
		protected function updateLight():void {}

		// Добавить дочерний объект
		public function attach(object:Object3D):void {
			// Если объект был в другом объекте
			if (object.parent != null) {
				// Удалить его оттуда
				object.parent.detach(object);
			}
			// Добавляем в список
			objects.add(object);
			// Указываем себя как родителя
			object.setParent(this);
			// Указываем камеру
			object.setView(view);
		}

		// Удалить дочерний объект
		public function detach(object:Object3D):void {
			// Проверяем, есть ли у нас этот объект
			if (objects.has(object)) {
				// Убираем из списка
				objects.remove(object);
				// Удаляем ссылку на родителя
				object.setParent(null);
				// Удаляем ссылку на камеру
				object.setView(null);
			}
		}

		// Получить дочерний объект по имени
		public function getObjectByName(name:String):Object3D {
			var res:Object3D = null;
			for each (var object:Object3D in objects) {
				if (object.name == name) {
					res = object;
					break;
				}
			}
			return res;
		}
		
		// Проверить освещение
		protected function updateLightChanged():void {
			// Собрать все источники внутри солида
			for each (var light:Light3D in solidParent.solidLights) {
				addLightChanged(light);
			}
		}
		
		public function set name(value:String):void {
			_name = value;
		}		

		public function get name():String {
			return _name;
		}		

		public function get x():Number {
			return _x;
		}		

		public function get y():Number {
			return _y;
		}		

		public function get z():Number {
			return _z;
		}		

		public function get rotX():Number {
			return _rotX;
		}		

		public function get rotY():Number {
			return _rotY;
		}		

		public function get rotZ():Number {
			return _rotZ;
		}		

		public function get scaleX():Number {
			return _scaleX;
		}		

		public function get scaleY():Number {
			return _scaleY;
		}		

		public function get scaleZ():Number {
			return _scaleZ;
		}

		public function set x(value:Number):void {
			_x = value;
			setPositionChanged();
		}		

		public function set y(value:Number):void {
			_y = value;
			setPositionChanged();
		}		

		public function set z(value:Number):void {
			_z = value;
			setPositionChanged();
		}
		
		public function set rotX(value:Number):void {
			_rotX = value;
			setGeometryChanged();
		}		

		public function set rotY(value:Number):void {
			_rotY = value;
			setGeometryChanged();
		}		

		public function set rotZ(value:Number):void {
			_rotZ = value;
			setGeometryChanged();
		}
		
		public function set scaleX(value:Number):void {
			_scaleX = value;
			setGeometryChanged();
		}

		public function set scaleY(value:Number):void {
			_scaleY = value;
			setGeometryChanged();
		}

		public function set scaleZ(value:Number):void {
			_scaleZ = value;
			setGeometryChanged();
		}
		
		public function get objects():Set {
			return _objects;
		}
		
		public function set solid(value:Boolean):void {
			// Сохранить солид
			_solid = value;
			
			var childSolid:Object3D;
			
			if (value) {
				// Если меня установили солидом, то разослать детям себя
				childSolid = this;
			} else {
				// Если я теперь не солид, то разослать детям своего солидПарента
				childSolid = solidParent;
			}
			// Рассылаем детям нового солидПарента
			for each (var object:Object3D in objects) {
				object.setSolidParent(childSolid);
			}
			
			// Пересчитать свет
			clearLightChanged();
			updateLightChanged();
		}
		
		public function get solid():Boolean {
			return _solid;
		}

		engine3d function setSolidParent(value:Object3D):void {
			
			// Забрали себя от старого solidParent
			solidParent.solidObjects.remove(this);
			
			// Добавили себя к новому solidParent 
			value.solidObjects.add(this);
			
			// Если я не солид - установить этот солидПарент у дочерних объектов
			if (!solid) {
				for each (var object:Object3D in objects) {
					object.setSolidParent(value);
				}
			}
			solidParent = value;
		}
		
		// Установка новой камеры для объекта
		engine3d function setView(value:View3D):void {
			view = value;
			// При снятии камеры сбросить флаги и очистить источники
			if (value == null) {
				geometryChanged = false;
				positionChanged = false;
				clearLightChanged();
			// При назначении камеры установить флаги изменения и проверить свет
			} else {
				geometryChanged = true;
				positionChanged = true;
				updateLightChanged();
			}
			// Установить эту камеру у дочерних объектов
			for each (var object:Object3D in objects) {
				object.setView(value);
			}
		}

		engine3d function setParent(value:Object3D):void {
			// Если отцепили, то сам себе солидПарент
			if (value == null) {
				setSolidParent(this);
			// Взять парентСолид у парента
			} else {
				setSolidParent(value.solid ? value : value.solidParent);
			}
			parent = value;
		}
		
		// Флаги геометрии
		engine3d function setGeometryChanged():void {
			if (!geometryChanged) {
				updateLightChanged();
				for each (var object:Object3D in objects) {
					object.setGeometryChanged();
				}
				geometryChanged = true;
			}
		}

		// Флаги позиции
		engine3d function setPositionChanged():void {
			if (!positionChanged) {
				updateLightChanged();
				for each (var object:Object3D in objects) {
					object.setPositionChanged();
				}
				positionChanged = true;
			}
		}
		
		// Добавить источник света
		engine3d function addLightChanged(value:Light3D):void {
			lightChanged.add(value);
		}

		// Убрать источники света
		engine3d function clearLightChanged():void {
			lightChanged = new Set();
		}
		
		// Флаг интерактивности
		public function set interactive(value:Boolean):void {
			_interactive = value;
		}
		public function get interactive():Boolean {
			return _interactive;
		}
		
		// Координаты объекта в системе координат камеры
		engine3d function get canvasCoords():Vector {
			return (view != null) ? new Vector(transform.d, transform.h, transform.l) : null;
		}
		
		// Клон
		public function clone():Object3D {
			var res:Object3D = new Object3D();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		protected function cloneParams(object:*):void {
			var obj:Object3D = Object3D(object);
			obj.x = x;
			obj.y = y;
			obj.z = z;
			obj.rotX = rotX;
			obj.rotY = rotY;
			obj.rotZ = rotZ;
			obj.scaleX = scaleX;
			obj.scaleY = scaleY;
			obj.scaleZ = scaleZ;
			obj.solid = solid;
			obj.name = name;
			obj.interactive = interactive;
			for each (var child:Object3D in objects) {
				obj.attach(child.clone());
			}
		}
		
		// Получить ветку объектов от текущего до корневого
		engine3d function getBranch():Array {
			var res:Array = new Array();
			var object:Object3D = this;
			while (object != null) {
				res.push(object);
				object = object.parent;
			}
			return res;
		}
		
		// Получить локальные координаты внутри объекта из координат камеры
		engine3d function canvasToLocal(coords:Vector):Vector {
			var res:Vector = null;
			if (view != null) {
				// Формируем ветку объектов
				var objectList:Array = getBranch();
	
				// Перевести точку в мировые координаты
				res = Math3D.vectorTransform(coords, view.inverseTransformation);

				var object:Object3D;
				var objectMatrix:Matrix3D;
				
				// Перебираем список объектов с конца (с корневого объекта)
				var i:int;
				for (i = objectList.length - 1; i >= 0; i--) {
					object = objectList[i];
					// Трансформируем точку через матрицу в локальные координаты текущего объекта
					res = Math3D.vectorTransform(res, object.inverseTransform);
				}
			}
			return res;
		}
		
		// Расчёт обратной локальной трансформации текущего объекта
		engine3d function get inverseTransform():Matrix3D {
			var res:Matrix3D = new Matrix3D();
			Math3D.translateMatrix(res, -_x, -_y, -_z);
			Math3D.rotateZMatrix(res, -_rotZ);
			Math3D.rotateYMatrix(res, -_rotY);
			Math3D.rotateXMatrix(res, -_rotX);
			Math3D.scaleMatrix(res, 1/_scaleX, 1/_scaleY, 1/_scaleZ);
			return res;
		}
		
		
	}
}		