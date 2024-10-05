package alternativa.engine3d.loaders.collada {
	import alternativa.engine3d.*;
	import alternativa.engine3d.animation.Animation;
	import alternativa.engine3d.animation.AnimationGroup;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.objects.Joint;
	import alternativa.engine3d.objects.Skin;
	
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;

	/**
	 * @private
	 */
	public class DaeController extends DaeElement {
	
		use namespace collada;
		use namespace alternativa3d;
	
		private var jointsBindMatrices:Vector.<Vector.<Number> >;
		private var vcounts:Array;
		private var indices:Array;
		private var jointsInput:DaeInput;
		private var weightsInput:DaeInput;
		private var inputsStride:int;
	
		public function DaeController(data:XML, document:DaeDocument) {
			super(data, document);
	
			// sources мы создаем внутри DaeDocument, здесь не нужно.
		}
	
		override protected function parseImplementation():Boolean {
			var vertexWeightsXML:XML = data.skin.vertex_weights[0];
			if (vertexWeightsXML == null) {
				return false;
			}
			var vcountsXML:XML = vertexWeightsXML.vcount[0];
			if (vcountsXML == null) {
				return false;
			}
			vcounts = parseIntsArray(vcountsXML);
			var indicesXML:XML = vertexWeightsXML.v[0];
			if (indicesXML == null) {
				return false;
			}
			indices = parseIntsArray(indicesXML);
			parseInputs();
			parseJointsBindMatrices();
			return true;
		}
	
		private function parseInputs():void {
			var inputsList:XMLList = data.skin.vertex_weights.input;
			var maxInputOffset:int = 0;
			for (var i:int = 0, count:int = inputsList.length(); i < count; i++) {
				var input:DaeInput = new DaeInput(inputsList[i], document);
				var semantic:String = input.semantic;
				if (semantic != null) {
					switch (semantic) {
						case "JOINT" :
							if (jointsInput == null) {
								jointsInput = input;
							}
							break;
						case "WEIGHT" :
							if (weightsInput == null) {
								weightsInput = input;
							}
							break;
					}
				}
				var offset:int = input.offset;
				maxInputOffset = (offset > maxInputOffset) ? offset : maxInputOffset;
			}
			inputsStride = maxInputOffset + 1;
		}
	
		/**
		 * Парсит инверсные матрицы для костей и сохраняет их в вектор.
		 */
		private function parseJointsBindMatrices():void {
			var jointsXML:XML = data.skin.joints.input.(@semantic == "INV_BIND_MATRIX")[0];
			if (jointsXML != null) {
				var jointsSource:DaeSource = document.findSource(jointsXML.@source[0]);
				if (jointsSource != null) {
					if (jointsSource.parse() && jointsSource.numbers != null && jointsSource.stride >= 16) {
						var stride:int = jointsSource.stride;
						var count:int = jointsSource.numbers.length/stride;
						jointsBindMatrices = new Vector.<Vector.<Number> >(count);
						for (var i:int = 0; i < count; i++) {
							var index:int = stride*i;
							var matrix:Vector.<Number> = new Vector.<Number>(16);
							jointsBindMatrices[i] = matrix;
							for (var j:int = 0; j < 16; j++) {
								matrix[j] = jointsSource.numbers[int(index + j)];
							}
						}
					}
				} else {
					document.logger.logNotFoundError(jointsXML.@source[0]);
				}
			}
		}
	
		private function get geometry():DaeGeometry {
			var geom:DaeGeometry = document.findGeometry(data.skin.@source[0]);
			if (geom == null) {
				document.logger.logNotFoundError(data.@source[0]);
			}
			return geom;
		}
	
		/**
		 * Возвращает геометрию с костями и контроллер для костей.
		 * Перед использованием вызвать parse().
		 */
		public function parseSkin(skinNode:DaeNode, materials:Object, skeletons:Vector.<DaeNode>):DaeAnimatedObject {
			var skinXML:XML = data.skin[0];
			if (skinXML != null) {
				var skin:Skin;
				var geom:DaeGeometry = geometry;
				if (geom != null) {
					geom.parse();
					skin = geom.parseAlternativa3DObject(true) as Skin;
					if (skin == null) {
						skin = new Skin();
					}
					var vertices:Vector.<Vertex> = geom.fillInMesh(skin, materials);
					applyBindShapeMatrix(skin);
					var joints:Vector.<DaeAnimatedObject> = addJointsToSkin(skin, skinNode,  findNodes(skeletons));
					setJointsBindMatrices(joints);
					linkVerticesToJoints(joints, vertices);
					skin.normalizeWeights();
					geom.cleanVertices(skin);
					skin.calculateNormals(true);
					skin.calculateBounds();
					return new DaeAnimatedObject(skin, mergeJointsAnimations(skin, joints));
				} else {
					skin = new Skin();
					skin.calculateNormals(true);
					skin.calculateBounds();
					return new DaeAnimatedObject(skin);
				}
			}
			return null;
		}

		/**
		 * Объединяет анимацию костей в одну анимацию, если требуется
		 */
		private function mergeJointsAnimations(skin:Skin, joints:Vector.<DaeAnimatedObject>):Animation {
			var complex:AnimationGroup = new AnimationGroup(skin);
			for (var i:int = 0, count:int = joints.length; i < count; i++) {
				var animatedObject:DaeAnimatedObject = joints[i];
				if (animatedObject.animation != null) {
					complex.addAnimation(animatedObject.animation);
				}
			}
			return (complex.numAnimations > 0) ? complex : null;
		}

		/**
		 * Задает костям их инверсные матрицы.
		 */
		private function setJointsBindMatrices(animatedJoints:Vector.<DaeAnimatedObject>):void {
			for (var i:int = 0, count:int = jointsBindMatrices.length; i < count; i++) {
				var animatedJoint:DaeAnimatedObject = animatedJoints[i];
				var bindMatrix:Vector.<Number> = jointsBindMatrices[i];
				Joint(animatedJoint.object).setBindingMatrix(bindMatrix[0], bindMatrix[1], bindMatrix[2], bindMatrix[3],
						bindMatrix[4], bindMatrix[5], bindMatrix[6], bindMatrix[7],
						bindMatrix[8], bindMatrix[9], bindMatrix[10], bindMatrix[11]);
			}
		}
		
		/**
		 * Связывает вершину и все ее дубликаты с костью
		 */
		private function linkVertexToJoint(joint:Joint, vertex:Vertex, weight:Number):void {
			joint.bindVertex(vertex, weight);
			// Цепляем дубликаты
			while ((vertex = vertex.value) != null) {
				joint.bindVertex(vertex, weight);
			}
		}
	
		/**
		 * Связывает вершины с костями
		 */
		private function linkVerticesToJoints(animatedJoints:Vector.<DaeAnimatedObject>, vertices:Vector.<Vertex>):void {
			var jointsOffset:int = jointsInput.offset;
			var weightsOffset:int = weightsInput.offset;
			var weightsSource:DaeSource = weightsInput.prepareSource(1);
			var weights:Vector.<Number> = weightsSource.numbers;
			var weightsStride:int = weightsSource.stride;
			var vertexIndex:int = 0;
			for (var i:int = 0, numVertices:int = vertices.length; i < numVertices; i++) {
				var vertex:Vertex = vertices[i];
				var count:int = vcounts[i];
				for (var j:int = 0; j < count; j++) {
					var index:int = inputsStride*(vertexIndex + j);
					var jointIndex:int = indices[int(index + jointsOffset)];
					if (jointIndex >= 0) {
						var weightIndex:int = indices[int(index + weightsOffset)];
						var weight:Number = weights[int(weightsStride*weightIndex)];
						linkVertexToJoint(Joint(animatedJoints[jointIndex].object), vertex, weight);
					}
				}
				vertexIndex += count;
			}
		}
	
		/**
		 * Создает иерархию костей и добавляет к скину.
		 *
		 * @return вектор добавленых к скину костей с анимацией.
		 * Если были добавлены вспомогательные кости, длина вектора будет отличаться от длины вектора nodes 
		 */
		private function addJointsToSkin(skin:Skin, skinNode:DaeNode, nodes:Vector.<DaeNode>):Vector.<DaeAnimatedObject> {
			// Словарь, в котором ключ-нода, значение-позиция в векторе nodes
			var nodesDictionary:Dictionary = new Dictionary();
			var count:int = nodes.length;
			var i:int;
			for (i = 0; i < count; i++) {
				nodesDictionary[nodes[i]] = i;
			}
			var animatedJoints:Vector.<DaeAnimatedObject> = new Vector.<DaeAnimatedObject>(count);
			for (i = 0; i < count; i++) {
				var node:DaeNode = nodes[i];
				if (isRootJointNode(node, nodesDictionary)) {
					var animatedJoint:DaeAnimatedObject = addRootJointToSkin(skin, skinNode, node);
					if (animatedJoint != null) {
						animatedJoints[i] = animatedJoint;
						addJointChildren(Joint(animatedJoint.object), animatedJoints, node, nodesDictionary);
					}
				}
			}
			return animatedJoints;
		}
	
		/**
		 * Возвращает <code>true</code> если у кости нет родительской кости
		 * @param node нода кости
		 * @param nodes словарь, в котором ключи это ноды всех костей
		 */
		private function isRootJointNode(node:DaeNode, nodes:Dictionary):Boolean {
			for (var parent:DaeNode = node.parent; parent != null; parent = parent.parent) {
				if (parent in nodes) {
					return false;
				}
			}
			return true;
		}
	
		/**
		 * Добавляет рутовую кость к скину
		 */
		private function addRootJointToSkin(skin:Skin, skinNode:DaeNode, node:DaeNode):DaeAnimatedObject {
			var joint:Joint;
			if (skinNode == node) {
				// Кость и является скином
				joint = new Joint();
				joint.name = node.name;
				skin.addJoint(joint);
				return new DaeAnimatedObject(joint);
			} else {
				if (node.scene == skinNode.scene) {
					var parent:DaeNode = node.parent;
					var toSceneMatrix:Matrix3D;
					if (parent != null) {
						// Считаем матрицу перевода кости в сцену
						toSceneMatrix = parent.getMatrix();
						while ((parent = parent.parent) != null) {
							toSceneMatrix.append(parent.getMatrix());
						}
					}
					// Считаем матрицу перевода локального пространства скина в сцену
					var skinMatrix:Matrix3D = skinNode.getMatrix();
					for (parent = skinNode.parent; parent != null; parent = parent.parent) {
						skinMatrix.append(parent.getMatrix());
					}
					skinMatrix.invert();
					// Считаем матрицу перевода в скин
					var toSkinMatrix:Matrix3D;
					if (toSceneMatrix != null) {
						toSkinMatrix = toSceneMatrix;
						toSkinMatrix.append(skinMatrix);
					} else {
						toSkinMatrix = skinMatrix;
					}
					// Если кость анимирована, создаем вспомогательную кость перевода в скин
					var additionalJoint:Joint = new Joint();
					additionalJoint.setMatrix(toSkinMatrix);
					skin.addJoint(additionalJoint);
					joint = new Joint();
					joint.name = node.name;
					additionalJoint.addJoint(joint);
					return node.applyAnimation(node.applyTransformations(joint));
				} else {
					// Не обрабатывается
					document.logger.logJointInAnotherSceneError(node.data);
					return null;
				}
			}
		}

		/**
		 * Создает иерархию дочерних костей и добавляет к родительской кости.
		 *
		 * @param parent родительская кость
		 * @param animatedJoints вектор костей в который положить созданные кости.
		 * В конец вектора будут добавлены вспомогательные кости, если понадобятся.
		 * @param parentNode нода родительской кости
		 * @param nodes словарь, в котором ключ это нода кости, а значение это индекс кости в векторе animatedJoints
		 */
		private function addJointChildren(parent:Joint, animatedJoints:Vector.<DaeAnimatedObject>, parentNode:DaeNode, nodes:Dictionary):void {
			var children:Vector.<DaeNode> = parentNode.nodes;
			for (var i:int = 0, count:int = children.length; i < count; i++) {
				var child:DaeNode = children[i];
				var joint:Joint;
				if (child in nodes) {
					joint = new Joint();
					joint.name = child.name;
					animatedJoints[nodes[child]] = child.applyAnimation(child.applyTransformations(joint));
					parent.addJoint(joint);
					addJointChildren(joint, animatedJoints, child, nodes);
				} else {
					// Нода не является костью
					if (hasJointInDescendants(child, nodes)) {
						// Если среди ее потомков есть кость, нужно создать вспомогательную кость вместо этой ноды.
						joint = new Joint();
						joint.name = child.name;
						// Добавляем в конец новую кость
						animatedJoints.push(child.applyAnimation(child.applyTransformations(joint)));
						parent.addJoint(joint);
						addJointChildren(joint, animatedJoints, child, nodes);
					}
				}
			}
		}

		private function hasJointInDescendants(parentNode:DaeNode, nodes:Dictionary):Boolean {
			var children:Vector.<DaeNode> = parentNode.nodes;
			for (var i:int = 0, count:int = children.length; i < count; i++) {
				var child:DaeNode = children[i];
				if (child in nodes || hasJointInDescendants(child, nodes)) {
					return true;
				}
			}
			return false;
		}
	
		/**
		 * Трансформирует все вершины объекта при помощи BindShapeMatrix из коллады
		 */
		private function applyBindShapeMatrix(skin:Skin):void {
			var matrixXML:XML = data.skin.bind_shape_matrix[0];
			if (matrixXML != null) {
				var matrix:Array = parseNumbersArray(matrixXML);
				if (matrix.length >= 16) {
					var a:Number = matrix[0];
					var b:Number = matrix[1];
					var c:Number = matrix[2];
					var d:Number = matrix[3];
					var e:Number = matrix[4];
					var f:Number = matrix[5];
					var g:Number = matrix[6];
					var h:Number = matrix[7];
					var i:Number = matrix[8];
					var j:Number = matrix[9];
					var k:Number = matrix[10];
					var l:Number = matrix[11];
					for (var vertex:Vertex = skin.vertexList; vertex != null; vertex = vertex.next) {
						var x:Number = vertex.x;
						var y:Number = vertex.y;
						var z:Number = vertex.z;
						vertex.x = a*x + b*y + c*z + d;
						vertex.y = e*x + f*y + g*z + h;
						vertex.z = i*x + j*y + k*z + l;
					}
				}
			}
		}
	
		public function findRootJointNodes(skeletons:Vector.<DaeNode>):Vector.<DaeNode> {
			var nodes:Vector.<DaeNode> = findNodes(skeletons);
			var i:int = 0;
			var count:int = nodes.length;
			if (count > 0) {
				var nodesDictionary:Dictionary = new Dictionary();
				for (i = 0; i < count; i++) {
					nodesDictionary[nodes[i]] = i;
				}
				var rootNodes:Vector.<DaeNode> = new Vector.<DaeNode>();
				for (i = 0; i < count; i++) {
					var node:DaeNode = nodes[i];
					if (isRootJointNode(node, nodesDictionary)) {
						rootNodes.push(node);
					}
				}
				return rootNodes;
			}
			return null;
		}
	
		/**
		 * Находит ноду по ее сиду в векторе скелетов
		 */
		private function findNode(nodeName:String, skeletons:Vector.<DaeNode>):DaeNode {
			var count:int = skeletons.length;
			for (var i:int = 0; i < count; i++) {
				var node:DaeNode = skeletons[i].getNodeBySid(nodeName);
				if (node != null) {
					return node;
				}
			}
			return null;
		}
	
		/**
		 * Возвращает вектор нод костей.
		 */
		private function findNodes(skeletons:Vector.<DaeNode>):Vector.<DaeNode> {
			var jointsXML:XML = data.skin.joints.input.(@semantic == "JOINT")[0];
			if (jointsXML != null) {
				var jointsSource:DaeSource = document.findSource(jointsXML.@source[0]);
				if (jointsSource != null) {
					if (jointsSource.parse() && jointsSource.names != null) {
						var stride:int = jointsSource.stride;
						var count:int = jointsSource.names.length/stride;
						var nodes:Vector.<DaeNode> = new Vector.<DaeNode>(count);
						for (var i:int = 0; i < count; i++) {
							var node:DaeNode = findNode(jointsSource.names[int(stride*i)], skeletons);
							if (node == null) {
								// Ошибка, нет ноды
							}
							nodes[i] = node;
						}
						return nodes;
					}
				} else {
					document.logger.logNotFoundError(jointsXML.@source[0]);
				}
			}
			return null;
		}
	
	}
}
