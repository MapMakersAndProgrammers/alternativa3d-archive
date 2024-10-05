package alternativa.engine3d.loaders.collada {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.Animation;
	import alternativa.engine3d.animation.MatrixAnimation;
	import alternativa.engine3d.animation.TransformAnimation;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	 * @private
	 */
	public class DaeNode extends DaeElement {
	
		use namespace collada;
		use namespace alternativa3d;

		public var scene:DaeVisualScene;
		public var parent:DaeNode;

		// Скин или рутовая кость
		public var skinOrRootJoint:Boolean = false;
		// Ссылка на рутовую кость скина, если есть
		public var rootJoint:DaeNode;

		/**
		 * Анимационные каналы этой ноды
		 */
		private var channels:Vector.<DaeChannel>;

		/**
		 * Вектор контроллеров, которые ссылаются на эту ноду
		 */
		private var instanceControllers:Vector.<DaeInstanceController>;

		/**
		 * Массив нод в этой ноде.
		 */
		public var nodes:Vector.<DaeNode>;
	
		/**
		 * Массив объектов в этой ноде.
		 * Перед использованием вызвать parse().
		 */
		public var objects:Vector.<DaeObject>;

		/**
		 * Вектор скинов в этой ноде.
		 * Перед использованием вызвать parse().
		 */
		public var skins:Vector.<DaeObject>;

		/**
		 * Создание ноды из xml. Рекурсивно создаются дочерние ноды.
		 */
		public function DaeNode(data:XML, document:DaeDocument, scene:DaeVisualScene = null, parent:DaeNode = null) {
			super(data, document);
	
			this.scene = scene;
			this.parent = parent;
	
			// Внутри <node> объявляются другие node.
			constructNodes();
		}

		private function constructNodes():void {
			var nodesList:XMLList = data.node;
			var count:int = nodesList.length();
			nodes = new Vector.<DaeNode>(count);
			for (var i:int = 0; i < count; i++) {
				var node:DaeNode = new DaeNode(nodesList[i], document, scene, this);
				if (node.id != null) {
					document.nodes[node.id] = node;
				}
				nodes[i] = node;
			}
		}

		public function addChannel(channel:DaeChannel):void {
			if (channels == null) {
				channels = new Vector.<DaeChannel>();
			}
			channels.push(channel);
		}

		public function addInstanceController(controller:DaeInstanceController):void {
			if (instanceControllers == null) {
				instanceControllers = new Vector.<DaeInstanceController>();
			}
			instanceControllers.push(controller);
		}

		override protected function parseImplementation():Boolean {
			this.skins = parseSkins();
			this.objects = parseObjects();
			return true;
		}

		private function parseInstanceMaterials(geometry:XML):Object {
			var instances:Object = new Object();
			var list:XMLList = geometry.bind_material.technique_common.instance_material;
			for (var i:int = 0, count:int = list.length(); i < count; i++) {
				var instance:DaeInstanceMaterial = new DaeInstanceMaterial(list[i], document);
				instances[instance.symbol] = instance;
			}
			return instances;
		}

		/**
		 * Возвращает ноду по сиду.
		 */
		public function getNodeBySid(sid:String):DaeNode {
			if (sid == this.sid) {
				return this;
			}

			var levelNodes:Vector.<Vector.<DaeNode> > = new Vector.<Vector.<DaeNode> >;
			var levelNodes2:Vector.<Vector.<DaeNode> > = new Vector.<Vector.<DaeNode> >;

			levelNodes.push(nodes);
			var len:int = levelNodes.length;
			while (len > 0) {
				for (var i:int = 0; i < len; i++) {
					var children:Vector.<DaeNode> = levelNodes[i];
					var count:int = children.length;
					for (var j:int = 0; j < count; j++) {
						var node:DaeNode = children[j];
						if (node.sid == sid) {
							return node;
						}
						if (node.nodes.length > 0) {
							levelNodes2.push(node.nodes);
						}
					}
				}
				var temp:Vector.<Vector.<DaeNode> > = levelNodes;
				levelNodes = levelNodes2;
				levelNodes2 = temp;
				levelNodes2.length = 0;

				len = levelNodes.length;
			}
			return null;
		}

		/**
		 * Парсит и возвращает массив скинов, связанных с этой нодой.
		 */
		public function parseSkins():Vector.<DaeObject> {
			if (instanceControllers == null) {
				return null;
			}
			var skins:Vector.<DaeObject> = new Vector.<DaeObject>();
			for (var i:int = 0, count:int = instanceControllers.length; i < count; i++) {
				var instanceController:DaeInstanceController = instanceControllers[i];
				instanceController.parse();
				var skinAndAnimatedJoints:DaeObject = instanceController.parseSkin(parseInstanceMaterials(instanceController.data));
				if (skinAndAnimatedJoints != null) {
					var skin:Skin = Skin(skinAndAnimatedJoints.object);
					// Имя берем из ноды, содержащей instance_controller
					skin.name = instanceController.node.name;
					// По новой схеме не применяем трансформаций и анимацию к скину. Все это задается в рутовых костях
					skins.push(skinAndAnimatedJoints);
				}
			}
			return (skins.length > 0) ? skins : null;
		}

		/**
		 * Парсит и возвращает массив объектов, связанных с этой нодой.
		 * Может быть Mesh или Object3D, если неизвестен тип объекта.
		 */
		public function parseObjects():Vector.<DaeObject> {
			var objects:Vector.<DaeObject> = new Vector.<DaeObject>();
			var children:XMLList = data.children();
			for (var i:int = 0, count:int = children.length(); i < count; i++) {
				var child:XML = children[i];
				switch (child.localName()) {
					case "instance_geometry":
						var geom:DaeGeometry = document.findGeometry(child.@url[0]);
						if (geom != null) {
							geom.parse();
//							var mesh:Mesh = geom.parseMesh(parseInstanceMaterials(child));
//							if (mesh != null) {
//								mesh.name = name;
//								objects.push(applyAnimation(applyTransformations(mesh)));
//							}
							var meshes:Vector.<Mesh> = geom.parseByPrimitives(parseInstanceMaterials(child));
							for (var j:int = 0; j < meshes.length; j++) {
								var mesh:Mesh = meshes[j];
								mesh.name = name;
								objects.push(applyAnimation(applyTransformations(mesh)));
							}
						} else {
							document.logger.logNotFoundError(child.@url[0]);
						}
						break;
					//case "instance_controller":
						// Парсится в методе parseSkins();
					//	break;
					case "instance_node":
						document.logger.logInstanceNodeError(child);
						break;
				}
			}
			return (objects.length > 0) ? objects : null;
		}

		/**
		 * Возвращает трансформацию ноды в виде матрицы
		 * 
		 * @param initialMatrix матрица, к которой будет добавлена трансформация ноды
		 */
		public function getMatrix(initialMatrix:Matrix3D = null):Matrix3D {
			var matrix:Matrix3D = (initialMatrix == null) ? new Matrix3D() : initialMatrix;
			var components:Array;
			var children:XMLList = data.children();
			for (var i:int = children.length() - 1; i >= 0; i--) {
				// Трансформации накладываются с конца в начало
				var child:XML = children[i];
				var sid:XML = child.@sid[0];
				if (sid != null && sid.toString() == "post-rotationY") {
					// Стандартный экспорт макса записал какой-то хлам, игнорируем
					continue;
				}
				switch (child.localName()) {
					case "scale" : {
						components = parseNumbersArray(child);
						matrix.appendScale(components[0], components[1], components[2]);
						break;
					}
					case "rotate" : {
						components = parseNumbersArray(child);
						matrix.appendRotation(components[3], new Vector3D(components[0], components[1], components[2]));
						break;
					}
					case "translate" : {
						components = parseNumbersArray(child);
						matrix.appendTranslation(components[0], components[1], components[2]);
						break;
					}
					case "matrix" : {
						components = parseNumbersArray(child);
						matrix.append(new Matrix3D(Vector.<Number>([components[0], components[4], components[8],  components[12],
							components[1], components[5], components[9],  components[13],
							components[2], components[6], components[10], components[14],
							components[3] ,components[7], components[11], components[15]])));
						break;
					}
					case "lookat" : {
						//						components = parseNumbersArray(child);
						break;
					}
					case "skew" : {
						document.logger.logSkewError(child);
						break;
					}
				}
			}
			return matrix;
		}

		/**
		 * Назначает контроллер анимации к объекту.
		 *
		 * @param animation анимация которую следует применить к объекту,
		 * если <code>null</code>, будет создана новая анимация из ноды.
		 */
		public function applyAnimation(object:Object3D, animation:Animation = null):DaeObject {
			animation = (animation == null) ? parseAnimation() : animation;
			if (animation != null) {
				animation.object = object;
			}
			return new DaeObject(object, animation);
		}

		/**
		 * Применяет трансформацию к объекту.
		 *
		 * @param prepend если не равен <code>null</code>, трансформация добавляется к этой матрице.
		 */
		public function applyTransformations(object:Object3D, prepend:Matrix3D = null, append:Matrix3D = null):Object3D {
			var matrix:Matrix3D = getMatrix(prepend);
			if (append != null) {
				matrix.append(append);
			}
			var v:Vector.<Vector3D> = matrix.decompose();
			object.x = v[0].x;
			object.y = v[0].y;
			object.z = v[0].z;
			object.rotationX = v[1].x;
			object.rotationY = v[1].y;
			object.rotationZ = v[1].z;
			object.scaleX = v[2].x;
			object.scaleY = v[2].y;
			object.scaleZ = v[2].z;
			return object;
		}

		/**
		 * Возвращает анимацию ноды.
		 */
		public function parseAnimation():Animation {
			if (channels == null) {
				return null;
			}
			var channel:DaeChannel = channels[0];
			channel.parse();
			if (channel.animatedParam == DaeChannel.PARAM_MATRIX) {
				// Анимация матрицы
				var matrixAnimation:MatrixAnimation = new MatrixAnimation();
				matrixAnimation.matrix = channel.track;
				return matrixAnimation;
			}
			// Это не анимация матрицы, значит покомпонентная анимация
			var animation:TransformAnimation = new TransformAnimation();
			var count:int = channels.length;
			for (var i:int = 0; i < count; i++) {
				channel = channels[i];
				channel.parse();
				switch (channel.animatedParam) {
					case DaeChannel.PARAM_TRANSLATE:
						animation.translation = channel.track;
						break;
					case DaeChannel.PARAM_TRANSLATE_X:
						animation.x = channel.track;
						break;
					case DaeChannel.PARAM_TRANSLATE_Y:
						animation.y = channel.track;
						break;
					case DaeChannel.PARAM_TRANSLATE_Z:
						animation.z = channel.track;
						break;
					case DaeChannel.PARAM_ROTATION_X:
						animation.rotationX = channel.track;
						break;
					case DaeChannel.PARAM_ROTATION_Y:
						animation.rotationY = channel.track;
						break;
					case DaeChannel.PARAM_ROTATION_Z:
						animation.rotationZ = channel.track;
						break;
					case DaeChannel.PARAM_SCALE:
						animation.scale = channel.track;
						break;
					case DaeChannel.PARAM_SCALE_X:
						animation.scaleX = channel.track;
						break;
					case DaeChannel.PARAM_SCALE_Y:
						animation.scaleY = channel.track;
						break;
					case DaeChannel.PARAM_SCALE_Z:
						animation.scaleZ = channel.track;
						break;
				}
			}
			return animation;
		}

        public function get layer():String {
            var layerXML:XML = data.@layer[0];
			return (layerXML == null) ? null : layerXML.toString();
        }

	}
}
