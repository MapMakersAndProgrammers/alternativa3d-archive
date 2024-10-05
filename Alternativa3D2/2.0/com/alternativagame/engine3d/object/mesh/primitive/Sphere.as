package com.alternativagame.engine3d.object.mesh.primitive {
	import com.alternativagame.engine3d.object.Object3D;
	
	
	public class Sphere extends Object3D {

		private var vertex:Array = new Array();
		private var polygon:Array = new Array();
		private var material:TextureMaterial;
		private var smooth:Boolean = false;
		
		private var polygonNum:int = 0;
		
		//конструктор		
		public function Sphere(material:TextureMaterial, poligonMap:Boolean=false, radius:Number = 100, latitudes:int = 8, longtitudes:int = 12, smooth:Boolean = false, positionX:Number = 0, positionY:Number = 0, positionZ:Number = 0, rotationX:Number = 0, rotationY:Number = 0, rotationZ:Number = 0, scaleX:Number = 1, scaleY:Number = 1, scaleZ:Number = 1) {
			super(solid, positionX, positionY, positionZ, rotationX, rotationY, rotationZ, scaleX, scaleY, scaleZ);
			this.smooth = smooth;
			this.material = material;
			
			var sector1: Number = 360/longtitudes; //сектор в горизонтальной плоскости
			var sector2: Number = 180/(latitudes + 1);//сектор по вертикали
			
			//создание 3D-объекта и точек полюсов в нем
			var polus1: Point3D = new Point3D(0,0,radius);
			var polus2: Point3D = new Point3D(0,0,-radius);
			add(polus1);
			add(polus2);
			
			var wd:Number = 1/longtitudes;
			var hd:Number = 1/(latitudes+1);
			
			for (var j:int = 1; j <= latitudes; j++) {
				vertex[j] = new Array;
				var beta: Number = j*sector2;//отклонение точки в проекции на вертикальную ось
				beta = beta*Math.PI/180;
				
				//прохождение по горизонтальной линии
				for (var i:int = 0; i < longtitudes; i++) {
										
					//создание вершин полигонов					
					var alpha: Number = i*sector1;//отклонение точки в горизонтальной плоскости
					alpha = alpha*Math.PI/180;
					
					var sa: Number = Math.sin(alpha);
					var ca: Number = Math.cos(alpha);
					var sb: Number = Math.sin(beta);
					var cb: Number = Math.cos(beta);
					var r: Number = radius*sb;
					vertex[j][i] = new Point3D(r*ca,r*sa,radius*cb);
					add(vertex[j][i]);
					
					 
					if (i > 0) {
						if (!poligonMap) {	
						//обтягивание полигонами (текстура натягивается на всю сферу)
							//верхний полюс
							if (j == 1) {
								addPoly(polus1,vertex[j][i-1],vertex[j][i],new UVCoord((i - 0.5)*wd,1),new UVCoord((i-1)*wd,1-j*hd),new UVCoord(i*wd,1-j*hd));
								if (i == longtitudes-1) {
									addPoly(polus1,vertex[j][i],vertex[j][0],new UVCoord((i - 0.5)*wd,1),new UVCoord(i*wd,1-j*hd),new UVCoord(1,1-j*hd));
								}
							} else {
								addPoly(vertex[j-1][i],vertex[j-1][i-1],vertex[j][i-1],new UVCoord(i*wd,1-(j-1)*hd),new UVCoord((i-1)*wd,1-(j-1)*hd),new UVCoord((i-1)*wd,1-j*hd));
								addPoly(vertex[j-1][i],vertex[j][i-1],vertex[j][i],new UVCoord(i*wd,1-(j-1)*hd),new UVCoord((i-1)*wd,1-j*hd),new UVCoord(i*wd,1-j*hd));
								if (i == longtitudes-1) {
									addPoly(vertex[j-1][0],vertex[j-1][i],vertex[j][i],new UVCoord(1,1-(j-1)*hd),new UVCoord(i*wd,1-(j-1)*hd),new UVCoord(i*wd,1-j*hd));
									addPoly(vertex[j-1][0],vertex[j][i],vertex[j][0],new UVCoord(1,1-(j-1)*hd),new UVCoord(i*wd,1-j*hd),new UVCoord(1,1-j*hd));
								}
								//нижний полюс
								if (j == latitudes) {
									addPoly(polus2,vertex[j][i],vertex[j][i-1],new UVCoord((i - 0.5)*wd,0),new UVCoord(i*wd,1-j*hd),new UVCoord((i-1)*wd,1-j*hd));
									if (i == longtitudes-1) {
										addPoly(polus2,vertex[j][0],vertex[j][i],new UVCoord((i - 0.5)*wd,0),new UVCoord(1,1-j*hd),new UVCoord(i*wd,1-j*hd));
									}
								}
							}
						} else {
						//обтягивание полигонами (текстура натягивается на каждую грань)
							//верхний полюс
							if (j == 1) {
								addPoly(polus1,vertex[j][i-1],vertex[j][i],new UVCoord(0.5,1),new UVCoord(1,0),new UVCoord(0,0));
								if (i == longtitudes-1) {
									addPoly(polus1,vertex[j][i],vertex[j][0],new UVCoord(0.5,1),new UVCoord(1,0),new UVCoord(0,0));
								}
							} else {
								addPoly(vertex[j-1][i],vertex[j-1][i-1],vertex[j][i-1],new UVCoord(1,0),new UVCoord(0,0),new UVCoord(0,1));
								addPoly(vertex[j-1][i],vertex[j][i-1],vertex[j][i],new UVCoord(1,0),new UVCoord(0,1),new UVCoord(1,1));
								if (i == longtitudes-1) {
									addPoly(vertex[j-1][0],vertex[j-1][i],vertex[j][i],new UVCoord(1,0),new UVCoord(0,0),new UVCoord(0,1));
									addPoly(vertex[j-1][0],vertex[j][i],vertex[j][0],new UVCoord(1,0),new UVCoord(0,1),new UVCoord(1,1));
								}
								//нижний полюс
								if (j == latitudes) {
									addPoly(polus2,vertex[j][i],vertex[j][i-1],new UVCoord(0.5,0),new UVCoord(0,1),new UVCoord(1,1));
									if (i == longtitudes-1) {
										addPoly(polus2,vertex[j][0],vertex[j][i],new UVCoord(0.5,0),new UVCoord(0,1),new UVCoord(1,1));
									}
								}
							}
						}
					}
				}
			}
		}//end of constructor
		
		//добавление полигона
		private function addPoly(p1:Point3D,p2:Point3D,p3:Point3D,a:UVCoord,b:UVCoord,c:UVCoord):void {
			polygon[polygonNum] = new Polygon3D(p1,p2,p3,material,smooth,a,b,c);
			add(polygon[polygonNum]);
			polygonNum++;
		}
		
	}
}