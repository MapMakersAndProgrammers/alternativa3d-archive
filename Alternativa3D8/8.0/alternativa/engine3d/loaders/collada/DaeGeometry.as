package alternativa.engine3d.loaders.collada {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;

	/**
	 * @private
	 */
	public class DaeGeometry extends DaeElement {
	
		use namespace collada;
		use namespace alternativa3d;

		private var primitives:Vector.<DaePrimitive>;

		private var vertices:DaeVertices;

		public function DaeGeometry(data:XML, document:DaeDocument) {
			super(data, document);

			// Внутри <geometry> объявляются элементы: sources, vertices.
			// sources мы создаем внутри DaeDocument, здесь не нужно.
			constructVertices();
		}

		private function constructVertices():void {
			var verticesXML:XML = data.mesh.vertices[0];
			if (verticesXML != null) {
				vertices = new DaeVertices(verticesXML, document);
				document.vertices[vertices.id] = vertices;
			}
		}

		override protected function parseImplementation():Boolean {
			if (vertices != null) {
				return parsePrimitives();
			}
			return false;
		}

		private function parsePrimitives():Boolean {
			primitives = new Vector.<DaePrimitive>();
			var children:XMLList = data.mesh.children();
			for (var i:int = 0, count:int = children.length(); i < count; i++) {
				var child:XML = children[i];
				switch (child.localName()) {
					case "polygons":
					case "polylist":
					case "triangles":
					case "trifans":
					case "tristrips":
						primitives.push(new DaePrimitive(child, document));
						break;
				}
			}
			return true;
		}

		/**
		 * Возвращает материал первого примитива 
		 * Перед использованием вызвать parse(). 
		 */
		public function getAnyMaterial(materials:Object):Material {
			if (primitives.length > 0) {
				var instanceMaterial:DaeInstanceMaterial = materials[primitives[0].materialSymbol];
				var mat:DaeMaterial = (instanceMaterial == null) ? null : instanceMaterial.material;
				if (mat != null) {
					mat.parse();
					return mat.material;
				}
			}
			return null;
		}

		/**
		 * Создает геометрию и возвращает в виде меша.
		 * Перед использованием вызвать parse().
		 *
		 * @param materials словарь материалов.
		 */
		public function parseMesh(materials:Object):Mesh {
			if (data.mesh.length() > 0) {
				var geometry:Geometry = new Geometry();
				fillInMesh(geometry, materials);
				cleanVertices(geometry);
//				mesh.calculateNormals(true);
				var mesh:Mesh = new Mesh();
				mesh.geometry = geometry;
				mesh.material = getAnyMaterial(materials);
				mesh.calculateBounds();
				return mesh;
			}
			return null;
		}

		public function parseByPrimitives(materials:Object):Vector.<Mesh> {
			if (data.mesh.length() > 0) {
				var result:Vector.<Mesh> = new Vector.<Mesh>();
				vertices.parse();
				for (var i:int = 0, count:int = primitives.length; i < count; i++) {
					var geometry:Geometry = new Geometry();
					var createdVertices:Vector.<Vertex> = vertices.fillInMesh(geometry);
					var primitive:DaePrimitive = primitives[i];
					primitive.parse();
					var material:DaeInstanceMaterial = null;
					if (primitive.verticesEquals(vertices)) {
						material = materials[primitive.materialSymbol];
						primitive.fillInMesh(geometry, createdVertices, material);
						cleanVertices(geometry);
						var mesh:Mesh = new Mesh();
						mesh.geometry = geometry;
						mesh.material = (material == null) ? null : material.material.material;
						mesh.calculateBounds();
						result.push(mesh);
					} else {
						// Ошибка, нельзя использовать вершины из другой геометрии
					}
				}
				return result;
			}
			return null;
		}

		/**
		 * Заполняет заданный объект геометрией и возвращает массив вершин с индексами.
		 * Перед использованием вызвать parse().
		 * Некоторые вершины в поле value содержат ссылку на дубликат вершины.
		 * После использования нужно вызвать cleanVertices для зачистки вершин от временных данных.
		 *
		 * @return массив вершин с индексами. У вершины в поле value задается дубликат вершины.
		 */
		public function fillInMesh(geometry:Geometry, materials:Object):Vector.<Vertex> {
			vertices.parse();
			var createdVertices:Vector.<Vertex> = vertices.fillInMesh(geometry);
			for (var i:int = 0, count:int = primitives.length; i < count; i++) {
				var primitive:DaePrimitive = primitives[i];
				primitive.parse();
				if (primitive.verticesEquals(vertices)) {
					primitive.fillInMesh(geometry, createdVertices, materials[primitive.materialSymbol]);
				} else {
					// Ошибка, нельзя использовать вершины из другой геометрии
				}
			}
			return createdVertices;
		}

		/**
		 * Зачищает вершины от временных данных
		 */
		public function cleanVertices(geometry:Geometry):void {
			for each (var vertex:Vertex in geometry._vertices) {
				vertex.index = 0;
				vertex._attributes = null;
				vertex.value = null;
			}
		}

	}
}
