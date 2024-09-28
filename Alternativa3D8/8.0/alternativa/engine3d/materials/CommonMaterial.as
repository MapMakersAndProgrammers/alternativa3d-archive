package alternativa.engine3d.materials {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendMode;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexFormat;
	import flash.display3D.Program3D;
	import flash.display3D.Texture3D;
	import flash.display3D.TextureCube3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

	use namespace alternativa3d;
	public class CommonMaterial extends Material {

		/**
		 * URL диффузной карты.
		 * Это свойство нужно при загрузке текстур ипользуя класс <code>MaterialLoader</code>.
		 * @see alternativa.engine3d.materials.MaterialLoader
		 */
		public var diffuseMapURL:String;
		/**
		 * URL карты прозрачности.
		 * Это свойство нужно при загрузке текстур ипользуя класс <code>MaterialLoader</code>.
		 * @see alternativa.engine3d.materials.MaterialLoader
		 */
		public var opacityMapURL:String;
		/**
		 * URL карты нормалей.
		 */
		public var normalMapURL:String;
		/**
		 * URL карты самосвечения.
		 */
		public var emissionMapURL:String;
		/**
		 * URL карты блика.
		 */
		public var specularMapURL:String;
		
		public var repeat:Boolean = true;
		public var diffuse:BitmapData;
		public var opacity:BitmapData;
		public var normals:BitmapData;
		public var specular:BitmapData;
		public var emission:BitmapData;
		public var emissionChannel:uint = 0;
		public var shadows:Boolean = false;
		
		
		public var ambientCube:TextureCube3D;
		public var diffuse3D:Texture3D;
		public var opacity3D:Texture3D;
		public var normals3D:Texture3D;
		public var specular3D:Texture3D;
		public var emission3D:Texture3D;

		public var glossiness:Number = 50;
		public var useSpecularMap:Boolean = true;
		public var useTangents:Boolean = true;
		public var flipX:Boolean = false;
		public var flipY:Boolean = false;
		public var ambient:Number = 0;

		public function CommonMaterial() {
		}

		private function getMeshProgram(camera:Camera3D, context3d:Context3D, makeShadows:Boolean):Program3D {
			var key:String = "Cmesh" +
				((repeat) ? "R" : "r") +
				((useTangents) ? "T" : "t") +
				((opacity3D != null) ? "O" : "o") +
				((emission3D != null) ? "E" : "e") +
				((useSpecularMap && specular3D != null) ? "S" : "s") +
				((flipX) ? "X" : "x") +
				((flipY) ? "Y" : "y") +
				((emissionChannel > 0) ? "E" : "e") +
				((ambientCube != null) ? "A" : "a") +
				((makeShadows) ? "1" : "0");
			var program:Program3D = camera.context3dCachedPrograms[key];
			if (program == null) {
				program = initMeshProgram(camera, context3d, makeShadows);
				camera.context3dCachedPrograms[key] = program;
			}
			return program;
		}

		private function initMeshProgram(camera:Camera3D, context3d:Context3D, makeShadows:Boolean):Program3D {
			var shadowCaster:DirectionalLight;
			if (makeShadows) {
				shadowCaster = camera.shadowCaster;
			}
			/*
			 * va0 - vertex xyz in object space
			 * va1 - vertex uv
			 * [useTangents==true]: va2.xyz - vertex tangent
			 * [useTangents==true]: va2.w - vertex bitangent direction
			 * [useTangents==true]: va3 - vertex normal
			 * [emissionChannel>0] - va4 - emission uv
			 * vc0 - vc3 projection matrix
			 * vc4 - camera xyz in object space
			 * [useTangents==true]: vc5 - inverted light direction in object space
			 * [useTangents==true]: vc5.w - 1.0
			 * [ambientCube!=null] vc8 - vc11 - normal toWorld transform matrix
			 * [shadows] vc12 - vc15 - shadows
			 */
			var vertexShader:String = 
				meshProjectionShader("op") +
				"mov v0, va1 \n";
				if (useTangents) {
					vertexShader +=
					"mov vt2, va3 \n" +
					"crs vt0.xyz, vt2, va2 \n" +	// vt0 - biTangent
					"mov vt0.w, va2.w \n" +
					"sub vt1, vc4, va0 \n" +	// vt1 - view vector
					"dp3 v1.x, vt1, va2 \n" + 
					"dp3 v1.y, vt1, vt0 \n" + 
					"dp3 v1.z, vt1, va3 \n" + 
					"mov v1.w, vc5.w \n" +
					// calculate light in tangent space
					"dp3 v2.x, vc5, va2 \n" + 
					"dp3 v2.y, vc5, vt0 \n" + 
					"dp3 v2.z, vc5, va3 \n" +
					"mov v2.w, vc5.w \n";
				} else {
					vertexShader += 
					"sub v1, vc4, va0 \n";
				}
				if (emissionChannel > 0) {
					vertexShader +=
					"mov v4, va4 \n"; 
				}
				if (makeShadows) {
					vertexShader += shadowCaster.attenuateVertexShader("v3", 12);
				}
				if (ambientCube != null) {
					vertexShader +=
					"dp3 vt0.x, va3, vc8 \n" +		// vt0 - world normal
					"dp3 vt0.y, va3, vc9 \n" +
					"dp3 vt0.z, va3, vc10 \n" +
					"dp3 vt0.w, va3, vc11 \n" + 
					"neg vt0.y, vt0.y\n" + 
					"mov v5, vt0 \n";
				}
			/*
			 * v0 - uv
			 * v1 - view vector (unnormalized)
			 * [useTangents==true] v2 - inverted light direction (unnormalized)
			 * [makeShadows==true] v3 - shadows
			 * [emissionChannel>0] v4 - emission uv
			 * [ambientCube!=null] v5 - world normal
			 * fs0 - diffuse
			 * fs1 - normalmap
			 * fs2 - opacity
			 * fs3 - emission
			 * fs4 - specular
			 * [makeShadows==true] fs5 - shadow map
			 * [ambientCube!=null] fs6 - ambient cube map
			 * fc0.x - 0.5
			 * fc0.y - glossiness
			 * fc0.z - ambient
			 * fc0.w - 1.0
			 * [useTangents==false] fc1 - inverted light direction (normalized)
			 * [makeShadows==true] fc2 - shadow constant
			 * fc3 : light color
			 * ft0 - result
			 */
			var fragmentShader:String = 
				"tex ft0, v0, fs0 <2d, " + ((repeat) ? "repeat" : "clamp") + ", linear, miplinear> \n" +	// ft0 - diffuse
 				// normal
				"tex ft1, v0, fs1 <2d, " + ((repeat) ? "repeat" : "clamp") + ", linear, miplinear> \n" +
				"sub ft1, ft1, fc0.xxxx \n" +
				// x2
				"add ft1, ft1, ft1 \n";  // ft1 - normal
				if (flipX || flipY) {
					fragmentShader +=
					((flipX && flipY) ?
					"neg ft1.xy, ft1.xy \n"
					 : ((flipX) ? 
					 "neg ft1.x, ft1.x \n" : 
					 "neg ft1.y, ft1.y \n")); 
				}
				// diffuse lighting
				if (useTangents) {
					fragmentShader +=
					"nrm ft4.xyz, v2.xyz \n" +	// ft4 - inverted light (normalized)
					"mov ft4.w, fc0.w \n" +
					"dp3 ft2, ft1, ft4 \n";
				} else {
					fragmentShader +=
					"dp3 ft2, ft1, fc1 \n";
				}
				fragmentShader +=
				"sat ft2.x, ft2.x \n";		// ft2.x - diffuse lighting
				if (makeShadows) {
					fragmentShader += shadowCaster.attenuateFragmentShader("ft5", "v3", 5, 2) +		// ft5 - shadow
					"mul ft2.x, ft2.x, ft5.x \n";
				}
				if (ambient > 0) {
					fragmentShader +=
					"add ft2.x, ft2.x, fc0.z \n";
				}
				if (emission3D != null) {
					// emission
					fragmentShader += 
					"tex ft3, " + ((emissionChannel > 0) ? "v4" : "v0") + ", fs3 <2d, " + ((repeat) ? "repeat" : "clamp") + ", linear, miplinear> \n" +	// ft3 - emission color
					"add ft3, ft3, ft3 \n" +
					"add ft2.x, ft2.x, ft3.x \n";	// ft2.x - diffuse + emission lighting
				}
				fragmentShader += 
				"mul ft2, ft2.xxxx, fc3 \n";
				if (ambientCube != null) {
					fragmentShader +=
					"tex ft3, v5, fs6 <cube, linear, mipnone>\n" +	// ft3 - ambient cube map color
					"add ft2, ft2, ft3 \n" +
					"mul ft0.xyz, ft0.xyz, ft2.xyz \n";	// ft0 - diffuse*lighting
				} else {
					fragmentShader +=
					"mul ft0.xyz, ft0.xyz, ft2.xyz \n";	// ft0 - diffuse*lighting
				}
				fragmentShader +=
				// specular lighting 
				// level = pow(max(dot(halfWay, normal), 0), gloss)
				// 1. calc halfway vector
				"nrm ft2.xyz, v1.xyz \n";	// ft2 - halfWay vector
				if (useTangents) {
					fragmentShader +=
					"add ft2, ft2, ft4 \n";
				} else {
					fragmentShader +=
					"add ft2, ft2, fc1 \n";
				}
				fragmentShader +=   
				"nrm ft2.xyz, ft2.xyz \n" +
				// 2. dot(halfWay, normal)
				"dp3 ft2, ft2, ft1 \n" +
				"sat ft2.x, ft2.x \n" +
				"pow ft2.x, ft2.x, fc0.y \n";	// ft2.x - specular highlight
				
				
				// dot/(dot - dot*n + n) По Шлику замена pow
//				"mul ft2.z, ft2.x, fc0.y \n" +
//				"sub ft2.y, ft2.x, ft2.z \n" +
//				"add ft2.y, ft2.y, fc0.y \n" +
//				"div ft2.x, ft2.x, ft2.y \n";
				fragmentShader += 
				"mul ft2, ft2.x, fc3 \n";
				
				if (useSpecularMap && specular3D != null) {
					// specular level
					fragmentShader += 
					"tex ft1, v0, fs4 <2d, " + ((repeat) ? "repeat" : "clamp") + ", linear, miplinear> \n" +	// ft1 - specular level
					"mul ft2, ft2, ft1.x \n";	// ft2.x - specular highlight
				}
				if (makeShadows) {
					fragmentShader +=
					"mul ft2, ft2, ft5.x \n";
				}
				fragmentShader += 
				"add ft0.xyz, ft0.xyz, ft2.xxx \n";	// ft0.xyz - diffuse*lighting + specular
				if (opacity3D != null) {
					// alpha
					fragmentShader +=
					"tex ft1, v0, fs2 <2d, " + ((repeat) ? "repeat" : "clamp") + ", linear, miplinear> \n" +	// ft1 - opacity level
					"mov ft0.w, ft1.x \n";	// ft0.w - alpha
				}
				fragmentShader += 
				"mov oc, ft0";
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX, vertexShader, false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT, fragmentShader, false);
			var program:Program3D = context3d.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		override alternativa3d function drawMesh(mesh:Mesh, camera:Camera3D):void {
			if (diffuse3D == null || normals3D == null) {
				return;
			}
			var context3d:Context3D = camera.view._context3d;
			var makeShadows:Boolean = mesh.useShadows && camera.shadowCaster != null && camera.shadowCaster.currentSplitHaveShadow && shadows;
			context3d.setProgram(getMeshProgram(camera, context3d, makeShadows));
			if (opacity3D != null) {
				context3d.setBlending(Context3DBlendMode.SOURCE_ALPHA, Context3DBlendMode.ONE_MINUS_SOURCE_ALPHA);
				context3d.setDepthTest(false, Context3DCompareMode.LESS);
			}
			meshProjectionShaderSetup(context3d, mesh);
			// uv
			context3d.setVertexStream(1, mesh.geometry.vertexBuffer, 3, Context3DVertexFormat.FLOAT_2);
			if (useTangents) {
				// tangent
				context3d.setVertexStream(2, mesh.geometry.vertexBuffer, 5, Context3DVertexFormat.FLOAT_4);
				// normal
				context3d.setVertexStream(3, mesh.geometry.vertexBuffer, 9, Context3DVertexFormat.FLOAT_3);
			}
			if (emissionChannel > 0) {
				context3d.setVertexStream(4, mesh.geometry.additionalUVChannels, 0, Context3DVertexFormat.FLOAT_2); 
			}
			context3d.setProgramConstants(Context3DProgramType.FRAGMENT, 0, 1, Vector.<Number>([0.5, glossiness, ambient, 1]));
			var shadowCaster:DirectionalLight;
			if (makeShadows) {
				shadowCaster = camera.shadowCaster;
				shadowCaster.attenuateProgramSetup(context3d, mesh, 12, 5, 2);
			}
			if (camera.numDirectionalLights > 0) {
				var light:DirectionalLight = camera.directionalLights[0];
				var matrix:Matrix3D = mesh.cameraMatrix.clone();
				matrix.append(light.lightMatrix);
				matrix.invert();
				var direction:Vector3D = matrix.deltaTransformVector(Vector3D.Z_AXIS);
				direction.normalize();
				if (useTangents) {
					context3d.setProgramConstants(Context3DProgramType.VERTEX, 5, 1, Vector.<Number>([-direction.x, -direction.y, -direction.z, 1]));
//					context3d.setProgramConstants("VERTEX", 5, 1, Vector.<Number>([direction.x, direction.y, direction.z, 1]));
				} else {
					context3d.setProgramConstants(Context3DProgramType.FRAGMENT, 1, 1, Vector.<Number>([-direction.x, -direction.y, -direction.z, 1]));
//					context3d.setProgramConstants("FRAGMENT", 1, 1, Vector.<Number>([direction.x, direction.y, direction.z, 1]));
				}
				matrix.identity();
				matrix.append(mesh.cameraMatrix);
				matrix.invert();
				var coords:Vector3D = matrix.position;
				context3d.setProgramConstants(Context3DProgramType.VERTEX, 4, 1, Vector.<Number>([coords.x, coords.y, coords.z, 1]));
				context3d.setProgramConstants(Context3DProgramType.VERTEX, 6, 1, Vector.<Number>([0, 1, 0, 1]));
				context3d.setProgramConstants(Context3DProgramType.FRAGMENT, 3, 1, light.color);
			} else {
				context3d.setProgramConstants(Context3DProgramType.FRAGMENT, 1, 1, Vector.<Number>([0, 0, 1, 1]));
			}
			context3d.setTexture(0, diffuse3D);
			context3d.setTexture(1, normals3D);
			if (opacity3D != null) {
				context3d.setTexture(2, opacity3D);
			}
			if (emission3D != null) {
				context3d.setTexture(3, emission3D);
			}
			if (useSpecularMap && specular3D != null) {
				context3d.setTexture(4, specular3D);
			}
			if (ambientCube != null) {
				var toWorld:Matrix3D = mesh.cameraMatrix.clone();
				toWorld.append(camera.globalMatrix);
				toWorld.invert();
				context3d.setProgramConstantsMatrix(Context3DProgramType.VERTEX, 8, toWorld);
				context3d.setTexture(6, ambientCube);
			}
			context3d.setCulling(Context3DTriangleFace.FRONT);
			if (camera.debug) {
				context3d.drawTrianglesSynchronized(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			} else {
				context3d.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			}
			if (makeShadows) {
				shadowCaster.attenuateProgramClean(context3d, 5);
			}
			context3d.setVertexStream(1, null, 0, Context3DVertexFormat.DISABLED);
			if (useTangents) {
				// tangent
				context3d.setVertexStream(2, null, 0, Context3DVertexFormat.DISABLED);
				// normal
				context3d.setVertexStream(3, null, 0, Context3DVertexFormat.DISABLED);
			}
			if (emissionChannel > 0) {
				context3d.setVertexStream(4, null, 0, Context3DVertexFormat.DISABLED);
			}
			if (opacity3D != null) {
				context3d.setBlending(Context3DBlendMode.ONE, Context3DBlendMode.ZERO);
				context3d.setDepthTest(true, Context3DCompareMode.LESS);
			}
		}

//		override alternativa3d function update(context3d:Context3D):void {
//			if (diffuse3D == null && diffuse != null) {
//				diffuse3D = context3d.createTexture(diffuse.width, diffuse.height, Context3DTextureFormat.BGRA, false);
//				uploadTextureWithMipmaps(diffuse3D, diffuse);
//			}
//			if (opacity3D == null && opacity != null) {
//				opacity3D = context3d.createTexture(opacity.width, opacity.height, Context3DTextureFormat.BGRA, false);
//				uploadTextureWithMipmaps(opacity3D, opacity);
//			}
//			if (normals3D == null && normals != null) {
//				normals3D = context3d.createTexture(normals.width, normals.height, Context3DTextureFormat.BGRA, false);
//				uploadTextureWithMipmaps(normals3D, normals);
//			}
//			if (emission3D == null && emission != null) {
//				emission3D = context3d.createTexture(emission.width, emission.height, Context3DTextureFormat.BGRA, false);
//				uploadTextureWithMipmaps(emission3D, emission);
//			}
//			if (specular3D == null && useSpecularMap && specular != null) {
//				specular3D = context3d.createTexture(specular.width, specular.height, Context3DTextureFormat.BGRA, false);
//				uploadTextureWithMipmaps(specular3D, specular);
//			}
//		}
		
//		public function setDiffuse3D(value:Texture3D):void {
//			diffuse3D = value;
//		}
//		
//		public function setOpacity3D(value:Texture3D):void {
//			opacity3D = value;
//		}
//		
//		public function setNormals3D(value:Texture3D):void {
//			normals3D = value;
//		}
//		
//		public function setEmission3D(value:Texture3D):void {
//			emission3D = value;
//		}
//		
//		public function setSpecular3D(value:Texture3D):void {
//			specular3D = value;
//		}
		
		public static function uploadTextureWithMipmaps( dest:Texture3D, src:BitmapData ):void {		
			var ws:int = src.width;
			var hs:int = src.height;
			var level:int = 0;
			var tmp:BitmapData = new BitmapData( src.width, src.height );
			var transform:Matrix = new Matrix();

			while ( ws > 1 && hs > 1 ) {
				tmp.draw( src, transform, null, null, null, true );
				dest.upload( tmp, level );
				transform.scale( 0.5, 0.5 );
				level++;
				ws >>= 1;
				hs >>= 1;
			}
			tmp.dispose();
		}

		override alternativa3d function get isTransparent():Boolean {
			return opacity != null;
		}
		
	}
}
