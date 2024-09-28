package alternativa.engine3d.containers {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	public class SplitContainer extends Object3DContainer {
		
		public var splitPlane:Vector3D = new Vector3D(0, 0, 1, 0);
		static private const invertCameraMatrix:Matrix3D = new Matrix3D();
		static private const cameraPosition:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		static private const invertCameraPosition:Vector.<Number> = new Vector.<Number>(3, true);		
		
		override protected function drawVisibleChildren(camera:Camera3D, object:Object3D, canvas:Canvas):void {
			var i:int;
			var child:Object3D;
			invertCameraMatrix.identity();
			invertCameraMatrix.prepend(object.cameraMatrix);
			invertCameraMatrix.invert();
			invertCameraMatrix.transformVectors(cameraPosition, invertCameraPosition);
			if (invertCameraPosition[0]*splitPlane.x + invertCameraPosition[1]*splitPlane.y + invertCameraPosition[2]*splitPlane.z < splitPlane.w) {
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
