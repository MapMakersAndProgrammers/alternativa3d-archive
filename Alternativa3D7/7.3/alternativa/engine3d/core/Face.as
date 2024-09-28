package alternativa.engine3d.core {
	import alternativa.engine3d.materials.Material;
	
	public class Face {
	
		public var material:Material;
	
		public var next:Face;
	
		public var negative:Face;
		public var positive:Face;
	
		public var wrapper:Wrapper;
	
		public var normalX:Number;
		public var normalY:Number;
		public var normalZ:Number;
		public var offset:Number;
	
		public var processNext:Face;
	
		public var distance:Number;
	
		public var geometry:Geometry;
	
		static public var collector:Face;
	
		static public function create():Face {
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
	
		public function create():Face {
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
		 * Расчёт нормали
		 * @param normalize Флаг нормализации
		 */
		/*public function calculateNormal(normalize:Boolean = false):void {
		 var w:Wrapper = wrapper;
		 var a:Vertex = w.vertex; w = w.next;
		 var b:Vertex = w.vertex; w = w.next;
		 var c:Vertex = w.vertex;
		 var abx:Number = b.x - a.x;
		 var aby:Number = b.y - a.y;
		 var abz:Number = b.z - a.z;
		 var acx:Number = c.x - a.x;
		 var acy:Number = c.y - a.y;
		 var acz:Number = c.z - a.z;
		 normalX = acz*aby - acy*abz;
		 normalY = acx*abz - acz*abx;
		 normalZ = acy*abx - acx*aby;
		 if (normalize) {
		 var length:Number = normalX*normalX + normalY*normalY + normalZ*normalZ;
		 if (length > 0.001) {
		 length = 1/Math.sqrt(length);
		 normalX *= length;
		 normalY *= length;
		 normalZ *= length;
		 }
		 }
		 offset = a.x*normalX + a.y*normalY + a.z*normalZ;
		 }*/
	
		/**
		 * Выстраивание вершин в лучшую последовательность и расчёт нормали
		 * @return Если грань не вырождена - true, иначе false
		 */
		public function calculateBestSequenceAndNormal():void {
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
					abx = b.x - a.x;
					aby = b.y - a.y;
					abz = b.z - a.z;
					acx = c.x - a.x;
					acy = c.y - a.y;
					acz = c.z - a.z;
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
			var abx:Number = b.x - a.x;
			var aby:Number = b.y - a.y;
			var abz:Number = b.z - a.z;
			var acx:Number = c.x - a.x;
			var acy:Number = c.y - a.y;
			var acz:Number = c.z - a.z;
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
			offset = a.x*nx + a.y*ny + a.z*nz;
		}
	
		/*public function destroy():void {
		 var w:Wrapper = wrapper;
		 w.vertex = null;
		 do {
		 w = w.next;
		 w.vertex = null;
		 } while (w.next != null);
		 w.next = Wrapper.collector;
		 Wrapper.collector = wrapper;
		 material = null;
		 wrapper = null;
		 //temporary = false;
		 processNext = null;
		 next = collector;
		 collector = this;
		 }*/
	
	}
}
