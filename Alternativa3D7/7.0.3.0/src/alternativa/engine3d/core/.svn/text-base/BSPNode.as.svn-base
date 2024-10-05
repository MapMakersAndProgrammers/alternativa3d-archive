package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	import __AS3__.vec.Vector;
	
	use namespace alternativa3d;
	
	public class BSPNode {
		
		static private var collector:Vector.<BSPNode> = new Vector.<BSPNode>();
		static private var collectorLength:int = 0;

		// Нормаль и смещение
		public var normal:int;
		
		// Дочерние ноды
		public var negative:BSPNode;
		public var positive:BSPNode;
		
		// Треугольники
		public var triangles:Vector.<int> = new Vector.<int>();
		public var trianglesLength:uint = 0;
		
		// Полигоны
		public var polygons:Vector.<int> = new Vector.<int>();
		public var polygonsLength:uint = 0;
		
		// Флаг расположения камеры
		public var cameraInfront:Boolean;
		
		// Предыдущая нода в стеке (для раскрытия рекурсии)
		public var prev:BSPNode;
		
		static alternativa3d function create():BSPNode {
			return (collectorLength > 0) ? collector[--collectorLength] : new BSPNode();
		}

		public function create():BSPNode {
			return (collectorLength > 0) ? collector[--collectorLength] : new BSPNode();
		}
		
		public function destroy():void {
			if (negative != null) {
				negative.destroy();
				negative = null;
			}
			if (positive != null) {
				positive.destroy();
				positive = null;
			}
			trianglesLength = 0;
			polygonsLength = 0;
			collector[collectorLength++] = this;
		}
		
		// Добавление фрагмента в ноду
		public function addFragment(fragment:Vector.<int>, begin:int, end:int):void {
			polygons[polygonsLength++] = end - begin;
			var i:int = begin, a:int = polygons[polygonsLength++] = fragment[i++], b:int = polygons[polygonsLength++] = fragment[i++], c:int;
			while (i < end) {
				triangles[trianglesLength++] = a;
				triangles[trianglesLength++] = b;
				triangles[trianglesLength++] = c = polygons[polygonsLength++] = fragment[i++];
				b = c;
			}
		}
		
	}
}
