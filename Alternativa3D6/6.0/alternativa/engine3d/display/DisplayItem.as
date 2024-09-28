package alternativa.engine3d.display {
	import alternativa.engine3d.*;
	
	import flash.display.Sprite;
	
	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class DisplayItem extends Sprite {
		/**
		 * @private
		 * Ссылка на следующий объект
		 */
		alternativa3d var next:DisplayItem;
	}
}