package com.alternativagame.engine3d.material {
	
	public class Material {

		// Прозрачность материала 
		public var alpha:Number = 1;
		
		// Метод наложения
		public var blendMode:String = "normal";
		
		// Смещение глубины
		public var depthOffset:Number = 0;
		
		// Клон
		public function clone():Material {
			var res:Material = new Material();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		protected function cloneParams(material:*):void {
			var mat:Material = Material(material);
			mat.alpha = alpha;
			mat.blendMode = blendMode;
			mat.depthOffset = depthOffset;
		}
		

	}
}