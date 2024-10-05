package alternativa.engine3d.objects {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Vertex;
	
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	
	public class Terrain extends Mesh {
		
		// шаг сетки
		public const step:uint = 10; 
		
		private var map:Vector.<Vector.<Vertex>>;
		
		private var heightMap:HeightMap;
		
		private var width:uint;
		
		private var height:uint;
		
		public function Terrain() {
			
		}
		
		public function build(heightMapData:BitmapData):void {
			if (heightMapData == null) return;
			this.heightMap = new HeightMap(heightMapData);
			
			geometry = new Geometry();
			width = heightMapData.width;
			height = heightMapData.height;
			map = new Vector.<Vector.<Vertex>>(width);
			var halfW:Number = width >> 1;
			var halfH:Number = height >> 1;
			var a:Number = halfW*halfW;
			var b:Number = halfH*halfH;
			var i:int;
			var j:int;
			for (i = 0; i < width; i++) {
				map[i] = new Vector.<Vertex>(height);
				for (j = 0; j < height; j++) {
					var h:uint = heightMap.getHeight(i, j);
				//	if (((i - halfW)*(i - halfW)/a + (j - halfH)*(j - halfH)/b) <= 1) {
						map[i][j] = geometry.addVertex(i*step, j*step, h , i,  j);
//					} else {
//						var y:Number = Math.sqrt(b*(a - (i - halfW)*(i - halfW))/a);
//						if (y != 0) {
//							if (j > halfH) {
//								y += halfH;
//							} else {
//								y = -y + halfH;
//							}
//							if (Math.abs(j - y) < step) {
//								map[i][j] = geometry.addVertex(i*step, y*step, h, i,  j);
//							}	
//						}
//					}
				}
			}
			var time:Number = getTimer();
			for (i = 0; i < width - 1; i++) {
				for (j = 0; j < height - 1; j++) {
					buildFaces(i, j);
				}
				
			}
			trace("build", getTimer() - time);
			map = null;
			
		}
		
		
		private function buildFaces(i:uint, j:uint):void {
			var vert:Vertex = map[i][j];
			var rightVert:Vertex = map[i][j+1];
			var bottomVert:Vertex = map[i+1][j];
			var bottomRightVert:Vertex = map[i+1][j+1];
			
			if (vert != null) {
				if ((rightVert == null && bottomVert == null) || (rightVert == null && bottomRightVert == null) || (bottomVert == null && bottomRightVert == null)) {
					return;
				}
				
				if (bottomRightVert == null) {
					geometry.addTriFace(vert, bottomVert, rightVert);
					return;
				}
				if (bottomVert == null) {
					geometry.addTriFace(vert, bottomRightVert, rightVert);
					return;
				}
				
				if (rightVert == null) {
					geometry.addTriFace(vert, bottomVert, bottomRightVert);
					return;
				}
				//var highestVert:Vertex = getHighestVertex(Vector.<Vertex>([vert, rightVert, bottomVert, bottomRightVert]));
				//if (highestVert == vert || highestVert == bottomRightVert) {
					geometry.addTriFace(vert, bottomVert, rightVert);
					geometry.addTriFace(bottomVert, bottomRightVert, rightVert);
				//} else {
				//	geometry.addTriFace(vert, bottomRightVert, rightVert);
				//	geometry.addTriFace(bottomVert, bottomRightVert, vert);
				//}
				
			} else {
				if (rightVert != null && bottomVert != null && bottomRightVert != null) {
					geometry.addTriFace(bottomVert, bottomRightVert, rightVert);
				}
			}
		}
		
		private function getHighestVertex(vertices:Vector.<Vertex>):Vertex {
			if (vertices == null || vertices.length == 0) return null; 
			var maxVertex:Vertex = vertices[0];
			for (var i:int = 1; i < vertices.length; i++) {
				if (vertices[i].z > maxVertex.z) {
					maxVertex = vertices[i];
				}
			}
			return maxVertex;
		}
		
		public function generate(width:uint, height:uint, maxHeight:Number):void {
			this.width = width;
			this.height = height;			
			
			init(maxHeight);
			
			fracture(0, 0, width - 1, height - 1, 0, height - 1, maxHeight);
			fracture(0, 0, width - 1, 0, width - 1, height - 1, maxHeight);
			
			smooth();
			smooth();
			smooth();
			smooth();
			for (var i:int = 0; i < width - 1; i++) {
				for (var j:int = 0; j < height - 1; j++) {
					buildFaces(i, j);
				}
				
			}
			
			map = null;
		}
		
		private function fracture(aX:uint, aY:uint, bX:uint, bY:uint, cX:uint, cY:uint, maxHeight:Number):void {
			if ((Math.abs(aX - bX) <= 1) && (Math.abs(aY - bY) <= 1)) return;
			var x1:uint = (aX - bX)/2 + bX;
			var y1:uint = (aY - bY)/2 + bY;
			
			var x2:uint = (aX - cX)/2 + cX;
			var y2:uint = (aY - cY)/2 + cY;
			
			var x3:uint = (bX - cX)/2 + cX;
			var y3:uint = (bY - cY)/2 + cY;
			
			(map[x1][y1] as Vertex).z += Math.random()*maxHeight;
			(map[x2][y2] as Vertex).z += Math.random()*maxHeight;
			(map[x3][y3] as Vertex).z += Math.random()*maxHeight;
			maxHeight *= 0.9;
			
			
			fracture(aX, aY, x2, y2, x1, y1, maxHeight);
			fracture(cX, cY, x2, y2, x3, y3, maxHeight);
			fracture(bX, bY, x3, y3, x1, y1, maxHeight);
			fracture(x1, y1, x2, y2, x3, y3, maxHeight);
			
		}
		
		private function init(maxHeight:Number):void {
			geometry = new Geometry();
			map = new Vector.<Vector.<Vertex>>(width);
			var h:Number = maxHeight << 1;
			for (var i:int = 0; i < width; i++) {
				map[i] = new Vector.<Vertex>(height);
				for (var j:int = 0; j < width; j++) {
					map[i][j] = geometry.addVertex(i*step, j*step, 0, i, j); 
				}
			} 	
		}
		
		private function smooth():void {
			
			for (var i:int = 0; i < width ; i++) {
				for (var j:int = 0; j < height; j++) {
					(map[i][j] as Vertex).z = getAverageZ(i, j);  
				}
			} 	
		}
		
		private function getAverageZ(i:uint, j:uint):Number {
			return (getVertexZ(i - 1, j - 1) + 
				   getVertexZ(i - 1, j) + 
				   getVertexZ(i - 1, j + 1) + 
				   getVertexZ(i, j - 1) +
				   getVertexZ(i, j) +
				   getVertexZ(i, j + 1) + 
				   getVertexZ(i + 1, j - 1) + 
				   getVertexZ(i + 1, j) + 
				   getVertexZ(i + 1, j + 1))/9;  
		}
		
		private function getVertexZ(i:uint, j:uint):Number {
			if (i < 0 || j < 0 || i > width - 1 || j > height - 1) {
				return 0;
			}
			
			return map[i][j].z;
		}
		
		
		public function getLightMap(lightVector:Vector3D):BitmapData {
			var ct:ColorTransform = new ColorTransform();
			ct.redOffset = 128;//248;
			ct.greenOffset = 128;//229;
			ct.blueOffset = 128;//195;
			var gen:LightMapGenerator = new LightMapGenerator(heightMap, step, ct.color);
			return gen.generateLightMap(lightVector);
		}
		
		public function getNormalMap():BitmapData {
			return heightMap.getNormalMap();
		}

	}
}