package alternativa.engine3d.loaders.collada {
	
	/**
	 * @private
	 */
	public class DaeEffectParam extends DaeElement {
	
		use namespace collada;
	
		private var effect:DaeEffect;
	
		public function DaeEffectParam(data:XML, effect:DaeEffect) {
			super(data, effect.document);
			this.effect = effect;
		}
	
		public function getFloat(setparams:Object):Number {
			var floatXML:XML = data.float[0];
			if (floatXML != null) {
				return parseNumber(floatXML);
			}
			var paramRef:XML = data.param.@ref[0];
			if (paramRef != null) {
				var param:DaeParam = effect.getParam(paramRef.toString(), setparams);
				if (param != null) {
					return param.getFloat();
				}
			}
			return NaN;
		}
	
		public function getColor(setparams:Object):Array {
			var colorXML:XML = data.color[0];
			if (colorXML != null) {
				return parseNumbersArray(colorXML);
			}
			var paramRef:XML = data.param.@ref[0];
			if (paramRef != null) {
				var param:DaeParam = effect.getParam(paramRef.toString(), setparams);
				if (param != null) {
					return param.getFloat4();
				}
			}
			return null;
		}
	
		private function get texture():String {
			var attr:XML = data.texture.@texture[0];
			return (attr == null) ? null : attr.toString();
		}
	
		public function getSampler(setparams:Object):DaeParam {
			var sid:String = texture;
			if (sid != null) {
				return effect.getParam(sid, setparams);
			}
			return null;
		}
	
		public function getImage(setparams:Object):DaeImage {
			var sampler:DaeParam = getSampler(setparams);
			if (sampler != null) {
				var surfaceSID:String = sampler.surfaceSID;
				if (surfaceSID != null) {
					var surface:DaeParam = effect.getParam(surfaceSID, setparams);
					if (surface != null) {
						return surface.image;
					}
				} else {
					return sampler.image;
				}
			} else {
				// Возможно файл был экспортирован стандартным экспортом макса, который забивает на спецификацию и хранит ссылку прямо на image.
				return document.findImageByID(texture);
			}
			return null;
		}
	
		public function get texCoord():String {
			var attr:XML = data.texture.@texcoord[0];
			return (attr == null) ? null : attr.toString();
		}
	
	}
}
