package alternativa.engine3d.objects {
	import flash.display.BitmapData;
	import flash.filters.ConvolutionFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	
	public class LightMapGenerator  {
		private var heightMap:HeightMap;
		private var mapWidth:uint;
		private var mapHeight:uint;
		private var step:uint;
		private var ambientColor:uint;
		private var ambientR:uint;
		private var ambientG:uint;
		private var ambientB:uint;
		
		public function LightMapGenerator(heightMap:HeightMap, step:uint, ambientColor:uint) {
			this.heightMap = heightMap;
			mapWidth = heightMap.width;
			mapHeight = heightMap.height;
			this.ambientColor = ambientColor;
			this.ambientR = (ambientColor >> 16) & 0xFF;
			this.ambientG = (ambientColor >> 8) & 0xFF;
			this.ambientB = (ambientColor) & 0xFF;
			this.step = step;
		}
		
		
		public function generateLightMap(lightVector:Vector3D):BitmapData {
			
			var normalMap:BitmapData = heightMap.getNormalMap();
			if (normalMap == null) return null;
			
			var lightMap:BitmapData = new BitmapData(mapWidth, mapHeight);
			var ct:ColorTransform = new ColorTransform();
			var i:int;
			var j:int;
			var time:Number = getTimer();
			// Считаем свет
			var lLen:Number = Math.sqrt(lightVector.x*lightVector.x + lightVector.y*lightVector.y + lightVector.z*lightVector.z);
			lightVector.x = lightVector.x/lLen;
			lightVector.y = lightVector.y/lLen;
			lightVector.z = lightVector.z/lLen;
			for (i = 0; i < mapWidth; i++) {
				for (j = 0; j < mapHeight; j++) {
					ct.color = normalMap.getPixel(i, j);
					var normal:Vector3D = new Vector3D((ct.redOffset - 128)/127,  (ct.greenOffset - 128)/127, (ct.blueOffset - 128)/127);
				//	var nLen:Number = Math.sqrt(normal.x*normal.x + normal.y*normal.y + normal.z*normal.z);
				//	var dot:Number = (normal.x/nLen)*lightVector.x + (normal.y/nLen)*lightVector.y + (normal.z/nLen)*lightVector.z;
					var dot:Number = (normal.x)*lightVector.x + (normal.y)*lightVector.y + (normal.z)*lightVector.z;
					
					var l:Number;
					if (dot < 0) {
						l = 0;
					} else {
						l = dot*255;
					}
					ct.redOffset = l;// + ambientR;
					ct.greenOffset = l;// + ambientG;
					ct.blueOffset = l;// + ambientB;
//					dot = dot*127 + 128;
//					ct.redOffset = dot;// + ambientR;
//					ct.greenOffset = dot;// + ambientG;
//					ct.blueOffset = dot;// + ambientB;
					lightMap.setPixel(i, j, ct.color);	
				}
			}
			trace("light", getTimer() - time);
			
			if (lightVector.x == 0 && lightVector.y == 0) return lightMap; 
			// Тени
			 lightMap = generateShadows(lightMap, lightVector);
//			
//			lightMap.applyFilter(lightMap, new Rectangle(0, 0, mapWidth, mapHeight), new Point(0, 0), gaussianFilter);
//			lightMap.applyFilter(lightMap, new Rectangle(0, 0, mapWidth, mapHeight), new Point(0, 0), gaussianFilter);
		//	lightMap.applyFilter(lightMap, new Rectangle(0, 0, mapWidth, mapHeight), new Point(0, 0), blurFilter);
			return lightMap;
			
		}
		
		private function generateShadows(lightMap:BitmapData, lightVector:Vector3D):BitmapData {
			var scale:Number = 1;
//			mapWidth *= scale;
//			mapHeight *= scale;
//			var tmp:BitmapData = new BitmapData(mapWidth, mapHeight);
//			tmp.draw(lightMap, new Matrix(scale, 0, 0, scale, 0, 0), null, null, null, false);
//			lightMap = tmp;
//		
			var time:Number = getTimer();
			var ct:ColorTransform = new ColorTransform();
			ct.redOffset = 0;
			ct.greenOffset = 0;
			ct.blueOffset = 0;
			var shadowColor:uint = ct.color;
//			var shadowColor:uint = ambientColor;
			var curColor:uint;
			if (lightVector.x != 0) {
				lightVector.y = lightVector.y/lightVector.x;
				lightVector.z = lightVector.z/lightVector.x;
				lightVector.x = 1;
			} else if (lightVector.y != 0) {
				lightVector.x = lightVector.x/lightVector.y;
				lightVector.z = lightVector.z/lightVector.y;
				lightVector.y = 1;
			}
		
			lightVector.z *= step;
			var point:Vector3D = new Vector3D();
			
			for (var i:uint = 0; i < mapWidth; i++) {
				for (var j:uint = 0; j < mapHeight; j++) {
					curColor = lightMap.getPixel(i, j); 
					if (curColor > shadowColor) {
						var flag:Boolean = true;
						//var point:Vector3D = new Vector3D(i, j, getHeight(i/scale, j/scale));
						point.x = i;
						point.y = j;
						point.z = heightMap.getHeight(uint(i/scale), uint(j/scale));
						while (flag) {
							point = getPointOnLightRay(lightVector, point, 0.1);
							if (point == null) {
								flag = false;
								point = new Vector3D();
							} else {
								if (point.z <= heightMap.getHeight(uint(point.x/scale), uint(point.y/scale))) {
									flag = false;	
								} else {
									lightMap.setPixel(point.x, point.y, shadowColor);
								}
							}
						}
					}
				}
			}
			trace("shadow", getTimer() - time);
			
			var array:Array = 	[0, 1, 0, 1, 4, 1, 0, 1, 0];
			var gaussianFilter:ConvolutionFilter = new ConvolutionFilter(3, 3, array, 8);
			lightMap.applyFilter(lightMap, new Rectangle(0, 0, mapWidth, mapHeight), new Point(0, 0), gaussianFilter);
			lightMap.applyFilter(lightMap, new Rectangle(0, 0, mapWidth, mapHeight), new Point(0, 0), gaussianFilter);
//			scale = 1/scale;
//			mapWidth *= scale;
//			mapHeight *= scale;
//			tmp = new BitmapData(mapWidth, mapHeight);
//			tmp.draw(lightMap, new Matrix(scale, 0, 0, scale, 0, 0), null, null, null, false);
//			lightMap = tmp;
			return lightMap;
		}
		
		private function getPointOnLightRay(vector:Vector3D, startPoint:Vector3D, threshold:Number = 0.1):Vector3D {
			var x:Number = startPoint.x - vector.x;
			var y:Number = startPoint.y - vector.y;
			var z:Number = startPoint.z - vector.z;
			startPoint.x = uint(x + 0.5);//Math.round(x);
			startPoint.y = uint(y + 0.5);//Math.round(y);
			startPoint.z = z;
			while (x < mapWidth && y < mapHeight && x >=0 && y >= 0 && z >=0) {
				var deltaX:Number = x - startPoint.x;
				deltaX = deltaX > 0 ? deltaX : -deltaX;
				var deltaY:Number =  y - startPoint.y;
				deltaY = deltaY > 0 ? deltaY : -deltaY;
				if (deltaX < threshold && deltaY < threshold) {
					return startPoint;
				}
//				if (Math.abs(x - startPoint.x) < threshold && Math.abs(y - startPoint.y) < threshold) {
//					return startPoint;
//				}
				x -= vector.x;
				y -= vector.y;
				z -= vector.z;
				startPoint.x = uint(x + 0.5);//Math.round(x);
				startPoint.y = uint(y + 0.5);//Math.round(y);
				startPoint.z = z;
			}
			
			return null;
			
		}
	}
}