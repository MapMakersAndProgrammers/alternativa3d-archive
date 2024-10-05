package com.alternativagame.engine3d.object.mesh.polygon {
	import com.alternativagame.engine3d.material.WireMaterial;
	import com.alternativagame.engine3d.skin.WireSkin;
	import com.alternativagame.engine3d.skin.Skin;
	import com.alternativagame.engine3d.object.mesh.Point3D;
	
	public class WirePolygon3D extends Polygon3D {
		
		// Флаги видимости граней
		private var _edgeAB:Boolean;
		private var _edgeBC:Boolean;
		private var _edgeCA:Boolean;
	
		public function WirePolygon3D(a:Point3D, b:Point3D, c:Point3D, material:WireMaterial = null, edgeAB:Boolean = true, edgeBC:Boolean = true, edgeCA:Boolean = true) {
			super(a, b, c, material);
			_edgeAB = edgeAB;
			_edgeBC = edgeBC;
			_edgeCA = edgeCA;
		}
		
		override protected function createSkin():Skin {
			return new WireSkin(this);
		}
		
		public function get edgeAB():Boolean {
			return _edgeAB;
		}

		public function get edgeBC():Boolean {
			return _edgeBC;
		}

		public function get edgeCA():Boolean {
			return _edgeCA;
		}

		public function set edgeAB(value:Boolean):void {
			_edgeAB = value;
			redrawSkin();
		}

		public function set edgeBC(value:Boolean):void {
			_edgeBC = value;
			redrawSkin();
		}

		public function set edgeCA(value:Boolean):void {
			_edgeCA = value;
			redrawSkin();
		}

		// Клон
		override public function clone(a:Point3D, b:Point3D, c:Point3D):Polygon3D {
			var res:WirePolygon3D = new WirePolygon3D(a, b, c);
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(object:*):void {
			var obj:WirePolygon3D = WirePolygon3D(object);
			super.cloneParams(obj);
			obj.edgeAB = edgeAB;
			obj.edgeBC = edgeBC;
			obj.edgeCA = edgeCA;
		}

		
		
	}
}