package alternativa.engine3d.materials {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexFormat;
	import flash.display3D.Program3D;
	import flash.display3D.Texture3D;
	import flash.utils.ByteArray;

	use namespace alternativa3d;

	/**
	 * Рисует сетку 
	 */
	public class GridMaterial extends Material {

		private var tilesColor:uint;
		private var groutColor:uint;
		public var countWidth:Number;
		public var countHeight:Number;
		public var groutWidth:Number;

		private var tilesTexture:Texture3D;

		public function GridMaterial(tilesColor:uint = 0x0, groutColor:uint = 0xFFFFFF, countWidth:Number = 4, countHeight:Number = 4, groutWidth:Number = 0.1) {
//			this.tilesColor = Vector.<Number>([((tilesColor >>> 16) & 0xFF)/255, ((tilesColor >>> 8) & 0xFF)/255, (tilesColor & 0xFF)/255, 1]);
//			this.groutColor = Vector.<Number>([((groutColor >>> 16) & 0xFF)/255, ((groutColor >>> 8) & 0xFF)/255, (groutColor & 0xFF)/255, 1]);
			this.tilesColor = tilesColor;
			this.groutColor = groutColor;
			this.countWidth = countWidth;
			this.countHeight = countHeight;
			this.groutWidth = groutWidth;
		}

		alternativa3d function evaluateFragmentShaderSimple(result:String, uv:String, const0:uint, texture:uint):String {
			return evaluateFragmentShader(result, uv, const0, const0, const0, texture);
		}

		alternativa3d function evaluateFragmentShader(result:String, uv:String, const0:uint, const1:uint, const2:uint, texture:uint):String {
			return "" +
			// X 
			"mul " + result + ".x, " + uv + ".x, fc" + const0.toString() + ".x \n" +
			"frc " + result + ".x, " + result + ".x \n" +
			"add " + result + ".x, " + result + ".x, fc" + const0.toString() + ".y \n" +
			"mul " + result + ".x, " + result + ".x, fc" + const0.toString() + ".z \n" +
			// Y
			"mul " + result + ".y, " + uv + ".y, fc" + const1.toString() + ".x \n" +
			"frc " + result + ".y, " + result + ".y \n" +
			"add " + result + ".y, " + result + ".y, fc" + const1.toString() + ".y \n" +
			"mul " + result + ".y, " + result + ".y, fc" + const1.toString() + ".z \n" +
			"mov " + result + ".zw, fc" + const2.toString() + ".zw \n" +
			"tex " + result + ", " + result + ", fs" + texture.toString() + " <2d, clamp, nearest, mipnone> \n";
		}

		private static var tempVector:Vector.<Number> = Vector.<Number>([0, 0, 0, 1]);

		alternativa3d function evaluateProgramSetupSimple(context3d:Context3D, const0:uint, texture:uint):void {
			var gx:Number = groutWidth*countWidth;
			tempVector[0] = countWidth;
			tempVector[1] = 0.5 - gx; 
			tempVector[2] = 1/(2 - 2*gx);
			context3d.setProgramConstants(Context3DProgramType.FRAGMENT, const0, 1, tempVector);
			context3d.setTexture(texture, tilesTexture);
		}

		alternativa3d function evaluateProgramSetup(context3d:Context3D, const0:uint, const1:uint, const2:uint, texture:uint):void {
			var gx:Number = groutWidth*countWidth;
			var gy:Number = groutWidth*countHeight;
			tempVector[0] = countWidth;
			tempVector[1] = 0.5 - gx; 
			tempVector[2] = 1/(2 - 2*gx);
			context3d.setProgramConstants(Context3DProgramType.FRAGMENT, const0, 1, tempVector);
			tempVector[0] = countHeight;
			tempVector[1] = 0.5 - gy; 
			tempVector[2] = 1/(2 - 2*gy);
			context3d.setProgramConstants(Context3DProgramType.FRAGMENT, const1, 1, tempVector);
			tempVector[2] = 0;
			context3d.setProgramConstants(Context3DProgramType.FRAGMENT, const2, 1, tempVector);
			context3d.setTexture(texture, tilesTexture);
		}

		private function getMeshProgram(camera:Camera3D, context3d:Context3D, makeShadows:Boolean):Program3D {
			var key:String = "Gmesh";
			var program:Program3D = camera.context3dCachedPrograms[key];
			if (program == null) {
				program = initMeshProgram(camera, context3d, makeShadows);
				camera.context3dCachedPrograms[key] = program;
			}
			return program;
		}

		private function initMeshProgram(camera:Camera3D, context3d:Context3D, makeShadows:Boolean):Program3D {
			/*
			 * va0 : vertex coords
			 * va1 : uv coords
			 * vc0-vc3 : projection matrix
			 */
			var vertexShader:String =
				"dp4 op.x, va0, vc0 \n" +
				"dp4 op.y, va0, vc1 \n" +
				"dp4 op.z, va0, vc2 \n" +
				"dp4 op.w, va0, vc3 \n" +
				"mov v0, va1 \n";
			/*
			 * v0 - uv coords
			 * fc0 : diffuse color
			 * fc1.x : count width
			 * fc1.y : x offset
			 * fc1.z : x mult
			 * fc2.x : count height
			 * fc2.y : y offset
			 * fc2.z : y mult
			 * fs0 : tile texture
			 */
			var fragmentShader:String;
			fragmentShader = evaluateFragmentShader("ft0", "v0", 0, 1, 2, 0);
			if (makeShadows) {
//				var light:DirectionalLight = camera.lights[0];
//				vertexShader += light.attenuateVertexShader("v1", 4);
//				fragmentShader += light.attenuateFragmentShader("ft1", "v1", 1, 0);
//				fragmentShader += "mul ft0, ft1, ft0 \n" +
//								  "mov oc, ft0";
				fragmentShader += "mov oc, ft0"
			} else {
				fragmentShader += "mov oc, ft0";
			}
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX, vertexShader, false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT, fragmentShader, false);
			var program:Program3D = context3d.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		/**
		 * Отрисовывает меш 
		 * @param projection матрица для проецирования вершин
		 * @param vertexBuffer буффер данных вершин, в котором в диапазоне индексов 0 - 3 хранятся координаты вершин, а в индексах 3 - 5 uv координаты.
		 * @param indexBuffer буффер индексов треугольников
		 * @param numTriangles количество треугольников для отрисовки
		 */
		override alternativa3d function drawMesh(mesh:Mesh, camera:Camera3D):void {
			var context3d:Context3D = camera.context3d;
			var makeShadows:Boolean = mesh.useShadows && camera.numDirectionalLights > 0;
			context3d.setProgram(getMeshProgram(camera, context3d, makeShadows));

			context3d.setVertexStream(0, mesh.geometry.vertexBuffer, 0, Context3DVertexFormat.FLOAT_3);
			context3d.setVertexStream(1, mesh.geometry.vertexBuffer, 3, Context3DVertexFormat.FLOAT_2);
			context3d.setProgramConstantsMatrix(Context3DProgramType.VERTEX, 0, mesh.projectionMatrix, true);

//			if (makeShadows) {
//				var light:DirectionalLight = camera.lights[0];
//				light.attenuateProgramSetup(view, mesh, 4, 1, 0);
//			}
			evaluateProgramSetup(context3d, 0, 1, 2, 0);
			context3d.setCulling(Context3DTriangleFace.NONE);
			if (camera.debug) {
				context3d.drawTrianglesSynchronized(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			} else {
				context3d.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			}
//			if (makeShadows) {
//				light.clean
//			}
			context3d.setVertexStream(1, null, 0, Context3DVertexFormat.DISABLED);
		}

		override alternativa3d function update(context3d:Context3D):void {
			if (tilesTexture == null) {
				tilesTexture = context3d.createTexture(4, 4, Context3DTextureFormat.BGRA, false);
				var txt:BitmapData = new BitmapData(4, 4, false, groutColor);
				txt.setPixel(1, 1, tilesColor);
				txt.setPixel(1, 2, tilesColor);
				txt.setPixel(2, 1, tilesColor);
				txt.setPixel(2, 2, tilesColor);
				tilesTexture.upload(txt);
			}
		}

		override alternativa3d function get isTransparent():Boolean {
			return false;
		}

	}
}
