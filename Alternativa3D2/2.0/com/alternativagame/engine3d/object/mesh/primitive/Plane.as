package com.alternativagame.engine3d.object.mesh.primitive {
	import com.alternativagame.engine3d.engine3d;
	import com.alternativagame.engine3d.material.PolygonMaterial;
	import com.alternativagame.engine3d.object.mesh.Point3D;
	import com.alternativagame.engine3d.object.mesh.PolyMesh3D;
	import com.alternativagame.engine3d.object.mesh.Polygroup3D;
	import com.alternativagame.engine3d.object.mesh.polygon.FillPolygon3D;
	import com.alternativagame.engine3d.object.mesh.polygon.Polygon3D;
	import com.alternativagame.engine3d.object.mesh.polygon.TexturePolygon3D;
	import com.alternativagame.engine3d.object.mesh.polygon.WirePolygon3D;
	
	import flash.geom.Point;
	
	use namespace engine3d;

	public class Plane extends PolyMesh3D {
		
		use namespace engine3d;
		
		public function Plane(polygonClass:Class, width:Number, height:Number, material:PolygonMaterial = null, widthSegments:uint = 1, heightSegments:uint = 1) {
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
					p[i][j] = new Point3D(j*ws - wh, hh - i*hs, 0);
					addPoint(p[i][j]);
				}
			}
			
			// Создание полигонов
			var wd:Number = 1/widthSegments;
			var hd:Number = 1/heightSegments;
			
			for (i = 0; i < heightSegments; i++) {
				for (j = 0; j < widthSegments; j++) {
					var poly1:Polygon3D = new polygonClass(p[i][j], p[i+1][j], p[i][j+1], material);
					var poly2:Polygon3D = new polygonClass(p[i+1][j], p[i+1][j+1], p[i][j+1], material);
					
					// Устанавливаем флаги видимости диагоналей, если Wire3D
					if (poly1 is WirePolygon3D) {
						WirePolygon3D(poly1).edgeBC = false;
						WirePolygon3D(poly2).edgeAB = (i == heightSegments - 1);
						WirePolygon3D(poly2).edgeBC = (j == widthSegments - 1);
						WirePolygon3D(poly2).edgeCA = false;
					}
					
					// Указываем UV-координаты, если TexturePolygon3D
					if (poly1 is TexturePolygon3D) {
						TexturePolygon3D(poly1).aUV = new Point((poly1.a.x + wh)/width, (poly1.a.y - hh)/height);
						TexturePolygon3D(poly1).bUV = new Point((poly1.b.x + wh)/width, (poly1.b.y - hh)/height);
						TexturePolygon3D(poly1).cUV = new Point((poly1.c.x + wh)/width, (poly1.c.y - hh)/height);
						TexturePolygon3D(poly2).aUV = new Point((poly2.a.x + wh)/width, (poly2.a.y - hh)/height);
						TexturePolygon3D(poly2).bUV = new Point((poly2.b.x + wh)/width, (poly2.b.y - hh)/height);
						TexturePolygon3D(poly2).cUV = new Point((poly2.c.x + wh)/width, (poly2.c.y - hh)/height);
					}
					
					addPolygon(poly1);
					addPolygon(poly2);
				}
			}
			
			// Создание полигруппы
			if (poly1 is FillPolygon3D) {
				setPolygroup("plane", polygons);
			}
			
		}
	}
}