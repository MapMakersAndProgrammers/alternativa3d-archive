package com.alternativagame.engine3d.object.mesh {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;
	
	import flash.utils.Dictionary;
	
	use namespace engine3d;

	public class Point3D {

		use namespace engine3d;

		// Ссылка на родителя
		engine3d var mesh:Mesh3D = null;

		// Смещение точки относительно родителя
		private var _coords:Vector;
		
		// Координаты в камере
		engine3d var canvasCoords:Vector;
		
		// Округлённые координаты в камере
		engine3d var canvasX:int;
		engine3d var canvasY:int;
		
		public function Point3D(x:Number = 0, y:Number = 0, z:Number = 0) {
			_coords = new Vector(x, y, z);
		}
		
		engine3d function updateTransform():void {
			canvasCoords = Math3D.vectorTransform(coords, mesh.transform);
			
			// Округлённые координаты в камере для отрисовки
			canvasX = Math.floor(canvasCoords.x);
			canvasY = -Math.floor(canvasCoords.z);
		}
		

		public function get x():Number {
			return coords.x;
		}		

		public function get y():Number {
			return coords.y;
		}		

		public function get z():Number {
			return coords.z;
		}
		
		public function set x(value:Number):void {
			coords.x = value;
			updateCoords();
		}		

		public function set y(value:Number):void {
			coords.y = value;
			updateCoords();
		}		

		public function set z(value:Number):void {
			coords.z = value;
			updateCoords();
		}
		
		public function get coords():Vector {
			return _coords;
		}
				
		public function set coords(value:Vector):void {
			_coords = value;
			updateCoords();
		}
		
		// Обновились координаты
		private function updateCoords():void {
			// Если в меше и в камере
			if (mesh != null && mesh.view != null) {
				// Расчитать глобальные координаты
				updateTransform();
				// Обновить зависимые полигоны
				mesh.updatePolygons(this);
			}
		}

		// Установить родителя
		engine3d function setMesh(value:Mesh3D):void {
			mesh = value;
			// Пересчитать трансформацию, если установили родителя
			if (value != null) {
				updateTransform();
			}
		}
		
		// Клон
		public function clone():Point3D {
			return new Point3D(x, y, z);
		}
	}
}