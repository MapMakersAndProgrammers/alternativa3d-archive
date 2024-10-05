package alternativa.engine3d.loaders.collada {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.materials.Material;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class DaePrimitive extends DaeElement {
	
		use namespace collada;
	
		private var verticesInput:DaeInput;
		private var texCoordsInputs:Vector.<DaeInput>;
		private var inputsStride:int;
	
		public function DaePrimitive(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		override protected function parseImplementation():Boolean {
			parseInputs();
			return true;
		}
	
		private function parseInputs():void {
			texCoordsInputs = new Vector.<DaeInput>();
			var inputsList:XMLList = data.input;
			var maxInputOffset:int = 0;
			for (var i:int = 0, count:int = inputsList.length(); i < count; i++) {
				var input:DaeInput = new DaeInput(inputsList[i], document);
				var semantic:String = input.semantic;
				if (semantic != null) {
					switch (semantic) {
						case "VERTEX" :
							if (verticesInput == null) {
								verticesInput = input;
							}
							break;
						case "TEXCOORD" :
							texCoordsInputs.push(input);
							break;
					}
				}
				var offset:int = input.offset;
				maxInputOffset = (offset > maxInputOffset) ? offset : maxInputOffset;
			}
			inputsStride = maxInputOffset + 1;
		}
	
		private function findTexCoordsInput(setNum:int):DaeInput {
			for (var i:int = 0, count:int = texCoordsInputs.length; i < count; i++) {
				var texCoordsInput:DaeInput = texCoordsInputs[i];
				if (texCoordsInput.setNum == setNum) {
					return texCoordsInput;
				}
			}
			return (texCoordsInputs.length > 0) ? texCoordsInputs[0] : null;
		}
	
		private function get type():String {
			return data.localName() as String;
		}
	
		/**
		 * Заполняет заданный меш геометрией этого примитива, используя заданные вершины.
		 * На вершины накладывается uv маппинг.
		 * Перед использованием вызвать parse().
		 */
		public function fillInMesh(geometry:Geometry, vertices:Vector.<Vertex>, instanceMaterial:DaeInstanceMaterial = null):void {
			var countXML:XML = data.@count[0];
			if (countXML == null) {
				document.logger.logNotEnoughDataError(data);
				return;
			}
			var numPrimitives:int = parseInt(countXML.toString(), 10);
			var texCoordsInput:DaeInput;
			var material:Material;
			if (instanceMaterial != null) {
				var dmat:DaeMaterial = instanceMaterial.material;
				dmat.parse();
				if (dmat.diffuseTexCoords != null) {
					texCoordsInput = findTexCoordsInput(instanceMaterial.getBindVertexInputSetNum(dmat.diffuseTexCoords));
				} else {
					texCoordsInput = findTexCoordsInput(-1);
				}
				dmat.used = true;
				material = dmat.material;
			} else {
				texCoordsInput = findTexCoordsInput(-1);
			}
			if (texCoordsInput != null) {
				// Если у вершины index != -1, значит вершина где-то используется и ее нужно сдублировать
				// Устанавливаем для такой вершины index в -2
				for each (var vertex:Vertex in vertices) {
					while (vertex != null && vertex.index != -1) {
						vertex.index = -2;
						// Переходим к следующему дубликату
						vertex = vertex.value;
					}
				}
			}
			var texCoords:Vector.<Number>;
			var texCoordsStride:int = 1;
			var texCoordsOffset:int = 0;
			if (texCoordsInput != null) {
				var texCoordsSource:DaeSource = texCoordsInput.prepareSource(2);
				if (texCoordsSource != null) {
					texCoords = texCoordsSource.numbers;
					texCoordsStride = texCoordsSource.stride;
					texCoordsOffset = texCoordsInput.offset;
				}
			}
			var indicesXML:XML;
			var indices:Array;
			switch (this.type) {
				case "polygons" : {
					if (data.ph.length() > 0) {
						// Полигоны с дырками не поддерживаются
						//						document.logger.lo
					}
					var indicesList:XMLList = data.p;
					for (var i:int = 0, count:int = indicesList.length(); i < count; i++) {
						indices = parseIntsArray(indicesList[i]);
						fillInPolygon(geometry, material, vertices, verticesInput.offset, indices.length/inputsStride, indices, texCoords, texCoordsStride, texCoordsOffset);
					}
					break;
				}
				case "polylist" : {
					indicesXML = data.p[0];
					if (indicesXML == null) {
						document.logger.logNotEnoughDataError(data);
						return;
					}
					indices = parseIntsArray(indicesXML);
					var vcountsXML:XML = data.vcount[0];
					var vcounts:Array;
					if (vcountsXML != null) {
						vcounts = parseIntsArray(vcountsXML);
						if (vcounts.length < numPrimitives) {
							return;
						}
						fillInPolylist(geometry, material, vertices, verticesInput.offset, numPrimitives, indices, vcounts, texCoords, texCoordsStride, texCoordsOffset);
					} else {
						fillInPolygon(geometry, material, vertices, verticesInput.offset, numPrimitives, indices, texCoords, texCoordsStride, texCoordsOffset);
					}
					break;
				}
				case "triangles" : {
					indicesXML = data.p[0];
					if (indicesXML == null) {
						document.logger.logNotEnoughDataError(data);
						return;
					}
					indices = parseIntsArray(indicesXML);
					fillInTriangles(geometry, material, vertices, verticesInput.offset, numPrimitives, indices, texCoords, texCoordsStride, texCoordsOffset);
					break;
				}
			}
		}
	
		/**
		 * Добавляет uv координаты вершине или создает новую вершину, если нельзя добавить в эту.
		 * Новая вершина добавляется в список value этой вершины.
		 * @return вершина с заданными uv координатами
		 */
		private function applyUV(geometry:Geometry, vertex:Vertex, texCoords:Vector.<Number>, index:int):Vertex {
			var u:Number = texCoords[index];
			var v:Number = 1 - texCoords[int(index + 1)];
			if (vertex.index == -1) {
				// Была без uv координат
				vertex._u = u;
				vertex._v = v;
				vertex.index = index;
				return vertex;
			}
			if (vertex.index == index) {
				return vertex;
			} else {
				// Дублируем вершину, если её index отличается от индекса заданной uv координаты
				while (vertex.value != null) {
					vertex = vertex.value;
					if (vertex.index == index) {
						return vertex;
					}
				}
				// Последний элемент, создаем дубликат и возвращаем
				var newVertex:Vertex = geometry.addVertex(vertex._x, vertex._y, vertex._z, u, v);
				vertex.value = newVertex;
				newVertex.index = index;
				return newVertex;
			}
		}
	
		/**
		 * Создает один полигон.
		 */
		private function fillInPolygon(geometry:Geometry, material:Material, vertices:Vector.<Vertex>, verticesOffset:int, numIndices:int, indices:Array, texCoords:Vector.<Number>, texCoordsStride:int = 1, texCoordsOffset:int = 0):void {
			var faceVertices:Vector.<Vertex> = new Vector.<Vertex>(numIndices);
			for (var i:int = 0; i < numIndices; i++) {
				var vertex:Vertex = vertices[indices[int(inputsStride*i + verticesOffset)]];
				if (texCoords != null) {
					vertex = applyUV(geometry, vertex, texCoords, texCoordsStride*indices[int(inputsStride*i + texCoordsOffset)]);
				}
				faceVertices[i] = vertex;
			}
			var face:Face = new Face();
			face.setVertices(faceVertices);
			face.geometry = geometry;
			geometry._faces[int(geometry.faceIdCounter++)] = face;
		}
	
		private function fillInPolylist(geometry:Geometry, material:Material, vertices:Vector.<Vertex>, verticesOffset:int, numFaces:int, indices:Array, vcounts:Array, texCoords:Vector.<Number> = null, texCoordsStride:int = 1, texCoordsOffset:int = 0):void {
			var polyIndex:int = 0;
			for (var i:int = 0; i < numFaces; i++) {
				var count:int = vcounts[i];
				if (count >= 3) {
					var faceVertices:Vector.<Vertex> = new Vector.<Vertex>(count);
					for (var j:int = 0; j < count; j++) {
						var vertexIndex:int = inputsStride*(polyIndex + j);
						var vertex:Vertex = vertices[indices[int(vertexIndex + verticesOffset)]];
						if (texCoords != null) {
							vertex = applyUV(geometry, vertex, texCoords, texCoordsStride*indices[int(vertexIndex + texCoordsOffset)]);
						}
						faceVertices[j] = vertex;
					}
					var face:Face = new Face();
					face.setVertices(faceVertices);
					face.geometry = geometry;
					geometry._faces[int(geometry.faceIdCounter++)] = face;
					polyIndex += count;
				}
			}
		}
	
		private function fillInTriangles(geometry:Geometry, material:Material, vertices:Vector.<Vertex>, verticesOffset:int, numFaces:int, indices:Array, texCoords:Vector.<Number> = null, texCoordsStride:int = 1, texCoordsOffset:int = 0):void {
			for (var i:int = 0; i < numFaces; i++) {
				var index:int = 3*inputsStride*i;
				var vertexIndex:int = index + verticesOffset;
				var a:Vertex = vertices[indices[int(vertexIndex)]];
				var b:Vertex = vertices[indices[int(vertexIndex + inputsStride)]];
				var c:Vertex = vertices[indices[int(vertexIndex + 2*inputsStride)]];
				if (texCoords != null) {
					var texIndex:int = index + texCoordsOffset;
					a = applyUV(geometry, a, texCoords, texCoordsStride*indices[int(texIndex)]);
					b = applyUV(geometry, b, texCoords, texCoordsStride*indices[int(texIndex + inputsStride)]);
					c = applyUV(geometry, c, texCoords, texCoordsStride*indices[int(texIndex + 2*inputsStride)]);
				}
				var face:Face = new Face();
				face.setVertices(Vector.<Vertex>([a, b, c]));
				face.geometry = geometry;
				geometry._faces[int(geometry.faceIdCounter++)] = face;
			}
		}
	
		/**
		 * Сравнивает вершины, используемые в примитиве с указанными
		 * Перед использованием вызвать parse().
		 */
		public function verticesEquals(otherVertices:DaeVertices):Boolean {
			var vertices:DaeVertices = document.findVertices(verticesInput.source);
			if (vertices == null) {
				document.logger.logNotFoundError(verticesInput.source);
			}
			return vertices == otherVertices;
		}
	
		public function get materialSymbol():String {
			var attr:XML = data.@material[0];
			return (attr == null) ? null : attr.toString();
		}
	
	}
}
