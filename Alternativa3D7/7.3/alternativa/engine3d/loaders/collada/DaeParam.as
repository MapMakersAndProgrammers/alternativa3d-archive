package alternativa.engine3d.loaders.collada {
	
	/**
	 * @private
	 */
	public class DaeParam extends DaeElement {
	
		use namespace collada;
	
		public function DaeParam(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		public function get ref():String {
			var attribute:XML = data.@ref[0];
			return (attribute == null) ? null : attribute.toString();
		}
	
		public function getFloat():Number {
			var floatXML:XML = data.float[0];
			if (floatXML != null) {
				return parseNumber(floatXML);
			}
			return NaN;
		}
	
		public function getFloat4():Array {
			var element:XML = data.float4[0];
			var components:Array;
			if (element == null) {
				element = data.float3[0];
				if (element != null) {
					components = parseNumbersArray(element);
					components[3] = 1.0;
				}
			} else {
				components = parseNumbersArray(element);
			}
			return components;
		}
	
		/**
		 * Возвращает sid параметра с типом surface. Только если тип этого элемента sampler2D и версия коллады 1.4.
		 */
		public function get surfaceSID():String {
			var element:XML = data.sampler2D.source[0];
			return (element == null) ? null : element.text().toString();
		}
	
		public function get wrap_s():String {
			var element:XML = data.sampler2D.wrap_s[0];
			return (element == null) ? null : element.text().toString();
		}
	
		public function get image():DaeImage {
			var surface:XML = data.surface[0];
			var image:DaeImage;
			if (surface != null) {
				// Collada 1.4
				var init_from:XML = surface.init_from[0];
				if (init_from == null) {
					// Error
					return null;
				}
				image = document.findImageByID(init_from.text().toString());
			} else {
				// Collada 1.5
				var imageIDXML:XML = data.instance_image.@url[0];
				if (imageIDXML == null) {
					// error
					return null;
				}
				image = document.findImage(imageIDXML);
			}
			return image;
		}
	
	}
}
