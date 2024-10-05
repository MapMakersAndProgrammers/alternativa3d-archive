package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.Event3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.engine3d.material.PolygonMaterial;
	import com.alternativagame.engine3d.object.mesh.polygon.Polygon3D;
	import com.alternativagame.type.Vector;
	
	import flash.geom.Point;

	use namespace engine3d;
	
	public class PolygonSkin extends Skin {
		
		use namespace engine3d;

		public function PolygonSkin(polygon:Polygon3D) {
			super(polygon.mesh);
			this.polygon = polygon;
		}
		
		override engine3d function draw():void {
			
			super.draw();
			var material:PolygonMaterial = polygon.material;
			
			alpha = material.alpha;
			blendMode = material.blendMode;
			
			var bx:int = polygon.b.canvasX - x;
			var by:int = polygon.b.canvasY - y;
			var cx:int = polygon.c.canvasX - x;
			var cy:int = polygon.c.canvasY - y;
			
			drawPolygon(bx, by, cx, cy);
		}
		
		protected function drawPolygon(bx:int, by:int, cx:int, cy:int):void {}
		
		override protected function updateCoords():void {
			x = polygon.a.canvasX;
			y = polygon.a.canvasY;
		}

		override engine3d function get interactive():Boolean {
			return polygon.interactive;
		}

		override engine3d function get material():Material {
			return polygon.material;
		}

		override engine3d function getIntersectionCoords(canvasCoords:Point):Vector {
			var res:Vector = new Vector(canvasCoords.x, 0, -canvasCoords.y);

			var a:Vector = polygon.a.canvasCoords;
			var b:Vector = polygon.b.canvasCoords;
			var c:Vector = polygon.c.canvasCoords;
			
			// Определение порядка вершин
			var top:Vector;
			var middle:Vector;
			var bottom:Vector;
			if (a.z > b.z) {
				if (a.z > c.z) {
					top = a;
					if (b.z > c.z) {
						middle = b;
						bottom = c;
					} else {
						middle = c;
						bottom = b;
					}
				} else {
					top = c;
					middle = a;
					bottom = b;
				}
			} else {
				if (b.z > c.z) {
					top = b;
					if (a.z > c.z) {
						middle = a;
						bottom = c;
					} else {
						middle = c;
						bottom = a;
					}
				} else {
					top = c;
					middle = b;
					bottom = a;
				}
			}
			
			var k1:Number = (top.z - res.z)/(top.z - bottom.z);
			var x1:Number = top.x - (top.x - bottom.x)*k1;
			var y1:Number = top.y - (top.y - bottom.y)*k1;

			var k2:Number;
			var x2:Number; 
			var y2:Number; 
			if (res.z > middle.z) {
				// В верхней части
				k2 = (top.z - res.z)/(top.z - middle.z);
				x2 = top.x - (top.x - middle.x)*k2;
				y2 = top.y - (top.y - middle.y)*k2;
			} else {
				// В нижней части
				k2 = (middle.z - res.z)/(middle.z - bottom.z);
				x2 = middle.x - (middle.x - bottom.x)*k2;
				y2 = middle.y - (middle.y - bottom.y)*k2;
			}
			
			res.y = y1 - (y1 - y2)*(x1 - res.x)/(x1-x2);
			
			return res;
		}
		
	}
}