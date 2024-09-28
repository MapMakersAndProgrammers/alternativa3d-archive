package alternativa.engine3d.containers {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.core.Object3DContainer;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.BitmapData;
	
	public class SkyBox extends Object3DContainer {
		
		private var backPlane:Mesh;
		private var frontPlane:Mesh;
		private var topPlane:Mesh;
		private var bottomPlane:Mesh;
		private var leftPlane:Mesh;
		private var rightPlane:Mesh;
		
		public function SkyBox(size:Number = 1000):void {
			backPlane = new Mesh();
			frontPlane = new Mesh();
			topPlane = new Mesh();
			bottomPlane = new Mesh();
			leftPlane = new Mesh();
			rightPlane = new Mesh();
			
			backPlane.clipping = 2;
			frontPlane.clipping = 2;
			topPlane.clipping = 2;
			bottomPlane.clipping = 2;
			leftPlane.clipping = 2;
			rightPlane.clipping = 2;
			
			backPlane.vertices = Vector.<Number>([
				-size, -size, -size,
				-size, -size, size,
				size, -size, size,
				size, -size, -size,
			]);
			frontPlane.vertices = Vector.<Number>([
				size, size, -size,
				size, size, size,
				-size, size, size,
				-size, size, -size,
			]);
			topPlane.vertices = Vector.<Number>([
				size, size, size,
				size, -size, size,
				-size, -size, size,
				-size, size, size,
			]);
			bottomPlane.vertices = Vector.<Number>([
				size, -size, -size,
				size, size, -size,
				-size, size, -size,
				-size, -size, -size,
			]);
			leftPlane.vertices = Vector.<Number>([
				-size, size, -size,
				-size, size, size,
				-size, -size, size,
				-size, -size, -size,
			]);
			rightPlane.vertices = Vector.<Number>([
				size, -size, -size,
				size, -size, size,
				size, size, size,
				size, size, -size,
			]);
			
			var uvts:Vector.<Number> = Vector.<Number>([1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0]); 
			backPlane.uvts = uvts;
			frontPlane.uvts = uvts;
			topPlane.uvts = uvts;
			bottomPlane.uvts = uvts;
			leftPlane.uvts = uvts;
			rightPlane.uvts = uvts;

			var indices:Vector.<int> = Vector.<int>([4, 0, 1, 2, 3]); 
			backPlane.indices = indices;
			frontPlane.indices = indices;
			topPlane.indices = indices;
			bottomPlane.indices = indices;
			leftPlane.indices = indices;
			rightPlane.indices = indices;

			backPlane.numVertices = 4;
			frontPlane.numVertices = 4;
			topPlane.numVertices = 4;
			bottomPlane.numVertices = 4;
			leftPlane.numVertices = 4;
			rightPlane.numVertices = 4;

			backPlane.numFaces = 1;
			frontPlane.numFaces = 1;
			topPlane.numFaces = 1;
			bottomPlane.numFaces = 1;
			leftPlane.numFaces = 1;
			rightPlane.numFaces = 1;

			backPlane.poly = true;
			frontPlane.poly = true;
			topPlane.poly = true;
			bottomPlane.poly = true;
			leftPlane.poly = true;
			rightPlane.poly = true;

			addChild(backPlane);
			addChild(frontPlane);
			addChild(topPlane);
			addChild(bottomPlane);
			addChild(leftPlane);
			addChild(rightPlane);
		}
		
		public function set backTexture(value:BitmapData):void {
			backPlane.texture = value;
		}

		public function set frontTexture(value:BitmapData):void {
			frontPlane.texture = value;
		}

		public function set topTexture(value:BitmapData):void {
			topPlane.texture = value;
		}

		public function set bottomTexture(value:BitmapData):void {
			bottomPlane.texture = value;
		}

		public function set leftTexture(value:BitmapData):void {
			leftPlane.texture = value;
		}

		public function set rightTexture(value:BitmapData):void {
			rightPlane.texture = value;
		}
		
	}
}
