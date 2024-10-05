package alternativa.engine3d.materials {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.objects.Joint; Joint;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.Bitmap3D;
	import flash.display.BitmapData;
	import flash.display.IndexBuffer3D;
	import flash.display.Program3D;
	import flash.display.Texture3D;
	import flash.display.VertexBuffer3D;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.lights.DirectionalLight;

	use namespace alternativa3d;

	public class TextureMaterial extends Material {
		
		static private const filter:ConvolutionFilter = new ConvolutionFilter(2, 2, [1, 1, 1, 1], 4, 0, false, true);
		static private const matrix:Matrix = new Matrix(0.5, 0, 0, 0.5);
		static private const rect:Rectangle = new Rectangle();
		static private const point:Point = new Point();
		
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
		 * Флаг повторения текстуры при отрисовке.
		 */
		public var repeat:Boolean = false;
		
		/**
		 * Флаг сглаживания текстуры при отрисовке.
		 */
		public var smooth:Boolean = true;
		
		/**
		 * @private 
		 */
		alternativa3d var _texture:BitmapData;
		
		/**
		 * @private 
		 */
		alternativa3d var texture3d:Texture3D;
		
		/**
		 * Создаёт новый экземпляр.
		 * @param texture Текстура.
		 * @param repeat Флаг повторения текстуры.
		 * @param smooth Флаг сглаживания текстуры.
		 */
		public function TextureMaterial(texture:BitmapData = null, repeat:Boolean = false, smooth:Boolean = true) {
			_texture = texture;
			this.repeat = repeat;
			this.smooth = smooth;
		}

		private function getSkinProgram(view:View, numJoints:uint):Program3D {
			var key:String = "Tskin" + ((repeat) ? "R" : "r") + ((smooth) ? "S" : "s") + numJoints.toString();
			var program:Program3D = view.cachedPrograms[key];
			if (program == null) {
				program = initSkinProgram(view, numJoints);
				view.cachedPrograms[key] = program;
			}
			return program;
		}

		private function getMeshProgram(camera:Camera3D, view:View):Program3D {
			var key:String = "Tmesh" + ((repeat) ? "R" : "r") + ((smooth) ? "S" : "s");
			var program:Program3D = view.cachedPrograms[key];
			if (program == null) {
				program = initMeshProgram(camera, view);
				view.cachedPrograms[key] = program;
			}
			return program;
		}

		private function initMeshProgram(camera:Camera3D, view:Bitmap3D):Program3D {
			var vertexShader:String = meshProjectionShader("op") +
								"mov v0, va1 \n";
			var fragmentShader:String = "tex ft0, v0, fs0 <2d," + ((repeat) ? "repeat" : "clamp") + "," + ((smooth) ? "linear" : "nearest") + ",miplinear> \n"; 

			if (camera.numLights > 0) {
				var light:DirectionalLight = camera.lights[0];
				vertexShader += light.attenuateVertexShader("v1", 4);
				fragmentShader += light.attenuateFragmentShader("ft1", "v1", 1, 0);
				fragmentShader += "mul ft0, ft1, ft0 \n" +
								  "mov oc, ft0";
			} else {
				fragmentShader += "mov oc, ft0";
			}
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX", vertexShader, false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble("FRAGMENT", fragmentShader, false);
			var program:Program3D = view.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		private function initSkinProgram(view:Bitmap3D, numJoints:uint):Program3D {
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX",
				skinProjectionShader(numJoints, "op", "vt0", "vt1") +
				"mov v0, va1" , false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble("FRAGMENT",
				"tex ft0, v0, fs0 <2d," + ((repeat) ? "repeat" : "clamp") + "," + ((smooth) ? "linear" : "nearest") + ",miplinear> \n" + 
				"mov oc, ft0", false);
			var program:Program3D = view.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		override alternativa3d function drawSkin(camera:Camera3D, joints:Vector.<Joint>, numJoints:uint, skin:Skin):void {
			if (texture3d == null || numJoints < 1) return;
			
			var view:View = camera.view;
			view.setProgram(getSkinProgram(view, numJoints));
			if (_texture.transparent) {
				view.setBlending("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA");
			} else {
				view.setBlending("ONE", "ZERO");
			}
			skinProjectionShaderSetup(view, joints, numJoints, skin.geometry.vertexBuffer);
			view.setVertexStream(1, skin.geometry.vertexBuffer, 3, "FLOAT_2");
			view.setTexture(0, texture3d);
			view.setCulling("FRONT");
			if (camera.debug) {
				view.drawTrianglesSynchronized(skin.geometry.indexBuffer, 0, skin.geometry.numTriangles);
			} else {
				view.drawTriangles(skin.geometry.indexBuffer, 0, skin.geometry.numTriangles);
			}
			skinProjectionShaderClean(view, numJoints);
			view.setVertexStream(1, null, 0, "DISABLED");
			if (_texture.transparent) {
				view.setBlending("ONE", "ZERO");
			}
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
			if (texture3d == null) return;

			var view:View = camera.view;
			view.setProgram(getMeshProgram(camera, view));
			if (_texture.transparent) {
				view.setBlending("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA");
			} else {
				view.setBlending("ONE", "ZERO");
			}
			meshProjectionShaderSetup(view, mesh);
			view.setVertexStream(1, mesh.geometry.vertexBuffer, 3, "FLOAT_2");
			if (camera.numLights > 0) {
				var light:DirectionalLight = camera.lights[0];
				light.attenuateProgramSetup(view, mesh, 4, 1, 0);
			}
			view.setTexture(0, texture3d);
			view.setCulling("FRONT");
			if (camera.debug) {
				view.drawTrianglesSynchronized(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			} else {
				view.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			}
			view.setVertexStream(1, null, 0, "DISABLED");
			if (_texture.transparent) {
				view.setBlending("ONE", "ZERO");
			}
		}

		override alternativa3d function update(view:Bitmap3D):void {
			if (texture3d != null) return;
			if (_texture != null) {
				var level:int = 0;
				texture3d = view.createTexture(_texture.width, _texture.height, "BGRA", false);
				texture3d.upload(_texture, level++);
				filter.preserveAlpha = !_texture.transparent;
				var bmp:BitmapData = (_texture.width*_texture.height > 16777215) ? _texture.clone() : new BitmapData(_texture.width, _texture.height, _texture.transparent);
				var current:BitmapData = _texture;
				rect.width = _texture.width;
				rect.height = _texture.height;
				while (rect.width % 2 == 0 && rect.height % 2 == 0) {
					bmp.applyFilter(current, rect, point, filter);
					rect.width >>= 1;
					rect.height >>= 1;
					current = new BitmapData(rect.width, rect.height, _texture.transparent, 0);
					current.draw(bmp, matrix, null, null, null, false);
					texture3d.upload(current, level++);
				}
				bmp.dispose();
			}
		}

		override alternativa3d function reset():void {
			texture3d = null;
		}
		
		/**
		 * Ткстура материала.
		 */
		public function get texture():BitmapData {
			return _texture;
		}
		
		/**
		 * @private
		 */
		public function set texture(value:BitmapData):void {
			//if (value.width % 2 > 0 || value.height % 2 > 0
			_texture = value;
			reset();
		}

		override alternativa3d function get isTransparent():Boolean {
			return (_texture != null) ? _texture.transparent : false;
		}

	}
}
