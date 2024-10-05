package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.Matrix3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.HelperMaterial;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.object.SkinObject3D;
	import com.alternativagame.engine3d.object.light.Light3D;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	use namespace engine3d;

	public class HelperSkin extends ObjectSkin {

		use namespace engine3d;
		
		private var tf:TextField = null;
		private var link:Shape;
		protected var gfx:Shape;

		public function HelperSkin(object:SkinObject3D) {
			super(object);
			link = new Shape();
			addChild(link);
			gfx = new Shape();
			addChild(gfx);
		}
		
		override engine3d function position():void {
			super.position();
			drawLink();
		}
		
		override engine3d function draw():void {
			super.draw();

			var material:HelperMaterial = HelperMaterial(this.material);
			
			// Если в материале есть текст
			if (material.text) {
				// Создаём текстовое поле если надо
				if (tf == null) {
					tf = new TextField();
					var f:TextFormat = new TextFormat("Courier", 11);
					f.align = "center";
					tf.defaultTextFormat = f;
					
					tf.autoSize = TextFieldAutoSize.LEFT;
					tf.selectable = false;
					tf.mouseEnabled = false;
					addChild(tf);
				}
				// Обновляем данные текстового поля
				tf.text = object.name;
				tf.textColor = material.textColor.toInt();
				tf.x = -tf.width/2;
			} else {
				// Удаляем текстовое поле если оно не нужно
				if (tf != null) {
					removeChild(tf);
					tf = null;
				}
			}
			
			drawLink();
		}
	
		// Рисуем связь с родителем
		private function drawLink():void {
			link.graphics.clear();
			if (HelperMaterial(material).link && object.parent != null) {
				var px:Number = object.parent.transform.d - x;
				var py:Number = - object.parent.transform.l - y;
				with (link.graphics) {
					moveTo(0,0);
					lineStyle(1, 0xFFFFFF, 0.3);
					lineTo(px, py);
				} 
			}
		}
		
		override protected function drawDefaultHit():void {
			with (graphics) {
				drawCircle(0, 0, 3);
			}
		}
		
	}
}