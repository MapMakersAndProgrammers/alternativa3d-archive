package alternativa.engine3d.sorting {

	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Space;
	
	use namespace alternativa3d;
	
	public class SpaceNonePrimitive extends NonePrimitive {
		
		// Ссылка на пространство
		alternativa3d var space:Space;
		
		// Хранилище неиспользуемых примитивов
		static private var collector:Array = new Array();
		
		// Примитивы на отложенное удаление
		static private var deferred:Array = new Array();
		
		static alternativa3d function create():SpaceNonePrimitive {
			var primitive:SpaceNonePrimitive;
			if ((primitive = collector.pop()) == null) {
				// Если коллектор пуст, создаём новый примитив
				return new SpaceNonePrimitive();
			}
			return primitive;
		}
		
		static alternativa3d function defer(primitive:SpaceNonePrimitive):void {
			deferred.push(primitive);
		}
		
		static alternativa3d function destroyDeferred():void {
			var primitive:SpaceNonePrimitive;
			while ((primitive = deferred.pop()) != null) {
				primitive.space = null;
				primitive.sortingLevel = null;
				collector.push(primitive);
			}
		}
	}
}