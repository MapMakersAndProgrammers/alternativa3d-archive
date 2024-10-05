package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.WireMaterial;
	import com.alternativagame.engine3d.object.mesh.polygon.WirePolygon3D;
	import com.alternativagame.type.Vector;
	
	use namespace engine3d;

	public class WireSkin extends PolygonSkin {

		use namespace engine3d;
		
		public function WireSkin(polygon:WirePolygon3D) {
			super(polygon);
		}

		override protected function drawPolygon(bx:int, by:int, cx:int, cy:int):void {
			var material:WireMaterial = WireMaterial(polygon.material);
			
			var wire:WirePolygon3D = WirePolygon3D(polygon);
			
			with (graphics) {
				clear();
				lineStyle(material.thickness, material.color.toInt());
				if (wire.edgeAB) {
					lineTo(bx, by);
					if (wire.edgeBC) {
						lineTo(cx, cy);
						if (wire.edgeCA) {
							lineTo(0, 0);
						}
					} else {
						if (wire.edgeCA) {
							moveTo(cx, cy);
							lineTo(0, 0);
						}
					}
				} else {
					if (wire.edgeBC) {
						moveTo(bx, by);
						lineTo(cx, cy);
						if (wire.edgeCA) {
							lineTo(0, 0);
						}
					} else {
						if (wire.edgeCA) {
							lineTo(cx, cy);
						}
					}
				}
			}
		}

	}
}