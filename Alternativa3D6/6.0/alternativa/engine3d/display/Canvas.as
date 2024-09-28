package alternativa.engine3d.display {
	
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Space;
	
	use namespace alternativa3d;
	
	public class Canvas extends DisplayItem {
		
		/**
		 * @private
		 * Пространство
		 */
		alternativa3d var space:Space;

		/**
		 * @private
		 * Ссылка на предыдущий объект
		 */
		alternativa3d var previous:DisplayItem;

		// Список отрисовочных объектов
		alternativa3d var firstItem:DisplayItem;
		alternativa3d var previousItem:DisplayItem;
		alternativa3d var currentItem:DisplayItem;

		// Хранилище неиспользуемых канвасов
		static private var collector:Array = new Array();

		/**
		 * @private
		 * Создание полотна.
		 */
		static alternativa3d function create():Canvas {
			var canvas:Canvas;
			if ((canvas = collector.pop()) == null) {
				// Если коллектор пуст, создаём новый канвас
				return new Canvas();
			}
			return canvas;
		}

		/**
		 * @private
		 * Удаление и зачистка канваса.
		 */
		static alternativa3d function destroy(canvas:Canvas):void {
			// Зачистка списка
			var item:DisplayItem = canvas.firstItem;
			while (item != null) {
				// Сохраняем следующий
				var next:DisplayItem = item.next;
				// Удаляем из канваса
				canvas.removeChild(item);
				// Удаляем
				(item is Skin) ? Skin.destroy(item as Skin) : Canvas.destroy(item as Canvas);
				// Следующий устанавливаем текущим
				item = next;
			}
			// Зачищаем ссылки
			canvas.next = null;
			canvas.previous = null;
			canvas.space = null;
			// Удаляем список
			canvas.firstItem = null;
			canvas.previousItem = null;
			canvas.currentItem = null;
			// Отправляем в хранилище
			collector.push(canvas);
		}

	}
}