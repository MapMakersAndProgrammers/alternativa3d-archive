package com.alternativagame.engine3d.object.mesh.primitive {
	import com.alternativagame.engine3d.object.Object3D;
	

	public class Geosphere extends Object3D {

		private var polygonNum:int = 0;
		private var a:Number;
		private var radius:Number;
		private var vertex:Array = new Array();
		private var polygon:Array = new Array();
		private var material:TextureMaterial;
		private var smooth:Boolean;
		private var currentSeg:int = 1;
		private var segments:int;

		public function Geosphere(material:TextureMaterial, radius:Number = 100, segments:int = 1, smooth:Boolean = false, positionX:Number = 0, positionY:Number = 0, positionZ:Number = 0, rotationX:Number = 0, rotationY:Number = 0, rotationZ:Number = 0, scaleX:Number = 1, scaleY:Number = 1, scaleZ:Number = 1) {
			super(solid, positionX, positionY, positionZ, rotationX, rotationY, rotationZ, scaleX, scaleY, scaleZ);
			this.material = material;
			this.smooth = smooth;
			this.radius = radius;
			this.segments = segments;

			var a1: Number = (4*radius)/Math.sqrt(2*(5+Math.sqrt(5))); //сторона треугольников (segments = 1)
			var h: Number = (a1*radius)/(a1 + radius); //высота полюса в первом пятиугольнике
			
			var dh: Number = radius - Math.sqrt(radius*radius - (a1*a1)/4); //поднятие второй точки над первой стороной
			var a2: Number = Math.sqrt((a*a)/4 + dh*dh); //сторона треугольников (segments = 2)
			var h2: Number = (a2*radius)/(a2 + radius) //высота полюса (segments = 2)
			
			var alpha: Number;
			var beta: Number;
			
			//создание 3D-объекта и точек полюсов в нем
			var polus1: Point3D = new Point3D(0,0,radius);
			var polus2: Point3D = new Point3D(0,0,-radius);
			add(polus1);
			add(polus2);
			
			//------------------ построение икосаэдра (segments = 1)
			for (var j:int = 1; j <= 2; j++) {
				vertex[j] = new Array;
				var n:int = 5;
				//прохождение по горизонтальной линии
				for (var i:int = 0; i < n; i++) {
					var mapCoord:UVCoord = new UVCoord(0,0);
					
					//создание вершин полигонов					
					if (j == 1) {
						alpha = 72*i;//отклонение точки в горизонтальной плоскости
						beta = Math.acos((radius-h)/radius);//отклонение точки в проекции на вертикальную ось
					} else {
						alpha = 72*i + 36;
						beta = Math.acos(-(radius-h)/radius);
					}
					alpha = alpha*Math.PI/180;
					//beta = beta*Math.PI/180;
					var sa: Number = Math.sin(alpha);
					var ca: Number = Math.cos(alpha);
					var sb: Number = Math.sin(beta);
					var cb: Number = Math.cos(beta);
					var r: Number = radius*sb;
					vertex[j][i] = new Point3D(r*ca,r*sa,radius*cb);
					add(vertex[j][i]);
					
					if (i > 0) {
					//обтягивание полигонами
						//верхний полюс
						if (j == 1) {
							addPoly(polus1,vertex[j][i-1],vertex[j][i],mapCoord,mapCoord,mapCoord,1);
							if (i == n-1) {
								addPoly(polus1,vertex[j][i],vertex[j][0],mapCoord,mapCoord,mapCoord,1);
							}
						} else {
							if (i < n) {
								addPoly(vertex[j][i-1],vertex[j-1][i],vertex[j-1][i-1],mapCoord,mapCoord,mapCoord,1);
								addPoly(vertex[j][i-1],vertex[j][i],vertex[j-1][i],mapCoord,mapCoord,mapCoord,1);
								if (i == n-1) {
									addPoly(vertex[j-1][0],vertex[j-1][i],vertex[j][i],mapCoord,mapCoord,mapCoord,1);
									addPoly(vertex[j][0],vertex[j-1][0],vertex[j][i],mapCoord,mapCoord,mapCoord,1);
								}
							}
							//нижний полюс
							//if (j == 2) {
								addPoly(polus2,vertex[j][i],vertex[j][i-1],mapCoord,mapCoord,mapCoord,1);
								if (i == n-1) {
									addPoly(polus2,vertex[j][0],vertex[j][i],mapCoord,mapCoord,mapCoord,1);
								}
							//}
						}
					}
				}
			}
		}//end of constructor
		
		//добавление полигона
		private function addPoly(p1:Point3D,p2:Point3D,p3:Point3D,a:UVCoord,b:UVCoord,c:UVCoord,rec:int):void {
			polygon[polygonNum] = new Polygon3D(p1,p2,p3,material,smooth);
			add(polygon[polygonNum]);
			polygonNum++;
			if (rec < segments) {
				addSegments(polygon[polygonNum-1],rec);
			}
			/*addSegments(polygon[polygonNum-1],rec);
			addSegments(polygon[polygonNum-5],rec);
			addSegments(polygon[polygonNum-9],rec);
			addSegments(polygon[polygonNum-13],rec);*/
		}
		
		//дробление полигона
		private function addSegments(p:Polygon3D,rec:int):void {
			//середина стороны ab
			var p1: Point3D = new Point3D((p.a.x + p.b.x)/2,(p.a.y + p.b.y)/2,(p.a.z + p.b.z)/2);
			//середина стороны bc
			var p2: Point3D = new Point3D((p.c.x + p.b.x)/2,(p.c.y + p.b.y)/2,(p.c.z + p.b.z)/2);
			//середина стороны ac
			var p3: Point3D = new Point3D((p.a.x + p.c.x)/2,(p.a.y + p.c.y)/2,(p.a.z + p.c.z)/2);
			
			var uv1:UVCoord = new UVCoord(0,0);
			var uv2:UVCoord = new UVCoord(0,0);
			var uv3:UVCoord = new UVCoord(0,0);
			
			add(p1);
			add(p2);
			add(p3);
			
			var p1x2: Number = p1.x*p1.x;
			var p1y2: Number = p1.y*p1.y;
			var p1z2: Number = p1.z*p1.z;
			
			var p2x2: Number = p2.x*p2.x;
			var p2y2: Number = p2.y*p2.y;
			var p2z2: Number = p2.z*p2.z;
			
			var p3x2: Number = p3.x*p3.x;
			var p3y2: Number = p3.y*p3.y;
			var p3z2: Number = p3.z*p3.z;
			//модуль вектора к точке p1 в квадрате
			var L12: Number = p1x2 + p1y2 + p1z2;
			//модуль вектора к точке p2 в квадрате
			var L22: Number = p2x2 + p2y2 + p2z2;
			//модуль вектора к точке p3 в квадрате
			var L32: Number = p3x2 + p3y2 + p3z2;
			
			//p1
			if (p1.x >= 0) {
				p1.x = Math.sqrt((p1x2 * radius*radius) / L12);				
			} else {
				p1.x = -Math.sqrt((p1x2 * radius*radius) / L12);				
			}
			if (p1.y >= 0) {
				p1.y = Math.sqrt((p1y2 * radius*radius) / L12);
			} else {
				p1.y = -Math.sqrt((p1y2 * radius*radius) / L12);
			}
			if (p1.z >= 0) {
				p1.z = Math.sqrt((p1z2 * radius*radius) / L12);
			} else {
				p1.z = -Math.sqrt((p1z2 * radius*radius) / L12);
			}
			//p2
			if (p2.x >= 0) {
				p2.x = Math.sqrt((p2x2 * radius*radius) / L22);				
			} else {
				p2.x = -Math.sqrt((p2x2 * radius*radius) / L22);				
			}
			if (p2.y >= 0) {
				p2.y = Math.sqrt((p2y2 * radius*radius) / L22);
			} else {
				p2.y = -Math.sqrt((p2y2 * radius*radius) / L22);
			}
			if (p2.z >= 0) {
				p2.z = Math.sqrt((p2z2 * radius*radius) / L22);
			} else {
				p2.z = -Math.sqrt((p2z2 * radius*radius) / L22);
			}
			//p3
			if (p3.x >= 0) {
				p3.x = Math.sqrt((p3x2 * radius*radius) / L32);				
			} else {
				p3.x = -Math.sqrt((p3x2 * radius*radius) / L32);				
			}
			if (p3.y >= 0) {
				p3.y = Math.sqrt((p3y2 * radius*radius) / L32);
			} else {
				p3.y = -Math.sqrt((p3y2 * radius*radius) / L32);
			}
			if (p3.z >= 0) {
				p3.z = Math.sqrt((p3z2 * radius*radius) / L32);
			} else {
				p3.z = -Math.sqrt((p3z2 * radius*radius) / L32);
			}
			
			//добавление полигонов
			addPoly(p1,p2,p3,uv1,uv2,uv3,rec+1);
			addPoly(p.a,p1,p3,uv1,uv2,uv3,rec+1);
			addPoly(p.b,p2,p1,uv1,uv2,uv3,rec+1);
			addPoly(p.c,p3,p2,uv1,uv2,uv3,rec+1);
			
			/*polygon[polygonNum] = new Polygon3D(p1,p2,p3,material,smooth);
			add(polygon[polygonNum]);
			polygonNum++;
			
			polygon[polygonNum] = new Polygon3D(p.a,p1,p3,material,smooth);
			add(polygon[polygonNum]);
			polygonNum++;
			
			polygon[polygonNum] = new Polygon3D(p.b,p2,p1,material,smooth);
			add(polygon[polygonNum]);
			polygonNum++;
			
			polygon[polygonNum] = new Polygon3D(p.c,p3,p2,material,smooth);
			add(polygon[polygonNum]);
			polygonNum++;*/
			
			removePolygon(p);
		}
		
		
	}//end of class
}
