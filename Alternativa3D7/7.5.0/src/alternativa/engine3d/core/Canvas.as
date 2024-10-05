package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class Canvas extends Sprite {
	
		static alternativa3d const defaultColorTransform:ColorTransform = new ColorTransform();
		static alternativa3d const collector:Vector.<Canvas> = new Vector.<Canvas>();
		static alternativa3d var collectorLength:int = 0;
	
		alternativa3d var gfx:Graphics = graphics;
	
		alternativa3d var modifiedGraphics:Boolean;
		alternativa3d var modifiedAlpha:Boolean;
		alternativa3d var modifiedBlendMode:Boolean;
		alternativa3d var modifiedColorTransform:Boolean;
		alternativa3d var modifiedFilters:Boolean;
	
		alternativa3d var _numChildren:int = 0;
		alternativa3d var numDraws:int = 0;
	
		alternativa3d var object:Object3D;
	
		alternativa3d function getChildCanvas(useGraphics:Boolean, useChildren:Boolean, object:Object3D = null, alpha:Number = 1, blendMode:String = "normal", colorTransform:ColorTransform = null, filters:Array = null):Canvas {
			var canvas:Canvas;
			var displayObject:DisplayObject;
			// Зачистка не канвасов
			while (_numChildren > numDraws && !((displayObject = getChildAt(_numChildren - 1 - numDraws)) is Canvas)) {
				removeChild(displayObject);
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
				addChildAt(canvas, 0);
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
			return canvas;
		}
	
		alternativa3d function removeChildren(keep:int):void {
			for (var canvas:Canvas; _numChildren > keep; _numChildren--) {
				if ((canvas = removeChildAt(0) as Canvas) != null) {
					canvas.object = null;
					if (canvas.modifiedGraphics) canvas.gfx.clear();
					if (canvas._numChildren > 0) canvas.removeChildren(0);
					collector[collectorLength++] = canvas;
				}
			}
		}
	
	}
}
