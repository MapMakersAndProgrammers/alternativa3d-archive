package com.alternativagame.engine3d.object.mesh.primitive {
	import com.alternativagame.engine3d.object.Object3D;
	
	
	public class Triangle extends Object3D {
		
		public function Triangle(material:TextureMaterial, x1:Number, y1:Number, z1:Number, x2:Number, y2:Number, z2:Number, x3:Number, y3:Number, z3:Number, a:UVCoord, b:UVCoord, c:UVCoord, smooth:Boolean = false, positionX:Number = 0, positionY:Number = 0, positionZ:Number = 0, rotationX:Number = 0, rotationY:Number = 0, rotationZ:Number = 0, scaleX:Number = 1, scaleY:Number = 1, scaleZ:Number = 1) {
			super(solid, positionX, positionY, positionZ, rotationX, rotationY, rotationZ, scaleX, scaleY, scaleZ);
			
			var p1:Point3D = new Point3D(x1, y1, z1);
			var p2:Point3D = new Point3D(x2, y2, z2);
			var p3:Point3D = new Point3D(x3, y3, z3);
			add(p1);
			add(p2);
			add(p3);
			
			add(new Polygon3D(p1, p2, p3, material, smooth, a, b, c));
		}
		
	}
}