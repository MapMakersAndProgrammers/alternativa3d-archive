package alternativa.engine3d.containers {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	public class DirectionContainer extends Object3DContainer {
		
		public var direction:Vector3D = new Vector3D(0, 0, -1);
		
		override protected function drawVisibleChildren(camera:Camera3D, object:Object3D, canvas:Canvas):void {
			var i:int;
			var child:Object3D;
			if (Vector3D.Z_AXIS.dotProduct(object.cameraMatrix.deltaTransformVector(direction)) < 0) {
				for (i = 0; i < numVisibleChildren; i++) {
					child = visibleChildren[i];
					if (camera.debugMode) child.debug(camera, child, canvas);
					child.draw(camera, child, canvas);
					visibleChildren[i] = null;
				}
			} else {
				for (i = numVisibleChildren - 1; i >= 0; i--) {
					child = visibleChildren[i];
					if (camera.debugMode) child.debug(camera, child, canvas);
					child.draw(camera, child, canvas);
					visibleChildren[i] = null;
				}
			}
		}
		
	}
}
