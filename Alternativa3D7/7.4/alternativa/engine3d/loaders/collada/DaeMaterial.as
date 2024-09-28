package alternativa.engine3d.loaders.collada {
	import alternativa.engine3d.materials.Material;

	/**
	 * @private
	 */
	public class DaeMaterial extends DaeElement {
	
		use namespace collada;
	
		/**
		 * Материал движка.
		 * Перед использованием вызвать parse().
		 */
		public var material:Material;
	
		/**
		 * Имя текстурного канала для карты цвета объекта
		 * Перед использованием вызвать parse().
		 */
		public var diffuseTexCoords:String;
	
		/**
		 * Материал используется.
		 */
		public var used:Boolean = false;
	
		public function DaeMaterial(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		private function parseSetParams():Object {
			var params:Object = new Object();
			var list:XMLList = data.instance_effect.setparam;
			for each (var element:XML in list) {
				var param:DaeParam = new DaeParam(element, document);
				params[param.ref] = param;
			}
			return params;
		}
	
		private function get effectURL():XML {
			return data.instance_effect.@url[0];
		}
	
		override protected function parseImplementation():Boolean {
			var effect:DaeEffect = document.findEffect(effectURL);
			if (effect != null) {
				effect.parse();
				material = effect.getMaterial(parseSetParams());
				diffuseTexCoords = effect.diffuseTexCoords;
				if (material != null) {
					material.name = name;
				}
				return true;
			}
			return false;
		}
	
	}
}
