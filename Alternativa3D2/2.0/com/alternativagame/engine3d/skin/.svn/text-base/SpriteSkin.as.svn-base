package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.Matrix3D;
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.SpriteMaterial;
	import com.alternativagame.engine3d.material.SpritePhase;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.object.SkinObject3D;
	import com.alternativagame.engine3d.object.Sprite3D;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	use namespace engine3d;

	public class SpriteSkin extends ObjectSkin {
		
		use namespace engine3d;
		
		// Битмапа
		private var bitmap:Bitmap;
		
		public function SpriteSkin(object:Sprite3D) {
			super(object);
			
			bitmap = new Bitmap();
			addChild(bitmap);
		}

		private function viewAngle(vector:Vector):Number {
			var len:Number = Math3D.vectorLength(vector);
			// Если вектор нулевой, угол - 0 градусов
			var cos:Number = (len != 0) ? (vector.y / len) : 1;
			return Math.acos(cos);
		}
		
		override engine3d function draw():void {
			super.draw();

			var objTransform:Matrix3D = object.transform.clone();
			objTransform.d = 0;
			objTransform.h = 0;
			objTransform.l = 0;
			
			var material:SpriteMaterial = SpriteMaterial(this.material);

			// Угол оси Z с вектором камеры 
			var pitchAngle:Number = viewAngle(new Vector(objTransform.c, objTransform.g, objTransform.k)) - Math.PI/2;
			
			// Угол оси X с вектором камеры
			var yawAngle:Number = viewAngle(new Vector(objTransform.a, objTransform.e, objTransform.i));
			if (objTransform.f > 0) yawAngle = -yawAngle;
			yawAngle += Math.PI/2;
			
			// Находим подходящую фазу
			var phase:SpritePhase = material.getPhase(Sprite3D(object).state, Math3D.toDegree(pitchAngle), Math3D.toDegree(yawAngle));
			if (phase != null) {
				bitmap.bitmapData = phase.bitmapData;
				bitmap.smoothing = material.smoothing;
				

				// Матрица преобразования скина
				var matrix:Matrix = new Matrix();
				matrix.tx = x;
				matrix.ty = y;
				
				var pivot:Point = new Point();
				// Трансформация в зависимости от флагов
				if (material.scale || material.rotate) {
					var m:Matrix3D = Math3D.combineMatrix(objTransform, phase.transform);
				}
				if (material.scale) {
					if (material.rotate) {
						// Полная трансформация
						matrix.a = m.a;
						matrix.b = -m.i;
						matrix.c = -m.c;
						matrix.d = m.k;
					} else {
						// Только масштабирование
						matrix.a = Math.sqrt(m.a*m.a + m.c*m.c);
						matrix.d = Math.sqrt(m.i*m.i + m.k*m.k);
					}
				} else {
					if (material.rotate) {
						// Только поворот
						var lenX:Number = Math.sqrt(m.a*m.a + m.c*m.c);
						var ma:Number = m.a/lenX;
						var mc:Number = m.c/lenX;
						matrix.a = ma;
						matrix.b = mc;
						matrix.c = -mc;
						matrix.d = ma;
					}
				}
				// Наложить матрицу на битмапу
				bitmap.x = -phase.pivot.x;
				bitmap.y = -phase.pivot.y;
				transform.matrix = matrix;
			} else {
				bitmap.bitmapData = null;
			}
		}
		
		override engine3d function light():void {
			var color:RGB = SkinObject3D(object).lightColor.clone();

			// Добавить самосвечение
			var selfIllumination:RGB = SpriteMaterial(this.material).selfIllumination;
			color.add(selfIllumination);
			
			var redMultiplier:Number = (color.red/5 + color.red*0.6 + 30) / 127;
			var greenMultiplier:Number = (color.green/5 + color.green*0.6 + 30) / 127;
			var blueMultiplier:Number = (color.blue/5 + color.blue*0.6 + 30) / 127;
			var redOffset:Number = (color.red - 127) * 0.65;
			var greenOffset:Number = (color.green - 127) * 0.65;
			var blueOffset:Number = (color.blue - 127) * 0.65;
			
			transform.colorTransform = new ColorTransform(redMultiplier, greenMultiplier, blueMultiplier, alpha, redOffset, greenOffset, blueOffset);
		}

	}
}