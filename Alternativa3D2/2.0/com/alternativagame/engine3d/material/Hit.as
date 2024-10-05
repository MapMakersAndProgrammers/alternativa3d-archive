package com.alternativagame.engine3d.material {
	import flash.geom.Point;
	import com.alternativagame.engine3d.Math3D;
	
	public final class Hit {
		
		static public function ngon(n:uint, radiusX:Number, radiusY:Number = -1, offsetX:Number = 0, offsetY:Number = 0, angle:Number = 0):Array {
			var res:Array = new Array();
			n = (n < 3) ? 3 : n;
			radiusY = (radiusY < 0) ? radiusX : radiusY;
			angle = Math3D.toRadian(angle);
			var sin:Number = Math.sin(angle);
			var cos:Number = Math.cos(angle);
			
			var a:Number = (Math.PI+Math.PI) / n; 
			for (var i:uint = 0; i < n; i++) {
				var x:Number = offsetX + Math.sin(a*i)*radiusX;
				var y:Number = offsetY - Math.cos(a*i)*radiusY;
				
				var cx:Number = x*cos - y*sin; 
				var cy:Number = y*cos + x*sin;
				
				res.push(new Point(cx, cy));
			}
			return res;
		}
		
		static public function rectangle(width:Number, height:Number, offsetX:Number = 0, offsetY:Number = 0):Array {
			var res:Array = new Array();
			var hw:Number = width/2;
			var hh:Number = height/2;
			res.push(new Point(offsetX - hw, offsetY - hh));
			res.push(new Point(offsetX + hw, offsetY - hh));
			res.push(new Point(offsetX + hw, offsetY + hh));
			res.push(new Point(offsetX - hw, offsetY + hh));
			return res;
		}
		
	}
}