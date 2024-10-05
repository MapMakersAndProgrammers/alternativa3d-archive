package alternativa.engine3d.loaders.collada {
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.TextureMaterial;

	/**
 * @private
 */
public class DaeEffect extends DaeElement {

	use namespace collada;

	private var effectParams:Object;
	private var commonParams:Object;
	private var techniqueParams:Object;

	private var diffuse:DaeEffectParam;
	private var emission:DaeEffectParam;
	private var transparent:DaeEffectParam;
	private var transparency:DaeEffectParam;

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
			if (shader.localName() == "constant") {
				var emissionXML:XML = shader.emission[0];
				if (emissionXML != null) {
					emission = new DaeEffectParam(emissionXML, this);
				}
			} else {
				var diffuseXML:XML = shader.diffuse[0];
				if (diffuseXML != null) {
					diffuse = new DaeEffectParam(diffuseXML, this);
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
		var diffuse:DaeEffectParam = (diffuse != null) ? diffuse : emission;
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
					var transparentImage:DaeImage = (transparent == null) ? null : transparent.getImage(setparams);
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
	 * Имя текстурного канала для карты цвета объекта
	 * Перед использованием вызвать parse().
	 */
	public function get diffuseTexCoords():String {
		return (diffuse == null && emission == null) ? null : ((diffuse != null) ? diffuse.texCoord : emission.texCoord);
	}

}
}
