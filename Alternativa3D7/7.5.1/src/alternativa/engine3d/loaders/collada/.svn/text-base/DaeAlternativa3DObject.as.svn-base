package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.containers.BSPContainer;
	import alternativa.engine3d.containers.ConflictContainer;
	import alternativa.engine3d.containers.KDContainer;
	import alternativa.engine3d.containers.LODContainer;
	import alternativa.engine3d.containers.DistanceSortContainer;
	import alternativa.engine3d.core.Clipping;
	import alternativa.engine3d.core.Object3DContainer;
	import alternativa.engine3d.core.Sorting;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.objects.Sprite3D;

	import flash.utils.getDefinitionByName;

	/**
	 * @private
	 */
	public class DaeAlternativa3DObject extends DaeElement {
	
		use namespace collada;
		use namespace alternativa3d;
		use namespace daeAlternativa3DLibrary;
		use namespace daeAlternativa3DMesh;
	
		public function DaeAlternativa3DObject(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		private function createObject(className:String):* {
			try {
				var ClassDef:Class = getDefinitionByName(className) as Class;
				return new ClassDef();
			} catch (e:ReferenceError) {
				trace("[ERROR]", e.message);
			}
			return null;
		}
	
		public function parseContainer():Object3DContainer {
			var container:Object3DContainer;
			var classNameXML:XML = data.@className[0];
			switch (data.localName()) {
				case "object3d": {
					if (classNameXML != null) {
						container = createObject(classNameXML.toString());
					} else {
						container = new Object3DContainer();
					}
					return setParams(container);
				}
				case "averageZ": {
					if (classNameXML != null) {
						container = createObject(classNameXML.toString());
					} else {
						container = new DistanceSortContainer();
					}
					return setParams(container);
				}
				case "conflict": {
					if (classNameXML != null) {
						container = createObject(classNameXML.toString());
					} else {
						container = new ConflictContainer();
					}
					return setParams(container);
				}
				case "kdTree": {
					if (classNameXML != null) {
						container = createObject(classNameXML.toString());
					} else {
						container = new KDContainer();
					}
					return setParams(container);
				}
				case "bsp": {
					if (classNameXML != null) {
						container = createObject(classNameXML.toString());
					} else {
						container = new BSPContainer();
					}
					return setParams(container);
				}
			}
			return null;
		}
	
		private function getClippingValue(clipping:XML):int {
			switch (clipping.toString()) {
				case "BOUND_CULLING":
					return Clipping.BOUND_CULLING;
					break;
				case "FACE_CULLING":
					return Clipping.FACE_CULLING;
					break;
				case "FACE_CLIPPING":
					return Clipping.FACE_CLIPPING;
					break;
			}
			return Clipping.BOUND_CULLING;
		}
	
		private function getSortingValue(sorting:XML):int {
			switch (sorting.toString()) {
				case "STATIC_BSP":
					return 3; //Sorting.STATIC_BSP;
					break;
				case "DYNAMIC_BSP":
					return Sorting.DYNAMIC_BSP;
					break;
				case "NONE":
					return Sorting.NONE;
					break;
				case "AVERAGE_Z":
					return Sorting.AVERAGE_Z;
					break;
			}
			return Sorting.NONE;
		}
	
		public function parseSprite3D(material:Material = null):Sprite3D {
			if (data.localName() == "sprite") {
				var sprite:Sprite3D;
				var classNameXML:XML = data.@className[0];
				if (classNameXML != null) {
					sprite = createObject(classNameXML.toString());
					sprite.material = material;
				} else {
					sprite = new Sprite3D(100, 100, material);
				}
				var sortingXML:XML = data.sorting[0];
				var clippingXML:XML = data.clipping[0];
				if (sortingXML != null) {
					sprite.sorting = getSortingValue(sortingXML);
				}
				if (clippingXML != null) {
					sprite.clipping = getClippingValue(clippingXML);
				}
				return setParams(sprite);
			}
			return null;
		}
	
		public function parseMesh(skin:Boolean = false):Mesh {
			if (data.localName() == "mesh") {
				var mesh:Mesh;
				var classNameXML:XML = data.@className[0];
				if (classNameXML != null) {
					mesh = createObject(classNameXML.toString());
				} else {
					mesh = (skin) ? new Skin() : new Mesh();
				}
				var sortingXML:XML = data.sorting[0];
				var clippingXML:XML = data.clipping[0];
				var optimizeXML:XML = data.optimizeBSP[0];
				if (clippingXML != null) {
					mesh.clipping = getClippingValue(clippingXML);
				}
				var optimize:Boolean = (optimizeXML != null) ? optimizeXML.toString() != "false" : true;
				if (sortingXML != null) {
					mesh.sorting = getSortingValue(sortingXML);
					if (optimize) mesh.transformId = 1;
				}
				return setParams(mesh);
			}
			return null;
		}
	
		public function parseLOD():LODContainer {
			if (data.localName() == "lod") {
				var lod:LODContainer;
				var classNameXML:XML = data.@className[0];
				if (classNameXML != null) {
					lod = createObject(classNameXML.toString());
				} else {
					lod = new LODContainer();
				}
				var levels:XMLList = data.level;
				var count:int = levels.length();
				for (var i:int = 0; i < count; i++) {
					var level:XML = levels[i];
					var node:DaeNode = document.findNode(level.@url[0]);
					var child:DaeObject = null;
					if (node != null) {
						if (node.rootJoint != null) {
							node = node.rootJoint;
							node.parse();
							if (node.skins != null) {
								child = node.skins[0];
							}
						} else {
							node.parse();
							if (node.objects != null) {
								child = node.objects[0];
							}
						}
					} else {
						document.logger.logNotFoundError(level.@url[0]);
					}
					if (child != null) {
						child.lodDistance = parseNumber(level.@distance[0]);
					}
				}
				return setParams(lod);
			}
			return new LODContainer();
		}
	
		private function setParams(object:*):* {
			var params:XMLList = data.param;
			for (var i:int = 0, count:int = params.length(); i < count; i++) {
				var param:XML = params[i];
				try {
					var name:String = param.@name[0].toString();
					var value:String = param.text().toString();
					if (value == "true") {
						object[name] = true;
					} else if (value == "false") {
						object[name] = false;
					} else if ((value.charAt(0) == '"' && value.charAt(value.length - 1) == '"') || (value.charAt(0) == "'" && value.charAt(value.length - 1) == "'")) {
						object[name] = value;
					} else {
						if (value.indexOf(".") >= 0) {
							object[name] = parseFloat(value);
						} else if (value.indexOf(",") >= 0) {
							value = value.replace(/,/, ".");
							object[name] = parseFloat(value);
						} else {
							object[name] = parseInt(value);
						}
					}
				} catch (e:Error) {
					trace("[ERROR]", e.message);
				}
			}
			return object;
		}
	
	}
}
