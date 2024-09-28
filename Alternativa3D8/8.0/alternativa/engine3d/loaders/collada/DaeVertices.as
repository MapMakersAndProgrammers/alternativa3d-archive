package alternativa.engine3d.loaders.collada {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Vertex;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class DaeVertices extends DaeElement {
	
		use namespace collada;
	
		/**
		 * Источник данных координат вершин. Содержит координаты в массиве numbers.
		 * Свойство stride источника не меньше трех.
		 * Перед использованием вызвать parse().
		 */
		private var positions:DaeSource;
		//private var texCoords:Vector.<DaeSource>;
	
		public function DaeVertices(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		override protected function parseImplementation():Boolean {
			// Получаем массив координат вершин
			var inputXML:XML = data.input.(@semantic == "POSITION")[0];
			if (inputXML != null) {
				positions = (new DaeInput(inputXML, document)).prepareSource(3);
				if (positions != null) {
					return true;
				}
			}
			return false;
		}
	
		/**
		 * Создает вершины в меше. У каждой вершины index устанавливается в значение позиции в массиве.
		 * Перед использованием вызвать parse().
		 *
		 * @return вектор вершин и их индексов
		 */
		public function fillInMesh(geometry:Geometry):Vector.<Vertex> {
			var stride:int = positions.stride;
			var coords:Vector.<Number> = positions.numbers;
			var numVerts:int = positions.numbers.length/stride;
			var createdVertices:Vector.<Vertex> = new Vector.<Vertex>(numVerts);
			var i:int;
			for (i = 0; i < numVerts; i++) {
				var offset:int = stride*i;
				var newVertex:Vertex = geometry.addVertex(coords[offset], coords[int(offset + 1)], coords[int(offset + 2)], 0, 0, i);  
				newVertex.index = i;
				createdVertices[i] = newVertex;
			}
			geometry.vertexIdCounter = numVerts - 1;
			return createdVertices;
		}

	}
}
