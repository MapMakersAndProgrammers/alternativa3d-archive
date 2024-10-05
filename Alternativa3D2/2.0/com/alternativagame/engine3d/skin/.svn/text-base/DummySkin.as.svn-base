package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.Matrix3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.HelperMaterial;
	import com.alternativagame.engine3d.object.Dummy3D;
	import com.alternativagame.engine3d.object.Object3D;
	
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	use namespace engine3d;
	
	public class DummySkin extends HelperSkin {

		use namespace engine3d;
		
		public function DummySkin(object:Dummy3D) {
			super(object);
		}

		override engine3d function draw():void {
			super.draw();
			
			// Чистим
			gfx.graphics.clear();
			
			var material:HelperMaterial = HelperMaterial(this.material); 
			
			if (material.body) {
				// Рисуем точку
				with (gfx.graphics) {
					beginFill(material.bodyColor.toInt());
					drawCircle(0,0,3);
				}
			}
			
			// Рисуем оси
			if (material.gizmo) {

				var transform:Matrix3D = object.transform;
				
				// Координаты осей
				var xx:Number = transform.a*40;
				var xy:Number = -transform.i*40;
				var yx:Number = transform.b*40;
				var yy:Number = -transform.j*40;
				var zx:Number = transform.c*40;
				var zy:Number = -transform.k*40;
				
				with (gfx.graphics) {	
					moveTo(0,0);
					lineStyle(1, 0xFF0000);
					lineTo(xx, xy);
	
					moveTo(0,0);
					lineStyle(1, 0x00FF00);
					lineTo(yx, yy);
	
					moveTo(0,0);
					lineStyle(1, 0x0000FF);
					lineTo(zx, zy);
				}
			}
		
		}
	}
}