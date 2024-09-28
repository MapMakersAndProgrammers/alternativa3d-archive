package alternativa.engine3d.core {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
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
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;

	use namespace alternativa3d;
	
	public class Camera3D extends Object3D {
		
		/**
		 * Вьюпорт камеры. 
		 */
		public var canvas:Canvas;
		public var fov:Number = Math.PI/2;
		/**
		 * Ширина вьюпорта. 
		 */
		public var width:Number = 500;
		/**
		 * Высота вьюпорта. 
		 */
		public var height:Number = 500;
		public var farClipping:Number = 5000;
		public var farFalloff:Number = 4000;
		public var nearClipping:Number = 50;

		// Матрица проецирования
		/**
		 * @private 
		 */
		alternativa3d var projectionMatrixData:Vector.<Number> = new Vector.<Number>(16, true);
		/**
		 * @private 
		 */
		alternativa3d var projectionMatrix:Matrix3D;
		// Параметры перспективы
		/**
		 * @private 
		 */
		alternativa3d var viewSize:Number;
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
		alternativa3d var perspectiveScaleX:Number;
		/**
		 * @private 
		 */
		alternativa3d var perspectiveScaleY:Number;
		/**
		 * @private 
		 */
		alternativa3d var invertPerspectiveScaleX:Number;
		/**
		 * @private 
		 */
		alternativa3d var invertPerspectiveScaleY:Number;
		/**
		 * @private 
		 */
		alternativa3d var focalLength:Number;
		// Перекрытия
		/**
		 * @private 
		 */
		alternativa3d var occlusionPlanes:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
		/**
		 * @private 
		 */
		alternativa3d var occlusionEdges:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
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
		override alternativa3d function get canDraw():Boolean {
			return false;
		}
		
		/**
		 * Отрисовка иерархии объектов, в которой находится камера.
		 * Перед render(), если менялись параметры камеры, нужно вызвать updateProjection().
		 */
		public function render():void {
			// Расчёт матрицы перевода из рута в камеру
			cameraMatrix.identity();
			var object:Object3D = this;
			while (object._parent != null) {
				cameraMatrix.append(object.matrix);
				object = object._parent;
			}
			cameraMatrix.invert();
			cameraMatrix.appendScale(perspectiveScaleX, perspectiveScaleY, 1);
			
			numOccluders = 0;
			occludedAll = false;
			
			numTriangles = 0;
			
			// Отрисовка
			if (object.visible && object.canDraw) {
				object.cameraMatrix.identity();
				object.cameraMatrix.prepend(cameraMatrix);
				object.cameraMatrix.prepend(object.matrix);
				if (object.cullingInCamera(this, 63) >= 0) {
					// Отрисовка объекта
					canvas.numDraws = 0;
					if (debugMode) object.debug(this, object, canvas);
					object.draw(this, object, canvas);
					// Если не нарисовалось, зачищаем рутовый канвас
					if (canvas.numDraws == 0) canvas.removeChildren(0);
				} else {
					// Если отсеклось, зачищаем рутовый канвас
					canvas.removeChildren(0);
				}
			}
		}
		
		/**
		 * После изменения параметров fov, width, height нужно вызвать этот метод.
		 */
		public function updateProjection():void {
			// Расчёт параметров перспективы
			viewSize = Math.sqrt(width*width + height*height)*0.5;
			focalLength = viewSize/Math.tan(fov*0.5);
			viewSizeX = width*0.5;
			viewSizeY = height*0.5;
			perspectiveScaleX = focalLength/viewSizeX;
			perspectiveScaleY = focalLength/viewSizeY;
			invertPerspectiveScaleX = viewSizeX/focalLength;
			invertPerspectiveScaleY = viewSizeY/focalLength;
			
			// Подготовка матрицы проецирования
			projectionMatrixData[0] = viewSizeX;
			projectionMatrixData[5] = viewSizeY;
			projectionMatrixData[10] = 1;
			projectionMatrixData[11] = 1;
			projectionMatrix = new Matrix3D(projectionMatrixData);
		}
		
		/*
		// Occlusion culling
			if (numOccluders > 0) {
				for (var n:int = 0; n < numOccluders; n++) {
					var occluder:Vector.<Number> = occluders[n];
					var occlude:Boolean = true; 
					occlude: for (var j:int = 0, length:int = occluder.length; j < length;) {
						var x:Number = occluder[j++], y:Number = occluder[j++], z:Number = occluder[j++]
						for (i = 0; i <= 21; i += 3) {
							if (boundBoxVertices[i]*x + boundBoxVertices[int(i + 1)]*y + boundBoxVertices[int(i + 2)]*z > 0) {
								occlude = false;
								break occlude; 
							}
						}
					}
					if (occlude) return -1;
				}
			}
		*/
		
		private static var _tmpv:Vector.<Number> = new Vector.<Number>(3);
		
		/**
		 * @param v
		 * @param result
		 */
		public function projectGlobal(v:Vector3D, result:Vector3D):void {
			_tmpv[0] = v.x; _tmpv[1] = v.y; _tmpv[2] = v.z;
			cameraMatrix.transformVectors(_tmpv, _tmpv);
			projectionMatrix.transformVectors(_tmpv, _tmpv);
			result.z = _tmpv[2];
			result.x = _tmpv[0]/result.z;
			result.y = _tmpv[1]/result.z;
		}
		
		// DEBUG
		
		// Режим отладки
		public var debugMode:Boolean = false;
		
		// Список объектов дебага
		private var debugSet:Object = new Object();
		
		// Добавить в дебаг
		public function addToDebug(debug:int, ... rest):void {
			if (!debugSet[debug]) debugSet[debug] = new Dictionary();
			for (var i:int = 0; i < rest.length;) debugSet[debug][rest[i++]] = true;
		}
		
		// Убрать из дебага
		public function removeFromDebug(debug:int, ... rest):void {
			if (debugSet[debug]) {
				for (var i:int = 0; i < rest.length;) delete debugSet[debug][rest[i++]];
				for (var key:* in debugSet[debug]);
				if (!key) delete debugSet[debug];
			}
		}
		
		// Проверка, находится ли объект или один из классов, от которых он нследован, в дебаге
		alternativa3d function checkInDebug(object:Object3D):int {
			var res:int = 0;
			for (var debug:int = 1; debug <= 256; debug = debug << 1) {
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
		
		public var diagram:Sprite = createDiagram();
		
		private var fpsTextField:TextField;
		private var memoryTextField:TextField;
		private var trianglesTextField:TextField;
		private var timerTextField:TextField;
		private var graph:Bitmap;
		private var rect:Rectangle;
		
		private var _diagramAlign:String = "TR";
		private var _diagramHorizontalMargin:Number = 2;
		private var _diagramVerticalMargin:Number = 2;

		public var fpsUpdatePeriod:int = 10;
		private var fpsUpdateCounter:int;
		private var previousFrameTime:int;
		private var previousPeriodTime:int;
	
		private var maxMemory:int;
		alternativa3d var numTriangles:int;

		public var timerUpdatePeriod:int = 10;
		private var timerUpdateCounter:int;
		private var timeSum:int;
		private var timeCount:int;
		private var timer:int;

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
				fpsTextField.text = "FPS: " + Number(diagram.stage.frameRate).toFixed(2);
				fpsTextField.selectable = false;
				fpsTextField.x = -3;
				fpsTextField.y = -5;
				diagram.addChild(fpsTextField);
				// Память
				memoryTextField = new TextField();
				memoryTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCC00);
				memoryTextField.autoSize = TextFieldAutoSize.LEFT;
				memoryTextField.text = "MEM: " + bytesToString(System.totalMemory);
				memoryTextField.selectable = false;
				memoryTextField.x = -3;
				memoryTextField.y = 4;
				diagram.addChild(memoryTextField);
				// Треугольники
				trianglesTextField = new TextField();
				trianglesTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF6600);
				trianglesTextField.autoSize = TextFieldAutoSize.LEFT;
				trianglesTextField.text = "TRI: " + 0;
				trianglesTextField.selectable = false;
				trianglesTextField.x = -2;
				trianglesTextField.y = 13;
				diagram.addChild(trianglesTextField);
				// Время выполнения метода
				timerTextField = new TextField();
				timerTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x0066FF);
				timerTextField.autoSize = TextFieldAutoSize.LEFT;
				timerTextField.text = "TMR:";
				timerTextField.selectable = false;
				timerTextField.x = -2;
				timerTextField.y = 13 + 9;
				diagram.addChild(timerTextField);
				// График
				graph = new Bitmap(new BitmapData(60, 40, true, 0x20FFFFFF));
				rect = new Rectangle(0, 0, 1, 40)
				graph.x = 0;
				graph.y = 27 + 9;
				diagram.addChild(graph);
				// Сброс параметров
				previousFrameTime = previousPeriodTime = getTimer();
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
				diagram.removeChild(trianglesTextField);
				diagram.removeChild(graph);
				fpsTextField = null;
				memoryTextField = null;
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
			if (diagram.stage != null) {
				var coord:Point = diagram.parent.globalToLocal(new Point());
				if (_diagramAlign == StageAlign.TOP_LEFT || _diagramAlign == StageAlign.LEFT || _diagramAlign == StageAlign.BOTTOM_LEFT) {
					diagram.x = Math.round(coord.x + _diagramHorizontalMargin);
				}
				if (_diagramAlign == StageAlign.TOP || _diagramAlign == StageAlign.BOTTOM) {
					diagram.x = Math.round(coord.x + diagram.stage.stageWidth/2 - graph.width/2);
				}
				if (_diagramAlign == StageAlign.TOP_RIGHT || _diagramAlign == StageAlign.RIGHT || _diagramAlign == StageAlign.BOTTOM_RIGHT) {
					diagram.x = Math.round(coord.x + diagram.stage.stageWidth - _diagramHorizontalMargin - graph.width);
				}
				if (_diagramAlign == StageAlign.TOP_LEFT || _diagramAlign == StageAlign.TOP || _diagramAlign == StageAlign.TOP_RIGHT) {
					diagram.y = Math.round(coord.y + _diagramVerticalMargin);
				}
				if (_diagramAlign == StageAlign.LEFT || _diagramAlign == StageAlign.RIGHT) {
					diagram.y = Math.round(coord.y + diagram.stage.stageHeight/2 - (graph.y + graph.height)/2);
				}
				if (_diagramAlign == StageAlign.BOTTOM_LEFT || _diagramAlign == StageAlign.BOTTOM || _diagramAlign == StageAlign.BOTTOM_RIGHT) {
					diagram.y = Math.round(coord.y + diagram.stage.stageHeight - _diagramVerticalMargin - graph.y - graph.height);
				}
			}
		}
				
		private function updateDiagram(e:Event):void {
			var fps:Number;
			var mod:int;
			var time:int = getTimer();
			var stageFrameRate:int = diagram.stage.frameRate;

			// FPS текст
			if (++fpsUpdateCounter == fpsUpdatePeriod) {
				fps = 1000*fpsUpdatePeriod/(time - previousPeriodTime);
				if (fps > stageFrameRate) fps = stageFrameRate;
				mod = fps*100 % 100;
				fpsTextField.text = "FPS: " + int(fps) + "." + ((mod >= 10) ? mod : ((mod > 0) ? ("0" + mod) : "00"));
				previousPeriodTime = time;
				fpsUpdateCounter = 0;
			}
			// FPS график
			fps = 1000/(time - previousFrameTime);
			if (fps > stageFrameRate) fps = stageFrameRate;
			graph.bitmapData.scroll(1, 0);
			graph.bitmapData.fillRect(rect, 0x20FFFFFF);
			graph.bitmapData.setPixel32(0, 40*(1 - fps/stageFrameRate), 0xFFCCCCCC);
			previousFrameTime = time;
			
			// Память текст
			var memory:int = System.totalMemory;
			memoryTextField.text = "MEM: " + bytesToString(memory);
			// Память график
			if (memory > maxMemory) maxMemory = memory;
			graph.bitmapData.setPixel32(0, 40*(1 - memory/maxMemory), 0xFFCCCC00);

			// Треугольники текст
			trianglesTextField.text = "TRI: " + numTriangles;

			// Время текст
			if (++timerUpdateCounter == timerUpdatePeriod) {
				if (timeCount > 0) {
					fps = timeSum/timeCount;
					mod = fps*100 % 100;
					timerTextField.text = "TMR: " + int(fps) + "." + ((mod >= 10) ? mod : ((mod > 0) ? ("0" + mod) : "00"));
				} else {
					timerTextField.text = "TMR:";
				}
				timerUpdateCounter = 0;
				timeSum = 0;
				timeCount = 0;
			}
		}
		
		public function startTimer():void {
			timer = getTimer();
		}
		
		public function stopTimer():void {
			timeSum += getTimer() - timer;
			timeCount++;
		}
		
		public function get diagramAlign():String {
			return _diagramAlign;
		}
		public function set diagramAlign(value:String):void {
			_diagramAlign = value;
			resizeDiagram();
		} 
		
		public function get diagramHorizontalMargin():Number {
			return _diagramHorizontalMargin;
		}
		public function set diagramHorizontalMargin(value:Number):void {
			_diagramHorizontalMargin = value;
			resizeDiagram();
		} 
		
		public function get diagramVerticalMargin():Number {
			return _diagramVerticalMargin;
		}
		public function set diagramVerticalMargin(value:Number):void {
			_diagramVerticalMargin = value;
			resizeDiagram();
		} 
		
		private function bytesToString(bytes:int):String {
			if (bytes < 1024) return bytes + "b";
			else if (bytes < 10240) return (bytes/1024).toFixed(2) + "kb";
			else if (bytes < 102400) return (bytes/1024).toFixed(1) + "kb";
			else if (bytes < 1048576) return (bytes >> 10) + "kb";
			else if (bytes < 10485760) return (bytes/1048576).toFixed(2) + "mb";
			else if (bytes < 104857600) return (bytes/1048576).toFixed(1) + "mb";
			else return (bytes >> 20) + "mb";
		}
		
	}
}