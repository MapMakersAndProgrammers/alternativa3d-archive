package alternativa.engine3d.core {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.display.BitmapData;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	use namespace alternativa3d;
		
	/**
	 * Объект, представляющий текстуру в виде последовательности её уменьшенных копий.
	 * Каждая следующая в два раза меньше предыдущей. Последняя имеет размер 1х1 пиксел.
	 * Чем дальше от камеры отрисовываемый объект, тем меньшая текстура выбирается.
	 * Это позволяет получить лучший визуальный результат и большую производительность.
	 */
	public class MipMap {
		
		/**
		 * Мип-текстуры 
		 */
		public var textures:Vector.<BitmapData> = new Vector.<BitmapData>();
		/**
		 * Количество мип-текстур 
		 */
		public var num:int;
		/**
		 * Отношение размера пиксела текстуры к единице измерения трёхмерного пространства
		 */
		public var resolution:Number;
		
		static private const filter:ConvolutionFilter = new ConvolutionFilter(2, 2, [1, 1, 1, 1], 4, 0, false, true);
		static private const point:Point = new Point();
		static private const matrix:Matrix = new Matrix();
		static private const rect:Rectangle = new Rectangle();
		public function MipMap(texture:BitmapData, resolution:Number = 1) {
			var bmp:BitmapData = new BitmapData(texture.width, texture.height, texture.transparent);
			var current:BitmapData = textures[num++] = texture;
			filter.preserveAlpha = !texture.transparent;
			var w:Number = rect.width = texture.width, h:Number = rect.height = texture.height;
			while (w > 1 && h > 1 && rect.width > 1 && rect.height > 1) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width = w >> 1;
				rect.height = h >> 1;
				matrix.a = rect.width/w;
				matrix.d = rect.height/h;
				w *= 0.5;
				h *= 0.5;
				current = new BitmapData(rect.width, rect.height, texture.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);					
				textures[num++] = current;
			}
			bmp.dispose();
			this.resolution = resolution;
		}
		
		/**
		 * Получение мип-уровня в зависимости от удалённости объекта от камеры 
		 * @param distance Z-координата объекта в пространстве камеры 
		 * @param camera Камера
		 * @return Индекс в списке мип-текстур textures
		 */
		public function getLevel(distance:Number, camera:Camera3D):int {
			var level:int = Math.log(distance/(camera.focalLength*resolution))*1.442695040888963387;
			if (level < 0) return 0; else if (level >= num) return num - 1;
			return level;
		}
	}
}