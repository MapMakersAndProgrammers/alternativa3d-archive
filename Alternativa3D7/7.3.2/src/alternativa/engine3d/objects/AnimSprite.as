package alternativa.engine3d.objects {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.Material;
	
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
		public var materials:Vector.<Material>;
		/**
		 * Устанавливаемый кадр
		 */
		public var frame:uint = 0;
	
		public function AnimSprite(width:Number = 100, height:Number = 100, materials:Vector.<Material> = null) {
			super(width, height);
			this.materials = materials;
		}
	
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			if (materials == null) return;
			material = materials[frame];
			super.draw(camera, object, parentCanvas);
		}
	
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			if (materials == null) return null;
			material = materials[frame];
			return super.getGeometry(camera, object);
		}
	
	}
}
