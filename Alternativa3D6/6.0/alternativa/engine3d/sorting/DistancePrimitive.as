package alternativa.engine3d.sorting {

	import alternativa.engine3d.*;
	import alternativa.types.Point3D;
	
	use namespace alternativa3d;

	public class DistancePrimitive extends Primitive {
		
		// Нода
		alternativa3d var node:DistanceNode;
		
		// Координаты в пространстве
		alternativa3d var coords:Point3D = new Point3D();
		
	}
}