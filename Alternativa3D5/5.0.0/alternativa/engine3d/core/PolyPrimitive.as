package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class PolyPrimitive {
		
		// Количество точек
		alternativa3d var num:uint;
		// Точки
		alternativa3d var points:Array = new Array();
		// UV-координаты
		alternativa3d var uvs:Array = new Array();
		
		// Грань
		alternativa3d var face:Face;
		// Родительский примитив
		alternativa3d var parent:PolyPrimitive;
		// Соседний примитив (при наличии родительского)
		alternativa3d var sibling:PolyPrimitive;
		
		// Фрагменты
		alternativa3d var fragment1:PolyPrimitive;
		alternativa3d var fragment2:PolyPrimitive;
		// Рассечения
		alternativa3d var splitTime1:Number;
		alternativa3d var splitTime2:Number;
		
		// BSP-нода, в которой находится примитив
		alternativa3d var node:BSPNode;
		
		// Значения для расчёта качества сплиттера
		alternativa3d var splits:uint;
		alternativa3d var disbalance:int;
		// Качество примитива как сплиттера (меньше - лучше)
		public var splitQuality:Number;

		// Приоритет в BSP-дереве. Чем ниже мобильность, тем примитив выше в дереве.
		public var mobility:int;

		// Хранилище неиспользуемых примитивов
		static private var collector:Array = new Array();
		
		// Создать примитив
		static alternativa3d function createPolyPrimitive():PolyPrimitive {
			// Достаём примитив из коллектора
			var primitive:PolyPrimitive = collector.pop();
			// Если коллектор пуст, создаём новый примитив
			if (primitive == null) {
				primitive = new PolyPrimitive();
			}
			//trace(primitive.num, primitive.points.length, primitive.face, primitive.parent, primitive.sibling, primitive.fragment1, primitive.fragment2, primitive.node);
			return primitive;
		}
		
		/**
		 * Кладёт примитив в коллектор для последующего реиспользования.
		 * Ссылка на грань и массивы точек зачищаются в этом методе.
		 * Ссылки на фрагменты (parent, sibling, back, front) должны быть зачищены перед запуском метода.
		 * 
		 * Исключение:
		 * при сборке примитивов в сцене ссылки на back и front зачищаются после запуска метода. 
		 *   
		 * @param primitive примитив на реиспользование
		 */
		static alternativa3d function destroyPolyPrimitive(primitive:PolyPrimitive):void {
			primitive.face = null;
			for (var i:uint = 0; i < primitive.num; i++) {
				primitive.points.pop();
				primitive.uvs.pop();
			}
			collector.push(primitive);
		}
		
		public function toString():String {
			return "[Primitive " + face._mesh._name + "]";
		}
		
	}
}