package alternativa.engine3d.sorting {
	
	import alternativa.engine3d.*;
	
	use namespace alternativa3d;
	
	public class BSPNode extends Node {

		// Дочерние полигональные ветки
		alternativa3d var frontBSP:BSPNode;
		alternativa3d var backBSP:BSPNode;

		// Дочерние точечные ноды
		alternativa3d var frontDistance:DistanceNode;
		alternativa3d var backDistance:DistanceNode;
		
		// Хранилище неиспользуемых нод
		static private var collector:Array = new Array();
		
		static alternativa3d function create():BSPNode {
			var node:BSPNode;
			if ((node = collector.pop()) == null) {
				// Если коллектор пуст, создаём новую ноду
				return new BSPNode();
			}
			return node;
		}
		
		static alternativa3d function destroy(node:BSPNode):void {
			// Удаляем ссылку на уровень
			node.sortingLevel = null;
			// Отправляем ноду в коллектор
			collector.push(node);
		}
/*		
		override alternativa3d function addBSPPrimitive(primitive:FaceBSPPrimitive):void {

		}

		override alternativa3d function addDistancePrimitive(primitive:DistancePrimitive):void {

		}
		
		alternativa3d function removePrimitive(primitive:FaceBSPPrimitive):void {
			
		}
*/		
	}
}