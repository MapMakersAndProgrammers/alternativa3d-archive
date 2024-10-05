package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
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
	
	public class Camera3D extends Object3D {
	
		/**
		 * Вьюпорт
		 */
		public var view:View;
		/**
		 * Поле зрения в радианах.
		 */
		public var fov:Number = Math.PI/2;
	
		public var nearClipping:Number = 0;
		public var farClipping:Number = 5000;
	
		// Параметры перспективы
		alternativa3d var viewSizeX:Number;
		alternativa3d var viewSizeY:Number;
		alternativa3d var focalLength:Number;
	
		// Перекрытия
		alternativa3d var occluders:Vector.<Vertex> = new Vector.<Vertex>();
		alternativa3d var numOccluders:int;
		alternativa3d var occludedAll:Boolean;
	
		alternativa3d var numDraws:int;
		alternativa3d var numPolygons:int;
		alternativa3d var numTriangles:int;
	
		/**
		 * Отрисовка иерархии объектов, в которой находится камера.
		 * Перед render(), если менялись параметры камеры, нужно вызвать updateProjection().
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
					if (root.cullingInCamera(this, root, 63) >= 0) {
						root.draw(this, root, view);
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
					view.onMouseMove();
				}
			}
		}
	
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
	
		private function invertMatrix():void {
			var a:Number = ma;
			var b:Number = mb;
			var c:Number = mc;
			var d:Number = md;
			var e:Number = me;
			var f:Number = mf;
			var g:Number = mg;
			var h:Number = mh;
			var i:Number = mi;
			var j:Number = mj;
			var k:Number = mk;
			var l:Number = ml;
			var det:Number = 1/(-c*f*i + b*g*i + c*e*j - a*g*j - b*e*k + a*f*k);
			ma = (-g*j + f*k)*det;
			mb = (c*j - b*k)*det;
			mc = (-c*f + b*g)*det;
			md = (d*g*j - c*h*j - d*f*k + b*h*k + c*f*l - b*g*l)*det;
			me = (g*i - e*k)*det;
			mf = (-c*i + a*k)*det;
			mg = (c*e - a*g)*det;
			mh = (c*h*i - d*g*i + d*e*k - a*h*k - c*e*l + a*g*l)*det;
			mi = (-f*i + e*j)*det;
			mj = (b*i - a*j)*det;
			mk = (-b*e + a*f)*det;
			ml = (d*f*i - b*h*i - d*e*j + a*h*j + b*e*l - a*f*l)*det;
		}
	
		/**
		 * @param v
		 * @param result
		 */
		public function projectGlobal(v:Vector3D, result:Vector3D):void {
			/*_tmpv[0] = v.x; _tmpv[1] = v.y; _tmpv[2] = v.z;
			 cameraMatrix.transformVectors(_tmpv, _tmpv);
			 projectionMatrix.transformVectors(_tmpv, _tmpv);
			 result.z = _tmpv[2];
			 result.x = _tmpv[0]/result.z;
			 result.y = _tmpv[1]/result.z;*/
		}
	
		// DEBUG
	
		// Режим отладки
		public var debug:Boolean = false;
	
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
				var key:*;
				for (key in debugSet[debug]) break;
				if (!key) delete debugSet[debug];
			}
		}
	
		// Проверка, находится ли объект или один из классов, от которых он нследован, в дебаге
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
	
		public var diagram:Sprite = createDiagram();
	
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
	
		public var fpsUpdatePeriod:int = 10;
		private var fpsUpdateCounter:int;
		private var previousFrameTime:int;
		private var previousPeriodTime:int;
	
		private var maxMemory:int;
	
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
			var value:Number;
			var mod:int;
			var time:int = getTimer();
			var stageFrameRate:int = diagram.stage.frameRate;
	
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
			else if (bytes < 10485760) return (bytes/1048576).toFixed(2);// + "mb";
			else if (bytes < 104857600) return (bytes/1048576).toFixed(1);// + "mb";
			else return String(bytes >> 20);// + "mb";
		}
	
		// Отложенное удаление в коллектор
	
		private var firstVertex:Vertex = new Vertex();
		private var firstFace:Face = new Face();
		private var firstWrapper:Wrapper = new Wrapper();
		alternativa3d var lastWrapper:Wrapper = firstWrapper;
		alternativa3d var lastVertex:Vertex = firstVertex;
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
	
	}
}
