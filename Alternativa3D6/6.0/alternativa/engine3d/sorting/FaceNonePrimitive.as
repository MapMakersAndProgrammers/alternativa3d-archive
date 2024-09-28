package alternativa.engine3d.sorting {

	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Face;
	
	use namespace alternativa3d;
	
	public class FaceNonePrimitive extends NonePrimitive {

		// Ссылка на грань
		alternativa3d var face:Face;

		// Хранилище неиспользуемых примитивов
		static private var collector:Array = new Array();
		
		// Примитивы на отложенное удаление
		static private var deferred:Array = new Array();
		
		static alternativa3d function create():FaceNonePrimitive {
			var primitive:FaceNonePrimitive;
			if ((primitive = collector.pop()) == null) {
				// Если коллектор пуст, создаём новый примитив
				return new FaceNonePrimitive();
			}
			return primitive;
		}
		
		static alternativa3d function defer(primitive:FaceNonePrimitive):void {
			deferred.push(primitive);
		}
		
		static alternativa3d function destroyDeferred():void {
			var primitive:FaceNonePrimitive;
			while ((primitive = deferred.pop()) != null) {
				primitive.face = null;
				primitive.sortingLevel = null;
				collector.push(primitive);
			}
		}
	}
}