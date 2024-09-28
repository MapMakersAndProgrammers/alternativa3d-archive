package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	use namespace alternativa3d;
	
	public class View extends Canvas {
	
		static private const mouse:Point = new Point();
		static private const listeners:Vector.<Function> = new Vector.<Function>();
	
		alternativa3d var _width:Number;
		alternativa3d var _height:Number;
	
		alternativa3d var _interactive:Boolean = false;
	
		private var altKey:Boolean;
		private var ctrlKey:Boolean;
		private var shiftKey:Boolean;
	
		private var pressedObject:Object3D;
		private var clickedObject:Object3D;
		private var overedObject:Object3D;
		private var overedBranch:Vector.<Object3D> = new Vector.<Object3D>();
	
		public function View(width:Number, height:Number, interactive:Boolean = false) {
			_width = width;
			_height = height;
			_interactive = interactive;
			mouseEnabled = false;
			mouseChildren = false;
			tabEnabled = false;
			tabChildren = false;
	
			addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage);
		}
	
		private function onAddToStage(e:Event):void {
			if (_interactive) addListeners();
		}
	
		private function onRemoveFromStage(e:Event):void {
			if (_interactive) removeListeners();
		}
	
		public function get interactive():Boolean {
			return _interactive;
		}
	
		public function set interactive(value:Boolean):void {
			if (_interactive != value) {
				if (stage != null) {
					if (value) {
						addListeners();
					} else {
						removeListeners();
					}
				}
				_interactive = value;
			}
		}
	
		private function addListeners():void {
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.CLICK, onClick);
			stage.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKey);
		}
	
		private function removeListeners():void {
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.removeEventListener(MouseEvent.CLICK, onClick);
			stage.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
			stage.removeEventListener(KeyboardEvent.KEY_UP, onKey);
			pressedObject = null;
			clickedObject = null;
			overedObject = null;
			overedBranch.length = 0;
		}
	
		private function onMouseDown(mouseEvent:MouseEvent):void {
			altKey = mouseEvent.altKey;
			ctrlKey = mouseEvent.ctrlKey;
			shiftKey = mouseEvent.shiftKey;
			var targetCanvas:Canvas = defineTargetCanvas();
			if (targetCanvas != null) {
				pressedObject = targetCanvas.interactiveObject;
				dispatchEventToCanvasHierarchy(MouseEvent3D.MOUSE_DOWN, targetCanvas);
			}
		}
	
		private function onClick(mouseEvent:MouseEvent):void {
			altKey = mouseEvent.altKey;
			ctrlKey = mouseEvent.ctrlKey;
			shiftKey = mouseEvent.shiftKey;
			var targetCanvas:Canvas = defineTargetCanvas();
			if (targetCanvas != null) {
				dispatchEventToCanvasHierarchy(MouseEvent3D.MOUSE_UP, targetCanvas);
				if (pressedObject == targetCanvas.interactiveObject) {
					clickedObject = targetCanvas.interactiveObject;
					dispatchEventToCanvasHierarchy(MouseEvent3D.CLICK, targetCanvas);
				}
			}
			pressedObject = null;
		}
	
		private function onDoubleClick(mouseEvent:MouseEvent):void {
			altKey = mouseEvent.altKey;
			ctrlKey = mouseEvent.ctrlKey;
			shiftKey = mouseEvent.shiftKey;
			var targetCanvas:Canvas = defineTargetCanvas();
			if (targetCanvas != null) {
				dispatchEventToCanvasHierarchy(MouseEvent3D.MOUSE_UP, targetCanvas);
				if (pressedObject == targetCanvas.interactiveObject) {
					dispatchEventToCanvasHierarchy(clickedObject == targetCanvas.interactiveObject && targetCanvas.interactiveObject.doubleClickEnabled ? MouseEvent3D.DOUBLE_CLICK : MouseEvent3D.CLICK, targetCanvas);
				}
			}
			clickedObject = null;
			pressedObject = null;
		}
	
		alternativa3d function onMouseMove(mouseEvent:MouseEvent = null):void {
			if (mouseEvent != null) {
				altKey = mouseEvent.altKey;
				ctrlKey = mouseEvent.ctrlKey;
				shiftKey = mouseEvent.shiftKey;
			}
			var targetCanvas:Canvas = defineTargetCanvas();
			if (targetCanvas != null) {
				var i:int;
				var canvas:Canvas;
				var object:Object3D;
				if (overedObject != targetCanvas.interactiveObject) {
					if (overedObject != null) {
						var length:int = overedBranch.length;
						dispatchEventToObjectHierarchy(MouseEvent3D.MOUSE_OUT);
						for (i = 0; i < length; i++) {
							object = overedBranch[i];
							canvas = targetCanvas;
							while (canvas != this) {
								if (object == canvas.interactiveObject) break;
								canvas = Canvas(canvas.parent);
							}
							if (canvas == this) {
								dispatchEvent3D(object, MouseEvent3D.ROLL_OUT, object);
							}
						}
						canvas = targetCanvas;
						while (canvas != this) {
							object = canvas.interactiveObject;
							for (i = 0; i < length; i++) {
								if (object == overedBranch[i]) break;
							}
							if (i == length) {
								dispatchEvent3D(object, MouseEvent3D.ROLL_OVER, object);
							}
							canvas = Canvas(canvas.parent);
						}
					} else {
						dispatchEventToCanvasHierarchy(MouseEvent3D.ROLL_OVER, targetCanvas);
					}
					dispatchEventToCanvasHierarchy(MouseEvent3D.MOUSE_OVER, targetCanvas);
				}
				if (mouseEvent != null) {
					dispatchEventToCanvasHierarchy(MouseEvent3D.MOUSE_MOVE, targetCanvas);
				}
				i = 0;
				canvas = targetCanvas;
				while (canvas != this) {
					overedBranch[i] = canvas.interactiveObject;
					i++;
					canvas = Canvas(canvas.parent);
				}
				overedObject = targetCanvas.interactiveObject;
				overedBranch.length = i;
			} else if (overedObject != null) {
				dispatchEventToObjectHierarchy(MouseEvent3D.MOUSE_OUT);
				dispatchEventToObjectHierarchy(MouseEvent3D.ROLL_OUT);
				overedObject = null;
				overedBranch.length = 0;
			}
		}
	
		private function onMouseWheel(mouseEvent:MouseEvent):void {
			altKey = mouseEvent.altKey;
			ctrlKey = mouseEvent.ctrlKey;
			shiftKey = mouseEvent.shiftKey;
			var targetCanvas:Canvas = defineTargetCanvas();
			if (targetCanvas != null) {
				dispatchEventToCanvasHierarchy(MouseEvent3D.MOUSE_WHEEL, targetCanvas, mouseEvent.delta);
			}
		}
	
		private function dispatchEventToCanvasHierarchy(type:String, canvas:Canvas, delta:int = 0):void {
			var target:Object3D = canvas.interactiveObject;
			while (canvas != this) {
				dispatchEvent3D(canvas.interactiveObject, type, target, delta);
				canvas = Canvas(canvas.parent);
			}
		}
	
		private function dispatchEventToObjectHierarchy(type:String, delta:int = 0):void {
			var target:Object3D = overedBranch[0];
			var length:int = overedBranch.length;
			for (var i:int = 0; i < length; i++) {
				dispatchEvent3D(overedBranch[i], type, target, delta);
			}
		}
	
		private function dispatchEvent3D(object:Object3D, type:String, target:Object3D, delta:int = 0):void {
			if (object.listeners != null) {
				var vector:Vector.<Function> = object.listeners[type];
				if (vector != null) {
					var i:int;
					var length:int = vector.length;
					for (i = 0; i < length; i++) {
						listeners[i] = vector[i];
					}
					for (i = 0; i < length; i++) {
						(listeners[i] as Function).call(null, new MouseEvent3D(type, target, altKey, ctrlKey, shiftKey, delta));
					}
				}
			}
		}
	
		private function defineTargetCanvas():Canvas {
			// Если мышь внутри области вьюпорта
			if (mouseX >= 0 && mouseY >= 0 && mouseX <= _width && mouseY <= _height) {
				// Получение объектов под мышью
				mouse.x = stage.mouseX;
				mouse.y = stage.mouseY;
				var displayObjects:Array = stage.getObjectsUnderPoint(mouse);
				// Перебор объектов
				for (var i:int = displayObjects.length - 1; i >= 0; i--) {
					var displayObject:DisplayObject = displayObjects[i];
					// Поиск канваса
					while (displayObject != null && !(displayObject is Canvas)) {
						displayObject = displayObject.parent;
					}
					// Если канвас найден
					if (displayObject != null) {
						var canvas:Canvas = Canvas(displayObject);
						// Проверка на прозрачность
						if (canvas.interactiveObject.interactiveAlpha <= 1) {
							// TODO: проверка порога альфы if (canvas.interactiveObject.interactiveAlpha > 0)
							// Определение целевого объекта
							var target:Canvas = null;
							while (canvas != this) {
								if (!canvas.interactiveObject.mouseChildren) {
									target = null;
								}
								if (target == null && canvas.interactiveObject.mouseEnabled) {
									target = canvas;
								}
								canvas = Canvas(canvas.parent);
							}
							if (target != null) {
								return target;
							}
						}
					} else {
						// TODO: тут должна быть проверка на интерактивность, чтобы понять перекрывает что-то вьюпорт или нет
					}
				}
			}
			return null;
		}
	
		private function onKey(keyboardEvent:KeyboardEvent):void {
			altKey = keyboardEvent.altKey;
			ctrlKey = keyboardEvent.ctrlKey;
			shiftKey = keyboardEvent.shiftKey;
		}
	
		override public function get width():Number {
			return _width;
		}
	
		override public function set width(value:Number):void {
			_width = value;
		}
	
		override public function get height():Number {
			return _height;
		}
	
		override public function set height(value:Number):void {
			_height = value;
		}
	
		public function clear():void {
			removeChildren(0);
			numDraws = 0;
		}
	
		override alternativa3d function getChildCanvas(interactiveObject:Object3D, useGraphics:Boolean, useChildren:Boolean, alpha:Number = 1, blendMode:String = "normal", colorTransform:ColorTransform = null, filters:Array = null):Canvas {
			var canvas:Canvas = super.getChildCanvas(interactiveObject, useGraphics, useChildren, alpha, blendMode, colorTransform, filters);
			canvas.x = _width/2;
			canvas.y = _height/2;
			return canvas;
		}
	
		override alternativa3d function removeChildren(keep:int):void {
			for (var i:int = 0; i < _numChildren - keep; i++) {
				var canvas:Canvas = getChildAt(i) as Canvas;
				if (canvas != null) {
					canvas.x = 0;
					canvas.y = 0;
				}
			}
			super.removeChildren(keep);
		}
	
	}
}