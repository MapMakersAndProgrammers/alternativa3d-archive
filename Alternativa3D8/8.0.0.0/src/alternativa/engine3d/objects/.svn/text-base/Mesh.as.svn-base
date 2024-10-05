package alternativa.engine3d.objects {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.materials.Material;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	public class Mesh extends Object3D {

		public var material:Material;
		
		public var geometry:Geometry;
		
		override alternativa3d function get isTransparent():Boolean {
			return (material == null) ? false : material.isTransparent;
		}

		/**
		 * @inheritDoc
		 */
		override public function intersectRay(origin:Vector3D, direction:Vector3D, exludedObjects:Dictionary = null, camera:Camera3D = null):RayIntersectionData {
			/*if (exludedObjects != null && exludedObjects[this]) return null;
			var ox:Number = origin.x;
			var oy:Number = origin.y;
			var oz:Number = origin.z;
			var dx:Number = direction.x;
			var dy:Number = direction.y;
			var dz:Number = direction.z;
			var point:Vector3D;
			var face:Face;
			var min:Number = 1e+22;
			for (var f:Face = faceList; f != null; f = f.next) {
				var normalX:Number = f.normalX;
				var normalY:Number = f.normalY;
				var normalZ:Number = f.normalZ;
				var dot:Number = dx*normalX + dy*normalY + dz*normalZ;
				if (dot < 0) {
					var offset:Number = ox*normalX + oy*normalY + oz*normalZ - f.offset;
					if (offset > 0) {
						var dst:Number = -offset/dot;
						if (point == null || dst < min) {
							var cx:Number = ox + dx*dst;
							var cy:Number = oy + dy*dst;
							var cz:Number = oz + dz*dst;
							var wrapper:Wrapper;
							for (wrapper = f.wrapper; wrapper != null; wrapper = wrapper.next) {
								var a:Vertex = wrapper.vertex;
								var b:Vertex = (wrapper.next != null) ? wrapper.next.vertex : f.wrapper.vertex;
								var abx:Number = b.x - a.x;
								var aby:Number = b.y - a.y;
								var abz:Number = b.z - a.z;
								var acx:Number = cx - a.x;
								var acy:Number = cy - a.y;
								var acz:Number = cz - a.z;
								if ((acz*aby - acy*abz)*normalX + (acx*abz - acz*abx)*normalY + (acy*abx - acx*aby)*normalZ < 0) break;
							}
							if (wrapper == null) {
								if (dst < min) {
									min = dst;
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
				dx = point.x - origin.x;
				dy = point.y - origin.y;
				dz = point.z - origin.z;
				res.distance = Math.sqrt(dx*dx + dy*dy + dz*dz);
				return res;
			} else {*/
				return null;
			//}
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
			projectionMatrix.identity();
			projectionMatrix.append(cameraMatrix);
			projectionMatrix.append(camera.projectionMatrix);
			geometry.update(camera.view);
			material.update(camera.view);
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
			var view:View = camera.view;
			geometry.update(view);
			material.update(view);
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

	}
}
