package com.alternativagame.engine3d {
	public final class Matrix3D {
		public var a:Number = 1;
		public var b:Number = 0;
		public var c:Number = 0;
		public var d:Number = 0;
		public var e:Number = 0;
		public var f:Number = 1;
		public var g:Number = 0;
		public var h:Number = 0;
		public var i:Number = 0;
		public var j:Number = 0;
		public var k:Number = 1;
		public var l:Number = 0;

		public function Matrix3D(x:Number = 0, y:Number = 0, z:Number = 0, rotX:Number = 0, rotY:Number = 0, rotZ:Number = 0, scaleX:Number = 1, scaleY:Number = 1, scaleZ:Number = 1) {
			// Если указано масштабирование
			if (arguments.length > 6) {
				Math3D.scaleMatrix(this, scaleX, scaleY, scaleZ);
			}
			// Если указан поворот
			if (arguments.length > 3) {
				Math3D.rotateMatrix(this, rotX, rotY, rotZ);
			}
			// Если указано смещение
			if (arguments.length > 0) {
				Math3D.translateMatrix(this, x, y, z);
			}
		}
		
		public function clone():Matrix3D {
			var res:Matrix3D = new Matrix3D();
			res.a = a;
			res.b = b;
			res.c = c;
			res.d = d;
			res.e = e;
			res.f = f;
			res.g = g;
			res.h = h;
			res.i = i;
			res.j = j;
			res.k = k;
			res.l = l;
			return res;
		}
		
		public function toString():String {
			return "Matrix:\r" + a.toFixed(3) + "\t" + b.toFixed(3) + "\t" + c.toFixed(3) + "\t" + d.toFixed(3) + "\r" + e.toFixed(3) + "\t" + f.toFixed(3) + "\t" + g.toFixed(3) + "\t" + h.toFixed(3) + "\r" + i.toFixed(3) + "\t" + j.toFixed(3) + "\t" + k.toFixed(3) + "\t" + l.toFixed(3);
		}
	}
}