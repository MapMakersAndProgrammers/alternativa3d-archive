package alternativa.engine3d.containers {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	
	use namespace alternativa3d;
	
	/**
	 * Контейнер, дочерние объекты которого отрисовываются по удалённости от камеры 
	 */
	public class AverageZContainer extends Object3DContainer {
		
		static private const averageZ:Vector.<Number> = new Vector.<Number>();
		static private const center:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		static private const cameraCenter:Vector.<Number> = new Vector.<Number>(3, true);
		static private const sortingStack:Vector.<int> = new Vector.<int>();
		
		override protected function drawVisibleChildren(camera:Camera3D, object:Object3D, canvas:Canvas):void {
			var i:int;
			var j:int;
			var l:int = 0;
			var r:int = numVisibleChildren - 1;
			var child:Object3D;
			var sortingStackIndex:int;
			var sortingLeft:Number;
			var sortingMedian:Number;
			var sortingRight:Number;
			var sortingChild:Object3D;
			// Сортировка
			for (i = 0; i < numVisibleChildren; i++) {
				child = visibleChildren[i];
				child.cameraMatrix.transformVectors(center, cameraCenter);
				averageZ[i] = cameraCenter[0]*cameraCenter[0] + cameraCenter[1]*cameraCenter[1] + cameraCenter[2]*cameraCenter[2];
			}
			sortingStack[0] = l;
			sortingStack[1] = r;
			sortingStackIndex = 2;
			while (sortingStackIndex > 0) {
				j = r = sortingStack[--sortingStackIndex];
				i = l = sortingStack[--sortingStackIndex];
				sortingMedian = averageZ[(r + l) >> 1];
				do {
	 				while ((sortingLeft = averageZ[i]) > sortingMedian) i++;
	 				while ((sortingRight = averageZ[j]) < sortingMedian) j--;
	 				if (i <= j) {
	 					sortingChild = visibleChildren[i];
						visibleChildren[i] = visibleChildren[j];
						visibleChildren[j] = sortingChild;
						averageZ[i++] = sortingRight;
						averageZ[j--] = sortingLeft;
	 				}
				} while (i <= j);
				if (l < j) {
					sortingStack[sortingStackIndex++] = l;
					sortingStack[sortingStackIndex++] = j;
				}
				if (i < r) {
					sortingStack[sortingStackIndex++] = i;
					sortingStack[sortingStackIndex++] = r;
				}
			}
			// Отрисовка
			for (i = numVisibleChildren - 1; i >= 0; i--) {
				child = visibleChildren[i];
				if (camera.debugMode) child.debug(camera, child, canvas);
				child.draw(camera, child, canvas);
				visibleChildren[i] = null;
			}
		}
		
	}
}
