package alternativa.engine3d.materials {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.objects.Joint; Joint;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.Bitmap3D;
	import flash.display.IndexBuffer3D;
	import flash.display.VertexBuffer3D;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.lights.DirectionalLight;
	import flash.display.Program3D;
	import flash.utils.ByteArray;
	import alternativa.engine3d.objects.Skin;
	import flash.media.Camera;
	
	use namespace alternativa3d;
	
	public class Material {

		/**
		 * Имя материала.
		 */
		public var name:String;
		
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

		alternativa3d function update(view:Bitmap3D):void {
		}
		
		alternativa3d function reset():void {
		}

		alternativa3d function drawSkin(camera:Camera3D, joints:Vector.<Joint>, numJoints:uint, skin:Skin):void {
		}

		alternativa3d function drawMesh(mesh:Mesh, camera:Camera3D):void {
		}

		private function initMeshInShadowMapProgram(view:Bitmap3D):Program3D {
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble("VERTEX",
				meshProjectionShader("vt0") +
				"mov v0, vt0 \n" +
				"mov op, vt0 \n", false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble("FRAGMENT",
				"mov ft0, v0.z \n" +
				"mov oc, ft0", false);
			var program:Program3D = view.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		alternativa3d function drawMeshInShadowMap(mesh:Mesh, camera:Camera3D, light:DirectionalLight):void {
			var view:View = camera.view;
			var program:Program3D = view.cachedPrograms["Smesh"];
			if (program == null) {
				program = initMeshInShadowMapProgram(view);
				view.cachedPrograms["Smesh"] = program;
			}
			view.setProgram(program);
			meshProjectionShaderSetup(view, mesh);
//			view.setCulling("FRONT");
			view.setCulling("BACK");
			if (camera.debug) {
				view.drawTrianglesSynchronized(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			} else {
				view.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			}
		}

		alternativa3d function skinProjectionShader(numJoints:uint, result4:String, vt4_1:String, vt4_2:String):String {
			var shader:String = "dp4 " + vt4_1 + ".x, va0, vc0 \n" +
								"dp4 " + vt4_1 + ".y, va0, vc1 \n" +
								"dp4 " + vt4_1 + ".z, va0, vc2 \n" +
								"dp4 " + vt4_1 + ".w, va0, vc3 \n" +
								"mul " + vt4_2 + ", vt0, va2.x \n";
			const chars:Array = ["x", "y", "z", "w"];
			var charIndex:int = 0;
			for (var i:int = 1; i < numJoints; i ++) {
				var index:int = 4 * i;
				shader += "dp4 " + vt4_1 + ".x, va0, vc" + index + " \n"
				shader += "dp4 " + vt4_1 + ".y, va0, vc" + int(index + 1) + " \n";
				shader += "dp4 " + vt4_1 + ".z, va0, vc" + int(index + 2) + " \n";
				shader += "dp4 " + vt4_1 + ".w, va0, vc" + int(index + 3) + " \n";
				shader += "mul " + vt4_1 + ", vt0, va" + int(int(i/4) + 2) + "." + chars[int(i % 4)] + " \n";
				shader += "add " + vt4_2 + ", vt1, vt0 \n";
			}
			shader += "mov " + result4 + ", " + vt4_2 + " \n"; 
			return shader;
		}

		alternativa3d function skinProjectionShaderSetup(view:View, joints:Vector.<Joint>, numJoints:uint, vertexBuffer:VertexBuffer3D):void {
			view.setVertexStream(0, vertexBuffer, 0, "FLOAT_3");
			var i:int;
			var count:int = int(numJoints/4);
			for (i = 0; i < count; i++) {
				view.setVertexStream(2 + i, vertexBuffer, 5 + 4*i, "FLOAT_4");
			}
			if (4*count < numJoints) {
				view.setVertexStream(2 + count, vertexBuffer, 5 + 4 * count, "FLOAT_" + (numJoints - (4*count)).toString()); 
			}
			for (i = 0; i < numJoints; i++) {
				var joint:Joint = joints[i];
				view.setProgramConstantsMatrixTransposed("VERTEX", 4 * i, joint.cameraMatrix);
			}
		}

		alternativa3d function skinProjectionShaderClean(view:Bitmap3D, numJoints:uint):void {
			var count:int = int(numJoints/4);
			for (var i:int = 0; i < count; i++) {
				view.setVertexStream(2 + i, null, 0, "DISABLED");
			}
			if (4*count < numJoints) {
				view.setVertexStream(2 + count, null, 0, "DISABLED"); 
			}
		}

		alternativa3d function meshProjectionShader(result4:String):String {
			var shader:String = "dp4 " + result4 + ".x, va0, vc0 \n" +
								"dp4 " + result4 + ".y, va0, vc1 \n" +
								"dp4 " + result4 + ".z, va0, vc2 \n" +
								"dp4 " + result4 + ".w, va0, vc3 \n";
			return shader;
		}

		alternativa3d function meshProjectionShaderSetup(view:Bitmap3D, mesh:Mesh):void {
			view.setVertexStream(0, mesh.geometry.vertexBuffer, 0, "FLOAT_3");
			view.setProgramConstantsMatrixTransposed("VERTEX", 0, mesh.projectionMatrix);
		}

		alternativa3d function get isTransparent():Boolean {
			return false;
		}

	}
}
