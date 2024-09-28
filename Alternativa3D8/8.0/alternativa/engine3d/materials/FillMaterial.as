package alternativa.engine3d.materials {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.objects.Joint; Joint;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.utils.ByteArray;
	import alternativa.engine3d.lights.DirectionalLight;
	import flash.geom.Matrix3D;
	import alternativa.engine3d.objects.Skin;
	import flash.display3D.Program3D;
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DBlendMode;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DTriangleFace;
	
	use namespace alternativa3d;
	
	/**
	 * Материал, заполняющий полигон сплошной одноцветной заливкой.
	 * Помимо заливки цветом, материал может рисовать границу полигона линией заданной толщины и цвета.
	 */
	public class FillMaterial extends Material {
	
		private var _color:int;
		private var _colorVector:Vector.<Number> = new Vector.<Number>(4);

//		/**
//		 * Толщина линий.
//		 * Линии отрисовываются только если толщина больше или равна <code>0</code>.
//		 * Значение по умолчанию <code>-1</code>.
//		 */
//		public var lineThickness:Number;
//		
//		/**
//		 * Цвет линий.
//		 * Линии отрисовываются только если толщина больше или равна <code>0</code>.
//		 * Значение по умолчанию <code>0xFFFFFF</code>.
//		 */
//		public var lineColor:int;
	
		/**
		 * Создаёт новый экземпляр.
		 * @param color Цвет заливки.
		 * @param alpha Альфа-прозрачность заливки
		 * @param lineThickness Толщина линий.
		 * @param lineColor Цвет линий.
		 */
		public function FillMaterial(color:int = 0x7F7F7F, alpha:Number = 1, lineThickness:Number = -1, lineColor:int = 0xFFFFFF) {
			_color = color;
			_colorVector[0] = ((color >> 16) & 0xFF)/255;
			_colorVector[1] = ((color >> 8) & 0xFF)/255;
			_colorVector[2] = (color & 0xFF)/255;
			_colorVector[3] = alpha;
//			this.lineThickness = lineThickness;
//			this.lineColor = lineColor;
		}

		private function getSkinProgram(camera:Camera3D, context3d:Context3D, numJoints:uint):Program3D {
			var key:String = "Fskin" + numJoints.toString() + ":" + camera.numDirectionalLights.toString();
			var program:Program3D = camera.context3dCachedPrograms[key];
			if (program == null) {
				program = initSkinProgram(camera, context3d, numJoints);
				camera.context3dCachedPrograms[key] = program;
			}
			return program;
		}

		private function initSkinProgram(camera:Camera3D, context3d:Context3D, numJoints:uint):Program3D {
			var vertexShader:String = skinProjectionShader(numJoints, "op", "vt0", "vt1");
			var fragmentShader:String;
//			if (camera.numLights > 0) {
//				var light:DirectionalLight = camera.lights[0];
//				vertexShader += light.attenuateVertexShader("v0", numJoints * 4);
//				fragmentShader = light.attenuateFragmentShader("ft0", "v0", 0, 1);
//				fragmentShader += "mul ft0, ft0, fc0 \n" +
//								  "mov oc, ft0";
//			} else {
				fragmentShader = "mov oc, fc0";
//			}
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX, vertexShader, false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT, fragmentShader, false);

			var program:Program3D = context3d.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		override alternativa3d function drawSkin(skin:Skin, camera:Camera3D, joints:Vector.<Joint>, numJoints:int, maxJoints:int, vertexBuffer:VertexBuffer3D, indexBuffer:IndexBuffer3D, numTriangles:int):void {
			if (numJoints < 1) return;
			var context3d:Context3D = camera.view._context3d;
			context3d.setProgram(getSkinProgram(camera, context3d, numJoints));
			if (_colorVector[3] < 1) {
				context3d.setBlending(Context3DBlendMode.SOURCE_ALPHA, Context3DBlendMode.ONE_MINUS_SOURCE_ALPHA);
				context3d.setDepthTest(false, Context3DCompareMode.LESS);
			} else {
				context3d.setBlending(Context3DBlendMode.ONE, Context3DBlendMode.ZERO);
			}
			skinProjectionShaderSetup(context3d, joints, numJoints, vertexBuffer);
//			if (camera.numLights > 0) {
//				var light:DirectionalLight = camera.lights[0];
//				var lightMatrix:Matrix3D = skin.cameraMatrix.clone();
//				lightMatrix.append(camera.globalMatrix);
//				lightMatrix.append(light.lightMatrix);
//				light.attenuateProgramSetup(context3d, lightMatrix, numJoints * 4, 0, 1);
//			}
			context3d.setProgramConstants(Context3DProgramType.FRAGMENT, 0, 1, _colorVector);
			context3d.setCulling(Context3DTriangleFace.FRONT);
			if (camera.debug) {
				context3d.drawTrianglesSynchronized(indexBuffer, 0, numTriangles);
			} else {
				context3d.drawTriangles(indexBuffer, 0, numTriangles);
			}
			skinProjectionShaderClean(context3d, numJoints);
			if (_colorVector[3] < 1) {
				context3d.setBlending(Context3DBlendMode.ONE, Context3DBlendMode.ZERO);
				context3d.setDepthTest(true, Context3DCompareMode.LESS);
			}
		}

		private function getMeshProgram(camera:Camera3D, context3d:Context3D, makeShadows:Boolean):Program3D {
			var key:String;
			if (makeShadows) {
				key = "Fmesh" + camera.shadowCaster.getKey();
			} else {
				key = "Fmesh";
			}
			var program:Program3D = camera.context3dCachedPrograms[key];
			if (program == null) {
				program = initMeshProgram(camera, context3d, makeShadows);
				camera.context3dCachedPrograms[key] = program;
			}
			return program;
		}

		private function initMeshProgram(camera:Camera3D, context3d:Context3D, makeShadows:Boolean):Program3D {
			var vertexShader:String = meshProjectionShader("op");
			var fragmentShader:String;
			if (makeShadows) {
				var shadowCaster:DirectionalLight = camera.shadowCaster;
				vertexShader += shadowCaster.attenuateVertexShader("v0", 4);
				fragmentShader = shadowCaster.attenuateFragmentShader("ft0", "v0", 0, 1);
				fragmentShader += "mul ft0, ft0, fc0 \n" +
								  "mov oc, ft0";
			} else {
				fragmentShader = "mov oc, fc0";
			}
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX, vertexShader, false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT, fragmentShader, false);
			var program:Program3D = context3d.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		/**
		 * Отрисовывает меш 
		 * @param view
		 * @param projection матрица для проецирования вершин
		 * @param vertexBuffer буффер данных вершин, в котором в диапазоне индексов 0 - 3 хранятся координаты вершин, а в индексах 3 - 5 uv координаты.
		 * @param indexBuffer буффер индексов треугольников
		 * @param numTriangles количество треугольников для отрисовки
		 */
		override alternativa3d function drawMesh(mesh:Mesh, camera:Camera3D):void {
			var context3d:Context3D = camera.view._context3d;
			var makeShadows:Boolean = mesh.useShadows && camera.shadowCaster != null && camera.shadowCaster.currentSplitHaveShadow;
			context3d.setProgram(getMeshProgram(camera, context3d, makeShadows));
			if (_colorVector[3] < 1) {
				context3d.setBlending(Context3DBlendMode.SOURCE_ALPHA, Context3DBlendMode.ONE_MINUS_SOURCE_ALPHA);
				context3d.setDepthTest(false, Context3DCompareMode.LESS);
			} else {
				context3d.setBlending(Context3DBlendMode.ONE, Context3DBlendMode.ZERO);
			}
			meshProjectionShaderSetup(context3d, mesh);
			var shadowCaster:DirectionalLight;
			if (makeShadows) {
				shadowCaster = camera.shadowCaster;
				shadowCaster.attenuateProgramSetup(context3d, mesh, 4, 0, 1);
			}
			context3d.setProgramConstants(Context3DProgramType.FRAGMENT, 0, 1, _colorVector);
			context3d.setCulling(Context3DTriangleFace.FRONT);
			if (camera.debug) {
				context3d.drawTrianglesSynchronized(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			} else {
				context3d.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			}
			if (makeShadows) {
				shadowCaster.attenuateProgramClean(context3d, 0);
			}
			if (_colorVector[3] < 1) {
				context3d.setBlending(Context3DBlendMode.ONE, Context3DBlendMode.ZERO);
				context3d.setDepthTest(true, Context3DCompareMode.LESS);
			}
		}

		/**
		 * Цвет заливки.
		 * Значение по умолчанию <code>0x7F7F7F</code>.
		 */
		public function get color():int {
			return _color;
		}

		/**
		 * @private
		 */
		public function set color(value:int):void {
			_color = value;
			_colorVector[0] = ((color >> 16) & 0xFF)/255;
			_colorVector[1] = ((color >> 8) & 0xFF)/255;
			_colorVector[2] = (color & 0xFF)/255;
		}

		/**
		 * Значение альфа-прозрачности.
		 * Допустимые значения находятся в диапазоне от <code>0</code> до <code>1</code>.
		 * Значение по умолчанию <code>1</code>.
		 */
		public function get alpha():Number {
			return _colorVector[3];
		}

		/**
		 * @private
		 */
		public function set alpha(value:Number):void {
			_colorVector[3] = value;
		}

		override alternativa3d function get isTransparent():Boolean {
			return _colorVector[3] < 1;
		}

	}
}
