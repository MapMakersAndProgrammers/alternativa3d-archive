package com.alternativagame.engine3d.material {
	import com.alternativagame.type.RGB;
	
	public class HelperMaterial extends ObjectMaterial {

		// Показывать подпись
		public var text:Boolean;
		
		// Цвет подписи
		public var textColor:RGB = new RGB(0xFFFFFF); 

		// Показывать связь с родителем
		public var link:Boolean;

		// Показывать тело объекта
		public var body:Boolean;

		// Показывать вспомогательную графику объекта
		public var gizmo:Boolean;

		// Цвет тела объекта
		public var bodyColor:RGB = new RGB(0xCCCCCC);
		

		public function HelperMaterial(text:Boolean = true, link:Boolean = true, gizmo:Boolean = true, body:Boolean = true) {
			this.text = text;
			this.link = link;
			this.gizmo = gizmo;
			this.body = body;
		}

		// Клон
		override public function clone():Material {
			var res:HelperMaterial = new HelperMaterial();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(material:*):void {
			var mat:HelperMaterial = HelperMaterial(material);
			super.cloneParams(mat);
			mat.text = text;
			mat.textColor = textColor.clone();
			mat.body = body;
			mat.gizmo = gizmo;
			mat.bodyColor = bodyColor.clone();
			mat.link = link;
		}

	}
}