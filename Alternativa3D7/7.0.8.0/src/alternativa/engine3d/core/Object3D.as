package alternativa.engine3d.core {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.ColorTransform;
	import flash.geom.Matrix3D;
	import flash.geom.Utils3D;
	import flash.utils.getQualifiedClassName;
	
	use namespace alternativa3d;

	/**
	 * Базовый трёхмерный объект
	 */
	public class Object3D {
		
		public var name:String;
		/**
		 * Матрица трансформации. Управлять трансформацией объекта можно только через это свойство
		 * путём назначения новой матрицы или с помощью методов матрицы.
		 */
		public var matrix:Matrix3D = new Matrix3D();
		public var visible:Boolean = true;
		
		public var alpha:Number = 1;
		public var blendMode:String = "normal";
		public var colorTransform:ColorTransform = null;
		public var filters:Array = null;

		alternativa3d var _parent:Object3DContainer;

		alternativa3d var _boundBox:BoundBox;
		
		alternativa3d var culling:int = 0;

		alternativa3d var cameraMatrix:Matrix3D = new Matrix3D();

		static private const boundBoxVertices:Vector.<Number> = new Vector.<Number>(24, true);

		alternativa3d function get canDraw():Boolean {
			return true;
		}

		alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {}
		
		alternativa3d function debug(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var debugResult:int = camera.checkInDebug(this);
			if (debugResult == 0) return;
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false);
			if (debugResult & Debug.AXES) object.drawAxes(camera, canvas);
			if (debugResult & Debug.CENTERS) object.drawCenter(camera, canvas);
			if (debugResult & Debug.NAMES) object.drawName(camera, canvas);
			if (debugResult & Debug.BOUNDS) object.drawBoundBox(camera, canvas);
		}
		
		alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			return null;
		}
		
		alternativa3d function split(normalX:Number, normalY:Number, normalZ:Number, offset:Number, threshold:Number):Vector.<Object3D> {
			return new Vector.<Object3D>(2);
		}
		
		public function get boundBox():BoundBox {
			return _boundBox;
		}
		
		public function set boundBox(value:BoundBox):void {
			_boundBox = value;
		}

		/**
		 * Расчёт баунда 
		 * @param matrix Трансформация пространства, в системе которого расчитывается баунд.
		 * Если этот параметр не указан, баунд расчитается в локальных координатах объекта. 
		 * @param boundBox Баунд, в который записывается результат.
		 * Если этот параметр не указан, создаётся новый экземпляр.
		 * @return Расчитанный баунд.
		 */
		public function calculateBoundBox(matrix:Matrix3D = null, boundBox:BoundBox = null):BoundBox {
			return null;
		}

		public function get parent():Object3DContainer {
			return _parent;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function cullingInCamera(camera:Camera3D, parentCulling:int):int {
			if (camera.occludedAll) return -1;
			culling = parentCulling;
			var i:int, infront:Boolean, behind:Boolean, boundBox:BoundBox = this.boundBox, numOccluders:int = camera.numOccluders, cull:Boolean = culling > 0 && boundBox != null, occlude:Boolean = numOccluders > 0 && boundBox != null;
			// Расчёт точек баунда в координатах камеры 
			if (cull || occlude) boundBoxVertices[0] = boundBoxVertices[3] = boundBoxVertices[6] = boundBoxVertices[9] = boundBox.minX, boundBoxVertices[1] = boundBoxVertices[4] = boundBoxVertices[13] = boundBoxVertices[16] = boundBox.minY, boundBoxVertices[2] = boundBoxVertices[8] = boundBoxVertices[14] = boundBoxVertices[20] = boundBox.minZ, boundBoxVertices[12] = boundBoxVertices[15] = boundBoxVertices[18] = boundBoxVertices[21] = boundBox.maxX, boundBoxVertices[7] = boundBoxVertices[10] = boundBoxVertices[19] = boundBoxVertices[22] = boundBox.maxY, boundBoxVertices[5] = boundBoxVertices[11] = boundBoxVertices[17] = boundBoxVertices[23] = boundBox.maxZ, cameraMatrix.transformVectors(boundBoxVertices, boundBoxVertices);
			// Куллинг
			if (cull) {
				if (culling & 1) {
					for (i = 2, infront = false, behind = false; i <= 23; i += 3) {
						if (boundBoxVertices[i] > camera.nearClipping) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						// TODO: проверка не нужна
						if (infront) culling &= 62;
					}
				}
				if (culling & 2) {
					for (i = 2, infront = false, behind = false; i <= 23; i += 3) {
						if (boundBoxVertices[i] < camera.farClipping) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						if (infront) culling &= 61;
					}
				}
				if (culling & 4) {
					for (i = 0, infront = false, behind = false; i <= 21; i += 3) {
						if (-boundBoxVertices[i] < boundBoxVertices[int(i + 2)]) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						if (infront) culling &= 59;
					}
				}
				if (culling & 8) {
					for (i = 0, infront = false, behind = false; i <= 21; i += 3) {
						if (boundBoxVertices[i] < boundBoxVertices[int(i + 2)]) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						if (infront) culling &= 55;
					}
				}
				if (culling & 16) {
					for (i = 1, infront = false, behind = false; i <= 22; i += 3) {
						if (-boundBoxVertices[i] < boundBoxVertices[int(i + 1)]) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						if (infront) culling &= 47;
					}
				}
				if (culling & 32) {
					for (i = 1, infront = false, behind = false; i <= 22; i += 3) {
						if (boundBoxVertices[i] < boundBoxVertices[int(i + 1)]) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						if (infront) culling &= 31;
					}
				}
			}
			// Окклюдинг
			if (occlude) {
				for (var o:int = 0; o < numOccluders; o++) {
					var planeOccluder:Vector.<Number> = camera.occlusionPlanes[o], planeOccluderLength:int = planeOccluder.length;
					for (var ni:int = 0; ni < planeOccluderLength; ni += 3) {
						var nx:Number = planeOccluder[ni], ny:Number = planeOccluder[int(ni + 1)], nz:Number = planeOccluder[int(ni + 2)];
						for (i = 0; i < 24; i += 3) if (nx*boundBoxVertices[i] + ny*boundBoxVertices[int(i + 1)] + nz*boundBoxVertices[int(i + 2)] >= 0) break;
						if (i < 24) break;
					}
					if (ni == planeOccluderLength) return -1;
				}
			}
			return culling;
		}

		alternativa3d function drawAxes(camera:Camera3D, canvas:Canvas):void {
			
		}
		
		alternativa3d function drawCenter(camera:Camera3D, canvas:Canvas):void {
			
		}
		
		alternativa3d function drawName(camera:Camera3D, canvas:Canvas):void {
			
		}
		
		static private const boundBoxProjectedVertices:Vector.<Number> = new Vector.<Number>(16, true);
		static private const boundBoxUVTs:Vector.<Number> = new Vector.<Number>(24, true);
		alternativa3d function drawBoundBox(camera:Camera3D, canvas:Canvas, color:int = -1):void {
			
			var boundBox:BoundBox = this.boundBox;
			if (boundBox == null) return;
			
			boundBoxVertices[0] = boundBoxVertices[3] = boundBoxVertices[6] = boundBoxVertices[9] = boundBox.minX;
			boundBoxVertices[1] = boundBoxVertices[4] = boundBoxVertices[13] = boundBoxVertices[16] = boundBox.minY;
			boundBoxVertices[2] = boundBoxVertices[8] = boundBoxVertices[14] = boundBoxVertices[20] = boundBox.minZ;
			
			boundBoxVertices[12] = boundBoxVertices[15] = boundBoxVertices[18] = boundBoxVertices[21] = boundBox.maxX;
			boundBoxVertices[7] = boundBoxVertices[10] = boundBoxVertices[19] = boundBoxVertices[22] = boundBox.maxY;
			boundBoxVertices[5] = boundBoxVertices[11] = boundBoxVertices[17] = boundBoxVertices[23] = boundBox.maxZ;
			
			cameraMatrix.transformVectors(boundBoxVertices, boundBoxVertices);
			for (var i:int = 0; i < 8; i++) {
				if (boundBoxVertices[int(i*3 +2)] <= 0) return;
			}
			Utils3D.projectVectors(camera.projectionMatrix, boundBoxVertices, boundBoxProjectedVertices, boundBoxUVTs);
			canvas.gfx.endFill();
			canvas.gfx.lineStyle(0, (color < 0) ? ((culling > 0) ? 0xFFFF00 : 0x00FF00) : color);
			canvas.gfx.moveTo(boundBoxProjectedVertices[0], boundBoxProjectedVertices[1]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[2], boundBoxProjectedVertices[3]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[6], boundBoxProjectedVertices[7]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[4], boundBoxProjectedVertices[5]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[0], boundBoxProjectedVertices[1]);
			canvas.gfx.moveTo(boundBoxProjectedVertices[8], boundBoxProjectedVertices[9]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[10], boundBoxProjectedVertices[11]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[14], boundBoxProjectedVertices[15]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[12], boundBoxProjectedVertices[13]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[8], boundBoxProjectedVertices[9]);
			canvas.gfx.moveTo(boundBoxProjectedVertices[0], boundBoxProjectedVertices[1]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[8], boundBoxProjectedVertices[9]);
			canvas.gfx.moveTo(boundBoxProjectedVertices[2], boundBoxProjectedVertices[3]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[10], boundBoxProjectedVertices[11]);
			canvas.gfx.moveTo(boundBoxProjectedVertices[4], boundBoxProjectedVertices[5]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[12], boundBoxProjectedVertices[13]);
			canvas.gfx.moveTo(boundBoxProjectedVertices[6], boundBoxProjectedVertices[7]);
			canvas.gfx.lineTo(boundBoxProjectedVertices[14], boundBoxProjectedVertices[15]);
		}
		
		public function toString():String {
			var className:String = getQualifiedClassName(this);
			return "[" + className.substr(className.indexOf("::") + 2) + " " + name + "]";
		}
		
	}
}
