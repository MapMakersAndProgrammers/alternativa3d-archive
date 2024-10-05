package com.alternativagame.engine3d.object.mesh {
	import com.alternativagame.engine3d.View3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.object.mesh.polygon.Polygon3D;
	import com.alternativagame.type.Set;
	
	import flash.utils.Dictionary;

	use namespace engine3d;
	
	public class Mesh3D extends Object3D {

		use namespace engine3d;
		
		// Список точек
		private var _points:Set;
		// Список полигонов
		private var _polygons:Set;
		
		public function Mesh3D() {
			_points = new Set();
			_polygons = new Set();
		}
		
		// Обновиться после трансформации
		override protected function updateTransform():void {
			
			transform.d = Math.floor(transform.d);
			transform.h = Math.floor(transform.h);
			transform.l = Math.floor(transform.l);
			
			for each (var point:Point3D in points) {
				point.updateTransform();
			}
			for each (var polygon:Polygon3D in polygons) {
				polygon.updateTransform();
			}
		}
		
		// Обновиться после освещения
		override protected function updateLight():void {
			if (lightChanged.length > 0) {
				for each (var polygon:Polygon3D in polygons) {
					polygon.updateLight();
				}
			}
		}
		
		// Обновить полигоны, содержащие point
		public function updatePolygons(point:Point3D):void {
			for each (var polygon:Polygon3D in polygons) {
				if (polygon.a == point || polygon.b == point || polygon.c == point) {
					polygon.reskin();
				}
			}
		}
		
		// Добавить точку в объект
		public function addPoint(point:Point3D):void {
			// Если точка была в другом меше, удаляем её оттуда
			if (point.mesh != null) {
				point.mesh.removePoint(point);
			}
			// Добавляем себе точку
			points.add(point);
			point.setMesh(this);
		}

		// Удалить точку из объекта
		public function removePoint(point:Point3D):void {
			// Если у меша такая точка есть
			if (points.has(point)) {
				// Удаляем полигоны, зацепленные за эту точку
				for each (var polygon:Polygon3D in polygons) {
					if (point == polygon.a || point == polygon.b || point == polygon.c) {
						removePolygon(polygon);
					}
				}
				// Удаляем точку
				points.remove(point);
				point.setMesh(null);
			}
		}
		
		// Добавить полигон в объект
		public function addPolygon(polygon:Polygon3D):void {
			// Если полигон был в другом меше, удаляем его оттуда
			if (polygon.mesh != null) {
				polygon.mesh.removePolygon(polygon);
			}
			// Добавляем полигон
			polygons.add(polygon);
			polygon.setMesh(this);
		}

		// Удалить полигон из объекта
		public function removePolygon(polygon:Polygon3D):void {
			if (polygons.has(polygon)) {
				polygons.remove(polygon);
				polygon.setMesh(null);
			}
		}
		
		public function get points():Set {
			return _points;
		}

		public function get polygons():Set {
			return _polygons;
		}
		
		// Смена камеры
		override engine3d function setView(value:View3D):void {
			if (value == null) {
				// Если удаляем из камеры - удалить скины полигонов
				for each (var polygon:Polygon3D in polygons) {
					polygon.removeSkin();
				}
			}
			super.setView(value);
		}
		
		// Флаг интерактивности
		override public function set interactive(value:Boolean):void {
			super.interactive = value;
			for each (var polygon:Polygon3D in polygons) {
				polygon.interactive = value;
			}
		}
		
		// Клон
		override public function clone():Object3D {
			var res:Mesh3D = new Mesh3D();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(object:*):void {
			var obj:Mesh3D = Mesh3D(object);
			super.cloneParams(obj);
			cloneGeometry(obj);
		}
		
		// Клонировать геометрию (точки, полигоны)
		protected function cloneGeometry(obj:Mesh3D):void {
			// Клонируем точки
			var p:Dictionary = new Dictionary();
			for each (var point:Point3D in points) {
				p[point] = point.clone();
				obj.addPoint(p[point]);
			}
			// Клонируем полигоны
			for each (var polygon:Polygon3D in polygons) {
				obj.addPolygon(polygon.clone(p[polygon.a], p[polygon.b], p[polygon.c]));
			}
		}
		
	}
}