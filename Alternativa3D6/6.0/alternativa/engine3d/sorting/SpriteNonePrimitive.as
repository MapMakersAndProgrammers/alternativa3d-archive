package alternativa.engine3d.sorting {

	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Sprite3D;
	
	use namespace alternativa3d;
	
	public class SpriteNonePrimitive extends NonePrimitive {
		
		// Ссылка на спрайт
		alternativa3d var sprite:Sprite3D;
		
		// Хранилище неиспользуемых примитивов
		static private var collector:Array = new Array();
		
		// Примитивы на отложенное удаление
		static private var deferred:Array = new Array();
		
		static alternativa3d function create():SpriteNonePrimitive {
			var primitive:SpriteNonePrimitive;
			if ((primitive = collector.pop()) == null) {
				// Если коллектор пуст, создаём новый примитив
				return new SpriteNonePrimitive();
			}
			return primitive;
		}
		
		static alternativa3d function defer(primitive:SpriteNonePrimitive):void {
			deferred.push(primitive);
		}
		
		static alternativa3d function destroyDeferred():void {
			var primitive:SpriteNonePrimitive;
			while ((primitive = deferred.pop()) != null) {
				primitive.sprite = null;
				primitive.sortingLevel = null;
				collector.push(primitive);
			}
		}
	}
}