package com.alternativagame.engine3d.material {
	public class PolygonMaterial extends Material {
		
		// Двусторонний материал
		public var twoSided:Boolean; 
		
		// Клон
		override public function clone():Material {
			var res:PolygonMaterial = new PolygonMaterial();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(material:*):void {
			var mat:PolygonMaterial = PolygonMaterial(material);
			super.cloneParams(mat);
			mat.twoSided = twoSided;
		}

		
	}
}