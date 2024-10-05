package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.Matrix3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.HelperMaterial;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.object.light.Omni3D;
	import com.alternativagame.type.RGB;
	
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	use namespace engine3d;

	public class OmniSkin extends HelperSkin {
		
		use namespace engine3d;
		
		public function OmniSkin(object:Omni3D) {
			super(object);
		}

		override engine3d function draw():void {
			super.draw();

			// Чистим
			gfx.graphics.clear();

			var material:HelperMaterial = HelperMaterial(this.material); 
			var omni:Omni3D = Omni3D(object);
			var color:RGB = (omni.color == null) ? new RGB() : omni.color.clone();
			color.limit();
			
			// Рисуем звёздочку
			if (material.body) {
				with (gfx.graphics) {
					lineStyle(1, color.toInt());
					moveTo(-8, 0);
					lineTo(8, 0);
					moveTo(0, -8);
					lineTo(0, 8);
					moveTo(-6, -6);
					lineTo(6, 6);
					moveTo(6, -6);
					lineTo(-6, 6);
				}
			}
			
			// Рисуем границы
			if (material.gizmo && omni.color != null) {
				with (gfx.graphics) {
					lineStyle(1, color.toInt(), 0.5);
					drawCircle(0, 0, omni.canvasFar);
					drawCircle(0, 0, omni.canvasNear);
				}
			}

		}
	}
}