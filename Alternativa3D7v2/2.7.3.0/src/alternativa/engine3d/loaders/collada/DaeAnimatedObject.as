package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.animation.Animation;
	import alternativa.engine3d.core.Object3D;

	/**
	 * @private
	 */
	public class DaeAnimatedObject {
	
		public var object:Object3D;
		public var animation:Animation;
		
		public function DaeAnimatedObject(object:Object3D, animation:Animation = null) {
			this.object = object;
			this.animation = animation;
		}
	
	}
}
