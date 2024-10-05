package alternativa.engine3d.animation {

	import alternativa.engine3d.animation.keys.MatrixKey;
	import alternativa.engine3d.core.Object3D;
	
	import flash.geom.Vector3D;

	/**
	 * Анимация матрицы объекта.
	 */
	public class MatrixAnimation extends Animation {

		/**
		 * Временная шкала с ключевыми кадрами анимации матрицы. 
		 */
		public var matrix:Track;

		private var matrixKey:MatrixKey = new MatrixKey(0, null);

		/**
		 * Создает новый экземпляр объекта.
		 *  
		 * @param object объект, матрица которого анимируется.
		 * @param weight вес анимации.
		 * @param speed скорость проигрывания анимации.
		 */
		public function MatrixAnimation(object:Object3D = null, weight:Number = 1.0, speed:Number = 1.0) {
			super(object, weight, speed);
		}

		/**
		 * @inheritDoc
		 */
		override protected function control(position:Number, weight:Number):void {
			if (matrix != null && object != null) {
				matrix.getKey(position, matrixKey);
				var t:Vector3D = matrixKey.translation;
				var r:Vector3D = matrixKey.rotation;
				setEulerAngles(r);
				var s:Vector3D = matrixKey.scale;
				var c:Number;
 				c = calculateBlendInterpolation(WEIGHTS_X, weight);
				object.x = (1 - c)*object.x + c*t.x;
				c = calculateBlendInterpolation(WEIGHTS_Y, weight);
				object.y = (1 - c)*object.y + c*t.y;
				c = calculateBlendInterpolation(WEIGHTS_Z, weight);
				object.z = (1 - c)*object.z + c*t.z;
				c = calculateBlendInterpolation(WEIGHTS_ROT_X, weight);
				object.rotationX = interpolateAngle(object.rotationX, r.x, c);
				c = calculateBlendInterpolation(WEIGHTS_ROT_Y, weight);
				object.rotationY = interpolateAngle(object.rotationY, r.y, c);
				c = calculateBlendInterpolation(WEIGHTS_ROT_Z, weight);
				object.rotationZ = interpolateAngle(object.rotationZ, r.z, c);
				c = calculateBlendInterpolation(WEIGHTS_SCALE_X, weight);
				object.scaleX = (1 - c)*object.scaleX + c*s.x;
				c = calculateBlendInterpolation(WEIGHTS_SCALE_Y, weight);
				object.scaleY = (1 - c)*object.scaleY + c*s.y;
				c = calculateBlendInterpolation(WEIGHTS_SCALE_Z, weight);
				object.scaleZ = (1 - c)*object.scaleZ + c*s.z;
			}
		}

		private function setEulerAngles(quat:Vector3D):void {
			var qi2:Number = 2*quat.x*quat.x;
			var qj2:Number = 2*quat.y*quat.y;
			var qk2:Number = 2*quat.z*quat.z;
			var qij:Number = 2*quat.x*quat.y;
			var qjk:Number = 2*quat.y*quat.z;
			var qki:Number = 2*quat.z*quat.x;
			var qri:Number = 2*quat.w*quat.x;
			var qrj:Number = 2*quat.w*quat.y;
			var qrk:Number = 2*quat.w*quat.z;

			var aa:Number = 1 - qj2 - qk2;
			var bb:Number = qij - qrk;
			var ee:Number = qij + qrk;
			var ff:Number = 1 - qi2 - qk2;
			var ii:Number = qki - qrj;
			var jj:Number = qjk + qri;
			var kk:Number = 1 - qi2 - qj2;

			if (-1 < ii && ii < 1) {
				quat.x = Math.atan2(jj, kk);
				quat.y = -Math.asin(ii);
				quat.z = Math.atan2(ee, aa);
			} else {
				quat.x = 0;
				quat.y = (ii <= -1) ? Math.PI : -Math.PI;
				quat.y *= 0.5;
				quat.z = Math.atan2(-bb, ff);
			}
		}

		/**
		 * @inheritDoc 
		 */
		override public function clone():Animation {
			var cloned:MatrixAnimation = new MatrixAnimation(object, weight, speed);
			cloned.matrix = matrix;
			cloned.length = length;
			return cloned;
		}

		/**
		 * @inheritDoc
		 */
		override public function slice(start:Number, end:Number = Number.MAX_VALUE):Animation {
			var animation:MatrixAnimation = new MatrixAnimation(object, weight, speed);
			animation.matrix = (matrix != null) ? matrix.slice(start, end) : null;
			animation.updateLength();
			return animation;
		}

		/**
		 * @inheritDoc
		 */
		override public function updateLength():void {
			super.updateLength();
			if (matrix != null) {
				var len:Number = matrix.length;
				length = (len > length) ? len : length;
			}
		}

	}
}
