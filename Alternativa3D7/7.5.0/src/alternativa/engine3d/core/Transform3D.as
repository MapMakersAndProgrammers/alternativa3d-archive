package alternativa.engine3d.core {
	
	import alternativa.engine3d.alternativa3d;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	public class Transform3D {
	
		/**
		 * Имя объекта.
		 */
		public var name:String;
	
		/**
		 * Координата X.
		 */
		public var x:Number = 0;
		
		/**
		 * Координата Y.
		 */
		public var y:Number = 0;
		
		/**
		 * Координата Z.
		 */
		public var z:Number = 0;
		
		/**
		 * Угол поворота вокруг оси X.
		 * Указывается в радианах.
		 */
		public var rotationX:Number = 0;
		
		/**
		 * Угол поворота вокруг оси Y.
		 * Указывается в радианах.
		 */
		public var rotationY:Number = 0;
		
		/**
		 * Угол поворота вокруг оси Z.
		 * Указывается в радианах.
		 */
		public var rotationZ:Number = 0;
		
		/**
		 * Коэффициент масштабирования по оси X.
		 */
		public var scaleX:Number = 1;
		
		/**
		 * Коэффициент масштабирования по оси Y.
		 */
		public var scaleY:Number = 1;
		
		/**
		 * Коэффициент масштабирования по оси Z.
		 */
		public var scaleZ:Number = 1;
	
		// Матрица
		
		/**
		 * @private 
		 */
		alternativa3d var ma:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mb:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mc:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var md:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var me:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mf:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mg:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mh:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mi:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mj:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mk:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var ml:Number;
	
		// Инверсная матрица
		
		/**
		 * @private 
		 */
		alternativa3d var ima:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imb:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imc:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imd:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var ime:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imf:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var img:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imh:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imi:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imj:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imk:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var iml:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var weightsSum:Vector.<Number>;
		
		/**
		 * Объект <code>Matrix3D</code>, содержащий значения, влияющие на масштабирование, поворот и перемещение объекта.
		 */
		public function get matrix():Matrix3D {
			var m:Matrix3D = new Matrix3D();
			var t:Vector3D = new Vector3D(x, y, z);
			var r:Vector3D = new Vector3D(rotationX, rotationY, rotationZ);
			var s:Vector3D = new Vector3D(scaleX, scaleY, scaleZ);
			var v:Vector.<Vector3D> = new Vector.<Vector3D>();
			v[0] = t;
			v[1] = r;
			v[2] = s;
			m.recompose(v);
			return m;
		}
	
		/**
		 * @private
		 */
		public function set matrix(value:Matrix3D):void {
			var v:Vector.<Vector3D> = value.decompose();
			var t:Vector3D = v[0];
			var r:Vector3D = v[1];
			var s:Vector3D = v[2];
			x = t.x;
			y = t.y;
			z = t.z;
			rotationX = r.x;
			rotationY = r.y;
			rotationZ = r.z;
			scaleX = s.x;
			scaleY = s.y;
			scaleZ = s.z;
		}
	
		/**
		 * @private 
		 */
		alternativa3d function composeMatrix():void {
			var cosX:Number = Math.cos(rotationX);
			var sinX:Number = Math.sin(rotationX);
			var cosY:Number = Math.cos(rotationY);
			var sinY:Number = Math.sin(rotationY);
			var cosZ:Number = Math.cos(rotationZ);
			var sinZ:Number = Math.sin(rotationZ);
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			var cosYscaleX:Number = cosY*scaleX;
			var sinXscaleY:Number = sinX*scaleY;
			var cosXscaleY:Number = cosX*scaleY;
			var cosXscaleZ:Number = cosX*scaleZ;
			var sinXscaleZ:Number = sinX*scaleZ;
			ma = cosZ*cosYscaleX;
			mb = cosZsinY*sinXscaleY - sinZ*cosXscaleY;
			mc = cosZsinY*cosXscaleZ + sinZ*sinXscaleZ;
			md = x;
			me = sinZ*cosYscaleX;
			mf = sinZsinY*sinXscaleY + cosZ*cosXscaleY;
			mg = sinZsinY*cosXscaleZ - cosZ*sinXscaleZ;
			mh = y;
			mi = -sinY*scaleX;
			mj = cosY*sinXscaleY;
			mk = cosY*cosXscaleZ;
			ml = z;
		}
	
		/**
		 * @private 
		 */
		alternativa3d function appendMatrix(transform:Transform3D):void {
			var a:Number = ma;
			var b:Number = mb;
			var c:Number = mc;
			var d:Number = md;
			var e:Number = me;
			var f:Number = mf;
			var g:Number = mg;
			var h:Number = mh;
			var i:Number = mi;
			var j:Number = mj;
			var k:Number = mk;
			var l:Number = ml;
			ma = transform.ma*a + transform.mb*e + transform.mc*i;
			mb = transform.ma*b + transform.mb*f + transform.mc*j;
			mc = transform.ma*c + transform.mb*g + transform.mc*k;
			md = transform.ma*d + transform.mb*h + transform.mc*l + transform.md;
			me = transform.me*a + transform.mf*e + transform.mg*i;
			mf = transform.me*b + transform.mf*f + transform.mg*j;
			mg = transform.me*c + transform.mf*g + transform.mg*k;
			mh = transform.me*d + transform.mf*h + transform.mg*l + transform.mh;
			mi = transform.mi*a + transform.mj*e + transform.mk*i;
			mj = transform.mi*b + transform.mj*f + transform.mk*j;
			mk = transform.mi*c + transform.mj*g + transform.mk*k;
			ml = transform.mi*d + transform.mj*h + transform.mk*l + transform.ml;
		}
	
		/**
		 * @private 
		 */
		alternativa3d function composeAndAppend(transform:Transform3D):void {
			var cosX:Number = Math.cos(rotationX);
			var sinX:Number = Math.sin(rotationX);
			var cosY:Number = Math.cos(rotationY);
			var sinY:Number = Math.sin(rotationY);
			var cosZ:Number = Math.cos(rotationZ);
			var sinZ:Number = Math.sin(rotationZ);
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			var cosYscaleX:Number = cosY*scaleX;
			var sinXscaleY:Number = sinX*scaleY;
			var cosXscaleY:Number = cosX*scaleY;
			var cosXscaleZ:Number = cosX*scaleZ;
			var sinXscaleZ:Number = sinX*scaleZ;
			var a:Number = cosZ*cosYscaleX;
			var b:Number = cosZsinY*sinXscaleY - sinZ*cosXscaleY;
			var c:Number = cosZsinY*cosXscaleZ + sinZ*sinXscaleZ;
			var d:Number = x;
			var e:Number = sinZ*cosYscaleX;
			var f:Number = sinZsinY*sinXscaleY + cosZ*cosXscaleY;
			var g:Number = sinZsinY*cosXscaleZ - cosZ*sinXscaleZ;
			var h:Number = y;
			var i:Number = -sinY*scaleX;
			var j:Number = cosY*sinXscaleY;
			var k:Number = cosY*cosXscaleZ;
			var l:Number = z;
			ma = transform.ma*a + transform.mb*e + transform.mc*i;
			mb = transform.ma*b + transform.mb*f + transform.mc*j;
			mc = transform.ma*c + transform.mb*g + transform.mc*k;
			md = transform.ma*d + transform.mb*h + transform.mc*l + transform.md;
			me = transform.me*a + transform.mf*e + transform.mg*i;
			mf = transform.me*b + transform.mf*f + transform.mg*j;
			mg = transform.me*c + transform.mf*g + transform.mg*k;
			mh = transform.me*d + transform.mf*h + transform.mg*l + transform.mh;
			mi = transform.mi*a + transform.mj*e + transform.mk*i;
			mj = transform.mi*b + transform.mj*f + transform.mk*j;
			mk = transform.mi*c + transform.mj*g + transform.mk*k;
			ml = transform.mi*d + transform.mj*h + transform.mk*l + transform.ml;
		}
	
		/**
		 * @private 
		 */
		alternativa3d function calculateInverseMatrix():void {
			var det:Number = 1/(-mc*mf*mi + mb*mg*mi + mc*me*mj - ma*mg*mj - mb*me*mk + ma*mf*mk);
			ima = (-mg*mj + mf*mk)*det;
			imb = (mc*mj - mb*mk)*det;
			imc = (-mc*mf + mb*mg)*det;
			imd = (md*mg*mj - mc*mh*mj - md*mf*mk + mb*mh*mk + mc*mf*ml - mb*mg*ml)*det;
			ime = (mg*mi - me*mk)*det;
			imf = (-mc*mi + ma*mk)*det;
			img = (mc*me - ma*mg)*det;
			imh = (mc*mh*mi - md*mg*mi + md*me*mk - ma*mh*mk - mc*me*ml + ma*mg*ml)*det;
			imi = (-mf*mi + me*mj)*det;
			imj = (mb*mi - ma*mj)*det;
			imk = (-mb*me + ma*mf)*det;
			iml = (md*mf*mi - mb*mh*mi - md*me*mj + ma*mh*mj + mb*me*ml - ma*mf*ml)*det;
		}

	}
}
