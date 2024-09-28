package alternativa.engine3d.loaders {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.core.Object3D;
	
	public class Parsed3DSData {
		
		/**
		 * Список объектов в порядке их появления в 3DS-данных.
		 **/		 
		public var objects:Vector.<Object3D>;
		/**
		 * Список материалов каждого объекта. Если для объекта нет назначенных материалов, соответствующий элемент списка равен null.
		 **/
		public var objectMaterials:Vector.<Vector.<String>>;
		/**
		 * Список материалов 3DS-файла (materialName => MaterialParams).
		 */		
		public var materials:Object;
		
	}
}