package alternativa.engine3d.containers {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	
	use namespace alternativa3d;
	
	/**
	 * Контейнер, дочерние объекты которого отрисовываются по удалённости от камеры
	 */
	public class ZSortContainer extends Object3DContainer {
	
		static private const sortingStack:Vector.<int> = new Vector.<int>();
	
		override protected function drawVisibleChildren(camera:Camera3D, object:Object3D, canvas:Canvas):void {
			var i:int;
			var j:int;
			var l:int = 0;
			var r:int = numVisibleChildren - 1;
			var child:Object3D;
			var stackIndex:int;
			var left:Number;
			var median:Number;
			var right:Number;
			sortingStack[0] = l;
			sortingStack[1] = r;
			stackIndex = 2;
			while (stackIndex > 0) {
				r = sortingStack[--stackIndex];
				l = sortingStack[--stackIndex];
				j = r;
				i = l;
				child = visibleChildren[(r + l) >> 1];
				median = child.ml;
				do {
					while ((left = (visibleChildren[i] as Object3D).ml) > median) i++;
					while ((right = (visibleChildren[j] as Object3D).ml) < median) j--;
					if (i <= j) {
						child = visibleChildren[i];
						visibleChildren[i++] = visibleChildren[j];
						visibleChildren[j--] = child;
					}
				} while (i <= j);
				if (l < j) {
					sortingStack[stackIndex++] = l;
					sortingStack[stackIndex++] = j;
				}
				if (i < r) {
					sortingStack[stackIndex++] = i;
					sortingStack[stackIndex++] = r;
				}
			}
			// Отрисовка
			for (i = numVisibleChildren - 1; i >= 0; i--) {
				child = visibleChildren[i];
				child.draw(camera, child, canvas);
				visibleChildren[i] = null;
			}
		}
	
	}
}
