package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.Matrix3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.HelperMaterial;
	import com.alternativagame.engine3d.object.light.Direct3D;
	import com.alternativagame.type.RGB;

	use namespace engine3d;
	
	public class DirectSkin extends HelperSkin {
		
		use namespace engine3d;
		
		public function DirectSkin(object:Direct3D) {
			super(object);
		}

		override engine3d function draw():void {
			super.draw();

			// Чистим
			gfx.graphics.clear();

			var material:HelperMaterial = HelperMaterial(this.material); 
			var direct:Direct3D = Direct3D(object);
			var color:RGB = (direct.color == null) ? new RGB() : direct.color.clone();
			color.limit();

			// Рисуем ромбик
			if (material.body) {
				with (gfx.graphics) {
					lineStyle(1, color.toInt());
					moveTo(-8, 0);
					lineTo(0, -8);
					lineTo(8, 0);
					lineTo(0, 8);
					lineTo(-8, 0);
				}
			}

			// Рисуем стрелку направления
			if (material.gizmo && direct.color != null) {
				with (gfx.graphics) {
					lineStyle(1, color.toInt(), 0.5);
					moveTo(0, 0);
					var x0:Number = direct.canvasVector.x*30;
					var y0:Number = -direct.canvasVector.z*30;
					lineTo(x0, y0);
					
					var ang:Number = Math.atan2(y0, x0);
					var x1:Number = Math.cos(ang + 2.5)*5 + x0;
					var y1:Number = Math.sin(ang + 2.5)*5 + y0;
					var x2:Number = Math.cos(ang - 2.5)*5 + x0;
					var y2:Number = Math.sin(ang - 2.5)*5 + y0;
					moveTo(x1, y1);
					lineTo(x0, y0);
					lineTo(x2, y2);
				}
			}

		}
	}
}