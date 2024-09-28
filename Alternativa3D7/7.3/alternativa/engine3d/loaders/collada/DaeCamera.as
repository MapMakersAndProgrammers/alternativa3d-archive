package alternativa.engine3d.loaders.collada {
	import alternativa.engine3d.core.Camera3D;
	
	/**
	 * @private
	 */
	public class DaeCamera extends DaeElement {
	
		use namespace collada;
	
		public function DaeCamera(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		private function setXFov(camera:Camera3D, xFov:Number):void {
			//camera.fov = 2*Math.atan(0.5*Math.sqrt(camera.width*camera.width + camera.height*camera.height)/(camera.width/(2*Math.tan(0.5*xFov))));
		}
	
		public function parseCamera():Camera3D {
			var camera:Camera3D = new Camera3D();
			var perspectiveXML:XML = data.optics.technique_common.perspective[0];
			if (perspectiveXML) {
				const DEG2RAD:Number = Math.PI/180;
				var xfovXML:XML = perspectiveXML.xfov[0];
				var yfovXML:XML = perspectiveXML.yfov[0];
				var ratioXML:XML = perspectiveXML.aspect_ratio[0];
				if (ratioXML == null) {
					if (xfovXML != null) {
						setXFov(camera, parseNumber(xfovXML)*DEG2RAD);
					} else if (yfovXML != null) {
						setXFov(camera, parseNumber(yfovXML)*DEG2RAD);
					}
				} else {
					var ratio:Number = parseNumber(ratioXML);
					//camera.height = camera.width/ratio;
					if (xfovXML != null) {
						setXFov(camera, parseNumber(xfovXML)*DEG2RAD);
					} else if (yfovXML != null) {
						setXFov(camera, ratio*parseNumber(yfovXML)*DEG2RAD);
					}
				}
				var znearXML:XML = perspectiveXML.znear[0];
				var zfarXML:XML = perspectiveXML.zfar[0];
				if (znearXML != null) {
					camera.nearClipping = parseNumber(znearXML);
				}
				if (zfarXML != null) {
					camera.farClipping = parseNumber(zfarXML);
				}
			}
			return camera;
		}
	
	}
}
