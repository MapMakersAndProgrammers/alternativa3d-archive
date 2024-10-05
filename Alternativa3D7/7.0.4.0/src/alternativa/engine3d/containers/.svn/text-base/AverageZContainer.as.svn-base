package alternativa.engine3d.containers {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import flash.geom.Vector3D;
	import alternativa.engine3d.core.Camera3D;
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
		private var sortingStackIndex:int;
		private var sortingLeft:Number;
		private var sortingMedian:Number;
		private var sortingRight:Number;
		private var sortingChild:Object3D;

		override protected function calculateOrder(camera:Camera3D, object:Object3D):void {

			// Сортировка
			for (var i:int = 0; i < numVisibleChildren; i++) {
				(visibleChildren[i] as Object3D).cameraMatrix.transformVectors(center, cameraCenter);
				averageZ[i] = cameraCenter[0]*cameraCenter[0] + cameraCenter[1]*cameraCenter[1] + cameraCenter[2]*cameraCenter[2];
			}
			
			var j:int, l:int = 0, r:int = numVisibleChildren - 1;
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
		}
	}
}