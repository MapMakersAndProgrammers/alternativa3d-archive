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
	import alternativa.engine3d.core.View;
	import flash.display.VertexBuffer3D;
	import flash.display.IndexBuffer3D;
	
	use namespace alternativa3d;
	
	public class Skin extends Mesh {

		public var renderedJoints:Vector.<Joint>;
		private var rootJoint:Joint = new Joint();
		
		private var jointLists:Vector.<Vector.<Joint>>;
		private var vertexBuffers:Vector.<VertexBuffer3D>;
		private var indexBuffers:Vector.<IndexBuffer3D>;
		private var numsTriangles:Vector.<int>;
		
		private function devide(view:View, limit:int):void {
			var i:int;
			var j:int;
			var k:*;
			var key:*;
			var joint:Joint;
			var sumJoints:int;
			var index:int;
			var face:Face;
			var wrapper:Wrapper;
			
			var siblings:Dictionary = new Dictionary();
			var fcs:Dictionary = new Dictionary();
			
			var heap:Dictionary = new Dictionary();
			var groups:Vector.<Dictionary> = new Vector.<Dictionary>();
			var groupsSiblings:Vector.<Dictionary> = new Vector.<Dictionary>();
			
			var renderedJointsLength:int = renderedJoints.length;
			for (i = 0; i < renderedJointsLength; i++) {
				joint = renderedJoints[i];
				siblings[joint] = new Dictionary();
				fcs[joint] = new Dictionary();
				heap[joint] = true;
			}
			// Определение соседних по граням джоинтов
			for each (face in geometry._faces) {
				for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					for each (index in wrapper.vertex._jointsIndices) {
						joint = renderedJoints[index];
						fcs[joint][face] = true;
						var dict:Dictionary = siblings[joint];
						for (var w:Wrapper = face.wrapper; w != null; w = w.next) {
							for each (var ind:uint in w.vertex._jointsIndices) {
								dict[renderedJoints[ind]] = true;
							}
						}
						
					}
				}
			}
			for (key in siblings) {
				joint = key;
				delete siblings[joint][joint];
				sumJoints = 1;
				for (k in siblings[joint]) sumJoints++;
				if (sumJoints > limit) throw new Error("Cannot devide skin.");
			}
			
			// Группировка
			while (true) {
				key = null;
				for (key in heap) break;
				if (key == null) break;
				
				joint = key;
				delete heap[key];
				
				var groupSum:int = 1;
				
				var group:Dictionary = new Dictionary();
				groups.push(group);
				group[joint] = true;
				
				var groupSiblings:Dictionary = new Dictionary();
				groupsSiblings.push(groupSiblings);
				for (key in siblings[joint]) {
					groupSiblings[key] = true;
					groupSum++;
				}
				while (true) {
					var found:Boolean = false;
					
					for (key in groupSiblings) {
						var jt:Joint = key;
						sumJoints = 0;
						for (k in siblings[jt]) {
							if (!group[k] && !groupSiblings[k]) sumJoints++;
							if (groupSum + sumJoints > limit) break;
						}
						if (groupSum + sumJoints <= limit) {
							group[jt] = true;
							delete heap[jt];
							delete groupSiblings[jt];
							for (k in siblings[jt]) {
								if (!group[k] && !groupSiblings[k]) {
									groupSiblings[k] = true;
									groupSum++;
								}
							}
							
							found = true;
							break;
						}
					}
					
					if (!found) break;
				}
			}
			
			// Перебор групп
			var num:int = 0;
			jointLists = new Vector.<Vector.<Joint>>();
			vertexBuffers = new Vector.<VertexBuffer3D>();
			indexBuffers = new Vector.<IndexBuffer3D>();
			numsTriangles = new Vector.<int>();
			for (i = 0; i < groups.length; i++) {
				//trace("----");
				
				var verticesSet:Dictionary = new Dictionary();
				var facesSet:Dictionary = new Dictionary();
				var joints:Vector.<Joint> = new Vector.<Joint>();
				var numJoints:int = 0;
				for (key in groups[i]) {
					joint = key;
					//trace("j", joint);
					joint.index = numJoints;
					joints[numJoints] = joint;
					numJoints++;
					for (k in fcs[joint]) {
						facesSet[k] = true;
						delete fcs[joint][k];
					}
				}
				for (key in groupsSiblings[i]) {
					joint = key;
					//trace("s", joint);
					joint.index = numJoints;
					joints[numJoints] = joint;
					numJoints++;
					// Удаление грани дрокола из соседей
					for (k in facesSet) {
						delete fcs[joint][k];
					}
				}
				
				// Вершины
				for (k in facesSet) {
					face = k;
					for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
						verticesSet[wrapper.vertex] = true;
					}
				}
				var vertex:Vertex;
				var numAttributes:uint;
				var maxAttributes:uint = 0;
				var verticesLength:int = 0;
				for (k in verticesSet) {
					vertex = k;
					verticesLength++;
					if (vertex._attributes != null) {
						numAttributes = vertex._attributes.length;
						if (numAttributes > maxAttributes) {
							maxAttributes = numAttributes;
						}
					}
				}
				maxAttributes += numJoints + 5;
				var vertices:Vector.<Number> = new Vector.<Number>(verticesLength*maxAttributes);
				var n:int = 0;
				for (k in verticesSet) {
					vertex = k;
					index = maxAttributes*n;
					vertices[int(index++)] = vertex._x;
					vertices[int(index++)] = vertex._y;
					vertices[int(index++)] = vertex._z;
					vertices[int(index++)] = vertex._u;
					vertices[int(index++)] = vertex._v;
					var jointIndex:uint;
					var jointWeight:Number;
					var sum:Number = 0;
					if (vertex._jointsIndices != null && vertex._jointsWeights != null) {
						var nJ:int = vertex._jointsIndices.length;
						var numWeights:int = vertex._jointsWeights.length;
						for (j = 0; j < numWeights; j++) {
							sum += vertex._jointsWeights[j];
						}
						if (sum > 0) {
							for (j = 0; j < nJ && j < numWeights; j++) {
								jointIndex = renderedJoints[vertex._jointsIndices[j]].index;
								jointWeight = vertex._jointsWeights[j];
								vertices[int(index + jointIndex)] = jointWeight/sum;
							}
						}
					}
					index += numJoints;
					if (vertex._attributes != null) {
						numAttributes = vertex._attributes.length;
						for (j = 0; j < numAttributes; j++) {
							vertices[int(index++)] = vertex._attributes[j];
						}
					}
					vertex.index = n;
					n++;
				}
				// Грани
				var indices:Vector.<uint> = new Vector.<uint>();
				var numTriangles:int = 0;
				for (k in facesSet) {
					face = k;
					var a:Wrapper = face.wrapper;
					var b:Wrapper = a.next;
					for (var c:Wrapper = b.next; c != null; c = c.next) {
						indices.push(a.vertex.index);
						indices.push(b.vertex.index);
						indices.push(c.vertex.index);
						b = c;
						numTriangles++;
					}
				}
				//trace(numTriangles);
				// Создание буферов
				if (numTriangles > 0) {
					jointLists[num] = joints;
					numsTriangles[num] = numTriangles;
					vertexBuffers[num] = view.createVertexBuffer(verticesLength, maxAttributes);
					vertexBuffers[num].upload(vertices, 0, verticesLength);
					indexBuffers[num] = view.createIndexBuffer(indices.length);
					indexBuffers[num].upload(indices, 0, indices.length);
					num++;
				}
			}
			
		}
		
		override alternativa3d function draw(camera:Camera3D):void {
			if (geometry == null || material == null || renderedJoints == null) return;
			projectionMatrix.identity();
			projectionMatrix.append(cameraMatrix);
			projectionMatrix.append(camera.projectionMatrix);
			material.update(camera.view);
			rootJoint.cameraMatrix.rawData = projectionMatrix.rawData;
			rootJoint.calculateMatrix();
			
			var numJoints:uint = renderedJoints.length;
			if (numJoints > 24 && indexBuffers == null) devide(camera.view, 24);
			
			if (indexBuffers != null) {
				var numDraws:int = indexBuffers.length;
				for (var i:int = 0; i < numDraws; i++) {
					material.drawSkin(this, camera, jointLists[i], jointLists[i].length, vertexBuffers[i], indexBuffers[i], numsTriangles[i]);
					camera.numDraws++;
					camera.numTriangles += numsTriangles[i];
				}
			} else {
				geometry.update(camera.view);
				numJoints = (numJoints <= geometry.numJointsInGeometry) ? numJoints : geometry.numJointsInGeometry;
				material.drawSkin(this, camera, renderedJoints, numJoints, geometry.vertexBuffer, geometry.indexBuffer, geometry.numTriangles);
				camera.numDraws++;
				camera.numTriangles += geometry.numTriangles;
			}
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
