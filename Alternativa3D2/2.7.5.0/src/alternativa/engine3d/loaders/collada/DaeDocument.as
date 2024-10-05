package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.alternativa3d;

	/**
	 * @private
	 */
	public class DaeDocument {
	
		use namespace collada;
		use namespace alternativa3d;
		use namespace daeAlternativa3DLibrary;

		public var scene:DaeVisualScene;
	
		/**
		 * Файл коллады
		 */
		private var data:XML;
	
		// Словари для хранения соответствий id->DaeElement
		internal var sources:Object;
		internal var arrays:Object;
		internal var vertices:Object;
		internal var geometries:Object;
		internal var nodes:Object;
		internal var cameras:Object;
		internal var images:Object;
		internal var effects:Object;
		internal var controllers:Object;
		internal var samplers:Object;
		internal var alternativa3DObjects:Object;
	
		public var materials:Object;
	
		internal var logger:DaeLogger;
	
		public var versionMajor:uint;
		public var versionMinor:uint;
		public var alternativa3DExtensionVersionMajor:uint = 0;
		public var alternativa3DExtensionVersionMinor:uint = 0;
	
		public function DaeDocument(document:XML) {
			this.data = document;
	
			var versionComponents:Array = data.@version[0].toString().split(/[.,]/);
			versionMajor = parseInt(versionComponents[1], 10);
			versionMinor = parseInt(versionComponents[2], 10);
	
			logger = new DaeLogger();
	
			constructStructures();
			constructScenes();
			constructInstanceControllers();
			constructAnimations();
			constructAlternativa3DObjects();
		}
		
		private function isLocalURL(url:String):Boolean {
			return url.charAt(0) == "#";
		}
	
		private function getLocalID(url:XML):String {
			var path:String = url.toString();
			if (isLocalURL(path)) {
				var i:int = path.lastIndexOf("#");
				return (i >= 0) ? path.substring(i + 1) : null;
			} else {
				logger.logExternalError(url);
				return null;
			}
		}
	
		// Ищем объявления всех элементов и заполняем словари
		private function constructStructures():void {
			var element:XML;
	
			sources = new Object();
			arrays = new Object();
			for each (element in data..source) {
				// Собираем все <source>. В конструкторах заполняется словарь arrays
				var source:DaeSource = new DaeSource(element, this);
				if (source.id != null) {
					sources[source.id] = source;
				}
			}
			cameras = new Object();
			for each (element in data.library_cameras.camera) {
				// Собираем все <camera>.
				var camera:DaeCamera = new DaeCamera(element, this);
				if (camera.id != null) {
					cameras[camera.id] = camera;
				}
			}
			images = new Object();
			for each (element in data.library_images.image) {
				// Собираем все <image>.
				var image:DaeImage = new DaeImage(element, this);
				if (image.id != null) {
					images[image.id] = image;
				}
			}
			effects = new Object();
			for each (element in data.library_effects.effect) {
				// Собираем все <effect>. В конструкторах заполняется словарь images
				var effect:DaeEffect = new DaeEffect(element, this);
				if (effect.id != null) {
					effects[effect.id] = effect;
				}
			}
			materials = new Object();
			for each (element in data.library_materials.material) {
				// Собираем все <material>.
				var material:DaeMaterial = new DaeMaterial(element, this);
				if (material.id != null) {
					materials[material.id] = material;
				}
			}
			geometries = new Object();
			vertices = new Object();
			for each (element in data.library_geometries.geometry) {
				// Собираем все <geometry>. В конструкторах заполняется словарь vertices
				var geom:DaeGeometry = new DaeGeometry(element, this);
				if (geom.id != null) {
					geometries[geom.id] = geom;
				}
			}
	
			controllers = new Object();
			for each (element in data.library_controllers.controller) {
				// Собираем все <controllers>
				var controller:DaeController = new DaeController(element, this);
				if (controller.id != null) {
					controllers[controller.id] = controller;
				}
			}
	
			nodes = new Object();
			for each (element in data.library_nodes.node) {
				// Создаем только корневые ноды, остальные создаются рекурсивно в конструкторах
				var node:DaeNode = new DaeNode(element, this);
				if (node.id != null) {
					nodes[node.id] = node;
				}
			}
		}
	
		private function constructInstanceControllers():void {
			for each (var node:DaeNode in nodes) {
				var instanceControllerXML:XML = node.data.instance_controller[0];
				if (instanceControllerXML != null) {
					node.skinOrRootJoint = true;
					var instanceController:DaeInstanceController = new DaeInstanceController(instanceControllerXML, this, node);
					var jointNodes:Vector.<DaeNode> = instanceController.findRootJointNodes();
					var i:int;
					var count:int = jointNodes.length;
					if (count > 0) {
						var jointNode:DaeNode = jointNodes[0];
						jointNode.addInstanceController(instanceController);
						node.rootJoint = jointNode;
						for (i = 0; i < count; i++) {
							jointNodes[i].skinOrRootJoint = true;
						}
					}
				}
			}
		}
		
		private function constructScenes():void {
			var vsceneURL:XML = data.scene.instance_visual_scene.@url[0];
			var vsceneID:String = getLocalID(vsceneURL);
			for each (var element:XML in data.library_visual_scenes.visual_scene) {
				// Создаем visual_scene, в конструкторах создаются node
				var vscene:DaeVisualScene = new DaeVisualScene(element, this);
				if (vscene.id == vsceneID) {
					this.scene = vscene;
				}
			}
			if (vsceneID != null && scene == null) {
				logger.logNotFoundError(vsceneURL);
			}
		}
	
		private function constructAnimations():void {
			var element:XML;
			samplers = new Object();
			for each (element in data.library_animations..sampler) {
				// Собираем все <sampler>
				var sampler:DaeSampler = new DaeSampler(element, this);
				if (sampler.id != null) {
					samplers[sampler.id] = sampler;
				}
			}
	
			for each (element in data.library_animations..channel) {
				var channel:DaeChannel = new DaeChannel(element, this);
				var node:DaeNode = channel.node;
				if (node != null) {
					node.addChannel(channel);
				}
			}
		}
	
		private function constructAlternativa3DObjects():void {
			alternativa3DObjects = new Object();
			var alternativa3dXML:XML = data.extra.technique.(@profile = "Alternativa3D").library[0];
			if (alternativa3dXML != null) {
				var versionComponents:Array = alternativa3dXML.version[0].text().toString().split(/[.,]/);
				alternativa3DExtensionVersionMajor = parseInt(versionComponents[0], 10);
				alternativa3DExtensionVersionMinor = parseInt(versionComponents[1], 10);
				var element:XML;
				var object:DaeAlternativa3DObject;
				for each (element in alternativa3dXML.library_containers.children()) {
					// контейнеры
					object = new DaeAlternativa3DObject(element, this);
					if (object.id != null) {
						alternativa3DObjects[object.id] = object;
					}
				}
				for each (element in alternativa3dXML.library_sprites.sprite) {
					// спрайты
					object = new DaeAlternativa3DObject(element, this);
					if (object.id != null) {
						alternativa3DObjects[object.id] = object;
					}
				}
				for each (element in alternativa3dXML.library_lods.lod) {
					// лоды
					object = new DaeAlternativa3DObject(element, this);
					if (object.id != null) {
						alternativa3DObjects[object.id] = object;
					}
				}
			} else {
				alternativa3DExtensionVersionMajor = alternativa3DExtensionVersionMinor = 0;
			}
		}
	
		public function findArray(url:XML):DaeArray {
			return arrays[getLocalID(url)];
		}
	
		public function findSource(url:XML):DaeSource {
			return sources[getLocalID(url)];
		}
	
		public function findCamera(url:XML):DaeCamera {
			return cameras[getLocalID(url)];
		}
	
		public function findImage(url:XML):DaeImage {
			return images[getLocalID(url)];
		}
	
		public function findImageByID(id:String):DaeImage {
			return images[id];
		}
	
		public function findEffect(url:XML):DaeEffect {
			return effects[getLocalID(url)];
		}
	
		public function findMaterial(url:XML):DaeMaterial {
			return materials[getLocalID(url)];
		}
	
		public function findVertices(url:XML):DaeVertices {
			return vertices[getLocalID(url)];
		}
	
		public function findGeometry(url:XML):DaeGeometry {
			return geometries[getLocalID(url)];
		}
	
		public function findNode(url:XML):DaeNode {
			return nodes[getLocalID(url)];
		}
	
		public function findNodeByID(id:String):DaeNode {
			return nodes[id];
		}
	
		public function findController(url:XML):DaeController {
			return controllers[getLocalID(url)];
		}
	
		public function findSampler(url:XML):DaeSampler {
			return samplers[getLocalID(url)];
		}
	
		public function findAlternativa3DObject(url:XML):DaeAlternativa3DObject {
			return alternativa3DObjects[getLocalID(url)];
		}
	
	}
}
