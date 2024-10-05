package com.alternativagame.engine3d.object.mesh.primitive {
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.PolygonMaterial;
	import com.alternativagame.engine3d.object.mesh.Point3D;
	import com.alternativagame.engine3d.object.mesh.PolyMesh3D;
	import com.alternativagame.engine3d.object.mesh.polygon.FillPolygon3D;
	import com.alternativagame.engine3d.object.mesh.polygon.Polygon3D;
	import com.alternativagame.engine3d.object.mesh.polygon.TexturePolygon3D;
	import com.alternativagame.engine3d.object.mesh.polygon.WirePolygon3D;
	
	import flash.geom.Point;

	use namespace engine3d;

	public class GeoPlane extends PolyMesh3D {
		
		use namespace engine3d;

		public function GeoPlane(polygonClass:Class, width:Number, height:Number, material:PolygonMaterial = null, widthSegments:uint = 1, heightSegments:uint = 1) {
			super();
			
			// Массив точек
			var p:Array = new Array();
			// Середина
			var wh:Number = width / 2;
			var hh:Number = height / 2;
			// Размеры сегмента
			var ws:Number = width / widthSegments;
			var hs:Number = height / heightSegments;
			
			var i:uint;
			var j:uint;
			
			// Создание точек
			for (i = 0; i <= heightSegments; i++) {
				p[i] = new Array();
				for (j = 0; j <= widthSegments; j++) {
					if (i % 2 == 0) {
						// Если чётный ряд
						p[i][j] = new Point3D(j*ws - wh, hh - i*hs, 0);
					} else {
						// Если нечётный ряд
						if (j == 0) {
							// Первая точка
							p[i][j] = new Point3D(-wh, hh - i*hs, 0);
						} else {
							p[i][j] = new Point3D(j*ws - wh - ws/2, hh - i*hs, 0);
							if (j == widthSegments) {
								// Последняя точка
								p[i][j+1] = new Point3D(wh, hh - i*hs, 0)
								addPoint(p[i][j+1]);
							}
						}
					}
					addPoint(p[i][j]);
				}
			}

			var poly:Polygon3D;
			for (i = 0; i < heightSegments; i++) {
				for (var n:uint = 0; n < widthSegments*2+1; n++) {
					
					j = Math.floor(n/2);
					if (i % 2 == 0) {
						// Если чётный ряд
						if (n % 2 == 0) {
							// Если остриём вверх
							poly = new polygonClass(p[i][j], p[i+1][j], p[i+1][j+1], material);
							if (poly is WirePolygon3D && (i < heightSegments - 1)) {
								WirePolygon3D(poly).edgeBC = false;
							}
						} else {
							// Если остриём вниз 
							poly = new polygonClass(p[i][j], p[i+1][j+1], p[i][j+1], material);
							if (poly is WirePolygon3D) {
								WirePolygon3D(poly).edgeAB = false;
								WirePolygon3D(poly).edgeBC = false;
							}
						}
					} else {
						// Если нечётный ряд
						if (n % 2 == 0) {
							// Если остриём вниз 
							poly = new polygonClass(p[i][j], p[i+1][j], p[i][j+1], material);
						} else {
							// Если остриём вверх
							poly = new polygonClass(p[i][j+1], p[i+1][j], p[i+1][j+1], material);
							if (poly is WirePolygon3D) {
								WirePolygon3D(poly).edgeAB = false;
								WirePolygon3D(poly).edgeBC = (i == heightSegments - 1);
								WirePolygon3D(poly).edgeCA = false;
							}

						}
					}
					
					// Указываем UV-координаты, если TexturePolygon3D
					if (poly is TexturePolygon3D) {
						TexturePolygon3D(poly).aUV = new Point((poly.a.x + wh)/width, (poly.a.y - hh)/height);
						TexturePolygon3D(poly).bUV = new Point((poly.b.x + wh)/width, (poly.b.y - hh)/height);
						TexturePolygon3D(poly).cUV = new Point((poly.c.x + wh)/width, (poly.c.y - hh)/height);
					}
					
					addPolygon(poly);
				}
			}
			
			// Создание полигруппы
			if (poly is FillPolygon3D) {
				setPolygroup("plane", polygons);
			}
			
			
		}		
		
	}
}