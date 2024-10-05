package alternativa.engine3d.core {
	import __AS3__.vec.Vector;
	
	import alternativa.Alternativa3D;
	import alternativa.engine3d.alternativa3d;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.display.StageAlign;
	import flash.display.Bitmap;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	
	use namespace alternativa3d;
	
	/**
	 * Вьюпорт, в который камера отрисовывает графику.
	 * <code>View</code> — это <code>DisplayObject</code>.
	 * @see alternativa.engine3d.core.Camera3D
	 */
	public class View extends Canvas {
	
		static private const mouse:Point = new Point();
		static private const branch:Vector.<Object3D> = new Vector.<Object3D>();
		static private const overedBranch:Vector.<Object3D> = new Vector.<Object3D>();
		static private const changedBranch:Vector.<Object3D> = new Vector.<Object3D>();
		static private const functions:Vector.<Function> = new Vector.<Function>();
	
		/**
		 * @private 
		 */
		alternativa3d var camera:Camera3D;
		
		/**
		 * @private 
		 */
		alternativa3d var _width:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var _height:Number;
	
		/**
		 * @private 
		 */
		alternativa3d var _interactive:Boolean = false;
	
		private var target:Object3D;
		private var pressedTarget:Object3D;
		private var clickedTarget:Object3D;
		private var overedTarget:Object3D;
	
		private var altKey:Boolean;
		private var ctrlKey:Boolean;
		private var shiftKey:Boolean;
		private var delta:int;
		private var buttonDown:Boolean;
		
		private var logo:Logo;
		private var border:Number = 5;
		private var _logoAlign:String = "BR";
		private var _logoHorizontalMargin:Number = border;
		private var _logoVerticalMargin:Number = border;
		
		private var bitmap:Bitmap;
		
		/**
		 * Создаёт новый вьюпорт.
		 * @param width Ширина вьюпорта.
		 * @param height Высота вьюпорта.
		 * @param interactive Флаг интерактивности.
		 * @see #interactive
		 */
		public function View(width:Number, height:Number, interactive:Boolean = false) {
			_width = width;
			_height = height;
			_interactive = interactive;
			
			mouseChildren = false;
			tabChildren = false;
			
			mouseEnabled = true;
			tabEnabled = false;
			
			var item:ContextMenuItem = new ContextMenuItem("Powered by Alternativa3D " + Alternativa3D.version);
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onItemSelect);
			
			var menu:ContextMenu = new ContextMenu();
			//menu.hideBuiltInItems();
			menu.customItems = [item];
			contextMenu = menu;
			
			showLogo();
			
			addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage);
		}
		
		private function onItemSelect(e:ContextMenuEvent):void {
			try {
				navigateToURL(new URLRequest("http://alternativaplatform.com"), "_blank");
			} catch (e:Error) {}
		}
		
		public function showLogo():void {
			if (logo == null) {
				logo = new Logo();
				super.addChild(logo);
				resizeLogo();
			}
		}
		
		public function hideLogo():void {
			if (logo != null) {
				super.removeChild(logo);
				logo = null;
			}
		}
		
		/**
		 * Выравнивание логотипа относительно области вьюпорта.
		 * Можно использовать константы класса <code>StageAlign</code>.
		 */
		public function get logoAlign():String {
			return _logoAlign;
		}
	
		/**
		 * @private
		 */
		public function set logoAlign(value:String):void {
			_logoAlign = value;
			resizeLogo();
		}
	
		/**
		 * Отступ логотипа от края вьюпорта по горизонтали.
		 */
		public function get logoHorizontalMargin():Number {
			return _logoHorizontalMargin;
		}
	
		/**
		 * @private
		 */
		public function set logoHorizontalMargin(value:Number):void {
			_logoHorizontalMargin = value;
			resizeLogo();
		}
	
		/**
		 * Отступ логотипа от края вьюпорта по вертикали.
		 */
		public function get logoVerticalMargin():Number {
			return _logoVerticalMargin;
		}
	
		/**
		 * @private
		 */
		public function set logoVerticalMargin(value:Number):void {
			_logoVerticalMargin = value;
			resizeLogo();
		}
		
		private function resizeLogo():void {
			if (logo != null) {
				if (_logoAlign == StageAlign.TOP_LEFT || _logoAlign == StageAlign.LEFT || _logoAlign == StageAlign.BOTTOM_LEFT) {
					logo.x = Math.round(_logoHorizontalMargin);
				}
				if (_logoAlign == StageAlign.TOP || _logoAlign == StageAlign.BOTTOM) {
					logo.x = Math.round((_width - logo.width)/2);
				}
				if (_logoAlign == StageAlign.TOP_RIGHT || _logoAlign == StageAlign.RIGHT || _logoAlign == StageAlign.BOTTOM_RIGHT) {
					logo.x = Math.round(_width - _logoHorizontalMargin - logo.width);
				}
				if (_logoAlign == StageAlign.TOP_LEFT || _logoAlign == StageAlign.TOP || _logoAlign == StageAlign.TOP_RIGHT) {
					logo.y = Math.round(_logoVerticalMargin);
				}
				if (_logoAlign == StageAlign.LEFT || _logoAlign == StageAlign.RIGHT) {
					logo.y = Math.round((_height - logo.height)/2);
				}
				if (_logoAlign == StageAlign.BOTTOM_LEFT || _logoAlign == StageAlign.BOTTOM || _logoAlign == StageAlign.BOTTOM_RIGHT) {
					logo.y = Math.round(_height - _logoVerticalMargin - logo.height);
				}
			}
		}
		
		/**
		 * Флаг интерактивности.
		 * Только при значении <code>true</code> будут обрабатываться трёхмерные события мыши.
		 * Значение по умолчанию <code>false</code>.
		 */
		public function get interactive():Boolean {
			return _interactive;
		}
	
		/**
		 * @private
		 */
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
		
		/**
		 * Очищает отрисованную графику.
		 */
		public function clear():void {
			removeChildren(0);
			numDraws = 0;
		}
		
		private function onAddToStage(e:Event):void {
			if (_interactive) addListeners();
		}
	
		private function onRemoveFromStage(e:Event):void {
			if (_interactive) removeListeners();
		}
		
		private function addListeners():void {
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.CLICK, onClick);
			stage.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
	
		private function removeListeners():void {
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.removeEventListener(MouseEvent.CLICK, onClick);
			stage.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			pressedTarget = null;
			clickedTarget = null;
			overedTarget = null;
		}
	
		private function onMouseDown(mouseEvent:MouseEvent):void {
			onMouse(mouseEvent);
			defineTarget();
			if (target != null) {
				propagateEvent(MouseEvent3D.MOUSE_DOWN, target, branchToVector(target, branch));
			}
			pressedTarget = target;
			target = null;
		}
	
		private function onMouseWheel(mouseEvent:MouseEvent):void {
			onMouse(mouseEvent);
			defineTarget();
			if (target != null) {
				propagateEvent(MouseEvent3D.MOUSE_WHEEL, target, branchToVector(target, branch));
			}
			target = null;
		}
		
		private function onClick(mouseEvent:MouseEvent):void {
			onMouse(mouseEvent);
			defineTarget();
			if (target != null) {
				propagateEvent(MouseEvent3D.MOUSE_UP, target, branchToVector(target, branch));
				if (pressedTarget == target) {
					clickedTarget = target;
					propagateEvent(MouseEvent3D.CLICK, target, branchToVector(target, branch));
				}
			}
			pressedTarget = null;
			target = null;
		}
	
		private function onDoubleClick(mouseEvent:MouseEvent):void {
			onMouse(mouseEvent);
			defineTarget();
			if (target != null) {
				propagateEvent(MouseEvent3D.MOUSE_UP, target, branchToVector(target, branch));
				if (pressedTarget == target) {
					propagateEvent(clickedTarget == target && target.doubleClickEnabled ? MouseEvent3D.DOUBLE_CLICK : MouseEvent3D.CLICK, target, branchToVector(target, branch));
				}
			}
			clickedTarget = null;
			pressedTarget = null;
			target = null;
		}
	
		/**
		 * @private 
		 */
		alternativa3d function onMouseMove(mouseEvent:MouseEvent = null):void {
			if (mouseEvent != null) onMouse(mouseEvent);
			defineTarget();
			if (mouseEvent != null && target != null) {
				propagateEvent(MouseEvent3D.MOUSE_MOVE, target, branchToVector(target, branch));
			}
			if (overedTarget != target) {
				branchToVector(target, branch);
				branchToVector(overedTarget, overedBranch);
				var branchLength:int = branch.length;
				var overedBranchLength:int = overedBranch.length;
				var changedBranchLength:int;
				var i:int;
				var j:int;
				var object:Object3D;
				if (overedTarget != null) {
					propagateEvent(MouseEvent3D.MOUSE_OUT, overedTarget, overedBranch, true, target);
					changedBranchLength = 0;
					for (i = 0; i < overedBranchLength; i++) {
						object = overedBranch[i];
						for (j = 0; j < branchLength; j++) if (object == branch[j]) break;
						if (j == branchLength) {
							changedBranch[changedBranchLength] = object;
							changedBranchLength++;
						}
					}
					if (changedBranchLength > 0) {
						changedBranch.length = changedBranchLength;
						propagateEvent(MouseEvent3D.ROLL_OUT, overedTarget, changedBranch, false, target);
					}
				}
				if (target != null) {
					changedBranchLength = 0;
					for (i = 0; i < branchLength; i++) {
						object = branch[i];
						for (j = 0; j < overedBranchLength; j++) if (object == overedBranch[j]) break;
						if (j == overedBranchLength) {
							changedBranch[changedBranchLength] = object;
							changedBranchLength++;
						}
					}
					if (changedBranchLength > 0) {
						changedBranch.length = changedBranchLength;
						propagateEvent(MouseEvent3D.ROLL_OVER, target, changedBranch, false, overedTarget);
					}
					propagateEvent(MouseEvent3D.MOUSE_OVER, target, branch, true, overedTarget);
				}
				overedTarget = target;
			}
			target = null;
		}
		
		private function branchToVector(object:Object3D, vector:Vector.<Object3D>):Vector.<Object3D> {
			var len:int = 0;
			while (object != null) {
				vector[len] = object;
				len++;
				object = object._parent;
			}
			vector.length = len;
			return vector;
		}
		
		private function propagateEvent(type:String, target:Object3D, objects:Vector.<Object3D>, bubbles:Boolean = true, relatedObject:Object3D = null):void {
			var oblectsLength:int = objects.length;
			var object:Object3D;
			var vector:Vector.<Function>;
			var length:int;
			var i:int;
			var j:int;
			var mouseEvent3D:MouseEvent3D;
			// Capture
			for (i = oblectsLength - 1; i > 0; i--) {
				object = objects[i];
				if (object.captureListeners != null) {
					vector = object.captureListeners[type];
					if (vector != null) {
						if (mouseEvent3D == null) {
							mouseEvent3D = new MouseEvent3D(type, bubbles, relatedObject, altKey, ctrlKey, shiftKey, buttonDown, delta);
							mouseEvent3D._target = target;
							mouseEvent3D.calculateLocalRay(mouseX, mouseY, target, camera);
						}
						mouseEvent3D._currentTarget = object;
						mouseEvent3D._eventPhase = 1;
						length = vector.length;
						for (j = 0; j < length; j++) functions[j] = vector[j];
						for (j = 0; j < length; j++) {
							(functions[j] as Function).call(null, mouseEvent3D);
							if (mouseEvent3D.stopImmediate) return;
						}
						if (mouseEvent3D.stop) return;
					}
				}
			}
			// Bubble
			for (i = 0; i < oblectsLength; i++) {
				object = objects[i];
				if (object.bubbleListeners != null) {
					vector = object.bubbleListeners[type];
					if (vector != null) {
						if (mouseEvent3D == null) {
							mouseEvent3D = new MouseEvent3D(type, bubbles, relatedObject, altKey, ctrlKey, shiftKey, buttonDown, delta);
							mouseEvent3D._target = target;
							mouseEvent3D.calculateLocalRay(mouseX, mouseY, target, camera);
						}
						mouseEvent3D._currentTarget = object;
						mouseEvent3D._eventPhase = (i == 0) ? 2 : 3;
						length = vector.length;
						for (j = 0; j < length; j++) functions[j] = vector[j];
						for (j = 0; j < length; j++) {
							(functions[j] as Function).call(null, mouseEvent3D);
							if (mouseEvent3D.stopImmediate) return;
						}
						if (mouseEvent3D.stop) return;
					}
				}
			}
		}
		
		private function defineTarget():void {
			// Если мышь внутри области вьюпорта
			if (mouseX >= 0 && mouseY >= 0 && mouseX <= _width && mouseY <= _height) {
				var source:Object3D;
				var object:Object3D;
				// Получение объектов под мышью
				mouse.x = stage.mouseX;
				mouse.y = stage.mouseY;
				var displayObjects:Array = stage.getObjectsUnderPoint(mouse);
				// Перебор объектов
				for (var i:int = displayObjects.length - 1; i >= 0; i--) {
					// Поиск канваса и проверка на интерактивный объект, перекрывающий вьюпорт
					var canvas:Canvas = null;
					var block:Boolean = false;
					for (var displayObject:DisplayObject = displayObjects[i]; displayObject.parent != stage; displayObject = displayObject.parent) {
						if (displayObject is Canvas) {
							canvas = Canvas(displayObject);
							break;
						}
						if ((displayObject is DisplayObjectContainer) && !(displayObject as DisplayObjectContainer).mouseChildren) {
							block = false;
						}
						if ((displayObject is InteractiveObject) && (displayObject as InteractiveObject).mouseEnabled) {
							block = true;
						}
					}
					if (block) break;
					// Если канвас найден
					if (canvas != null) {
						object = canvas.object;
						if (object != null/* && object.interactiveAlpha <= 1*/) {
							// TODO: проверка порога альфы
							//if (object.interactiveAlpha > 0)
							if (object != null) {
								var t:Object3D = null;
								var o:Object3D;
								// Получение потенциальной цели
								for (o = object; o != null; o = o._parent) {
									if ((o is Object3DContainer) && !Object3DContainer(o).mouseChildren) t = null;
									if (t == null && o.mouseEnabled) t = o;
								}
								// Если потенциальная цель найдена
								if (t != null) {
									if (target != null) {
										// Если ранее найденная цель встречается среди родителей потенциальной цели включаяя
										for (o = t; o != null; o = o._parent) {
											if (o == target) {
												source = object;
												target = t;
												break;
											}
										}
									} else {
										source = object;
										target = t;
									}
									if (source == target) break;
								}
							}
						}
					}
				}
			}
		}
		
		private function onMouse(mouseEvent:MouseEvent):void {
			altKey = mouseEvent.altKey;
			ctrlKey = mouseEvent.ctrlKey;
			shiftKey = mouseEvent.shiftKey;
			buttonDown = mouseEvent.buttonDown;
			delta = mouseEvent.delta;
		}
		
		private function onKeyDown(keyboardEvent:KeyboardEvent):void {
			altKey = keyboardEvent.altKey;
			ctrlKey = keyboardEvent.ctrlKey;
			shiftKey = keyboardEvent.shiftKey;
			if (ctrlKey && shiftKey && keyboardEvent.keyCode == Keyboard.F1 && bitmap == null) {
				bitmap = new Bitmap(Logo.image);
				bitmap.x = Math.round((_width - bitmap.width)/2);
				bitmap.y = Math.round((_height - bitmap.height)/2);
				super.addChild(bitmap);
				setTimeout(removeBitmap, 2048);
			}
		}
		
		private function removeBitmap():void {
			if (bitmap != null) {
				super.removeChild(bitmap);
				bitmap = null;
			}
		}
		
		private function onKeyUp(keyboardEvent:KeyboardEvent):void {
			altKey = keyboardEvent.altKey;
			ctrlKey = keyboardEvent.ctrlKey;
			shiftKey = keyboardEvent.shiftKey;
		}
	
		/**
		 * Ширина вьюпорта.
		 */
		override public function get width():Number {
			return _width;
		}
	
		/**
		 * @private 
		 */
		override public function set width(value:Number):void {
			_width = value;
			resizeLogo();
		}
	
		/**
		 * Высота вьюпорта.
		 */
		override public function get height():Number {
			return _height;
		}
	
		/**
		 * @private 
		 */
		override public function set height(value:Number):void {
			_height = value;
			resizeLogo();
		}
		
		/**
		 * @private 
		 */
		override public function addChild(child:DisplayObject):DisplayObject {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function removeChild(child:DisplayObject):DisplayObject {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function removeChildAt(index:int):DisplayObject {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function getChildAt(index:int):DisplayObject {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function getChildIndex(child:DisplayObject):int {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function setChildIndex(child:DisplayObject, index:int):void {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function swapChildren(child1:DisplayObject, child2:DisplayObject):void {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function swapChildrenAt(index1:int, index2:int):void {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function getChildByName(name:String):DisplayObject {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override public function contains(child:DisplayObject):Boolean {
			throw new Error("Unsupported operation.");
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function getChildCanvas(useGraphics:Boolean, useChildren:Boolean, object:Object3D = null, alpha:Number = 1, blendMode:String = "normal", colorTransform:ColorTransform = null, filters:Array = null):Canvas {
			var canvas:Canvas;
			var displayObject:DisplayObject;
			// Зачистка не канвасов
			while (_numChildren > numDraws && !((displayObject = super.getChildAt(_numChildren - 1 - numDraws)) is Canvas)) {
				super.removeChild(displayObject);
				_numChildren--;
			}
			// Получение канваса
			if (_numChildren > numDraws++) {
				canvas = displayObject as Canvas;
				// Зачистка
				if (canvas.modifiedGraphics) {
					canvas.gfx.clear();
				}
				if (canvas._numChildren > 0 && !useChildren) {
					canvas.removeChildren(0);
				}
			} else {
				canvas = (collectorLength > 0) ? collector[--collectorLength] : new Canvas();
				super.addChildAt(canvas, 0);
				_numChildren++;
			}
			// Сохранение интерактивного объекта
			canvas.object = object;
			// Пометка о том, что в graphics будет что-то нарисовано
			canvas.modifiedGraphics = useGraphics;
			// Установка свойств
			if (alpha != 1) {
				canvas.alpha = alpha;
				canvas.modifiedAlpha = true;
			} else if (canvas.modifiedAlpha) {
				canvas.alpha = 1;
				canvas.modifiedAlpha = false;
			}
			if (blendMode != "normal") {
				canvas.blendMode = blendMode;
				canvas.modifiedBlendMode = true;
			} else if (canvas.modifiedBlendMode) {
				canvas.blendMode = "normal";
				canvas.modifiedBlendMode = false;
			}
			if (colorTransform != null) {
				colorTransform.alphaMultiplier = alpha;
				canvas.transform.colorTransform = colorTransform;
				canvas.modifiedColorTransform = true;
			} else if (canvas.modifiedColorTransform) {
				defaultColorTransform.alphaMultiplier = alpha;
				canvas.transform.colorTransform = defaultColorTransform;
				canvas.modifiedColorTransform = false;
			}
			if (filters != null) {
				canvas.filters = filters;
				canvas.modifiedFilters = true;
			} else if (canvas.modifiedFilters) {
				canvas.filters = null;
				canvas.modifiedFilters = false;
			}
			canvas.x = _width/2;
			canvas.y = _height/2;
			return canvas;
		}
	
		/**
		 * @private 
		 */
		override alternativa3d function removeChildren(keep:int):void {
			for (var canvas:Canvas; _numChildren > keep; _numChildren--) {
				if ((canvas = super.removeChildAt(0) as Canvas) != null) {
					canvas.object = null;
					canvas.x = 0;
					canvas.y = 0;
					if (canvas.modifiedGraphics) canvas.gfx.clear();
					if (canvas._numChildren > 0) canvas.removeChildren(0);
					collector[collectorLength++] = canvas;
				}
			}
		}
		
	}
}

import flash.display.Shape;
import flash.display.Graphics;
import flash.display.BitmapData;
import alternativa.engine3d.core.View;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.display.Shader;
import flash.geom.Transform;
import flash.display.DisplayObject;
import flash.filters.GlowFilter;
import flash.filters.BitmapFilterQuality;
import flash.events.MouseEvent;
import flash.net.navigateToURL;
import flash.net.URLRequest;
import flash.accessibility.Accessibility;
import flash.accessibility.AccessibilityProperties;
import flash.geom.Point;
import flash.utils.getTimer;

class Logo extends Shape {
	
	static public const image:BitmapData = createBMP();
	static private function createBMP():BitmapData {
		var bmp:BitmapData = new BitmapData(103, 22, true, 0);
		bmp.setVector(bmp.rect, Vector.<uint>([
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,1040187392,2701131776,2499805184,738197504,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2516582400,4278190080,2516582400,0,0,0,0,2516582400,4278190080,2516582400,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,771751936,2533359616,4282199055,4288505883,4287716373,4280949511,2298478592,234881024,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4278190080,4294892416,4278190080,0,0,0,0,4278190080,4294892416,4278190080,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,1728053248,4279504646,4287917866,4294285341,4294478345,4294478346,4293626391,4285810708,4278387201,1291845632,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,2516582400,4278190080,4278190080,4278190080,2516582400,2516582400,4278190080,2516582400,2516582400,4278190080,2516582400,2516582400,4278190080,2516582400,2516582400,4278190080,4278190080,4278190080,2516582400,0,0,2516582400,4278190080,2516582400,2516582400,4278190080,4278190080,4278190080,2516582400,0,2516582400,4278190080,4278190080,4278190080,4294892416,4278190080,0,0,0,0,4278190080,4294892416,4278190080,4278190080,4278190080,2516582400,2516582400,4278190080,2516582400,0,2516582400,4278190080,2516582400,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,2197815296,4280753934,4291530288,4294412558,4294411013,4294411784,4294411784,4294411271,4294411790,4289816858,4279635461,1711276032,0,0,0,0,0,0,0,0,0,0,0,0,0,2516582400,4278190080,4294892416,4294892416,4294892416,4278190080,2516582400,4278190080,4294892416,4294892416,4294892416,4278190080,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4278190080,4294892416,4294892416,4294892416,4278190080,2516582400,2516582400,4278190080,4294892416,4278190080,4278190080,4294892416,4294892416,4294892416,4278190080,2516582400,4278190080,4294892416,4294892416,4294892416,4294892416,4278190080,0,0,0,0,4278190080,4294892416,4294892416,4294892416,4294892416,4278190080,4278190080,4294892416,4278190080,0,4278190080,4294892416,4278190080,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,2332033024,4283252258,4293301553,4294409478,4294409991,4294410761,4294476552,4294476296,4294410249,4294344200,4294343945,4291392799,4280752908,2030043136,0,0,0,0,0,0,0,0,0,0,0,0,4278190080,4294892416,4278190080,4278190080,4278190080,4294892416,4278190080,4294892416,4278190080,4278190080,4278190080,4294892416,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4294892416,4278190080,4278190080,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4278190080,4278190080,4294892416,4278190080,4294892416,4278190080,4278190080,4278190080,4278190080,2516582400,0,0,0,0,2516582400,4278190080,4278190080,4278190080,4278190080,4294892416,4278190080,4294892416,4278190080,0,4278190080,4294892416,4278190080,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,2281701376,4283186471,4293692972,4294276097,4294343176,4294409225,4294475017,4293554194,4293817874,4294408967,4294342921,4294342664,4294341895,4292640548,4281936662,2197815296,0,0,0,0,0,0,0,0,0,0,0,4278190080,4294892416,4278190080,0,4278190080,4294892416,4278190080,4294892416,4278190080,0,4278190080,4294892416,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4294892416,4278190080,4294892416,4294892416,4294892416,4278190080,4294892416,4278190080,2516582400,4278190080,4294892416,4278190080,4294892416,4294892416,4294892416,4278190080,4294892416,4278190080,0,4278190080,4294892416,4278190080,0,0,0,0,4278190080,4294892416,4278190080,0,4278190080,4294892416,4278190080,4294892416,4278190080,0,4278190080,4294892416,4278190080,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,2030043136,4282068512,4293561399,4294208769,4294210313,4294407689,4294210313,4290530057,4281734151,4282851341,4291913754,4294275848,4294275591,4294275592,4294208517,4293164329,4282133785,2080374784,0,0,0,0,0,0,0,0,0,0,2516582400,4278190080,4278190080,4278190080,4278190080,4294892416,4278190080,4294892416,4278190080,4278190080,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4278190080,4294892416,4278190080,4294892416,4278190080,4294892416,4278190080,4278190080,4278190080,4278190080,4278190080,4294892416,4278190080,0,4278190080,4294892416,4278190080,4278190080,4278190080,4278190080,4278190080,4294892416,4278190080,4278190080,4278190080,4294892416,4278190080,0,0,0,0,4278190080,4294892416,4278190080,4278190080,4278190080,4294892416,4278190080,4294892416,4278190080,4278190080,4278190080,4278190080,2516582400,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,1627389952,4280293393,4292577349,4294272769,4294208264,4294471177,4293617417,4286918406,4279502337,1912602624,2030043136,4280422919,4289945382,4294009867,4293875462,4293743369,4293610244,4292440624,4280950288,1761607680,0,0,0,0,0,0,0,0,0,4278190080,4294892416,4294892416,4294892416,4294892416,4278190080,2516582400,4278190080,4294892416,4294892416,4294892416,4278190080,2516582400,2516582400,4278190080,4294892416,4278190080,4278190080,4294892416,4294892416,4278190080,4278190080,4294892416,4294892416,4294892416,4278190080,4278190080,4294892416,4278190080,0,2516582400,4278190080,4294892416,4294892416,4294892416,4278190080,2516582400,4278190080,4294892416,4294892416,4294892416,4278190080,2516582400,0,0,0,0,2516582400,4278190080,4294892416,4294892416,4294892416,4278190080,2516582400,4278190080,4294892416,4294892416,4294892416,4294892416,4278190080,0,0,0,0,0,0,0,0,
		0,0,0,0,0,788529152,4279044359,4291067728,4294075141,4294075143,4294338057,4293352968,4284490243,4278321408,1291845632,0,0,1476395008,4278781187,4288236848,4293610511,4293609221,4293610249,4293609989,4291261239,4279241478,1291845632,0,0,0,0,0,0,0,0,4278190080,4294892416,4278190080,4278190080,4278190080,2516582400,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,0,2516582400,4278190080,2516582400,2516582400,4278190080,4278190080,2516582400,2516582400,4278190080,4278190080,4278190080,2516582400,2516582400,4278190080,2516582400,0,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,0,0,0,0,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,2516582400,4278190080,4278190080,4278190080,4294892416,4278190080,0,0,0,0,0,0,0,0,
		0,0,0,0,0,2550136832,4287849288,4294009360,4293941509,4294007817,4293679113,4284620803,2852126720,822083584,0,0,0,0,989855744,2751463424,4288172857,4293610511,4293543429,4293543943,4293611019,4289621050,4278649858,620756992,0,0,0,0,0,0,0,4278190080,4294892416,4278190080,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4278190080,4294892416,4294892416,4294892416,4278190080,2516582400,0,0,0,0,0,0,0,0,
		0,0,0,0,2030043136,4283380775,4294011945,4293873409,4293939977,4293808649,4285867012,4278649344,1090519040,0,0,0,0,0,0,939524096,4278255872,4288764223,4293609227,4293543175,4293542917,4293677843,4287124784,2516582400,0,0,0,0,0,0,0,2516582400,4278190080,2516582400,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,0,0,0,0,0,0,0,0,
		0,0,0,805306368,4279569674,4292243009,4293609217,4293676041,4293937929,4288687621,4279305216,1543503872,0,0,0,0,0,0,0,452984832,2214592512,4278781188,4290602054,4293410821,4293477384,4293476868,4293745950,4283773466,2181038080,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,2566914048,4287714107,4293543949,4293542919,4293673225,4291834377,4280879106,2080374784,0,0,0,0,0,0,0,1962934272,4279898124,4286467380,4278846980,4280686612,4292961598,4293343745,4293411081,4293476100,4292566822,4280357128,1140850688,0,0,0,0,0,0,0,0,0,0,0,0,0,2516582400,4278190080,2516582400,2516582400,4278190080,2516582400,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2516582400,4278190080,2516582400,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,0,0,0,2516582400,4278190080,2516582400,
		0,0,1207959552,4281539862,4293417771,4293343234,4293277193,4292947466,4284880134,2483027968,0,0,0,0,0,0,989855744,2751463424,4282917657,4291648314,4293346067,4288303409,2734686208,4284299053,4293479197,4293343493,4293409801,4293410569,4288759582,2902458368,0,0,0,0,0,0,0,0,0,0,0,0,0,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4278190080,4294967295,4278190080,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4278190080,4293141248,4293141248,4293141248,4278190080,2516582400,0,0,0,4278190080,4293141248,4278190080,
		0,0,2969567232,4289023795,4293211656,4293144328,4293143305,4290389514,4279108353,536870912,0,0,0,335544320,1543503872,2986344448,4281076999,4287967257,4293213977,4293078532,4293078275,4293412634,4284428061,2986344448,4289023285,4293277192,4293343240,4293277191,4293412372,4282850829,1711276032,0,0,0,0,0,0,0,2516582400,4278190080,2516582400,0,0,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,2516582400,4278190080,4278190080,4278190080,2516582400,0,0,2516582400,4278190080,2516582400,4278190080,4278190080,4278190080,4278190080,2516582400,0,0,0,2516582400,4278190080,2516582400,0,2516582400,4278190080,4294967295,4278190080,4278190080,2516582400,4278190080,2516582400,0,0,0,2516582400,4278190080,2516582400,0,2516582400,4278190080,2516582400,0,0,2516582400,4278190080,4278190080,4278190080,4293141248,4278190080,2516582400,4278190080,4278190080,4278190080,4293141248,4278190080,
		0,956301312,4281604366,4293149982,4293077253,4293078025,4292684810,4282912516,1979711488,1660944384,1778384896,2130706432,3204448256,4279371011,4283635982,4288752661,4292621844,4293078537,4293078022,4293078537,4293210121,4293144583,4290726433,4278518273,4280422668,4292691489,4293210117,4293276937,4293276680,4290592536,4278649601,134217728,0,0,0,0,0,2516582400,4278190080,4294967295,4278190080,2516582400,0,4278190080,4294967295,4278190080,4294967295,4294967295,4278190080,4278190080,4294967295,4294967295,4294967295,4278190080,2516582400,2516582400,4278190080,4294967295,4278190080,4294967295,4294967295,4294967295,4294967295,4278190080,2516582400,0,2516582400,4278190080,4294967295,4278190080,2516582400,4278190080,4294967295,4294967295,4278190080,4294967295,4278190080,4294967295,4278190080,0,0,0,4278190080,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,2516582400,0,0,4278190080,4293141248,4293141248,4278190080,2516582400,4278190080,4293141248,4293141248,4293141248,4293141248,4278190080,
		0,2717908992,4287903514,4293078538,4293078280,4293143817,4290652684,4281666563,4281797635,4283831561,4284292110,4285670934,4289475868,4291769878,4293079566,4293078281,4293078023,4293078280,4293209609,4293275145,4292357130,4287900432,4280290309,1728053248,2432696320,4286854178,4293145355,4293144584,4293144328,4293212431,4283636492,1610612736,0,0,0,0,2516582400,4278190080,4294967295,4278190080,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4294967295,4278190080,4278190080,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4278190080,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,4294967295,4278190080,4294967295,4278190080,2516582400,0,2516582400,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4294967295,4278190080,2516582400,0,2516582400,4278190080,4278190080,4293141248,4278190080,4293141248,4278190080,4278190080,4278190080,4278190080,2516582400,
		520093696,4280027652,4292426772,4293078279,4293079049,4293144329,4292751115,4292555019,4292948491,4293079819,4293146126,4293211917,4293210888,4293145095,4293210632,4293144841,4293210633,4293275913,4292685578,4288618760,4282584324,2969567232,1207959552,0,671088640,4279896839,4292362526,4293078022,4293078793,4293078536,4290065172,4278780673,167772160,0,0,2516582400,4278190080,4294967295,4278190080,4278190080,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4294967295,4278190080,4294967295,4294967295,4294967295,4278190080,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,0,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4278190080,4294967295,4278190080,2516582400,0,0,4278190080,4293141248,4278190080,4293141248,4278190080,0,4278190080,4293141248,4278190080,
		1811939328,4284620297,4293211403,4293210888,4293211145,4293276937,4293277193,4293277961,4293344265,4293410056,4293344776,4293344776,4293345033,4293410569,4293475848,4293344265,4292819211,4289276169,4283437573,4278714880,1828716544,0,0,0,0,2516582400,4287181084,4293078538,4293078025,4293143560,4293211664,4283110665,1409286144,0,0,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4294967295,4278190080,4278190080,4278190080,4278190080,4278190080,4294967295,4278190080,0,4278190080,4294967295,4278190080,0,4278190080,4294967295,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4294967295,4278190080,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4278190080,4278190080,4278190080,4293141248,4278190080,4293141248,4278190080,4278190080,4278190080,4293141248,4278190080,
		3087007744,4289148172,4293345035,4293345034,4293411080,4293476870,4293477893,4293544453,4293611013,4293677063,4293677833,4293677833,4293612298,4293218572,4292102669,4287771145,4282651909,4278714880,1912602624,218103808,0,0,0,0,0,771751936,4280880904,4292621585,4293143048,4292685067,4290916111,4284160266,1811939328,0,0,4278190080,4294967295,4294967295,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,4278190080,4294967295,4278190080,4294967295,4278190080,4278190080,4294967295,4294967295,4294967295,4278190080,4278190080,4294967295,4278190080,0,4278190080,4294967295,4278190080,0,4278190080,4294967295,4278190080,4294967295,4294967295,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,4294967295,4278190080,4294967295,4278190080,0,2516582400,4278190080,4294967295,4278190080,2516582400,4278190080,4294967295,4294967295,4294967295,4278190080,2516582400,4278190080,4294967295,4278190080,4293141248,4293141248,4293141248,4278190080,2516582400,4278190080,4293141248,4293141248,4293141248,4278190080,2516582400,
		1325400064,4280618243,4284819723,4287709972,4289877530,4293028892,4293948702,4293883680,4293818144,4292045341,4289484568,4288433169,4286856717,4282916870,4279831042,3036676096,1526726656,184549376,0,0,0,0,0,0,0,0,3305111552,4289014285,4288159495,4283372037,4279370753,2164260864,50331648,0,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,2516582400,4278190080,2516582400,2516582400,4278190080,2516582400,4278190080,2516582400,2516582400,4278190080,4278190080,4278190080,2516582400,2516582400,4278190080,2516582400,0,2516582400,4278190080,2516582400,0,2516582400,4278190080,2516582400,4278190080,4278190080,4278190080,2516582400,0,2516582400,4278190080,2516582400,4278190080,2516582400,4278190080,2516582400,0,0,2516582400,4278190080,2516582400,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,2516582400,4278190080,2516582400,4278190080,4278190080,4278190080,2516582400,0,2516582400,4278190080,4278190080,4278190080,2516582400,0,
		0,671088640,1828716544,2600468480,3170893824,4026531840,4261412864,4261412864,4261412864,3808428032,3170893824,2969567232,2667577344,1526726656,553648128,0,0,0,0,0,0,0,0,0,0,0,1543503872,3305111552,3120562176,1811939328,385875968,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		]));
		return bmp;
	}
	
	private	var border:int = 5;
	private var over:Boolean = false;
	private var press:Boolean;
	
	public function Logo() {
		graphics.beginBitmapFill(image, null, false, true);
		graphics.drawRect(0, 0, image.width, image.height);
		
		addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage);
	}
	
	private function onAddToStage(e:Event):void {
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onClick);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave);
	}
	
	private function onRemoveFromStage(e:Event):void {
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.removeEventListener(MouseEvent.MOUSE_UP, onClick);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeave);
	}
	
	private function onMouseMove(e:MouseEvent):void {
		if (mouseX >= -border && mouseX <= image.width + border && mouseY >= -border && mouseY <= image.height + border) {
			if (!over) {
				filters = [new GlowFilter(0xFFFF88, 1, 1.2, 1.2, 3, BitmapFilterQuality.HIGH)];
			}
			over = true;
		} else {
			if (over) {
				filters = null;
			}
			over = false;
		}
	}
	
	private function onMouseLeave(e:Event):void {
		filters = null;
		over = false;
	}
	
	private function onMouseDown(e:MouseEvent):void {
		press = over;
	}
	
	private function onClick(e:MouseEvent):void {
		if (press && over) {
			try {
				navigateToURL(new URLRequest("http://alternativaplatform.com"), "_blank");
			} catch (e:Error) {}
		}
		press = false;
	}
	
}
