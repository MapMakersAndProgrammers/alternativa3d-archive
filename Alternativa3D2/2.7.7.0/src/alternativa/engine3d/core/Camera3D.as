package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	import flash.utils.getTimer;
	
	use namespace alternativa3d;
	
	/**
	 * Камера визуализирует иерархию трёхмерных объектов, в которой находится.
	 * Камера имеет усечённую пирамиду видимости, построенную из четырёх плоскостей, построенных по вьюпорту и двух по ближнему и дальнему расстоянию отсечения.
	 * Пирамида видимости нужна для исключения объектов из отрисовки, если они не попадают в поле зрения.
	 * Отрисовка осуществляется во вьюпорт — <code>View</code>.
	 * @see alternativa.engine3d.core.View
	 */
	public class Camera3D extends Object3D {
	
		/**
		 * Вьюпорт камеры.
		 * Если вьюпорт не указан, отрисовка осуществляться не будет.
		 */
		public var view:View;
		
		/**
		 * Поле зрения (field of view).
		 * Указывается в радианах.
		 * Значение по умолчанию <code>Math.PI/2</code> — это 90 градусов.
		 */
		public var fov:Number = Math.PI/2;
	
		/**
		 * Ближнее расстояние отсечения.
		 * Значение по умолчанию <code>0</code>.
		 */
		public var nearClipping:Number = 0;
		
		/**
		 * Дальнее расстояние отсечения.
		 * Значение по умолчанию <code>Number.MAX_VALUE</code>.
		 */
		public var farClipping:Number = Number.MAX_VALUE;
	
		/**
		 * @private 
		 */
		alternativa3d var viewSizeX:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var viewSizeY:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var focalLength:Number;
	
		/**
		 * @private 
		 */
		alternativa3d var occluders:Vector.<Vertex> = new Vector.<Vertex>();
		
		/**
		 * @private 
		 */
		alternativa3d var numOccluders:int;
		
		/**
		 * @private 
		 */
		alternativa3d var occludedAll:Boolean;
	
		/**
		 * @private 
		 */
		alternativa3d var numDraws:int;
		
		/**
		 * @private 
		 */
		alternativa3d var numPolygons:int;
		
		/**
		 * @private 
		 */
		alternativa3d var numTriangles:int;

		/**
		 * Отрисовывает иерархию объектов, в которой находится камера.
		 * Чтобы отрисовка произошла, камере должен быть назначен <code>view</code>.
		 */
		public function render():void {
			if (view != null) {
				// Расчёт параметров проецирования
				viewSizeX = view._width*0.5;
				viewSizeY = view._height*0.5;
				focalLength = Math.sqrt(viewSizeX*viewSizeX + viewSizeY*viewSizeY)/Math.tan(fov*0.5);
				// Расчёт матрицы перевода из глобального пространства в камеру
				composeMatrix();
				var root:Object3D = this;
				while (root._parent != null) {
					root = root._parent;
					root.composeMatrix();
					appendMatrix(root);
				}
				invertMatrix();
				// Сброс окклюдеров
				numOccluders = 0;
				occludedAll = false;
				// Сброс счётчиков
				numDraws = 0;
				numPolygons = 0;
				numTriangles = 0;
				// Сброс отрисовок
				view.numDraws = 0;
				// Отрисовка
				if (root != this && root.visible) {
					root.appendMatrix(this);
					if (root.cullingInCamera(this, 63) >= 0) {
						root.draw(this, view);
						// Отложенное удаление вершин и граней в коллектор
						deferredDestroy();
						// Зачистка окклюдеров
						clearOccluders();
					}
				}
				// Зачистка ненужных канвасов
				view.removeChildren(view.numDraws);
				// Обработка интерактивности после рендера
				if (view._interactive) {
					view.camera = this;
					view.onMouseMove();
				}
			}
		}
		
		/**
		 * Переводит точку из глобального пространства в экранные координаты.
		 * @param point Точка в глобальном пространстве.
		 * @return Объект <code>Vector3D</code>, в котором содержатся экранные координаты.
		 */
		public function projectGlobal(point:Vector3D):Vector3D {
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				appendMatrix(root);
			}
			invertMatrix();
			var res:Vector3D = new Vector3D();
			res.x = ma*point.x + mb*point.y + mc*point.z + md;
			res.y = me*point.x + mf*point.y + mg*point.z + mh;
			res.z = mi*point.x + mj*point.y + mk*point.z + ml;
			res.x = res.x*viewSizeX/res.z + view._width/2;
			res.y = res.y*viewSizeY/res.z + view._height/2;
			return res;
		}
		
		/**
		 * Расчитывает луч в глобальном пространстве.
		 * Прямая луча проходит через начало координат камеры и точку на плоскости вьюпорта, заданную <code>deltaX</code> и <code>deltaY</code>.
		 * Луч может быть использован в методе <code>intersectRay()</code> трёхмерных объектов.
		 * @param origin Начало луча. Луч начинается от <code>nearClipping</code> камеры.
		 * @param direction Направление луча.
		 * @param deltaX Горизонтальная координата в плоскости вьюпорта относительно его центра.
		 * @param deltaY Вертикальная координата в плоскости вьюпорта относительно его центра.
		 */
		public function calculateRay(origin:Vector3D, direction:Vector3D, deltaX:Number = 0, deltaY:Number = 0):void {
			// Создание луча в камере
			var dx:Number = deltaX*focalLength/viewSizeX;
			var dy:Number = deltaY*focalLength/viewSizeY;
			var dz:Number = focalLength;
			var ox:Number = dx*nearClipping/focalLength;
			var oy:Number = dy*nearClipping/focalLength;
			var oz:Number = nearClipping;
			// Перевод луча в глобальное пространство
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				appendMatrix(root);
			}
			origin.x = ma*ox + mb*oy + mc*oz + md;
			origin.y = me*ox + mf*oy + mg*oz + mh;
			origin.z = mi*ox + mj*oy + mk*oz + ml;
			direction.x = ma*dx + mb*dy + mc*dz;
			direction.y = me*dx + mf*dy + mg*dz;
			direction.z = mi*dx + mj*dy + mk*dz;
			var directionL:Number = 1/Math.sqrt(direction.x*direction.x + direction.y*direction.y + direction.z*direction.z);
			direction.x *= directionL;
			direction.y *= directionL;
			direction.z *= directionL;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Camera3D = new Camera3D();
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:Camera3D = source as Camera3D;
			fov = src.fov;
			nearClipping = src.nearClipping;
			farClipping = src.farClipping;
			debug = src.debug;
		}

		/**
		 * @private 
		 */
		override alternativa3d function composeMatrix():void {
			var cosX:Number = Math.cos(rotationX);
			var sinX:Number = Math.sin(rotationX);
			var cosY:Number = Math.cos(rotationY);
			var sinY:Number = Math.sin(rotationY);
			var cosZ:Number = Math.cos(rotationZ);
			var sinZ:Number = Math.sin(rotationZ);
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			var cosYscaleX:Number = cosY*scaleX*viewSizeX/focalLength;
			var sinXscaleY:Number = sinX*scaleY*viewSizeY/focalLength;
			var cosXscaleY:Number = cosX*scaleY*viewSizeY/focalLength;
			var cosXscaleZ:Number = cosX*scaleZ;
			var sinXscaleZ:Number = sinX*scaleZ;
			ma = cosZ*cosYscaleX;
			mb = cosZsinY*sinXscaleY - sinZ*cosXscaleY;
			mc = cosZsinY*cosXscaleZ + sinZ*sinXscaleZ;
			md = x;
			me = sinZ*cosYscaleX;
			mf = sinZsinY*sinXscaleY + cosZ*cosXscaleY;
			mg = sinZsinY*cosXscaleZ - cosZ*sinXscaleZ;
			mh = y;
			mi = -sinY*scaleX;
			mj = cosY*sinXscaleY;
			mk = cosY*cosXscaleZ;
			ml = z;
		}
	
		// DEBUG
	
		/**
		 * Флаг режима отладки.
		 * Отладочная графика будет рисоваться, только если значение <code>debug</code> установлено в <code>true</code>.
		 * Значение по умолчанию <code>false</code>.
		 * @see #addToDebug()
		 * @see #removeFromDebug()
		 */
		public var debug:Boolean = false;
	
		private var debugSet:Object = new Object();
	
		/**
		 * Добавляет объект или класс на отладку.
		 * Если добавлен класс, то в режиме отладки будут рисоваться все объекты этого класса.
		 * @param debug Значение класса <code>Debug</code>.
		 * @param objectOrClass Экземпляр <code>Object3D</code> или класс из иерархии <code>Object3D</code>.
		 * Примечание: отладочная графика будет рисоваться только при установленном в <code>true</code> свойстве камеры <code>debug</code>.
		 * @see alternativa.engine3d.core.Debug
		 * @see #debug
		 * @see #removeFromDebug()
		 */
		public function addToDebug(debug:int, objectOrClass:*):void {
			if (!debugSet[debug]) debugSet[debug] = new Dictionary();
			debugSet[debug][objectOrClass] = true;
		}
	
		/**
		 * Удаляет объект или класс из отладки.
		 * @param debug Значение класса <code>Debug</code>.
		 * @param objectOrClass Экземпляр <code>Object3D</code> или класс из иерархии <code>Object3D</code>.
		 * @see alternativa.engine3d.core.Debug
		 * @see #debug
		 * @see #addToDebug()
		 */
		public function removeFromDebug(debug:int, objectOrClass:*):void {
			if (debugSet[debug]) {
				delete debugSet[debug][objectOrClass];
				var key:*;
				for (key in debugSet[debug]) break;
				if (!key) delete debugSet[debug];
			}
		}
	
		/**
		 * @private 
		 * Проверка, находится ли объект или один из классов, от которых он нследован, в дебаге
		 */
		alternativa3d function checkInDebug(object:Object3D):int {
			var res:int = 0;
			for (var debug:int = 1; debug <= 512; debug <<= 1) {
				if (debugSet[debug]) {
					if (debugSet[debug][Object3D] || debugSet[debug][object]) {
						res |= debug;
					} else {
						var objectClass:Class = getDefinitionByName(getQualifiedClassName(object)) as Class;
						while (objectClass != Object3D) {
							if (debugSet[debug][objectClass]) {
								res |= debug;
								break;
							}
							objectClass = Class(getDefinitionByName(getQualifiedSuperclassName(objectClass)));
						}
					}
				}
			}
			return res;
		}
		
		// Диаграмма
		
		private var _diagram:Sprite = createDiagram();
	
		/**
		 * Количество кадров, через которые происходит обновление значения FPS в диаграмме.
		 * @see #diagram
		 */
		public var fpsUpdatePeriod:int = 10;
		
		/**
		 * Количество кадров, через которые происходит обновление значения MS в диаграмме.
		 * @see #diagram
		 */
		public var timerUpdatePeriod:int = 10;
		
		private var fpsTextField:TextField;
		private var memoryTextField:TextField;
		private var drawsTextField:TextField;
		private var polygonsTextField:TextField;
		private var trianglesTextField:TextField;
		private var timerTextField:TextField;
		private var graph:Bitmap;
		private var rect:Rectangle;
	
		private var _diagramAlign:String = "TR";
		private var _diagramHorizontalMargin:Number = 2;
		private var _diagramVerticalMargin:Number = 2;
	
		private var fpsUpdateCounter:int;
		private var previousFrameTime:int;
		private var previousPeriodTime:int;
	
		private var maxMemory:int;
	
		private var timerUpdateCounter:int;
		private var timeSum:int;
		private var timeCount:int;
		private var timer:int;
		
		/**
		 * Начинает отсчёт времени.
		 * Методы <code>startTimer()</code> и <code>stopTimer()</code> нужны для того, чтобы замерять время выполнения ежекадрово вызывающегося куска кода.
		 * Результат замера показывается в диаграмме в поле MS.
		 * @see #diagram
		 * @see #stopTimer()
		 */
		public function startTimer():void {
			timer = getTimer();
		}
	
		/**
		 * Заканчивает отсчёт времени.
		 * Методы <code>startTimer()</code> и <code>stopTimer()</code> нужны для того, чтобы замерять время выполнения ежекадрово вызывающегося куска кода.
		 * Результат замера показывается в диаграмме в поле MS.
		 * @see #diagram
		 * @see #startTimer()
		 */
		public function stopTimer():void {
			timeSum += getTimer() - timer;
			timeCount++;
		}
		
		/**
		 * Диаграмма, на которой отображается отладочная информация.
		 * Чтобы отобразить диаграмму, её нужно добавить на экран.
		 * FPS — Среднее количество кадров в секунду за промежуток в <code>fpsUpdatePeriod</code> кадров.<br>
		 * MS — Среднее время выполнения замеряемого с помощью <code>startTimer</code> - <code>stopTimer</code> участка кода в миллисекундах за промежуток в <code>timerUpdatePeriod</code> кадров.<br>
		 * MEM — Количество занимаемой плеером памяти в мегабайтах.<br>
		 * DRW — Количество отрисовочных вызовов в текущем кадре.<br>
		 * PLG — Количество видимых полигонов в текущем кадре.<br>
		 * TRI — Количество отрисованных треугольников в текущем кадре.
		 * @see #fpsUpdatePeriod
		 * @see #timerUpdatePeriod
		 * @see #startTimer()
		 * @see #stopTimer()
		 */
		public function get diagram():DisplayObject {
			return _diagram;
		}
		
		/**
		 * Выравнивание диаграммы относительно рабочей области.
		 * Можно использовать константы класса <code>StageAlign</code>.
		 */
		public function get diagramAlign():String {
			return _diagramAlign;
		}
	
		/**
		 * @private
		 */
		public function set diagramAlign(value:String):void {
			_diagramAlign = value;
			resizeDiagram();
		}
	
		/**
		 * Отступ диаграммы от края рабочей области по горизонтали.
		 */
		public function get diagramHorizontalMargin():Number {
			return _diagramHorizontalMargin;
		}
	
		/**
		 * @private
		 */
		public function set diagramHorizontalMargin(value:Number):void {
			_diagramHorizontalMargin = value;
			resizeDiagram();
		}
	
		/**
		 * Отступ диаграммы от края рабочей области по вертикали.
		 */
		public function get diagramVerticalMargin():Number {
			return _diagramVerticalMargin;
		}
	
		/**
		 * @private
		 */
		public function set diagramVerticalMargin(value:Number):void {
			_diagramVerticalMargin = value;
			resizeDiagram();
		}
		
		private function createDiagram():Sprite {
			var diagram:Sprite = new Sprite();
			diagram.mouseEnabled = false;
			diagram.mouseChildren = false;
			// Инициализация диаграммы
			diagram.addEventListener(Event.ADDED_TO_STAGE, function():void {
				// FPS
				fpsTextField = new TextField();
				fpsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
				fpsTextField.autoSize = TextFieldAutoSize.LEFT;
				fpsTextField.text = "FPS:";
				fpsTextField.selectable = false;
				fpsTextField.x = -3;
				fpsTextField.y = -5;
				diagram.addChild(fpsTextField);
				fpsTextField = new TextField();
				fpsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
				fpsTextField.autoSize = TextFieldAutoSize.RIGHT;
				fpsTextField.text = Number(diagram.stage.frameRate).toFixed(2);
				fpsTextField.selectable = false;
				fpsTextField.x = -3;
				fpsTextField.y = -5;
				fpsTextField.width = 65;
				diagram.addChild(fpsTextField);
				// Время выполнения метода
				timerTextField = new TextField();
				timerTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x0066FF);
				timerTextField.autoSize = TextFieldAutoSize.LEFT;
				timerTextField.text = "MS:";
				timerTextField.selectable = false;
				timerTextField.x = -3;
				timerTextField.y = 4;
				diagram.addChild(timerTextField);
				timerTextField = new TextField();
				timerTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x0066FF);
				timerTextField.autoSize = TextFieldAutoSize.RIGHT;
				timerTextField.text = "";
				timerTextField.selectable = false;
				timerTextField.x = -3;
				timerTextField.y = 4;
				timerTextField.width = 65;
				diagram.addChild(timerTextField);
				// Память
				memoryTextField = new TextField();
				memoryTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCC00);
				memoryTextField.autoSize = TextFieldAutoSize.LEFT;
				memoryTextField.text = "MEM:";
				memoryTextField.selectable = false;
				memoryTextField.x = -3;
				memoryTextField.y = 13;
				diagram.addChild(memoryTextField);
				memoryTextField = new TextField();
				memoryTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCC00);
				memoryTextField.autoSize = TextFieldAutoSize.RIGHT;
				memoryTextField.text = bytesToString(System.totalMemory);
				memoryTextField.selectable = false;
				memoryTextField.x = -3;
				memoryTextField.y = 13;
				memoryTextField.width = 65;
				diagram.addChild(memoryTextField);
				// Отрисовочные вызовы
				drawsTextField = new TextField();
				drawsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x00CC00);
				drawsTextField.autoSize = TextFieldAutoSize.LEFT;
				drawsTextField.text = "DRW:";
				drawsTextField.selectable = false;
				drawsTextField.x = -3;
				drawsTextField.y = 22;
				diagram.addChild(drawsTextField);
				drawsTextField = new TextField();
				drawsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x00CC00);
				drawsTextField.autoSize = TextFieldAutoSize.RIGHT;
				drawsTextField.text = "0";
				drawsTextField.selectable = false;
				drawsTextField.x = -3;
				drawsTextField.y = 22;
				drawsTextField.width = 52;
				diagram.addChild(drawsTextField);
				// Полигоны
				polygonsTextField = new TextField();
				polygonsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF0033);
				polygonsTextField.autoSize = TextFieldAutoSize.LEFT;
				polygonsTextField.text = "PLG:";
				polygonsTextField.selectable = false;
				polygonsTextField.x = -3;
				polygonsTextField.y = 31;
				diagram.addChild(polygonsTextField);
				polygonsTextField = new TextField();
				polygonsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF0033);
				polygonsTextField.autoSize = TextFieldAutoSize.RIGHT;
				polygonsTextField.text = "0";
				polygonsTextField.selectable = false;
				polygonsTextField.x = -3;
				polygonsTextField.y = 31;
				polygonsTextField.width = 52;
				diagram.addChild(polygonsTextField);
				// Треугольники
				trianglesTextField = new TextField();
				trianglesTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF6600);
				trianglesTextField.autoSize = TextFieldAutoSize.LEFT;
				trianglesTextField.text = "TRI:";
				trianglesTextField.selectable = false;
				trianglesTextField.x = -3;
				trianglesTextField.y = 40;
				diagram.addChild(trianglesTextField);
				trianglesTextField = new TextField();
				trianglesTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF6600);
				trianglesTextField.autoSize = TextFieldAutoSize.RIGHT;
				trianglesTextField.text = "0";
				trianglesTextField.selectable = false;
				trianglesTextField.x = -3;
				trianglesTextField.y = 40;
				trianglesTextField.width = 52;
				diagram.addChild(trianglesTextField);
				// График
				graph = new Bitmap(new BitmapData(60, 40, true, 0x20FFFFFF));
				rect = new Rectangle(0, 0, 1, 40);
				graph.x = 0;
				graph.y = 54;
				diagram.addChild(graph);
				// Сброс параметров
				previousPeriodTime = getTimer();
				previousFrameTime = previousPeriodTime;
				fpsUpdateCounter = 0;
				maxMemory = 0;
				timerUpdateCounter = 0;
				timeSum = 0;
				timeCount = 0;
				// Подписка
				diagram.stage.addEventListener(Event.ENTER_FRAME, updateDiagram, false, -1000);
				diagram.stage.addEventListener(Event.RESIZE, resizeDiagram, false, -1000);
				resizeDiagram();
			});
			// Деинициализация диаграммы
			diagram.addEventListener(Event.REMOVED_FROM_STAGE, function():void {
				// Обнуление
				diagram.removeChild(fpsTextField);
				diagram.removeChild(memoryTextField);
				diagram.removeChild(drawsTextField);
				diagram.removeChild(polygonsTextField);
				diagram.removeChild(trianglesTextField);
				diagram.removeChild(timerTextField);
				diagram.removeChild(graph);
				fpsTextField = null;
				memoryTextField = null;
				drawsTextField = null;
				polygonsTextField = null;
				trianglesTextField = null;
				timerTextField = null;
				graph.bitmapData.dispose();
				graph = null;
				rect = null;
				// Отписка
				diagram.stage.removeEventListener(Event.ENTER_FRAME, updateDiagram);
				diagram.stage.removeEventListener(Event.RESIZE, resizeDiagram);
			});
			return diagram;
		}
	
		private function resizeDiagram(e:Event = null):void {
			if (_diagram.stage != null) {
				var coord:Point = _diagram.parent.globalToLocal(new Point());
				if (_diagramAlign == StageAlign.TOP_LEFT || _diagramAlign == StageAlign.LEFT || _diagramAlign == StageAlign.BOTTOM_LEFT) {
					_diagram.x = Math.round(coord.x + _diagramHorizontalMargin);
				}
				if (_diagramAlign == StageAlign.TOP || _diagramAlign == StageAlign.BOTTOM) {
					_diagram.x = Math.round(coord.x + _diagram.stage.stageWidth/2 - graph.width/2);
				}
				if (_diagramAlign == StageAlign.TOP_RIGHT || _diagramAlign == StageAlign.RIGHT || _diagramAlign == StageAlign.BOTTOM_RIGHT) {
					_diagram.x = Math.round(coord.x + _diagram.stage.stageWidth - _diagramHorizontalMargin - graph.width);
				}
				if (_diagramAlign == StageAlign.TOP_LEFT || _diagramAlign == StageAlign.TOP || _diagramAlign == StageAlign.TOP_RIGHT) {
					_diagram.y = Math.round(coord.y + _diagramVerticalMargin);
				}
				if (_diagramAlign == StageAlign.LEFT || _diagramAlign == StageAlign.RIGHT) {
					_diagram.y = Math.round(coord.y + _diagram.stage.stageHeight/2 - (graph.y + graph.height)/2);
				}
				if (_diagramAlign == StageAlign.BOTTOM_LEFT || _diagramAlign == StageAlign.BOTTOM || _diagramAlign == StageAlign.BOTTOM_RIGHT) {
					_diagram.y = Math.round(coord.y + _diagram.stage.stageHeight - _diagramVerticalMargin - graph.y - graph.height);
				}
			}
		}
	
		private function updateDiagram(e:Event):void {
			var value:Number;
			var mod:int;
			var time:int = getTimer();
			var stageFrameRate:int = _diagram.stage.frameRate;
	
			// FPS текст
			if (++fpsUpdateCounter == fpsUpdatePeriod) {
				value = 1000*fpsUpdatePeriod/(time - previousPeriodTime);
				if (value > stageFrameRate) value = stageFrameRate;
				mod = value*100 % 100;
				fpsTextField.text = int(value) + "." + ((mod >= 10) ? mod : ((mod > 0) ? ("0" + mod) : "00"));
				previousPeriodTime = time;
				fpsUpdateCounter = 0;
			}
			// FPS график
			value = 1000/(time - previousFrameTime);
			if (value > stageFrameRate) value = stageFrameRate;
			graph.bitmapData.scroll(1, 0);
			graph.bitmapData.fillRect(rect, 0x20FFFFFF);
			graph.bitmapData.setPixel32(0, 40*(1 - value/stageFrameRate), 0xFFCCCCCC);
			previousFrameTime = time;
	
			// Время текст
			if (++timerUpdateCounter == timerUpdatePeriod) {
				if (timeCount > 0) {
					value = timeSum/timeCount;
					mod = value*100 % 100;
					timerTextField.text = int(value) + "." + ((mod >= 10) ? mod : ((mod > 0) ? ("0" + mod) : "00"));
				} else {
					timerTextField.text = "";
				}
				timerUpdateCounter = 0;
				timeSum = 0;
				timeCount = 0;
			}
	
			// Память текст
			var memory:int = System.totalMemory;
			value = memory/1048576;
			mod = value*100 % 100;
			memoryTextField.text = int(value) + "." + ((mod >= 10) ? mod : ((mod > 0) ? ("0" + mod) : "00"));
	
			// Память график
			if (memory > maxMemory) maxMemory = memory;
			graph.bitmapData.setPixel32(0, 40*(1 - memory/maxMemory), 0xFFCCCC00);
	
			// Отрисовочные вызовы текст
			drawsTextField.text = String(numDraws);
	
			// Полигоны текст
			polygonsTextField.text = String(numPolygons);
	
			// Треугольники текст
			trianglesTextField.text = String(numTriangles);
		}
	
		private function bytesToString(bytes:int):String {
			if (bytes < 1024) return bytes + "b";
			else if (bytes < 10240) return (bytes/1024).toFixed(2) + "kb";
			else if (bytes < 102400) return (bytes/1024).toFixed(1) + "kb";
			else if (bytes < 1048576) return (bytes >> 10) + "kb";
			else if (bytes < 10485760) return (bytes/1048576).toFixed(2);// + "mb";
			else if (bytes < 104857600) return (bytes/1048576).toFixed(1);// + "mb";
			else return String(bytes >> 20);// + "mb";
		}
	
		// Отложенное удаление в коллектор
	
		private var firstVertex:Vertex = new Vertex();
		private var firstFace:Face = new Face();
		private var firstWrapper:Wrapper = new Wrapper();
		
		/**
		 * @private 
		 */
		alternativa3d var lastWrapper:Wrapper = firstWrapper;
		
		/**
		 * @private 
		 */
		alternativa3d var lastVertex:Vertex = firstVertex;
		
		/**
		 * @private 
		 */
		alternativa3d var lastFace:Face = firstFace;
	
		private function deferredDestroy():void {
			for (var face:Face = firstFace.next; face != null; face = face.next) {
				var w:Wrapper = face.wrapper;
				if (w != null) {
					for (var lw:Wrapper = null; w != null; lw = w,w = w.next) {
						w.vertex = null;
					}
					lastWrapper.next = face.wrapper;
					lastWrapper = lw;
				}
				face.material = null;
				face.wrapper = null;
				//face.processNext = null;
				//face.geometry = null;
			}
			if (firstFace != lastFace) {
				lastFace.next = Face.collector;
				Face.collector = firstFace.next;
				firstFace.next = null;
				lastFace = firstFace;
			}
			if (firstWrapper != lastWrapper) {
				lastWrapper.next = Wrapper.collector;
				Wrapper.collector = firstWrapper.next;
				firstWrapper.next = null;
				lastWrapper = firstWrapper;
			}
			if (firstVertex != lastVertex) {
				lastVertex.next = Vertex.collector;
				Vertex.collector = firstVertex.next;
				firstVertex.next = null;
				lastVertex = firstVertex;
			}
		}
	
		/**
		 * @private 
		 */
		alternativa3d function clearOccluders():void {
			for (var i:int = 0; i < numOccluders; i++) {
				var first:Vertex = occluders[i];
				//for (var last:Vertex = first; last.next != null; last = last.next);
				var last:Vertex = first;
				while (last.next != null) last = last.next;
				last.next = Vertex.collector;
				Vertex.collector = first;
				occluders[i] = null;
			}
			numOccluders = 0;
		}
		
		// Вспомогательные методы
		
		/**
		 * @private 
		 */
		alternativa3d function sortByAverageZ(list:Face):Face {
			var num:int;
			var sum:Number;
			var wrapper:Wrapper;
			var left:Face = list;
			var right:Face = list.processNext;
			while (right != null && right.processNext != null) {
				list = list.processNext;
				right = right.processNext.processNext;
			}
			right = list.processNext;
			list.processNext = null;
			if (left.processNext != null) {
				left = sortByAverageZ(left);
			} else {
				num = 0;
				sum = 0;
				for (wrapper = left.wrapper; wrapper != null; wrapper = wrapper.next) {
					num++;
					sum += wrapper.vertex.cameraZ;
				}
				left.distance = sum/num;
			}
			if (right.processNext != null) {
				right = sortByAverageZ(right);
			} else {
				num = 0;
				sum = 0;
				for (wrapper = right.wrapper; wrapper != null; wrapper = wrapper.next) {
					num++;
					sum += wrapper.vertex.cameraZ;
				}
				right.distance = sum/num;
			}
			var flag:Boolean = left.distance > right.distance;
			if (flag) {
				list = left;
				left = left.processNext;
			} else {
				list = right;
				right = right.processNext;
			}
			var last:Face = list;
			while (true) {
				if (left == null) {
					last.processNext = right;
					return list;
				} else if (right == null) {
					last.processNext = left;
					return list;
				}
				if (flag) {
					if (left.distance > right.distance) {
						last = left;
						left = left.processNext;
					} else {
						last.processNext = right;
						last = right;
						right = right.processNext;
						flag = false;
					}
				} else {
					if (right.distance > left.distance) {
						last = right;
						right = right.processNext;
					} else {
						last.processNext = left;
						last = left;
						left = left.processNext;
						flag = true;
					}
				}
			}
			return null;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function sortByDynamicBSP(list:Face, threshold:Number, result:Face = null):Face {
			var w:Wrapper;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var v:Vertex;
			var splitter:Face = list;
			list = splitter.processNext;
			// Поиск удовлетворяющей нормали
			w = splitter.wrapper;
			a = w.vertex;
			w = w.next;
			b = w.vertex;
			var ax:Number = a.cameraX;
			var ay:Number = a.cameraY;
			var az:Number = a.cameraZ;
			var abx:Number = b.cameraX - ax;
			var aby:Number = b.cameraY - ay;
			var abz:Number = b.cameraZ - az;
			var normalX:Number = 0;
			var normalY:Number = 0;
			var normalZ:Number = 1;
			var offset:Number = az;
			var length:Number = 0;
			for (w = w.next; w != null; w = w.next) {
				v = w.vertex;
				var acx:Number = v.cameraX - ax;
				var acy:Number = v.cameraY - ay;
				var acz:Number = v.cameraZ - az;
				var nx:Number = acz*aby - acy*abz;
				var ny:Number = acx*abz - acz*abx;
				var nz:Number = acy*abx - acx*aby;
				var nl:Number = nx*nx + ny*ny + nz*nz;
				if (nl > threshold) {
					nl = 1/Math.sqrt(nl);
					normalX = nx*nl;
					normalY = ny*nl;
					normalZ = nz*nl;
					offset = ax*normalX + ay*normalY + az*normalZ;
					break;
				} else if (nl > length) {
					nl = 1/Math.sqrt(nl);
					normalX = nx*nl;
					normalY = ny*nl;
					normalZ = nz*nl;
					offset = ax*normalX + ay*normalY + az*normalZ;
					length = nl;
				}
			}
			var offsetMin:Number = offset - threshold;
			var offsetMax:Number = offset + threshold;
			var negativeFirst:Face;
			var negativeLast:Face;
			var splitterLast:Face = splitter;
			var positiveFirst:Face;
			var positiveLast:Face;
			var next:Face;
			for (var face:Face = list; face != null; face = next) {
				next = face.processNext;
				w = face.wrapper;
				a = w.vertex;
				w = w.next;
				b = w.vertex;
				w = w.next;
				c = w.vertex;
				w = w.next;
				var ao:Number = a.cameraX*normalX + a.cameraY*normalY + a.cameraZ*normalZ;
				var bo:Number = b.cameraX*normalX + b.cameraY*normalY + b.cameraZ*normalZ;
				var co:Number = c.cameraX*normalX + c.cameraY*normalY + c.cameraZ*normalZ;
				var behind:Boolean = ao < offsetMin || bo < offsetMin || co < offsetMin;
				var infront:Boolean = ao > offsetMax || bo > offsetMax || co > offsetMax;
				for (; w != null; w = w.next) {
					v = w.vertex;
					var vo:Number = v.cameraX*normalX + v.cameraY*normalY + v.cameraZ*normalZ;
					if (vo < offsetMin) {
						behind = true;
					} else if (vo > offsetMax) {
						infront = true;
					}
					v.offset = vo;
				}
				if (!behind) {
					if (!infront) {
						splitterLast.processNext = face;
						splitterLast = face;
					} else {
						if (positiveFirst != null) {
							positiveLast.processNext = face;
						} else {
							positiveFirst = face;
						}
						positiveLast = face;
					}
				} else if (!infront) {
					if (negativeFirst != null) {
						negativeLast.processNext = face;
					} else {
						negativeFirst = face;
					}
					negativeLast = face;
				} else {
					a.offset = ao;
					b.offset = bo;
					c.offset = co;
					var negative:Face = face.create();
					negative.material = face.material;
					lastFace.next = negative;
					lastFace = negative;
					var positive:Face = face.create();
					positive.material = face.material;
					lastFace.next = positive;
					lastFace = positive;
					var wNegative:Wrapper = null;
					var wPositive:Wrapper = null;
					var wNew:Wrapper;
					//for (w = face.wrapper.next.next; w.next != null; w = w.next);
					w = face.wrapper.next.next;
					while (w.next != null) w = w.next;
					a = w.vertex;
					ao = a.offset;
					for (w = face.wrapper; w != null; w = w.next) {
						b = w.vertex;
						bo = b.offset;
						if (ao < offsetMin && bo > offsetMax || ao > offsetMax && bo < offsetMin) {
							var t:Number = (offset - ao)/(bo - ao);
							v = b.create();
							lastVertex.next = v;
							lastVertex = v;
							v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
							v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
							v.cameraZ = a.cameraZ + (b.cameraZ - a.cameraZ)*t;
							v.u = a.u + (b.u - a.u)*t;
							v.v = a.v + (b.v - a.v)*t;
							wNew = w.create();
							wNew.vertex = v;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
							wNew = w.create();
							wNew.vertex = v;
							if (wPositive != null) {
								wPositive.next = wNew;
							} else {
								positive.wrapper = wNew;
							}
							wPositive = wNew;
						}
						if (bo <= offsetMax) {
							wNew = w.create();
							wNew.vertex = b;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
						}
						if (bo >= offsetMin) {
							wNew = w.create();
							wNew.vertex = b;
							if (wPositive != null) {
								wPositive.next = wNew;
							} else {
								positive.wrapper = wNew;
							}
							wPositive = wNew;
						}
						a = b;
						ao = bo;
					}
					if (negativeFirst != null) {
						negativeLast.processNext = negative;
					} else {
						negativeFirst = negative;
					}
					negativeLast = negative;
					if (positiveFirst != null) {
						positiveLast.processNext = positive;
					} else {
						positiveFirst = positive;
					}
					positiveLast = positive;
					face.processNext = null;
				}
			}
			if (positiveFirst != null) {
				positiveLast.processNext = null;
				if (positiveFirst.processNext != null) {
					result = sortByDynamicBSP(positiveFirst, threshold, result);
				} else {
					positiveFirst.processNext = result;
					result = positiveFirst;
				}
			}
			splitterLast.processNext = result;
			result = splitter;
			if (negativeFirst != null) {
				negativeLast.processNext = null;
				if (negativeFirst.processNext != null) {
					result = sortByDynamicBSP(negativeFirst, threshold, result);
				} else {
					negativeFirst.processNext = result;
					result = negativeFirst;
				}
			}
			return result;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function cull(list:Face, culling:int):Face {
			var first:Face;
			var last:Face;
			var next:Face;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var d:Wrapper;
			var v:Vertex;
			var w:Wrapper;
			var ax:Number;
			var ay:Number;
			var az:Number;
			var bx:Number;
			var by:Number;
			var bz:Number;
			var cx:Number;
			var cy:Number;
			var cz:Number;
			var c1:Boolean = (culling & 1) > 0;
			var c2:Boolean = (culling & 2) > 0;
			var c4:Boolean = (culling & 4) > 0;
			var c8:Boolean = (culling & 8) > 0;
			var c16:Boolean = (culling & 16) > 0;
			var c32:Boolean = (culling & 32) > 0;
			var near:Number = nearClipping;
			var far:Number = farClipping;
			var needX:Boolean = c4 || c8;
			var needY:Boolean = c16 || c32;
			for (var face:Face = list; face != null; face = next) {
				next = face.processNext;
				d = face.wrapper;
				a = d.vertex;
				d = d.next;
				b = d.vertex;
				d = d.next;
				c = d.vertex;
				d = d.next;
				if (needX) {
					ax = a.cameraX;
					bx = b.cameraX;
					cx = c.cameraX;
				}
				if (needY) {
					ay = a.cameraY;
					by = b.cameraY;
					cy = c.cameraY;
				}
				az = a.cameraZ;
				bz = b.cameraZ;
				cz = c.cameraZ;
				if (c1) {
					if (az <= near || bz <= near || cz <= near) {
						face.processNext = null;
						continue;
					}
					for (w = d; w != null; w = w.next) {
						if (w.vertex.cameraZ <= near) break;
					}
					if (w != null) {
						face.processNext = null;
						continue;
					}
				}
				if (c2 && az >= far && bz >= far && cz >= far) {
					for (w = d; w != null; w = w.next) {
						if (w.vertex.cameraZ < far) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (c4 && az <= -ax && bz <= -bx && cz <= -cx) {
					for (w = d; w != null; w = w.next) {
						v = w.vertex;
						if (-v.cameraX < v.cameraZ) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (c8 && az <= ax && bz <= bx && cz <= cx) {
					for (w = d; w != null; w = w.next) {
						v = w.vertex;
						if (v.cameraX < v.cameraZ) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (c16 && az <= -ay && bz <= -by && cz <= -cy) {
					for (w = d; w != null; w = w.next) {
						v = w.vertex;
						if (-v.cameraY < v.cameraZ) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (c32 && az <= ay && bz <= by && cz <= cy) {
					for (w = d; w != null; w = w.next) {
						v = w.vertex;
						if (v.cameraY < v.cameraZ) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (first != null) {
					last.processNext = face;
				} else {
					first = face;
				}
				last = face;
			}
			if (last != null) {
				last.processNext = null;
			}
			return first;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function clip(list:Face, culling:int):Face {
			var first:Face;
			var last:Face;
			var next:Face;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var d:Wrapper;
			var v:Vertex;
			var w:Wrapper;
			var wFirst:Wrapper;
			var wLast:Wrapper;
			var wNext:Wrapper;
			var wNew:Wrapper;
			var ax:Number;
			var ay:Number;
			var az:Number;
			var bx:Number;
			var by:Number;
			var bz:Number;
			var cx:Number;
			var cy:Number;
			var cz:Number;
			var c1:Boolean = (culling & 1) > 0;
			var c2:Boolean = (culling & 2) > 0;
			var c4:Boolean = (culling & 4) > 0;
			var c8:Boolean = (culling & 8) > 0;
			var c16:Boolean = (culling & 16) > 0;
			var c32:Boolean = (culling & 32) > 0;
			var near:Number = nearClipping;
			var far:Number = farClipping;
			var needX:Boolean = c4 || c8;
			var needY:Boolean = c16 || c32;
			var faceCulling:int;
			var t:Number;
			for (var face:Face = list; face != null; face = next) {
				next = face.processNext;
				d = face.wrapper;
				a = d.vertex;
				d = d.next;
				b = d.vertex;
				d = d.next;
				c = d.vertex;
				d = d.next;
				if (needX) {
					ax = a.cameraX;
					bx = b.cameraX;
					cx = c.cameraX;
				}
				if (needY) {
					ay = a.cameraY;
					by = b.cameraY;
					cy = c.cameraY;
				}
				az = a.cameraZ;
				bz = b.cameraZ;
				cz = c.cameraZ;
				faceCulling = 0;
				if (c1) {
					if (az <= near && bz <= near && cz <= near) {
						for (w = d; w != null; w = w.next) {
							if (w.vertex.cameraZ > near) {
								faceCulling |= 1;
								break;
							}
						}
						if (w == null) {
							face.processNext = null;
							continue;
						}
					} else if (az > near && bz > near && cz > near) {
						for (w = d; w != null; w = w.next) {
							if (w.vertex.cameraZ <= near) {
								faceCulling |= 1;
								break;
							}
						}
					} else {
						faceCulling |= 1;
					}
				}
				if (c2) {
					if (az >= far && bz >= far && cz >= far) {
						for (w = d; w != null; w = w.next) {
							if (w.vertex.cameraZ < far) {
								faceCulling |= 2;
								break;
							}
						}
						if (w == null) {
							face.processNext = null;
							continue;
						}
					} else if (az < far && bz < far && cz < far) {
						for (w = d; w != null; w = w.next) {
							if (w.vertex.cameraZ >= far) {
								faceCulling |= 2;
								break;
							}
						}
					} else {
						faceCulling |= 2;
					}
				}
				if (c4) {
					if (az <= -ax && bz <= -bx && cz <= -cx) {
						for (w = d; w != null; w = w.next) {
							v = w.vertex;
							if (-v.cameraX < v.cameraZ) {
								faceCulling |= 4;
								break;
							}
						}
						if (w == null) {
							face.processNext = null;
							continue;
						}
					} else if (az > -ax && bz > -bx && cz > -cx) {
						for (w = d; w != null; w = w.next) {
							v = w.vertex;
							if (-v.cameraX >= v.cameraZ) {
								faceCulling |= 4;
								break;
							}
						}
					} else {
						faceCulling |= 4;
					}
				}
				if (c8) {
					if (az <= ax && bz <= bx && cz <= cx) {
						for (w = d; w != null; w = w.next) {
							v = w.vertex;
							if (v.cameraX < v.cameraZ) {
								faceCulling |= 8;
								break;
							}
						}
						if (w == null) {
							face.processNext = null;
							continue;
						}
					} else if (az > ax && bz > bx && cz > cx) {
						for (w = d; w != null; w = w.next) {
							v = w.vertex;
							if (v.cameraX >= v.cameraZ) {
								faceCulling |= 8;
								break;
							}
						}
					} else {
						faceCulling |= 8;
					}
				}
				if (c16) {
					if (az <= -ay && bz <= -by && cz <= -cy) {
						for (w = d; w != null; w = w.next) {
							v = w.vertex;
							if (-v.cameraY < v.cameraZ) {
								faceCulling |= 16;
								break;
							}
						}
						if (w == null) {
							face.processNext = null;
							continue;
						}
					} else if (az > -ay && bz > -by && cz > -cy) {
						for (w = d; w != null; w = w.next) {
							v = w.vertex;
							if (-v.cameraY >= v.cameraZ) {
								faceCulling |= 16;
								break;
							}
						}
					} else {
						faceCulling |= 16;
					}
				}
				if (c32) {
					if (az <= ay && bz <= by && cz <= cy) {
						for (w = d; w != null; w = w.next) {
							v = w.vertex;
							if (v.cameraY < v.cameraZ) {
								faceCulling |= 32;
								break;
							}
						}
						if (w == null) {
							face.processNext = null;
							continue;
						}
					} else if (az > ay && bz > by && cz > cy) {
						for (w = d; w != null; w = w.next) {
							v = w.vertex;
							if (v.cameraY >= v.cameraZ) {
								faceCulling |= 32;
								break;
							}
						}
					} else {
						faceCulling |= 32;
					}
				}
				if (faceCulling > 0) {
					wFirst = null;
					wLast = null;
					w = face.wrapper;
					while (w != null) {
						wNew = w.create();
						wNew.vertex = w.vertex;
						if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
						wLast = wNew;
						w = w.next;
					}
					// Клиппинг по передней стороне
					if (faceCulling & 1) {
						a = wLast.vertex;
						az = a.cameraZ;
						for (w = wFirst, wFirst = null, wLast = null; w != null; w = wNext) {
							wNext = w.next;
							b = w.vertex;
							bz = b.cameraZ;
							if (bz > near && az <= near || bz <= near && az > near) {
								t = (near - az)/(bz - az);
								v = b.create();
								lastVertex.next = v;
								lastVertex = v;
								v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
								v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
								v.cameraZ = az + (bz - az)*t;
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								v.u = a.u + (b.u - a.u)*t;
								v.v = a.v + (b.v - a.v)*t;
								wNew = w.create();
								wNew.vertex = v;
								if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
								wLast = wNew;
							}
							if (bz > near) {
								if (wFirst != null) wLast.next = w; else wFirst = w;
								wLast = w;
								w.next = null;
							} else {
								w.vertex = null;
								w.next = Wrapper.collector;
								Wrapper.collector = w;
							}
							a = b;
							az = bz;
						}
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
					}
					// Клиппинг по задней стороне
					if (faceCulling & 2) {
						a = wLast.vertex;
						az = a.cameraZ;
						for (w = wFirst, wFirst = null, wLast = null; w != null; w = wNext) {
							wNext = w.next;
							b = w.vertex;
							bz = b.cameraZ;
							if (bz < far && az >= far || bz >= far && az < far) {
								t = (far - az)/(bz - az);
								v = b.create();
								lastVertex.next = v;
								lastVertex = v;
								v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
								v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
								v.cameraZ = az + (bz - az)*t;
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								v.u = a.u + (b.u - a.u)*t;
								v.v = a.v + (b.v - a.v)*t;
								wNew = w.create();
								wNew.vertex = v;
								if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
								wLast = wNew;
							}
							if (bz < far) {
								if (wFirst != null) wLast.next = w; else wFirst = w;
								wLast = w;
								w.next = null;
							} else {
								w.vertex = null;
								w.next = Wrapper.collector;
								Wrapper.collector = w;
							}
							a = b;
							az = bz;
						}
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
					}
					// Клиппинг по левой стороне
					if (faceCulling & 4) {
						a = wLast.vertex;
						ax = a.cameraX;
						az = a.cameraZ;
						for (w = wFirst, wFirst = null, wLast = null; w != null; w = wNext) {
							wNext = w.next;
							b = w.vertex;
							bx = b.cameraX;
							bz = b.cameraZ;
							if (bz > -bx && az <= -ax || bz <= -bx && az > -ax) {
								t = (ax + az)/(ax + az - bx - bz);
								v = b.create();
								lastVertex.next = v;
								lastVertex = v;
								v.cameraX = ax + (bx - ax)*t;
								v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
								v.cameraZ = az + (bz - az)*t;
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								v.u = a.u + (b.u - a.u)*t;
								v.v = a.v + (b.v - a.v)*t;
								wNew = w.create();
								wNew.vertex = v;
								if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
								wLast = wNew;
							}
							if (bz > -bx) {
								if (wFirst != null) wLast.next = w; else wFirst = w;
								wLast = w;
								w.next = null;
							} else {
								w.vertex = null;
								w.next = Wrapper.collector;
								Wrapper.collector = w;
							}
							a = b;
							ax = bx;
							az = bz;
						}
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
					}
					// Клипинг по правой стороне
					if (faceCulling & 8) {
						a = wLast.vertex;
						ax = a.cameraX;
						az = a.cameraZ;
						for (w = wFirst, wFirst = null, wLast = null; w != null; w = wNext) {
							wNext = w.next;
							b = w.vertex;
							bx = b.cameraX;
							bz = b.cameraZ;
							if (bz > bx && az <= ax || bz <= bx && az > ax) {
								t = (az - ax)/(az - ax + bx - bz);
								v = b.create();
								lastVertex.next = v;
								lastVertex = v;
								v.cameraX = ax + (bx - ax)*t;
								v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
								v.cameraZ = az + (bz - az)*t;
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								v.u = a.u + (b.u - a.u)*t;
								v.v = a.v + (b.v - a.v)*t;
								wNew = w.create();
								wNew.vertex = v;
								if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
								wLast = wNew;
							}
							if (bz > bx) {
								if (wFirst != null) wLast.next = w; else wFirst = w;
								wLast = w;
								w.next = null;
							} else {
								w.vertex = null;
								w.next = Wrapper.collector;
								Wrapper.collector = w;
							}
							a = b;
							ax = bx;
							az = bz;
						}
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
					}
					// Клипинг по верхней стороне
					if (faceCulling & 16) {
						a = wLast.vertex;
						ay = a.cameraY;
						az = a.cameraZ;
						for (w = wFirst, wFirst = null, wLast = null; w != null; w = wNext) {
							wNext = w.next;
							b = w.vertex;
							by = b.cameraY;
							bz = b.cameraZ;
							if (bz > -by && az <= -ay || bz <= -by && az > -ay) {
								t = (ay + az)/(ay + az - by - bz);
								v = b.create();
								lastVertex.next = v;
								lastVertex = v;
								v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
								v.cameraY = ay + (by - ay)*t;
								v.cameraZ = az + (bz - az)*t;
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								v.u = a.u + (b.u - a.u)*t;
								v.v = a.v + (b.v - a.v)*t;
								wNew = w.create();
								wNew.vertex = v;
								if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
								wLast = wNew;
							}
							if (bz > -by) {
								if (wFirst != null) wLast.next = w; else wFirst = w;
								wLast = w;
								w.next = null;
							} else {
								w.vertex = null;
								w.next = Wrapper.collector;
								Wrapper.collector = w;
							}
							a = b;
							ay = by;
							az = bz;
						}
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
					}
					// Клипинг по нижней стороне
					if (faceCulling & 32) {
						a = wLast.vertex;
						ay = a.cameraY;
						az = a.cameraZ;
						for (w = wFirst, wFirst = null, wLast = null; w != null; w = wNext) {
							wNext = w.next;
							b = w.vertex;
							by = b.cameraY;
							bz = b.cameraZ;
							if (bz > by && az <= ay || bz <= by && az > ay) {
								t = (az - ay)/(az - ay + by - bz);
								v = b.create();
								lastVertex.next = v;
								lastVertex = v;
								v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
								v.cameraY = ay + (by - ay)*t;
								v.cameraZ = az + (bz - az)*t;
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								v.u = a.u + (b.u - a.u)*t;
								v.v = a.v + (b.v - a.v)*t;
								wNew = w.create();
								wNew.vertex = v;
								if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
								wLast = wNew;
							}
							if (bz > by) {
								if (wFirst != null) wLast.next = w; else wFirst = w;
								wLast = w;
								w.next = null;
							} else {
								w.vertex = null;
								w.next = Wrapper.collector;
								Wrapper.collector = w;
							}
							a = b;
							ay = by;
							az = bz;
						}
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
					}
					face.processNext = null;
					var newFace:Face = face.create();
					newFace.material = face.material;
					lastFace.next = newFace;
					lastFace = newFace;
					newFace.wrapper = wFirst;
					face = newFace;
				}
				if (first != null) {
					last.processNext = face;
				} else {
					first = face;
				}
				last = face;
			}
			if (last != null) {
				last.processNext = null;
			}
			return first;
		}
		
	}
}
