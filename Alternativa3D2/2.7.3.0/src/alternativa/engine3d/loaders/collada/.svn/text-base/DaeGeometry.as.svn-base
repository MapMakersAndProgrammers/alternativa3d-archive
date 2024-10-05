package alternativa.engine3d.loaders.collada {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Vertex;
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
		 * Создает геометрию и возвращает в виде меша.
		 * Перед использованием вызвать parse().
		 *
		 * @param materials словарь материалов.
		 */
		public function parseMesh(materials:Object):Mesh {
			if (data.mesh.length() > 0) {
				var mesh:Mesh = parseAlternativa3DObject(false);
				if (mesh == null) {
					mesh = new Mesh();
				}
				fillInMesh(mesh, materials);
				cleanVertices(mesh);
				mesh.calculateNormals(true);
				mesh.calculateBounds();
				return mesh;
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
		public function fillInMesh(mesh:Mesh, materials:Object):Vector.<Vertex> {
			vertices.parse();
			var createdVertices:Vector.<Vertex> = vertices.fillInMesh(mesh);
			for (var i:int = 0, count:int = primitives.length; i < count; i++) {
				var primitive:DaePrimitive = primitives[i];
				primitive.parse();
				if (primitive.verticesEquals(vertices)) {
					primitive.fillInMesh(mesh, createdVertices, materials[primitive.materialSymbol]);
				} else {
					// Ошибка, нельзя использовать вершины из другой геометрии
				}
			}
			return createdVertices;
		}
	
		/**
		 * Зачищает вершины от временных данных
		 */
		public function cleanVertices(mesh:Mesh):void {
			for (var vertex:Vertex = mesh.vertexList; vertex != null; vertex = vertex.next) {
				vertex.index = 0;
				vertex.value = null;
			}
		}
	
		public function parseAlternativa3DObject(skin:Boolean = false):Mesh {
			var profile:XML = data.mesh.extra.technique.(@profile == "Alternativa3D")[0];
			if (profile != null) {
				var meshXML:XML = profile.mesh[0];
				if (meshXML != null) {
					return (new DaeAlternativa3DObject(meshXML, document)).parseMesh(skin);
				}
			}
			return null;
		}
	
	}
}
