package com.alternativagame.engine3d.object.mesh.polygon {
	import com.alternativagame.engine3d.material.TextureMaterial;
	import com.alternativagame.engine3d.skin.TextureSkin;
	
	import flash.geom.Point;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;
	import flash.utils.Dictionary;
	import com.alternativagame.engine3d.skin.Skin;
	import com.alternativagame.engine3d.object.mesh.Point3D;
	
	public class TexturePolygon3D extends FillPolygon3D {
		
		// UV-координаты точек
		private var _aUV:Point;
		private var _bUV:Point;
		private var _cUV:Point;

		public function TexturePolygon3D(a:Point3D, b:Point3D, c:Point3D, material:TextureMaterial = null, aUV:Point = null, bUV:Point = null, cUV:Point = null) {
			super(a, b, c, material);
			_aUV = aUV;
			_bUV = bUV;
			_cUV = cUV;
		}

		override protected function createSkin():Skin {
			return new TextureSkin(this);
		}
		
		public function get aUV():Point {
			return _aUV;
		}

		public function get bUV():Point {
			return _bUV;
		}

		public function get cUV():Point {
			return _cUV;
		}

		public function set aUV(value:Point):void {
			_aUV = value;
			redrawSkin();
		}

		public function set bUV(value:Point):void {
			_bUV = value;
			redrawSkin();
		}

		public function set cUV(value:Point):void {
			_cUV = value;
			redrawSkin();
		}

		// Клон
		override public function clone(a:Point3D, b:Point3D, c:Point3D):Polygon3D {
			var res:TexturePolygon3D = new TexturePolygon3D(a, b, c);
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(object:*):void {
			var obj:TexturePolygon3D = TexturePolygon3D(object);
			super.cloneParams(obj);
			obj.aUV = aUV.clone();
			obj.bUV = bUV.clone();
			obj.cUV = cUV.clone();
		}

		
	}
}