package alternativa.engine3d.core {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.Bitmap;
	import flash.display.Bitmap3D;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	
	use namespace alternativa3d;
	
	public class Camera3D extends Object3D {
		
		public var debug:Boolean = true;
		
		public var window:Rectangle;
		
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
		public var nearClipping:Number;
		
		/**
		 * Дальнее расстояние отсечения.
		 * Значение по умолчанию <code>Number.MAX_VALUE</code>.
		 */
		public var farClipping:Number;

		/**
		 * Настройки клиппинга для текущего сплита 
		 */
		alternativa3d var currentNearClipping:Number;
		alternativa3d var currentFarClipping:Number;

		public var shadowCaster:DirectionalLight;

		public var directionalLights:Vector.<DirectionalLight>;
		alternativa3d var numDirectionalLights:int;
		
		public var omniLights:Vector.<OmniLight>;
		
		public var sortTransparentObjects:Boolean = false;
		
		/**
		 * @private 
		 */
		alternativa3d var focalLength:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var projectionMatrixData:Vector.<Number> = new Vector.<Number>(16);
		
		alternativa3d var globalMatrix:Matrix3D = new Matrix3D();
		
		/**
		 * @private 
		 */
		alternativa3d var numDraws:int;
		
		/**
		 * @private 
		 */
		alternativa3d var numTriangles:int;

		alternativa3d var transparentObjects:Vector.<Object3D> = new Vector.<Object3D>();
		alternativa3d var numTransparent:int = 0;

		public function Camera3D(nearClipping:Number, farClipping:Number) {
			this.nearClipping = nearClipping;
			this.farClipping = farClipping;
		}

		/**
		 * Отрисовывает иерархию объектов, в которой находится камера.
		 * Чтобы отрисовка произошла, камере должен быть назначен <code>view</code>.
		 */
		public function render():void {
			// Сброс счётчиков
			numDraws = 0;
			numTriangles = 0;
			if (view != null) {
				// Расчёт параметров проецирования
				var viewSizeX:Number = view._width*0.5;
				var viewSizeY:Number = view._height*0.5;
				if (window != null) {
//					projectionMatrixData[12] = -viewSizeX;
//					projectionMatrixData[13] = viewSizeY;
//					projectionMatrixData[12] = (window.x + window.width/2 - viewSizeX);
//					projectionMatrixData[13] = (-window.y - window.height/2 + viewSizeY);
				} else {
//					projectionMatrixData[12] = 0;
//					projectionMatrixData[13] = 0;
				}
				focalLength = Math.sqrt(viewSizeX*viewSizeX + viewSizeY*viewSizeY)/Math.tan(fov*0.5);
				if (window) {
					projectionMatrixData[0] = focalLength/viewSizeX*window.width/view._width;
					projectionMatrixData[5] = -focalLength/viewSizeY*window.height/view._height;
				} else {
					projectionMatrixData[0] = focalLength/viewSizeX;
					projectionMatrixData[5] = -focalLength/viewSizeY;
				}
				projectionMatrixData[10]= farClipping/(farClipping - nearClipping);
				projectionMatrixData[11]= 1;
				projectionMatrixData[14]= -nearClipping*farClipping/(farClipping - nearClipping);
				
				projectionMatrix.rawData = projectionMatrixData;
				
				composeMatrix();
				globalMatrix.identity();
				globalMatrix.append(cameraMatrix);
				var root:Object3D = this;
				while (root._parent != null) {
					root = root._parent;
					root.composeMatrix();
					globalMatrix.append(root.cameraMatrix);
				}

				// Расчёт матрицы перевода из глобального пространства в камеру
				var i:int;
				// Отрисовка
				var r:Number = (view.backgroundColor >> 16)/255;
				var g:Number = ((view.backgroundColor >> 8) & 0xFF)/255;
				var b:Number = (view.backgroundColor & 0xFF)/255;
				view.clear(r, g, b, view.backgroundAlpha);
				if (root != this && root.visible) {
					numDirectionalLights = (directionalLights == null) ? 0 : directionalLights.length;
					if (omniLights != null) {
						cameraMatrix.identity();
						cameraMatrix.append(globalMatrix);
						cameraMatrix.invert();
						
						for each (var omni:OmniLight in omniLights) {
							omni.composeMatrix();
							root = omni;
							while (root._parent != null) {
								root = root._parent;
								root.composeMatrix();
								omni.cameraMatrix.append(root.cameraMatrix);
							}
							omni.cameraMatrix.append(cameraMatrix);
							omni.cameraCoords[0] = 0;
							omni.cameraCoords[1] = 0;
							omni.cameraCoords[2] = 0;
							omni.cameraMatrix.transformVectors(omni.cameraCoords, omni.cameraCoords);
						}
					}
					if (shadowCaster != null) {
						for (var j:int = shadowCaster.numSplits - 1; j >= 0; j--) {
							// В методе update происходит отрисовка сцены в шедоумапу
							// При этом затирается матрица cameraMatrix всех объектов и камеры в том числе
							shadowCaster.update(this, view, j);

							if (j < (shadowCaster.numSplits - 1)) {
								view.clear(r, g, b, view.backgroundAlpha, 1.0, 0, Bitmap3D.CLEAR_MASK_DEPTH); 
							}

							currentNearClipping = shadowCaster.currentSplitNear;
							currentFarClipping = shadowCaster.currentSplitFar;

							projectionMatrixData[10]= currentFarClipping/(currentFarClipping - currentNearClipping);
							projectionMatrixData[14]= -currentNearClipping*currentFarClipping/(currentFarClipping - currentNearClipping);
							projectionMatrix.rawData = projectionMatrixData;

							// Считаем матрицу перевода в камеру в цикле, поскольку она перетирается в методе DirectionalLight.update выше
							cameraMatrix.identity();
							cameraMatrix.append(globalMatrix);
							cameraMatrix.invert();
							root.composeMatrix();
							root.cameraMatrix.append(cameraMatrix);
							if (root.cullingInCamera(this, 63) >= 0) {
								root.draw(this);
								if (sortTransparentObjects && numTransparent > 1) sortByDistance();
								for (i = 0; i < numTransparent; i++) {
									transparentObjects[i].draw(this);
								}
								numTransparent = 0;
								transparentObjects.length = 0;
							}
						}
					} else {
						currentNearClipping = nearClipping;
						currentFarClipping = farClipping;
						cameraMatrix.identity();
						cameraMatrix.append(globalMatrix);
						cameraMatrix.invert();
						//cameraMatrix.append(projectionMatrix);
						root.composeMatrix();
						root.cameraMatrix.append(cameraMatrix);
						if (root.cullingInCamera(this, 63) >= 0) {
							root.draw(this);
							if (sortTransparentObjects && numTransparent > 1) sortByDistance();
							for (i = 0; i < numTransparent; i++) {
								transparentObjects[i].draw(this);
							}
							numTransparent = 0;
							transparentObjects.length = 0;
						}
					}
				}
				view.flush();
			}
		}
		
		private function sortByDistance():void {
			var sortingStack:Vector.<int> = new Vector.<int>();
			var i:int;
			var j:int;
			var child:Object3D;
			var l:int = 0;
			var r:int = numTransparent - 1;
			var stackIndex:int;
			var left:Number;
			var median:Number;
			var right:Number;
			sortingStack[0] = l;
			sortingStack[1] = r;
			stackIndex = 2;
			for (i = 0; i < numTransparent; i++) {
				child = transparentObjects[i];
				child.distance = child.cameraMatrix.position.z;
			}
			while (stackIndex > 0) {
				r = sortingStack[--stackIndex];
				l = sortingStack[--stackIndex];
				j = r;
				i = l;
				child = transparentObjects[(r + l) >> 1];
				median = child.distance;
				do {
					while ((left = (transparentObjects[i] as Object3D).distance) > median) i++;
					while ((right = (transparentObjects[j] as Object3D).distance) < median) j--;
					if (i <= j) {
						child = transparentObjects[i];
						transparentObjects[i++] = transparentObjects[j];
						transparentObjects[j--] = child;
					}
				} while (i <= j);
				if (l < j) {
					sortingStack[stackIndex++] = l;
					sortingStack[stackIndex++] = j;
				}
				if (i < r) {
					sortingStack[stackIndex++] = i;
					sortingStack[stackIndex++] = r;
				}
			}
		}
		
		/**
		 * Переводит точку из глобального пространства в экранные координаты.
		 * Для расчёта необходимо, чтобы у камеры был установлен вьюпорт.
		 * @param point Точка в глобальном пространстве.
		 * @return Объект <code>Vector3D</code>, в котором содержатся экранные координаты.
		 */
		public function projectGlobal(point:Vector3D):Vector3D {
			if (view == null) throw new Error("It is necessary to have view set.");
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				cameraMatrix.append(root.cameraMatrix);
			}
			cameraMatrix.invert();
			var res:Vector3D = cameraMatrix.transformVector(point);
			var viewSizeX:Number = view._width*0.5;
			var viewSizeY:Number = view._height*0.5;
			focalLength = Math.sqrt(viewSizeX*viewSizeX + viewSizeY*viewSizeY)/Math.tan(fov*0.5);
			res.x = res.x*focalLength/res.z + viewSizeX;
			res.y = res.y*focalLength/res.z + viewSizeY;
			return res;
		}
		
		/**
		 * Расчитывает луч в глобальном пространстве.
		 * Прямая луча проходит через начало координат камеры и точку на плоскости вьюпорта, заданную <code>deltaX</code> и <code>deltaY</code>.
		 * Луч может быть использован в методе <code>intersectRay()</code> трёхмерных объектов.
		 * @param origin Начало луча. Луч начинается от <code>nearClipping</code> камеры.
		 * @param direction Направление луча.
		 * @param viewX Горизонтальная координата в плоскости вьюпорта.
		 * @param viewY Вертикальная координата в плоскости вьюпорта.
		 */
		public function calculateRay(origin:Vector3D, direction:Vector3D, viewX:Number, viewY:Number):void {
			if (view == null) throw new Error("It is necessary to have view set.");
			var viewSizeX:Number = view._width*0.5;
			var viewSizeY:Number = view._height*0.5;
			focalLength = Math.sqrt(viewSizeX*viewSizeX + viewSizeY*viewSizeY)/Math.tan(fov*0.5);
			// Создание луча в камере
			direction.x = viewX - viewSizeX;
			direction.y = viewY - viewSizeY;
			direction.z = focalLength;
			origin.x = direction.x*nearClipping/focalLength;
			origin.y = direction.y*nearClipping/focalLength;
			origin.z = nearClipping;
			// Перевод луча в глобальное пространство
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				cameraMatrix.append(root.cameraMatrix);
			}
			var org:Vector3D = cameraMatrix.transformVector(origin);
			var dir:Vector3D = cameraMatrix.deltaTransformVector(direction);
			dir.normalize();
			origin.x = org.x;
			origin.y = org.y;
			origin.z = org.z;
			direction.x = dir.x;
			direction.y = dir.y;
			direction.z = dir.z;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var camera:Camera3D = new Camera3D(nearClipping, farClipping);
			camera.cloneBaseProperties(this);
			camera.fov = fov;
			camera.nearClipping = nearClipping;
			camera.farClipping = farClipping;
			return camera;
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
				fpsTextField.width = 85;
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
				timerTextField.width = 85;
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
				memoryTextField.width = 85;
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
				drawsTextField.width = 72;
				diagram.addChild(drawsTextField);
				// Треугольники
				trianglesTextField = new TextField();
				trianglesTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF3300); // 0xFF6600, 0xFF0033
				trianglesTextField.autoSize = TextFieldAutoSize.LEFT;
				trianglesTextField.text = "TRI:";
				trianglesTextField.selectable = false;
				trianglesTextField.x = -3;
				trianglesTextField.y = 31;
				diagram.addChild(trianglesTextField);
				trianglesTextField = new TextField();
				trianglesTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF3300);
				trianglesTextField.autoSize = TextFieldAutoSize.RIGHT;
				trianglesTextField.text = "0";
				trianglesTextField.selectable = false;
				trianglesTextField.x = -3;
				trianglesTextField.y = 31;
				trianglesTextField.width = 72;
				diagram.addChild(trianglesTextField);
				// График
				graph = new Bitmap(new BitmapData(80, 40, true, 0x20FFFFFF));
				rect = new Rectangle(0, 0, 1, 40);
				graph.x = 0;
				graph.y = 45;
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
				diagram.removeChild(trianglesTextField);
				diagram.removeChild(timerTextField);
				diagram.removeChild(graph);
				fpsTextField = null;
				memoryTextField = null;
				drawsTextField = null;
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
			drawsTextField.text = formatInt(numDraws);
	
			// Треугольники текст
			trianglesTextField.text = formatInt(numTriangles);
		}
		
		private function formatInt(num:int):String {
			var n:int;
			var s:String;
			if (num < 1000) {
				return "" + num;
			} else if (num < 1000000) {
				n = num % 1000;
				if (n < 10) {
					s = "00" + n;
				} else if (n < 100) {
					s = "0" + n;
				} else {
					s = "" + n;
				}
				return int(num/1000) + " " + s;
			} else {
				n = (num % 1000000)/1000;
				if (n < 10) {
					s = "00" + n;
				} else if (n < 100) {
					s = "0" + n;
				} else {
					s = "" + n;
				}
				n = num % 1000;
				if (n < 10) {
					s += " 00" + n;
				} else if (n < 100) {
					s += " 0" + n;
				} else {
					s += " " + n;
				}
				return int(num/1000000) + " " + s;
			}
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
		
		private static var planeMesh:Mesh = createPlaneMesh();
		
		private static function createPlaneMesh():Mesh {
			var mesh:Mesh = new Mesh();
			var g:Geometry = new Geometry();
			g.addQuadFace(g.addVertex(-1, 1, 0, 0, 1), g.addVertex(1, 1, 0, 1, 1), g.addVertex(1, -1, 0, 1, 0), g.addVertex(-1, -1, 0, 0, 0));
			mesh.geometry = g;
			return mesh;
		}

		/**
		 * @private
		 * Отрисовывает материал на весь экран 
		 */
		alternativa3d function drawMaterial(material:Material):void {
			planeMesh.geometry.update(view);
			material.update(view);
			material.drawMesh(planeMesh, this);
		}

	}
}
