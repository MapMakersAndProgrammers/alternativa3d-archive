package alternativa.engine3d.containers {

	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.Vector3D;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	
	use namespace alternativa3d;
		
	public class DirectionContainer extends Object3DContainer {
		
		public var direction:Vector3D = new Vector3D(0, 0, -1);
		
		override protected function calculateOrder(camera:Camera3D, object:Object3D):void {
			if (Vector3D.Z_AXIS.dotProduct(object.cameraMatrix.deltaTransformVector(direction)) < 0) {
				var num:uint = numVisibleChildren >> 1;
				for (var i:uint = 0; i < num; i++) {
					var child:Object3D = visibleChildren[i];
					visibleChildren[i] = visibleChildren[numVisibleChildren - 1 - i];
					visibleChildren[numVisibleChildren - 1 - i] = child;
				}
			}
		}
		
	}
}