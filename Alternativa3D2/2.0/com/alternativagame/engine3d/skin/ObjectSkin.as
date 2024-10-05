package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.Event3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.engine3d.material.ObjectMaterial;
	import com.alternativagame.engine3d.object.SkinObject3D;
	import com.alternativagame.type.Vector;
	
	import flash.display.Shape;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	use namespace engine3d;
	
	public class ObjectSkin extends Skin {
		
		use namespace engine3d;
		
		private var hit:Array;
		
		public function ObjectSkin(object:SkinObject3D) {
			super(object);
		}
		
		override engine3d function draw():void {
			super.draw();

			var material:ObjectMaterial = ObjectMaterial(this.material);
			
			alpha = material.alpha;
			blendMode = material.blendMode;
			
			// Отрисовка хит-области
			if (hit != material.hit) {
				hit = material.hit;
				with (graphics) {
					clear();
					beginFill(0, 0);
					if (hit.length > 2) {
						moveTo(hit[hit.length-1].x, hit[hit.length-1].y);
						for (var i:uint = 0; i < hit.length; i++) {
							lineTo(hit[i].x, hit[i].y);
						}
					} else {
						drawDefaultHit();
					}
					endFill();
				}
			}
		}
		
		protected function drawDefaultHit():void {}
		
		override protected function updateCoords():void {
			var canvasCoords:Vector = object.canvasCoords;
			x = canvasCoords.x;
			y = -canvasCoords.z;
		}
		
		override engine3d function get interactive():Boolean {
			return object.interactive;
		}

		override engine3d function get material():Material {
			return SkinObject3D(object).material;
		}

		override engine3d function getIntersectionCoords(canvasCoords:Point):Vector {
			return new Vector(canvasCoords.x, object.canvasCoords.y, -canvasCoords.y);
		}
		
	}
}