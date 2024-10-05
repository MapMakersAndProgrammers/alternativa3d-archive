package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.types.Point3D;
	import alternativa.types.Set;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public final class BSPNode {
		
		// Родительская нода
		alternativa3d var parent:BSPNode;
		
		// Дочерние ветки
		alternativa3d var front:BSPNode; 
		alternativa3d var back:BSPNode;
		
		// Нормаль плоскости ноды
		alternativa3d var normal:Point3D = new Point3D();

		// Смещение плоскости примитива
		alternativa3d var offset:Number;
		
		// Минимальная мобильность ноды
		alternativa3d var mobility:int = int.MAX_VALUE;
		
		// Набор примитивов в ноде
		alternativa3d var primitive:PolyPrimitive;
		alternativa3d var backPrimitives:Set;
		alternativa3d var frontPrimitives:Set;
		
		// Хранилище неиспользуемых нод
		static private var collector:Array = new Array();
		
		// Создать ноду на основе примитива
		static alternativa3d function createBSPNode(primitive:PolyPrimitive):BSPNode {
			// Достаём ноду из коллектора
			var node:BSPNode = collector.pop();
			// Если коллектор пуст, создаём новую ноду
			if (node == null) {
				node = new BSPNode();
			}

			// Добавляем примитив в ноду
			node.primitive = primitive;
			// Сохраняем ноду
			primitive.node = node;
			// Сохраняем плоскость
			node.normal.copy(primitive.face.globalNormal);
			node.offset = primitive.face.globalOffset;
			// Сохраняем мобильность
			node.mobility = primitive.mobility;
			return node;
		}
		
		// Удалить ноду, все ссылки должны быть почищены
		static alternativa3d function destroyBSPNode(node:BSPNode):void {
			//trace(node.back, node.front, node.parent, node.primitive, node.backPrimitives, node.frontPrimitives);
			collector.push(node);
		}
		
	}
}