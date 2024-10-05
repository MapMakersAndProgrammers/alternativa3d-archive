package com.alternativagame.engine3d.object.mesh {
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.object.mesh.polygon.FillPolygon3D;
	import com.alternativagame.engine3d.object.mesh.polygon.Polygon3D;
	import com.alternativagame.type.Set;
	
	import flash.utils.Dictionary;
	
	use namespace engine3d;

	public class PolyMesh3D extends Mesh3D {

		use namespace engine3d;
		
		// Полигруппы
		private var polygroups:Array;
		
		public function PolyMesh3D() {
			polygroups = new Array();
		}

		// Обновиться после трансформации
		override protected function updateTransform():void {
			for each (var polygroup:Polygroup3D in polygroups) {
				polygroup.updateTransform();
			}
			super.updateTransform();
		}
		
		// Обновиться после освещения
		override protected function updateLight():void {
			if (lightChanged.length > 0) {
				for each (var polygroup:Polygroup3D in polygroups) {
					polygroup.updateLight();
				}
			}
			super.updateLight();
		}
		
		// Установить полигруппу для полигонов
		public function setPolygroup(name:String, polygons:Set):void {
			var polygon:FillPolygon3D;
			
			// Удаляем полигоны из старых полигрупп
			for each (polygon in polygons) {
				// Если полигон уже в полигруппе - убрать его оттуда
				if (polygon.polygroup != null) {
					// Если этот полигон последний в полигруппе - удалить её из списка
					if (polygon.polygroup.polygons.length <= 1) {
						delete polygroups[polygon.polygroup.name];
					}
					polygon.polygroup.removePolygon(polygon);
				}
			}
			
			// Если устанавливаем полигруппу
			if (name != null) {
				// Если полигруппы нет - создаём
				if (polygroups[name] == undefined) {
					polygroups[name] = new Polygroup3D(name);
					polygroups[name].mesh = this;
				}
				var polygroup:Polygroup3D = polygroups[name];
				
				// Добавить полигоны в полигруппу
				for each (polygon in polygons) {
					polygroup.addPolygon(polygon);
				}
				
			}
			
			// Обновить весь меш
			for each (polygroup in polygroups) {
				polygroup.calculateParams();
			}
			updateLightChanged();
			geometryChanged = true;
		}
		
		// Клон
		override public function clone():Object3D {
			var res:PolyMesh3D = new PolyMesh3D();
			cloneParams(res);
			return res;
		}
		
		// Клонировать геометрию (точки, полигоны, полигруппы)
		override protected function cloneGeometry(obj:Mesh3D):void {
			// Клонируем точки
			var p:Dictionary = new Dictionary();
			for each (var point:Point3D in points) {
				p[point] = point.clone();
				obj.addPoint(p[point]);
			}
			// Клонируем полигоны
			var f:Dictionary = new Dictionary();
			for each (var polygon:Polygon3D in polygons) {
				f[polygon] = polygon.clone(p[polygon.a], p[polygon.b], p[polygon.c]);
				obj.addPolygon(f[polygon]);
			}
			// Клонируем полигруппы
			/*for each (var polygroup:Polygroup3D in polygroups) {
				var g:Polygroup3D = new Polygroup3D();
				for each (polygon in polygroup.polygons) {
					g.addPolygon(f[polygon]);
				}
				PolyMesh3D(obj).addPolygroup(g);
			}*/
		}
		
		
	}
}