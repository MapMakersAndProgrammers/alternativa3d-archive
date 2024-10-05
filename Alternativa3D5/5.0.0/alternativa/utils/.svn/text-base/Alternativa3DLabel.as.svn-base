package alternativa.utils {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	/**
	 * Графическая ссылка на сайт разработчиков 3D-движка.
	 */
	public class Alternativa3DLabel extends Sprite {
		
		[Embed(source="labelsmall.png")] private static const bmpLabelSmall:Class;
		[Embed(source="labelmedium.png")] private static const bmpLabelMedium:Class;
		[Embed(source="labelbig.png")] private static const bmpLabelBig:Class;
		private static const labelSmall:BitmapData = new bmpLabelSmall().bitmapData;
		private static const labelMedium:BitmapData = new bmpLabelMedium().bitmapData;
		private static const labelBig:BitmapData = new bmpLabelBig().bitmapData;
		
		/**
		 * Маленький размер изображения.
		 * Только текст.
		 */
		public static const SIZE_SMALL:String = "small";
		/**
		 * Средний размер изображения.
		 * Текст и логотип среднего размера.
		 */
		public static const SIZE_MEDIUM:String = "medium";
		/**
		 * Крупный размер изображения.
		 * Крупный текст и логотип крупного размера.
		 */
		public static const SIZE_BIG:String = "big";
		
		/**
		 * Создание экземпляра класса
		 * @param size размер изображения
		 * Может принимать значения Alternativa3DLabel.SIZE_SMALL, Alternativa3DLabel.SIZE_MEDIUM и Alternativa3DLabel.SIZE_BIG.
		 */
		public function Alternativa3DLabel(size:String = SIZE_MEDIUM) {
			super();
			
			buttonMode = true;
			//useHandCursor = true;
			
			// Проверки на null
			size = (size != null) ? size.toLowerCase() : SIZE_MEDIUM;
			
			// Контейнер
			var image:Bitmap = new Bitmap();
			
			// Установка изображения в зависимости от размера
			if (size == SIZE_SMALL) {
				image.bitmapData = labelSmall;
			} else {
				if (size == SIZE_BIG) {
					image.bitmapData = labelBig;
				} else {
					image.bitmapData = labelMedium;
				}
			}

			addChild(image);
			
			addEventListener(MouseEvent.CLICK, onClick);
		}
		
		private function onClick(e:MouseEvent):void {
			navigateToURL(new URLRequest("http://alternativaplatform.com"), "_blank");
		}
	}
}