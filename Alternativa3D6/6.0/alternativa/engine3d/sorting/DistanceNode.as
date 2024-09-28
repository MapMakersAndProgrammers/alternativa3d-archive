package alternativa.engine3d.sorting {
	
	import alternativa.engine3d.*;
	import alternativa.types.Set;
	import alternativa.engine3d.core.Space;
	
	use namespace alternativa3d;
	
	public class DistanceNode extends Node {

		// Список пространств
		alternativa3d var spaces:Set = new Set();
		// Список спрайтов
		alternativa3d var sprites:Set = new Set();
		// Список граней
		alternativa3d var faces:Set = new Set();
		
		// Хранилище неиспользуемых нод
		static private var collector:Array = new Array();
		
		static alternativa3d function create():DistanceNode {
			var node:DistanceNode;
			if ((node = collector.pop()) == null) {
				// Если коллектор пуст, создаём новую ноду
				return new DistanceNode();
			}
			return node;
		}
		
		static alternativa3d function destroy(node:DistanceNode):void {
			// Удаляем ссылку на уровень
			node.sortingLevel = null;
			// Отправляем ноду в коллектор
			collector.push(node);
		}
/*
		override alternativa3d function addDistancePrimitive(primitive:DistancePrimitive):void {
			// Пометка в уровне об изменении примитива
			sortingLevel.changedPrimitives[primitive] = true;
			// Устанавливаем связь примитива и ноды
			primitives[primitive] = true;
			primitive.node = this;
		}
*/
		alternativa3d function removeSpace(space:Space):void {
			trace("removeSpace", sortingLevel, space);
			
			// Пометка в уровне об изменении примитива
			sortingLevel.changed[space] = true;
			// Удаляем связь пространства и ноды
			space.node = null;
			delete spaces[space];
			// Если в ноде примитивов больше нет 
			if (spaces.isEmpty() && sprites.isEmpty() && faces.isEmpty()) {
				// Если есть родительская нода
				if (parent != null) {
					// Удаляем связь ноды с родительской нодой
					if (parent.backDistance == this) {
						parent.backDistance = null;
					} else {
						parent.frontDistance = null;
					}
					parent = null;
				} else {
					// Удаляем корневую ноду из уровня
					sortingLevel.distanceNode = null;
				}
				// Отправляем ноду в коллектор
				destroy(this);
			}
		}
		
	}
}