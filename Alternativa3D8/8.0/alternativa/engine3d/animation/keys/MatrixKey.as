package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;

	use namespace alternativa3d;

	/**
	 * Ключевой кадр матричного типа. 
	 */
	public class MatrixKey extends Key {

//		public static function test():void {
//			const min:Number = Math.PI / 3;
//			var key:MatrixKey = new MatrixKey(0);
//			trace("[1]");
//			testAll(0);
//			trace("[2]");
//			testAll(min);
//			trace("[3]");
//			testAll(2*min);
//			trace("[4]");
//			testAll(3*min);
//			trace("[5]");
//			testAll(-min);
//			trace("[6]");
//			testAll(-2*min);
//			trace("[7]");
//			testAll(-3*min);
//		}
//
//		private static function testAll(angle:Number):void {
//			const min:Number = Math.PI / 3;
//			const toDegree:Number = 180/Math.PI;
//			var key:MatrixKey = new MatrixKey(0);
//			trace("0", key.interpolateAngle(angle, 0, 0.1)*toDegree);
//			trace("60", key.interpolateAngle(angle, min, 0.1)*toDegree);
//			trace("120", key.interpolateAngle(angle, 2*min, 0.1)*toDegree);
//			trace("180", key.interpolateAngle(angle, 3*min, 0.1)*toDegree);
//			trace("-60", key.interpolateAngle(angle, -min, 0.1)*toDegree);
//			trace("-120", key.interpolateAngle(angle, -2*min, 0.1)*toDegree);
//			trace("-180", key.interpolateAngle(angle, -3*min, 0.1)*toDegree);
//		}
		
		/**
		 * Компоненты перемещения по осям X, Y, Z
		 */
		public var translation:Vector3D;
		/**
		 * Кватернион вращения
		 */
		public var rotation:Vector3D;
		/**
		 * Компоненты масштаба по осям X, Y, Z
		 */
		public var scale:Vector3D;

		/**
		 * Создает ключевой кадр матричного типа.
		 *  
		 * @param time время кадра.
		 * @param matrix значение кадра.
		 */
		public function MatrixKey(time:Number, matrix:Matrix3D = null) {
			super(time);
			if (matrix != null) {
				var v:Vector.<Vector3D> = matrix.decompose(Orientation3D.QUATERNION);
				translation = v[0];
				rotation = v[1];
				scale = v[2];
			} else {
				translation = new Vector3D();
   				rotation = new Vector3D();
				scale = new Vector3D();
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function interpolate(time:Number, next:Key, key:Key = null):Key {
			if (key != null) {
				key.time = time;
			} else {
				key = new MatrixKey(time);
			}
			var t:Vector3D = MatrixKey(key).translation;
			var r:Vector3D = MatrixKey(key).rotation;
			var s:Vector3D = MatrixKey(key).scale;
			if (next != null) {
				var nt:Vector3D = MatrixKey(next).translation;
				var nr:Vector3D = MatrixKey(next).rotation;
				var ns:Vector3D = MatrixKey(next).scale;
				var c2:Number = (time - this.time)/(next.time - this.time);
				var c1:Number = 1 - c2;
				t.x =  c1 * translation.x + c2 * nt.x;
				t.y =  c1 * translation.y + c2 * nt.y;
				t.z =  c1 * translation.z + c2 * nt.z;
				slerp(rotation, nr, c2, r);
				s.x =  c1 * scale.x + c2 * ns.x;
				s.y =  c1 * scale.y + c2 * ns.y;
				s.z =  c1 * scale.z + c2 * ns.z;
			} else {
				t.x = translation.x;
				t.y = translation.y;
				t.z = translation.z;
				r.x = rotation.x;
				r.y = rotation.y;
				r.z = rotation.z;
				s.x = scale.x;
				s.y = scale.y;
				s.z = scale.z;
			}
			return key;
		}

		/**
		 * Выполняет сферическую интерполяцию между двумя заданными кватернионами по наименьшему расстоянию.
		 * 
		 * @param a первый кватерион
		 * @param b второй кватернион
		 * @param t параметр интерполяции, обычно принадлежит отрезку [0, 1]
		 * @return this
		 */
		private function slerp(a:Vector3D, b:Vector3D, t:Number, result:Vector3D):void {
			var flip:Number = 1;
			// Так как одна и та же ориентация представляется двумя значениями q и -q, нужно сменить знак одного из кватернионов
			// если скалярное произведение отрицательно. Иначе будет получено интерполированное значение по наибольшему расстоянию.
			var cosine:Number = a.w*b.w + a.x*b.x + a.y*b.y + a.z*b.z;
			if (cosine < 0)	{ 
				cosine = -cosine; 
				flip = -1; 
			}
			if ((1 - cosine) < 0.001) {
				// Вблизи нуля используется линейная интерполяция
				var k1:Number = 1 - t;
				var k2:Number = t*flip;
				result.w = a.w*k1 + b.w*k2;
				result.x = a.x*k1 + b.x*k2;
				result.y = a.y*k1 + b.y*k2;
				result.z = a.z*k1 + b.z*k2;
				var d:Number = result.w*result.w + result.x*result.x + result.y*result.y + result.z*result.z;
				if (d == 0) {
					result.w = 1;
				} else {
					result.scaleBy(1/Math.sqrt(d));
				}
			} else {
				var theta:Number = Math.acos(cosine); 
				var sine:Number = Math.sin(theta); 
				var beta:Number = Math.sin((1 - t)*theta)/sine; 
				var alpha:Number = Math.sin(t*theta)/sine*flip;
				result.w = a.w*beta + b.w*alpha;
				result.x = a.x*beta + b.x*alpha;
				result.y = a.y*beta + b.y*alpha;
				result.z = a.z*beta + b.z*alpha;
			}
		}

		/**
		 * Интерполяция между двумя ненормализованными углами.
		 */
		private function interpolateAngle(angle1:Number, angle2:Number, c:Number):Number {
			const PI:Number = Math.PI;
			const PITwice:Number = 2*PI;
			var delta:Number = angle2 - angle1;
			if (delta > PI) {
				delta -= PITwice;
			} else if (delta < -PI) {
				delta += PITwice;
			}
//			if (delta < (PI + 0.01) && delta > (PI - 0.01)) {
//				trace("[BDif+]", angle1, angle2);
//			}
//			if (delta < (-PI + 0.01) && delta > (-PI - 0.01)) {
//				trace("[BDif-]", angle1, angle2);
//			}
			return angle1 + c * delta;
		}
//		private function interpolateAngle(angle1:Number, angle2:Number, c:Number):Number {
//			const PI2:Number = 2*Math.PI;
//			angle1 = (angle1 > Math.PI) ? angle1%PI2 - PI2 : (angle1 <= -Math.PI) ? (angle1%PI2) + PI2 : angle1;
//			angle2 = (angle2 > Math.PI) ? angle2%PI2 - PI2 : (angle2 <= -Math.PI) ? (angle2%PI2) + PI2 : angle2;
//			var delta:Number = angle2 - angle1;
//			delta = (delta > Math.PI) ? delta - PI2 : (delta < -Math.PI) ? delta + PI2 : delta;
//			return angle1 + c * delta;
//		}

		/**
		 * Создает и возвращает матрицу на основе компонентов ключа
		 */
		public function getMatrix():Matrix3D {
			var m:Matrix3D = new Matrix3D();
			var v:Vector.<Vector3D> = new Vector.<Vector3D>(3);
			v[0] = translation;
			v[1] = rotation;
			v[2] = scale;
			m.recompose(v, Orientation3D.QUATERNION);
			return m;
		}

		/**
		 * Устанавливает значения компонентов ключа из матрицы
		 */
		public function setMatrix(value:Matrix3D):void {
			var v:Vector.<Vector3D> = value.decompose(Orientation3D.QUATERNION);
			translation = v[0];
			rotation = v[1];
			scale = v[2];
		}

		/**
		 * Строковое представление объекта. 
		 */
		public function toString():String {
			return "[MatrixKey " + time + " translation:" + translation.toString() + " rotation:" + rotation + " scale:" + scale + "]]";
		}

	}
}
