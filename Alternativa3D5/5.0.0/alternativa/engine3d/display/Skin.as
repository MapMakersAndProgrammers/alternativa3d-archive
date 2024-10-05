package alternativa.engine3d.display {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Operation;
	import alternativa.engine3d.core.PolyPrimitive;
	import alternativa.engine3d.materials.SurfaceMaterial;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class Skin extends Sprite {

		/**
		 * @private
		 * Графика скина (для быстрого доступа)
		 */
		alternativa3d var gfx:Graphics = graphics;

		/**
		 * @private
		 * Ссылка на следующий скин
		 */
		alternativa3d var nextSkin:Skin;
		
		/**
		 * @private
		 * Примитив
		 */
		alternativa3d var primitive:PolyPrimitive;

		/**
		 * @private
		 * Материал
		 */
		alternativa3d var material:SurfaceMaterial;
		
		// Хранилище неиспользуемых скинов
		static private var collector:Array = new Array();

		/**
		 * @private
		 * Создание скина.
		 */
		static alternativa3d function createSkin():Skin {
			// Достаём скин из коллектора
			var skin:Skin = collector.pop();
			// Если коллектор пуст, создаём новый скин
			if (skin == null) {
				skin = new Skin();
			}
			return skin;
		}

		/**
		 * @private
		 * Удаление скина, все ссылки должны быть почищены.
		 */
		static alternativa3d function destroySkin(skin:Skin):void {
			collector.push(skin);
		}
	}
}