package alternativa.engine3d.materials {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.Bitmap3D;
	import flash.display.BitmapData;
	import flash.display.Program3D;
	import flash.display.Texture3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

	use namespace alternativa3d;
	public class CommonMaterial extends Material {

		public var diffuse:BitmapData;
		public var opacity:BitmapData;
		public var normals:BitmapData;
		public var specular:BitmapData;
		public var emission:BitmapData;

		private var diffuse3D:Texture3D;
		private var opacity3D:Texture3D;
		private var normals3D:Texture3D;
		private var specular3D:Texture3D;
		private var emission3D:Texture3D;

		public var glossiness:Number = 1;
		public var useSpecularMap:Boolean = true;
		public var useTangents:Boolean = false;
		public var flipX:Boolean = false;
		public var flipY:Boolean = false;

		public function CommonMaterial() {
		}

		private function getMeshProgram(camera:Camera3D, view:View, makeShadows:Boolean):Program3D {
			var key:String = "Cmesh" +
				((useTangents) ? "T" : "t") +
				((opacity3D != null) ? "O" : "o") +
				((emission3D != null) ? "E" : "e") +
				((useSpecularMap && specular3D != null) ? "S" : "s") +
				((flipX) ? "X" : "x") +
				((flipY) ? "Y" : "y");
			var program:Program3D = view.cachedPrograms[key];
			if (program == null) {
				program = initMeshProgram(camera, view, makeShadows);
				view.cachedPrograms[key] = program;
			}
			return program;
		}

		private function initMeshProgram(camera:Camera3D, view:Bitmap3D, makeShadows:Boolean):Program3D {
			/*
			 * va0 - vertex xyz in object space
			 * va1 - vertex uv
			 * (useTangents==true): va2.xyz - vertex tangent
			 * (useTangents==true): va2.w - vertex bitangent direction
			 * (useTangents==true): va3 - vertex normal
			 * vc0 - vc3 projection matrix
			 * vc4 - camera xyz in object space
			 * (useTangents==true): vc5 - inverted light direction in object space
			 * (useTangents==true): vc5.w - 1.0
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
//				trace("VERTEX:\n", vertexShader);
			/*
			 * v0 - uv
			 * v1 - view vector (unnormalized)
			 * (useTangents==true) - v2 - inverted light direction (unnormalized)
			 * fs0 - diffuse
			 * fs1 - normalmap
			 * fs2 - opacity
			 * fs3 - emission
			 * fs4 - specular
			 * fc0.x - 0.5
			 * fc0.y - glossiness
			 * fc0.z - 1.0
			 * (useTangents==false) - fc1 - inverted light direction (normalized)
			 * ft0 - result
			 */
			var fragmentShader:String = 
				"tex ft0, v0, fs0 <2d, clamp, linear, miplinear> \n" +	// ft0 - diffuse
 				// normal
				"tex ft1, v0, fs1 <2d, clamp, linear, miplinear> \n" +
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
					"mov ft4.w, fc0.z \n" +
					"dp3 ft2, ft1, ft4 \n";
				} else {
					fragmentShader +=
					"dp3 ft2, ft1, fc1 \n";
				}
				fragmentShader +=
				"sat ft2.x, ft2.x \n";		// ft2.x - diffuse lighting
				if (emission3D != null) {
					// emission
					fragmentShader += 
					"tex ft3, v0, fs3 <2d, clamp, linear, miplinear> \n" +	// ft3 - emission color
					"add ft2.x, ft2.x, ft3.x \n";	// ft2.x - diffuse + emission lighting
				}
				fragmentShader +=
				"mul ft0.xyz, ft0.xyz, ft2.xxx \n" +	// ft0 - diffuse*lighting
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
				
				if (useSpecularMap && specular3D != null) {
					// specular level
					fragmentShader += 
					"tex ft1, v0, fs4 <2d, clamp, linear, miplinear> \n" +	// ft1 - specular level
					"mul ft2.x, ft2.x, ft1.x \n";	// ft2.x - specular highlight
				}
				fragmentShader += 
				"add ft0.xyz, ft0.xyz, ft2.xxx \n";	// ft0.xyz - diffuse*lighting + specular
				if (opacity3D != null) {
					// alpha
					fragmentShader +=
					"tex ft1, v0, fs2 <2d, clamp, linear, miplinear> \n" +	// ft1 - opacity level
					"mov ft0.w, ft1.x \n";	// ft0.w - alpha
				}
				fragmentShader += 
				"mov oc, ft0";
//			if (makeShadows) {
//				var light:DirectionalLight = camera.lights[0];
//				vertexShader += light.attenuateVertexShader("v1", 4);
//				fragmentShader += light.attenuateFragmentShader("ft1", "v1", 1, 0);
//				fragmentShader += "mul ft0, ft1, ft0 \n" +
//								  "mov oc, ft0";
//			} else {
//				fragmentShader += "mov oc, ft0";
//			}
//			trace("FRAGMENT:\n", fragmentShader);
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX", vertexShader, false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble("FRAGMENT", fragmentShader, false);
			var program:Program3D = view.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		override alternativa3d function drawMesh(mesh:Mesh, camera:Camera3D):void {
			if (diffuse3D == null || normals3D == null) {
				return;
			}
			var view:View = camera.view;
			var makeShadows:Boolean = mesh.useShadows && camera.numLights > 0;
			view.setProgram(getMeshProgram(camera, view, makeShadows));
			if (opacity3D != null) {
				view.setBlending("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA");
			}
			meshProjectionShaderSetup(view, mesh);
			// uv
			view.setVertexStream(1, mesh.geometry.vertexBuffer, 3, "FLOAT_2");
			if (useTangents) {
				// tangent
				view.setVertexStream(2, mesh.geometry.vertexBuffer, 5, "FLOAT_4");
				// normal
				view.setVertexStream(3, mesh.geometry.vertexBuffer, 9, "FLOAT_3");
			}
			view.setProgramConstants("FRAGMENT", 0, 1, Vector.<Number>([0.5, glossiness, 1.0, 1]));
			if (makeShadows) {
				var light:DirectionalLight = camera.lights[0];
//				light.attenuateProgramSetup(view, mesh, 4, 1, 0);
				var matrix:Matrix3D = mesh.cameraMatrix.clone();
				matrix.append(light.lightMatrix);
				matrix.invert();
				var direction:Vector3D = matrix.deltaTransformVector(Vector3D.Z_AXIS);
				direction.normalize();
				if (useTangents) {
					view.setProgramConstants("VERTEX", 5, 1, Vector.<Number>([-direction.x, -direction.y, -direction.z, 1]));
				} else {
					view.setProgramConstants("FRAGMENT", 1, 1, Vector.<Number>([-direction.x, -direction.y, -direction.z, 1]));
				}
				matrix.identity();
				matrix.append(mesh.cameraMatrix);
				matrix.invert();
				var coords:Vector3D = matrix.position;
				view.setProgramConstants("VERTEX", 4, 1, Vector.<Number>([coords.x, coords.y, coords.z, 1]));
				view.setProgramConstants("VERTEX", 6, 1, Vector.<Number>([0, 1, 0, 1]));
			} else {
				view.setProgramConstants("FRAGMENT", 1, 1, Vector.<Number>([0, 0, 1, 1]));
			}
			view.setTexture(0, diffuse3D);
			view.setTexture(1, normals3D);
			if (opacity3D != null) {
				view.setTexture(2, opacity3D);
			}
			if (emission3D != null) {
				view.setTexture(3, emission3D);
			}
			if (useSpecularMap && specular3D != null) {
				view.setTexture(4, specular3D);
			}
			view.setCulling("FRONT");
			if (camera.debug) {
				view.drawTrianglesSynchronized(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			} else {
				view.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			}
			view.setVertexStream(1, null, 0, "DISABLED");
			if (useTangents) {
				// tangent
				view.setVertexStream(2, null, 0, "DISABLED");
				// normal
				view.setVertexStream(3, null, 0, "DISABLED");
			}
			if (opacity3D != null) {
				view.setBlending("ONE", "ZERO");
			}
		}

		override alternativa3d function update(view:Bitmap3D):void {
			if (diffuse3D == null && diffuse != null) {
				diffuse3D = view.createTexture(diffuse.width, diffuse.height, "BGRA", false);
				uploadTextureWithMipmaps(diffuse3D, diffuse);
			}
			if (opacity3D == null && opacity != null) {
				opacity3D = view.createTexture(opacity.width, opacity.height, "BGRA", false);
				uploadTextureWithMipmaps(opacity3D, opacity);
			}
			if (normals3D == null && normals != null) {
				normals3D = view.createTexture(normals.width, normals.height, "BGRA", false);
				uploadTextureWithMipmaps(normals3D, normals);
			}
			if (emission3D == null && emission != null) {
				emission3D = view.createTexture(emission.width, emission.height, "BGRA", false);
				uploadTextureWithMipmaps(emission3D, emission);
			}
			if (specular3D == null && useSpecularMap && specular != null) {
				specular3D = view.createTexture(specular.width, specular.height, "BGRA", false);
				uploadTextureWithMipmaps(specular3D, specular);
			}
		}

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
