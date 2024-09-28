package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;

	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Utils3D;
	
	use namespace alternativa3d;
	
	public class Geometry {
		
		static private var collector:Geometry;
		
		// Вспомогательные
		static private const sortingFragments:Vector.<Fragment> = new Vector.<Fragment>();
		static private const sortingStack:Vector.<int> = new Vector.<int>();
		static private const verticesMap:Vector.<int> = new Vector.<int>();
		static private var negativeReserve:Fragment = Fragment.create();
		static private var positiveReserve:Fragment = Fragment.create();
		
		public var next:Geometry;
		
		public var vertices:Vector.<Number> = new Vector.<Number>();
		public var uvts:Vector.<Number> = new Vector.<Number>();
		public var verticesLength:int = 0;
		public var numVertices:int = 0;
		
		public var projectedVertices:Vector.<Number> = new Vector.<Number>();
		private var drawIndices:Vector.<int> = new Vector.<int>();
		private var drawIndicesLength:int = 0;
		
		public var fragment:Fragment;
		
		public var numOccluders:int;
		
		// Передаваемые при сплите свойства
		
		public var cameraMatrix:Matrix3D = new Matrix3D();
		public var alpha:Number;
		public var blendMode:String;
		public var colorTransform:ColorTransform;
		public var filters:Array;
		
		public var sorting:int;
		
		public var texture:BitmapData;
		public var smooth:Boolean;
		public var repeatTexture:Boolean;
		
		public var debugResult:int = 0;
		
		public var viewAligned:Boolean = false;
		public var textureMatrix:Matrix = new Matrix();
		public var projectionX:Number;
		public var projectionY:Number;
		
		// AABB
		public var minX:Number;
		public var minY:Number;
		public var minZ:Number;
		public var maxX:Number;
		public var maxY:Number;
		public var maxZ:Number;
		
		// OOBB
		static private const inverseCameraMatrix:Matrix3D = new Matrix3D();
		static private const localVertices:Vector.<Number> = new Vector.<Number>();
		public var points:Vector.<Number> = new Vector.<Number>(24, true);
		public var planes:Vector.<Number> = new Vector.<Number>(24, true);
		
		static public function create():Geometry {
			if (collector != null) {
				var res:Geometry = collector;
				collector = collector.next;
				res.next = null;
				return res;
			} else {
				return new Geometry();
			}
		}
		
		public function create():Geometry {
			if (collector != null) {
				var res:Geometry = collector;
				collector = collector.next;
				res.next = null;
				return res;
			} else {
				return new Geometry();
			}
		}
		
		public function destroy():void {
			if (fragment != null) {
				destroyFragments(fragment);
				fragment = null;
			}
			numVertices = 0;
			verticesLength = 0;
			viewAligned = false;
			colorTransform = null;
			filters = null;
			numOccluders = 0;
			debugResult = 0;
			next = collector;
			collector = this;
		}
		
		private function destroyFragments(fragment:Fragment):void {
			if (fragment.negative != null) {
				destroyFragments(fragment.negative);
				fragment.negative = null;
			}
			if (fragment.positive != null) {
				destroyFragments(fragment.positive);
				fragment.positive = null;
			}
			var last:Fragment = fragment;
			while (last.next != null) {
				last = last.next;
			}
			last.next = Fragment.collector;
			Fragment.collector = fragment;
		}
		
		public function calculateAABB():void {
			var verts:Vector.<Number> = vertices;
			minX = Number.MAX_VALUE;
			minY = Number.MAX_VALUE;
			minZ = Number.MAX_VALUE;
			maxX = -Number.MAX_VALUE;
			maxY = -Number.MAX_VALUE;
			maxZ = -Number.MAX_VALUE;
			for (var i:int = 0, c:Number; i < verticesLength;) {
				c = verts[i]; i++;
				if (c < minX) minX = c;
				if (c > maxX) maxX = c;
				c = verts[i]; i++;
				if (c < minY) minY = c;
				if (c > maxY) maxY = c;
				c = verts[i]; i++;
				if (c < minZ) minZ = c;
				if (c > maxZ) maxZ = c;
			}
		}
		
		public function calculateOOBB():void {
			var verts:Vector.<Number> = localVertices;
			vertices.length = verticesLength;
			inverseCameraMatrix.identity();
			inverseCameraMatrix.prepend(cameraMatrix);
			inverseCameraMatrix.invert();
			inverseCameraMatrix.transformVectors(vertices, verts);
			minX = Number.MAX_VALUE;
			minY = Number.MAX_VALUE;
			minZ = Number.MAX_VALUE;
			maxX = -Number.MAX_VALUE;
			maxY = -Number.MAX_VALUE;
			maxZ = -Number.MAX_VALUE;
			for (var i:int = 0, c:Number; i < verticesLength;) {
				c = verts[i]; i++;
				if (c < minX) minX = c;
				if (c > maxX) maxX = c;
				c = verts[i]; i++;
				if (c < minY) minY = c;
				if (c > maxY) maxY = c;
				c = verts[i]; i++;
				if (c < minZ) minZ = c;
				if (c > maxZ) maxZ = c;
			}
			// Костыль
			if (maxX - minX < 1) {
				maxX = minX + 1;
			}
			if (maxY - minY < 1) {
				maxY = minY + 1;
			}
			if (maxZ - minZ < 1) {
				maxZ = minZ + 1;
			}
			// A
			points[0] = minX;
			points[1] = minY;
			points[2] = minZ;
			// B
			points[3] = maxX;
			points[4] = minY;
			points[5] = minZ;
			// C
			points[6] = minX;
			points[7] = maxY;
			points[8] = minZ;
			// D
			points[9] = maxX;
			points[10] = maxY;
			points[11] = minZ;
			// E
			points[12] = minX;
			points[13] = minY;
			points[14] = maxZ;
			// F
			points[15] = maxX;
			points[16] = minY;
			points[17] = maxZ;
			// G
			points[18] = minX;
			points[19] = maxY;
			points[20] = maxZ;
			// H
			points[21] = maxX;
			points[22] = maxY;
			points[23] = maxZ;
			// Перевод вершин баунда из локальных координат в камеру
			cameraMatrix.transformVectors(points, points);
			// Front
			var ax:Number = points[0];
			var ay:Number = points[1];
			var az:Number = points[2];
			var abx:Number = points[3] - ax;
			var aby:Number = points[4] - ay;
			var abz:Number = points[5] - az;
			var acx:Number = points[12] - ax;
			var acy:Number = points[13] - ay;
			var acz:Number = points[14] - az;
			var nx:Number = acz*aby - acy*abz;
			var ny:Number = acx*abz - acz*abx;
			var nz:Number = acy*abx - acx*aby;
			var nl:Number = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
			nx *= nl;
			ny *= nl;
			nz *= nl;
			planes[0] = nx;
			planes[1] = ny;
			planes[2] = nz;
			planes[3] = ax*nx + ay*ny + az*nz;
			// Back
			ax = points[6];
			ay = points[7];
			az = points[8];
			abx = points[18] - ax;
			aby = points[19] - ay;
			abz = points[20] - az;
			acx = points[9] - ax;
			acy = points[10] - ay;
			acz = points[11] - az;
			nx = acz*aby - acy*abz;
			ny = acx*abz - acz*abx;
			nz = acy*abx - acx*aby;
			nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
			nx *= nl;
			ny *= nl;
			nz *= nl;
			planes[4] = nx;
			planes[5] = ny;
			planes[6] = nz;
			planes[7] = ax*nx + ay*ny + az*nz;
			// Left
			ax = points[0];
			ay = points[1];
			az = points[2];
			abx = points[12] - ax;
			aby = points[13] - ay;
			abz = points[14] - az;
			acx = points[6] - ax;
			acy = points[7] - ay;
			acz = points[8] - az;
			nx = acz*aby - acy*abz;
			ny = acx*abz - acz*abx;
			nz = acy*abx - acx*aby;
			nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
			nx *= nl;
			ny *= nl;
			nz *= nl;
			planes[8] = nx;
			planes[9] = ny;
			planes[10] = nz;
			planes[11] = ax*nx + ay*ny + az*nz;
			// Right
			ax = points[3];
			ay = points[4];
			az = points[5];
			abx = points[9] - ax;
			aby = points[10] - ay;
			abz = points[11] - az;
			acx = points[15] - ax;
			acy = points[16] - ay;
			acz = points[17] - az;
			nx = acz*aby - acy*abz;
			ny = acx*abz - acz*abx;
			nz = acy*abx - acx*aby;
			nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
			nx *= nl;
			ny *= nl;
			nz *= nl;
			planes[12] = nx;
			planes[13] = ny;
			planes[14] = nz;
			planes[15] = ax*nx + ay*ny + az*nz;
			// Top
			ax = points[12];
			ay = points[13];
			az = points[14];
			abx = points[15] - ax;
			aby = points[16] - ay;
			abz = points[17] - az;
			acx = points[18] - ax;
			acy = points[19] - ay;
			acz = points[20] - az;
			nx = acz*aby - acy*abz;
			ny = acx*abz - acz*abx;
			nz = acy*abx - acx*aby;
			nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
			nx *= nl;
			ny *= nl;
			nz *= nl;
			planes[16] = nx;
			planes[17] = ny;
			planes[18] = nz;
			planes[19] = ax*nx + ay*ny + az*nz;
			// Bottom
			ax = points[0];
			ay = points[1];
			az = points[2];
			abx = points[6] - ax;
			aby = points[7] - ay;
			abz = points[8] - az;
			acx = points[3] - ax;
			acy = points[4] - ay;
			acz = points[5] - az;
			nx = acz*aby - acy*abz;
			ny = acx*abz - acz*abx;
			nz = acy*abx - acx*aby;
			nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
			nx *= nl;
			ny *= nl;
			nz *= nl;
			planes[20] = nx;
			planes[21] = ny;
			planes[22] = nz;
			planes[23] = ax*nx + ay*ny + az*nz;
		}
		
		public function split(axisX:Boolean, axisY:Boolean, coord:Number, threshold:Number, negative:Geometry, positive:Geometry):void {
			var i:int;
			var c:Number;
			var verts:Vector.<Number>;
			var vertsLen:int;
			// Сброс карты
			for (i = 0; i < numVertices; i++) verticesMap[i] = -1;
			// Разбиение
			splitFragments(fragment, negative, positive, axisX, axisY, coord, coord - threshold, coord + threshold);
			// Копирование свойств
			if (negative != null && fragment.negative != null) {
				negative.fragment = fragment.negative;
				fragment.negative = null;
				negative.texture = texture;
				negative.smooth = smooth;
				negative.repeatTexture = repeatTexture;
				negative.cameraMatrix.identity();
				negative.cameraMatrix.prepend(cameraMatrix);
				negative.alpha = alpha;
				negative.blendMode = blendMode;
				negative.colorTransform = colorTransform;
				negative.filters = filters;
				negative.sorting = sorting;
				negative.debugResult = debugResult;
				negative.viewAligned = viewAligned;
				if (viewAligned) {
					negative.textureMatrix.a = textureMatrix.a;
					negative.textureMatrix.b = textureMatrix.b;
					negative.textureMatrix.c = textureMatrix.c;
					negative.textureMatrix.d = textureMatrix.d;
					negative.textureMatrix.tx = textureMatrix.tx;
					negative.textureMatrix.ty = textureMatrix.ty;
					negative.projectionX = projectionX;
					negative.projectionY = projectionY;
				}
				// Обновление баунда
				verts = negative.vertices;
				vertsLen = negative.verticesLength;
				if (axisX) {
					negative.minX = minX;
					negative.maxX = coord;
					negative.minY = maxY;
					negative.maxY = minY;
					negative.minZ = maxZ;
					negative.maxZ = minZ;
					for (i = 0; i < vertsLen;) {
						i++;
						c = verts[i]; i++;
						if (c < negative.minY) negative.minY = c;
						if (c > negative.maxY) negative.maxY = c;
						c = verts[i]; i++;
						if (c < negative.minZ) negative.minZ = c;
						if (c > negative.maxZ) negative.maxZ = c;
					}
				} else if (axisY) {
					negative.minX = maxX;
					negative.maxX = minX;
					negative.minY = minY;
					negative.maxY = coord;
					negative.minZ = maxZ;
					negative.maxZ = minZ;
					for (i = 0; i < vertsLen;) {
						c = verts[i]; i++;
						if (c < negative.minX) negative.minX = c;
						if (c > negative.maxX) negative.maxX = c;
						i++;
						c = verts[i]; i++;
						if (c < negative.minZ) negative.minZ = c;
						if (c > negative.maxZ) negative.maxZ = c;
					}
				} else {
					negative.minX = maxX;
					negative.minY = maxY;
					negative.minZ = minZ;
					negative.maxX = minX;
					negative.maxY = minY;
					negative.maxZ = coord;
					for (i = 0; i < vertsLen;) {
						c = verts[i]; i++;
						if (c < negative.minX) negative.minX = c;
						if (c > negative.maxX) negative.maxX = c;
						c = verts[i]; i++;
						if (c < negative.minY) negative.minY = c;
						if (c > negative.maxY) negative.maxY = c;
						i++;
					}
				}
			}
			if (positive != null && fragment.positive != null) {
				positive.fragment = fragment.positive;
				fragment.positive = null;
				positive.texture = texture;
				positive.smooth = smooth;
				positive.repeatTexture = repeatTexture;
				positive.cameraMatrix.identity();
				positive.cameraMatrix.prepend(cameraMatrix);
				positive.alpha = alpha;
				positive.blendMode = blendMode;
				positive.colorTransform = colorTransform;
				positive.filters = filters;
				positive.sorting = sorting;
				positive.debugResult = debugResult;
				positive.viewAligned = viewAligned;
				if (viewAligned) {
					positive.textureMatrix.a = textureMatrix.a;
					positive.textureMatrix.b = textureMatrix.b;
					positive.textureMatrix.c = textureMatrix.c;
					positive.textureMatrix.d = textureMatrix.d;
					positive.textureMatrix.tx = textureMatrix.tx;
					positive.textureMatrix.ty = textureMatrix.ty;
					positive.projectionX = projectionX;
					positive.projectionY = projectionY;
				}
				// Обновление баунда
				verts = positive.vertices;
				vertsLen = positive.verticesLength;
				if (axisX) {
					positive.minX = coord;
					positive.maxX = maxX;
					positive.minY = maxY;
					positive.maxY = minY;
					positive.minZ = maxZ;
					positive.maxZ = minZ;
					for (i = 0; i < vertsLen;) {
						i++;
						c = verts[i]; i++;
						if (c < positive.minY) positive.minY = c;
						if (c > positive.maxY) positive.maxY = c;
						c = verts[i]; i++;
						if (c < positive.minZ) positive.minZ = c;
						if (c > positive.maxZ) positive.maxZ = c;
					}
				} else if (axisY) {
					positive.minX = maxX;
					positive.maxX = minX;
					positive.minY = coord;
					positive.maxY = maxY;
					positive.minZ = maxZ;
					positive.maxZ = minZ;
					for (i = 0; i < vertsLen;) {
						c = verts[i]; i++;
						if (c < positive.minX) positive.minX = c;
						if (c > positive.maxX) positive.maxX = c;
						i++;
						c = verts[i]; i++;
						if (c < positive.minZ) positive.minZ = c;
						if (c > positive.maxZ) positive.maxZ = c;
					}
				} else {
					positive.minX = maxX;
					positive.maxX = minX;
					positive.minY = maxY;
					positive.maxY = minY;
					positive.minZ = coord;
					positive.maxZ = maxZ;
					for (i = 0; i < vertsLen;) {
						c = verts[i]; i++;
						if (c < positive.minX) positive.minX = c;
						if (c > positive.maxX) positive.maxX = c;
						c = verts[i]; i++;
						if (c < positive.minY) positive.minY = c;
						if (c > positive.maxY) positive.maxY = c;
						i++;
					}
				}
			}
			fragment.next = Fragment.collector;
			Fragment.collector = fragment;
			fragment = null;
		}
		
		private function splitFragments(fragment:Fragment, negativeGeometry:Geometry, positiveGeometry:Geometry, axisX:Boolean, axisY:Boolean, coord:Number, minCoord:Number, maxCoord:Number):void {
			var result:Fragment = fragment;
			var innegative:Boolean = negativeGeometry != null;
			var inpositive:Boolean = positiveGeometry != null;
			var split:Boolean = innegative && inpositive;
			var crop:Boolean = !split;
			var negativeNegative:Fragment;
			var negativePositive:Fragment;
			var positiveNegative:Fragment;
			var positivePositive:Fragment;
			// Проход по дочерним нодам
			if (result.negative != null) {
				splitFragments(result.negative, negativeGeometry, positiveGeometry, axisX, axisY, coord, minCoord, maxCoord);
				negativeNegative = result.negative.negative;
				negativePositive = result.negative.positive;
				result.negative.negative = null;
				result.negative.positive = null;
				result.negative.next = Fragment.collector;
				Fragment.collector = result.negative;
				result.negative = null;
			}
			if (result.positive != null) {
				splitFragments(result.positive, negativeGeometry, positiveGeometry, axisX, axisY, coord, minCoord, maxCoord);
				positiveNegative = result.positive.negative;
				positivePositive = result.positive.positive;
				result.positive.negative = null;
				result.positive.positive = null;
				result.positive.next = Fragment.collector;
				Fragment.collector = result.positive;
				result.positive = null;
			}
			// Разделение
			var negativeFirst:Fragment;
			var negativeLast:Fragment;
			var positiveFirst:Fragment;
			var positiveLast:Fragment;
			var negative:Fragment = negativeReserve;
			var negativeIndices:Vector.<int> = negative.indices;
			var positive:Fragment = positiveReserve;
			var positiveIndices:Vector.<int> = positive.indices;
			var negativeVertices:Vector.<Number>;
			var negativeUVTs:Vector.<Number>;
			var positiveVertices:Vector.<Number>;
			var positiveUVTs:Vector.<Number>;
			var negV:int;
			var negVi:int;
			var posV:int;
			var posVi:int;
			if (innegative) {
				negativeVertices = negativeGeometry.vertices;
				negativeUVTs = negativeGeometry.uvts;
				negV = negativeGeometry.numVertices;
				negVi = negativeGeometry.verticesLength;
			}
			if (inpositive) {
				positiveVertices = positiveGeometry.vertices;
				positiveUVTs = positiveGeometry.uvts;
				posV = positiveGeometry.numVertices;
				posVi = positiveGeometry.verticesLength;
			}
			while (fragment != null) {
				var next:Fragment = fragment.next;
				if (fragment.num > 0) {
					var indices:Vector.<int> = fragment.indices;
					var num:int = fragment.num;
					var infront:Boolean = false;
					var behind:Boolean = false;
					var negativeNum:int = 0;
					var positiveNum:int = 0;
					// Первая точка ребра
					var n:int = num - 1;
					var a:int = indices[n];
					var ai:int = a*3;
					var ax:Number = vertices[ai]; n = ai + 1;
					var ay:Number = vertices[n]; n++;
					var az:Number = vertices[n];
					var ac:Number = axisX ? ax : (axisY ? ay : az);
					for (var i:int = 0; i < num; i++) {
						// Вторая точка ребра
						var b:int = indices[i];
						var bi:int = b*3;
						var bx:Number = vertices[bi]; n = bi + 1;
						var by:Number = vertices[n]; n++;
						var bz:Number = vertices[n];
						var bc:Number = axisX ? bx : (axisY ? by : bz);
						// Рассечение ребра
						if (split && (bc > maxCoord && ac < minCoord || bc < minCoord && ac > maxCoord) || crop && (innegative && (ac < coord && bc >= coord || bc < coord && ac >= coord) || inpositive && (ac <= coord && bc > coord || bc <= coord && ac > coord))) {
							var t:Number = (ac - coord)/(ac - bc);
							var au:Number = uvts[ai]; ai++;
							var av:Number = uvts[ai];
							var bu:Number = uvts[bi]; n = bi + 1;
							var bv:Number = uvts[n];
							var x:Number = ax + (bx - ax)*t;
							var y:Number = ay + (by - ay)*t;
							var z:Number = az + (bz - az)*t;
							var u:Number = au + (bu - au)*t;
							var v:Number = av + (bv - av)*t;
							if (innegative) {
								negativeVertices[negVi] = x;
								negativeUVTs[negVi] = u; negVi++;
								negativeVertices[negVi] = y;
								negativeUVTs[negVi] = v; negVi++;
								negativeVertices[negVi] = z;
								negativeUVTs[negVi] = 0; negVi++;
								negativeIndices[negativeNum] = negV; negativeNum++; negV++;
							}
							if (inpositive) {
								positiveVertices[posVi] = x;
								positiveUVTs[posVi] = u; posVi++;
								positiveVertices[posVi] = y;
								positiveUVTs[posVi] = v; posVi++;
								positiveVertices[posVi] = z;
								positiveUVTs[posVi] = 0; posVi++;
								positiveIndices[positiveNum] = posV; positiveNum++; posV++;
							}
						}
						// Добавление точки
						if (split && bc < minCoord || crop && innegative && bc < coord) {
							if (verticesMap[b] < 0) {
								negativeVertices[negVi] = bx;
								negativeUVTs[negVi] = uvts[bi]; negVi++;
								negativeVertices[negVi] = by; n = bi + 1;
								negativeUVTs[negVi] = uvts[n]; negVi++;
								negativeVertices[negVi] = bz;
								negativeUVTs[negVi] = 0; negVi++;
								negativeIndices[negativeNum] = negV; negativeNum++;
								verticesMap[b] = negV; negV++;
							} else {
								negativeIndices[negativeNum] = verticesMap[b]; negativeNum++;
							}
							behind = true;
						} else if (split && bc > maxCoord || crop && inpositive && bc > coord) {
							if (verticesMap[b] < 0) {
								positiveVertices[posVi] = bx;
								positiveUVTs[posVi] = uvts[bi]; posVi++;
								positiveVertices[posVi] = by; n = bi + 1;
								positiveUVTs[posVi] = uvts[n]; posVi++;
								positiveVertices[posVi] = bz;
								positiveUVTs[posVi] = 0; posVi++;
								positiveIndices[positiveNum] = posV; positiveNum++;
								verticesMap[b] = posV; posV++;
							} else {
								positiveIndices[positiveNum] = verticesMap[b]; positiveNum++;
							}
							infront = true;
						} else if (split) {
							negativeVertices[negVi] = bx;
							positiveVertices[posVi] = bx;
							negativeUVTs[negVi] = uvts[bi]; negVi++;
							positiveUVTs[posVi] = uvts[bi]; posVi++;
							negativeVertices[negVi] = by;
							positiveVertices[posVi] = by; n = bi + 1;
							negativeUVTs[negVi] = uvts[n]; negVi++;
							positiveUVTs[posVi] = uvts[n]; posVi++;
							negativeVertices[negVi] = bz;
							positiveVertices[posVi] = bz;
							negativeUVTs[negVi] = 0; negVi++;
							positiveUVTs[posVi] = 0; posVi++;
							negativeIndices[negativeNum] = negV; negativeNum++;
							positiveIndices[positiveNum] = posV; positiveNum++;
							verticesMap[b] = negV; negV++;
							verticesMap[b] = posV; posV++;
						}
						a = b;
						ai = bi;
						ax = bx;
						ay = by;
						az = bz;
						ac = bc;
					}
					// Анализ разбиения
					if (behind) {
						negativeGeometry.numVertices = negV;
						negativeGeometry.verticesLength = negVi;
						negative.num = negativeNum;
						if (sorting == 2) {
							negative.normalX = fragment.normalX;
							negative.normalY = fragment.normalY;
							negative.normalZ = fragment.normalZ;
							negative.offset = fragment.offset;
						}
						if (negativeFirst != null) {
							negativeLast.next = negative;
						} else {
							negativeFirst = negative;
						}
						negativeLast = negative;
						negativeReserve = fragment.create();
						negative = negativeReserve;
						negativeIndices = negative.indices;
					} else if (negativeNum > 0) {
						negV = negativeGeometry.numVertices;
						negVi = negativeGeometry.verticesLength;
					}
					if (infront || split && !behind && !infront) {
						positiveGeometry.numVertices = posV;
						positiveGeometry.verticesLength = posVi;
						positive.num = positiveNum;
						if (sorting == 2) {
							positive.normalX = fragment.normalX;
							positive.normalY = fragment.normalY;
							positive.normalZ = fragment.normalZ;
							positive.offset = fragment.offset;
						}
						if (positiveFirst != null) {
							positiveLast.next = positive;
						} else {
							positiveFirst = positive;
						}
						positiveLast = positive;
						positiveReserve = fragment.create();
						positive = positiveReserve;
						positiveIndices = positive.indices;
					} else if (positiveNum > 0) {
						posV = positiveGeometry.numVertices;
						posVi = positiveGeometry.verticesLength;
					}
				}
				if (fragment != result) {
					fragment.next = Fragment.collector;
					Fragment.collector = fragment;
				}
				fragment = next;
			}
			// Если сзади от сплита есть фрагменты или обе дочерние ноды
			if (negativeFirst != null || negativeNegative != null && positiveNegative != null) {
				if (negativeFirst == null) {
					negativeFirst = result.create();
				}
				if (sorting == 3) {
					negativeFirst.normalX = result.normalX;
					negativeFirst.normalY = result.normalY;
					negativeFirst.normalZ = result.normalZ;
					negativeFirst.offset = result.offset;
				}
				result.negative = negativeFirst;
				negativeFirst.negative = negativeNegative;
				negativeFirst.positive = positiveNegative;
			} else {
				result.negative = (negativeNegative != null) ? negativeNegative : positiveNegative;
			}
			// Если сзади от сплита есть фрагменты или обе дочерние ноды
			if (positiveFirst != null || negativePositive != null && positivePositive != null) {
				if (positiveFirst == null) {
					positiveFirst = result.create();
				}
				if (sorting == 3) {
					positiveFirst.normalX = result.normalX;
					positiveFirst.normalY = result.normalY;
					positiveFirst.normalZ = result.normalZ;
					positiveFirst.offset = result.offset;
				}
				result.positive = positiveFirst;
				positiveFirst.negative = negativePositive;
				positiveFirst.positive = positivePositive;
			} else {
				result.positive = (negativePositive != null) ? negativePositive : positivePositive;
			}
		}
		
		public function draw(camera:Camera3D, parentCanvas:Canvas, threshold:Number, matrix:Matrix3D = null):void {
			var i:int;
			var j:int;
			var a:int;
			var b:int;
			var c:int;
			var indices:Vector.<int>;
			var num:int;
			var current:Fragment;
			var last:Fragment;
			// Перевод в камеру
			if (matrix != null) {
				vertices.length = verticesLength;
				matrix.transformVectors(vertices, vertices);
			}
			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, alpha, blendMode, colorTransform, filters);
			if (viewAligned) {
				// Отрисовка
				canvas.gfx.beginBitmapFill(texture, textureMatrix, false, smooth);
				var x:Number = vertices[0]*projectionX;
				var y:Number = vertices[1]*projectionY;
				canvas.gfx.moveTo(x, y);
				for (i = 3; i < verticesLength; i++) {
					x = vertices[i]*projectionX; i++;
					y = vertices[i]*projectionY; i++;
					canvas.gfx.lineTo(x, y);
				}
				fragment.next = Fragment.collector;
				Fragment.collector = fragment;
			} else {
				// Сброс
				drawIndicesLength = 0;
				// Без сортировки
				if (sorting == 0) {
					current = fragment;
					do {
						indices = current.indices;
						num = current.num;
						a = indices[0];
						b = indices[1];
						for (i = 2; i < num; i++) {
							drawIndices[drawIndicesLength] = a;
							drawIndicesLength++;
							drawIndices[drawIndicesLength] = b;
							drawIndicesLength++;
							c = indices[i];
							drawIndices[drawIndicesLength] = c;
							drawIndicesLength++;
							b = c;
						}
						last = current;
						current = current.next;
					} while (current != null);
					last.next = Fragment.collector;
					Fragment.collector = fragment;
				// Сортировка по средним Z
				} else if (sorting == 1) {
					var fragments:Vector.<Fragment> = sortingFragments;
					var fragmentsLength:int = 0;
					// Заполнение вектора
					current = fragment;
					do {
						indices = current.indices;
						num = current.num;
						var sum:Number = 0;
						for (i = 0; i < num; i++) {
							var vi:int = indices[i]*3 + 2;
							sum += vertices[vi];
						}
						current.offset = sum/num;
						fragments[fragmentsLength] = current;
						fragmentsLength++;
						last = current;
						current = current.next;
					} while (current != null);
					// Сортировка
					var stack:Vector.<int> = sortingStack;
					stack[0] = 0;
					stack[1] = fragmentsLength - 1;
					var index:int = 2;
					while (index > 0) {
						index--;
						var r:int = stack[index];
						j = r;
						index--;
						var l:int = stack[index];
						i = l;
						var k:int = r + l;
						var t:int = k >> 1;
						current = fragments[t];
						var median:Number = current.offset;
						while (i <= j) {
			 				var left:Fragment = fragments[i];
			 				while (left.offset > median) {
			 					i++;
			 					left = fragments[i];
			 				}
			 				var right:Fragment = fragments[j];
			 				while (right.offset < median) {
			 					j--;
				 				right = fragments[j];
				 			}
			 				if (i <= j) {
			 					fragments[i] = right;
			 					fragments[j] = left;
			 					i++;
			 					j--;
			 				}
			 			}
						if (l < j) {
							stack[index] = l;
							index++;
							stack[index] = j;
							index++;
						}
						if (i < r) {
							stack[index] = i;
							index++;
							stack[index] = r;
							index++;
						}
					}
					// Сбор
					for (i = 0; i < fragmentsLength; i++) {
						current = fragments[i];
						indices = current.indices;
						num = current.num;
						a = indices[0];
						b = indices[1];
						for (j = 2; j < num; j++) {
							drawIndices[drawIndicesLength] = a;
							drawIndicesLength++;
							drawIndices[drawIndicesLength] = b;
							drawIndicesLength++;
							c = indices[j];
							drawIndices[drawIndicesLength] = c;
							drawIndicesLength++;
							b = c;
						}
						fragments[i] = null;
					}
					last.next = Fragment.collector;
					Fragment.collector = fragment;
				// Динамическое BSP
				} else if (sorting == 2) {
					current = fragment.next;
					fragment.next = null;
					drawDynamicNode(fragment, current, threshold);
				// Статическое BSP
				} else {
					drawStaticNode(fragment);
				}
				// Проецирование
				vertices.length = verticesLength;
				uvts.length = verticesLength;
				projectedVertices.length = numVertices << 1;
				Utils3D.projectVectors(camera.projectionMatrix, vertices, projectedVertices, uvts);
				// Отрисовка
				canvas.gfx.beginBitmapFill(texture, null, repeatTexture, smooth);
				drawIndices.length = drawIndicesLength;
				camera.numTriangles += drawIndicesLength/3;
				canvas.gfx.drawTriangles(projectedVertices, drawIndices, uvts, "none");
			}
			fragment = null;
		}
		
		public function drawPart(camera:Camera3D, parentCanvas:Canvas, fragment:Fragment):void {
			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, alpha, blendMode, colorTransform, filters);
			var i:int;
			var a:int;
			var b:int;
			var c:int;
			var current:Fragment;
			var last:Fragment;
			var indices:Vector.<int>;
			var num:int;
			if (viewAligned) {
				// Отрисовка
				canvas.gfx.beginBitmapFill(texture, textureMatrix, false, smooth);
				current = fragment;
				do {
					indices = current.indices;
					num = current.num;
					a = indices[0]*3;
					var x:Number = vertices[a]*projectionX; a++;
					var y:Number = vertices[a]*projectionY;
					canvas.gfx.moveTo(x, y);
					for (i = 1; i < num; i++) {
						a = indices[i]*3;
						x = vertices[a]*projectionX; a++;
						y = vertices[a]*projectionY;
						canvas.gfx.lineTo(x, y);
					}
					current.geometry = null;
					last = current;
					current = current.next;
				} while (current != null);
			} else {
				// Сброс
				drawIndicesLength = 0;
				// Перебор
				current = fragment;
				do {
					indices = current.indices;
					num = current.num;
					a = indices[0];
					b = indices[1];
					for (i = 2; i < num; i++) {
						drawIndices[drawIndicesLength] = a;
						drawIndicesLength++;
						drawIndices[drawIndicesLength] = b;
						drawIndicesLength++;
						c = indices[i];
						drawIndices[drawIndicesLength] = c;
						drawIndicesLength++;
						b = c;
					}
					current.geometry = null;
					last = current;
					current = current.next;
				} while (current != null);
				// Отрисовка
				canvas.gfx.beginBitmapFill(texture, null, repeatTexture, smooth);
				drawIndices.length = drawIndicesLength;
				camera.numTriangles += drawIndicesLength/3;
				canvas.gfx.drawTriangles(projectedVertices, drawIndices, uvts, "none");
			}
			last.next = Fragment.collector;
			Fragment.collector = fragment;
		}

		private function drawStaticNode(splitter:Fragment):void {
			var negative:Fragment = splitter.negative;
			var positive:Fragment = splitter.positive;
			splitter.negative = null;
			splitter.positive = null;
			if (splitter.offset < 0) {
				if (negative != null) {
					drawStaticNode(negative);
				}
				if (splitter.num > 0) {
					var current:Fragment = splitter;
					var last:Fragment;
					do {
						var indices:Vector.<int> = current.indices;
						var num:int = current.num;
						var a:int = indices[0];
						var b:int = indices[1];
						for (var i:int = 2; i < num; i++) {
							drawIndices[drawIndicesLength] = a;
							drawIndicesLength++;
							drawIndices[drawIndicesLength] = b;
							drawIndicesLength++;
							var c:int = indices[i];
							drawIndices[drawIndicesLength] = c;
							drawIndicesLength++;
							b = c;
						}
						last = current;
						current = current.next;
					} while (current != null);
					last.next = Fragment.collector;
					Fragment.collector = splitter;
				} else {
					splitter.next = Fragment.collector;
					Fragment.collector = splitter;
				}
				if (positive != null) {
					drawStaticNode(positive);
				}
			} else {
				if (positive != null) {
					drawStaticNode(positive);
				}
				splitter.next = Fragment.collector;
				Fragment.collector = splitter;
				if (negative != null) {
					drawStaticNode(negative);
				}
			}
		}

		private function drawDynamicNode(splitter:Fragment, source:Fragment, threshold:Number):void {
			var negative:Fragment = negativeReserve;
			var negativeIndices:Vector.<int> = negative.indices;
			var positive:Fragment = positiveReserve;
			var positiveIndices:Vector.<int> = positive.indices;
			var next:Fragment;
			var negativeFirst:Fragment;
			var negativeLast:Fragment;
			var splitterLast:Fragment = splitter;
			var positiveFirst:Fragment;
			var positiveLast:Fragment;
			var normalX:Number = splitter.normalX;
			var normalY:Number = splitter.normalY;
			var normalZ:Number = splitter.normalZ;
			var offset:Number = splitter.offset;
			var i:int;
			var a:int;
			var b:int;
			var c:int;
			var indices:Vector.<int>;
			var num:int;
			// Перебор входной последовательности
			while (source != null) {
				next = source.next;
				indices = source.indices;
				num = source.num;
				var infront:Boolean = false;
				var behind:Boolean = false;
				var negativeNum:int = 0;
				var positiveNum:int = 0;
				// Первая точка ребра
				var n:int = num - 1;
				a = indices[n];
				var ai:int = a*3;
				var ax:Number = vertices[ai]; n = ai + 1;
				var ay:Number = vertices[n]; n++;
				var az:Number = vertices[n];
				var ao:Number = ax*normalX + ay*normalY + az*normalZ - offset;
				for (i = 0; i < num; i++) {
					// Вторая точка ребра
					b = indices[i];
					var bi:int = b*3;
					var bx:Number = vertices[bi]; n = bi + 1;
					var by:Number = vertices[n]; n++;
					var bz:Number = vertices[n];
					var bo:Number = bx*normalX + by*normalY + bz*normalZ - offset;
					// Рассечение ребра
					if (ao < -threshold && bo > threshold || bo < -threshold && ao > threshold) {
						var t:Number = ao/(ao - bo);
						var au:Number = uvts[ai]; ai++;
						var av:Number = uvts[ai];
						var bu:Number = uvts[bi]; n = bi + 1;
						var bv:Number = uvts[n];
						vertices[verticesLength] = ax + (bx - ax)*t;
						uvts[verticesLength] = au + (bu - au)*t; verticesLength++;
						vertices[verticesLength] = ay + (by - ay)*t;
						uvts[verticesLength] = av + (bv - av)*t; verticesLength++;
						vertices[verticesLength] = az + (bz - az)*t;
						uvts[verticesLength] = 0; verticesLength++;
						negativeIndices[negativeNum] = numVertices;
						negativeNum++;
						positiveIndices[positiveNum] = numVertices;
						positiveNum++;
						numVertices++;
					}
					// Добавление точки
					if (bo < -threshold) {
						negativeIndices[negativeNum] = b;
						negativeNum++;
						behind = true;
					} else if (bo > threshold) {
						positiveIndices[positiveNum] = b;
						positiveNum++;
						infront = true;
					} else {
						negativeIndices[negativeNum] = b;
						negativeNum++;
						positiveIndices[positiveNum] = b;
						positiveNum++;
					}
					a = b;
					ai = bi;
					ax = bx;
					ay = by;
					az = bz;
					ao = bo;
				}
				// Анализ разбиения
				if (behind && infront) {
					negative.num = negativeNum;
					positive.num = positiveNum;
					negative.normalX = source.normalX;
					negative.normalY = source.normalY;
					negative.normalZ = source.normalZ;
					negative.offset = source.offset;
					positive.normalX = source.normalX;
					positive.normalY = source.normalY;
					positive.normalZ = source.normalZ;
					positive.offset = source.offset;
					if (negativeFirst != null) {
						negativeLast.next = negative;
					} else {
						negativeFirst = negative;
					}
					negativeLast = negative;
					if (positiveFirst != null) {
						positiveLast.next = positive;
					} else {
						positiveFirst = positive;
					}
					positiveLast = positive;
					negativeReserve = source.create();
					positiveReserve = source.create();
					negative = negativeReserve;
					negativeIndices = negative.indices;
					positive = positiveReserve;
					positiveIndices = positive.indices;
					source.next = Fragment.collector;
					Fragment.collector = source;
				} else if (behind) {
					source.next = null;
					if (negativeFirst != null) {
						negativeLast.next = source;
					} else {
						negativeFirst = source;
					}
					negativeLast = source;
				} else if (infront) {
					source.next = null;
					if (positiveFirst != null) {
						positiveLast.next = source;
					} else {
						positiveFirst = source;
					}
					positiveLast = source;
				} else {
					source.next = null;
					splitterLast.next = source;
					splitterLast = source;
				}
				source = next;
			}
			// Сбор задней части
			if (negativeFirst != negativeLast) {
				next = negativeFirst.next;
				negativeFirst.next = null;
				drawDynamicNode(negativeFirst, next, threshold);
			} else if (negativeFirst != null) {
				negativeFirst.next = splitter;
				splitter = negativeFirst;
			}
			// Если в передней части только один фрагмент
			if (positiveFirst != null && positiveFirst == positiveLast) {
				splitterLast.next = positiveFirst;
				splitterLast = positiveFirst;
				positiveFirst = null;
			}
			// Отрисовка
			next = splitter;
			do {
				indices = next.indices;
				num = next.num;
				a = indices[0];
				b = indices[1];
				for (i = 2; i < num; i++) {
					drawIndices[drawIndicesLength] = a;
					drawIndicesLength++;
					drawIndices[drawIndicesLength] = b;
					drawIndicesLength++;
					c = indices[i];
					drawIndices[drawIndicesLength] = c;
					drawIndicesLength++;
					b = c;
				}
				next = next.next;
			} while (next != null);
			splitterLast.next = Fragment.collector;
			Fragment.collector = splitter;
			// Сбор передней части
			if (positiveFirst != null) {
				next = positiveFirst.next;
				positiveFirst.next = null;
				drawDynamicNode(positiveFirst, next, threshold);
			}
		}

		public function debug(camera:Camera3D, container:Object3D, parentCanvas:Canvas, threshold:Number, bb:int, matrix:Matrix3D = null):void {
			if (debugResult == 0) return;
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false);
			if (debugResult & Debug.EDGES) {
				if (matrix != null) {
					matrix = matrix.clone();
				} else {
					matrix = new Matrix3D();
				}
				var i:int;
				var k:int;
				var vi:int;
				var num:int;
				var x:Number;
				var y:Number;
				var current:Fragment;
				// Перевод в камеру
				vertices.length = verticesLength;
				matrix.transformVectors(vertices, vertices);
				if (viewAligned && (debugResult & Debug.BOUNDS) && bb == 2) {
					canvas.gfx.lineStyle(0, 0xFF9900);
				} else {
					canvas.gfx.lineStyle(0, 0xFFFFFF);
				}
				// Сброс
				drawIndicesLength = 0;
				// Динамическое BSP
				if (sorting == 2 && !viewAligned) {
					// Клонирование списка 
					var first:Fragment;
					var last:Fragment;
					current = fragment;
					while (current != null) {
						if (first != null) {
							last.next = last.create();
							last = last.next;
						} else {
							first = Fragment.create();
							last = first;
						}
						for (i = 0; i < current.num; i++) {
							last.indices[i] = current.indices[i];
						}
						last.num = current.num;
						last.normalX = current.normalX;
						last.normalY = current.normalY;
						last.normalZ = current.normalZ;
						last.offset = current.offset;
						current = current.next;
					}
					var numVerts:int = numVertices;
					// Сбор
					current = first.next;
					first.next = null;
					debugDynamicNode(first, current, threshold, canvas);
					// Проецирование
					vertices.length = verticesLength;
					Utils3D.projectVectors(camera.projectionMatrix, vertices, projectedVertices, uvts);
					// Отрисовка
					for (i = 0, k = 0; i < drawIndicesLength; i++) {
						if (i == k) {
							num = drawIndices[i];
							i++;
							k += num;
							vi = drawIndices[k] << 1;
							x = projectedVertices[vi]; vi++;
							y = projectedVertices[vi];
							canvas.gfx.moveTo(x, y);
							k++;
						}
						vi = drawIndices[i] << 1;
						x = projectedVertices[vi]; vi++;
						y = projectedVertices[vi];
						canvas.gfx.lineTo(x, y);
					}
					numVertices = numVerts;
					verticesLength = numVerts*3;
				} else {
					// Проецирование
					Utils3D.projectVectors(camera.projectionMatrix, vertices, projectedVertices, uvts);
					// Без сортировки
					if (sorting == 0 || sorting == 1 || viewAligned) {
						current = fragment;
						while (current != null) {
							k = current.num - 1;
							vi = current.indices[k] << 1;
							x = projectedVertices[vi]; vi++;
							y = projectedVertices[vi];
							canvas.gfx.moveTo(x, y);
							for (i = 0; i < current.num; i++) {
								vi = current.indices[i] << 1;
								x = projectedVertices[vi]; vi++;
								y = projectedVertices[vi];
								canvas.gfx.lineTo(x, y);
							}
							current = current.next;
						}
					// Статическое BSP
					} else {
						debugStaticNode(fragment, canvas);
					}
				}
				matrix.invert();
				matrix.transformVectors(vertices, vertices);
			}
			if (debugResult & Debug.BOUNDS) {
				if (bb > 0) {
					var containerBoundBox:BoundBox = container._boundBox;
					container._boundBox = new BoundBox();
					if (bb == 1) {
						container._boundBox.minX = minX;
						container._boundBox.minY = minY;
						container._boundBox.minZ = minZ;
						container._boundBox.maxX = maxX;
						container._boundBox.maxY = maxY;
						container._boundBox.maxZ = maxZ;
						container.drawBoundBox(camera, canvas, 0x99FF00);
					} else if (bb == 2 && !viewAligned) {
						var containerCameraMatrix:Matrix3D = container.cameraMatrix;
						container.cameraMatrix = cameraMatrix;
						inverseCameraMatrix.identity();
						inverseCameraMatrix.prepend(cameraMatrix);
						inverseCameraMatrix.invert();
						inverseCameraMatrix.transformVectors(points, points);
						container._boundBox.infinity();
						for (i = 0; i < 24;) {
							var c:Number = points[i]; i++;
							if (c < container._boundBox.minX) container._boundBox.minX = c;
							if (c > container._boundBox.maxX) container._boundBox.maxX = c;
							c = points[i]; i++;
							if (c < container._boundBox.minY) container._boundBox.minY = c;
							if (c > container._boundBox.maxY) container._boundBox.maxY = c;
							c = points[i]; i++;
							if (c < container._boundBox.minZ) container._boundBox.minZ = c;
							if (c > container._boundBox.maxZ) container._boundBox.maxZ = c;
						}
						container.drawBoundBox(camera, canvas, 0xFF9900);
						container.cameraMatrix = containerCameraMatrix;
					}
					container._boundBox = containerBoundBox;
				}
			}
		}

		public function debugPart(camera:Camera3D, canvas:Canvas, fragment:Fragment):void {
			if (debugResult & Debug.EDGES) {
				while (fragment != null) {
					var k:int = fragment.num - 1;
					var vi:int = fragment.indices[k] << 1;
					var x:Number = projectedVertices[vi]; vi++;
					var y:Number = projectedVertices[vi];
					canvas.gfx.moveTo(x, y);
					for (var i:int = 0; i < fragment.num; i++) {
						vi = fragment.indices[i] << 1;
						x = projectedVertices[vi]; vi++;
						y = projectedVertices[vi];
						canvas.gfx.lineTo(x, y);
					}
					fragment = fragment.next;
				}
			}
		}

		private function debugStaticNode(splitter:Fragment, canvas:Canvas):void {
			if (splitter.negative != null) {
				debugStaticNode(splitter.negative, canvas);
			}
			if (splitter.positive != null) {
				debugStaticNode(splitter.positive, canvas);
			}
			if (splitter.num > 0) {
				var current:Fragment = splitter;
				while (current != null) {
					var k:int = current.num - 1;
					var vi:int = current.indices[k] << 1;
					var x:Number = projectedVertices[vi]; vi++;
					var y:Number = projectedVertices[vi];
					canvas.gfx.moveTo(x, y);
					for (var i:int = 0; i < current.num; i++) {
						vi = current.indices[i] << 1;
						x = projectedVertices[vi]; vi++;
						y = projectedVertices[vi];
						canvas.gfx.lineTo(x, y);
					}
					current = current.next;
				}
			}
		}

		private function debugDynamicNode(splitter:Fragment, source:Fragment, threshold:Number, canvas:Canvas):void {
			var negative:Fragment = negativeReserve;
			var negativeIndices:Vector.<int> = negative.indices;
			var positive:Fragment = positiveReserve;
			var positiveIndices:Vector.<int> = positive.indices;
			var next:Fragment;
			var negativeFirst:Fragment;
			var negativeLast:Fragment;
			var splitterLast:Fragment = splitter;
			var positiveFirst:Fragment;
			var positiveLast:Fragment;
			var normalX:Number = splitter.normalX;
			var normalY:Number = splitter.normalY;
			var normalZ:Number = splitter.normalZ;
			var offset:Number = splitter.offset;
			var i:int;
			var a:int;
			var b:int;
			var c:int;
			var indices:Vector.<int>;
			var num:int;
			// Перебор входной последовательности
			while (source != null) {
				next = source.next;
				indices = source.indices;
				num = source.num;
				var infront:Boolean = false;
				var behind:Boolean = false;
				var negativeNum:int = 0;
				var positiveNum:int = 0;
				// Первая точка ребра
				var n:int = num - 1;
				a = indices[n];
				var ai:int = a*3;
				var ax:Number = vertices[ai]; n = ai + 1;
				var ay:Number = vertices[n]; n++;
				var az:Number = vertices[n];
				var ao:Number = ax*normalX + ay*normalY + az*normalZ - offset;
				for (i = 0; i < num; i++) {
					// Вторая точка ребра
					b = indices[i];
					var bi:int = b*3;
					var bx:Number = vertices[bi]; n = bi + 1;
					var by:Number = vertices[n]; n++;
					var bz:Number = vertices[n];
					var bo:Number = bx*normalX + by*normalY + bz*normalZ - offset;
					// Рассечение ребра
					if (ao < -threshold && bo > threshold || bo < -threshold && ao > threshold) {
						var t:Number = ao/(ao - bo);
						var au:Number = uvts[ai]; ai++;
						var av:Number = uvts[ai];
						var bu:Number = uvts[bi]; n = bi + 1;
						var bv:Number = uvts[n];
						vertices[verticesLength] = ax + (bx - ax)*t;
						uvts[verticesLength] = au + (bu - au)*t; verticesLength++;
						vertices[verticesLength] = ay + (by - ay)*t;
						uvts[verticesLength] = av + (bv - av)*t; verticesLength++;
						vertices[verticesLength] = az + (bz - az)*t;
						uvts[verticesLength] = 0; verticesLength++;
						negativeIndices[negativeNum] = numVertices;
						negativeNum++;
						positiveIndices[positiveNum] = numVertices;
						positiveNum++;
						numVertices++;
					}
					// Добавление точки
					if (bo < -threshold) {
						negativeIndices[negativeNum] = b;
						negativeNum++;
						behind = true;
					} else if (bo > threshold) {
						positiveIndices[positiveNum] = b;
						positiveNum++;
						infront = true;
					} else {
						negativeIndices[negativeNum] = b;
						negativeNum++;
						positiveIndices[positiveNum] = b;
						positiveNum++;
					}
					a = b;
					ai = bi;
					ax = bx;
					ay = by;
					az = bz;
					ao = bo;
				}
				// Анализ разбиения
				if (behind && infront) {
					negative.num = negativeNum;
					positive.num = positiveNum;
					negative.normalX = source.normalX;
					negative.normalY = source.normalY;
					negative.normalZ = source.normalZ;
					negative.offset = source.offset;
					positive.normalX = source.normalX;
					positive.normalY = source.normalY;
					positive.normalZ = source.normalZ;
					positive.offset = source.offset;
					if (negativeFirst != null) {
						negativeLast.next = negative;
					} else {
						negativeFirst = negative;
					}
					negativeLast = negative;
					if (positiveFirst != null) {
						positiveLast.next = positive;
					} else {
						positiveFirst = positive;
					}
					positiveLast = positive;
					negativeReserve = source.create();
					positiveReserve = source.create();
					negative = negativeReserve;
					negativeIndices = negative.indices;
					positive = positiveReserve;
					positiveIndices = positive.indices;
					source.next = Fragment.collector;
					Fragment.collector = source;
				} else if (behind) {
					source.next = null;
					if (negativeFirst != null) {
						negativeLast.next = source;
					} else {
						negativeFirst = source;
					}
					negativeLast = source;
				} else if (infront) {
					source.next = null;
					if (positiveFirst != null) {
						positiveLast.next = source;
					} else {
						positiveFirst = source;
					}
					positiveLast = source;
				} else {
					source.next = null;
					splitterLast.next = source;
					splitterLast = source;
				}
				source = next;
			}
			// Сбор задней части
			if (negativeFirst != negativeLast) {
				next = negativeFirst.next;
				negativeFirst.next = null;
				debugDynamicNode(negativeFirst, next, threshold, canvas);
			} else if (negativeFirst != null) {
				negativeFirst.next = splitter;
				splitter = negativeFirst;
			}
			// Если в передней части только один фрагмент
			if (positiveFirst != null && positiveFirst == positiveLast) {
				splitterLast.next = positiveFirst;
				splitterLast = positiveFirst;
				positiveFirst = null;
			}
			// Отрисовка
			next = splitter;
			do {
				indices = next.indices;
				num = next.num;
				drawIndices[drawIndicesLength] = num;
				drawIndicesLength++;
				for (i = 0; i < num; i++) {
					drawIndices[drawIndicesLength] = indices[i];
					drawIndicesLength++;
				}
				next = next.next;
			} while (next != null);
			splitterLast.next = Fragment.collector;
			Fragment.collector = splitter;
			// Сбор передней части
			if (positiveFirst != null) {
				next = positiveFirst.next;
				positiveFirst.next = null;
				debugDynamicNode(positiveFirst, next, threshold, canvas);
			}
		}
		
	}
}
