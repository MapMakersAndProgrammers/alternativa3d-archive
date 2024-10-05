package com.alternativagame.engine3d {
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.skin.Skin;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Set;
	import com.alternativagame.type.Vector;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	use namespace engine3d;
	
	public class View3D extends Sprite {
		
		use namespace engine3d;

		// Корневой объект
		private var _object:Object3D = null;
		
		// Область отрисовки спрайтов
		private var canvas:Sprite;
		private var canvasCoords:Vector; 
		
		// Список скинов на изменение глубины
		private var skinsToDepth:Array;
		// Список скинов на перепозиционирование
		private var skinsToPosition:Set;
		// Список скинов на отрисовку
		private var skinsToDraw:Set;
		// Список скинов на освещение
		private var skinsToLight:Set;

		// Размеры окна камеры
		private var _width:uint;
		private var _height:uint;
		
		// Флаг ограничения окна камеры
		private var _crop:Boolean = false;
		
		// Координаты камеры относительно начала координат
		private var _targetX:Number = 0;
		private var _targetY:Number = 0;
		private var _targetZ:Number = 0;

		// Повороты камеры
		private var _pitch:Number = 0;
		private var _roll:Number = 0;
		private var _yaw:Number = 0;
		
		// Степень увеличения объектов
		private var _zoom:Number = 1;

		// Трансформация камеры
		engine3d var transformation:Matrix3D;
		engine3d var inverseTransformation:Matrix3D;

		// Изменилась точка обзора камеры
		engine3d var positionChanged:Boolean = true;

		// Изменился угол обзора или масштаб
		engine3d var geometryChanged:Boolean = true;
		
		// Флаг заморозки камеры
		private var _hold:Boolean = false;

		// Текущий нажатый объект
		private var pressedObject:Object3D;

		public function View3D(width:uint, height:uint) {
			 			
			hitArea = new Sprite();
			hitArea.mouseEnabled = false;
			hitArea.visible = false;
			with (hitArea.graphics) {
				beginFill(0);
				drawRect(0, 0, 100, 100);
			}
			addChild(hitArea);
			
			canvas = new Sprite();
			canvas.mouseEnabled = false;
			canvas.mouseChildren = false;
			addChild(canvas);
			
			canvasCoords = new Vector();
			
			this.width = width;
			this.height = height;

			skinsToDepth = new Array();
			skinsToPosition = new Set();
			skinsToDraw = new Set();
			skinsToLight = new Set();
			
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		private function onMouseDown(e:MouseEvent):void {
			dispatchEvent3D(Event3D.DOWN, e.ctrlKey, e.altKey, e.shiftKey);
		}
		
		private function onMouseUp(e:MouseEvent):void {
			dispatchEvent3D(Event3D.UP, e.ctrlKey, e.altKey, e.shiftKey);
		}
		
		private function dispatchEvent3D(type:String, ctrlKey:Boolean, altKey:Boolean, shiftKey:Boolean):void {
			var mouse:Point = new Point(stage.mouseX, stage.mouseY);
			var skin:Skin = getSkinFromPoint(mouse);
			
			// Если нажали на интерактивный скин
			if (skin != null && skin.interactive) {

				// При нажатии сохраняем нажатый объект
				if (type == Event3D.DOWN) {
					pressedObject = skin.object;
				}

				var click:Boolean = (type == Event3D.UP && pressedObject == skin.object);

				// Получаем пересечение вектора мыши со скином
				var canvasCoords:Vector = skin.getIntersectionCoords(canvas.globalToLocal(mouse));
				
				// Формируем ветку объектов
				var objectList:Array = skin.object.getBranch();
				
				// Перевести точку в мировые координаты
				var worldCoords:Vector = Math3D.vectorTransform(canvasCoords, inverseTransformation);
				
				// Рассчитываем точку в координатах каждого из родительских объектах и формируем список
				var coordsList:Array = new Array();
				
				var objectMatrix:Matrix3D;
				var objectCoords:Vector = worldCoords.clone();
				var currentObject:Object3D;
				
				// Перебираем список объектов с конца (с корневого объекта)
				var i:int;
				for (i = objectList.length - 1; i >= 0; i--) {
					currentObject = objectList[i];
					// Трансформируем точку через матрицу в локальные координаты текущего объекта
					objectCoords = Math3D.vectorTransform(objectCoords, currentObject.inverseTransform);
					coordsList[i] = objectCoords.clone();
				}
				
				// Рассылаем события от объектов
				for (i = 0; i < objectList.length; i++) {
					currentObject = objectList[i];
					currentObject.dispatchEvent(new Event3D(type, ctrlKey, altKey, shiftKey, skin.object, skin.polygon, skin.material, canvasCoords, objectCoords, coordsList[i])); 
					// Если отжали на нажатом объекте, то отправить ещё и клик 
					if (click) {
						currentObject.dispatchEvent(new Event3D(Event3D.CLICK, ctrlKey, altKey, shiftKey, skin.object, skin.polygon, skin.material, canvasCoords, objectCoords, coordsList[i]));
					}
				}
				
				// Отослать событие от камеры
				dispatchEvent(new Event3D(type, ctrlKey, altKey, shiftKey, skin.object, skin.polygon, skin.material, canvasCoords, objectCoords, worldCoords));
				
				// Если отжали на нажатом объекте, то отправить ещё и клик 
				if (click) {
					dispatchEvent(new Event3D(Event3D.CLICK, ctrlKey, altKey, shiftKey, skin.object, skin.polygon, skin.material, canvasCoords, objectCoords, worldCoords));
				}
				
			} else {
				// При нажатии на пустое место сбрасываем нажатый объект
				if (type == Event3D.DOWN) {
					pressedObject = null;
				}
				
				// Рассылаем пустое событие
				dispatchEvent(new Event3D(type, ctrlKey, altKey, shiftKey));
				
				// Если нажатый объект также был пуст, то отправить клик на пустое место 
				if (type == Event3D.UP && pressedObject == null) {
					dispatchEvent(new Event3D(Event3D.CLICK, ctrlKey, altKey, shiftKey));
				}
			}

			
		}
		
		// Получить скин по заданным координатам
		public function getSkinFromPoint(point:Point):Skin {
			// Получаем список объектов под координатой
			var objectList:Array = getObjectsUnderPoint(point);
			
			// Оставить в списке только скины
			var skinList:Array = new Array(); 
			var len:uint = objectList.length;
			for (var i:uint = 0; i < len; i++) {
				if (objectList[i] is Skin) {
					skinList.push(objectList[i]);
				}
			}
			
			// Сортируем их по глубине
			skinList.sortOn("sortDepth", Array.NUMERIC);
			
			// Возвращаем самый близкий
			return skinList[0];
		}
		
		
		// Заморозить изображение камеры
		public function hold():void {
			_hold = true;
			canvas.cacheAsBitmap = true;
		}

		// Заморозить изображение камеры
		public function unhold():void {
			_hold = false;
			canvas.cacheAsBitmap = false;
		}
		
		// Перерисовать объекты в камере
		public function draw():void {
			if (object != null) {

				// Если изменилась геометрия
				if (geometryChanged) {
					
					// Пересчитать трансформацию
					transformation = new Matrix3D();
					Math3D.rotateZMatrix(transformation, -_yaw);
					Math3D.rotateYMatrix(transformation, -_roll);
					Math3D.rotateXMatrix(transformation, -_pitch);
					Math3D.scaleMatrix(transformation, _zoom, _zoom, _zoom);
					
				}
				
				// Если изменилась позиция
				if (geometryChanged || positionChanged) {
	
					// Передвигаем всю область скинов
					canvasCoords = Math3D.vectorTransform(new Vector(-_targetX, -_targetY, -_targetZ), transformation);

					// Пересчитать инверсную трансформацию
					var inv:Matrix3D = new Matrix3D(_targetX, _targetY, _targetZ, _pitch, _roll, _yaw, 1/_zoom, 1/_zoom, 1/_zoom);
					inv.d += inv.a*canvasCoords.x + inv.b*canvasCoords.y + inv.c*canvasCoords.z;
					inv.h += inv.e*canvasCoords.x + inv.f*canvasCoords.y + inv.g*canvasCoords.z;
					inv.l += inv.i*canvasCoords.x + inv.j*canvasCoords.y + inv.k*canvasCoords.z;
					inverseTransformation = inv;
					
					canvas.x = width/2 + canvasCoords.x;
					canvas.y = height/2 - canvasCoords.z;
					
				}

				geometryChanged = false;
				positionChanged = false;

				// Если камера не заморожена
				if (!_hold) {
					// Расчитываем трансформацию дерева объектов
					object.calculateTransform();
	
					// Расчитать освещение дерева объектов
					object.calculateLight();
					
					
					if (skinsToDepth.length > 0 || skinsToPosition.length > 0 || skinsToDraw.length > 0 || skinsToLight.length > 0) {
						trace(skinsToDepth.length, skinsToDraw.length, skinsToPosition.length, skinsToLight.length);
					}
					
					
					// Сортируем глубины
					sortDepths();
					
					var skin:Skin;
					// Позиционируем скины
					for each (skin in skinsToPosition) {
						skin.position();
					}
					skinsToPosition = new Set();
					
					// Отрисовываем скины
					for each (skin in skinsToDraw) {
						skin.draw();
					}
					skinsToDraw = new Set();
					
					// Освещаем скины
					for each (skin in skinsToLight) {
						skin.light();
					}
					skinsToLight = new Set();
					
				}
			}
		}
		
		// Запуск стирания скина
		private function clearSkin(skin:Skin, index:int, arr:Array):void {
			canvas.removeChild(DisplayObject(skin));
		}

		// Сортировка глубин скинов
		private function sortDepths():void {
			 
			// Убираем скины из списка
			skinsToDepth.forEach(clearSkin);
			
			// Сортируем скины по глубине
			skinsToDepth.sortOn("sortDepth", Array.NUMERIC | Array.DESCENDING);
			
			// Вставляем скины на нужные глубины
			var ma:int = -1;
			var mb:int = (canvas.numChildren > 0) ? canvas.numChildren : 0;
			
			var side:Boolean = false;
			var skin:Skin;
			var a:int;
			var b:int;
			var c:int;
			var len:uint = skinsToDepth.length;
			
			for (var i:uint = 0; i < len; i++) {
				skin = (side) ? skinsToDepth.pop() : skinsToDepth.shift();
				a = ma;
				b = mb;
				while (a < b - 1) {
					c = (a + b) >>> 1;
					(skin.sortDepth >= (canvas.getChildAt(c) as Skin).sortDepth) ? (b = c) : (a = c);
				}
				canvas.addChildAt(DisplayObject(skin), b);
				(side) ? (mb = b) : (ma = b);
				mb++;
				side = !side;
			}
		}		 

		// Добавить скин в список изменения глубин
		engine3d function addToDepth(skin:Skin):void {
			if (skinsToDepth.indexOf(skin) < 0) skinsToDepth.push(skin);
		}

		// Добавить скин в список репозиционированных в следующий раз
		engine3d function addToPosition(skin:Skin):void {
			skinsToPosition.add(skin);
		}

		// Добавить скин в список отрисовываемых в следующий раз
		engine3d function addToDraw(skin:Skin):void {
			skinsToDraw.add(skin);
		}

		// Добавить скин в список освещаемых в следующий раз
		engine3d function addToLight(skin:Skin):void {
			skinsToLight.add(skin);
		}

		// Добавить скин
		engine3d function addSkin(skin:Skin):void {
			canvas.addChild(DisplayObject(skin));
		}

		// Убрать скин
		engine3d function removeSkin(skin:Skin):void {
			// Удаляем скин из камеры
			canvas.removeChild(DisplayObject(skin));
			// Удаляем из списка на сортировку
			var i:int = skinsToDepth.indexOf(skin);
			if (i>=0) skinsToDepth.splice(i,1);
			// Удаляем из список на отрисовку, позиционирование и освещение
			skinsToPosition.remove(skin);
			skinsToDraw.remove(skin);
			skinsToLight.remove(skin);
		}

		// Указать корневой объект
		public function set object(value:Object3D):void {
			// Если есть текущий объект
			if (object != null) {
				// Снимаем у него камеру
				object.setView(null);
			}
			
			// Если устанавливаем не пустой объект
			if (value != null) {
				// Если объект был в другой камере и был там корневым
				if (value.view != null && value === value.view.object) {
					// Снимаем у той камеры объект
					value.view.object = null;
				} else {
					// Если объект был в другом объекте
					if (value.parent != null) {
						// Удалить его оттуда
						value.parent.detach(value);
					}
				}
				// Указываем объектам камеру
				value.setView(this);
			}
			
			_object = value;
		}

		public function get object():Object3D {
			return _object;
		}

		public function get targetX():Number {
			return _targetX;
		}		

		public function get targetY():Number {
			return _targetY;
		}		

		public function get targetZ():Number {
			return _targetZ;
		}		
		
		public function get zoom():Number {
			return _zoom;
		}

		public function get pitch():Number {
			return _pitch;
		}

		public function get roll():Number {
			return _roll;
		}

		public function get yaw():Number {
			return _yaw;
		}
	
		public function set targetX(value:Number):void {
			_targetX = value;
			positionChanged = true;
		}		

		public function set targetY(value:Number):void {
			_targetY = value;
			positionChanged = true;
		}		

		public function set targetZ(value:Number):void {
			_targetZ = value;
			positionChanged = true;
		}
		
		public function set pitch(value:Number):void {
			_pitch = value;
			setGeometryChanged();
		}		

		public function set roll(value:Number):void {
			_roll = value;
			setGeometryChanged();
		}		

		public function set yaw(value:Number):void {
			_yaw = value;
			setGeometryChanged();
		}
		
		public function set zoom(value:Number):void {
			_zoom = value;
			setGeometryChanged();
		}

		engine3d function setGeometryChanged():void {
			// Изменить геометрию у объекта и его потомков
			if (!geometryChanged && object != null) {
				object.setGeometryChanged();
				geometryChanged = true;
			}
		}
		
		override public function set width(value:Number):void {
			_width = value;
			hitArea.width = _width;
			canvas.x = _width/2 + canvasCoords.x;
			if (crop) {
				scrollRect = new Rectangle(0, 0, _width, height);
			}
		}

		override public function get width():Number {
			return _width;
		}

		override public function set height(value:Number):void {
			_height = value;
			hitArea.height = _height;
			canvas.y = _height/2 - canvasCoords.z;
			if (crop) {
				scrollRect = new Rectangle(0, 0, width, _height);
			}
		}

		override public function get height():Number {
			return _height;
		}

		public function set crop(value:Boolean):void {
			_crop = value;
			if (value) {
				scrollRect = new Rectangle(0, 0, width, height);
			} else {
				scrollRect = null;
			}
		}

		public function get crop():Boolean {
			return _crop;
		}
		
		public function get mouseCanvasCoords():Point {
			var res:Point = null;
			if (stage != null) {
				res = canvas.globalToLocal(new Point(stage.mouseX, stage.mouseY));
			}
			return res;
		}
		
		public function canvasToView(coords:Vector):Vector {
			return Math3D.vectorAdd(coords, canvasCoords);
		}

		public function viewToCanvas(coords:Vector):Vector {
			return Math3D.vectorSub(coords, canvasCoords);
		}

	
	}
}
