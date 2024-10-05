package com.alternativagame.engine3d.object {
	import com.alternativagame.engine3d.View3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.HelperMaterial;
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.engine3d.object.light.Light3D;
	import com.alternativagame.engine3d.skin.DummySkin;
	import com.alternativagame.engine3d.skin.Skin;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;
	
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;

	use namespace engine3d;
	
	public class SkinObject3D extends Object3D {
		
		use namespace engine3d;
		
		// Отображение объекта в камере
		protected var skin:Skin = null;
		private var _material:Material;
		
		// Список цветов источников с учетом силы
		private var lights:Dictionary;
		
		// Текущее освещение
		private var _lightColor:RGB = null;
		
		// Нормаль всех скин-объектов
		static private var normal:Vector = new Vector(0, -1, 0);
		
		public function SkinObject3D(material:Material = null) {
			super();
			this.material = material;
			lights = new Dictionary();
		}

		override protected function updateTransform():void { 
			// Обновить глубину скина и добавить его в список сортировки
			if (skin != null) {
				skin.depth = transform.h;
				view.addToDepth(skin);
			
				// Если изменилась геометрия
				if (geometryChanged) {
					view.addToDraw(skin);
				} else {
					if (positionChanged) {
						// Если изменилась позиция
						view.addToPosition(skin);
					}
				}
			}
		}
		
		// Обновиться после освещения
		override protected function updateLight():void {
			// Флаг на добавление в список освещения
			var toLight:Boolean = false;
			
			// Если есть источники на пересчёт, обновляем список
			if (lightChanged.length > 0) {
				
				var color:RGB;
				
				for each (var light:Light3D in lightChanged) {
					// Расчот производим, только если в одной солид-группе
					if (light.solidParent == solidParent) {
						// Мои координаты
						var coords:Vector = new Vector(transform.d, transform.h, transform.l);
						
						// Получаем освещение от источника
						color = light.getLightColor(coords, normal);
						
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
				var newLightColor:RGB = new RGB();
				for each (color in lights) {
					newLightColor.add(color);
				}

				// Если свет новый, добавляем на освещение
				if (lightColor == null || !newLightColor.equals(lightColor)) {
					_lightColor = newLightColor;
					toLight = true;
				}
			} else {
				// Если освещения ещё не было, установить по умолчанию и добавить на освещение
				if (lightColor == null) {
					_lightColor = new RGB();
					toLight = true;
				}
			}
			// Если добавляем на освещение, есть скин и камера, то отправляем на освещение в камеру
			if (toLight && skin != null && view != null) {
				view.addToLight(skin);
			}
		}
		
		override engine3d function setView(value:View3D):void {
			if (value == null) {
				if (skin != null) {
					view.removeSkin(skin);
					_lightColor = null;
					skin = null;
				}
			} else {
				if (material != null) {
					skin = createSkin();
					if (skin != null) value.addSkin(skin);
				}
			}
			super.setView(value);
		}
		
		protected function createSkin():Skin {
			return null;
		}
		
		// Обновление скина при смене каких-либо параметров объекта
		protected function updateSkin():void {
			if (view != null && skin != null) {
				view.addToDraw(skin);
				view.addToLight(skin);
			}
		}

		public function get lightColor():RGB {
			return _lightColor;
		}
		
		// Установить новый материал
		public function set material(value:Material):void {
			// Если объект в камере
			if (view != null) {
				// Устанавливаем материал
				if (value != null) {
					if (skin == null) {
						skin = createSkin();
						if (skin != null) view.addSkin(skin);
					}
					// Обновляем скин
					updateSkin();
				// Сбрасываем материал
				} else {
					if (skin != null) {
						view.removeSkin(skin);
						skin = null;
					}
				}
			}
			// Сохраняем значение материала
			_material = value;
		}

		public function get material():Material {
			return _material;
		}
		
		// При смене параметров обновляем скин
		override public function set solid(value:Boolean):void {
			super.solid = value;
			updateSkin();
		}		

		override engine3d function setSolidParent(value:Object3D):void {
			super.setSolidParent(value);
			updateSkin();
		}		

		override engine3d function setParent(value:Object3D):void {
			super.setParent(value);
			updateSkin();
		}		

		override public function set name(value:String):void {
			super.name = value;
			updateSkin();
		}
		
		// Клон
		override public function clone():Object3D {
			var res:SkinObject3D = new SkinObject3D();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(object:*):void {
			var obj:SkinObject3D = SkinObject3D(object);
			super.cloneParams(obj);
			obj.material = material;
		}

	}
}