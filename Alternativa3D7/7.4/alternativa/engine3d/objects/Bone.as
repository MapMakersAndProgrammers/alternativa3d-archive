package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	
	use namespace alternativa3d;
	
	public class Bone extends Joint {
	
		public var length:Number;
		public var distance:Number;
	
		// Длина кости
		private var lx:Number;
		private var ly:Number;
		private var lz:Number;
		private var ldot:Number;
	
		public function Bone(length:Number, distance:Number) {
			this.length = length;
			this.distance = distance;
		}
	
		override alternativa3d function calculateBindingMatrix(parent:Object3D):void {
			super.calculateBindingMatrix(parent);
			lx = mc*length;
			ly = mg*length;
			lz = mk*length;
			ldot = lx*lx + ly*ly + lz*lz;
		}
	
		public function bindVerticesByDistance(skin:Skin):void {
			for (var vertex:Vertex = skin.vertexList; vertex != null; vertex = vertex.next) bindVertexByDistance(vertex);
		}
	
		public function bindVertexByDistance(vertex:Vertex):void {
			var vx:Number = vertex.x - md;
			var vy:Number = vertex.y - mh;
			var vz:Number = vertex.z - ml;
			var dot:Number = vx*lx + vy*ly + vz*lz;
			if (dot > 0) {
				if (ldot > dot) {
					dot /= ldot;
					vx = vertex.x - md - dot*lx;
					vy = vertex.y - mh - dot*ly;
					vz = vertex.z - ml - dot*lz;
				} else {
					vx -= lx;
					vy -= ly;
					vz -= lz;
				}
			}
			bindVertex(vertex, 1 - Math.sqrt(vx*vx + vy*vy + vz*vz)/distance);
		}
	
	}
}