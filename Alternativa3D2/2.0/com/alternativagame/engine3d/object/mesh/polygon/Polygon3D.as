package com.alternativagame.engine3d.object.mesh.polygon {
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.engine3d.material.PolygonMaterial;
	import com.alternativagame.engine3d.material.TextureMaterial;
	import com.alternativagame.engine3d.object.mesh.Mesh3D;
	import com.alternativagame.engine3d.object.mesh.Point3D;
	import com.alternativagame.engine3d.skin.Skin;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;
	
	import flash.utils.Dictionary;

	use namespace engine3d;

	public class Polygon3D {

		use namespace engine3d;

		// Отображение полигона в камере
		protected var skin:Skin = null;
		private var _material:PolygonMaterial;
		
		// Ссылка на родителя
		engine3d var mesh:Mesh3D = null;

		// Флаг интерактивности
		private var _interactive:Boolean = false;

		// Точки
		engine3d var a:Point3D;
		engine3d var b:Point3D;
		engine3d var c:Point3D;
		
		public function Polygon3D(a:Point3D, b:Point3D, c:Point3D, material:PolygonMaterial = null) {
			this.material = material;
			this.a = a;
			this.b = b;
			this.c = c;
		}
		
		// Обновить геометрию
		protected function updateGeometry():void {
			// Если материал есть и полигон видимый или двусторонний
			if (material != null && (material.twoSided || checkVisibility())) {
				// Если скина нет, создаём
				if (skin == null) {
					skin = createSkin();
					mesh.view.addSkin(skin);
				}
				// Расчитываем глубину и добавляем в список на сортировку
				skin.depth = (a.canvasCoords.y + b.canvasCoords.y + c.canvasCoords.y)/3;
				mesh.view.addToDepth(skin);
				// Добавляем в список на отрисовку
				mesh.view.addToDraw(skin);
				updateParams();
			} else {
				removeSkin();
			}
		}
		
		// Обновить позицию
		protected function updatePosition():void {
			if (skin != null) {
				// Расчитываем глубину и добавляем в список на сортировку
				skin.depth = (a.canvasCoords.y + b.canvasCoords.y + c.canvasCoords.y)/3;
				mesh.view.addToDepth(skin);
				// Добавляем в список на позиционирование
				mesh.view.addToPosition(skin);
				updateParams();
			}
		}
		
		engine3d function updateTransform():void {
			if (mesh.geometryChanged) {
				updateGeometry();
			} else {
				if (mesh.positionChanged) {
					updatePosition();
				}
			}
		}

		// Обновление параметров полигона (центр, нормаль)
		protected function updateParams():void {}
		
		// Обновление освещения
		engine3d function updateLight():void {}
		
		// Удаление скина из камеры
		engine3d function removeSkin():void {
			if (skin != null ) {
				mesh.view.removeSkin(skin);
				skin = null;
			}
		}

		// Немедленный пересчёт и переосвещение
		engine3d function reskin():void {
			updateGeometry();
			relightSkin();
		}

		// Немедленная перерисовка скина
		protected function redrawSkin():void {
			if (skin != null) {
				mesh.view.addToDraw(skin);
			}
		}

		// Немедленное переосвещение скина
		protected function relightSkin():void {}

		protected function createSkin():Skin {
			return null;
		}

		// Установить новый материал
		public function set material(value:PolygonMaterial):void {
			// Сохраняем значение материала
			_material = value;
			// Если есть родительский меш и он в камере
			if (mesh != null && mesh.view != null) {
				reskin();
			}
		}

		public function get material():PolygonMaterial {
			return _material;
		}
		
		// Установить родителя
		engine3d function setMesh(value:Mesh3D):void {
			// При смене родителя убираем свой скин из его камеры
			if (skin != null) mesh.view.removeSkin(skin);
			
			// Сохраняем родителя
			mesh = value;
			
			// Забираем у родителя флаг интерактивности
			if (value != null) {
				interactive = value.interactive;
			}

			// Перерисоваться, если установили родителя
			if (value != null && value.view != null/* && !value.geometryChanged*/) {
				reskin();
			}
		}
		
		// Флаг интерактивности
		public function set interactive(value:Boolean):void {
			_interactive = value;
		}
		public function get interactive():Boolean {
			return _interactive;
		}		
		
		// Быстрый расчёт видимости грани в камере
		protected function checkVisibility():Boolean {
			var av:Vector = a.canvasCoords;
			var bv:Vector = b.canvasCoords;
			var cv:Vector = c.canvasCoords;
			return (bv.z - av.z)*(cv.x - av.x) < (bv.x - av.x)*(cv.z - av.z);
		}
		
		// Клон
		public function clone(a:Point3D, b:Point3D, c:Point3D):Polygon3D {
			var res:Polygon3D = new Polygon3D(a, b, c);
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		protected function cloneParams(object:*):void {
			var obj:Polygon3D = Polygon3D(object);
			obj.material = material;
		}
		
		
	}
}