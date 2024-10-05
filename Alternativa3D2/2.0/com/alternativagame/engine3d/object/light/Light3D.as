package com.alternativagame.engine3d.object.light {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.HelperMaterial;
	import com.alternativagame.engine3d.object.HelperObject3D;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Set;
	import com.alternativagame.type.Vector;

	use namespace engine3d;
	
	public class Light3D extends HelperObject3D {
		
		use namespace engine3d;
		
		// Цвет освещения
		private var _color:RGB;
		
		public function Light3D(color:RGB = null, material:HelperMaterial = null) {
			super(material);
			this.color = color;
			solidLights.add(this);
		}
		
		// Освещение в заданной точке
		engine3d function getLightColor(coords:Vector, normal:Vector):RGB {
			return null;
		}
		
		// Возвращает освещение на основе направления света и нормали поверхности 
		protected function calculateLightColor(normal:Vector, vector:Vector):RGB {
			if (color == null) {
				// Если цвета нет, то вернуть null
				return null;
			} else {
				var strength:Number = 1 - Math3D.vectorDot(normal, vector);
				return new RGB((color.red*strength) >>> 1, (color.green*strength) >>> 1, (color.blue*strength) >>> 1);
			}
		}
		
		// Проверить освещение
		override protected function updateLightChanged():void {
			applyToSolidObjects();
		}
		
		// Повлиять на солид-область
		protected function applyToSolidObjects():void {
			for each (var obj:Object3D in solidParent.solidObjects) {
				// На источники света не светим
				if (!(obj is Light3D)) {
					obj.addLightChanged(this);
				}
			}
		}
		
		override engine3d function setSolidParent(value:Object3D):void {

			// Забрали себя от старого solidParent
			solidParent.solidLights.remove(this);
			
			// Добавили себя к новому solidParent 
			value.solidLights.add(this);
			
			// Разослать старым соседям, чтобы пересчитались
			applyToSolidObjects();

			super.setSolidParent(value);
		}
		
		public function set color(value:RGB):void {
			_color = value;
			updateSkin();
			applyToSolidObjects();
		}
		
		public function get color():RGB {
			return _color;
		}
		
		// Клон
		override public function clone():Object3D {
			var res:Light3D = new Light3D();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(object:*):void {
			var obj:Light3D = Light3D(object);
			super.cloneParams(obj);
			obj.color = color.clone();
		}
		
	}
}