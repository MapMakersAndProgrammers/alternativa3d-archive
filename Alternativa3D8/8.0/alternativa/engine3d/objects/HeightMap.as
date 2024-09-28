package alternativa.engine3d.objects {
	import __AS3__.vec.Vector;
	
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	
	
	public class HeightMap {
		
//		private var map:Vector.<Vector.<uint>>;
		private var mapWidth:uint;
		private var mapHeight:uint;
		private var normalMap:BitmapData;
		private var heightMap:BitmapData;
		
		public function HeightMap(heightMap:BitmapData) {
			this.heightMap = heightMap;
			mapWidth = heightMap.width;
			mapHeight = heightMap.height;
//			map = new Vector.<Vector.<uint>>();
//			for (var i:int = 0; i < mapWidth; i++) {
//				var vector:Vector.<uint> = new Vector.<uint>();
//				map[i] = vector;
//				for (var j:int = 0; j < mapHeight;j++) {
//					var color:uint = heightMap.getPixel(i, j);
//					vector[j] = ((color >> 16) & 0xFF)/255;
//				}
//			}
		}
		
		public function getHeight(x:uint, y:uint):Number {
			
//			if (heightMap == null) {
//				trace("getHeight::heightMap == null");
//				return null;
//			}
			if (x < 0 || y < 0 || x >= mapWidth || y >= mapHeight) {
				trace("getHeight::incorrect x or y ", x, y);
				return -1;
			}
//			return map[x][y];
			return ((heightMap.getPixel(x, y) >> 16) & 0xFF)/255;
		}
		
		public function get width():uint {
			return mapWidth;
		}
		
		public function get height():uint {
			return mapHeight;
		}
		
		public function generateNormalMap():BitmapData {
			var normalMap:BitmapData = new BitmapData(mapWidth, mapHeight);
			var ct:ColorTransform = new ColorTransform();
			var scale:Number = 16;
			for (var i:int = 0; i < mapWidth - 1; i++) {
				for (var j:int = 0; j < mapHeight - 1; j++) {
					var c:Number = getHeight(i, j);
					var dx:Number = (c - getHeight(i, j+1))*scale;
					var dy:Number = (c - getHeight(i+1, j))*scale;
				//	var c1:Number = getHeight(i+1, j+1)/255;
				//	var dx1:Number = (c1 - getHeight(i, j+1)/255)*scale;
				//	var dy1:Number = (c1 - getHeight(i+1, j)/255)*scale;
					var len:Number = Math.sqrt(dx*dx + dy*dy + 1);
				//	var len1:Number = Math.sqrt(dx1*dx1 + dy1*dy1 + 1);
					var nx:Number = dy/len;
					var ny:Number = dx/len;
					var nz:Number = 1/len;
					ct.redOffset = 128 + 127*nx;
					ct.greenOffset = 128 + 127*ny;
			//		if (nz < 0.8) trace("nz", nz);
					ct.blueOffset = 128 + 127*nz;
					normalMap.setPixel(i, j, ct.color);
				}
			}
			return normalMap;
		}
		
		public function getNormalMap():BitmapData {
			if (normalMap != null) return normalMap;
			return generateNormalMap();
		}

	}
}