package alternativa.engine3d.objects {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	
	import flash.geom.Matrix3D;
	import flash.display.BitmapData;
	import alternativa.engine3d.core.MipMap;
	
	use namespace alternativa3d;	

	public class MeshReference extends Object3D {

		public var referenceMesh:Mesh;
		
		public var sorting:int;
		
		public var texture:BitmapData;
		
		public var mipMapping:int;
		
		public var mipMap:MipMap;
		
		public function MeshReference(referenceMesh:Mesh = null, sorting:int = 0, texture:BitmapData = null, mipMapping:int = 0, mipMap:MipMap = null) {
			this.referenceMesh = referenceMesh;
			this.sorting = sorting;
			this.texture = texture;
			this.mipMapping = mipMapping;
			this.mipMap = mipMap;
		}
		
		override alternativa3d function get canDraw():Boolean {
			return (texture != null || mipMap != null) && referenceMesh.numFaces > 0;
		}

		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Сохранение параметров
			var meshSorting:int = referenceMesh.sorting;
			var meshTexture:BitmapData = referenceMesh.texture;
			var meshMipMapping:int = referenceMesh.mipMapping;
			var meshMipMap:MipMap = referenceMesh.mipMap;
			// Назначение своих
			referenceMesh.sorting = sorting;
			referenceMesh.texture = texture;
			referenceMesh.mipMapping = mipMapping;
			referenceMesh.mipMap = mipMap;
			// Отрисовка
			referenceMesh.draw(camera, object, parentCanvas);
			// Возврат параметров
			referenceMesh.sorting = meshSorting;
			referenceMesh.texture = meshTexture;
			referenceMesh.mipMapping = meshMipMapping;
			referenceMesh.mipMap = meshMipMap;
		}
		
		override alternativa3d function debug(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Сохранение параметров
			var meshSorting:int = referenceMesh.sorting;
			var meshTexture:BitmapData = referenceMesh.texture;
			var meshMipMapping:int = referenceMesh.mipMapping;
			var meshMipMap:MipMap = referenceMesh.mipMap;
			// Назначение своих
			referenceMesh.sorting = sorting;
			referenceMesh.texture = texture;
			referenceMesh.mipMapping = mipMapping;
			referenceMesh.mipMap = mipMap;
			// Отрисовка
			referenceMesh.debug(camera, object, parentCanvas);
			// Возврат параметров
			referenceMesh.sorting = meshSorting;
			referenceMesh.texture = meshTexture;
			referenceMesh.mipMapping = meshMipMapping;
			referenceMesh.mipMap = meshMipMap;
		}
		
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			// Сохранение параметров
			var meshSorting:int = referenceMesh.sorting;
			var meshTexture:BitmapData = referenceMesh.texture;
			var meshMipMapping:int = referenceMesh.mipMapping;
			var meshMipMap:MipMap = referenceMesh.mipMap;
			// Назначение своих
			referenceMesh.sorting = sorting;
			referenceMesh.texture = texture;
			referenceMesh.mipMapping = mipMapping;
			referenceMesh.mipMap = mipMap;
			// Получение геометрии
			var geometry:Geometry = referenceMesh.getGeometry(camera, object);
			// Возврат параметров
			referenceMesh.sorting = meshSorting;
			referenceMesh.texture = meshTexture;
			referenceMesh.mipMapping = meshMipMapping;
			referenceMesh.mipMap = meshMipMap;
			return geometry;
		}
		
		override public function get boundBox():BoundBox {
			return referenceMesh.boundBox;
		}
		
		override public function calculateBoundBox(matrix:Matrix3D = null, boundBox:BoundBox = null):BoundBox {
			return referenceMesh.calculateBoundBox(matrix, boundBox);
		}
		
	}
}
