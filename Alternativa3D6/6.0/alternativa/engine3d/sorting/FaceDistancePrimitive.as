package alternativa.engine3d.sorting {

	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Face;
	
	use namespace alternativa3d;
	
	public class FaceDistancePrimitive extends DistancePrimitive {
		
		// Ссылка на грань
		alternativa3d var face:Face;
		
		// Хранилище неиспользуемых примитивов
		static private var collector:Array = new Array();
		
		// Примитивы на отложенное удаление
		static private var deferred:Array = new Array();
		
		static alternativa3d function create():FaceDistancePrimitive {
			var primitive:FaceDistancePrimitive;
			if ((primitive = collector.pop()) == null) {
				// Если коллектор пуст, создаём новый примитив
				return new FaceDistancePrimitive();
			}
			return primitive;
		}
		
		static alternativa3d function defer(primitive:FaceDistancePrimitive):void {
			deferred.push(primitive);
		}
		
		static alternativa3d function destroyDeferred():void {
			var primitive:FaceDistancePrimitive;
			while ((primitive = deferred.pop()) != null) {
				primitive.face = null;
				primitive.node = null;				
				collector.push(primitive);
			}
		}
		
	}
}