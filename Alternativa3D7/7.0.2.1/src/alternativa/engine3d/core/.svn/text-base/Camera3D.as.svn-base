package alternativa.engine3d.core {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import alternativa.engine3d.objects.Mesh;

	use namespace alternativa3d;
	
	public class Camera3D extends Object3D {
		
		/**
		 * Вьюпорт камеры. 
		 */
		public var canvas:Canvas;
		public var fov:Number = Math.PI/2;
		/**
		 * Ширина вьюпорта. 
		 */
		public var width:Number = 500;
		/**
		 * Высота вьюпорта. 
		 */
		public var height:Number = 500;
		public var farClipping:Number = 5000;
		public var farFalloff:Number = 4000;
		public var nearClipping:Number = 50;

		// Матрица проецирования
		/**
		 * @private 
		 */
		alternativa3d var projectionMatrixData:Vector.<Number> = new Vector.<Number>(16, true);
		/**
		 * @private 
		 */
		alternativa3d var projectionMatrix:Matrix3D;
		// Параметры перспективы
		/**
		 * @private 
		 */
		alternativa3d var viewSize:Number;
		/**
		 * @private 
		 */
		alternativa3d var viewSizeX:Number;
		/**
		 * @private 
		 */
		alternativa3d var viewSizeY:Number;
		/**
		 * @private 
		 */
		alternativa3d var perspectiveScaleX:Number;
		/**
		 * @private 
		 */
		alternativa3d var perspectiveScaleY:Number;
		/**
		 * @private 
		 */
		alternativa3d var invertPerspectiveScaleX:Number;
		/**
		 * @private 
		 */
		alternativa3d var invertPerspectiveScaleY:Number;
		/**
		 * @private 
		 */
		alternativa3d var focalLength:Number;
		// Перекрытия
		/**
		 * @private 
		 */
		alternativa3d var occlusionPlanes:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
		/**
		 * @private 
		 */
		alternativa3d var occlusionEdges:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
		/**
		 * @private 
		 */
		alternativa3d var numOccluders:int;
		/**
		 * @private 
		 */
		alternativa3d var occludedAll:Boolean;

		/**
		 * @private 
		 */
		override alternativa3d function get canDraw():Boolean {
			return false;
		}
		
		/**
		 * Отрисовка иерархии объектов, в которой находится камера.
		 * Перед render(), если менялись параметры камеры, нужно вызвать updateProjection().
		 */
		public function render():void {
			// Расчёт матрицы перевода из рута в камеру
			cameraMatrix.identity();
			var object:Object3D = this;
			while (object._parent != null) {
				cameraMatrix.append(object.matrix);
				object = object._parent;
			}
			cameraMatrix.invert();
			cameraMatrix.appendScale(perspectiveScaleX, perspectiveScaleY, 1);
			
			numOccluders = 0;
			occludedAll = false;
			
			Mesh.numDrawingTriangles = 0;
			
			// Отрисовка
			if (object.visible && object.canDraw) {
				object.cameraMatrix.identity();
				object.cameraMatrix.prepend(cameraMatrix);
				object.cameraMatrix.prepend(object.matrix);
				if (object.cullingInCamera(this, 63) >= 0) {
					// Отрисовка объекта
					canvas.numDraws = 0;
					object.draw(this, object, canvas);
					// Если не нарисовалось, зачищаем рутовый канвас
					if (canvas.numDraws == 0) canvas.removeChildren(0);
				} else {
					// Если отсеклось, зачищаем рутовый канвас
					canvas.removeChildren(0);
				}
			}
		}
		
		/**
		 * После изменения параметров fov, width, height нужно вызвать этот метод.
		 */
		public function updateProjection():void {
			// Расчёт параметров перспективы
			viewSize = Math.sqrt(width*width + height*height)*0.5;
			focalLength = viewSize/Math.tan(fov*0.5);
			viewSizeX = width*0.5;
			viewSizeY = height*0.5;
			perspectiveScaleX = focalLength/viewSizeX;
			perspectiveScaleY = focalLength/viewSizeY;
			invertPerspectiveScaleX = viewSizeX/focalLength;
			invertPerspectiveScaleY = viewSizeY/focalLength;
			
			// Подготовка матрицы проецирования
			projectionMatrixData[0] = viewSizeX;
			projectionMatrixData[5] = viewSizeY;
			projectionMatrixData[10] = 1;
			projectionMatrixData[11] = 1;
			projectionMatrix = new Matrix3D(projectionMatrixData);
		}
		
		/*
		// Occlusion culling
			if (numOccluders > 0) {
				for (var n:int = 0; n < numOccluders; n++) {
					var occluder:Vector.<Number> = occluders[n];
					var occlude:Boolean = true; 
					occlude: for (var j:int = 0, length:int = occluder.length; j < length;) {
						var x:Number = occluder[j++], y:Number = occluder[j++], z:Number = occluder[j++]
						for (i = 0; i <= 21; i += 3) {
							if (boundBoxVertices[i]*x + boundBoxVertices[int(i + 1)]*y + boundBoxVertices[int(i + 2)]*z > 0) {
								occlude = false;
								break occlude; 
							}
						}
					}
					if (occlude) return -1;
				}
			}
		*/
		
		private static var _tmpv:Vector.<Number> = new Vector.<Number>(3);
		
		/**
		 * @param v
		 * @param result
		 */
		public function projectGlobal(v:Vector3D, result:Vector3D):void {
			_tmpv[0] = v.x; _tmpv[1] = v.y; _tmpv[2] = v.z;
			cameraMatrix.transformVectors(_tmpv, _tmpv);
			projectionMatrix.transformVectors(_tmpv, _tmpv);
			result.z = _tmpv[2];
			result.x = _tmpv[0]/result.z;
			result.y = _tmpv[1]/result.z;
		}
		
	}
}