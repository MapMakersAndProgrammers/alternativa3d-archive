package alternativa.engine3d.lights {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	import __AS3__.vec.Vector;
	
	use namespace alternativa3d;
	
	public class OmniLight extends Object3D	{
		
		public var color:int;
		
		public var radius:Number;
		
		public var strength:Number;

		alternativa3d var cameraCoords:Vector.<Number> = new Vector.<Number>(3);
		
		public function OmniLight(color:int, radius:Number, strength:Number = 1) {
			this.color = color;
			this.radius = radius;
			this.strength = strength;
		}
		
	}
}