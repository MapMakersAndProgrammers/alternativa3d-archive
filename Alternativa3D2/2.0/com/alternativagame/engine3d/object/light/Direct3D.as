package com.alternativagame.engine3d.object.light {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.HelperMaterial;
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.skin.DirectSkin;
	import com.alternativagame.engine3d.skin.Skin;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;
	
	use namespace engine3d;

	public class Direct3D extends Light3D {

		use namespace engine3d;
		
		// Текущая нормаль освещения в пространстве камеры
		engine3d var canvasVector:Vector;
		
		public function Direct3D(color:RGB = null, material:HelperMaterial = null) {
			super(color, material);
		}

		// Обновиться после трансформации
		override protected function updateTransform():void {
			super.updateTransform();
			
			// Сохраняем нормаль
			canvasVector = new Vector(transform.b, transform.f, transform.j);
			Math3D.normalize(canvasVector);
		}
		
		override protected function createSkin():Skin {
			return new DirectSkin(this);
		}
		
		// Освещение в заданной точке
		override engine3d function getLightColor(coords:Vector, normal:Vector):RGB {
			return calculateLightColor(normal, canvasVector);
		}

		// Клон
		override public function clone():Object3D {
			var res:Direct3D = new Direct3D();
			cloneParams(res);
			return res;
		}

	}
}