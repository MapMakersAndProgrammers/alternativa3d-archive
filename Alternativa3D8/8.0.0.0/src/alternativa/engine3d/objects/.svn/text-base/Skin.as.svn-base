package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	
	use namespace alternativa3d;
	
	public class Skin extends Mesh {

		public var renderedJoints:Vector.<Joint>;
		private var rootJoint:Joint = new Joint();

		public function Skin() {
		}

		override alternativa3d function draw(camera:Camera3D):void {
			if (geometry == null || material == null || renderedJoints == null) return;
			projectionMatrix.identity();
			projectionMatrix.append(cameraMatrix);
			projectionMatrix.append(camera.projectionMatrix);
			geometry.update(camera.view);
			material.update(camera.view);
			rootJoint.cameraMatrix.rawData = projectionMatrix.rawData;
			rootJoint.calculateMatrix();
			var numJoints:uint = renderedJoints.length;
			numJoints = (numJoints <= geometry.numJointsInGeometry) ? numJoints : geometry.numJointsInGeometry;
			material.drawSkin(camera, renderedJoints, numJoints, this);
//			material.drawMesh(camera.view, camera.renderMatrix, vertexBuffer, indexBuffer, numTriangles);
			camera.numDraws++;
			camera.numTriangles += geometry.numTriangles;
		}

// -- Расчет вершин на CPU
//		private function transformVertices():void {
//			var vertices:Vector.<Number> = new Vector.<Number>(verts.length);
//			var numVerts:uint = verts.length/dwordsPerVertex;
//			for (var i:int = 0; i < numVerts; i++) {
//				var coords:Vector3D = new Vector3D();
//				var index:int = dwordsPerVertex*i;
//				for (var j:int = 0, numJoints:int = renderedJoints.length; j < numJoints; j++) {
//					var weight:Number = verts[int(index + 5 + j)];
//					if (weight > 0) {
//						var joint:Joint = renderedJoints[j];
//						var v:Vector3D = joint.renderMatrix.transformVector(new Vector3D(verts[index], verts[int(index + 1)], verts[int(index + 2)]));
//						v.scaleBy(weight);
//						coords.incrementBy(v);
//					}
//				}
//				vertices[index] = coords.x;
//				vertices[int(index + 1)] = coords.y;
//				vertices[int(index + 2)] = coords.z;
//				vertices[int(index + 3)] = verts[int(index + 3)]; 
//				vertices[int(index + 4)] = verts[int(index + 4)]; 
//			}
//			vertexBuffer.upload(vertices, 0, numVerts);
//		}

		public function addJoint(joint:Joint):Joint {
			return rootJoint.addJoint(joint);
		}

		public function removeJoint(joint:Joint):Joint {
			return rootJoint.removeJoint(joint);
		}

		public function get numJoints():int {
			return rootJoint.numJoints;
		}

		public function getJointAt(index:int):Joint {
			return rootJoint.getJointAt(index);
		}

		override public function clone():Object3D {
			var res:Skin = new Skin();
			res.cloneBaseProperties(this);
			return res;
		}

		override protected function cloneBaseProperties(source:Object3D):void {
			super.cloneBaseProperties(source);
			var sourceSkin:Skin = Skin(source);
			rootJoint = Joint(sourceSkin.rootJoint.clone());
			
			if (sourceSkin.renderedJoints != null) {
				renderedJoints = new Vector.<Joint>().concat(sourceSkin.renderedJoints);
				remapRenderedJoints(rootJoint, sourceSkin.rootJoint); 
			}
		}

		private function remapRenderedJoints(joint:Joint, sourceJoint:Joint):void {
			for (var i:int = 0, count:int = joint.numJoints; i < count; i++) {
				var child:Joint = joint.getJointAt(i);
				var sourceChild:Joint = sourceJoint.getJointAt(i);
				var index:int = renderedJoints.indexOf(sourceChild);
				if (index >= 0) {
					renderedJoints[index] = child;
				}
				remapRenderedJoints(child, sourceChild);
			}
		}

	}
}
