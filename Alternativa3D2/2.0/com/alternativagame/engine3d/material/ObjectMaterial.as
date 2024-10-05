package com.alternativagame.engine3d.material {
	public class ObjectMaterial extends Material {
		
		// Массив точек хит-области
		public var hit:Array = new Array();
		
		// Клон
		override public function clone():Material {
			var res:ObjectMaterial = new ObjectMaterial();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(material:*):void {
			var mat:ObjectMaterial = ObjectMaterial(material);
			super.cloneParams(mat);
			mat.hit = hit;
		}
		
	}
}