package alternativa.engine3d.loaders.collada {
	import alternativa.engine3d.materials.CommonMaterial;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.TextureMaterial;

	/**
	 * @private
	 */
	public class DaeEffect extends DaeElement {
		
		public static var commonAlways:Boolean = false;
		
		use namespace collada;
	
		private var effectParams:Object;
		private var commonParams:Object;
		private var techniqueParams:Object;
	
		private var diffuse:DaeEffectParam;
		private var transparent:DaeEffectParam;
		private var transparency:DaeEffectParam;
		private var bump:DaeEffectParam;
		private var emission:DaeEffectParam;
		private var specular:DaeEffectParam;
	
		public function DaeEffect(data:XML, document:DaeDocument) {
			super(data, document);
	
			// Внтри <effect> объявляются image.
			constructImages();
		}
	
		private function constructImages():void {
			var list:XMLList = data..image;
			for each (var element:XML in list) {
				var image:DaeImage = new DaeImage(element, document);
				if (image.id != null) {
					document.images[image.id] = image;
				}
			}
		}
	
		override protected function parseImplementation():Boolean {
			var element:XML;
			var param:DaeParam;
			effectParams = new Object();
			for each (element in data.newparam) {
				param = new DaeParam(element, document);
				effectParams[param.sid] = param;
			}
			commonParams = new Object();
			for each (element in data.profile_COMMON.newparam) {
				param = new DaeParam(element, document);
				commonParams[param.sid] = param;
			}
			techniqueParams = new Object();
			var technique:XML = data.profile_COMMON.technique[0];
			if (technique != null) {
				for each (element in technique.newparam) {
					param = new DaeParam(element, document);
					techniqueParams[param.sid] = param;
				}
			}
			var shader:XML = data.profile_COMMON.technique.*.(localName() == "constant" || localName() == "lambert" || localName() == "phong" || localName() == "blinn")[0];
			if (shader != null) {
				var diffuseXML:XML = null;
				if (shader.localName() == "constant") {
					diffuseXML = shader.emission[0];
				} else {
					diffuseXML = shader.diffuse[0];
					var emissionXML:XML = shader.emission[0];
					if (emissionXML != null) {
						emission = new DaeEffectParam(emissionXML, this);
					}
				}
				if (diffuseXML != null) {
					diffuse = new DaeEffectParam(diffuseXML, this);
				}
				if (shader.localName() == "phong" || shader.localName() == "blinn") {
					var specularXML:XML = shader.specular[0];
					if (specularXML != null) {
						specular = new DaeEffectParam(specularXML, this);
					}
				}
				var transparentXML:XML = shader.transparent[0];
				if (transparentXML != null) {
					transparent = new DaeEffectParam(transparentXML, this);
				}
				var transparencyXML:XML = shader.transparency[0];
				if (transparencyXML != null) {
					transparency = new DaeEffectParam(transparencyXML, this);
				}
			}
			var bumpXML:XML = data.profile_COMMON.technique.extra.technique.(hasOwnProperty("@profile") && @profile == "OpenCOLLADA3dsMax").bump[0];
			if (bumpXML != null) {
				bump = new DaeEffectParam(bumpXML, this);
			}
			return true;
		}

		internal function getParam(name:String, setparams:Object):DaeParam {
			var param:DaeParam = setparams[name];
			if (param != null) {
				return param;
			}
			param = techniqueParams[name];
			if (param != null) {
				return param;
			}
			param = commonParams[name];
			if (param != null) {
				return param;
			}
			return effectParams[name];
		}
	
		private function float4ToUint(value:Array, alpha:Boolean = true):uint {
			var r:uint = (value[0] * 255);
			var g:uint = (value[1] * 255);
			var b:uint = (value[2] * 255);
			if (alpha) {
				var a:uint = (value[3] * 255);
				return (a << 24) | (r << 16) | (g << 8) | b;
			} else {
				return (r << 16) | (g << 8) | b;
			}
		}
	
		/**
		 * Возвращает материал движка с заданными параметрами.
		 * Перед использованием вызвать parse().
		 */
		public function getMaterial(setparams:Object):Material {
			var bumpURL:String = null;
			var transparentImage:DaeImage;
			if (bump != null || commonAlways) {
				var bumpImage:DaeImage = (bump != null) ? bump.getImage(setparams) : null;
				if (bumpImage != null) {
					bumpURL = bumpImage.init_from;
				}
				var emissionURL:String = null;
				if (emission != null) {
					var emissionImage:DaeImage = emission.getImage(setparams);
					if (emissionImage != null) {
						emissionURL = emissionImage.init_from;
					}
				}
				var specularURL:String = null;
				if (specular != null) {
					var specularImage:DaeImage = specular.getImage(setparams);
					if (specularImage != null) {
						specularURL = specularImage.init_from;
					}
				}
				var commonMaterial:CommonMaterial = new CommonMaterial();
				var diffuseImage:DaeImage = (diffuse == null) ? null : diffuse.getImage(setparams);
				if (diffuseImage != null) {
					commonMaterial.diffuseMapURL = diffuseImage.init_from;
				}
				transparentImage = (transparent == null) ? null : transparent.getImage(setparams);
				if (transparentImage != null) {
					commonMaterial.opacityMapURL = transparentImage.init_from;
				}
				commonMaterial.normalMapURL = bumpURL;
				commonMaterial.emissionMapURL = emissionURL;
				commonMaterial.specularMapURL = specularURL;
				return commonMaterial;
			}
			if (diffuse != null) {
				var color:Array = diffuse.getColor(setparams);
				if (color != null) {
					var fillMaterial:FillMaterial = new FillMaterial(float4ToUint(color, false), color[3]);
					if (transparency != null) {
						var value:Number = transparency.getFloat(setparams);
						if (!isNaN(value)) {
							fillMaterial.alpha = value;
						}
					}
					return fillMaterial;
				} else {
					var image:DaeImage = diffuse.getImage(setparams);
					if (image != null) {
						var sampler:DaeParam = diffuse.getSampler(setparams);
						var textureMaterial:TextureMaterial = new TextureMaterial();
						textureMaterial.repeat = (sampler == null) ? true : (sampler.wrap_s == null || sampler.wrap_s == "WRAP");
						textureMaterial.diffuseMapURL = image.init_from;
						transparentImage = (transparent == null) ? null : transparent.getImage(setparams);
						if (transparentImage != null) {
							textureMaterial.opacityMapURL = transparentImage.init_from;
						}
						return textureMaterial;
					}
				}
			}
			return null;
		}
	
		/**
		 * Имя текстурного канала для основной карты объекта.
		 * Перед использованием вызвать parse().
		 */
		public function get mainTexCoords():String {
			var channel:String = null;
			channel = (channel == null && diffuse != null) ? diffuse.texCoord : channel;
			channel = (channel == null && transparent != null) ? transparent.texCoord : channel;
			channel = (channel == null && bump != null) ? bump.texCoord : channel;
			channel = (channel == null && emission != null) ? emission.texCoord : channel;
			channel = (channel == null && specular != null) ? specular.texCoord : channel;
			return channel;
		}
	
	}
}
