package alternativa.engine3d.materials {
	
	import alternativa.engine3d.alternativa3d;
	import flash.display.BitmapData;
	import alternativa.engine3d.materials.TextureMaterial;
	import flash.display.Bitmap3D;
	import flash.geom.Matrix3D;
	import flash.display.VertexBuffer3D;
	import flash.display.IndexBuffer3D;
	import flash.display.Program3D;
	import flash.utils.ByteArray;
	import __AS3__.vec.Vector;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.materials.AGALMiniAssembler;
	
	use namespace alternativa3d;
	
	public class EnvMaterial extends TextureMaterial {
		
		static private var program:Program3D;
		
		public function EnvMaterial(texture:BitmapData = null) {
			super(texture);
		}
		
		public function drawMesh(mesh:Mesh, camera:Camera3D):void {
			if (texture3d == null) return;
			
			var view:View = camera.view;
			if (program == null) program = initProgram(view);
			
			view.setProgram(program);
			if (_texture.transparent) {
				view.setBlending("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA");
			} else {
				view.setBlending("ONE", "ZERO");
			}
			view.setVertexStream(0, mesh.geometry.vertexBuffer, 0, "FLOAT_3");
			view.setVertexStream(1, mesh.geometry.vertexBuffer, 3, "FLOAT_2");
			view.setVertexStream(2, mesh.geometry.vertexBuffer, 5, "FLOAT_3");
			view.setTexture(0, texture3d);
			
			/*view.setProgramConstantsMatrixTransposed("VERTEX", 0, mesh.projectionMatrix);
			view.setProgramConstantsMatrixTransposed("VERTEX", 4, mesh.cameraMatrix);*/
			
			view.setProgramConstantsMatrixTransposed("VERTEX", 0, mesh.cameraMatrix);
			view.setProgramConstantsMatrixTransposed("VERTEX", 4, camera.projectionMatrix);
			view.setProgramConstants("VERTEX", 8, 4, Vector.<Number>([0, 0, 1, 2]));
			
			view.setProgramConstants("FRAGMENT", 0, 2, Vector.<Number>([0.43, 0.5]));
			view.setCulling("FRONT");
			view.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			view.setVertexStream(2, null, 0, "FLOAT_4");
			
		}
		
		private static function initProgram(view:Bitmap3D):Program3D {
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX",
				// Перевод в камеру вершины
				"dp4 vt0.x, va0, vc0 \n" +
				"dp4 vt0.y, va0, vc1 \n" +
				"dp4 vt0.z, va0, vc2 \n" +
				"dp4 vt0.w, va0, vc3 \n" +
				// Проецирование
				"dp4 op.x, vt0, vc4 \n" +
				"dp4 op.y, vt0, vc5 \n" +
				"dp4 op.z, vt0, vc6 \n" +
				"dp4 op.w, vt0, vc7 \n" +
				// Перевод в камеру нормали
				"dp3 vt1.x, va2.xyz, vc0 \n" +
				"dp3 vt1.y, va2.xyz, vc1 \n" +
				"dp3 vt1.z, va2.xyz, vc2 \n" +
				"dp3 vt1.w, va2.xyz, vc3 \n" +
				// Нормализация
				/*"dp3 vt3.x, vt0, vt0 \n" +
				"rsq vt3.x, vt3.x \n" +
				"mul vt0.xyz, vt0.xyz, vt3.x \n" +*/
				// Поиск отраженного вектора
				"dp3 vt1.w, vt0, vt1 \n" +
				"mul vt1.w, vt1.w, vc8.w \n" +
				"mul vt1.xyz, vt1.xyz, vt1.w \n" +
				"sub vt1.xyz, vt1.xyz, vt0.xyz \n" +
				// Поиск исправленной нормали
				"sub vt0.xyz, vc2.xyz, vt1.xyz \n" +
				"dp3 vt1.x, vt0, vt0 \n" +
				"rsq vt1.x, vt1.x \n" +
				"mul v1.xyz, vt0.xyz, vt1.x \n" +
				
				"mov v0, va1", false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble("FRAGMENT",
				"mul ft0, v1, fc0.x \n" +  
				"add ft0, ft0, fc0.y \n" +  
				"tex ft0, ft0, fs0 <2d,clamp,linear,miplinear> \n" +
				"mov oc, ft0", false);
				/*"dp3 ft1.x, v1, v1 \n" +
				"rsq ft1.x, ft1.x \n" +
				"mul ft1, v1, ft1.x \n" +
				"mul ft0, ft1, fc0.x \n" +  
				"add ft0, ft0, fc0.y \n" +  
				"tex ft0, ft0, fs0 <2d,clamp,linear,miplinear> \n" +
				"mov oc, ft0", false);*/
			var program:Program3D = view.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}
		
		/*private static function initProgram(view:Bitmap3D):Program3D {
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX",
				"dp4 op.x, va0, vc0 \n" +
				"dp4 op.y, va0, vc1 \n" +
				"dp4 op.z, va0, vc2 \n" +
				"dp4 op.w, va0, vc3 \n" +
				"dp3 v1.x, va2.xyz, vc4 \n" +
				"dp3 v1.y, va2.xyz, vc5 \n" +
				"dp3 v1.z, va2.xyz, vc6 \n" +
				"dp3 v1.w, va2.xyz, vc7 \n" +
				"mov v0, va1", false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble("FRAGMENT",
				"mul ft0, v1, fc0.x \n" +  
				"add ft0, ft0, fc0.y \n" +  
				"tex ft0, ft0, fs0 <2d,clamp,linear,miplinear> \n" +
				"mov oc, ft0", false);
			var program:Program3D = view.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}*/
		
	}
}