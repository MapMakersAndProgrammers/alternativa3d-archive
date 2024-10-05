package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;

	import flash.geom.Matrix3D;

	use namespace alternativa3d;
	
	public class MatrixKey extends Key {

		private static const tempMatrix:Matrix3D = new Matrix3D();

		public var matrix:Matrix3D;
	
		public function MatrixKey(time:Number, matrix:Matrix3D) {
			super(time);
			this.matrix = matrix;
		}
	
		override alternativa3d function interpolate(time:Number, next:Key, key:Key = null):Key {
			var mat:Matrix3D;
			if (next != null) {
				mat = tempMatrix;
				mat.identity();
				mat.append(matrix);
				mat.interpolateTo((next as MatrixKey).matrix, (time - this.time)/(next.time - this.time));
			} else {
				mat = matrix;
			}
			if (key != null) {
				key.time = time;
				MatrixKey(key).matrix = mat;
				return key;
			} else {
				return new MatrixKey(time, mat);
			}
		}
	
		public function toString():String {
			return "[MatrixKey " + time + ":" + matrix.rawData + "]";
		}
	
	}
}
