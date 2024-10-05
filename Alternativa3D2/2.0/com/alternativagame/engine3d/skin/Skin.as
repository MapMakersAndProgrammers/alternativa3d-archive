package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.object.SkinObject3D;
	import com.alternativagame.engine3d.object.mesh.polygon.Polygon3D;
	import com.alternativagame.type.Vector;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	use namespace engine3d;

	public class Skin extends Sprite {
		
		use namespace engine3d;
		
		engine3d var object:Object3D;
		engine3d var polygon:Polygon3D = null;
		engine3d var depth:Number;
		
		public function Skin(object:Object3D) {
			this.object = object;
		}
		
		engine3d function position():void {
			updateCoords();
		}
		
		engine3d function draw():void {
			updateCoords();
		}
		
		protected function updateCoords():void {}
		
		engine3d function light():void {}
		
		public function get sortDepth():Number {
			return depth + ((material != null) ? material.depthOffset : 0);
		}
			
		engine3d function get interactive():Boolean {
			return false;
		}

		engine3d function get material():Material {
			return null;
		}

		// Получить координаты точки пересечения скина с вектором (x, 1, -y) - координаты на экране
		engine3d function getIntersectionCoords(canvasCoords:Point):Vector {
			return null;
		}
			
	}
}