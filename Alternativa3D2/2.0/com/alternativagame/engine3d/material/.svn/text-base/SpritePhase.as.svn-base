package com.alternativagame.engine3d.material {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import com.alternativagame.engine3d.Matrix3D;
	import com.alternativagame.engine3d.Math3D;
	
	public class SpritePhase {
		
		// Битмапа фазы
		public var bitmapData:BitmapData;
		
		// Точка привязки битмапы
		private var _pivot:Point;
		
		private var _transform:Matrix3D;
		
		private var _pitch:Number;
		private var _yaw:Number;
		
		public function SpritePhase(bitmapData:BitmapData, pivot:Point, pitch:Number, yaw:Number) {
			this.bitmapData = bitmapData;
			_pivot = (pivot == null) ? new Point(bitmapData.width / 2, bitmapData.height / 2) : pivot;
			
			// Проверка углов
			pitch = Math3D.limitAngle(pitch);
			if (pitch < 0) {
				if (pitch < -90) {
					pitch = -180 - pitch;
					yaw += 180;
				}
			} else {
				if (pitch > 90) {
					pitch = 180 - pitch;
					yaw += 180;
				}
			}
			yaw = Math3D.limitAngle(yaw);
			
			// Сохраняем углы
			_pitch = pitch;
			_yaw = yaw;
			
			// Формируем матрицу трансформации фазы
			_transform = new Matrix3D();
			Math3D.translateMatrix(_transform, -_pivot.x, 0, _pivot.y);
			
			Math3D.rotateXMatrix(_transform, -_pitch);
			Math3D.rotateZMatrix(_transform, -_yaw);
		}
		
		public function get transform():Matrix3D {
			return _transform;
		}
		
		public function get pitch():Number {
			return _pitch;
		}
		
		public function get yaw():Number {
			return _yaw;
		}
		
		public function get pivot():Point {
			return _pivot;
		}
		
	}
}