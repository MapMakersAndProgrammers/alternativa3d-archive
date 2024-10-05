package com.alternativagame.engine3d.object.mesh.primitive {
	import com.alternativagame.engine3d.object.Object3D;
	
	
	public class Box3D extends Object3D {
		
		public function Box3D(material:TextureMaterial, width:Number = 100, height:Number = 100, length:Number = 100, segments:uint = 1, solid:Boolean = false, smooth:Boolean = false, positionX:Number = 0, positionY:Number = 0, positionZ:Number = 0, rotationX:Number = 0, rotationY:Number = 0, rotationZ:Number = 0, scaleX:Number = 1, scaleY:Number = 1, scaleZ:Number = 1) {
			super(solid, positionX, positionY, positionZ, rotationX, rotationY, rotationZ, scaleX, scaleY, scaleZ);
			
			var p:Array = new Array();
			var wh:Number = width / 2;
			var hh:Number = height / 2;
			var lh:Number = length / 2;
			var ws:Number = width / segments;
			var hs:Number = height / segments;
			var ls:Number = length / segments;
			var i:uint;
			var j:uint;
			var k:uint;
			
			//создание точек
			for (i = 0; i <= segments; i++) {
				p[i] = new Array();
				for (j = 0; j <= segments; j++) {
					p[i][j] = new Array();
					for (k = 0; k <= segments; k++) {
						if (k == 0 || k == segments) {
							p[i][j][k] = new Point3D(i*ls - lh, j*ws - wh, k*hs - hh);
							add(p[i][j][k]);
						}
						if (k >0 && k<segments) {
							if (i==0 || i==segments || j==0 || j==segments) {
								p[i][j][k] = new Point3D(i*ls - lh, j*ws - wh, k*hs - hh);
								add(p[i][j][k]);
							}
						}
					}
				}
			}
			
			var wd:Number = 1/segments;
			var hd:Number = 1/segments;
			var ld:Number = 1/segments;
			
			//построение нижней грани
			for (i = 0; i < segments; i++) {
				for (j = 0; j < segments; j++) {
					add(new Polygon3D(p[i+1][j][0], p[i][j][0], p[i][j+1][0], material, smooth, new UVCoord((i+1)*wd, j*hd), new UVCoord(i*wd, j*hd), new UVCoord(i*wd, (j+1)*hd)));
					add(new Polygon3D(p[i+1][j+1][0], p[i+1][j][0], p[i][j+1][0], material, smooth, new UVCoord((i+1)*wd, (j+1)*hd), new UVCoord((i+1)*wd, j*hd), new UVCoord(i*wd, (j+1)*hd)));
				}
			}
			//построение верхней грани
			for (i = 0; i < segments; i++) {
				for (j = 0; j < segments; j++) {
					add(new Polygon3D(p[i][j][segments], p[i+1][j][segments], p[i][j+1][segments], material, smooth, new UVCoord(i*wd, j*hd), new UVCoord((i+1)*wd, j*hd), new UVCoord(i*wd, (j+1)*hd)));
					add(new Polygon3D(p[i+1][j][segments], p[i+1][j+1][segments], p[i][j+1][segments], material, smooth, new UVCoord((i+1)*wd, j*hd), new UVCoord((i+1)*wd, (j+1)*hd), new UVCoord(i*wd, (j+1)*hd)));
				}
			}
			//построение фронтальной грани
			for (i = 0; i < segments; i++) {
				for (k = 0; k < segments; k++) {
					add(new Polygon3D(p[i][0][k], p[i+1][0][k], p[i][0][k+1], material, smooth, new UVCoord(i*wd, k*hd), new UVCoord((i+1)*wd, k*hd), new UVCoord(i*wd, (k+1)*hd)));
					add(new Polygon3D(p[i+1][0][k], p[i+1][0][k+1], p[i][0][k+1], material, smooth, new UVCoord((i+1)*wd, k*hd), new UVCoord((i+1)*wd, (k+1)*hd), new UVCoord(i*wd, (k+1)*hd)));
				}
			}
			//построение задней грани
			for (i = 0; i < segments; i++) {
				for (k = 0; k < segments; k++) {
					add(new Polygon3D(p[i+1][segments][k], p[i][segments][k], p[i][segments][k+1], material, smooth, new UVCoord((segments-(i+1))*wd, k*hd), new UVCoord((segments-i)*wd, k*hd), new UVCoord((segments-i)*wd, (k+1)*hd)));
					add(new Polygon3D(p[i+1][segments][k+1], p[i+1][segments][k], p[i][segments][k+1], material, smooth, new UVCoord((segments-(i+1))*wd, (k+1)*hd), new UVCoord((segments-(i+1))*wd, k*hd), new UVCoord((segments-i)*wd, (k+1)*hd)));
				}
			}
			//построение левой грани
			for (i = 0; i < segments; i++) {
				for (j = 0; j < segments; j++) {
					add(new Polygon3D(p[0][i+1][j], p[0][i][j], p[0][i][j+1], material, smooth, new UVCoord((segments-(i+1))*wd, j*hd), new UVCoord((segments-i)*wd, j*hd), new UVCoord((segments-i)*wd, (j+1)*hd)));
					add(new Polygon3D(p[0][i+1][j+1], p[0][i+1][j], p[0][i][j+1], material, smooth, new UVCoord((segments-(i+1))*wd, (j+1)*hd), new UVCoord((segments-(i+1))*wd, j*hd), new UVCoord((segments-i)*wd, (j+1)*hd)));
				}
			}
			//построение правой грани
			for (i = 0; i < segments; i++) {
				for (j = 0; j < segments; j++) {
					add(new Polygon3D(p[segments][i][j], p[segments][i+1][j], p[segments][i][j+1], material, smooth, new UVCoord(i*wd, j*hd), new UVCoord((i+1)*wd, j*hd), new UVCoord(i*wd, (j+1)*hd)));
					add(new Polygon3D(p[segments][i+1][j], p[segments][i+1][j+1], p[segments][i][j+1], material, smooth, new UVCoord((i+1)*wd, j*hd), new UVCoord((i+1)*wd, (j+1)*hd), new UVCoord(i*wd, (j+1)*hd)));
				}
			}
					
		}
		
	}
}