package alternativa.engine3d.materials {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	
	use namespace alternativa3d;
	
	/**
	 * Материал, заполняющий полигон сплошной одноцветной заливкой.
	 * Помимо заливки цветом, материал может рисовать границу полигона линией заданной толщины и цвета.
	 */
	public class FillMaterial extends Material {
	
		/**
		 * Цвет заливки.
		 * Значение по умолчанию <code>0x7F7F7F</code>.
		 */
		public var color:int;
		
		/**
		 * Значение альфа-прозрачности.
		 * Допустимые значения находятся в диапазоне от <code>0</code> до <code>1</code>.
		 * Значение по умолчанию <code>1</code>.
		 */
		public var alpha:Number;
		
		/**
		 * Толщина линий.
		 * Линии отрисовываются только если толщина больше или равна <code>0</code>.
		 * Значение по умолчанию <code>-1</code>.
		 */
		public var lineThickness:Number;
		
		/**
		 * Цвет линий.
		 * Линии отрисовываются только если толщина больше или равна <code>0</code>.
		 * Значение по умолчанию <code>0xFFFFFF</code>.
		 */
		public var lineColor:int;
	
		/**
		 * Создаёт новый экземпляр.
		 * @param color Цвет заливки.
		 * @param alpha Альфа-прозрачность заливки
		 * @param lineThickness Толщина линий.
		 * @param lineColor Цвет линий.
		 */
		public function FillMaterial(color:int = 0x7F7F7F, alpha:Number = 1, lineThickness:Number = -1, lineColor:int = 0xFFFFFF) {
			this.color = color;
			this.alpha = alpha;
			this.lineThickness = lineThickness;
			this.lineColor = lineColor;
		}
	
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, canvas:Canvas, list:Face, distance:Number):void {
			var viewSizeX:Number = camera.viewSizeX;
			var viewSizeY:Number = camera.viewSizeY;
			var next:Face;
			// Отрисовка
			if (lineThickness >= 0) canvas.gfx.lineStyle(lineThickness, lineColor);
			for (var face:Face = list; face != null; face = next) {
				next = face.processNext;
				face.processNext = null;
				var wrapper:Wrapper = face.wrapper;
				var vertex:Vertex = wrapper.vertex;
				if (alpha > 0) canvas.gfx.beginFill(color, alpha);
				canvas.gfx.moveTo(vertex.cameraX*viewSizeX/vertex.cameraZ, vertex.cameraY*viewSizeY/vertex.cameraZ);
				var numVertices:int = -1;
				for (wrapper = wrapper.next; wrapper != null; wrapper = wrapper.next) {
					vertex = wrapper.vertex;
					canvas.gfx.lineTo(vertex.cameraX*viewSizeX/vertex.cameraZ, vertex.cameraY*viewSizeY/vertex.cameraZ);
					numVertices++;
				}
				if (alpha <= 0) {
					vertex = face.wrapper.vertex;
					canvas.gfx.lineTo(vertex.cameraX*viewSizeX/vertex.cameraZ, vertex.cameraY*viewSizeY/vertex.cameraZ);
				}
				camera.numTriangles += numVertices;
				camera.numPolygons++;
			}
			camera.numDraws++;
		}
	
		/**
		 * @private 
		 */
		override alternativa3d function drawViewAligned(camera:Camera3D, canvas:Canvas, list:Face, distance:Number, a:Number, b:Number, c:Number, d:Number, tx:Number, ty:Number):void {
			var viewSizeX:Number = camera.viewSizeX;
			var viewSizeY:Number = camera.viewSizeY;
			var next:Face;
			// Отрисовка
			if (lineThickness >= 0) canvas.gfx.lineStyle(lineThickness, lineColor);
			for (var face:Face = list; face != null; face = next) {
				next = face.processNext;
				face.processNext = null;
				var wrapper:Wrapper = face.wrapper;
				var vertex:Vertex = wrapper.vertex;
				if (alpha > 0) canvas.gfx.beginFill(color, alpha);
				canvas.gfx.moveTo(vertex.cameraX*viewSizeX/distance, vertex.cameraY*viewSizeY/distance);
				var numVertices:int = -1;
				for (wrapper = wrapper.next; wrapper != null; wrapper = wrapper.next) {
					vertex = wrapper.vertex;
					canvas.gfx.lineTo(vertex.cameraX*viewSizeX/distance, vertex.cameraY*viewSizeY/distance);
					numVertices++;
				}
				camera.numTriangles += numVertices;
				camera.numPolygons++;
			}
			camera.numDraws++;
		}
	
	}
}