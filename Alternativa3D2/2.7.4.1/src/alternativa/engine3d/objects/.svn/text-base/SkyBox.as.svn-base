package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Clipping;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Sorting;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.materials.TextureMaterial;

	import flash.geom.Matrix;
	import flash.geom.Point;

	use namespace alternativa3d;
	
	public class SkyBox extends Mesh {
		
		static public const LEFT:String = "left";
		static public const RIGHT:String = "right";
		static public const BACK:String = "back";
		static public const FRONT:String = "front";
		static public const BOTTOM:String = "bottom";
		static public const TOP:String = "top";
		
		private var leftFace:Face;
		private var rightFace:Face;
		private var backFace:Face;
		private var frontFace:Face;
		private var bottomFace:Face;
		private var topFace:Face;
		
		public function SkyBox(size:Number, left:TextureMaterial, right:TextureMaterial, back:TextureMaterial, front:TextureMaterial, bottom:TextureMaterial, top:TextureMaterial, uvPadding:Number = 0) {
			
			size *= 0.5;
			
			var a:Vertex = addVertex(-size, -size, size, uvPadding, uvPadding);
			var b:Vertex = addVertex(-size, -size, -size, uvPadding, 1 - uvPadding);
			var c:Vertex = addVertex(-size, size, -size, 1 - uvPadding, 1 - uvPadding);
			var d:Vertex = addVertex(-size, size, size, 1 - uvPadding, uvPadding);
			leftFace = addQuadFace(a, b, c, d, left);
			
			a = addVertex(size, size, size, uvPadding, uvPadding);
			b = addVertex(size, size, -size, uvPadding, 1 - uvPadding);
			c = addVertex(size, -size, -size, 1 - uvPadding, 1 - uvPadding);
			d = addVertex(size, -size, size, 1 - uvPadding, uvPadding);
			rightFace = addQuadFace(a, b, c, d, right);
			
			a = addVertex(size, -size, size, uvPadding, uvPadding);
			b = addVertex(size, -size, -size, uvPadding, 1 - uvPadding);
			c = addVertex(-size, -size, -size, 1 - uvPadding, 1 - uvPadding);
			d = addVertex(-size, -size, size, 1 - uvPadding, uvPadding);
			backFace = addQuadFace(a, b, c, d, back);
			
			a = addVertex(-size, size, size, uvPadding, uvPadding);
			b = addVertex(-size, size, -size, uvPadding, 1 - uvPadding);
			c = addVertex(size, size, -size, 1 - uvPadding, 1 - uvPadding);
			d = addVertex(size, size, size, 1 - uvPadding, uvPadding);
			frontFace = addQuadFace(a, b, c, d, front);
			
			a = addVertex(-size, size, -size, uvPadding, uvPadding);
			b = addVertex(-size, -size, -size, uvPadding, 1 - uvPadding);
			c = addVertex(size, -size, -size, 1 - uvPadding, 1 - uvPadding);
			d = addVertex(size, size, -size, 1 - uvPadding, uvPadding);
			bottomFace = addQuadFace(a, b, c, d, bottom);
			
			a = addVertex(-size, -size, size, uvPadding, uvPadding);
			b = addVertex(-size, size, size, uvPadding, 1 - uvPadding);
			c = addVertex(size, size, size, 1 - uvPadding, 1 - uvPadding);
			d = addVertex(size, -size, size, 1 - uvPadding, uvPadding);
			topFace = addQuadFace(a, b, c, d, top);
			
			calculateBounds();
			calculateNormals(true);
			
			clipping = Clipping.FACE_CLIPPING;
			sorting = Sorting.NONE;
		}
		
		public function getSide(side:String):Face {
			switch (side) {
				case LEFT:
					return leftFace;
				case RIGHT:
					return rightFace;
				case BACK:
					return backFace;
				case FRONT:
					return frontFace;
				case BOTTOM:
					return bottomFace;
				case TOP:
					return topFace;
			}
			return null;
		}
		
		public function transformUV(side:String, matrix:Matrix):void {
			var face:Face = getSide(side);
			if (face != null) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					var res:Point = matrix.transformPoint(new Point(vertex.u, vertex.v));
					vertex.u = res.x;
					vertex.v = res.y;
				}
			}
		}
		
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			object.culling &= ~3;
			super.draw(camera, object, parentCanvas);
		}
		
	}
}
