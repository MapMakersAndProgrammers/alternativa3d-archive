package com.alternativagame.engine3d.object {
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.engine3d.material.SpriteMaterial;
	import com.alternativagame.engine3d.skin.SpriteSkin;
	import flash.utils.Dictionary;
	import com.alternativagame.type.Vector;
	import com.alternativagame.type.RGB;
	import com.alternativagame.engine3d.skin.Skin;

	public class Sprite3D extends SkinObject3D {
		
		private var _state:String = "default";
		
		public function Sprite3D(material:SpriteMaterial = null) {
			super(material);
		}
		
		override protected function createSkin():Skin {
			return new SpriteSkin(this); 
		}
		
		public function set state(value:String):void {
			if (_state != value) {
				_state = value;
				updateSkin();
			}
		}
		
		public function get state():String {
			return _state;
		}
		
		// Клон
		override public function clone():Object3D {
			var res:Sprite3D = new Sprite3D();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(object:*):void {
			var obj:Sprite3D = Sprite3D(object);
			super.cloneParams(obj);
			obj.state = state;
		}
		
	}
}