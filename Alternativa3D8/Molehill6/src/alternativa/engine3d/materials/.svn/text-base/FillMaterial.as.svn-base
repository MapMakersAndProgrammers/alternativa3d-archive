package alternativa.engine3d.materials {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.objects.Joint; Joint;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.Bitmap3D;
	import flash.display.IndexBuffer3D;
	import flash.display.Program3D;
	import flash.display.VertexBuffer3D;
	import flash.utils.ByteArray;
	import alternativa.engine3d.lights.DirectionalLight;
	import flash.geom.Matrix3D;
	import alternativa.engine3d.objects.Skin;
	
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

		private function getSkinProgram(camera:Camera3D, view:View, numJoints:uint):Program3D {
			var key:String = "Fskin" + numJoints.toString() + ":" + camera.numDirectionalLights.toString();
			var program:Program3D = view.cachedPrograms[key];
			if (program == null) {
				program = initSkinProgram(camera, view, numJoints);
				view.cachedPrograms[key] = program;
			}
			return program;
		}

		private function initSkinProgram(camera:Camera3D, view:Bitmap3D, numJoints:uint):Program3D {
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
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX", vertexShader, false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble("FRAGMENT", fragmentShader, false);

			var program:Program3D = view.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		override alternativa3d function drawSkin(skin:Skin, camera:Camera3D, joints:Vector.<Joint>, numJoints:uint, vertexBuffer:VertexBuffer3D, indexBuffer:IndexBuffer3D, numTriangles:int):void {
			if (numJoints < 1) return;
			var view:View = camera.view;
			view.setProgram(getSkinProgram(camera, view, numJoints));
			if (_colorVector[3] < 1) {
				view.setBlending("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA");
				view.setDepthTest(false, "LESS");
			} else {
				view.setBlending("ONE", "ZERO");
			}
			skinProjectionShaderSetup(view, joints, numJoints, vertexBuffer);
//			if (camera.numLights > 0) {
//				var light:DirectionalLight = camera.lights[0];
//				var lightMatrix:Matrix3D = skin.cameraMatrix.clone();
//				lightMatrix.append(camera.globalMatrix);
//				lightMatrix.append(light.lightMatrix);
//				light.attenuateProgramSetup(view, lightMatrix, numJoints * 4, 0, 1);
//			}
			view.setProgramConstants("FRAGMENT", 0, 1, _colorVector);
			view.setCulling("FRONT");
			if (camera.debug) {
				view.drawTrianglesSynchronized(indexBuffer, 0, numTriangles);
			} else {
				view.drawTriangles(indexBuffer, 0, numTriangles);
			}
			skinProjectionShaderClean(view, numJoints);
			if (_colorVector[3] < 1) {
				view.setBlending("ONE", "ZERO");
				view.setDepthTest(true, "LESS");
			}
		}

		private function getMeshProgram(camera:Camera3D, view:View, makeShadows:Boolean):Program3D {
			var key:String;
			if (makeShadows) {
				key = "Fmesh" + camera.shadowCaster.getKey();
			} else {
				key = "Fmesh";
			}
			var program:Program3D = view.cachedPrograms[key];
			if (program == null) {
				program = initMeshProgram(camera, view, makeShadows);
				view.cachedPrograms[key] = program;
			}
			return program;
		}

		private function initMeshProgram(camera:Camera3D, view:Bitmap3D, makeShadows:Boolean):Program3D {
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
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX", vertexShader, false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble("FRAGMENT", fragmentShader, false);
			var program:Program3D = view.createProgram();
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
			var view:View = camera.view;
			var makeShadows:Boolean = mesh.useShadows && camera.shadowCaster != null && camera.shadowCaster.currentSplitHaveShadow;
			view.setProgram(getMeshProgram(camera, view, makeShadows));
			if (_colorVector[3] < 1) {
				view.setBlending("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA");
				view.setDepthTest(false, "LESS");
			} else {
				view.setBlending("ONE", "ZERO");
			}
			meshProjectionShaderSetup(view, mesh);
			var shadowCaster:DirectionalLight;
			if (makeShadows) {
				shadowCaster = camera.shadowCaster;
				shadowCaster.attenuateProgramSetup(view, mesh, 4, 0, 1);
			}
			view.setProgramConstants("FRAGMENT", 0, 1, _colorVector);
			view.setCulling("FRONT");
			if (camera.debug) {
				view.drawTrianglesSynchronized(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			} else {
				view.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			}
			if (makeShadows) {
				shadowCaster.attenuateProgramClean(view, 0);
			}
			if (_colorVector[3] < 1) {
				view.setBlending("ONE", "ZERO");
				view.setDepthTest(true, "LESS");
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
