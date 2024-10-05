package com.alternativagame.engine3d.material {
	import com.alternativagame.type.RGB;
	
	import flash.display.BitmapData;
	
	public final class TextureMaterial extends FillMaterial {

		// Текстура
		public var texture:BitmapData = null;

		// Сглаженность
		public var smoothing:Boolean;

		public function TextureMaterial(texture:BitmapData = null, smoothing:Boolean = true, color:RGB = null, twoSided:Boolean = false) {
			super(color, twoSided);
			this.texture = texture;
			this.smoothing = smoothing;
		}

		// Клон
		override public function clone():Material {
			var res:TextureMaterial = new TextureMaterial();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(material:*):void {
			var mat:TextureMaterial = TextureMaterial(material);
			super.cloneParams(mat);
			mat.texture = texture;
			mat.smoothing = smoothing;
		}

	}
}