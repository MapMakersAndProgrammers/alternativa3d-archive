package com.alternativagame.engine3d {
	import com.alternativagame.type.Vector;
	import flash.geom.Point;
	
	public final class Math3D {
		static private var toRad:Number = Math.PI/180;
		static private var toDeg:Number = 180/Math.PI;

		// Перевести в радианы
		static public function toRadian(n:Number):Number {
			return n*toRad;
		}
		
		// Перевести в градусы
		static public function toDegree(n:Number):Number {
			return n*toDeg;
		}
		
		// Перевести значение градуса в пределы -180..180
		static public function limitAngle(n:Number):Number {
			var res:Number = n % 360;
			res = (res > 0) ? ((res > 180) ? (res - 360) : res) : ((res < -180) ? (res + 360) : res);
			return res;
		}
		
		// Кратчайшая разница углов (углы должны быть лимитированы)
		static public function deltaAngle(a:Number, b:Number):Number {
			var delta:Number = b - a;
			if (delta > 180) {
				return delta - 360;
			} else {
				if (delta < -180) {
					return delta + 360;
				} else {
					return delta;
				}
			}
		}
		
		static public function random(... args):Number {
			if (args.length == 0) {
				return Math.random();
			} else {
				if (args.length == 1) {
					return Math.random()*args[0];
				} else {
					return Math.random()*(args[1]-args[0])+args[0];
				}
			}
		}

		// Длина вектора
		static public function vectorLength(v:Vector):Number {
			return Math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
		}

		// Длина вектора
		static public function vectorLengthSquare(v:Vector):Number {
			return v.x*v.x + v.y*v.y + v.z*v.z;
		}
		
		// Нормализовать вектор
		static public function normalize(v:Vector):void {
			var n:Number = vectorLength(v);
			if (n !== 0) {
				v.x /= n;
				v.y /= n;
				v.z /= n;
			} else {
				v.x = 0;
				v.y = 0;
				v.z = 0;
			}
		}
		
		// Сложение векторов
		static public function vectorAdd(v1:Vector, v2:Vector):Vector {
			return new Vector(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
		}
		
		// Вычитание векторов
		static public function vectorSub(v1:Vector, v2:Vector):Vector {
			return new Vector(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z);
		}

		// Умножить вектор на скаляр
		static public function vectorMultiply(v:Vector, n:Number):Vector {
			return new Vector(v.x*n, v.y*n, v.z*n);
		}


		// Скалярное произведение векторов
		static public function vectorDot(v1:Vector, v2:Vector):Number {
			return (v1.x*v2.x + v1.y*v2.y + v1.z*v2.z);
		}

		// Векторное произведение векторов
		static public function vectorCross(v1:Vector, v2:Vector):Vector {
			return new Vector(v1.y*v2.z - v1.z*v2.y, v1.z*v2.x - v1.x*v2.z, v1.x*v2.y - v1.y*v2.x);
		}

		// Угол между векторами
		static public function vectorAngle(v1:Vector, v2:Vector):Number {
			var len:Number = vectorLength(v1)*vectorLength(v2);
			// Если один из векторов нулевой, угол - 0 градусов
			var cos:Number = (len != 0) ? (vectorDot(v1, v2) / len) : 1;
			return Math.acos(cos);
		}

		// Угол между векторами (работает только если векторы нормализованы)		
		static public function vectorAngleFast(v1:Vector, v2:Vector):Number {
			return Math.acos(vectorDot(v1, v2));
		}
		
		// Отбрасывает дробную часть у координат вектора
		static public function vectorFloor(v:Vector):Vector {
			return new Vector(Math.floor(v.x), Math.floor(v.y), Math.floor(v.z));
		}
		
		// Сравнение векторов с погрешностью
		static public function vectorEquals(v1:Vector, v2:Vector, delta:Number = 0):Boolean {
			var d:Vector = vectorSub(v1, v2);
			return (Math.abs(d.x) <= delta) && (Math.abs(d.y) <= delta) && (Math.abs(d.z) <= delta);
		}
		
		// Нахождение нормали грани
		static public function normal(points:Array):Vector {
			var v1:Vector = new Vector(points[1].x - points[0].x, points[1].y - points[0].y, points[1].z - points[0].z);
			var v2:Vector = new Vector(points[1].x - points[2].x, points[1].y - points[2].y, points[1].z - points[2].z);
			var res:Vector = vectorCross(v1, v2);
			normalize(res);
			return res;
		}
		
		// Перенос матрицы
		static public function translateMatrix(m:Matrix3D, x:Number, y:Number, z:Number):void {
			m.d += x;
			m.h += y;
			m.l += z;
		}

		// Масштабирование матрицы
		static public function scaleMatrix(m:Matrix3D, x:Number, y:Number, z:Number):void {
			m.a *= x;
			m.b *= x;
			m.c *= x;
			m.d *= x;
			m.e *= y;
			m.f *= y;
			m.g *= y;
			m.h *= y;
			m.i *= z;
			m.j *= z;
			m.k *= z;
			m.l *= z;
		}

		// Масштабирование матрицы по X
		static public function scaleXMatrix(m:Matrix3D, value:Number):void {
			m.a *= value;
			m.b *= value;
			m.c *= value;
			m.d *= value;
		}

		// Масштабирование матрицы по Y
		static public function scaleYMatrix(m:Matrix3D, value:Number):void {
			m.e *= value;
			m.f *= value;
			m.g *= value;
			m.h *= value;
		}
		
		// Масштабирование матрицы по Z
		static public function scaleZMatrix(m:Matrix3D, value:Number):void {
			m.i *= value;
			m.j *= value;
			m.k *= value;
			m.l *= value;
		}

		// Поворот матрицы
		static public function rotateMatrix(m:Matrix3D, x:Number, y:Number, z:Number):void {
			var xRadian:Number = Math3D.toRadian(x);
			var yRadian:Number = Math3D.toRadian(y);
			var zRadian:Number = Math3D.toRadian(z);
			var cosX:Number = Math.cos(xRadian);
			var sinX:Number = Math.sin(xRadian);
			var cosY:Number = Math.cos(yRadian);
			var sinY:Number = Math.sin(yRadian);
			var cosZ:Number = Math.cos(zRadian);
			var sinZ:Number = Math.sin(zRadian);

			var a:Number = m.a;
			var b:Number = m.b;
			var c:Number = m.c;
			var d:Number = m.d;
			var e:Number = m.e;
			var f:Number = m.f;
			var g:Number = m.g;
			var h:Number = m.h;
			var i:Number = m.i;
			var j:Number = m.j;
			var k:Number = m.k;
			var l:Number = m.l;
			
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			
			var ra:Number = cosZ*cosY;
			var rb:Number = cosZsinY*sinX - sinZ*cosX;
			var rc:Number = cosZsinY*cosX + sinZ*sinX;

			var re:Number = sinZ*cosY;
			var rf:Number = sinZsinY*sinX + cosZ*cosX;
			var rg:Number = sinZsinY*cosX - cosZ*sinX;
			
			var ri:Number = -sinY;
			var rj:Number = cosY*sinX;
			var rk:Number = cosY*cosX;

			m.a = ra*a + rb*e + rc*i;
			m.b = ra*b + rb*f + rc*j;
			m.c = ra*c + rb*g + rc*k;
			m.d = ra*d + rb*h + rc*l;

			m.e = re*a + rf*e + rg*i;
			m.f = re*b + rf*f + rg*j;
			m.g = re*c + rf*g + rg*k;
			m.h = re*d + rf*h + rg*l;

			m.i = ri*a + rj*e + rk*i;
			m.j = ri*b + rj*f + rk*j;
			m.k = ri*c + rj*g + rk*k;
			m.l = ri*d + rj*h + rk*l;

		}

		// Поворот матрицы вдоль X
		static public function rotateXMatrix(m:Matrix3D, angle:Number):void {
			var angleRadian:Number = Math3D.toRadian(angle);
			var sin:Number = Math.sin(angleRadian);
			var cos:Number = Math.cos(angleRadian);

			var e:Number = m.e;
			var f:Number = m.f;
			var g:Number = m.g;
			var h:Number = m.h;
			var i:Number = m.i;
			var j:Number = m.j;
			var k:Number = m.k;
			var l:Number = m.l;

			m.e = cos*e - sin*i;
			m.f = cos*f - sin*j;
			m.g = cos*g - sin*k;
			m.h = cos*h - sin*l;

			m.i = sin*e + cos*i;
			m.j = sin*f + cos*j;
			m.k = sin*g + cos*k;
			m.l = sin*h + cos*l;
		}
		
		// Поворот матрицы вдоль Y
		static public function rotateYMatrix(m:Matrix3D, angle:Number):void {
			var angleRadian:Number = Math3D.toRadian(angle);
			var sin:Number = Math.sin(angleRadian);
			var cos:Number = Math.cos(angleRadian);

			var a:Number = m.a;
			var b:Number = m.b;
			var c:Number = m.c;
			var d:Number = m.d;
			var i:Number = m.i;
			var j:Number = m.j;
			var k:Number = m.k;
			var l:Number = m.l;

			m.a = cos*a + sin*i;
			m.b = cos*b + sin*j;
			m.c = cos*c + sin*k;
			m.d = cos*d + sin*l;

			m.i = -sin*a + cos*i;
			m.j = -sin*b + cos*j;
			m.k = -sin*c + cos*k;
			m.l = -sin*d + cos*l;
		}

		// Поворот матрицы вдоль Z
		static public function rotateZMatrix(m:Matrix3D, angle:Number):void {
			var angleRadian:Number = Math3D.toRadian(angle);
			var sin:Number = Math.sin(angleRadian);
			var cos:Number = Math.cos(angleRadian);

			var a:Number = m.a;
			var b:Number = m.b;
			var c:Number = m.c;
			var d:Number = m.d;
			var e:Number = m.e;
			var f:Number = m.f;
			var g:Number = m.g;
			var h:Number = m.h;

			m.a = cos*a - sin*e;
			m.b = cos*b - sin*f;
			m.c = cos*c - sin*g;
			m.d = cos*d - sin*h;

			m.e = sin*a + cos*e;
			m.f = sin*b + cos*f;
			m.g = sin*c + cos*g;
			m.h = sin*d + cos*h;
		}
		
		// Умножение матриц
		static public function combineMatrix(m1:Matrix3D, m2:Matrix3D):Matrix3D {
			var res:Matrix3D = new Matrix3D();

			res.a = m1.a*m2.a + m1.b*m2.e + m1.c*m2.i;
			res.b = m1.a*m2.b + m1.b*m2.f + m1.c*m2.j;
			res.c = m1.a*m2.c + m1.b*m2.g + m1.c*m2.k;
			res.d = m1.a*m2.d + m1.b*m2.h + m1.c*m2.l + m1.d;

			res.e = m1.e*m2.a + m1.f*m2.e + m1.g*m2.i;
			res.f = m1.e*m2.b + m1.f*m2.f + m1.g*m2.j;
			res.g = m1.e*m2.c + m1.f*m2.g + m1.g*m2.k;
			res.h = m1.e*m2.d + m1.f*m2.h + m1.g*m2.l + m1.h;

			res.i = m1.i*m2.a + m1.j*m2.e + m1.k*m2.i;
			res.j = m1.i*m2.b + m1.j*m2.f + m1.k*m2.j;
			res.k = m1.i*m2.c + m1.j*m2.g + m1.k*m2.k;
			res.l = m1.i*m2.d + m1.j*m2.h + m1.k*m2.l + m1.l;

			return res;
		}
		
		// Трансформация вектора через матрицу
		static public function vectorTransform(v:Vector, m:Matrix3D):Vector {
			var res:Vector = new Vector();
			res.x = m.a*v.x + m.b*v.y + m.c*v.z + m.d;
			res.y = m.e*v.x + m.f*v.y + m.g*v.z + m.h;
			res.z = m.i*v.x + m.j*v.y + m.k*v.z + m.l;
			return res;
		}
		
		// Проверка на пересечение луча с заданным треугольником
		static public function tryangleIntersection(a:Vector, b:Vector, c:Vector, n:Vector, v1:Vector, v2:Vector): Vector {
			var res:Vector;
			
			var d:Number = -n.x*a.x - n.y*a.y - n.z*a.z;
			var v:Vector = new Vector(v2.x-v1.x, v2.y-v1.y, v2.z-v1.z);
			var nv:Number = (n.x*v.x + n.y*v.y + n.z*v.z);
			if (nv != 0) {
				//нахождение точки пересечения луча с плоскостью полигона
				var t:Number = -(d + n.x*v1.x + n.y*v1.y + n.z*v1.z)/nv;
				res = new Vector(v1.x + t*v.x,v1.y + t*v.y,v1.z + t*v.z);
				//проверка на попадание точки пересечения в заданный треугольник
				var uu:Number = ((res.x - a.x)*(c.y - a.y)-(c.x - a.x)*(res.y - a.y))/((b.x - a.x)*(c.y - a.y)-(c.x - a.x)*(b.y - a.y));
				var vv:Number = (res.y - a.y - uu*(b.y - a.y))/(c.y - a.y);
				if (!(uu > 0 && vv > 0 && (1-uu-vv) > 0)) {
					//точка не лежит в треугольнике
					res = null;
				}
			} else {
				//луч параллелен плоскости
				res = null;
			}
			return res;
		}
		
		//проверка на прохождение луча (v1, v2) через сферу с центром (c) заданного радиуса (r)
		static public function sphereIntersection(c:Vector, r:Number, v1:Vector, v2:Vector):Vector {
			var res: Vector;
			
			var v: Vector = new Vector(v2.x-v1.x, v2.y-v1.y, v2.z-v1.z);
			var n: Vector = new Vector(-v.x,-v.y,-v.z);
			
			var d: Number = -n.x*c.x - n.y*c.y - n.z*c.z;
			var nv: Number = (n.x*v.x + n.y*v.y + n.z*v.z);
			// нахождение точки пересечения луча с плоскостью перпендикулярной лучу,
			// проходящей через центр сферы
			var t: Number = -(d + n.x*v1.x + n.y*v1.y + n.z*v1.z)/nv;
			res = new Vector(v1.x + t*v.x,v1.y + t*v.y,v1.z + t*v.z);
			//определение длины перпендикуляра
			var l: Number = Math.sqrt((res.x-c.x)*(res.x-c.x) + (res.y-c.y)*(res.y-c.y) + (res.z-c.z)*(res.z-c.z));
			if (l > r) {
				res = null;
			}
						
			return res;
		}
		
		// Нахождение перпендикуляра к отрезку(v1, v2) из произвольной точки(c)
		static public function perpendicularToSegment(c:Vector, v1:Vector, v2:Vector):Vector {
			var res:Vector;
			
			var v:Vector = vectorSub(v2, v1);
			var n:Vector = new Vector(-v.x, -v.y, -v.z);
			
			var d:Number = -vectorDot(n, c);
			var nv:Number = vectorDot(n, v);

			var t:Number = -(d + vectorDot(n, v1))/nv;
			res = vectorAdd(v1, vectorMultiply(v, t));
			
			return res;
		}
		
		// Расстояние от точки до ребра в плоскости камеры
		static public function segmentDistance(first:Point, second:Point, point:Point):Number {
			// Вектор ребра
			var dx:Number = second.x - first.x;
			var dy:Number = second.y - first.y;
			
			// Вектор точки
			var px:Number = point.x - first.x;
			var py:Number = point.y - first.y;
			
			// Векторное произведение (площадь параллелограмма) поделить на длину ребра 
			return (dx*py - dy*px)/Math.sqrt(dx*dx + dy*dy);
		}
		
		// Попадает ли точка в 2D-треугольник 
		static public function tryangleHasPoint(a:Point, b:Point, c:Point, point:Point):Boolean {
			if (vectorCross2D(c.subtract(a), point.subtract(a)) <= 0) {
				if (vectorCross2D(b.subtract(c), point.subtract(c)) <= 0) {
					if (vectorCross2D(a.subtract(b), point.subtract(b)) <= 0) {
						return true;
					} else {
						return false;
					}
				} else {
					return false;
				}
			} else {
				return false;
			}
		}
		
		static public function vectorCross2D(a:Point, b:Point):Number {
			return a.x*b.y - a.y*b.x;
		}
		
	}
}