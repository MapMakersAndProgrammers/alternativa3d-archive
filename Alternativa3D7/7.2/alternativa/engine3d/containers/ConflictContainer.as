package alternativa.engine3d.containers {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Fragment;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	
	import flash.geom.Matrix3D;
	import flash.geom.Utils3D;
	
	use namespace alternativa3d;

	public class ConflictContainer extends Object3DContainer {
		
		public var resolveByAABB:Boolean = false;
		public var resolveByOOBB:Boolean = false;
		
		//public var isolateAABBConflicts:Boolean = false;
		//public var isolateOOBBConflicts:Boolean = false;
		
		public var threshold:Number = 0.1;
		
		// Вспомогательные
		static private const sortingFragments:Vector.<Fragment> = new Vector.<Fragment>();
		static private const sortingStack:Vector.<int> = new Vector.<int>();
		static private var negativeReserve:Fragment = Fragment.create();
		static private var positiveReserve:Fragment = Fragment.create();
		
		// Камера в контейнере
		static private const coords:Vector.<Number> = new Vector.<Number>(3, true);
		protected var inverseCameraMatrix:Matrix3D = new Matrix3D();
		protected var cameraX:Number;
		protected var cameraY:Number;
		protected var cameraZ:Number;		
		
		// Плоскости отсечения камеры в контейнере
		static private const cameraPlanes:Vector.<Number> = new Vector.<Number>(21, true);
		private var nearPlaneX:Number;
		private var nearPlaneY:Number;
		private var nearPlaneZ:Number;
		private var nearPlaneOffset:Number;
		private var farPlaneX:Number;
		private var farPlaneY:Number;
		private var farPlaneZ:Number;
		private var farPlaneOffset:Number;
		private var leftPlaneX:Number;
		private var leftPlaneY:Number;
		private var leftPlaneZ:Number;
		private var leftPlaneOffset:Number;
		private var rightPlaneX:Number;
		private var rightPlaneY:Number;
		private var rightPlaneZ:Number;
		private var rightPlaneOffset:Number;
		private var topPlaneX:Number;
		private var topPlaneY:Number;
		private var topPlaneZ:Number;
		private var topPlaneOffset:Number;
		private var bottomPlaneX:Number;
		private var bottomPlaneY:Number;
		private var bottomPlaneZ:Number;
		private var bottomPlaneOffset:Number;

		// Перекрытия
		static private const edgeOccluder:Vector.<Number> = new Vector.<Number>();
		private var occluders:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
		protected var numOccluders:int;

		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Сбор видимой геометрии
			var geometry:Geometry = getGeometry(camera, object);
			// Если есть видимая геометрия
			if (geometry != null) {
				// Подготовка канваса
				var canvas:Canvas = parentCanvas.getChildCanvas(false, true, object.alpha, object.blendMode, object.colorTransform, object.filters);
				canvas.numDraws = 0;
				// Если объектов несколько
				if (geometry.next != null) {
					var current:Geometry;
					// Расчёт инверсной матрицы камеры и позицци камеры в контейнере
					calculateInverseCameraMatrix(object.cameraMatrix);
					// AABB
					if (resolveByAABB) {
						current = geometry;
						while (current != null) {
							current.vertices.length = current.verticesLength;
							inverseCameraMatrix.transformVectors(current.vertices, current.vertices);
							current.calculateAABB();
							current = current.next;
						}
						drawAABBGeometry(camera, object, canvas, geometry);
					// OOBB
					} else if (resolveByOOBB) {
						current = geometry;
						while (current != null) {
							if (!current.viewAligned) {
								current.calculateOOBB();
							}
							current = current.next;
						}
						drawOOBBGeometry(camera, object, canvas, geometry);
					// Конфликт
					} else {
						drawConflictGeometry(camera, object, canvas, geometry);
					}
				} else {
					if (camera.debugMode) geometry.debug(camera, object, canvas, threshold, 0);
					geometry.draw(camera, canvas, threshold);
					geometry.destroy();
				}
				// Если была отрисовка
				if (canvas.numDraws > 0) {
					canvas.removeChildren(canvas.numDraws);
				} else {
					parentCanvas.numDraws--;
				}
			}
		}

		protected function calculateInverseCameraMatrix(matrix:Matrix3D):void {
			coords[0] = 0;
			coords[1] = 0;
			coords[2] = 0;
			inverseCameraMatrix.identity();
			inverseCameraMatrix.prepend(matrix);
			inverseCameraMatrix.invert();
			inverseCameraMatrix.transformVectors(coords, coords);
			cameraX = coords[0];
			cameraY = coords[1];
			cameraZ = coords[2];
		}
		
		protected function calculateCameraPlanes(camera:Camera3D):void {
			// Перевод плоскостей камеры в пространство контейнера
			cameraPlanes[0] = cameraPlanes[1] = cameraPlanes[2] = cameraPlanes[3] = cameraPlanes[4] = cameraPlanes[6] = cameraPlanes[7] = 0;
			cameraPlanes[5] = camera.nearClipping;
			cameraPlanes[8] = camera.farClipping;
			cameraPlanes[9] = cameraPlanes[10] = cameraPlanes[13] = cameraPlanes[18] = -1;
			cameraPlanes[11] = cameraPlanes[12] = cameraPlanes[14] = cameraPlanes[15] = cameraPlanes[16] = cameraPlanes[17] = cameraPlanes[19] = cameraPlanes[20] = 1;
			inverseCameraMatrix.transformVectors(cameraPlanes, cameraPlanes);
			// Ближняя плоскость
			var bax:Number = cameraPlanes[9] - cameraPlanes[12];
			var bay:Number = cameraPlanes[10] - cameraPlanes[13];
			var baz:Number = cameraPlanes[11] - cameraPlanes[14];
			var bcx:Number = cameraPlanes[15] - cameraPlanes[12];
			var bcy:Number = cameraPlanes[16] - cameraPlanes[13];
			var bcz:Number = cameraPlanes[17] - cameraPlanes[14];
			nearPlaneX = bcy*baz - bcz*bay;
			nearPlaneY = bcz*bax - bcx*baz;
			nearPlaneZ = bcx*bay - bcy*bax;
			nearPlaneOffset = cameraPlanes[3]*nearPlaneX + cameraPlanes[4]*nearPlaneY + cameraPlanes[5]*nearPlaneZ;
			// Дальняя плоскость
			farPlaneX = -nearPlaneX;
			farPlaneY = -nearPlaneY;
			farPlaneZ = -nearPlaneZ;
			farPlaneOffset = cameraPlanes[6]*farPlaneX + cameraPlanes[7]*farPlaneY + cameraPlanes[8]*farPlaneZ;
			// Рёбра пирамиды
			var ax:Number = cameraPlanes[9] - cameraX;
			var ay:Number = cameraPlanes[10] - cameraY;
			var az:Number = cameraPlanes[11] - cameraZ;
			var bx:Number = cameraPlanes[12] - cameraX;
			var by:Number = cameraPlanes[13] - cameraY;
			var bz:Number = cameraPlanes[14] - cameraZ;
			var cx:Number = cameraPlanes[15] - cameraX;
			var cy:Number = cameraPlanes[16] - cameraY;
			var cz:Number = cameraPlanes[17] - cameraZ;
			var dx:Number = cameraPlanes[18] - cameraX;
			var dy:Number = cameraPlanes[19] - cameraY;
			var dz:Number = cameraPlanes[20] - cameraZ;
			// Левая плоскость
			leftPlaneX = dy*az - dz*ay;
			leftPlaneY = dz*ax - dx*az;
			leftPlaneZ = dx*ay - dy*ax;
			leftPlaneOffset = cameraX*leftPlaneX + cameraY*leftPlaneY + cameraZ*leftPlaneZ;
			// Правая плоскость
			rightPlaneX = by*cz - bz*cy;
			rightPlaneY = bz*cx - bx*cz;
			rightPlaneZ = bx*cy - by*cx;
			rightPlaneOffset = cameraX*rightPlaneX + cameraY*rightPlaneY + cameraZ*rightPlaneZ;
			// Верхняя плоскость
			topPlaneX = ay*bz - az*by;
			topPlaneY = az*bx - ax*bz;
			topPlaneZ = ax*by - ay*bx;
			topPlaneOffset = cameraX*topPlaneX + cameraY*topPlaneY + cameraZ*topPlaneZ;
			// Нижняя плоскость
			bottomPlaneX = cy*dz - cz*dy;
			bottomPlaneY = cz*dx - cx*dz;
			bottomPlaneZ = cx*dy - cy*dx;
			bottomPlaneOffset = cameraX*bottomPlaneX + cameraY*bottomPlaneY + cameraZ*bottomPlaneZ;
		}
		
		protected function updateOccluders(camera:Camera3D):void {
			for (var o:int = numOccluders, occluder:Vector.<Number>; o < camera.numOccluders; o++) {
				var cameraEdgeOccluder:Vector.<Number> = camera.occlusionEdges[o], edgeOccluderLength:int = cameraEdgeOccluder.length;
				edgeOccluder.length = edgeOccluderLength;
				// Перевод точек рёбер окклюдеров в пространство контейнера
				inverseCameraMatrix.transformVectors(cameraEdgeOccluder, edgeOccluder);
				// Создание окклюдера в контейнере
				if (occluders.length > numOccluders) occluder = occluders[numOccluders++] else occluder = occluders[numOccluders++] = new Vector.<Number>();
				// Построение плоскостей отсечения
				for (var i:int = 0, ni:int = 0, nx:Number, ny:Number, nz:Number; i < edgeOccluderLength;) {
					var ax:Number = edgeOccluder[i++] - cameraX, ay:Number = edgeOccluder[i++] - cameraY, az:Number = edgeOccluder[i++] - cameraZ, bx:Number = edgeOccluder[i++] - cameraX, by:Number = edgeOccluder[i++] - cameraY, bz:Number = edgeOccluder[i++] - cameraZ;
					occluder[ni++] = nx = bz*ay - by*az, occluder[ni++] = ny = bx*az - bz*ax, occluder[ni++] = nz = by*ax - bx*ay, occluder[ni++] = cameraX*nx + cameraY*ny + cameraZ*nz;
				}
				occluder.length = ni;
			}	
		}

		protected function cullingInContainer(camera:Camera3D, boundBox:BoundBox, culling:int):int {
			if (camera.occludedAll) return -1;
			if (culling > 0) {
				// Отсечение по ниар
				if (culling & 1) {
					if (nearPlaneX >= 0) if (nearPlaneY >= 0) if (nearPlaneZ >= 0) {
						if (boundBox.maxX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.maxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.minX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.minZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundBox.maxX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.minZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.minX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.maxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else if (nearPlaneZ >= 0) {
						if (boundBox.maxX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.maxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.minX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.minZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundBox.maxX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.minZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.minX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.maxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else if (nearPlaneY >= 0) if (nearPlaneZ >= 0) {
						if (boundBox.minX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.maxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.maxX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.minZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundBox.minX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.minZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.maxX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.maxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else if (nearPlaneZ >= 0) {
						if (boundBox.minX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.maxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.maxX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.minZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundBox.minX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.minZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.maxX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.maxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					}
				}
				// Отсечение по фар
				if (culling & 2) {
					if (farPlaneX >= 0) if (farPlaneY >= 0) if (farPlaneZ >= 0) {
						if (boundBox.maxX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.maxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.minX*farPlaneX + boundBox.minY*farPlaneY + boundBox.minZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundBox.maxX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.minZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.minX*farPlaneX + boundBox.minY*farPlaneY + boundBox.maxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else if (farPlaneZ >= 0) {
						if (boundBox.maxX*farPlaneX + boundBox.minY*farPlaneY + boundBox.maxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.minX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.minZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundBox.maxX*farPlaneX + boundBox.minY*farPlaneY + boundBox.minZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.minX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.maxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else if (farPlaneY >= 0) if (farPlaneZ >= 0) {
						if (boundBox.minX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.maxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.maxX*farPlaneX + boundBox.minY*farPlaneY + boundBox.minZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundBox.minX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.minZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.maxX*farPlaneX + boundBox.minY*farPlaneY + boundBox.maxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else if (farPlaneZ >= 0) {
						if (boundBox.minX*farPlaneX + boundBox.minY*farPlaneY + boundBox.maxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.maxX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.minZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundBox.minX*farPlaneX + boundBox.minY*farPlaneY + boundBox.minZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.maxX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.maxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					}
				}
				// Отсечение по левой стороне
				if (culling & 4) {
					if (leftPlaneX >= 0) if (leftPlaneY >= 0) if (leftPlaneZ >= 0) {
						if (boundBox.maxX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.maxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.minX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.minZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundBox.maxX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.minZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.minX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.maxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else if (leftPlaneZ >= 0) {
						if (boundBox.maxX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.maxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.minX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.minZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundBox.maxX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.minZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.minX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.maxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else if (leftPlaneY >= 0) if (leftPlaneZ >= 0) {
						if (boundBox.minX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.maxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.maxX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.minZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundBox.minX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.minZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.maxX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.maxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else if (leftPlaneZ >= 0) {
						if (boundBox.minX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.maxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.maxX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.minZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundBox.minX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.minZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.maxX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.maxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					}
				}
				// Отсечение по правой стороне
				if (culling & 8) {
					if (rightPlaneX >= 0) if (rightPlaneY >= 0) if (rightPlaneZ >= 0) {
						if (boundBox.maxX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.maxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.minX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.minZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundBox.maxX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.minZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.minX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.maxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else if (rightPlaneZ >= 0) {
						if (boundBox.maxX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.maxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.minX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.minZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundBox.maxX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.minZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.minX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.maxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else if (rightPlaneY >= 0) if (rightPlaneZ >= 0) {
						if (boundBox.minX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.maxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.maxX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.minZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundBox.minX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.minZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.maxX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.maxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else if (rightPlaneZ >= 0) {
						if (boundBox.minX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.maxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.maxX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.minZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundBox.minX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.minZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.maxX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.maxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					}
				}
				// Отсечение по верхней стороне
				if (culling & 16) {
					if (topPlaneX >= 0) if (topPlaneY >= 0) if (topPlaneZ >= 0) {
						if (boundBox.maxX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.maxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.minX*topPlaneX + boundBox.minY*topPlaneY + boundBox.minZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundBox.maxX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.minZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.minX*topPlaneX + boundBox.minY*topPlaneY + boundBox.maxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else if (topPlaneZ >= 0) {
						if (boundBox.maxX*topPlaneX + boundBox.minY*topPlaneY + boundBox.maxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.minX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.minZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundBox.maxX*topPlaneX + boundBox.minY*topPlaneY + boundBox.minZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.minX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.maxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else if (topPlaneY >= 0) if (topPlaneZ >= 0) {
						if (boundBox.minX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.maxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.maxX*topPlaneX + boundBox.minY*topPlaneY + boundBox.minZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundBox.minX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.minZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.maxX*topPlaneX + boundBox.minY*topPlaneY + boundBox.maxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else if (topPlaneZ >= 0) {
						if (boundBox.minX*topPlaneX + boundBox.minY*topPlaneY + boundBox.maxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.maxX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.minZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundBox.minX*topPlaneX + boundBox.minY*topPlaneY + boundBox.minZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.maxX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.maxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					}
				}
				// Отсечение по нижней стороне
				if (culling & 32) {
					if (bottomPlaneX >= 0) if (bottomPlaneY >= 0) if (bottomPlaneZ >= 0) {
						if (boundBox.maxX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.minX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.minZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundBox.maxX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.minZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.minX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else if (bottomPlaneZ >= 0) {
						if (boundBox.maxX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.minX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.minZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundBox.maxX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.minZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.minX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else if (bottomPlaneY >= 0) if (bottomPlaneZ >= 0) {
						if (boundBox.minX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.maxX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.minZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundBox.minX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.minZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.maxX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else if (bottomPlaneZ >= 0) {
						if (boundBox.minX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.maxX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.minZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundBox.minX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.minZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.maxX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					}
				}
			}
			// Отсечение по окклюдерам
			for (var o:int = 0; o < numOccluders; o++) {
				var occluder:Vector.<Number> = occluders[o], occluderLength:int = occluder.length;
				for (var ni:int = 0; ni < occluderLength; ni += 4) {
					var nx:Number = occluder[ni], ny:Number = occluder[int(ni + 1)], nz:Number = occluder[int(ni + 2)], no:Number = occluder[int(ni + 3)];
					if (nx >= 0) if (ny >= 0) if (nz >= 0) {
						if (boundBox.maxX*nx + boundBox.maxY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.maxX*nx + boundBox.maxY*ny + boundBox.minZ*nz > no) break;
					} else if (nz >= 0) {
						if (boundBox.maxX*nx + boundBox.minY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.maxX*nx + boundBox.minY*ny + boundBox.minZ*nz > no) break;
					} else if (ny >= 0) if (nz >= 0) {
						if (boundBox.minX*nx + boundBox.maxY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.minX*nx + boundBox.maxY*ny + boundBox.minZ*nz > no) break;
					} else if (nz >= 0) {
						if (boundBox.minX*nx + boundBox.minY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.minX*nx + boundBox.minY*ny + boundBox.minZ*nz > no) break;
					}
				}
				if (ni == occluderLength) return -1;
			}
			return culling;
		}
		
		protected function occludeGeometry(camera:Camera3D, geometry:Geometry):Boolean {
			if (camera.occludedAll) return true;
			for (var i:int = geometry.numOccluders; i < numOccluders; i++) {
				var occluder:Vector.<Number> = occluders[i];
				var occluderLength:int = occluder.length;
				var j:int = 0;
				for (; j < occluderLength; j++) {
					var nx:Number = occluder[j]; j++;
					var ny:Number = occluder[j]; j++;
					var nz:Number = occluder[j]; j++;
					var no:Number = occluder[j];
					if (nx >= 0) if (ny >= 0) if (nz >= 0) {
						if (geometry.maxX*nx + geometry.maxY*ny + geometry.maxZ*nz > no) break;
					} else {
						if (geometry.maxX*nx + geometry.maxY*ny + geometry.minZ*nz > no) break;
					} else if (nz >= 0) {
						if (geometry.maxX*nx + geometry.minY*ny + geometry.maxZ*nz > no) break;
					} else {
						if (geometry.maxX*nx + geometry.minY*ny + geometry.minZ*nz > no) break;
					} else if (ny >= 0) if (nz >= 0) {
						if (geometry.minX*nx + geometry.maxY*ny + geometry.maxZ*nz > no) break;
					} else {
						if (geometry.minX*nx + geometry.maxY*ny + geometry.minZ*nz > no) break;
					} else if (nz >= 0) {
						if (geometry.minX*nx + geometry.minY*ny + geometry.maxZ*nz > no) break;
					} else {
						if (geometry.minX*nx + geometry.minY*ny + geometry.minZ*nz > no) break;
					}
				}
				if (j == occluderLength) return true;
			}
			geometry.numOccluders = numOccluders;
			return false;
		}

		protected function drawAABBGeometry(camera:Camera3D, object:Object3D, canvas:Canvas, geometry:Geometry):void {
			var coord:Number;
			var coordMin:Number;
			var coordMax:Number;
			var axisX:Boolean;
			var axisY:Boolean;
			var current:Geometry = geometry;
			var compared:Geometry;
			// Поиск сплита
			while (current != null) {
				// Сплиты по оси X
				coord = current.minX;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				var outside:Boolean = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.maxX <= coordMax) {
							outside = true;
						} else if (compared.minX < coordMin) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = true;
					axisY = false;
					break;
				}
				coord = current.maxX;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.minX >= coordMin) {
							outside = true;
						} else if (compared.maxX > coordMax) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = true;
					axisY = false;
					break;
				}
				// Сплиты по оси Y
				coord = current.minY;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.maxY <= coordMax) {
							outside = true;
						} else if (compared.minY < coordMin) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = false;
					axisY = true;
					break;
				}
				coord = current.maxY;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.minY >= coordMin) {
							outside = true;
						} else if (compared.maxY > coordMax) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = false;
					axisY = true;
					break;
				}
				// Сплиты по оси Z
				coord = current.minZ;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.maxZ <= coordMax) {
							outside = true;
						} else if (compared.minZ < coordMin) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = false;
					axisY = false;
					break;
				}
				coord = current.maxZ;
				coordMin = coord - threshold;
				coordMax = coord + threshold;
				outside = false;
				compared = geometry;
				while (compared != null) {
					if (current != compared) {
						if (compared.minZ >= coordMin) {
							outside = true;
						} else if (compared.maxZ > coordMax) {
							break;
						}
					}
					compared = compared.next;
				}
				if (compared == null && outside) {
					axisX = false;
					axisY = false;
					break;
				}
				current = current.next;
			}
			// Если найден сплит
			if (current != null) {
				var next:Geometry;
				var negative:Geometry;
				var middle:Geometry;
				var positive:Geometry;
				while (geometry != null) {
					next = geometry.next;
					var min:Number = axisX ? geometry.minX : (axisY ? geometry.minY : geometry.minZ);
					var max:Number = axisX ? geometry.maxX : (axisY ? geometry.maxY : geometry.maxZ);
					if (max > coordMax) {
						geometry.next = positive;
						positive = geometry;
					} else if (min < coordMin) {
						geometry.next = negative;
						negative = geometry;
					} else {
						geometry.next = middle;
						middle = geometry;
					}
					geometry = next;
				}
				// Определение положения камеры
				if (axisX && cameraX > coord || axisY && cameraY > coord || !axisX && !axisY && cameraZ > coord) {
					// Отрисовка объектов спереди
					if (positive != null) {
						if (positive.next != null) {
							drawAABBGeometry(camera, object, canvas, positive);
						} else {
							if (camera.debugMode) positive.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
							positive.draw(camera, canvas, threshold, object.cameraMatrix);
							positive.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					while (middle != null) {
						next = middle.next;
						if (camera.debugMode) middle.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
						middle.draw(camera, canvas, threshold, object.cameraMatrix);
						middle.destroy();
						middle = next;
					}
					// Отрисовка объектов сзади
					if (negative != null) {
						if (negative.next != null) {
							drawAABBGeometry(camera, object, canvas, negative);
						} else {
							if (camera.debugMode) negative.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
							negative.draw(camera, canvas, threshold, object.cameraMatrix);
							negative.destroy();
						}
					}
				} else {
					// Отрисовка объектов сзади
					if (negative != null) {
						if (negative.next != null) {
							drawAABBGeometry(camera, object, canvas, negative);
						} else {
							if (camera.debugMode) negative.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
							negative.draw(camera, canvas, threshold, object.cameraMatrix);
							negative.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					while (middle != null) {
						next = middle.next;
						if (camera.debugMode) middle.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
						middle.draw(camera, canvas, threshold, object.cameraMatrix);
						middle.destroy();
						middle = next;
					}
					// Отрисовка объектов спереди
					if (positive != null) {
						if (positive.next != null) {
							drawAABBGeometry(camera, object, canvas, positive);
						} else {
							if (camera.debugMode) positive.debug(camera, object, canvas, threshold, 1, object.cameraMatrix);
							positive.draw(camera, canvas, threshold, object.cameraMatrix);
							positive.destroy();
						}
					}
				}
			// Если не найден сплит
			} else if (resolveByOOBB) {
				current = geometry;
				while (current != null) {
					current.vertices.length = current.verticesLength;
					object.cameraMatrix.transformVectors(current.vertices, current.vertices);
					if (!current.viewAligned) {
						current.calculateOOBB();
					}
					current = current.next;
				}
				drawOOBBGeometry(camera, object, canvas, geometry);
			} else {
				current = geometry;
				while (current != null) {
					current.vertices.length = current.verticesLength;
					object.cameraMatrix.transformVectors(current.vertices, current.vertices);
					current = current.next;
				}
				drawConflictGeometry(camera, object, canvas, geometry);
			}
		}
		
		protected function drawOOBBGeometry(camera:Camera3D, object:Object3D, canvas:Canvas, geometry:Geometry):void {
			var i:int;
			var j:int;
			var x:Number;
			var y:Number;
			var z:Number;
			var o:Number;
			var planeX:Number;
			var planeY:Number;
			var planeZ:Number;
			var planeOffset:Number;
			var behind:Boolean;
			var infront:Boolean;
			var current:Geometry = geometry;
			var compared:Geometry;
			var points:Vector.<Number>;
			var pointsLength:int;
			// Поиск сплита
			while (current != null) {
				if (current.viewAligned) {
					planeOffset = current.vertices[2];
					compared = geometry;
					while (compared != null) {
						if (!compared.viewAligned) {
							behind = false;
							infront = false;
							// Перебор точек
							for (j = 2; j < 24; j += 3) {
								o = compared.points[j] - planeOffset;
								if (o > 0) {
									if (behind) {
										break;
									} else {
										infront = true;
									}
								} else if (infront) {
									break;
								} else {
									behind = true;
								}
							}
							// Если встретилось препятствие
							if (j < 24) break;
						}
						compared = compared.next;
					}
					// Если не встретилось препятствий
					if (compared == null) break;
				} else {
					// Перебор плоскостей
					for (i = 0; i < 24; i++) {
						planeX = current.planes[i]; i++;
						planeY = current.planes[i]; i++;
						planeZ = current.planes[i]; i++;
						planeOffset = current.planes[i];
						var outside:Boolean = false;
						compared = geometry;
						while (compared != null) {
							if (current != compared) {
								behind = false;
								infront = false;
								if (compared.viewAligned) {
									points = compared.vertices;
									pointsLength = compared.verticesLength;
								} else {
									points = compared.points;
									pointsLength = 24;
								}
								// Перебор точек
								for (j = 0; j < pointsLength; j++) {
									x = points[j]; j++;
									y = points[j]; j++;
									z = points[j];
									o = x*planeX + y*planeY + z*planeZ - planeOffset;
									if (o >= -threshold) {
										if (behind) {
											break;
										} else {
											outside = true;
											infront = true;
										}
									} else if (infront) {
										break;
									} else {
										behind = true;
									}
								}
								// Если встретилось препятствие
								if (j < pointsLength) break;
							}
							compared = compared.next;
						}
						// Если не встретилось препятствий и есть объекты по обе стороны
						if (compared == null && outside) break;
					}
					// Если найдена разделяющая плоскость
					if (i < 24) break;
				}
				current = current.next;
			}
			// Если найден сплит
			if (current != null) {
				var next:Geometry;
				var negative:Geometry;
				var middle:Geometry;
				var positive:Geometry;
				if (current.viewAligned) {
					while (geometry != null) {
						next = geometry.next;
						if (geometry.viewAligned) {
							o = geometry.vertices[2] - planeOffset;
							if (o < -threshold) {
								geometry.next = positive;
								positive = geometry;
							} else if (o > threshold) {
								geometry.next = negative;
								negative = geometry;
							} else {
								geometry.next = middle;
								middle = geometry;
							}
						} else {
							for (j = 2; j < 24; j += 3) {
								o = geometry.points[j] - planeOffset;
								if (o < -threshold) {
									geometry.next = positive;
									positive = geometry;
									break;
								} else if (o > threshold) {
									geometry.next = negative;
									negative = geometry;
									break;
								}
							}
							if (j == 24) {
								geometry.next = middle;
								middle = geometry;
							}
						}
						geometry = next;
					}
				} else {
					while (geometry != null) {
						next = geometry.next;
						if (geometry.viewAligned) {
							points = geometry.vertices;
							pointsLength = geometry.verticesLength;
						} else {
							points = geometry.points;
							pointsLength = 24;
						}
						for (j = 0; j < pointsLength; j++) {
							x = points[j]; j++;
							y = points[j]; j++;
							z = points[j];
							o = x*planeX + y*planeY + z*planeZ - planeOffset;
							if (o < -threshold) {
								geometry.next = negative;
								negative = geometry;
								break;
							} else if (o > threshold) {
								geometry.next = positive;
								positive = geometry;
								break;
							}
						}
						if (j == pointsLength) {
							geometry.next = middle;
							middle = geometry;
						}
						geometry = next;
					}
				}
				// Определение положения камеры
				if (current.viewAligned || planeOffset < 0) {
					// Отрисовка объектов спереди
					if (positive != null) {
						if (positive.next != null) {
							drawOOBBGeometry(camera, object, canvas, positive);
						} else {
							if (camera.debugMode) positive.debug(camera, object, canvas, threshold, 2);
							positive.draw(camera, canvas, threshold);
							positive.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					while (middle != null) {
						next = middle.next;
						if (camera.debugMode) middle.debug(camera, object, canvas, threshold, 2);
						middle.draw(camera, canvas, threshold);
						middle.destroy();
						middle = next;
					}
					// Отрисовка объектов сзади
					if (negative != null) {
						if (negative.next != null) {
							drawOOBBGeometry(camera, object, canvas, negative);
						} else {
							if (camera.debugMode) negative.debug(camera, object, canvas, threshold, 2);
							negative.draw(camera, canvas, threshold);
							negative.destroy();
						}
					}
				} else {
					// Отрисовка объектов сзади
					if (negative != null) {
						if (negative.next != null) {
							drawOOBBGeometry(camera, object, canvas, negative);
						} else {
							if (camera.debugMode) negative.debug(camera, object, canvas, threshold, 2);
							negative.draw(camera, canvas, threshold);
							negative.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					while (middle != null) {
						next = middle.next;
						if (camera.debugMode) middle.debug(camera, object, canvas, threshold, 2);
						middle.draw(camera, canvas, threshold);
						middle.destroy();
						middle = next;
					}
					// Отрисовка объектов спереди
					if (positive != null) {
						if (positive.next != null) {
							drawOOBBGeometry(camera, object, canvas, positive);
						} else {
							if (camera.debugMode) positive.debug(camera, object, canvas, threshold, 2);
							positive.draw(camera, canvas, threshold);
							positive.destroy();
						}
					}
				}
			// Если не найден сплит	
			} else {
				drawConflictGeometry(camera, object, canvas, geometry);
			}
		}

		protected function drawConflictGeometry(camera:Camera3D, object:Object3D, canvas:Canvas, geometry:Geometry):void {
			var i:int;
			var j:int;
			var next:Geometry;
			var fragment:Fragment;
			// Геометрия с сортировкой предрасчитанное BSP
			var bspGeometry:Geometry;
			// Геометрия, которая присутствует в конфликте
			var conflict:Geometry;
			// Фрагменты с сортировкой динамическое BSP
			var dynamicBSPFirst:Fragment;
			var dynamicBSPLast:Fragment;
			// Фрагменты с сортировкой по средним Z
			var averageZFirst:Fragment;
			var averageZLast:Fragment;
			// Перебор геометрических объектов
			while (geometry != null) {
				next = geometry.next;
				// Сортировка по предрасчитанному BSP
				if (geometry.sorting == 2) {
					geometry.next = bspGeometry;
					bspGeometry = geometry;
				} else {
					// Сортировка по динамическому BSP
					if (geometry.sorting == 3) {
						if (dynamicBSPFirst != null) {
							dynamicBSPLast.next = geometry.fragment;
						} else {
							dynamicBSPFirst = geometry.fragment;
							dynamicBSPLast = dynamicBSPFirst;
							dynamicBSPLast.geometry = geometry;
						}
						while (dynamicBSPLast.next != null) {
							dynamicBSPLast = dynamicBSPLast.next;
							dynamicBSPLast.geometry = geometry;
						}
					// Сортировка по средним Z
					} else {
						if (averageZFirst != null) {
							averageZLast.next = geometry.fragment;
						} else {
							averageZFirst = geometry.fragment;
							averageZLast = averageZFirst;
							averageZLast.geometry = geometry;
						}
						while (averageZLast.next != null) {
							averageZLast = averageZLast.next;
							averageZLast.geometry = geometry;
						}
					}
					geometry.fragment = null;
					geometry.next = conflict;
					conflict = geometry;
				}
				geometry = next;
			}
			// Соединение списков
			if (conflict != null) {
				geometry = conflict;
				while (geometry.next != null) {
					geometry = geometry.next;
				}
				geometry.next = bspGeometry;
			} else {
				conflict = bspGeometry;
			}
			// Разрешение конфликта
			if (conflict != null) {
				// Сбор первоначальной кучи фрагментов
				var result:Fragment;
				if (dynamicBSPFirst != null) {
					result = dynamicBSPFirst;
					if (averageZFirst != null) {
						dynamicBSPLast.next = averageZFirst;
					}
				} else {
					if (averageZFirst != null) {
						result = averageZFirst;
					}
				}
				// Если есть статические BSP
				if (bspGeometry != null) {
					// Встройка кучи в первый bsp с внутренней сортировкой
					result = collectNode(bspGeometry.fragment, result, bspGeometry, true);
					result.positive = null;
					bspGeometry = bspGeometry.next;
					// Встройка кучи в остальные bsp без внутренней сортировки
					while (bspGeometry != null) {
						result = collectNode(bspGeometry.fragment, result, bspGeometry, false);
						result.positive = null;
						bspGeometry.fragment = null;
						bspGeometry = bspGeometry.next;
					}
				// Если есть динамические BSP
				} else if (dynamicBSPFirst != null) {
					result = result.next;
					dynamicBSPFirst.next = null;
					result = collectNode(dynamicBSPFirst, result, null, true);
					result.positive = null;
				// Если есть сортировка по средним Z
				} else if (averageZFirst != null) {
					result = sortFragments(result);
					result.positive = null;
				}
				// Проецирование
				geometry = conflict;
				while (geometry != null) {
					geometry.vertices.length = geometry.verticesLength;
					geometry.uvts.length = geometry.verticesLength;
					geometry.projectedVertices.length = geometry.numVertices << 1;
					Utils3D.projectVectors(camera.projectionMatrix, geometry.vertices, geometry.projectedVertices, geometry.uvts);
					geometry = geometry.next;
				}
				// Сбор отрисовочных вызовов
				geometry = result.geometry;
				fragment = result;
				while (fragment.next != null) {
					if (fragment.next.geometry != geometry) {
						fragment.next.negative = result;
						result = fragment.next;
						fragment.next = null;
						geometry = result.geometry;
						fragment = result;
					} else {
						fragment = fragment.next;
					}
				}
				// Дебаг
				if (camera.debugMode) {
					var debugCanvas:Canvas = canvas.getChildCanvas(true, false);
					debugCanvas.gfx.lineStyle(0, 0xFF0000);
					fragment = result;
					while (fragment != null) {
						fragment.geometry.debugPart(camera, debugCanvas, fragment);
						fragment = fragment.negative;
					}
				}
				// Отрисовка
				fragment = result;
				do {
					result = fragment;
					fragment = result.negative;
					result.negative = null;
					result.geometry.drawPart(camera, canvas, result);
				} while (fragment != null);
				// Зачистка
				while (conflict != null) {
					next = conflict.next;
					conflict.destroy();
					conflict = next;
				}
			}
		}
		
		// На выходе список, positive первого элемента которого указывает на последний элемент
		private function collectNode(splitter:Fragment, source:Fragment, geometry:Geometry, sort:Boolean):Fragment {
			var negative:Fragment = negativeReserve;
			var negativeIndices:Vector.<int> = negative.indices;
			var positive:Fragment = positiveReserve;
			var positiveIndices:Vector.<int> = positive.indices;
			var next:Fragment;
			var negativeFirst:Fragment;
			var negativeLast:Fragment;
			var nodeFirst:Fragment;
			var nodeLast:Fragment;
			var positiveFirst:Fragment;
			var positiveLast:Fragment;
			var normalX:Number = splitter.normalX;
			var normalY:Number = splitter.normalY;
			var normalZ:Number = splitter.normalZ;
			var offset:Number = splitter.offset;
			// Сбор фрагментов ноды
			if (geometry == null) {
				nodeFirst = splitter;
				nodeLast = splitter;
			} else if (splitter.num > 0) {
				nodeFirst = splitter;
				nodeLast = splitter;
				nodeLast.geometry = geometry;
				while (nodeLast.next != null) {
					nodeLast = nodeLast.next;
					nodeLast.geometry = geometry;
				}
			}
			// Перебор входной последовательности
			while (source != null) {
				next = source.next;
				var sourceGeometry:Geometry = source.geometry;
				var vertices:Vector.<Number> = sourceGeometry.vertices;
				var uvts:Vector.<Number> = sourceGeometry.uvts;
				var v:int = sourceGeometry.numVertices;
				var vi:int = sourceGeometry.verticesLength;
				var indices:Vector.<int> = source.indices;
				var num:int = source.num;
				var infront:Boolean = false;
				var behind:Boolean = false;
				var negativeNum:int = 0;
				var positiveNum:int = 0;
				// Первая точка ребра
				var n:int = num - 1;
				var a:int = indices[n];
				var ai:int = a*3;
				var ax:Number = vertices[ai]; n = ai + 1;
				var ay:Number = vertices[n]; n++;
				var az:Number = vertices[n];
				var ao:Number = ax*normalX + ay*normalY + az*normalZ - offset;
				for (var i:int = 0; i < num; i++) {
					// Вторая точка ребра
					var b:int = indices[i];
					var bi:int = b*3;
					var bx:Number = vertices[bi]; n = bi + 1;
					var by:Number = vertices[n]; n++;
					var bz:Number = vertices[n];
					var bo:Number = bx*normalX + by*normalY + bz*normalZ - offset;
					// Рассечение ребра
					if (ao < -threshold && bo > threshold || bo < -threshold && ao > threshold) {
						var t:Number = ao/(ao - bo);
						var au:Number = uvts[ai]; ai++;
						var av:Number = uvts[ai];
						var bu:Number = uvts[bi]; n = bi + 1;
						var bv:Number = uvts[n];
						vertices[vi] = ax + (bx - ax)*t;
						uvts[vi] = au + (bu - au)*t; vi++;
						vertices[vi] = ay + (by - ay)*t;
						uvts[vi] = av + (bv - av)*t; vi++;
						vertices[vi] = az + (bz - az)*t;
						uvts[vi] = 0; vi++;
						negativeIndices[negativeNum] = v;
						negativeNum++;
						positiveIndices[positiveNum] = v;
						positiveNum++;
						v++;
					}
					// Добавление точки
					if (bo < -threshold) {
						negativeIndices[negativeNum] = b;
						negativeNum++;
						behind = true;
					} else if (bo > threshold) {
						positiveIndices[positiveNum] = b;
						positiveNum++;
						infront = true;
					} else {
						negativeIndices[negativeNum] = b;
						negativeNum++;
						positiveIndices[positiveNum] = b;
						positiveNum++;
					}
					a = b;
					ai = bi;
					ax = bx;
					ay = by;
					az = bz;
					ao = bo;
				}
				// Анализ разбиения
				if (behind && infront) {
					sourceGeometry.numVertices = v;
					sourceGeometry.verticesLength = vi;
					negative.num = negativeNum;
					positive.num = positiveNum;
					negative.geometry = sourceGeometry;
					positive.geometry = sourceGeometry;
					if (sourceGeometry.sorting == 3) {
						negative.normalX = source.normalX;
						negative.normalY = source.normalY;
						negative.normalZ = source.normalZ;
						negative.offset = source.offset;
						positive.normalX = source.normalX;
						positive.normalY = source.normalY;
						positive.normalZ = source.normalZ;
						positive.offset = source.offset;
					}
					if (negativeFirst != null) {
						negativeLast.next = negative;
					} else {
						negativeFirst = negative;
					}
					negativeLast = negative;
					if (positiveFirst != null) {
						positiveLast.next = positive;
					} else {
						positiveFirst = positive;
					}
					positiveLast = positive;
					negativeReserve = source.create();
					positiveReserve = source.create();
					negative = negativeReserve;
					negativeIndices = negative.indices;
					positive = positiveReserve;
					positiveIndices = positive.indices;
					source.geometry = null;
					source.destroy();
				} else if (behind) {
					source.next = null;
					if (negativeFirst != null) {
						negativeLast.next = source;
					} else {
						negativeFirst = source;
					}
					negativeLast = source;
				} else if (infront) {
					source.next = null;
					if (positiveFirst != null) {
						positiveLast.next = source;
					} else {
						positiveFirst = source;
					}
					positiveLast = source;
				} else {
					source.next = null;
					if (nodeFirst != null) {
						nodeLast.next = source;
					} else {
						nodeFirst = source;
					}
					nodeLast = source;
				}
				source = next;
			}
			// Сбор задней части
			if (splitter.negative != null) {
				negativeFirst = collectNode(splitter.negative, negativeFirst, geometry, sort);
				negativeLast = negativeFirst.positive;
				negativeFirst.positive = null;
				splitter.negative = null;
			} else if (sort && negativeFirst != negativeLast) {
				if (negativeFirst.geometry.sorting == 3) {
					next = negativeFirst.next;
					negativeFirst.next = null;
					negativeFirst = collectNode(negativeFirst, next, null, sort);
				} else {
					negativeFirst = sortFragments(negativeFirst);
				}
				negativeLast = negativeFirst.positive;
				negativeFirst.positive = null;
			}
			// Сбор передней части
			if (splitter.positive != null) {
				positiveFirst = collectNode(splitter.positive, positiveFirst, geometry, sort);
				positiveLast = positiveFirst.positive;
				positiveFirst.positive = null;
				splitter.positive = null;
			} else if (sort && positiveFirst != positiveLast) {
				if (positiveFirst.geometry.sorting == 3) {
					next = positiveFirst.next;
					positiveFirst.next = null;
					positiveFirst = collectNode(positiveFirst, next, null, sort);
				} else {
					positiveFirst = sortFragments(positiveFirst);
				}
				positiveLast = positiveFirst.positive;
				positiveFirst.positive = null;
			}
			// Если камера спереди
			if (splitter.offset < 0) {
				if (negativeFirst != null) {
					if (nodeFirst != null) {
						negativeLast.next = nodeFirst;
						if (positiveFirst != null) {
							nodeLast.next = positiveFirst;
							negativeFirst.positive = positiveLast;
						} else {
							negativeFirst.positive = nodeLast;
						}
					} else {
						if (positiveFirst != null) {
							negativeLast.next = positiveFirst;
							negativeFirst.positive = positiveLast;
						} else {
							negativeFirst.positive = negativeLast;
						}
					}
					return negativeFirst;
				} else if (nodeFirst != null) {
					if (positiveFirst != null) {
						nodeLast.next = positiveFirst;
						nodeFirst.positive = positiveLast;
					} else {
						nodeFirst.positive = nodeLast;
					}
					return nodeFirst;
				} else {
					positiveFirst.positive = positiveLast;
					return positiveFirst;
				}
			} else {
				if (positiveFirst != null) {
					if (nodeFirst != null) {
						positiveLast.next = nodeFirst;
						if (negativeFirst != null) {
							nodeLast.next = negativeFirst;
							positiveFirst.positive = negativeLast;
						} else {
							positiveFirst.positive = nodeLast;
						}
					} else {
						if (negativeFirst != null) {
							positiveLast.next = negativeFirst;
							positiveFirst.positive = negativeLast;
						} else {
							positiveFirst.positive = positiveLast;
						}
					}
					return positiveFirst;
				} else if (nodeFirst != null) {
					if (negativeFirst != null) {
						nodeLast.next = negativeFirst;
						nodeFirst.positive = negativeLast;
					} else {
						nodeFirst.positive = nodeLast;
					}
					return nodeFirst;
				} else {
					negativeFirst.positive = negativeLast;
					return negativeFirst;
				}
			}
		}
		
		// На выходе список, positive первого элемента которого указывает на последний элемент
		private function sortFragments(source:Fragment):Fragment {
			var i:int;
			var j:int;
			var next:Fragment;
			var first:Fragment;
			var last:Fragment;
			var fragments:Vector.<Fragment> = sortingFragments;
			var fragmentsLength:int = 0;
			// Заполнение вектора
			while (source != null) {
				next = source.next;
				source.next = null;
				var vertices:Vector.<Number> = source.geometry.vertices;
				var indices:Vector.<int> = source.indices;
				var num:int = source.num;
				var sum:Number = 0;
				for (i = 0; i < num; i++) {
					var vi:int = indices[i]*3 + 2;
					sum += vertices[vi];
				}
				source.offset = sum/num;
				fragments[fragmentsLength] = source;
				fragmentsLength++;
				source = next;
			}
			// Сортировка
			var stack:Vector.<int> = sortingStack;
			stack[0] = 0;
			stack[1] = fragmentsLength - 1;
			var index:int = 2;
			while (index > 0) {
				index--;
				var r:int = stack[index];
				j = r;
				index--;
				var l:int = stack[index];
				i = l;
				var k:int = r + l;
				var t:int = k >> 1;
				next = fragments[t];
				var median:Number = next.offset;
				while (i <= j) {
	 				var left:Fragment = fragments[i];
	 				while (left.offset > median) {
	 					i++;
	 					left = fragments[i];
	 				}
	 				var right:Fragment = fragments[j];
	 				while (right.offset < median) {
	 					j--;
		 				right = fragments[j];
		 			}
	 				if (i <= j) {
	 					fragments[i] = right;
	 					fragments[j] = left;
	 					i++;
	 					j--;
	 				}
	 			}
				if (l < j) {
					stack[index] = l;
					index++;
					stack[index] = j;
					index++;
				}
				if (i < r) {
					stack[index] = i;
					index++;
					stack[index] = r;
					index++;
				}
			}
			// Сбор
			for (i = 0; i < fragmentsLength; i++) {
				next = fragments[i];
				if (first != null) {
					last.next = next;
				} else {
					first = next;
				}
				last = next;
				fragments[i] = null;
			}
			first.positive = last;
			return first;
		}
		
	}
}
