package alternativa.engine3d.objects {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.materials.Material;
	
	import flash.display3D.Context3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	public class Mesh extends Object3D {

		public var material:Material;
		
		public var geometry:Geometry;
		
		alternativa3d var omnies:Vector.<Number> = new Vector.<Number>();
		alternativa3d var omniesLength:int = 0;
			
		override alternativa3d function get isTransparent():Boolean {
			return (material == null) ? false : material.isTransparent;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var mesh:Mesh = new Mesh();
			mesh.cloneBaseProperties(this);
			mesh.geometry = geometry;
			mesh.material = material;
			return mesh;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D):void {
			if (geometry == null || material == null) return;
			
			inverseCameraMatrix.identity();
			inverseCameraMatrix.append(cameraMatrix);
			inverseCameraMatrix.invert();
			var omniLocalCoords:Vector.<Number> = new Vector.<Number>(3);
			omniesLength = 0;
			for each (var omni:OmniLight in camera.omniLights) {
				inverseCameraMatrix.transformVectors(omni.cameraCoords, omniLocalCoords);
				var ox:Number = omniLocalCoords[0];
				var oy:Number = omniLocalCoords[1];
				var oz:Number = omniLocalCoords[2];
				if (ox + omni.radius > boundMinX && ox - omni.radius < boundMaxX && oy + omni.radius > boundMinY && oy - omni.radius < boundMaxY && oz + omni.radius > boundMinZ && oz - omni.radius < boundMaxZ) {
					omnies[omniesLength++] = ox;
					omnies[omniesLength++] = oy;
					omnies[omniesLength++] = oz;
					omnies[omniesLength++] = 1/omni.radius;
					omnies[omniesLength++] = ((omni.color >> 16) & 0xFF)/255;
					omnies[omniesLength++] = ((omni.color >> 8) & 0xFF)/255;
					omnies[omniesLength++] = (omni.color & 0xFF)/255;
					omnies[omniesLength++] = omni.strength;
				}
			}
			
			projectionMatrix.identity();
			projectionMatrix.append(cameraMatrix);
			projectionMatrix.append(camera.projectionMatrix);
			geometry.update(camera.context3d);
			material.update(camera.context3d);
			
			material.drawMesh(this, camera);
			
			camera.numDraws++;
			camera.numTriangles += geometry.numTriangles;
		}

		/**
		 * @private 
		 */
		override alternativa3d function drawInShadowMap(camera:Camera3D, light:DirectionalLight):void {
			if (geometry == null || material == null) return;
			projectionMatrix.identity();
			projectionMatrix.append(cameraMatrix);
			projectionMatrix.append(light.projectionMatrix);
			var context3d:Context3D = camera.context3d;
			geometry.update(context3d);
			material.update(context3d);
			light.predraw(context3d);
			material.drawMeshInShadowMap(this, camera, light);
			camera.numDraws++;
			camera.numTriangles += geometry.numTriangles;
		}

		/**
		 * @private 
		 */
		override alternativa3d function updateBounds(bounds:Object3D, matrix:Matrix3D = null):void {
			if (geometry != null) {
				var vertex:Vertex;
				if (matrix != null) {
					var rawData:Vector.<Number> = matrix.rawData;
					var ma:Number = rawData[0];
					var mb:Number = rawData[4];
					var mc:Number = rawData[8];
					var md:Number = rawData[12];
					var me:Number = rawData[1];
					var mf:Number = rawData[5];
					var mg:Number = rawData[9];
					var mh:Number = rawData[13];
					var mi:Number = rawData[2];
					var mj:Number = rawData[6];
					var mk:Number = rawData[10];
					var ml:Number = rawData[14];
					for each (vertex in geometry._vertices) {
						var x:Number = ma*vertex.x + mb*vertex.y + mc*vertex.z + md;
						var y:Number = me*vertex.x + mf*vertex.y + mg*vertex.z + mh;
						var z:Number = mi*vertex.x + mj*vertex.y + mk*vertex.z + ml;
						if (x < bounds.boundMinX) bounds.boundMinX = x;
						if (x > bounds.boundMaxX) bounds.boundMaxX = x;
						if (y < bounds.boundMinY) bounds.boundMinY = y;
						if (y > bounds.boundMaxY) bounds.boundMaxY = y;
						if (z < bounds.boundMinZ) bounds.boundMinZ = z;
						if (z > bounds.boundMaxZ) bounds.boundMaxZ = z;
					}
				} else {
					for each (vertex in geometry._vertices) {
						if (vertex.x < bounds.boundMinX) bounds.boundMinX = vertex.x;
						if (vertex.x > bounds.boundMaxX) bounds.boundMaxX = vertex.x;
						if (vertex.y < bounds.boundMinY) bounds.boundMinY = vertex.y;
						if (vertex.y > bounds.boundMaxY) bounds.boundMaxY = vertex.y;
						if (vertex.z < bounds.boundMinZ) bounds.boundMinZ = vertex.z;
						if (vertex.z > bounds.boundMaxZ) bounds.boundMaxZ = vertex.z;
					}
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function intersectRay(origin:Vector3D, direction:Vector3D, exludedObjects:Dictionary = null, camera:Camera3D = null):RayIntersectionData {
			if (exludedObjects != null && exludedObjects[this]) return null;
			if (!boundIntersectRay(origin, direction, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ)) return null;
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
				var a:Vertex = w.vertex; w = w.next;
				var b:Vertex = w.vertex; w = w.next;
				var c:Vertex = w.vertex;
				var abx:Number = b._x - a._x;
				var aby:Number = b._y - a._y;
				var abz:Number = b._z - a._z;
				var acx:Number = c._x - a._x;
				var acy:Number = c._y - a._y;
				var acz:Number = c._z - a._z;
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
					var offset:Number = ox*normalX + oy*normalY + oz*normalZ - (a._x*normalX + a._y*normalY + a._z*normalZ);
					if (offset > 0) {
						var time:Number = -offset/dot;
						if (point == null || time < minTime) {
							var cx:Number = ox + dx*time;
							var cy:Number = oy + dy*time;
							var cz:Number = oz + dz*time;
							var wrapper:Wrapper;
							for (wrapper = f.wrapper; wrapper != null; wrapper = wrapper.next) {
								a = wrapper.vertex;
								b = (wrapper.next != null) ? wrapper.next.vertex : f.wrapper.vertex;
								abx = b._x - a._x;
								aby = b._y - a._y;
								abz = b._z - a._z;
								acx = cx - a._x;
								acy = cy - a._y;
								acz = cz - a._z;
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
		
	}
}
