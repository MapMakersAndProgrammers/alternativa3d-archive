package alternativa.engine3d.loaders {
	
	public class MaterialParams {
		
		public var color:uint;
		public var opacity:Number;
		public var diffuseMap:String;
		public var opacityMap:String;
		
		public function toString():String {
			return "[MaterialParams color=" + color + ", opacity=" + opacity + ", diffuseMap=" + diffuseMap + ", opacityMap=" + opacityMap + "]";
		}

	}
}