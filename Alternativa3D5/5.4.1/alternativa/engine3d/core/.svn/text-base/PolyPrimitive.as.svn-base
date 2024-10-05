package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 * Примитивный полигон (примитив), хранящийся в узле BSP-дерева.
	 */
	public class PolyPrimitive {
		
		/**
		 * @private
		 * Количество точек
		 */
		alternativa3d var num:uint;
		/**
		 * @private
		 * Точки
		 */
		alternativa3d var points:Array = new Array();
		/**
		 * @private
		 * UV-координаты
		 */
		alternativa3d var uvs:Array = new Array();
		/**
		 * @private
		 * Грань
		 */
		alternativa3d var face:Face;
		/**
		 * @private
		 * Родительский примитив
		 */
		alternativa3d var parent:PolyPrimitive;
		/**
		 * @private
		 * Соседний примитив (при наличии родительского)
		 */
		alternativa3d var sibling:PolyPrimitive;
		/**
		 * @private
		 * Фрагменты
		 */
		alternativa3d var backFragment:PolyPrimitive;
		/**
		 * @private
		 */
		alternativa3d var frontFragment:PolyPrimitive;
		/**
		 * @private
		 * Рассечения
		 */
		alternativa3d var splitTime1:Number;
		/**
		 * @private
		 */
		alternativa3d var splitTime2:Number;
		/**
		 * @private
		 * BSP-нода, в которой находится примитив
		 */
		alternativa3d var node:BSPNode;
		/**
		 * @private
		 * Значения для расчёта качества сплиттера
		 */
		alternativa3d var splits:uint;
		/**
		 * @private
		 */
		alternativa3d var disbalance:int;
		/**
		 * @private
		 * Качество примитива как сплиттера (меньше - лучше)
		 */
		public var splitQuality:Number;
		/**
		 * @private
		 * Приоритет в BSP-дереве. Чем ниже мобильность, тем примитив выше в дереве.
		 */
		public var mobility:int;

		// Хранилище неиспользуемых примитивов
		static private var collector:Array = new Array();
		
		/**
		 * @private
		 * Создать примитив
		 */
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
		 * @private
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
		
		/**
		 * Строковое представление объекта.
		 */
		public function toString():String {
			return "[Primitive " + face._mesh._name + "]";
		}
	}
}