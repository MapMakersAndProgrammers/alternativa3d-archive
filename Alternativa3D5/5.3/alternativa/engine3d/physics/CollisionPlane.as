package alternativa.engine3d.physics {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.BSPNode;

	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class CollisionPlane {
		public var node:BSPNode;
		public var infront:Boolean;
		public var sourceOffset:Number;
		public var destinationOffset:Number;
		
		// Хранилище неиспользуемых плоскостей
		static private var collector:Array = new Array();
		
		// Создать плоскость
		static alternativa3d function createCollisionPlane(node:BSPNode, infront:Boolean, sourceOffset:Number, destinationOffset:Number):CollisionPlane {
			
			// Достаём плоскость из коллектора
			var plane:CollisionPlane = collector.pop();
			// Если коллектор пуст, создаём новую плоскость
			if (plane == null) {
				plane = new CollisionPlane();
			}

			plane.node = node;
			plane.infront = infront;
			plane.sourceOffset = sourceOffset;
			plane.destinationOffset = destinationOffset;

			return plane;
		}
		
		// Удалить плоскость, все ссылки должны быть почищены
		static alternativa3d function destroyCollisionPlane(plane:CollisionPlane):void {
			collector.push(plane);
		}
		
		
	}
}