package alternativa.engine3d.display {
	import alternativa.engine3d.*;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.sorting.Primitive;
	
	import flash.display.Graphics;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 * Контейнер, используемый материалами для отрисовки примитивов.
	 * Каждый примитив BSP-дерева рисуется в своём контейнере.
	 */
	public class Skin extends DisplayItem {

		/**
		 * @private
		 * Графика скина (для быстрого доступа)
		 */
		alternativa3d var gfx:Graphics = graphics;

		/**
		 * @private
		 * Примитив
		 */
		//alternativa3d var primitive:Primitive;

		/**
		 * @private
		 * Материал, связанный со скином.
		 */
		alternativa3d var material:Material;
		
		// Хранилище неиспользуемых скинов
		static private var collector:Array = new Array();

		/**
		 * @private
		 * Создание скина.
		 */
		static alternativa3d function create():Skin {
			var skin:Skin;
			if ((skin = collector.pop()) == null) {
				// Если коллектор пуст, создаём новый скин
				return new Skin();
			}
			return skin;
		}

		/**
		 * @private
		 * Удаление скина.
		 */
		static alternativa3d function destroy(skin:Skin):void {
			// Очистка скина
			if (skin.material != null) {
				skin.material.clear(skin);
			}
			// Зачищаем ссылки
			skin.next = null;
			//skin.primitive = null;
			skin.material = null;
			// Отправляем в хранилище
			collector.push(skin);
		}
	}
}