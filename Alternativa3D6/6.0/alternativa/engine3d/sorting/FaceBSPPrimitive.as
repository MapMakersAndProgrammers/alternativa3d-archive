package alternativa.engine3d.sorting {

	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Face;
	
	use namespace alternativa3d;

	public class FaceBSPPrimitive extends Primitive {
		
		// Ссылка на грань
		alternativa3d var face:Face;

		// Нода
		alternativa3d var node:BSPNode;
		
		// Уровень в BSP 
		alternativa3d var bspLevel:int;
		
		// Хранилище неиспользуемых примитивов
		static private var collector:Array = new Array();
		
		// Примитивы на отложенное удаление
		static private var deferred:Array = new Array();
		
		static alternativa3d function create():FaceBSPPrimitive {
			var primitive:FaceBSPPrimitive;
			if ((primitive = collector.pop()) == null) {
				// Если коллектор пуст, создаём новый примитив
				return new FaceBSPPrimitive();
			}
			return primitive;
		}
		
		static alternativa3d function defer(primitive:FaceBSPPrimitive):void {
			deferred.push(primitive);
		}
		
		static alternativa3d function destroyDeferred():void {
			var primitive:FaceBSPPrimitive;
			while ((primitive = deferred.pop()) != null) {
				primitive.face = null;
				primitive.node = null;				
				collector.push(primitive);
			}
		}		
	}
}