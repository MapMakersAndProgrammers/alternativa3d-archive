package alternativa.engine3d.lights {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.GridMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Texture3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace alternativa3d;
	public class DirectionalLight extends Object3D {

		public var useSingle:Boolean = false;

		// lambda scales between logarithmic and uniform
		public var shadowLambda:Number = 1.0;

		public var debugShadowMaterial:GridMaterial;

		public var createTextures:Boolean = false;

		private static var dummy:Texture3D;

		public var color:Vector.<Number> = Vector.<Number>([1, 1, 1, 1]);

		public var debugMaterial:TextureMaterial;
		
		public var options:Vector.<Number> = Vector.<Number>([0.007, 10000, 1.0, 0]); // Смещение, множитель

		// Матрица перевода в источник света
		alternativa3d var lightMatrix:Matrix3D = new Matrix3D();
		alternativa3d var uvMatrix:Matrix3D = new Matrix3D();

		private var near:Number;
		private var far:Number;

		private var _width:uint;
		private var _height:uint;

		public var numSplits:uint;
		alternativa3d var currentSplitNear:Number;
		alternativa3d var currentSplitFar:Number;

		alternativa3d var currentSplitHaveShadow:Boolean = false;

		alternativa3d var globalVector:Vector3D;

		// Баунды сплита
		alternativa3d var frustumMinX:Number;
		alternativa3d var frustumMaxX:Number;
		alternativa3d var frustumMinY:Number;
		alternativa3d var frustumMaxY:Number;
		alternativa3d var frustumMinZ:Number;
		alternativa3d var frustumMaxZ:Number;

		private var shadowMap:Texture3D;

		public function DirectionalLight(width:uint, height:uint, near:Number, far:Number, numSplits:uint = 4) {
			this._width = width;
			this._height = height;
			this.near = near;
			this.far = far;
			this.numSplits = numSplits;
		}

		alternativa3d function update(camera:Camera3D, context3d:Context3D, splitIndex:int):void {
			// Расчёт матрицы перевода из глобального пространства в камеру
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				cameraMatrix.append(root.cameraMatrix);
			}
			globalVector = cameraMatrix.deltaTransformVector(Vector3D.Z_AXIS);
			cameraMatrix.invert();

			var cameraWCoeff:Number = camera.width/2/camera.focalLength;
			var cameraHCoeff:Number = camera.height/2/camera.focalLength;

			var points:Vector.<Vector3D> = new Vector.<Vector3D>();
			points[0] = new Vector3D(-cameraWCoeff, -cameraHCoeff, 0);
			points[1] = new Vector3D(cameraWCoeff, -cameraHCoeff, 0);
			points[2] = new Vector3D(cameraWCoeff, cameraHCoeff, 0);
			points[3] = new Vector3D(-cameraWCoeff, cameraHCoeff, 0);
			var p:Vector3D;
			var transformed:Vector3D = new Vector3D();

			var currentNear:Number = (camera.nearClipping < near) ? near : camera.nearClipping; 
			var currentFar:Number = (camera.farClipping < far) ? camera.farClipping : far;

			frustumMinX = Number.MAX_VALUE;
			frustumMinY = Number.MAX_VALUE;
			frustumMinZ = Number.MAX_VALUE;
			frustumMaxX = -Number.MAX_VALUE;
			frustumMaxY = -Number.MAX_VALUE;
			frustumMaxZ = -Number.MAX_VALUE;

			var fNear:Number = splitIndex/numSplits;
			var splitNear:Number = shadowLambda*currentNear*Math.pow(currentFar/currentNear, fNear) + (1 - shadowLambda)*(currentNear + fNear*(currentFar - currentNear));
			var fFar:Number = (splitIndex + 1)/numSplits;
			var splitFar:Number = shadowLambda*currentNear*Math.pow(currentFar/currentNear, fFar) + (1 - shadowLambda)*(currentNear + fFar*(currentFar - currentNear));

			currentSplitNear = splitNear;
			currentSplitFar = splitFar;

			projectionMatrix.identity();
			projectionMatrix.append(camera.globalMatrix);
			projectionMatrix.append(cameraMatrix);
			// Считаем баунд куска в источнике света
			for (var j:int = 0; j < 8; j++) {
				if (j < 4) {
					p = points[j];
					transformed.x = p.x * splitNear;
					transformed.y = p.y * splitNear;
					transformed.z = splitNear;
				} else {
					p = points[j - 4];
					transformed.x = p.x * splitFar;
					transformed.y = p.y * splitFar;
					transformed.z = splitFar;
				}
				p = projectionMatrix.transformVector(transformed);
				if (p.x < frustumMinX) {
					frustumMinX = p.x;
				} else if (p.x > frustumMaxX) {
					frustumMaxX = p.x;
				}
				if (p.y < frustumMinY) {
					frustumMinY = p.y;
				} else if (p.y > frustumMaxY) {
					frustumMaxY = p.y;
				}
				if (p.z > frustumMaxZ) {
					frustumMaxZ = p.z;
				}
			}
			frustumMinZ = 0;

			var pixelW:Number = 1/_width;

			// Считаем матрицу проецирования
			var rawData:Vector.<Number> = new Vector.<Number>(16);
			// cameraMatrixData
			rawData[0] = 2/(frustumMaxX - frustumMinX);
			rawData[5] = 2/(frustumMaxY - frustumMinY);
			rawData[10]= 1/(frustumMaxZ - frustumMinZ);
			rawData[12] = (-0.5 * (frustumMaxX + frustumMinX) * rawData[0]);
			rawData[13] = (-0.5 * (frustumMaxY + frustumMinY) * rawData[5]);
			rawData[14]= -frustumMinZ/(frustumMaxZ - frustumMinZ);
			rawData[15]= 1;
			projectionMatrix.rawData = rawData;

			rawData[0] = 1/((frustumMaxX - frustumMinX));
			if (useSingle) {
				rawData[5] = 1/((frustumMaxY - frustumMinY));
			} else {
				rawData[5] = -1/((frustumMaxY - frustumMinY));
			}
			rawData[12] = 0.5 - (0.5 * (frustumMaxX + frustumMinX) * rawData[0]);
			rawData[13] = 0.5 - (0.5 * (frustumMaxY + frustumMinY) * rawData[5]);
			uvMatrix = new Matrix3D(rawData);

			lightMatrix.identity();
			lightMatrix.append(camera.globalMatrix);
			lightMatrix.append(cameraMatrix);
			lightMatrix.append(uvMatrix);

			if (debugShadowMaterial != null) {
				debugShadowMaterial.update(context3d);
			}
			currentSplitHaveShadow = false;
			if (root != this && root.visible && !root.isTransparent && root.useShadows) {
				root.composeMatrix();
				root.cameraMatrix.append(cameraMatrix);
				if (root.cullingInLight(this, 63) >= 0) {
					root.drawInShadowMap(camera, this);
				}
			}
			if (currentSplitHaveShadow) {
				context3d.setRenderToBackbuffer();
			}
		}

		alternativa3d function predraw(context3d:Context3D):void {
			if (!currentSplitHaveShadow) {
				// Создаем или очищаем шедоумапу
				if (createTextures || shadowMap == null) {
					if (useSingle) {
//						shadowMap = context3d.createTexture(_width, _height, "SINGLE", true);
						shadowMap = context3d.createTexture(_width, _height, Context3DTextureFormat.SINGLE_FLOAT, true);
					} else {
//						shadowMap = context3d.createTexture(_width, _height, "BGRA", true);
						shadowMap = context3d.createTexture(_width, _height, Context3DTextureFormat.RGBA_FLOAT, true);
					}
				}
//				if (debugMaterial != null && splitIndex == 0) {
//					debugMaterial.texture3d = shadowMap;
//				}
				context3d.setRenderToTexture(shadowMap, true);
				context3d.clear(1, 1, 1, 1, 1);

				currentSplitHaveShadow = true;
			}
		}

		alternativa3d function getKey():String {
			return (debugShadowMaterial != null) ? "D" : "d";
		}

		alternativa3d function attenuateVertexShader(v4:String, const4x4:uint):String {
//			if (!shadow) {
//				return "";
//			}
			var shader:String = "dp4 " + v4 + ".x, va0, vc" + const4x4+ " \n" +
								"dp4 " + v4 + ".y, va0, vc" + (const4x4 + 1) + " \n" +
								"dp4 " + v4 + ".z, va0, vc" + (const4x4 + 2) + " \n" +
								"dp4 " + v4 + ".w, va0, vc" + (const4x4 + 3) + " \n";
			return shader;
		}

		alternativa3d function attenuateFragmentShader(result4:String, v4:String, texture:uint, const0:uint):String {
//			if (!shadow) {
//				return "mov " + result4 + ", fc" + const0 + ".zzzz \n";
//			}
			if (debugShadowMaterial != null) {
				return debugShadowMaterial.evaluateFragmentShaderSimple(result4, v4, const0, texture);
			}
// 			Отображение шедоу мапы
//			return "tex " + result4 + ", " + v4 + ", fs" + texture.toString() + " <2d,clamp,nearest> \n";

			var shader:String = 
			 	"tex " + result4 + ", " + v4 + ", fs" + texture.toString() + " <2d," + ((useSingle) ? "single," : "") + "clamp,nearest> \n" +
				"add " + result4 + ".z, " + result4 + ".z, fc" + const0.toString() + ".x \n" + // Смещение
				"sub " + result4 + ".z, " + result4 + ".z, " + v4 + ".z \n" +
				"mul " + result4 + ".z, " + result4 + ".z, fc" + const0.toString() + ".y \n" +
				"sat " + result4 + ".z, " + result4 + ".z \n" +
				"mov " + result4 + ", " + result4 + ".zzzz \n";
			return shader; 
		}

		alternativa3d function attenuateProgramSetup(context3d:Context3D, obj:Object3D, const4x4:uint, texture:uint, constF2:uint):void {
//			if (!shadow) {
//				context3d.setProgramConstants("FRAGMENT", constF2, 1, options);
//			}
//			trace("SET:", texture);
			var lightMatrix:Matrix3D = obj.cameraMatrix.clone();
			lightMatrix.append(this.lightMatrix);
			context3d.setTexture(texture, shadowMap);
			context3d.setProgramConstantsMatrix(Context3DProgramType.VERTEX, const4x4, lightMatrix, true);
			if (debugShadowMaterial != null) {
				debugShadowMaterial.evaluateProgramSetupSimple(context3d, constF2, texture);
			} else {
				context3d.setProgramConstants(Context3DProgramType.FRAGMENT, constF2, 1, options);
			}
		}

		alternativa3d function attenuateProgramClean(context3d:Context3D, texture:uint):void {
//			trace("CLN:", texture);
//			if (shadow && !createTextures) {
			if (!createTextures) {
				if (dummy == null) {
					dummy = context3d.createTexture(1, 1, Context3DTextureFormat.BGRA, false);
				}
				context3d.setTexture(texture, dummy);
			}
		}

	}
}
