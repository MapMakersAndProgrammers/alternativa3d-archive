package alternativa.engine3d.core {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	/**
	 * Грань, образованная тремя или более вершинами. Грани являются составными частями полигональных объектов.
	 * @see alternativa.engine3d.core.Geometry
	 * @see alternativa.engine3d.core.Vertex
	 */
	public class Face {
	
//		/**
//		 * Материал грани.
//		 * @see alternativa.engine3d.materials.Material
//		 */
//		public var material:Material;
	
		alternativa3d var geometry:Geometry;
	
		/**
		 * @private 
		 */
		alternativa3d var next:Face;
	
		/**
		 * @private 
		 */
		alternativa3d var wrapper:Wrapper;
	
		/**
		 * @private 
		 */
		alternativa3d var normalX:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var normalY:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var normalZ:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var offset:Number;
	
		/**
		 * @private 
		 */
		static alternativa3d var collector:Face;
	
		/**
		 * @private 
		 */
		static alternativa3d function create():Face {
			if (collector != null) {
				var res:Face = collector;
				collector = res.next;
				res.next = null;
				/*if (res.processNext != null) trace("!!!processNext!!!");
				if (res.geometry != null) trace("!!!geometry!!!");
				if (res.negative != null) trace("!!!negative!!!");
				if (res.positive != null) trace("!!!positive!!!");*/
				return res;
			} else {
				//trace("new Face");
				return new Face();
			}
		}
	
		/**
		 * @private 
		 */
		alternativa3d function create():Face {
			if (collector != null) {
				var res:Face = collector;
				collector = res.next;
				res.next = null;
				/*if (res.processNext != null) trace("!!!processNext!!!");
				if (res.geometry != null) trace("!!!geometry!!!");
				if (res.negative != null) trace("!!!negative!!!");
				if (res.positive != null) trace("!!!positive!!!");*/
				return res;
			} else {
				//trace("new Face");
				return new Face();
			}
		}
	
		/**
		 * Нормаль грани.
		 */
		public function get normal():Vector3D {
			var w:Wrapper = wrapper;
			var a:Vertex = w.vertex; w = w.next;
			var b:Vertex = w.vertex; w = w.next;
			var c:Vertex = w.vertex;
			var abx:Number = b._x - a._x;
			var aby:Number = b._y - a._y;
			var abz:Number = b._z - a._z;
			var acx:Number = c._x - a._x;
			var acy:Number = c._y - a._y;
			var acz:Number = c._z - a._z;
			var nx:Number = acz*aby - acy*abz;
			var ny:Number = acx*abz - acz*abx;
			var nz:Number = acy*abx - acx*aby;
			var len:Number = nx*nx + ny*ny + nz*nz;
			if (len > 0.001) {
				len = 1/Math.sqrt(len);
				nx *= len;
				ny *= len;
				nz *= len;
			}
			
			normalX = nx;
			normalY = ny;
			normalZ = nz;
			return new Vector3D(nx, ny, nz, a._x*nx + a._y*ny + a._z*nz);
		}
		
		
		public function getUV(point:Vector3D):Point {
			
			if (normalX != normalX) {
				var normal:Vector3D = normal;
				normalX = normal.x;
				normalY = normal.y;
				normalZ = normal.z;
			}
			
			var a:Vertex = wrapper.vertex;
			var b:Vertex = wrapper.next.vertex;
			var c:Vertex = wrapper.next.next.vertex;
			var abx:Number = b.x - a.x;
			var aby:Number = b.y - a.y;
			var abz:Number = b.z - a.z;
			var abu:Number = b.u - a.u;
			var abv:Number = b.v - a.v;
			var acx:Number = c.x - a.x;
			var acy:Number = c.y - a.y;
			var acz:Number = c.z - a.z;
			var acu:Number = c.u - a.u;
			var acv:Number = c.v - a.v;
			// Нахождение матрицы uv-трансформации
			var det:Number = -normalX*acy*abz + acx*normalY*abz + normalX*aby*acz - abx*normalY*acz - acx*aby*normalZ + abx*acy*normalZ;
			var ima:Number = (-normalY*acz + acy*normalZ)/det;
			var imb:Number = (normalX*acz - acx*normalZ)/det;
			var imc:Number = (-normalX*acy + acx*normalY)/det;
			var imd:Number = (a.x*normalY*acz - normalX*a.y*acz - a.x*acy*normalZ + acx*a.y*normalZ + normalX*acy*a.z - acx*normalY*a.z)/det;
			var ime:Number = (normalY*abz - aby*normalZ)/det;
			var imf:Number = (-normalX*abz + abx*normalZ)/det;
			var img:Number = (normalX*aby - abx*normalY)/det;
			var imh:Number = (normalX*a.y*abz - a.x*normalY*abz + a.x*aby*normalZ - abx*a.y*normalZ - normalX*aby*a.z + abx*normalY*a.z)/det;
			var ma:Number = abu*ima + acu*ime;
			var mb:Number = abu*imb + acu*imf;
			var mc:Number = abu*imc + acu*img;
			var md:Number = abu*imd + acu*imh + a.u;
			var me:Number = abv*ima + acv*ime;
			var mf:Number = abv*imb + acv*imf;
			var mg:Number = abv*imc + acv*img;
			var mh:Number = abv*imd + acv*imh + a.v;
			// UV
			return new Point(ma*point.x + mb*point.y + mc*point.z + md, me*point.x + mf*point.y + mg*point.z + mh);
		}
		
		/**
		 * Вершины, на базе которых построена грань.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function get vertices():Vector.<Vertex> {
			var res:Vector.<Vertex> = new Vector.<Vertex>();
			var len:int = 0;
			for (var w:Wrapper = wrapper; w != null; w = w.next) {
				res[len] = w.vertex;
				len++;
			}
			return res;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function calculateBestSequenceAndNormal():void {
			if (wrapper.next.next.next != null) {
				var max:Number = -1e+22;
				var s:Wrapper;
				var sm:Wrapper;
				var sp:Wrapper;
				for (w = wrapper; w != null; w = w.next) {
					var wn:Wrapper = (w.next != null) ? w.next : wrapper;
					var wm:Wrapper = (wn.next != null) ? wn.next : wrapper;
					a = w.vertex;
					b = wn.vertex;
					c = wm.vertex;
					abx = b._x - a._x;
					aby = b._y - a._y;
					abz = b._z - a._z;
					acx = c._x - a._x;
					acy = c._y - a._y;
					acz = c._z - a._z;
					nx = acz*aby - acy*abz;
					ny = acx*abz - acz*abx;
					nz = acy*abx - acx*aby;
					nl = nx*nx + ny*ny + nz*nz;
					if (nl > max) {
						max = nl;
						s = w;
					}
				}
				if (s != wrapper) {
					//for (sm = wrapper.next.next.next; sm.next != null; sm = sm.next);
					sm = wrapper.next.next.next;
					while (sm.next != null) sm = sm.next;
					//for (sp = wrapper; sp.next != s && sp.next != null; sp = sp.next);
					sp = wrapper;
					while (sp.next != s && sp.next != null) sp = sp.next;
					sm.next = wrapper;
					sp.next = null;
					wrapper = s;
				}
			}
			var w:Wrapper = wrapper;
			var a:Vertex = w.vertex;
			w = w.next;
			var b:Vertex = w.vertex;
			w = w.next;
			var c:Vertex = w.vertex;
			var abx:Number = b._x - a._x;
			var aby:Number = b._y - a._y;
			var abz:Number = b._z - a._z;
			var acx:Number = c._x - a._x;
			var acy:Number = c._y - a._y;
			var acz:Number = c._z - a._z;
			var nx:Number = acz*aby - acy*abz;
			var ny:Number = acx*abz - acz*abx;
			var nz:Number = acy*abx - acx*aby;
			var nl:Number = nx*nx + ny*ny + nz*nz;
			if (nl > 0) {
				nl = 1/Math.sqrt(nl);
				nx *= nl;
				ny *= nl;
				nz *= nl;
				normalX = nx;
				normalY = ny;
				normalZ = nz;
			}
			offset = a._x*nx + a._y*ny + a._z*nz;
		}
	
	}
}
