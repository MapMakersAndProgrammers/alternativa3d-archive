package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.animation.Key;
	import alternativa.engine3d.animation.Track;
	import alternativa.engine3d.animation.ValueKey;

	/**
	 * @private
	 */
	public class DaeChannel extends DaeElement {
	
		static public const PARAM_UNDEFINED:int = -1;
		static public const PARAM_TRANSLATE_X:int = 0;
		static public const PARAM_TRANSLATE_Y:int = 1;
		static public const PARAM_TRANSLATE_Z:int = 2;
		static public const PARAM_SCALE_X:int = 3;
		static public const PARAM_SCALE_Y:int = 4;
		static public const PARAM_SCALE_Z:int = 5;
		static public const PARAM_ROTATION_X:int = 6;
		static public const PARAM_ROTATION_Y:int = 7;
		static public const PARAM_ROTATION_Z:int = 8;
		static public const PARAM_TRANSLATE:int = 9;
		static public const PARAM_SCALE:int = 10;
		static public const PARAM_MATRIX:int = 11;
	
		/**
		 * Анимационный трек с ключами.
		 * Перед использованием вызвать parse().
		 */
		public var track:Track;
	
		/**
		 * Тип анимированного параметра, принимает одно из значений DaeChannel.PARAM_*.
		 * Перед использованием вызвать parse().
		 */
		public var animatedParam:int = PARAM_UNDEFINED;
	
		public function DaeChannel(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		/**
		 * Возвращает ноду которой предназначена анимация.
		 */
		public function get node():DaeNode {
			var targetXML:XML = data.@target[0];
			if (targetXML != null) {
				var targetParts:Array = targetXML.toString().split("/");
				// Первая часть это id элемента
				var node:DaeNode = document.findNodeByID(targetParts[0]);
				if (node != null) {
					// Последняя часть это трансформируемый элемент
					targetParts.pop();
					for (var i:int = 1, count:int = targetParts.length; i < count; i++) {
						var sid:String = targetParts[i];
						node = node.getNodeBySid(sid);
						if (node == null) {
							return null;
						}
					}
					return node;
				}
			}
			return null;
		}
	
		override protected function parseImplementation():Boolean {
			parseTransformationType();
			parseSampler();
			return true;
		}
	
		private function parseTransformationType():void {
			var targetXML:XML = data.@target[0];
			if (targetXML == null) return;
	
			// Разбиваем путь на части
			var targetParts:Array = targetXML.toString().split("/");
			var sid:String = targetParts.pop();
			var sidParts:Array = sid.split(".");
			var sidPartsCount:int = sidParts.length;
	
			// Определяем тип свойства
			var transformationXML:XML;
			var children:XMLList = node.data.children();
			for (var i:int = 0, count:int = children.length(); i < count; i++) {
				var child:XML = children[i];
				var attr:XML = child.@sid[0];
				if (attr != null && attr.toString() == sidParts[0]) {
					transformationXML = child;
					break;
				}
			}
			// TODO:: вариант со скобками на всякий случай
			var transformationName:String = transformationXML.localName() as String;
			if (sidPartsCount > 1) {
				var componentName:String = sidParts[1];
				switch (transformationName) {
					case "translate":
						switch (componentName) {
							case "X":
								animatedParam = PARAM_TRANSLATE_X;
								break;
							case "Y":
								animatedParam = PARAM_TRANSLATE_Y;
								break;
							case "Z":
								animatedParam = PARAM_TRANSLATE_Z;
								break;
						}
						break;
					case "rotate": {
						var axis:Array = parseNumbersArray(transformationXML);
						// TODO:: искать максимальное значение, а не единицу
						switch (axis.indexOf(1)) {
							case 0:
								animatedParam = PARAM_ROTATION_X;
								break;
							case 1:
								animatedParam = PARAM_ROTATION_Y;
								break;
							case 2:
								animatedParam = PARAM_ROTATION_Z;
								break;
						}
						break;
					}
					case "scale":
						switch (componentName) {
							case "X":
								animatedParam = PARAM_SCALE_X;
								break;
							case "Y":
								animatedParam = PARAM_SCALE_Y;
								break;
							case "Z":
								animatedParam = PARAM_SCALE_Z;
								break;
						}
						break;
				}
			} else {
				switch (transformationName) {
					case "translate":
						animatedParam = PARAM_TRANSLATE;
						break;
					case "scale":
						animatedParam = PARAM_SCALE;
						break;
					case "matrix":
						animatedParam = PARAM_MATRIX;
						break;
				}
			}
		}
	
		private function parseSampler():void {
			var sampler:DaeSampler = document.findSampler(data.@source[0]);
			if (sampler != null) {
				sampler.parse();
	
				if (animatedParam == PARAM_MATRIX) {
					track = sampler.parseMatrixTrack();
					return;
				}
				if (animatedParam == PARAM_TRANSLATE || animatedParam == PARAM_SCALE) {
					track = sampler.parsePointsTrack();
					return;
				}
				track = sampler.parseValuesTrack();
				if (animatedParam == PARAM_ROTATION_X || animatedParam == PARAM_ROTATION_Y || animatedParam == PARAM_ROTATION_Z) {
					// Переводим углы в радианы
					var toRad:Number = Math.PI/180;
					for (var key:Key = track.keyList; key != null; key = key.next) {
						var valueKey:ValueKey = ValueKey(key);
						valueKey.value *= toRad;
					}
				}
			} else {
				document.logger.logNotFoundError(data.@source[0]);
			}
		}
	
	}
}
