package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Face;
	import __AS3__.vec.Vector;
	import alternativa.engine3d.core.Wrapper;
	import flash.geom.Matrix3D;
	
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
		
		/**
		 * @private 
		 */
		override alternativa3d function updateBounds(bounds:Object3D, matrix:Matrix3D = null):void {
			if (geometry != null) {
				rootJoint.composeMatrix();
				if (matrix != null) {
					rootJoint.cameraMatrix.append(matrix);
				}
				rootJoint.calculateMatrix();
				var i:int;
				var coordsIn:Vector.<Number> = new Vector.<Number>(3);
				var coordsOut:Vector.<Number> = new Vector.<Number>(3);
				for each (var vertex:Vertex in geometry._vertices) {
					var x:Number = 0;
					var y:Number = 0;
					var z:Number = 0;
					coordsIn[0] = vertex.x;
					coordsIn[1] = vertex.y;
					coordsIn[2] = vertex.z;
					var num:int = vertex._jointsIndices.length;
					var sumWeights:Number = 0;
					for (i = 0; i < num; i++) {
						sumWeights += vertex._jointsWeights[i];
					}
					for (i = 0; i < num; i++) {
						var index:int = vertex._jointsIndices[i];
						var joint:Joint = renderedJoints[index];
						joint.cameraMatrix.transformVectors(coordsIn, coordsOut);
						var weight:Number = vertex._jointsWeights[i]/sumWeights;
						x += coordsOut[0]*weight;
						y += coordsOut[1]*weight;
						z += coordsOut[2]*weight;
					}
					if (x < bounds.boundMinX) bounds.boundMinX = x;
					if (x > bounds.boundMaxX) bounds.boundMaxX = x;
					if (y < bounds.boundMinY) bounds.boundMinY = y;
					if (y > bounds.boundMaxY) bounds.boundMaxY = y;
					if (z < bounds.boundMinZ) bounds.boundMinZ = z;
					if (z > bounds.boundMaxZ) bounds.boundMaxZ = z;
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function intersectRay(origin:Vector3D, direction:Vector3D, exludedObjects:Dictionary = null, camera:Camera3D = null):RayIntersectionData {
			if (exludedObjects != null && exludedObjects[this]) return null;
			
			rootJoint.composeMatrix();
			rootJoint.calculateMatrix();
			
			var i:int;
			var vertex:Vertex;
			
			var map:Dictionary = new Dictionary();
			var coordsIn:Vector.<Number> = new Vector.<Number>(3);
			var coordsOut:Vector.<Number> = new Vector.<Number>(3);
			
			for each (vertex in geometry._vertices) {
				var value:Vector3D = new Vector3D();
				map[vertex] = value;
				coordsIn[0] = vertex.x;
				coordsIn[1] = vertex.y;
				coordsIn[2] = vertex.z;
				var num:int = vertex._jointsIndices.length;
				var sumWeights:Number = 0;
				for (i = 0; i < num; i++) {
					sumWeights += vertex._jointsWeights[i];
				}
				for (i = 0; i < num; i++) {
					var index:int = vertex._jointsIndices[i];
					var joint:Joint = renderedJoints[index];
					joint.cameraMatrix.transformVectors(coordsIn, coordsOut);
					var weight:Number = vertex._jointsWeights[i]/sumWeights;
					value.x += coordsOut[0]*weight;
					value.y += coordsOut[1]*weight;
					value.z += coordsOut[2]*weight;
				}
			}
			var ox:Number = origin.x;
			var oy:Number = origin.y;
			var oz:Number = origin.z;
			var dx:Number = direction.x;
			var dy:Number = direction.y;
			var dz:Number = direction.z;
			var point:Vector3D;
			var face:Face;
			var minTime:Number = 1e+22;
			for each (var f:Face in geometry._faces) {
				var w:Wrapper = f.wrapper;
				var a:Vector3D = map[w.vertex]; w = w.next;
				var b:Vector3D = map[w.vertex]; w = w.next;
				var c:Vector3D = map[w.vertex];
				var abx:Number = b.x - a.x;
				var aby:Number = b.y - a.y;
				var abz:Number = b.z - a.z;
				var acx:Number = c.x - a.x;
				var acy:Number = c.y - a.y;
				var acz:Number = c.z - a.z;
				var normalX:Number = acz*aby - acy*abz;
				var normalY:Number = acx*abz - acz*abx;
				var normalZ:Number = acy*abx - acx*aby;
				var len:Number = normalX*normalX + normalY*normalY + normalZ*normalZ;
				if (len > 0.001) {
					len = 1/Math.sqrt(len);
					normalX *= len;
					normalY *= len;
					normalZ *= len;
				}
				var dot:Number = dx*normalX + dy*normalY + dz*normalZ;
				if (dot < 0) {
					var offset:Number = ox*normalX + oy*normalY + oz*normalZ - (a.x*normalX + a.y*normalY + a.z*normalZ);
					if (offset > 0) {
						var time:Number = -offset/dot;
						if (point == null || time < minTime) {
							var cx:Number = ox + dx*time;
							var cy:Number = oy + dy*time;
							var cz:Number = oz + dz*time;
							var wrapper:Wrapper;
							for (wrapper = f.wrapper; wrapper != null; wrapper = wrapper.next) {
								a = map[wrapper.vertex];
								b = (wrapper.next != null) ? map[wrapper.next.vertex] : map[f.wrapper.vertex];
								abx = b.x - a.x;
								aby = b.y - a.y;
								abz = b.z - a.z;
								acx = cx - a.x;
								acy = cy - a.y;
								acz = cz - a.z;
								if ((acz*aby - acy*abz)*normalX + (acx*abz - acz*abx)*normalY + (acy*abx - acx*aby)*normalZ < 0) break;
							}
							if (wrapper == null) {
								if (time < minTime) {
									minTime = time;
									if (point == null) point = new Vector3D();
									point.x = cx;
									point.y = cy;
									point.z = cz;
									face = f;
								}
							}
						}
					}
				}
			}
			if (point != null) {
				var res:RayIntersectionData = new RayIntersectionData();
				res.object = this;
				res.face = face;
				res.point = point;
				res.time = minTime;
				return res;
			} else {
				return null;
			}
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
