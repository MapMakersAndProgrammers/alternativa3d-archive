package alternativa.engine3d.materials {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.objects.Joint; Joint;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.utils.ByteArray;
	import alternativa.engine3d.objects.Skin;
	import flash.media.Camera;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexFormat;
	import alternativa.engine3d.lights.DirectionalLight;
	
	use namespace alternativa3d;
	
	public class Material {

		/**
		 * Имя материала.
		 */
		public var name:String;
		
		alternativa3d function update(context3d:Context3D):void {
		}
		
		alternativa3d function reset():void {
		}

		alternativa3d function drawSkin(skin:Skin, camera:Camera3D, joints:Vector.<Joint>, numJoints:int, maxJoints:int, vertexBuffer:VertexBuffer3D, indexBuffer:IndexBuffer3D, numTriangles:int):void {
		}

		alternativa3d function drawMesh(mesh:Mesh, camera:Camera3D):void {
		}

		private function initMeshInShadowMapProgram(context3d:Context3D):Program3D {
			var vertexProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX,
				meshProjectionShader("vt0") +
				"mov v0, vt0 \n" +
				"mov op, vt0 \n", false);
			var fragmentProgram:ByteArray = new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT,
				"mov ft0, v0.z \n" +
				"mov oc, ft0", false);
			var program:Program3D = context3d.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			return program;
		}

		alternativa3d function drawMeshInShadowMap(mesh:Mesh, camera:Camera3D, light:DirectionalLight):void {
			var context3d:Context3D = camera.view._context3d;
			var program:Program3D = camera.context3dCachedPrograms["Smesh"];
			if (program == null) {
				program = initMeshInShadowMapProgram(context3d);
				camera.context3dCachedPrograms["Smesh"] = program;
			}
			context3d.setProgram(program);
			meshProjectionShaderSetup(context3d, mesh);
//			context3d.setCulling("FRONT");
			context3d.setCulling(Context3DTriangleFace.BACK);
			if (camera.debug) {
				context3d.drawTrianglesSynchronized(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
			} else {
				context3d.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
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

		alternativa3d function skinProjectionShaderSetup(context3d:Context3D, joints:Vector.<Joint>, numJoints:uint, vertexBuffer:VertexBuffer3D):void {
			context3d.setVertexStream(0, vertexBuffer, 0, Context3DVertexFormat.FLOAT_3);
			var i:int;
			var count:int = int(numJoints/4);
			for (i = 0; i < count; i++) {
				context3d.setVertexStream(2 + i, vertexBuffer, 5 + 4*i, Context3DVertexFormat.FLOAT_4);
			}
			if (4*count < numJoints) {
				var vertexFormat:String;
				switch (numJoints - (4 * count)) {
					case 1:
						vertexFormat = Context3DVertexFormat.FLOAT_1;
						break;
					case 2:
						vertexFormat = Context3DVertexFormat.FLOAT_2;
						break;
					case 3:
						vertexFormat = Context3DVertexFormat.FLOAT_3;
						break;
				}
				context3d.setVertexStream(2 + count, vertexBuffer, 5 + 4 * count, vertexFormat); 
			}
			for (i = 0; i < numJoints; i++) {
				var joint:Joint = joints[i];
				context3d.setProgramConstantsMatrix(Context3DProgramType.VERTEX, 4 * i, joint.cameraMatrix, true);
			}
		}

		alternativa3d function skinProjectionShaderClean(context3d:Context3D, numJoints:uint):void {
			var count:int = int(numJoints/4);
			for (var i:int = 0; i < count; i++) {
				context3d.setVertexStream(2 + i, null, 0, Context3DVertexFormat.DISABLED);
			}
			if (4*count < numJoints) {
				context3d.setVertexStream(2 + count, null, 0, Context3DVertexFormat.DISABLED); 
			}
		}

		alternativa3d function meshProjectionShader(result4:String):String {
			var shader:String = "dp4 " + result4 + ".x, va0, vc0 \n" +
								"dp4 " + result4 + ".y, va0, vc1 \n" +
								"dp4 " + result4 + ".z, va0, vc2 \n" +
								"dp4 " + result4 + ".w, va0, vc3 \n";
			return shader;
		}

		alternativa3d function meshProjectionShaderSetup(context3d:Context3D, mesh:Mesh):void {
			context3d.setVertexStream(0, mesh.geometry.vertexBuffer, 0, Context3DVertexFormat.FLOAT_3);
			context3d.setProgramConstantsMatrix(Context3DProgramType.VERTEX, 0, mesh.projectionMatrix, true);
		}

		alternativa3d function get isTransparent():Boolean {
			return false;
		}

	}
}
