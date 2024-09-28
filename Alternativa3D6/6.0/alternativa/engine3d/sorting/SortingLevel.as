package alternativa.engine3d.sorting {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Space;
	import alternativa.types.Set;
	
	use namespace alternativa3d;
	
	public class SortingLevel {
		
		// Порядковый номер
		alternativa3d var index:int;
		
		// Пространство
		alternativa3d var space:Space;
		
		// Следующий уровень
		alternativa3d var next:SortingLevel;
		
		// Корневая нода дерева
		alternativa3d var bspNode:BSPNode;
		alternativa3d var distanceNode:DistanceNode;
		
		// Список несортируемых пространств
		alternativa3d var spaces:Set = new Set();
		// Список пространств на сортировку по дистанции 
		alternativa3d var spacesDistance:Set = new Set();

		// Список несортируемых спрайтов
		alternativa3d var sprites:Set = new Set();
		// Список спрайтов на сортировку по дистанции 
		alternativa3d var spritesDistance:Set = new Set();

		// Список несортируемых граней
		alternativa3d var faces:Set = new Set();
		// Список граней на сортировку по дистанции 
		alternativa3d var facesDistance:Set = new Set();
		// Список граней на сортировку по BSP
		alternativa3d var facesBSP:Array = new Array();
		 
		/**
		 * @private
		 * Список изменённых объектов
		 */
		alternativa3d var changed:Set = new Set();
		
		alternativa3d function calculate():void {
			/*var polyPrimitive:FacePolyPrimitive;
			var pointPrimitive:PointPrimitive;
			
			// Добавляем полигональные примитивы
			while ((polyPrimitive = polyPrimitivesToAdd.pop()) != null) {
			}

			// Если есть точечные примитивы на добавление
			if (pointPrimitivesToAdd[0] != undefined) {

				// Если корневого нода ещё нет, создаём
				if (root == null) {
					root = PointNode.create();
					root.space = this;
				}
				
				// Встраиваем примитивы в дерево
				while ((pointPrimitive = pointPrimitivesToAdd.pop()) != null) {
					trace(pointPrimitive);
					root.addPointPrimitive(pointPrimitive);
				}
				
			}*/
			
			// Если есть изменения, помечаем на очистку
			if (!changed.isEmpty()) {
				space._scene.levelsToClear[this] = true;
			}
			
			delete space._scene.levelsToCalculate[this];
		}
		
		alternativa3d function clear():void {
			trace(this, "clear");
			
			delete space._scene.levelsToClear[this];
		}
		
	}
}