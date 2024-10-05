package alternativa.engine3d.materials {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.materials.AGALMiniAssembler;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendMode;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexFormat;
	import flash.display3D.Program3D;
	import flash.display3D.Texture3D;
	import flash.utils.ByteArray;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.IndexBuffer3D;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.objects.Joint;
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;
	
	public class SkinMaterial extends Material {
		
		static private var programs:Object = new Object();
		
		public var transparent:Boolean;
		
		private var diffuse3D:Texture3D;
		private var normal3D:Texture3D;
		private var specular3D:Texture3D;
		
		public function SkinMaterial(diffuse3D:Texture3D, normal3D:Texture3D, specular3D:Texture3D, transparent:Boolean) {
			this.diffuse3D = diffuse3D;
			this.normal3D = normal3D;
			this.specular3D = specular3D;
			this.transparent = transparent;
		}
		
		override alternativa3d function get isTransparent():Boolean {
			return transparent;
		}
		
		override alternativa3d function drawSkin(skin:Skin, camera:Camera3D, joints:Vector.<Joint>, numJoints:int, maxJoints:int, vertexBuffer:VertexBuffer3D, indexBuffer:IndexBuffer3D, numTriangles:int):void {
			var context3d:Context3D = camera.view.context3d;
			if (transparent) {
				context3d.setBlending(Context3DBlendMode.SOURCE_ALPHA, Context3DBlendMode.ONE_MINUS_SOURCE_ALPHA);
				context3d.setDepthTest(false, Context3DCompareMode.LESS);
			} else {
				context3d.setBlending(Context3DBlendMode.ONE, Context3DBlendMode.ZERO);
			}
			
			//trace(maxJoints);
			var numOmnies:int = skin.omniesLength/8;
			var key:String = numJoints + "_" + maxJoints + "_" + numOmnies;
			var program:Program3D = programs[key];
			if (program == null) {
				program = initProgram(context3d, numJoints, maxJoints, numOmnies);
				programs[key] = program;
			}
			context3d.setProgram(program);
			
			var i:int;
			// Вершины
			context3d.setVertexStream(0, vertexBuffer, 0, Context3DVertexFormat.FLOAT_3);
			// UV
			context3d.setVertexStream(1, vertexBuffer, 3, Context3DVertexFormat.FLOAT_2);
			// Нормали
			context3d.setVertexStream(2, vertexBuffer, 5, Context3DVertexFormat.FLOAT_3);
			// Тангенты
			context3d.setVertexStream(3, vertexBuffer, 8, Context3DVertexFormat.FLOAT_4);
			// Индексы и веса
			for (i = 0; i < Math.floor(maxJoints/2); i++) {
				context3d.setVertexStream(4 + i, vertexBuffer, 12 + i*4, Context3DVertexFormat.FLOAT_4);
			}
			// Джоинты
			for (i = 0; i < numJoints; i++) {
				var joint:Joint = joints[i];
				context3d.setProgramConstantsMatrix(Context3DProgramType.VERTEX, i*4, joint.localMatrix, true);
			}
			context3d.setProgramConstantsMatrix(Context3DProgramType.VERTEX, numJoints*4, skin.projectionMatrix, true);
			// Источники света
			context3d.setProgramConstants(Context3DProgramType.FRAGMENT, 0, 1, Vector.<Number>([0, 0, 0.5, 1]));
			context3d.setProgramConstants(Context3DProgramType.FRAGMENT, 1, numOmnies*2, skin.omnies);
			// Текстуры
			context3d.setTexture(0, diffuse3D);
			context3d.setTexture(1, normal3D);
			context3d.setTexture(2, specular3D);
			context3d.setCulling(Context3DTriangleFace.FRONT);
			if (camera.debug) {
				context3d.drawTrianglesSynchronized(indexBuffer, 0, numTriangles);
			} else {
				context3d.drawTriangles(indexBuffer, 0, numTriangles);
			}
			
			context3d.setVertexStream(1, null, 0, Context3DVertexFormat.DISABLED);
			context3d.setVertexStream(2, null, 0, Context3DVertexFormat.DISABLED);
			context3d.setVertexStream(3, null, 0, Context3DVertexFormat.DISABLED);
			for (i = 0; i < Math.floor(maxJoints/2); i++) {
				context3d.setVertexStream(4 + i, null, 0, Context3DVertexFormat.DISABLED);
			}
			
			if (transparent) {
				context3d.setBlending(Context3DBlendMode.ONE, Context3DBlendMode.ZERO);
				context3d.setDepthTest(true, Context3DCompareMode.LESS);
			}
		}
		
		private function initProgram(context3d:Context3D, numJoints:int, maxJoints:int, numOmnies:int):Program3D {
			var i:int;
			var index:int;
			
			var vshader:String = "";
				 
				// Вершина
				vshader += "m44 vt1, va0, vc[va4.x] \n"
				vshader += "mul vt1, vt1, va4.y \n"
				vshader += "m44 vt0, va0, vc[va4.z] \n"
				vshader += "mul vt0, vt0, va4.w \n";
				vshader += "add vt1, vt1, vt0 \n";
				// Нормаль
				vshader += "m33 vt2.xyz, va2.xyz, vc[va4.x] \n"
				vshader += "mul vt2.xyz, vt2.xyz, va4.y \n"
				vshader += "m33 vt0.xyz, va2.xyz, vc[va4.z] \n"
				vshader += "mul vt0.xyz, vt0.xyz, va4.w \n";
				vshader += "add vt2.xyz, vt2.xyz, vt0.xyz \n";
				vshader += "mov vt2.w, va2.w \n"
				// Тангент 
				vshader += "m33 vt3.xyz, va3.xyz, vc[va4.x] \n"
				vshader += "mul vt3.xyz, vt3.xyz, va4.y \n"
				vshader += "m33 vt0.xyz, va3.xyz, vc[va4.z] \n"
				vshader += "mul vt0.xyz, vt0.xyz, va4.w \n";
				vshader += "add vt3.xyz, vt3.xyz, vt0.xyz \n";
				vshader += "mov vt3.w, va3.w \n"
			
			for (i = 1; i < Math.floor(maxJoints/2); i++) {
				index = i + 4;
				// Вершина
				vshader += "m44 vt0, va0, vc[va" + index + ".x] \n"
				vshader += "mul vt0, vt0, va" + index + ".y \n";
				vshader += "add vt1, vt1, vt0 \n";
				vshader += "m44 vt0, va0, vc[va" + index + ".z] \n"
				vshader += "mul vt0, vt0, va" + index + ".w \n";
				vshader += "add vt1, vt1, vt0 \n";
				// Нормаль
				vshader += "m33 vt0.xyz, va2.xyz, vc[va" +index + ".x] \n"
				vshader += "mul vt0.xyz, vt0.xyz, va" + index + ".y \n";
				vshader += "add vt2.xyz, vt2.xyz, vt0.xyz \n";
				vshader += "m33 vt0.xyz, va2.xyz, vc[va" +index + ".z] \n"
				vshader += "mul vt0.xyz, vt0.xyz, va" + index + ".w \n";
				vshader += "add vt2.xyz, vt2.xyz, vt0.xyz \n";
				// Тангент 
				vshader += "m33 vt0.xyz, va3.xyz, vc[va" + index + ".x] \n"
				vshader += "mul vt0.xyz, vt0.xyz, va" + index + ".y \n";
				vshader += "add vt3.xyz, vt3.xyz, vt0.xyz \n";
				vshader += "m33 vt0.xyz, va3.xyz, vc[va" + index + ".z] \n"
				vshader += "mul vt0.xyz, vt0.xyz, va" + index + ".w \n";
				vshader += "add vt3.xyz, vt3.xyz, vt0.xyz \n";
			}	
				// Проецирование
				vshader += "dp4 vt5.x, vt1, vc" + int(numJoints*4) + " \n"
				vshader += "dp4 vt5.y, vt1, vc" + int(numJoints*4 + 1) + " \n"
				vshader += "dp4 vt5.z, vt1, vc" + int(numJoints*4 + 2) + " \n"
				vshader += "dp4 vt5.w, vt1, vc" + int(numJoints*4 + 3) + " \n"
				vshader += "mov op, vt5 \n";
			
				// Битангент
				vshader += "crs vt4.xyz, vt3, vt2 \n";
				vshader += "mul vt4.xyz, vt4.xyz, va3.w \n";
				vshader += "mov vt4.w, va3.w \n";
				// Коррекция тангента
				vshader += "crs vt3.xyz, vt2, vt4 \n";
				
				// Транспонирование
				vshader += "mov vt5.w, vt3.y \n";
				vshader += "mov vt3.y, vt4.x \n";
				vshader += "mov vt4.x, vt5.w \n";
				vshader += "mov vt5.w, vt3.z \n";
				vshader += "mov vt3.z, vt2.x \n";
				vshader += "mov vt2.x, vt5.w \n";
				vshader += "mov vt5.w, vt4.z \n";
				vshader += "mov vt4.z, vt2.y \n";
				vshader += "mov vt2.y, vt5.w \n";
				
				// Передача
				vshader += "mov v1, vt1 \n";
				vshader += "mov v2, vt2 \n";
				vshader += "mov v3, vt3 \n";
				vshader += "mov v4, vt4 \n";
				
				vshader += "mov v0, va1";
				
			
			var fshader:String = "";
				
				// Диффузия
				fshader += "tex ft0, v0, fs0 <2d,clamp,linear,miplinear> \n"
				// Нормали
				fshader += "tex ft1, v0, fs1 <2d,clamp,linear,miplinear> \n"
				// Спекулар
				fshader += "tex ft2, v0, fs2 <2d,clamp,linear,miplinear> \n"
				
				// Трансформация нормали в локальное пространство из тангента
				fshader += "dp3 ft3.x, ft1, v3 \n"
				fshader += "dp3 ft3.y, ft1, v4 \n"
				fshader += "dp3 ft3.z, ft1, v2 \n"
				fshader += "mov ft3.w, ft0.w \n"
				
				// Нулевой вектор
				fshader += "mov ft4, fc0.x \n";
				
			for (i = 0; i < numOmnies; i++) {

				// Вектор от вершины к омнику
				fshader += "sub ft5, fc" + int(1 + 2*i) + ", v1 \n"
				// Обратная длина вектора
				fshader += "dp3 ft6.x, ft5, ft5 \n"
				fshader += "rsq ft6.x, ft6.x \n"
				// Длина вектора
				fshader += "div ft7.x, fc0.w, ft6.x \n"
				// Нормализация
				fshader += "mul ft6, ft5, ft6.x \n"
				// Угол
				fshader += "dp3 ft6.x, ft3, ft6 \n"
				fshader += "sat ft6.x, ft6.x \n"
				// Расстояние
				fshader += "mul ft7.x, ft7.x, fc" + int(1 + 2*i) + ".w \n"
				fshader += "sub ft7.x, fc0.w, ft7.x \n"
				fshader += "sat ft7.x, ft7.x \n"
				fshader += "mul ft6.x, ft6.x, ft7.x \n"
				// Цвет
				fshader += "mul ft6.xyz, fc" + int(2 + 2*i) + ".xyz, ft6.x \n"
				// Сила
				fshader += "mul ft6.xyz, fc" + int(2 + 2*i) + ".w, ft6.xyz \n"
				// Добавление
				fshader += "add ft4.xyz, ft4.xyz, ft6.xyz \n"
			}
				// Амбиент
				//fshader += "add ft4.xyz, ft4.xyz, fc0.z \n"
				
				// Спекулар
				fshader += "mul ft4.xyz, ft4.xyz, ft2.x \n"
				
				// Умножение на 2 как в лайтмапе
				fshader += "add ft4.xyz, ft4.xyz, ft4.xyz \n"
				
				fshader += "mul ft0.xyz, ft0.xyz, ft4.xyz \n"
				
				fshader += "mov oc, ft0";
				
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX, vshader, false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT,	fshader, false);
			var program:Program3D = context3d.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}
		
	}
}
