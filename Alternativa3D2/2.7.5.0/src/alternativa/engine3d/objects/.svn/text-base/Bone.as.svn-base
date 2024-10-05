package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.Vertex;
	
	use namespace alternativa3d;
	
	/**
	 * <code>Bone</code> является составной частью объекта <code>Skin</code>.
	 * Используется в скелетной анимации.
	 * @see alternativa.engine3d.objects.Skin
	 */
	public class Bone extends Joint {
	
		/**
		 * Длина кости.
		 */
		public var length:Number;
		
		/**
		 * Дистанция влияния на вершины.
		 */
		public var distance:Number;
	
		// Длина кости
		
		/**
		 * @private 
		 */
		alternativa3d var lx:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var ly:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var lz:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var ldot:Number;
	
		/**
		 * Создаёт новый экземпляр.
		 * @param length Длина кости.
		 * @param distance Дистанция влияния на вершины.
		 * 
		 */
		public function Bone(length:Number, distance:Number) {
			this.length = length;
			this.distance = distance;
		}
	
		/**
		 * Создаёт связи с вершина по дистанции.
		 * @param skin Объект <code>Skin</code>, в котором находится кость.
		 * @see alternativa.engine3d.objects.Skin
		 */
		public function bindVerticesByDistance(skin:Skin):void {
			for (var vertex:Vertex = skin.vertexList; vertex != null; vertex = vertex.next) bindVertexByDistance(vertex);
		}
	
		/**
		 * Создаёт связь с вершиной.
		 * @param vertex Вершина.
		 * @see alternativa.engine3d.core.Vertex
		 */
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
		
		/**
		 * @private 
		 */
		override alternativa3d function calculateBindingMatrix(parent:Transform3D):void {
			super.calculateBindingMatrix(parent);
			lx = mc*length;
			ly = mg*length;
			lz = mk*length;
			ldot = lx*lx + ly*ly + lz*lz;
		}
	
		/**
		 * @private 
		 */
		override alternativa3d function drawDebug(camera:Camera3D, canvas:Canvas):void {
			if (numJoints == 0) {
				var x1:Number = md*camera.viewSizeX/ml;
				var y1:Number = mh*camera.viewSizeY/ml;
				var z:Number = mi*length + ml;
				var x2:Number = (ma*length + md)*camera.viewSizeX/z;
				var y2:Number = (me*length + mh)*camera.viewSizeY/z;
				if (ml > 0 && z > 0) {
					Debug.drawBone(canvas, x1, y1, x2, y2, 10*camera.focalLength/ml, 0x0099FF);
				}
			} else {
				super.drawDebug(camera, canvas);
			}
		}
		
	}
}
