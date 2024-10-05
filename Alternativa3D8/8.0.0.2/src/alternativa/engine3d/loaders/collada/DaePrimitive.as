package alternativa.engine3d.loaders.collada {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.materials.Material;
	
	import flash.geom.Point;
	
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

		private function getTexCoordsDatas(mainSetNum:int):Vector.<TexCoordsData> {
			var mainInput:DaeInput = null;
			var texCoordsInput:DaeInput;
			var i:int;
			var numInputs:int = texCoordsInputs.length;
			for (i = 0; i < numInputs; i++) {
				texCoordsInput = texCoordsInputs[i];
				if (texCoordsInput.setNum == mainSetNum) {
					mainInput = texCoordsInput;
					break;
				}
			}
			var datas:Vector.<TexCoordsData> = new Vector.<TexCoordsData>();
			for (i = 0; i < numInputs; i++) {
				texCoordsInput = texCoordsInputs[i];
				var texCoordsSource:DaeSource = texCoordsInput.prepareSource(2);
				if (texCoordsSource != null) {
					var data:TexCoordsData = new TexCoordsData(texCoordsSource.numbers, texCoordsSource.stride, texCoordsInput.offset);
					if (texCoordsInput == mainInput) {
						datas.unshift(data);
					} else {
						datas.push(data);
					}
				}
			}
			return (datas.length > 0) ? datas : null;
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
			var texCoordsDatas:Vector.<TexCoordsData>;
			var material:Material;
			if (instanceMaterial != null) {
				var dmat:DaeMaterial = instanceMaterial.material;
				dmat.parse();
				if (dmat.mainTexCoords != null) {
					texCoordsDatas = getTexCoordsDatas(instanceMaterial.getBindVertexInputSetNum(dmat.mainTexCoords));
				} else {
					texCoordsDatas = getTexCoordsDatas(-1);
				}
				dmat.used = true;
				material = dmat.material;
			} else {
				texCoordsDatas = getTexCoordsDatas(-1);
			}
			var i:int;
			if (texCoordsDatas != null) {
				var numTexCoords:int = texCoordsDatas.length;
				if (numTexCoords > 32) {
					numTexCoords = 32;
					texCoordsDatas.length = 32;
					// Предупреждение
				}
				// Создаем новые канналы и сохраняем ссылки на них
				if (numTexCoords > 1) {
					if (geometry.uvChannels == null) {
						geometry.uvChannels = [];
					}
					for (i = 1; i < numTexCoords; i++) {
						var texCoordsData:TexCoordsData = texCoordsDatas[i];
						// В массиве uvChannels первый каннал - нулевой индекс
						var channel:Vector.<Point> = geometry.uvChannels[int(i - 1)];
						if (channel == null) {
							channel = new Vector.<Point>(geometry.vertexIdCounter + 1);
							geometry.uvChannels[int(i - 1)] = channel;
							geometry.numAdditionalUVChannels++;
						}
						texCoordsData.channel = channel;
					}
				}
				for each (var vertex:Vertex in vertices) {
					var attributes:Vector.<Number> = vertex._attributes;
					if (attributes != null) {
						// Устанавливаем для вершин attributes[texIndex] в -2, чтобы создался дубликат вершины
						while (vertex != null) {
							attributes = vertex._attributes;
							var numAttributes:int = attributes.length;
							for (i = 0; i < numTexCoords; i++) {
								attributes[i] = -2;
							}
							vertex = vertex.value;
						}
					}
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
					var count:int = indicesList.length()
					for (i = 0; i < count; i++) {
						indices = parseIntsArray(indicesList[i]);
						fillInPolygon(geometry, material, vertices, verticesInput.offset, indices.length/inputsStride, indices, texCoordsDatas);
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
						fillInPolylist(geometry, material, vertices, verticesInput.offset, numPrimitives, indices, vcounts, texCoordsDatas);
					} else {
						fillInPolygon(geometry, material, vertices, verticesInput.offset, numPrimitives, indices, texCoordsDatas);
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
					fillInTriangles(geometry, material, vertices, verticesInput.offset, numPrimitives, indices, texCoordsDatas);
					break;
				}
			}
		}

		private function setUVChannels(geometry:Geometry, vertex:Vertex, texCoordsDatas:Vector.<TexCoordsData>):void {
			var numTexCoords:int = texCoordsDatas.length;
			var attributes:Vector.<Number> = new Vector.<Number>(numTexCoords);
			vertex._attributes = attributes; 
			for (var i:int = 0; i < numTexCoords; i++) {
				var texCoordsData:TexCoordsData = texCoordsDatas[i];
				attributes[i] = texCoordsData.index;
				var index:int = texCoordsData.stride*texCoordsData.index;
				var values:Vector.<Number> = texCoordsData.values;
				var u:Number = values[index];
				var v:Number = 1 - values[int(index + 1)];
				if (i > 0) {
					texCoordsData.channel[vertex.index] = new Point(u, v);
				} else {
					vertex._u = u;
					vertex._v = v;
				}
			}
		}

		/**
		 * Добавляет uv координаты вершине или создает новую вершину, если нельзя добавить в эту.
		 * Новая вершина добавляется в список value этой вершины.
		 * @return вершина с заданными uv координатами
		 */
		private function applyUV(geometry:Geometry, vertex:Vertex, texCoordsDatas:Vector.<TexCoordsData>):Vertex {
			var attributes:Vector.<Number> = vertex._attributes;
			var i:int;
			var numTexCoords:int = texCoordsDatas.length;
			var texCoordsData:TexCoordsData;
			if (attributes == null) {
				// Свободная вершина
				setUVChannels(geometry, vertex, texCoordsDatas);
				return vertex;
			}
			for (i = 0; i < numTexCoords; i++) {
				texCoordsData = texCoordsDatas[i];
				if (attributes[i] != texCoordsData.index) {
					// Ищем дубликат, который соответствует вершине
					while (vertex.value != null) {
						vertex = vertex.value;
						for (i = 0; i < numTexCoords; i++) {
							texCoordsData = texCoordsDatas[i];
							if (vertex._attributes[i] != texCoordsData.index) {
								break;
							}
						}
						if (i == numTexCoords) {
							// Идентичный вертекс
							return vertex;
						}							
					}
					// Последний элемент, создаем дубликат и возвращаем
					var newVertex:Vertex = geometry.addVertex(vertex._x, vertex._y, vertex._z);
					vertex.value = newVertex;
					newVertex.index = geometry.vertexIdCounter;
					// Копируем канналы
					setUVChannels(geometry, newVertex, texCoordsDatas);
					return newVertex;
				}
			}
			// Вертекс уже имеет идентичный маппинг
			return vertex;
		}

		/**
		 * Создает один полигон.
		 */
		private function fillInPolygon(geometry:Geometry, material:Material, vertices:Vector.<Vertex>, verticesOffset:int, numIndices:int, indices:Array, texCoordsDatas:Vector.<TexCoordsData> = null):void {
			var faceVertices:Vector.<Vertex> = new Vector.<Vertex>(numIndices);
			for (var i:int = 0; i < numIndices; i++) {
				var vertex:Vertex = vertices[indices[int(inputsStride*i + verticesOffset)]];
				if (texCoordsDatas != null) {
					var numTexCoordsDatas:int = texCoordsDatas.length;
					for (var t:int = 0; t < numTexCoordsDatas; t++) {
						var texCoords:TexCoordsData = texCoordsDatas[t];
						texCoords.index = indices[int(inputsStride*i + texCoords.offset)];
					}
					vertex = applyUV(geometry, vertex, texCoordsDatas);
				}
				faceVertices[i] = vertex;
			}
			addFaceToGeometry(geometry, faceVertices);
		}

		private function fillInPolylist(geometry:Geometry, material:Material, vertices:Vector.<Vertex>, verticesOffset:int, numFaces:int, indices:Array, vcounts:Array, texCoordsDatas:Vector.<TexCoordsData> = null):void {
			var polyIndex:int = 0;
			for (var i:int = 0; i < numFaces; i++) {
				var count:int = vcounts[i];
				if (count >= 3) {
					var faceVertices:Vector.<Vertex> = new Vector.<Vertex>(count);
					for (var j:int = 0; j < count; j++) {
						var vertexIndex:int = inputsStride*(polyIndex + j);
						var vertex:Vertex = vertices[indices[int(vertexIndex + verticesOffset)]];
						if (texCoordsDatas != null) {
							var numTexCoordsDatas:int = texCoordsDatas.length;
							for (var t:int = 0; t < numTexCoordsDatas; t++) {
								var texCoords:TexCoordsData = texCoordsDatas[t];
								texCoords.index = indices[int(vertexIndex + texCoords.offset)];
							}
							vertex = applyUV(geometry, vertex, texCoordsDatas);
						}
						faceVertices[j] = vertex;
					}
					addFaceToGeometry(geometry, faceVertices);
					polyIndex += count;
				}
			}
		}

		private function fillInTriangles(geometry:Geometry, material:Material, vertices:Vector.<Vertex>, verticesOffset:int, numFaces:int, indices:Array, texCoordsDatas:Vector.<TexCoordsData> = null):void {
			for (var i:int = 0; i < numFaces; i++) {
				var index:int = 3*inputsStride*i;
				var vertexIndex:int = index + verticesOffset;
				var a:Vertex = vertices[indices[int(vertexIndex)]];
				var b:Vertex = vertices[indices[int(vertexIndex + inputsStride)]];
				var c:Vertex = vertices[indices[int(vertexIndex + 2*inputsStride)]];
				if (texCoordsDatas != null) {
					var t:int;
					var texCoords:TexCoordsData;
					var numTexCoordsDatas:int = texCoordsDatas.length;
					for (t = 0; t < numTexCoordsDatas; t++) {
						texCoords = texCoordsDatas[t];
						texCoords.index = indices[int(index + texCoords.offset)];
					}
					a = applyUV(geometry, a, texCoordsDatas);
					for (t = 0; t < numTexCoordsDatas; t++) {
						texCoords = texCoordsDatas[t];
						texCoords.index = indices[int(index + texCoords.offset + inputsStride)];
					}
					b = applyUV(geometry, b, texCoordsDatas);
					for (t = 0; t < numTexCoordsDatas; t++) {
						texCoords = texCoordsDatas[t];
						texCoords.index = indices[int(index + texCoords.offset + 2*inputsStride)];
					}
					c = applyUV(geometry, c, texCoordsDatas);
				}
				addTriFaceToGeometry(geometry, a, b, c);
			}
		}

		private function addTriFaceToGeometry(geometry:Geometry, a:Vertex, b:Vertex, c:Vertex):void {
			var face:Face = new Face();
			var aWrapper:Wrapper = new Wrapper();
			aWrapper.vertex = a;
			var bWrapper:Wrapper = new Wrapper();
			bWrapper.vertex = b;
			var cWrapper:Wrapper = new Wrapper();
			cWrapper.vertex = c;
			aWrapper.next = bWrapper;
			bWrapper.next = cWrapper;
			cWrapper.next = null;
			face.wrapper = aWrapper;
			face.geometry = geometry;
			geometry._faces[int(geometry.faceIdCounter++)] = face;
		}

		private function addFaceToGeometry(geometry:Geometry, value:Vector.<Vertex>):void {
			var face:Face = new Face();
			var last:Wrapper = null;
			for (var i:int = 0, count:int = value.length; i < count; i++) {
				var newWrapper:Wrapper = new Wrapper();
				newWrapper.vertex = value[i];
				if (last != null) {
					last.next = newWrapper;
				} else {
					face.wrapper = newWrapper;
				}
				last = newWrapper;
			}
			face.geometry = geometry;
			geometry._faces[int(geometry.faceIdCounter++)] = face;
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
	import __AS3__.vec.Vector;
	import flash.display.IndexBuffer3D;
	import flash.geom.Point;

class TexCoordsData {
	public var values:Vector.<Number>;
	public var stride:int;
	public var offset:int;
	public var index:int;
	public var channel:Vector.<Point>;

	public function TexCoordsData(values:Vector.<Number>, stride:int, offset:int) {
		this.values = values;
		this.stride = stride;
		this.offset = offset;
	}

}
