package com.alternativagame.engine3d.object.light {
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;

	public class Ambient3D extends Light3D {

		use namespace engine3d;
		
		public function Ambient3D(color:RGB = null) {
			super(color);
		}
		
		// Освещение в заданной точке
		engine3d function getLightColor(coords:Vector, normal:Vector):RGB {
			return color;
		}

		// Клон
		override public function clone():Object3D {
			var res:Ambient3D = new Ambient3D();
			cloneParams(res);
			return res;
		}
		
	}
}