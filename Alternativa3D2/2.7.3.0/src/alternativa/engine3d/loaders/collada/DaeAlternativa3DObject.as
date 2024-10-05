package alternativa.engine3d.loaders.collada {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.containers.ConflictContainer;
	import alternativa.engine3d.containers.KDTree;
	import alternativa.engine3d.containers.ZSortContainer;
	import alternativa.engine3d.core.Clipping;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	import alternativa.engine3d.core.Sorting;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.LOD;
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
						container = new ZSortContainer();
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
						container = new KDTree();
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
					return Sorting.STATIC_BSP;
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
				} else {
					sprite = new Sprite3D();
				}
				sprite.material = material;
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
					if (mesh.sorting == Sorting.STATIC_BSP) {
						mesh.calculateBSP(optimize);
					} else if (mesh.sorting == Sorting.DYNAMIC_BSP && optimize) {
						mesh.optimizeForDynamicBSP();
					}
				}
				return setParams(mesh);
			}
			return null;
		}
	
		public function parseLOD():LOD {
			if (data.localName() == "LOD" || data.localName() == "lod") {
				var lod:LOD;
				var classNameXML:XML = data.@className[0];
				if (classNameXML != null) {
					lod = createObject(classNameXML.toString());
				} else {
					lod = new LOD();
				}
				var levels:XMLList = data.level;
				var count:int = levels.length();
				var distances:Vector.<Number> = lod.lodDistances = new Vector.<Number>(count);
				var objects:Vector.<Object3D> = lod.lodObjects = new Vector.<Object3D>(count);
				for (var i:int = 0; i < count; i++) {
					var level:XML = levels[i];
					distances[i] = parseNumber(level.@distance[0]);
					var node:DaeNode = document.findNode(level.@url[0]);
					if (node != null) {
						if (node.rootJoint != null) {
							node = node.rootJoint;
							node.parse();
							if (node.skins.length > 0) {
								objects[i] = node.skins[0].object;
							}
						} else {
							if (node.objects.length > 0) {
								objects[i] = node.objects[0].object;
							}
						}
					} else {
						document.logger.logNotFoundError(level.@url[0]);
					}
				}
				return setParams(lod);
			}
			return new LOD();
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
