package alternativa.engine3d.containers {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	
	use namespace alternativa3d;
	
	/**
	 * Контейнер, дочерние объекты которого отрисовываются в порядке удалённости от камеры.
	 */
	public class DistanceSortContainer extends Object3DContainer {
	
		static private const sortingStack:Vector.<int> = new Vector.<int>();
		
		/**
		 * Определяет, сортировать объекты по полному расстоянию до камеры или только по Z-дистанции в пространстве камеры.
		 * Значение по умолчанию — <code>false</code>.
		 */
		public var sortByZ:Boolean = false;
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:DistanceSortContainer = new DistanceSortContainer();
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:DistanceSortContainer = source as DistanceSortContainer;
			sortByZ = src.sortByZ;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function drawVisibleChildren(camera:Camera3D, canvas:Canvas):void {
			var i:int;
			var j:int;
			var child:Object3D;
			var l:int = 0;
			var r:int = numVisibleChildren - 1;
			var stackIndex:int;
			var left:Number;
			var median:Number;
			var right:Number;
			sortingStack[0] = l;
			sortingStack[1] = r;
			stackIndex = 2;
			// Сортировка
			if (sortByZ) {
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
			} else {
				for (i = 0; i < numVisibleChildren; i++) {
					child = visibleChildren[i];
					var dx:Number = child.md*camera.viewSizeX/camera.focalLength;
					var dy:Number = child.mh*camera.viewSizeY/camera.focalLength;
					child.distance = dx*dx + dy*dy + child.ml*child.ml;
				}
				while (stackIndex > 0) {
					r = sortingStack[--stackIndex];
					l = sortingStack[--stackIndex];
					j = r;
					i = l;
					child = visibleChildren[(r + l) >> 1];
					median = child.distance;
					do {
						while ((left = (visibleChildren[i] as Object3D).distance) > median) i++;
						while ((right = (visibleChildren[j] as Object3D).distance) < median) j--;
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
			}
			// Отрисовка
			for (i = numVisibleChildren - 1; i >= 0; i--) {
				child = visibleChildren[i];
				child.draw(camera, canvas);
				visibleChildren[i] = null;
			}
		}
		
	}
}
