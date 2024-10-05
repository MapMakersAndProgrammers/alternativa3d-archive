package com.alternativagame.engine3d.object {
	import com.alternativagame.engine3d.material.HelperMaterial;
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.engine3d.skin.DummySkin;
	import com.alternativagame.engine3d.skin.Skin;
	
	public class Dummy3D extends HelperObject3D {

		public function Dummy3D(material:HelperMaterial = null) {
			super(material);
		}

		override protected function createSkin():Skin {
			return new DummySkin(this); 
		}

		// Клон
		override public function clone():Object3D {
			var res:Dummy3D = new Dummy3D();
			cloneParams(res);
			return res;
		}
		
	}
}