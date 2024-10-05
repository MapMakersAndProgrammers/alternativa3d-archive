package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.MipMap;
	import alternativa.engine3d.core.Object3D;

	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;	
	
	/**
	 * Анимированный спрайт. 
	 * Анимация осуществляется путём переключения изображений,
	 * хранящихся в списке textures
	 */
	public class AnimSprite extends Sprite3D {
		
		/**
		 * Список кадров изображений 
		 */
		public var textures:Vector.<BitmapData>;
		public var mipMaps:Vector.<MipMap>;
		/**
		 * Устанавливаемый кадр 
		 */
		public var frame:uint = 0;
		
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			if (mipMapping == 0) {
				texture = textures[frame];
			} else {
				mipMap = mipMaps[frame];
			}
			super.draw(camera, object, parentCanvas);
		}
		
		override alternativa3d function debug(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			if (mipMapping == 0) {
				texture = textures[frame];
			} else {
				mipMap = mipMaps[frame];
			}
			super.debug(camera, object, parentCanvas);
		}
		
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			if (mipMapping == 0) {
				texture = textures[frame];
			} else {
				mipMap = mipMaps[frame];
			}
			return super.getGeometry(camera, object);
		}
		
		override public function calculateBoundBox(matrix:Matrix3D = null, boundBox:BoundBox = null):BoundBox {
			if (mipMapping == 0) {
				texture = textures[frame];
			} else {
				mipMap = mipMaps[frame];
			}
			return super.calculateBoundBox(matrix, boundBox);
		}
		
	}
}
