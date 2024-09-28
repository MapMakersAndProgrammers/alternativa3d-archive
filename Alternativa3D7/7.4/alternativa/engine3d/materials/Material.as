package alternativa.engine3d.materials {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Face;
	
	use namespace alternativa3d;
	
	public class Material {
	
		public var name:String;
	
		alternativa3d function draw(camera:Camera3D, canvas:Canvas, list:Face, distance:Number):void {
			clearLinks(list);
		}
	
		alternativa3d function drawViewAligned(camera:Camera3D, canvas:Canvas, list:Face, distance:Number, a:Number, b:Number, c:Number, d:Number, tx:Number, ty:Number):void {
			clearLinks(list);
		}
	
		alternativa3d function clearLinks(list:Face):void {
			while (list != null) {
				var next:Face = list.processNext;
				list.processNext = null;
				list = next;
			}
		}
	
	}
}
