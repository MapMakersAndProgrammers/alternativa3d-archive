package alternativa.engine3d.core {
	
	import __AS3__.vec.Vector;
	import flash.geom.Matrix3D;
	
	public class BoundBox {
		
		public var minX:Number = Number.MAX_VALUE;
		public var minY:Number = Number.MAX_VALUE;
		public var minZ:Number = Number.MAX_VALUE;
		public var maxX:Number = -Number.MAX_VALUE;
		public var maxY:Number = -Number.MAX_VALUE;
		public var maxZ:Number = -Number.MAX_VALUE;
		
		public function setSize(minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number):void {
			this.minX = minX;
			this.minY = minY;
			this.minZ = minZ;
			this.maxX = maxX;
			this.maxY = maxY;
			this.maxZ = maxZ;
		}

		public function addBoundBox(boundBox:BoundBox):void {
			minX = (boundBox.minX < minX) ? boundBox.minX : minX;
			minY = (boundBox.minY < minY) ? boundBox.minY : minY;
			minZ = (boundBox.minZ < minZ) ? boundBox.minZ : minZ;
			maxX = (boundBox.maxX > maxX) ? boundBox.maxX : maxX;
			maxY = (boundBox.maxY > maxY) ? boundBox.maxY : maxY;
			maxZ = (boundBox.maxZ > maxZ) ? boundBox.maxZ : maxZ;
		}
		
		public function addPoint(x:Number, y:Number, z:Number):void {
			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
			if (z < minZ) minZ = z;
			if (z > maxZ) maxZ = z;
		}
		
		public function infinity():void {
			minX = minY = minZ = Number.MAX_VALUE;
			maxX = maxY = maxZ = -Number.MAX_VALUE;
		}
		
		public function copyFrom(boundBox:BoundBox):void {
			minX = boundBox.minX;
			minY = boundBox.minY;
			minZ = boundBox.minZ;
			maxX = boundBox.maxX;
			maxY = boundBox.maxY;
			maxZ = boundBox.maxZ;
		}
		
		public function clone():BoundBox {
			var clone:BoundBox = new BoundBox();
			clone.copyFrom(this); 
			return clone;
		}
		
		public function toString():String {
			return "BoundBox [" + minX.toFixed(2) + ", " + minY.toFixed(2) + ", " + minZ.toFixed(2) + " - " + maxX.toFixed(2) + ", " + maxY.toFixed(2) + ", " + maxZ.toFixed(2) + "]";
		}
		
	}
}
