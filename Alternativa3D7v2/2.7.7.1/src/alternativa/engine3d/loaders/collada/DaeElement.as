package alternativa.engine3d.loaders.collada {
	
	/**
	 * @private
	 */
	public class DaeElement {
	
		use namespace collada;
	
		public var document:DaeDocument;
	
		public var data:XML;
	
		/**
		 * -1 - not parsed, 0 - parsed with error, 1 - parsed without error.
		 */
		private var _parsed:int = -1;
	
		public function DaeElement(data:XML, document:DaeDocument) {
			this.document = document;
			this.data = data;
		}
	
		/**
		 * Выполняет предварительную настройку объекта.
		 *
		 * @return <code>false</code> в случае ошибки.
		 */
		public function parse():Boolean {
			// -1 - not parsed, 0 - parsed with error, 1 - parsed without error.
			if (_parsed < 0) {
				_parsed = parseImplementation() ? 1 : 0;
				return _parsed != 0;
			}
			return _parsed != 0;
		}
	
		/**
		 * Переопределяемый метод parse()
		 */
		protected function parseImplementation():Boolean {
			return true;
		}
	
		/**
		 * Возвращает массив значений типа String.
		 */
		protected function parseStringArray(element:XML):Array {
			return element.text().toString().split(/\s+/);
		}
	
		protected function parseNumbersArray(element:XML):Array {
			var arr:Array = element.text().toString().split(/\s+/);
			for (var i:int = 0, count:int = arr.length; i < count; i++) {
				var value:String = arr[i];
				if (value.indexOf(",") != -1) {
					value = value.replace(/,/, ".");
				}
				arr[i] = parseFloat(value);
			}
			return arr;
		}
	
		protected function parseIntsArray(element:XML):Array {
			var arr:Array = element.text().toString().split(/\s+/);
			for (var i:int = 0, count:int = arr.length; i < count; i++) {
				var value:String = arr[i];
				arr[i] = parseInt(value, 10);
			}
			return arr;
		}
	
		protected function parseNumber(element:XML):Number {
			var value:String = element.toString().replace(/,/, ".");
			return parseFloat(value);
		}
	
		public function get id():String {
			var idXML:XML = data.@id[0];
			return (idXML == null) ? null : idXML.toString();
		}
	
		public function get sid():String {
			var attr:XML = data.@sid[0];
			return (attr == null) ? null : attr.toString();
		}
	
		public function get name():String {
			var nameXML:XML = data.@name[0];
			return (nameXML == null) ? null : nameXML.toString();
		}
	
	}
}
