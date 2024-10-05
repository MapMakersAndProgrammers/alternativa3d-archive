package com.alternativagame.engine3d.object.mesh.polygon {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.FillMaterial;
	import com.alternativagame.engine3d.object.light.Light3D;
	import com.alternativagame.engine3d.object.mesh.Mesh3D;
	import com.alternativagame.engine3d.object.mesh.Point3D;
	import com.alternativagame.engine3d.object.mesh.PolyMesh3D;
	import com.alternativagame.engine3d.object.mesh.Polygroup3D;
	import com.alternativagame.engine3d.skin.FillSkin;
	import com.alternativagame.engine3d.skin.Skin;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Set;
	import com.alternativagame.type.Vector;
	
	import flash.utils.Dictionary;

	use namespace engine3d;
	
	public class FillPolygon3D extends Polygon3D {

		use namespace engine3d;

		// Ссылка на полигруппу
		engine3d var polygroup:Polygroup3D = null;

		// Нормаль
		engine3d var canvasNormal:Vector;

		// Центр полигона
		engine3d var canvasCenter:Vector;

		// Текущее освещение
		engine3d var lightColor:RGB;
		
		// Список цветов источников с учетом силы
		private var lights:Dictionary;
		
		public function FillPolygon3D(a:Point3D, b:Point3D, c:Point3D, material:FillMaterial = null) {
			super(a, b, c, material);
			clearLight();
		}
		
		override protected function createSkin():Skin {
			return new FillSkin(this);
		}

		// Обновление параметров полигона (центр, нормаль)
		override protected function updateParams():void {
			// Если не в полигруппе, то расчитываем собственные нормаль и центр
			if (polygroup == null) {
				var av:Vector = a.canvasCoords;
				var bv:Vector = b.canvasCoords;
				var cv:Vector = c.canvasCoords;
	
				// Расчёт центра полигона
				canvasCenter = new Vector((av.x + bv.x + cv.x)/3, (av.y + bv.y + cv.y)/3, (av.z + bv.z + cv.z)/3);
				
				// Расчёт нормали
				var v:Vector = new Vector(bv.x - av.x, bv.y - av.y, bv.z - av.z);
				var w:Vector = new Vector(cv.x - av.x, cv.y - av.y, cv.z - av.z);
				canvasNormal = Math3D.vectorCross(v, w);
				Math3D.normalize(canvasNormal);
			}
		}

		// Обновить освещение
		override engine3d function updateLight():void {
			if (skin != null) {
				calculateLight(mesh.lightChanged);
			}
		}
		
		// Удаление скина из камеры
		override engine3d function removeSkin():void {
			super.removeSkin();
			clearLight();
		}
		
		// Обнуляем цвет и список источников
		protected function clearLight():void {
			lightColor = new RGB();
			lights = new Dictionary();
		}
		
		// Немедленное переосвещение скина
		override protected function relightSkin():void {
			clearLight();
			// Пересчитать свет с источниками в солиде
			if (skin != null) {
				calculateLight(mesh.solidParent.solidLights);
			}
		}
		
		protected function calculateLight(lightSet:Set):void {
			// Если есть источники на пересчёт, обновляем список
			if (lightSet.length > 0) {
				
				// Новое освещение
				var newLightColor:RGB;
				
				// Если в полигруппе, то взять освещение из неё
				if (polygroup != null) {

					newLightColor = polygroup.lightColor;
					
				// Иначе рассчитать самостоятельно
				} else {
					
					var color:RGB;
					
					for each (var light:Light3D in lightSet) {
						// Расчет производим, только если в одной солид-группе
						if (light.solidParent == mesh.solidParent) {
							
							// Получаем освещение от источника
							color = light.getLightColor(canvasCenter, canvasNormal);
							
							if (color == null) {
								delete lights[light];
							} else {
								lights[light] = color;
							}
						// Удаляем источник из списка, если он перешёл в другую солид-группу
						} else {
							delete lights[light];
						}
					}
	
					// Расчёт общего света
					newLightColor = new RGB();
					for each (color in lights) {
						newLightColor.add(color);
					}
				}

				// Если свет новый, добавляем на освещение
				if (!newLightColor.equals(lightColor)) {
					lightColor = newLightColor;
					// Отправляем на освещение в камеру
					if (skin != null) {
						mesh.view.addToLight(skin);
					}
				}
			}
		} 

		// Установить полигруппу
		engine3d function setPolygroup(value:Polygroup3D):void {
			polygroup = value;
			
			// Обновить параметры и переосветиться
			updateParams();
			relightSkin();
		}
		
		// Установить родителя
		override engine3d function setMesh(value:Mesh3D):void {
			// Если удаляем себя - удалить и из полигруппы
			if (value == null && mesh != null && polygroup != null) {
				var polygon:Set = new Set();
				polygon.add(this);
				PolyMesh3D(mesh).setPolygroup(null, polygon);
			}
			super.setMesh(value);
		}
		
		// Клон
		override public function clone(a:Point3D, b:Point3D, c:Point3D):Polygon3D {
			var res:FillPolygon3D = new FillPolygon3D(a, b, c);
			cloneParams(res);
			return res;
		}
		
	}
}