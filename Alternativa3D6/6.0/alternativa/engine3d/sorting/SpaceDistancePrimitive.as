package alternativa.engine3d.sorting {

	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Space;
	
	use namespace alternativa3d;
	
	public class SpaceDistancePrimitive extends DistancePrimitive {
		
		// Ссылка на пространство
		alternativa3d var space:Space;
		
		// Хранилище неиспользуемых примитивов
		static private var collector:Array = new Array();
		
		// Примитивы на отложенное удаление
		static private var deferred:Array = new Array();
		
		static alternativa3d function create():SpaceDistancePrimitive {
			var primitive:SpaceDistancePrimitive;
			if ((primitive = collector.pop()) == null) {
				// Если коллектор пуст, создаём новый примитив
				return new SpaceDistancePrimitive();
			}
			return primitive;
		}
		
		static alternativa3d function defer(primitive:SpaceDistancePrimitive):void {
			deferred.push(primitive);
		}
		
		static alternativa3d function destroyDeferred():void {
			var primitive:SpaceDistancePrimitive;
			while ((primitive = deferred.pop()) != null) {
				primitive.space = null;
				primitive.node = null;
				collector.push(primitive);
			}
		}
		
	}
}