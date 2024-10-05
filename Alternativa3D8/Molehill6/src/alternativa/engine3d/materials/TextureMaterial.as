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
		
		public var useMipmapping:Boolean = true;
		
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

		private function getMeshProgram(camera:Camera3D, view:View, makeShadows:Boolean):Program3D {
			var key:String = "Tmesh" +
				((useMipmapping) ? "M" : "m") + 
				((repeat) ? "R" : "r") +
				((smooth) ? "S" : "s") + 
				((makeShadows) ? "1" : "0");
			var program:Program3D = view.cachedPrograms[key];
			if (program == null) {
				program = initMeshProgram(camera, view, makeShadows);
				view.cachedPrograms[key] = program;
			}
			return program;
		}

		private function initMeshProgram(camera:Camera3D, view:Bitmap3D, makeShadows:Boolean):Program3D {
			var vertexShader:String = meshProjectionShader("op") +
								"mov v0, va1 \n";
			var fragmentShader:String = "tex ft0, v0, fs0 <2d," + ((repeat) ? "repeat" : "clamp") + "," + ((smooth) ? "linear" : "nearest") + "," + ((useMipmapping) ? "miplinear" : "mipnone") + "> \n"; 

			if (makeShadows) {
				var shadowCaster:DirectionalLight = camera.shadowCaster;
				vertexShader += shadowCaster.attenuateVertexShader("v1", 4);
				fragmentShader += shadowCaster.attenuateFragmentShader("ft1", "v1", 1, 0);
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

		override alternativa3d function drawSkin(skin:Skin, camera:Camera3D, joints:Vector.<Joint>, numJoints:uint, vertexBuffer:VertexBuffer3D, indexBuffer:IndexBuffer3D, numTriangles:int):void {
			if (texture3d == null || numJoints < 1) return;
			
			var view:View = camera.view;
			view.setProgram(getSkinProgram(view, numJoints));
			if (_texture.transparent) {
				view.setBlending("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA");
				view.setDepthTest(false, "LESS");
			} else {
				view.setBlending("ONE", "ZERO");
			}
			skinProjectionShaderSetup(view, joints, numJoints, vertexBuffer);
			view.setVertexStream(1, vertexBuffer, 3, "FLOAT_2");
			view.setTexture(0, texture3d);
			view.setCulling("FRONT");
			if (camera.debug) {
				view.drawTrianglesSynchronized(indexBuffer, 0, numTriangles);
			} else {
				view.drawTriangles(indexBuffer, 0, numTriangles);
			}
			skinProjectionShaderClean(view, numJoints);
			view.setVertexStream(1, null, 0, "DISABLED");
			if (_texture.transparent) {
				view.setBlending("ONE", "ZERO");
				view.setDepthTest(true, "LESS");
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
			var makeShadows:Boolean = mesh.useShadows && camera.shadowCaster != null && camera.shadowCaster.currentSplitHaveShadow;
			if (_texture.transparent) {
				view.setBlending("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA");
				view.setDepthTest(false, "LESS");
			} else {
				view.setBlending("ONE", "ZERO");
			}
			
			var shadowCaster:DirectionalLight;
			if (mesh.omniesLength == 0) {
				view.setProgram(getMeshProgram(camera, view, makeShadows));
				meshProjectionShaderSetup(view, mesh);
				view.setVertexStream(1, mesh.geometry.vertexBuffer, 3, "FLOAT_2");
				if (makeShadows) {
					shadowCaster = camera.shadowCaster;
					shadowCaster.attenuateProgramSetup(view, mesh, 4, 1, 0);
				}
			} else {
				view.setVertexStream(0, mesh.geometry.vertexBuffer, 0, "FLOAT_3");
				view.setVertexStream(1, mesh.geometry.vertexBuffer, 3, "FLOAT_2");
				view.setVertexStream(2, mesh.geometry.vertexBuffer, 5, "FLOAT_3");
				
				view.setProgramConstantsMatrixTransposed("VERTEX", 0, mesh.projectionMatrix);
				view.setProgramConstants("VERTEX", 4, 1, Vector.<Number>([0, 0, 0, 1]));
				view.setProgramConstants("VERTEX", 5, mesh.omniesLength/4, mesh.omnies);
				
				//var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX",
				var res:String = 
					"dp4 op.x, va0, vc0 \n" +
					"dp4 op.y, va0, vc1 \n" +
					"dp4 op.z, va0, vc2 \n" +
					"dp4 op.w, va0, vc3 \n" +
					
					// Нулевой вектор
					"mov vt3, vc4.x \n";
					
					for (var i:int = 0; i < mesh.omniesLength/8; i++) {
						res +=
						// Вектор от вершины к омнику
						"sub vt0, vc" + int(5 + 2*i) + ", va0 \n" +
						// Обратная длина вектора
						"dp3 vt1.x, vt0, vt0 \n" +
						"rsq vt1.x, vt1.x \n" +
						// Длина вектора
						"div vt2.x, vc4.w, vt1.x \n" +
						// Нормализация
						"mul vt1, vt0, vt1.x \n" +
						// Угол
						"dp3 vt1.x, va2, vt1 \n" +
						"sat vt1.x, vt1.x \n" +
						// Расстояние
						"mul vt2.x, vt2.x, vc" + int(5 + 2*i) + ".w \n" +
						"sub vt2.x, vc4.w, vt2.x \n" +
						"sat vt2.x, vt2.x \n" +
						"mul vt1.x, vt1.x, vt2.x \n" +
						// Цвет
						"mul vt1.xyz, vc" + int(6 + 2*i) + ".xyz, vt1.x \n" +
						// Сила
						"mul vt1.xyz, vc" + int(6 + 2*i) + ".w, vt1.xyz \n" +
						// Добавление
						"add vt3.xyz, vt3.xyz, vt1.xyz \n"
					}
					
					res +=
					
					// Умножение на 2 как в лайтмапе
					"add vt3.xyz, vt3.xyz, vt3.xyz \n" +
					
					"mov v1, vt3 \n" +
					"mov v0, va1";
					
				var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX", res, false);
				
				var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble("FRAGMENT",
					"tex ft0, v0, fs0 <2d,clamp,linear,miplinear> \n" +
					"mul ft0.xyz, ft0.xyz, v1.xyz \n" +
					"mov oc, ft0", false);
					
				var program:Program3D = view.createProgram();
				program.upload(vertexProgram, fragmentProgram);
				view.setProgram(program);
			}
			
			view.setTexture(0, texture3d);
			view.setCulling("FRONT");
			if (camera.debug) {
				view.drawTrianglesSynchronized(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			} else {
				view.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			}
			if (makeShadows) {
				shadowCaster.attenuateProgramClean(view, 1);
			}
			view.setVertexStream(1, null, 0, "DISABLED");
			if (_texture.transparent) {
				view.setBlending("ONE", "ZERO");
				view.setDepthTest(true, "LESS");
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
