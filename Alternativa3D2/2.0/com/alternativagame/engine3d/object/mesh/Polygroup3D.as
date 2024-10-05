package com.alternativagame.engine3d.object.mesh {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.Matrix3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.object.light.Light3D;
	import com.alternativagame.engine3d.object.mesh.polygon.FillPolygon3D;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Set;
	import com.alternativagame.type.Vector;
	
	import flash.utils.Dictionary;
	
	use namespace engine3d;

	public class Polygroup3D {

		use namespace engine3d;

		// Имя
		engine3d var name:String;
		
		// Ссылка на родителя
		engine3d var mesh:PolyMesh3D = null;
		
		// Список полигонов
		engine3d var polygons:Set;
		
		// Нормаль
		private var normal:Vector;

		// Центр полигруппы
		private var center:Vector;

		// Нормаль в камере
		engine3d var viewNormal:Vector;

		// Центр полигруппы в камере
		engine3d var viewCenter:Vector;

		// Текущее освещение
		engine3d var lightColor:RGB = null;
		
		// Список цветов источников с учетом силы
		private var lights:Dictionary;
		
		public function Polygroup3D(name:String) {
			lights = new Dictionary();
			polygons = new Set(true);
			this.name = name;
		}
		
		// Обновление после трансформации меша
		engine3d function updateTransform():void {
			var transform:Matrix3D = mesh.transform.clone();
			
			// Расчитываем центр в координатах камеры
			viewCenter = Math3D.vectorTransform(center, transform);
			
			// Убираем сдвиг матрицы родителя
			transform.d = 0;
			transform.h = 0;
			transform.l = 0;
			
			// Расчитываем нормаль в координатах камеры
			viewNormal = Math3D.vectorTransform(normal, transform);
			Math3D.normalize(viewNormal);
		}
		
		// Расчёт локальных нормали и центра
		engine3d function calculateParams():void {
			normal = new Vector();
			center = new Vector();
			
			// Если полигоны в группе есть
			if (polygons.length > 0) {
			
				var av:Vector;
				var bv:Vector;
				var cv:Vector;
				var v:Vector;
				var w:Vector;
				var polynormal:Vector;
							
				for each (var polygon:FillPolygon3D in polygons) {
					av = polygon.a.coords;
					bv = polygon.b.coords;
					cv = polygon.c.coords;
		
					// Добавляем центр полигона
					center = Math3D.vectorAdd(center, new Vector(av.x + bv.x + cv.x, av.y + bv.y + cv.y, av.z + bv.z + cv.z));
					
					// Добавляем нормаль полигона
					v = new Vector(bv.x - av.x, bv.y - av.y, bv.z - av.z);
					w = new Vector(cv.x - av.x, cv.y - av.y, cv.z - av.z);
					polynormal = Math3D.vectorCross(v, w);
					Math3D.normalize(polynormal);
					normal = Math3D.vectorAdd(normal, polynormal);
				}
				// Усредняем центр
				center = Math3D.vectorMultiply(center, 1/(polygons.length*3));
				
				// Нормализуем сумму нормалей
				Math3D.normalize(normal);
			}
		}
		
		engine3d function updateLight():void {

			// Если есть источники на пересчёт, обновляем список
			if (mesh.lightChanged.length > 0) {
				
				var color:RGB;
				
				for each (var light:Light3D in mesh.lightChanged) {
					// Расчет производим, только если в одной солид-группе
					if (light.solidParent == mesh.solidParent) {
						
						// Получаем освещение от источника
						color = light.getLightColor(viewCenter, viewNormal);
						
						if (color == null) {
							delete lights[light];
						} else {
							lights[light] = color;
						}
					} else {
						delete lights[light];
					}
				}

				// Расчёт общего света
				lightColor = new RGB();
				for each (color in lights) {
					lightColor.add(color);
				}
			}
		}
		
		// Добавить полигон в группу
		engine3d function addPolygon(polygon:FillPolygon3D):void {
			if (polygon.polygroup != null) {
				polygon.polygroup.removePolygon(polygon);
			}
			polygons.add(polygon);
			polygon.setPolygroup(this);
		}

		// Удалить полигон из группы
		engine3d function removePolygon(polygon:FillPolygon3D):void {
			if (polygons.has(polygon)) {			
				polygons.remove(polygon);
				polygon.setPolygroup(null);
			}
		}
		
	}
}