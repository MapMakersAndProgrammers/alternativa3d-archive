package alternativa.engine3d.animation {
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;
	
	public class MatrixKey extends Key {
	
		public var matrix:Matrix3D;
	
		public function MatrixKey(time:Number, matrix:Matrix3D) {
			super(time);
			this.matrix = matrix;
		}
	
		override alternativa3d function interpolate(time:Number, next:Key, key:Key = null):Key {
			if (key != null) {
				key.time = time;
				MatrixKey(key).matrix = matrix;
				return key;
			} else {
				return new MatrixKey(time, matrix);
			}
		}
	
		public function toString():String {
			return "[MatrixKey " + time + ":" + matrix.rawData + "]";
		}
	
	}
}
