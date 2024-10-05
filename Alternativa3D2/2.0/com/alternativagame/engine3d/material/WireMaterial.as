package com.alternativagame.engine3d.material {
	import com.alternativagame.type.RGB;
	
	public class WireMaterial extends PolygonMaterial {
		
		// Цвет рёбер
		public var color:RGB;

		// Толщина рёбер
		public var thickness:Number;

		public function WireMaterial(color:RGB = null, thickness:Number = 1, twoSided:Boolean = false) {
			this.color = (color == null) ? new RGB(0xFFFFFF) : color;
			this.thickness = thickness;
			this.twoSided = twoSided;
		} 

		// Клон
		override public function clone():Material {
			var res:WireMaterial = new WireMaterial();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(material:*):void {
			var mat:WireMaterial = WireMaterial(material);
			super.cloneParams(mat);
			mat.color = color.clone();
			mat.thickness = thickness;
		}

		
	}
}