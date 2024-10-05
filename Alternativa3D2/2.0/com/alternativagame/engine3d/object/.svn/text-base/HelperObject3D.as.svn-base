package com.alternativagame.engine3d.object {
	import com.alternativagame.engine3d.material.HelperMaterial;
	
	public class HelperObject3D extends SkinObject3D {
		
		public function HelperObject3D(material:HelperMaterial = null) {
			super(material);
		}

		override public function set name(value:String):void {
			super.name = value;
			updateSkin();
		}
		
		// Клон
		override public function clone():Object3D {
			var res:HelperObject3D = new HelperObject3D();
			cloneParams(res);
			return res;
		}
	
	}
}