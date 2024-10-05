package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;

	import flash.geom.Matrix3D;

	use namespace alternativa3d;

	/**
	 * Ключевой кадр матричного типа. 
	 */
	public class MatrixKey extends Key {

		private static const tempMatrix:Matrix3D = new Matrix3D();

		/**
		 * Значение ключа. 
		 */
		public var matrix:Matrix3D;

		/**
		 * Создает ключевой кадр матричного типа.
		 *  
		 * @param time время кадра.
		 * @param matrix значение кадра.
		 */
		public function MatrixKey(time:Number, matrix:Matrix3D) {
			super(time);
			this.matrix = matrix;
		}

		/**
		 * @private 
		 */
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

		/**
		 * Строковое представление объекта. 
		 */
		public function toString():String {
			return "[MatrixKey " + time + ":" + matrix.rawData + "]";
		}

	}
}
