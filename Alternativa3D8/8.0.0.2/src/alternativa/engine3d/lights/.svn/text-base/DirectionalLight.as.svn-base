package alternativa.engine3d.lights {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.materials.TextureMaterial;
	
	import flash.display.Texture3D;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	use namespace alternativa3d;
	public class DirectionalLight extends Object3D {

		public var color:Vector.<Number> = Vector.<Number>([1, 1, 1, 1]);

		public var debugMaterial:TextureMaterial;
		
		public var shadow:Boolean = true;
		
		public var options:Vector.<Number> = Vector.<Number>([0.007, 10000, 1.0, 0]); // Смещение, множитель

		// Матрица перевода в источник света
		alternativa3d var lightMatrix:Matrix3D = new Matrix3D();
		alternativa3d var uvMatrix:Matrix3D = new Matrix3D();

		private var near:Number;
		private var far:Number;

		private var _width:uint;
		private var _height:uint;

		alternativa3d var numSplits:uint;
		alternativa3d var currentSplitNear:Number;
		alternativa3d var currentSplitFar:Number;

		private var shadowMap:Texture3D;

		public function DirectionalLight(width:uint, height:uint, near:Number, far:Number, numSplits:uint = 4) {
			this._width = width;
			this._height = height;
			this.near = near;
			this.far = far;
			this.numSplits = numSplits;
		}

		alternativa3d function update(camera:Camera3D, view:View, splitIndex:int):void {
			if (shadow) {
//				shadowMap = view.createTexture(_width, _height, "BGRA", true);
//				if (shadowMap == null) {
					shadowMap = view.createTexture(_width, _height, "RGBA_FLOAT", true);
//				}
				if (debugMaterial != null && splitIndex == 0) {
					debugMaterial.texture3d = shadowMap;
				}
			}
			// Расчёт матрицы перевода из глобального пространства в камеру
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				cameraMatrix.append(root.cameraMatrix);
			}
			cameraMatrix.invert();

			if (shadow) {
				view.setRenderToTexture(shadowMap, true);
				view.clear(1, 1, 1, 1, 1);
			}

			var cameraWCoeff:Number = camera.view._width/2/camera.focalLength;
			var cameraHCoeff:Number = camera.view._height/2/camera.focalLength;

			var points:Vector.<Vector3D> = new Vector.<Vector3D>();
			points[0] = new Vector3D(-cameraWCoeff, -cameraHCoeff, 0);
			points[1] = new Vector3D(cameraWCoeff, -cameraHCoeff, 0);
			points[2] = new Vector3D(cameraWCoeff, cameraHCoeff, 0);
			points[3] = new Vector3D(-cameraWCoeff, cameraHCoeff, 0);
			var p:Vector3D;
			var transformed:Vector3D = new Vector3D();

			var currentNear:Number = (camera.nearClipping < near) ? near : camera.nearClipping; 
			var currentFar:Number = (camera.farClipping < far) ? camera.farClipping : far;
			var scissor:Rectangle = new Rectangle();

			var minLightX:Number = Number.MAX_VALUE, minLightY:Number = Number.MAX_VALUE, minLightZ:Number = Number.MAX_VALUE;
			var maxLightX:Number = -Number.MAX_VALUE, maxLightY:Number = -Number.MAX_VALUE, maxLightZ:Number = -Number.MAX_VALUE;

			const lambda:Number = 1;
			var splitNear:Number = lambda*currentNear*Math.pow(currentFar/currentNear, splitIndex/numSplits) + (1 - lambda)*((currentNear + splitIndex/numSplits)*(currentFar - currentNear));
			var splitFar:Number = lambda*currentNear*Math.pow(currentFar/currentNear, (splitIndex + 1)/numSplits) + (1 - lambda)*((currentNear + (splitIndex + 1)/numSplits)*(currentFar - currentNear));

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
				if (p.x < minLightX) {
					minLightX = p.x;
				} else if (p.x > maxLightX) {
					maxLightX = p.x;
				}
				if (p.y < minLightY) {
					minLightY = p.y;
				} else if (p.y > maxLightY) {
					maxLightY = p.y;
				}
				if (p.z < minLightZ) {
					minLightZ = p.z;
				} else if (p.z > maxLightZ) {
					maxLightZ = p.z;
				}
			}
			minLightZ = 0;
//				trace("[Light bounds]", minLightX, maxLightX, minLightY, maxLightY, minLightZ, maxLightZ);

			var pixelW:Number = 1/_width;

			// Считаем матрицу проецирования
			var rawData:Vector.<Number> = new Vector.<Number>(16);
			// cameraMatrixData
//			rawData[0] = 2/(maxLightX - minLightX)/numSplits;
			rawData[0] = 2/(maxLightX - minLightX);
			rawData[5] = 2/(maxLightY - minLightY);
			rawData[10]= 1/(maxLightZ - minLightZ);
//				rawData[12] = (-0.5 * (maxLightX + minLightX) * rawData[0]) + 2*i/numSplits - 1/numSplits;
			rawData[12] = (-0.5 * (maxLightX + minLightX) * rawData[0]);
			rawData[13] = (-0.5 * (maxLightY + minLightY) * rawData[5]);
			rawData[14]= -minLightZ/(maxLightZ - minLightZ);
			rawData[15]= 1;
			projectionMatrix.rawData = rawData;

			rawData[0] = 1/((maxLightX - minLightX));
			rawData[5] = -1/((maxLightY - minLightY));
//			rawData[12] = 0.5 - (0.5 * (maxLightX + minLightX) * rawData[0]) + i/numSplits - 0.5/numSplits;
			rawData[12] = 0.5 - (0.5 * (maxLightX + minLightX) * rawData[0]);
			rawData[13] = 0.5 - (0.5 * (maxLightY + minLightY) * rawData[5]);
			uvMatrix = new Matrix3D(rawData);

			lightMatrix.identity();
			lightMatrix.append(camera.globalMatrix);
			lightMatrix.append(cameraMatrix);
			lightMatrix.append(uvMatrix);

//			scissor.x = i * _width/numSplits;
//			scissor.width = _width/numSplits;
//			scissor.height = _height;
//			view.setScissor(scissor);
			if (shadow && root != this && root.visible && !root.isTransparent && root.useShadows) {
				root.composeMatrix();
				root.cameraMatrix.append(cameraMatrix);
				root.drawInShadowMap(camera, this);
			}
//			splitNear = splitFar;
			view.flush();
			if (shadow) {
				view.setRenderToBackbuffer();
			}
//			view.setScissor(null);
		}

		alternativa3d function attenuateVertexShader(v4:String, const4x4:uint):String {
			if (!shadow) {
				return "";
			}
			var shader:String = "dp4 " + v4 + ".x, va0, vc" + const4x4+ " \n" +
								"dp4 " + v4 + ".y, va0, vc" + (const4x4 + 1) + " \n" +
								"dp4 " + v4 + ".z, va0, vc" + (const4x4 + 2) + " \n" +
								"dp4 " + v4 + ".w, va0, vc" + (const4x4 + 3) + " \n";
			return shader;
		}

		alternativa3d function attenuateFragmentShader(result4:String, v4:String, texture:uint, const2:uint):String {
			if (!shadow) {
				return "mov " + result4 + ", fc" + const2 + ".zzzz \n";
			}
// Отображение шедоу мапы
//			var shader:String = "tex " + result4 + ", " + v4 + ", fs" + texture.toString() + " <2d,clamp,nearest> \n" +
//								"mov " + result4 + ", " + result4 + ".zzzz \n";

			var shader:String = "tex " + result4 + ", " + v4 + ", fs" + texture.toString() + " <2d,clamp,nearest> \n" +
								"add " + result4 + ".z, " + result4 + ".z, fc" + const2.toString() + ".x \n" + // Смещение
								"sub " + result4 + ".z, " + result4 + ".z, " + v4 + ".z \n" +
								"mul " + result4 + ".z, " + result4 + ".z, fc" + const2.toString() + ".y \n" +
								"sat " + result4 + ".z, " + result4 + ".z \n" +
								"mov " + result4 + ", " + result4 + ".zzzz \n";
			return shader; 
		}

		alternativa3d function attenuateProgramSetup(view:View, obj:Object3D, const4x4:uint, texture:uint, constF2:uint):void {
			if (!shadow) {
				view.setProgramConstants("FRAGMENT", constF2, 1, options);
			}
			var lightMatrix:Matrix3D = obj.cameraMatrix.clone();
			lightMatrix.append(this.lightMatrix);
			view.setTexture(texture, shadowMap);
			view.setProgramConstantsMatrixTransposed("VERTEX", const4x4, lightMatrix);
			view.setProgramConstants("FRAGMENT", constF2, 1, options);
		}

	}
}
