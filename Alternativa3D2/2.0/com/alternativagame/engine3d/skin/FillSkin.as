package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.FillMaterial;
	import com.alternativagame.engine3d.object.mesh.polygon.FillPolygon3D;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;
	
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	
	use namespace engine3d;

	public class FillSkin extends PolygonSkin {

		use namespace engine3d;
		
		public function FillSkin(polygon:FillPolygon3D) {
			super(polygon);
			// Изначально осветить
			light();
		}

		override protected function drawPolygon(bx:int, by:int, cx:int, cy:int):void {
			with (graphics) {
				clear();
				beginFill(FillMaterial(polygon.material).color.toInt());
				lineTo(bx, by);
				lineTo(cx, cy);
			}
		}
		
		override engine3d function light():void {
			var color:RGB = FillPolygon3D(polygon).lightColor.clone();

			// Добавить самосвечение
			var selfIllumination:RGB = FillMaterial(polygon.material).selfIllumination;
			color.add(selfIllumination);
			
			var redMultiplier:Number = (color.red/5 + color.red*0.6 + 30) / 127;
			var greenMultiplier:Number = (color.green/5 + color.green*0.6 + 30) / 127;
			var blueMultiplier:Number = (color.blue/5 + color.blue*0.6 + 30) / 127;
			var redOffset:Number = (color.red - 127) * 0.65;
			var greenOffset:Number = (color.green - 127) * 0.65;
			var blueOffset:Number = (color.blue - 127) * 0.65;
			
			transform.colorTransform = new ColorTransform(redMultiplier, greenMultiplier, blueMultiplier, alpha, redOffset, greenOffset, blueOffset);
		}
	}
}