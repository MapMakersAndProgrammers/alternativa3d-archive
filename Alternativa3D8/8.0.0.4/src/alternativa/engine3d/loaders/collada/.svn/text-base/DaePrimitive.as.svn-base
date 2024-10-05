package alternativa.engine3d.loaders.collada {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.materials.Material;
	
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class DaePrimitive extends DaeElement {

		use namespace collada;

		private var verticesInput:DaeInput;
		private var texCoordsInputs:Vector.<DaeInput>;
		private var normalsInput:DaeInput;
		private var normals:Vector.<Number>;
		private var normalsStride:int;
		private var biNormalsInputs:Vector.<DaeInput>;
		private var tangentsInputs:Vector.<DaeInput>;
		private var biNormalsInput:DaeInput;
		private var tangentsInput:DaeInput;
		private var biNormals:Vector.<Number>;
		private var biNormalsStride:int;
		private var tangents:Vector.<Number>;
		private var tangentsStride:int; 
		
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
			tangentsInputs = new Vector.<DaeInput>();
			biNormalsInputs = new Vector.<DaeInput>();
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
						case "NORMAL":
							if (normalsInput == null) {
								normalsInput = input;
							}
							break;	
						case "TEXTANGENT":
							tangentsInputs.push(input);
							break;
						case "TEXBINORMAL":
							biNormalsInputs.push(input);
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
					var data:TexCoordsData = new TexCoordsData(texCoordsSource.numbers, texCoordsSource.stride, texCoordsInput.offset, texCoordsInput.setNum);
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
				
				// Находим тангенты и бинормали для основного канала
				if (biNormalsInputs.length > 0 && tangentsInputs.length > 0) {
					var mainSet:int = (texCoordsDatas[0]  as TexCoordsData).inputSet;
					var bt:DaeInput;
					var bn:DaeInput;
					for (i = 0; i < numTexCoords;i++) {
						bn = biNormalsInputs[i]; 
						if (bn.setNum == mainSet) {
							biNormalsInput = bn;
						}
						bt = tangentsInputs[i]; 
						if (bt.setNum == mainSet) {
							tangentsInput = bt;
						}
						if (tangentsInput && biNormalsInput) {
							break;
						}
					}
					
					if (biNormalsInput == null || tangentsInput == null) {
						biNormalsInput = biNormalsInputs[0];
						tangentsInput = tangentsInputs[0];
					}
					
					var biTangentsSource:DaeSource = tangentsInput.prepareSource(3);
					var biNormalsSource:DaeSource = biNormalsInput.prepareSource(3);
					tangents = biTangentsSource.numbers;
					tangentsStride = biTangentsSource.stride;
					biNormals = biNormalsSource.numbers;
					biNormalsStride = biNormalsSource.stride;
					geometry.hasTangents = true;
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
			
//			var normals:Vector.<Vector3D>;
			if (normalsInput) {
//				normals = fillNormals(normalsInput.prepareSource(3));
//				geometry.needCalculateNormals = false;
				var normalsSource:DaeSource = normalsInput.prepareSource(3);
				normals = normalsSource.numbers;
				normalsStride = normalsSource.stride;
				geometry.hasNormals = true;
			}
			
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
					if (normalsInput) {
						newVertex.normal = vertex.normal.clone();
						if (tangentsInput) {
							newVertex.tangent = vertex.tangent.clone();
						}
					}
					
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
				var index:int = inputsStride*i;
				var vertex:Vertex = vertices[indices[int(index + verticesOffset)]];
				if (normalsInput && vertex.normal == null) {
					var normalIndex:int = indices[index + normalsInput.offset]*normalsStride;
					vertex.normal = new Vector3D(normals[normalIndex], normals[normalIndex + 1], normals[normalIndex + 2]);
				}
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
						if (normalsInput && vertex.normal == null) {
							var normalIndex:int = indices[vertexIndex + normalsInput.offset]*normalsStride;
							vertex.normal = new Vector3D(normals[normalIndex], normals[normalIndex + 1], normals[normalIndex + 2]);
						}
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
		
		private function fillBiNormalDirectional(normal:Vector3D, tangent:Vector3D, biNormalX:Number, biNormalY:Number, biNormalZ:Number):void {
			var crossX:Number = normal.y*tangent.z - normal.z*tangent.y;
			var crossY:Number = normal.z*tangent.x - normal.x*tangent.z;
			var crossZ:Number = normal.x*tangent.y - normal.y*tangent.x;
    		var dot:Number = crossX*biNormalX + crossY*biNormalY + crossZ*biNormalZ;
    		tangent.w = dot < 0 ? -1 : 1;
		}

		private function fillInTriangles(geometry:Geometry, material:Material, vertices:Vector.<Vertex>, verticesOffset:int, numFaces:int, indices:Array, texCoordsDatas:Vector.<TexCoordsData> = null):void {
			
			for (var i:int = 0; i < numFaces; i++) {
				var index:int = 3*inputsStride*i;
				var vertexIndex:int = index + verticesOffset;
				var a:Vertex = vertices[indices[int(vertexIndex)]];
				var b:Vertex = vertices[indices[int(vertexIndex + inputsStride)]];
				var c:Vertex = vertices[indices[int(vertexIndex + 2*inputsStride)]];
				
				if (normalsInput) {
					var normalIndex:int = index + normalsInput.offset;
					var nIndex:int;
					if (a.normal == null) {
						nIndex = indices[normalIndex]*normalsStride;
						a.normal = new Vector3D(normals[nIndex], normals[nIndex + 1], normals[nIndex + 2]);
					}
					if (b.normal == null) {
						nIndex = indices[normalIndex + inputsStride]*normalsStride;
						b.normal = new Vector3D(normals[nIndex], normals[nIndex + 1], normals[nIndex + 2]);
					}
					if (c.normal == null) {
						nIndex = indices[normalIndex + 2*inputsStride]*normalsStride;
						c.normal = new Vector3D(normals[nIndex], normals[nIndex + 1], normals[nIndex + 2]);
					}
					
//					if (a.normal == null || b.normal == null || c.normal == null) {
//						trace("NRM:");
//					}
						
					if (tangentsInput && biNormalsInput) {
						var tangentIndex:int = index + tangentsInput.offset;
						var btIndex:int;
						var biNormalIndex:int = index + biNormalsInput.offset;
						var bnIndex:int;
						
						if (a.tangent == null) {
							btIndex = indices[tangentIndex]*tangentsStride;
							a.tangent = new Vector3D(tangents[btIndex], tangents[btIndex + 1], tangents[btIndex + 2]);
							bnIndex = indices[biNormalIndex]*biNormalsStride;
							fillBiNormalDirectional(a.normal, a.tangent, biNormals[bnIndex], biNormals[bnIndex + 1], biNormals[bnIndex + 2]);  
						}
						
						if (b.tangent == null) {
							btIndex = indices[tangentIndex + inputsStride]*tangentsStride;
							b.tangent = new Vector3D(tangents[btIndex], tangents[btIndex + 1], tangents[btIndex + 2]);
							bnIndex = indices[biNormalIndex + inputsStride]*biNormalsStride;
							fillBiNormalDirectional(b.normal, b.tangent, biNormals[bnIndex], biNormals[bnIndex + 1], biNormals[bnIndex + 2]);
						}
						
						if (c.tangent == null) {
							btIndex = indices[tangentIndex + 2*inputsStride]*tangentsStride;
							c.tangent = new Vector3D(tangents[btIndex], tangents[btIndex + 1], tangents[btIndex + 2]);
							bnIndex = indices[biNormalIndex + 2*inputsStride]*biNormalsStride;
							fillBiNormalDirectional(c.normal, c.tangent, biNormals[bnIndex], biNormals[bnIndex + 1], biNormals[bnIndex + 2]);
						}
					}
				}
				
				
				
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
	import flash.geom.Point;

class TexCoordsData {
	public var values:Vector.<Number>;
	public var stride:int;
	public var offset:int;
	public var index:int;
	public var channel:Vector.<Point>;
	public var inputSet:int;

	public function TexCoordsData(values:Vector.<Number>, stride:int, offset:int, inputSet:int) {
		this.values = values;
		this.stride = stride;
		this.offset = offset;
		this.inputSet = inputSet;
	}

}
