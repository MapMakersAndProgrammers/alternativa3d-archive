package com.alternativagame.engine3d.material {
	import com.alternativagame.type.RGB;
	
	public class FillMaterial extends PolygonMaterial {
		
		// Цвет при отсутствии текстуры
		public var color:RGB;

		// Цвет самосвечения материала
		public var selfIllumination:RGB = new RGB();

		public function FillMaterial(color:RGB = null, twoSided:Boolean = false) {
			this.color = (color == null) ? new RGB(0x7F7F7F) : color;
			this.twoSided = twoSided;
		} 

		// Клон
		override public function clone():Material {
			var res:FillMaterial = new FillMaterial();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(material:*):void {
			var mat:FillMaterial = FillMaterial(material);
			super.cloneParams(mat);
			mat.color = color.clone();
			mat.selfIllumination = selfIllumination.clone();
		}

	}
}