package alternativa.engine3d.loaders {
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	/**
	 * @private
	 * Класс содержит обобщённую информацию о материале.
	 */
	internal class MaterialInfo {
		public var color:uint;
		public var alpha:Number;

		public var textureFileName:String;
		public var bitmapData:BitmapData;
		public var repeat:Boolean;

		public var mapOffset:Point;
		public var mapSize:Point;
	}
}