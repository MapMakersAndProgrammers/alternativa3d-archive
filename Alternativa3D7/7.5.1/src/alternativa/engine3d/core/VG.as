package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.ColorTransform;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class VG {
	
		alternativa3d var next:VG;
	
		alternativa3d var faceStruct:Face;
	
		// Передаваемые при сплите свойства
		alternativa3d var object:Object3D;
		alternativa3d var alpha:Number;
		alternativa3d var blendMode:String;
		alternativa3d var colorTransform:ColorTransform;
		alternativa3d var filters:Array;
		alternativa3d var sorting:int;
		alternativa3d var debug:int = 0;
		alternativa3d var space:int = 0;
		alternativa3d var viewAligned:Boolean = false;
		alternativa3d var tma:Number;
		alternativa3d var tmb:Number;
		alternativa3d var tmc:Number;
		alternativa3d var tmd:Number;
		alternativa3d var tmtx:Number;
		alternativa3d var tmty:Number;
	
		// AABB
		alternativa3d var boundMinX:Number;
		alternativa3d var boundMinY:Number;
		alternativa3d var boundMinZ:Number;
		alternativa3d var boundMaxX:Number;
		alternativa3d var boundMaxY:Number;
		alternativa3d var boundMaxZ:Number;
	
		// OOBB
		alternativa3d var boundVertexList:Vertex = Vertex.createList(8);
		alternativa3d var boundPlaneList:Vertex = Vertex.createList(6);
	
		alternativa3d var numOccluders:int;
	
		static private var collector:VG;
	
		static alternativa3d function create(object:Object3D, faceStruct:Face, sorting:int, debug:int, viewAligned:Boolean, a:Number = 1, b:Number = 0, c:Number = 0, d:Number = 1, tx:Number = 0, ty:Number = 0):VG {
			var geometry:VG;
			if (collector != null) {
				geometry = collector;
				collector = collector.next;
				geometry.next = null;
			} else {
				//trace("new VG");
				geometry = new VG();
			}
			geometry.object = object;
			geometry.alpha = object.alpha;
			geometry.blendMode = object.blendMode;
			geometry.colorTransform = object.colorTransform;
			geometry.filters = object.filters;
			geometry.faceStruct = faceStruct;
			geometry.sorting = sorting;
			geometry.debug = debug;
			if (viewAligned) {
				geometry.viewAligned = true;
				geometry.tma = a;
				geometry.tmb = b;
				geometry.tmc = c;
				geometry.tmd = d;
				geometry.tmtx = tx;
				geometry.tmty = ty;
			}
			return geometry;
		}
	
		alternativa3d function destroy():void {
			if (faceStruct != null) {
				destroyFaceStruct(faceStruct);
				faceStruct = null;
			}
			object = null;
			viewAligned = false;
			colorTransform = null;
			filters = null;
			numOccluders = 0;
			debug = 0;
			space = 0;
			next = collector;
			collector = this;
		}
	
		private function destroyFaceStruct(struct:Face):void {
			if (struct.processNegative != null) {
				destroyFaceStruct(struct.processNegative);
				struct.processNegative = null;
			}
			if (struct.processPositive != null) {
				destroyFaceStruct(struct.processPositive);
				struct.processPositive = null;
			}
			for (var next:Face = struct.processNext; next != null; next = struct.processNext) {
				struct.processNext = null;
				struct = next; 
			}
		}
	
		alternativa3d function calculateAABB(a:Number, b:Number, c:Number, d:Number, e:Number, f:Number, g:Number, h:Number, i:Number, j:Number, k:Number, l:Number):void {
			boundMinX = 1e+22;
			boundMinY = 1e+22;
			boundMinZ = 1e+22;
			boundMaxX = -1e+22;
			boundMaxY = -1e+22;
			boundMaxZ = -1e+22;
			calculateAABBStruct(faceStruct, ++object.transformId, a, b, c, d, e, f, g, h, i, j, k, l);
			// Тип баунда
			space = 1;
		}
	
		alternativa3d function calculateOOBB(container:Object3D):void {
			if (space == 1) transformStruct(faceStruct, ++object.transformId, container.ma, container.mb, container.mc, container.md, container.me, container.mf, container.mg, container.mh, container.mi, container.mj, container.mk, container.ml);
			if (viewAligned) {
				
			} else {
				boundMinX = 1e+22;
				boundMinY = 1e+22;
				boundMinZ = 1e+22;
				boundMaxX = -1e+22;
				boundMaxY = -1e+22;
				boundMaxZ = -1e+22;
				calculateOOBBStruct(faceStruct, ++object.transformId, object.ima, object.imb, object.imc, object.imd, object.ime, object.imf, object.img, object.imh, object.imi, object.imj, object.imk, object.iml);
				//calculateOOBBStruct(faceStruct, ++object.transformId);
				// Костыль
				if (boundMaxX - boundMinX < 1) {
					boundMaxX = boundMinX + 1;
				}
				if (boundMaxY - boundMinY < 1) {
					boundMaxY = boundMinY + 1;
				}
				if (boundMaxZ - boundMinZ < 1) {
					boundMaxZ = boundMinZ + 1;
				}
				// Заполнениее вершин баунда
				var a:Vertex = boundVertexList;
				a.x = boundMinX;
				a.y = boundMinY;
				a.z = boundMinZ;
				var b:Vertex = a.next;
				b.x = boundMaxX;
				b.y = boundMinY;
				b.z = boundMinZ;
				var c:Vertex = b.next;
				c.x = boundMinX;
				c.y = boundMaxY;
				c.z = boundMinZ;
				var d:Vertex = c.next;
				d.x = boundMaxX;
				d.y = boundMaxY;
				d.z = boundMinZ;
				var e:Vertex = d.next;
				e.x = boundMinX;
				e.y = boundMinY;
				e.z = boundMaxZ;
				var f:Vertex = e.next;
				f.x = boundMaxX;
				f.y = boundMinY;
				f.z = boundMaxZ;
				var g:Vertex = f.next;
				g.x = boundMinX;
				g.y = boundMaxY;
				g.z = boundMaxZ;
				var h:Vertex = g.next;
				h.x = boundMaxX;
				h.y = boundMaxY;
				h.z = boundMaxZ;
				// Перевод вершин баунда из локальных координат в камеру
				for (var vertex:Vertex = a; vertex != null; vertex = vertex.next) {
					vertex.cameraX = object.ma*vertex.x + object.mb*vertex.y + object.mc*vertex.z + object.md;
					vertex.cameraY = object.me*vertex.x + object.mf*vertex.y + object.mg*vertex.z + object.mh;
					vertex.cameraZ = object.mi*vertex.x + object.mj*vertex.y + object.mk*vertex.z + object.ml;
				}
				// Заполнение плоскостей баунда
				var front:Vertex = boundPlaneList;
				var back:Vertex = front.next;
				var ax:Number = a.cameraX;
				var ay:Number = a.cameraY;
				var az:Number = a.cameraZ;
				var abx:Number = b.cameraX - ax;
				var aby:Number = b.cameraY - ay;
				var abz:Number = b.cameraZ - az;
				var acx:Number = e.cameraX - ax;
				var acy:Number = e.cameraY - ay;
				var acz:Number = e.cameraZ - az;
				var nx:Number = acz*aby - acy*abz;
				var ny:Number = acx*abz - acz*abx;
				var nz:Number = acy*abx - acx*aby;
				var nl:Number = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
				nx *= nl;
				ny *= nl;
				nz *= nl;
				front.cameraX = nx;
				front.cameraY = ny;
				front.cameraZ = nz;
				front.offset = ax*nx + ay*ny + az*nz;
				back.cameraX = -nx;
				back.cameraY = -ny;
				back.cameraZ = -nz;
				back.offset = -c.cameraX*nx - c.cameraY*ny - c.cameraZ*nz;
				var left:Vertex = back.next;
				var right:Vertex = left.next;
				ax = a.cameraX;
				ay = a.cameraY;
				az = a.cameraZ;
				abx = e.cameraX - ax;
				aby = e.cameraY - ay;
				abz = e.cameraZ - az;
				acx = c.cameraX - ax;
				acy = c.cameraY - ay;
				acz = c.cameraZ - az;
				nx = acz*aby - acy*abz;
				ny = acx*abz - acz*abx;
				nz = acy*abx - acx*aby;
				nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
				nx *= nl;
				ny *= nl;
				nz *= nl;
				left.cameraX = nx;
				left.cameraY = ny;
				left.cameraZ = nz;
				left.offset = ax*nx + ay*ny + az*nz;
				right.cameraX = -nx;
				right.cameraY = -ny;
				right.cameraZ = -nz;
				right.offset = -b.cameraX*nx - b.cameraY*ny - b.cameraZ*nz;
				var top:Vertex = right.next;
				var bottom:Vertex = top.next;
				ax = e.cameraX;
				ay = e.cameraY;
				az = e.cameraZ;
				abx = f.cameraX - ax;
				aby = f.cameraY - ay;
				abz = f.cameraZ - az;
				acx = g.cameraX - ax;
				acy = g.cameraY - ay;
				acz = g.cameraZ - az;
				nx = acz*aby - acy*abz;
				ny = acx*abz - acz*abx;
				nz = acy*abx - acx*aby;
				nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
				nx *= nl;
				ny *= nl;
				nz *= nl;
				top.cameraX = nx;
				top.cameraY = ny;
				top.cameraZ = nz;
				top.offset = ax*nx + ay*ny + az*nz;
				bottom.cameraX = -nx;
				bottom.cameraY = -ny;
				bottom.cameraZ = -nz;
				bottom.offset = -a.cameraX*nx - a.cameraY*ny - a.cameraZ*nz;
				// Проверка на вывернутость
				if (front.offset < -back.offset) {
					back.cameraX = -back.cameraX;
					back.cameraY = -back.cameraY;
					back.cameraZ = -back.cameraZ;
					back.offset = -back.offset;
					front.cameraX = -front.cameraX;
					front.cameraY = -front.cameraY;
					front.cameraZ = -front.cameraZ;
					front.offset = -front.offset;
				}
				if (left.offset < -right.offset) {
					left.cameraX = -left.cameraX;
					left.cameraY = -left.cameraY;
					left.cameraZ = -left.cameraZ;
					left.offset = -left.offset;
					right.cameraX = -right.cameraX;
					right.cameraY = -right.cameraY;
					right.cameraZ = -right.cameraZ;
					right.offset = -right.offset;
				}
				if (bottom.offset < -top.offset) {
					bottom.cameraX = -bottom.cameraX;
					bottom.cameraY = -bottom.cameraY;
					bottom.cameraZ = -bottom.cameraZ;
					bottom.offset = -bottom.offset;
					top.cameraX = -top.cameraX;
					top.cameraY = -top.cameraY;
					top.cameraZ = -top.cameraZ;
					top.offset = -top.offset;
				}
			}
			// Тип баунда
			space = 2;
		}
	
		private function calculateAABBStruct(struct:Face, transformId:int, a:Number, b:Number, c:Number, d:Number, e:Number, f:Number, g:Number, h:Number, i:Number, j:Number, k:Number, l:Number):void {
			for (var face:Face = struct; face != null; face = face.processNext) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					if (vertex.transformId != transformId) {
						var cameraX:Number = vertex.cameraX;
						var cameraY:Number = vertex.cameraY;
						var cameraZ:Number = vertex.cameraZ;
						vertex.cameraX = a*cameraX + b*cameraY + c*cameraZ + d;
						vertex.cameraY = e*cameraX + f*cameraY + g*cameraZ + h;
						vertex.cameraZ = i*cameraX + j*cameraY + k*cameraZ + l;
						if (vertex.cameraX < boundMinX) boundMinX = vertex.cameraX;
						if (vertex.cameraX > boundMaxX) boundMaxX = vertex.cameraX;
						if (vertex.cameraY < boundMinY) boundMinY = vertex.cameraY;
						if (vertex.cameraY > boundMaxY) boundMaxY = vertex.cameraY;
						if (vertex.cameraZ < boundMinZ) boundMinZ = vertex.cameraZ;
						if (vertex.cameraZ > boundMaxZ) boundMaxZ = vertex.cameraZ;
						vertex.transformId = transformId;
					}
				}
			}
			if (struct.processNegative != null) calculateAABBStruct(struct.processNegative, transformId, a, b, c, d, e, f, g, h, i, j, k, l);
			if (struct.processPositive != null) calculateAABBStruct(struct.processPositive, transformId, a, b, c, d, e, f, g, h, i, j, k, l);
		}
	
		private function calculateOOBBStruct(struct:Face, transformId:int, a:Number, b:Number, c:Number, d:Number, e:Number, f:Number, g:Number, h:Number, i:Number, j:Number, k:Number, l:Number):void {
			for (var face:Face = struct; face != null; face = face.processNext) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					if (vertex.transformId != transformId) {
						var x:Number = a*vertex.cameraX + b*vertex.cameraY + c*vertex.cameraZ + d;
						var y:Number = e*vertex.cameraX + f*vertex.cameraY + g*vertex.cameraZ + h;
						var z:Number = i*vertex.cameraX + j*vertex.cameraY + k*vertex.cameraZ + l;
						if (x < boundMinX) boundMinX = x;
						if (x > boundMaxX) boundMaxX = x;
						if (y < boundMinY) boundMinY = y;
						if (y > boundMaxY) boundMaxY = y;
						if (z < boundMinZ) boundMinZ = z;
						if (z > boundMaxZ) boundMaxZ = z;
						vertex.transformId = transformId;
					}
				}
			}
			if (struct.processNegative != null) calculateOOBBStruct(struct.processNegative, transformId, a, b, c, d, e, f, g, h, i, j, k, l);
			if (struct.processPositive != null) calculateOOBBStruct(struct.processPositive, transformId, a, b, c, d, e, f, g, h, i, j, k, l);
		}
		
		/*private function calculateOOBBStruct(struct:Face, transformId:int):void {
			for (var face:Face = struct; face != null; face = face.processNext) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					if (vertex.transformId != transformId) {
						if (vertex.x < boundMinX) boundMinX = vertex.x;
						if (vertex.x > boundMaxX) boundMaxX = vertex.x;
						if (vertex.y < boundMinY) boundMinY = vertex.y;
						if (vertex.y > boundMaxY) boundMaxY = vertex.y;
						if (vertex.z < boundMinZ) boundMinZ = vertex.z;
						if (vertex.z > boundMaxZ) boundMaxZ = vertex.z;
						vertex.transformId = transformId;
					}
				}
			}
			if (struct.processNegative != null) calculateOOBBStruct(struct.processNegative, transformId);
			if (struct.processPositive != null) calculateOOBBStruct(struct.processPositive, transformId);
		}*/
	
		private function updateAABBStruct(struct:Face, transformId:int):void {
			for (var face:Face = struct; face != null; face = face.processNext) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					if (vertex.transformId != transformId) {
						if (vertex.cameraX < boundMinX) boundMinX = vertex.cameraX;
						if (vertex.cameraX > boundMaxX) boundMaxX = vertex.cameraX;
						if (vertex.cameraY < boundMinY) boundMinY = vertex.cameraY;
						if (vertex.cameraY > boundMaxY) boundMaxY = vertex.cameraY;
						if (vertex.cameraZ < boundMinZ) boundMinZ = vertex.cameraZ;
						if (vertex.cameraZ > boundMaxZ) boundMaxZ = vertex.cameraZ;
						vertex.transformId = transformId;
					}
				}
			}
			if (struct.processNegative != null) updateAABBStruct(struct.processNegative, transformId);
			if (struct.processPositive != null) updateAABBStruct(struct.processPositive, transformId);
		}
	
		// Сам объект с другим набором граней остаётся спереди, его next указывает на негативную часть
		alternativa3d function split(camera:Camera3D, planeX:Number, planeY:Number, planeZ:Number, planeOffset:Number, threshold:Number):void {
			var result:Face = faceStruct.create();
			splitFaceStruct(camera, faceStruct, result, planeX, planeY, planeZ, planeOffset, planeOffset - threshold, planeOffset + threshold);
			// Копирование свойств
			if (result.processNegative != null) {
				var negative:VG;
				if (collector != null) {
					negative = collector;
					collector = collector.next;
					negative.next = null;
				} else {
					//trace("new VG");
					negative = new VG();
				}
				next = negative;
				negative.faceStruct = result.processNegative;
				result.processNegative = null;
				negative.object = object;
				negative.alpha = alpha;
				negative.blendMode = blendMode;
				negative.colorTransform = colorTransform;
				negative.filters = filters;
				negative.sorting = sorting;
				negative.debug = debug;
				negative.space = space;
				negative.viewAligned = viewAligned;
				if (viewAligned) {
					negative.tma = tma;
					negative.tmb = tmb;
					negative.tmc = tmc;
					negative.tmd = tmd;
					negative.tmtx = tmtx;
					negative.tmty = tmty;
				}
				negative.boundMinX = 1e+22;
				negative.boundMinY = 1e+22;
				negative.boundMinZ = 1e+22;
				negative.boundMaxX = -1e+22;
				negative.boundMaxY = -1e+22;
				negative.boundMaxZ = -1e+22;
				negative.updateAABBStruct(negative.faceStruct, ++object.transformId);
			} else {
				next = null;
			}
			if (result.processPositive != null) {
				faceStruct = result.processPositive;
				result.processPositive = null;
				boundMinX = 1e+22;
				boundMinY = 1e+22;
				boundMinZ = 1e+22;
				boundMaxX = -1e+22;
				boundMaxY = -1e+22;
				boundMaxZ = -1e+22;
				updateAABBStruct(faceStruct, ++object.transformId);
			} else {
				faceStruct = null;
			}
			result.next = Face.collector;
			Face.collector = result;
		}
	
		// Всегда отсекается негативная часть, поэтому если нужно получить негативную, следует перевернуть плоскость
		alternativa3d function crop(camera:Camera3D, planeX:Number, planeY:Number, planeZ:Number, planeOffset:Number, threshold:Number):void {
			faceStruct = cropFaceStruct(camera, faceStruct, planeX, planeY, planeZ, planeOffset, planeOffset - threshold, planeOffset + threshold);
			if (faceStruct != null) {
				boundMinX = 1e+22;
				boundMinY = 1e+22;
				boundMinZ = 1e+22;
				boundMaxX = -1e+22;
				boundMaxY = -1e+22;
				boundMaxZ = -1e+22;
				updateAABBStruct(faceStruct, ++object.transformId);
			}
		}
	
		private function splitFaceStruct(camera:Camera3D, struct:Face, result:Face, normalX:Number, normalY:Number, normalZ:Number, offset:Number, offsetMin:Number, offsetMax:Number):void {
			var face:Face;
			var next:Face;
			var w:Wrapper;
			var v:Vertex;
			var v2:Vertex;
			// Разделение дочерних нод
			var negativeNegative:Face;
			var negativePositive:Face;
			var positiveNegative:Face;
			var positivePositive:Face;
			if (struct.processNegative != null) {
				splitFaceStruct(camera, struct.processNegative, result, normalX, normalY, normalZ, offset, offsetMin, offsetMax);
				struct.processNegative = null;
				negativeNegative = result.processNegative;
				negativePositive = result.processPositive;
			}
			if (struct.processPositive != null) {
				splitFaceStruct(camera, struct.processPositive, result, normalX, normalY, normalZ, offset, offsetMin, offsetMax);
				struct.processPositive = null;
				positiveNegative = result.processNegative;
				positivePositive = result.processPositive;
			}
			// Разделение ноды
			var negativeFirst:Face;
			var negativeLast:Face;
			var positiveFirst:Face;
			var positiveLast:Face;
			var negative:Face;
			var positive:Face;
			var wNegative:Wrapper;
			var wPositive:Wrapper;
			var wNew:Wrapper;
			if (struct.wrapper != null) {
				for (face = struct; face != null; face = next) {
					next = face.processNext;
					w = face.wrapper;
					var a:Vertex = w.vertex;
					w = w.next;
					var b:Vertex = w.vertex;
					w = w.next;
					var c:Vertex = w.vertex;
					w = w.next;
					var ao:Number = a.cameraX*normalX + a.cameraY*normalY + a.cameraZ*normalZ;
					var bo:Number = b.cameraX*normalX + b.cameraY*normalY + b.cameraZ*normalZ;
					var co:Number = c.cameraX*normalX + c.cameraY*normalY + c.cameraZ*normalZ;
					var behind:Boolean = ao < offsetMin || bo < offsetMin || co < offsetMin;
					var infront:Boolean = ao > offsetMax || bo > offsetMax || co > offsetMax;
					var fullBehind:Boolean = ao < offsetMin && bo < offsetMin && co < offsetMin;
					for (; w != null; w = w.next) {
						v = w.vertex;
						var vo:Number = v.cameraX*normalX + v.cameraY*normalY + v.cameraZ*normalZ;
						if (vo < offsetMin) {
							behind = true;
						} else {
							fullBehind = false;
							if (vo > offsetMax) infront = true;
						}
						v.offset = vo;
					}
					if (!behind) {
						if (positiveFirst != null) {
							positiveLast.processNext = face;
						} else {
							positiveFirst = face;
						}
						positiveLast = face;
					} else if (!infront) {
						if (fullBehind) {
							if (negativeFirst != null) {
								negativeLast.processNext = face;
							} else {
								negativeFirst = face;
							}
							negativeLast = face;
						} else {
							a.offset = ao;
							b.offset = bo;
							c.offset = co;
							negative = face.create();
							negative.material = face.material;
							camera.lastFace.next = negative;
							camera.lastFace = negative;
							wNegative = null;
							for (w = face.wrapper; w != null; w = w.next) {
								b = w.vertex;
								if (b.offset >= offsetMin) {
									v2 = b.create();
									camera.lastVertex.next = v2;
									camera.lastVertex = v2;
									v2.x = b.x;
									v2.y = b.y;
									v2.z = b.z;
									v2.u = b.u;
									v2.v = b.v;
									v2.cameraX = b.cameraX;
									v2.cameraY = b.cameraY;
									v2.cameraZ = b.cameraZ;
									b = v2;
								}
								wNew = w.create();
								wNew.vertex = b;
								if (wNegative != null) {
									wNegative.next = wNew;
								} else {
									negative.wrapper = wNew;
								}
								wNegative = wNew;
							}
							if (negativeFirst != null) {
								negativeLast.processNext = negative;
							} else {
								negativeFirst = negative;
							}
							negativeLast = negative;
							face.processNext = null;
						}
					} else {
						a.offset = ao;
						b.offset = bo;
						c.offset = co;
						negative = face.create();
						negative.material = face.material;
						camera.lastFace.next = negative;
						camera.lastFace = negative;
						positive = face.create();
						positive.material = face.material;
						camera.lastFace.next = positive;
						camera.lastFace = positive;
						wNegative = null;
						wPositive = null;
						//for (w = face.wrapper.next.next; w.next != null; w = w.next);
						w = face.wrapper.next.next;
						while (w.next != null) w = w.next;
						a = w.vertex;
						ao = a.offset;
						for (w = face.wrapper; w != null; w = w.next) {
							b = w.vertex;
							bo = b.offset;
							if (ao < offsetMin && bo > offsetMax || ao > offsetMax && bo < offsetMin) {
								var t:Number = (offset - ao)/(bo - ao);
								v = b.create();
								camera.lastVertex.next = v;
								camera.lastVertex = v;
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								v.u = a.u + (b.u - a.u)*t;
								v.v = a.v + (b.v - a.v)*t;
								v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
								v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
								v.cameraZ = a.cameraZ + (b.cameraZ - a.cameraZ)*t;
								wNew = w.create();
								wNew.vertex = v;
								if (wNegative != null) {
									wNegative.next = wNew;
								} else {
									negative.wrapper = wNew;
								}
								wNegative = wNew;
								v2 = b.create();
								camera.lastVertex.next = v2;
								camera.lastVertex = v2;
								v2.x = v.x;
								v2.y = v.y;
								v2.z = v.z;
								v2.u = v.u;
								v2.v = v.v;
								v2.cameraX = v.cameraX;
								v2.cameraY = v.cameraY;
								v2.cameraZ = v.cameraZ;
								wNew = w.create();
								wNew.vertex = v2;
								if (wPositive != null) {
									wPositive.next = wNew;
								} else {
									positive.wrapper = wNew;
								}
								wPositive = wNew;
							}
							if (b.offset < offsetMin) {
								wNew = w.create();
								wNew.vertex = b;
								if (wNegative != null) {
									wNegative.next = wNew;
								} else {
									negative.wrapper = wNew;
								}
								wNegative = wNew;
							} else if (b.offset > offsetMax) {
								wNew = w.create();
								wNew.vertex = b;
								if (wPositive != null) {
									wPositive.next = wNew;
								} else {
									positive.wrapper = wNew;
								}
								wPositive = wNew;
							} else {
								wNew = w.create();
								wNew.vertex = b;
								if (wPositive != null) {
									wPositive.next = wNew;
								} else {
									positive.wrapper = wNew;
								}
								wPositive = wNew;
								v2 = b.create();
								camera.lastVertex.next = v2;
								camera.lastVertex = v2;
								v2.x = b.x;
								v2.y = b.y;
								v2.z = b.z;
								v2.u = b.u;
								v2.v = b.v;
								v2.cameraX = b.cameraX;
								v2.cameraY = b.cameraY;
								v2.cameraZ = b.cameraZ;
								wNew = w.create();
								wNew.vertex = v2;
								if (wNegative != null) {
									wNegative.next = wNew;
								} else {
									negative.wrapper = wNew;
								}
								wNegative = wNew;
							}
							a = b;
							ao = bo;
						}
						if (negativeFirst != null) {
							negativeLast.processNext = negative;
						} else {
							negativeFirst = negative;
						}
						negativeLast = negative;
						if (positiveFirst != null) {
							positiveLast.processNext = positive;
						} else {
							positiveFirst = positive;
						}
						positiveLast = positive;
						face.processNext = null;
					}
				}
			}
			// Если сзади от сплита есть грани или обе дочерние ноды
			if (negativeFirst != null || negativeNegative != null && positiveNegative != null) {
				// Создание пустой ноды
				if (negativeFirst == null) {
					negativeFirst = struct.create();
					camera.lastFace.next = negativeFirst;
					camera.lastFace = negativeFirst;
				} else {
					negativeLast.processNext = null;
				}
				if (sorting == 3) {
					negativeFirst.normalX = struct.normalX;
					negativeFirst.normalY = struct.normalY;
					negativeFirst.normalZ = struct.normalZ;
					negativeFirst.offset = struct.offset;
				}
				negativeFirst.processNegative = negativeNegative;
				negativeFirst.processPositive = positiveNegative;
				result.processNegative = negativeFirst;
			} else {
				result.processNegative = (negativeNegative != null) ? negativeNegative : positiveNegative;
			}
			// Если спереди от сплита есть грани или обе дочерние ноды
			if (positiveFirst != null || negativePositive != null && positivePositive != null) {
				// Создание пустой ноды
				if (positiveFirst == null) {
					positiveFirst = struct.create();
					camera.lastFace.next = positiveFirst;
					camera.lastFace = positiveFirst;
				} else {
					positiveLast.processNext = null;
				}
				if (sorting == 3) {
					positiveFirst.normalX = struct.normalX;
					positiveFirst.normalY = struct.normalY;
					positiveFirst.normalZ = struct.normalZ;
					positiveFirst.offset = struct.offset;
				}
				positiveFirst.processNegative = negativePositive;
				positiveFirst.processPositive = positivePositive;
				result.processPositive = positiveFirst;
			} else {
				result.processPositive = (negativePositive != null) ? negativePositive : positivePositive;
			}
		}
	
		private function cropFaceStruct(camera:Camera3D, struct:Face, normalX:Number, normalY:Number, normalZ:Number, offset:Number, offsetMin:Number, offsetMax:Number):Face {
			var face:Face;
			var next:Face;
			var w:Wrapper;
			var v:Vertex;
			// Разделение дочерних нод
			var negativePositive:Face;
			var positivePositive:Face;
			if (struct.processNegative != null) {
				negativePositive = cropFaceStruct(camera, struct.processNegative, normalX, normalY, normalZ, offset, offsetMin, offsetMax);
				struct.processNegative = null;
			}
			if (struct.processPositive != null) {
				positivePositive = cropFaceStruct(camera, struct.processPositive, normalX, normalY, normalZ, offset, offsetMin, offsetMax);
				struct.processPositive = null;
			}
			// Разделение ноды
			var positiveFirst:Face;
			var positiveLast:Face;
			if (struct.wrapper != null) {
				for (face = struct; face != null; face = next) {
					next = face.processNext;
					w = face.wrapper;
					var a:Vertex = w.vertex;
					w = w.next;
					var b:Vertex = w.vertex;
					w = w.next;
					var c:Vertex = w.vertex;
					w = w.next;
					var ao:Number = a.cameraX*normalX + a.cameraY*normalY + a.cameraZ*normalZ;
					var bo:Number = b.cameraX*normalX + b.cameraY*normalY + b.cameraZ*normalZ;
					var co:Number = c.cameraX*normalX + c.cameraY*normalY + c.cameraZ*normalZ;
					var behind:Boolean = ao < offsetMin || bo < offsetMin || co < offsetMin;
					var infront:Boolean = ao > offsetMax || bo > offsetMax || co > offsetMax;
					for (; w != null; w = w.next) {
						v = w.vertex;
						var vo:Number = v.cameraX*normalX + v.cameraY*normalY + v.cameraZ*normalZ;
						if (vo < offsetMin) {
							behind = true;
						} else if (vo > offsetMax) {
							infront = true;
						}
						v.offset = vo;
					}
					if (!infront) {
						face.processNext = null;
					} else if (!behind) {
						if (positiveFirst != null) {
							positiveLast.processNext = face;
						} else {
							positiveFirst = face;
						}
						positiveLast = face;
					} else {
						a.offset = ao;
						b.offset = bo;
						c.offset = co;
						var positive:Face = face.create();
						positive.material = face.material;
						camera.lastFace.next = positive;
						camera.lastFace = positive;
						var wPositive:Wrapper = null;
						var wNew:Wrapper;
						//for (w = face.wrapper.next.next; w.next != null; w = w.next);
						w = face.wrapper.next.next;
						while (w.next != null) w = w.next;
						a = w.vertex;
						ao = a.offset;
						for (w = face.wrapper; w != null; w = w.next) {
							b = w.vertex;
							bo = b.offset;
							if (ao < offsetMin && bo > offsetMax || ao > offsetMax && bo < offsetMin) {
								var t:Number = (offset - ao)/(bo - ao);
								v = b.create();
								camera.lastVertex.next = v;
								camera.lastVertex = v;
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								v.u = a.u + (b.u - a.u)*t;
								v.v = a.v + (b.v - a.v)*t;
								v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
								v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
								v.cameraZ = a.cameraZ + (b.cameraZ - a.cameraZ)*t;
								wNew = w.create();
								wNew.vertex = v;
								if (wPositive != null) {
									wPositive.next = wNew;
								} else {
									positive.wrapper = wNew;
								}
								wPositive = wNew;
							}
							if (bo >= offsetMin) {
								wNew = w.create();
								wNew.vertex = b;
								if (wPositive != null) {
									wPositive.next = wNew;
								} else {
									positive.wrapper = wNew;
								}
								wPositive = wNew;
							}
							a = b;
							ao = bo;
						}
						if (positiveFirst != null) {
							positiveLast.processNext = positive;
						} else {
							positiveFirst = positive;
						}
						positiveLast = positive;
						face.processNext = null;
					}
				}
			}
			// Если спереди от сплита есть грани или обе дочерние ноды
			if (positiveFirst != null || negativePositive != null && positivePositive != null) {
				// Создание пустой ноды
				if (positiveFirst == null) {
					positiveFirst = struct.create();
					camera.lastFace.next = positiveFirst;
					camera.lastFace = positiveFirst;
				} else {
					positiveLast.processNext = null;
				}
				if (sorting == 3) {
					positiveFirst.normalX = struct.normalX;
					positiveFirst.normalY = struct.normalY;
					positiveFirst.normalZ = struct.normalZ;
					positiveFirst.offset = struct.offset;
				}
				positiveFirst.processNegative = negativePositive;
				positiveFirst.processPositive = positivePositive;
				return positiveFirst;
			} else {
				return (negativePositive != null) ? negativePositive : positivePositive;
			}
		}
		
		alternativa3d function transformStruct(struct:Face, transformId:int, a:Number, b:Number, c:Number, d:Number, e:Number, f:Number, g:Number, h:Number, i:Number, j:Number, k:Number, l:Number):void {
			for (var face:Face = struct; face != null; face = face.processNext) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					if (vertex.transformId != transformId) {
						var cameraX:Number = vertex.cameraX;
						var cameraY:Number = vertex.cameraY;
						var cameraZ:Number = vertex.cameraZ;
						vertex.cameraX = a*cameraX + b*cameraY + c*cameraZ + d;
						vertex.cameraY = e*cameraX + f*cameraY + g*cameraZ + h;
						vertex.cameraZ = i*cameraX + j*cameraY + k*cameraZ + l;
						vertex.transformId = transformId;
					}
				}
			}
			if (struct.processNegative != null) transformStruct(struct.processNegative, transformId, a, b, c, d, e, f, g, h, i, j, k, l);
			if (struct.processPositive != null) transformStruct(struct.processPositive, transformId, a, b, c, d, e, f, g, h, i, j, k, l);
		}
		
		alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas, threshold:Number, container:Object3D):void {
			var canvas:Canvas;
			var list:Face;
			// Трансформация в камеру
			if (space == 1) transformStruct(faceStruct, ++object.transformId, container.ma, container.mb, container.mc, container.md, container.me, container.mf, container.mg, container.mh, container.mi, container.mj, container.mk, container.ml);
			if (viewAligned) {
				list = faceStruct;
				// Дебаг
				if (debug > 0) {
					canvas = parentCanvas.getChildCanvas(true, false);
					if (debug & Debug.EDGES) Debug.drawEdges(camera, canvas, list, (space != 2) ? 0xFFFFFF : 0xFF9900);
					if (debug & Debug.BOUNDS) {
						if (space == 1) {
							Debug.drawBounds(camera, canvas, container, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ, 0x99FF00);
						}
					}
				}
				// Отрисовка
				canvas = parentCanvas.getChildCanvas(true, false, object, alpha, blendMode, colorTransform, filters);
				list.material.drawViewAligned(camera, canvas, list, object.ml, tma, tmb, tmc, tmd, tmtx, tmty);
			} else {
				// Сортировка
				switch (sorting) {
					case 0:
						list = faceStruct;
						break;
					case 1:
						list = (faceStruct.processNext != null) ? camera.sortByAverageZ(faceStruct) : faceStruct;
						break;
					case 2:
						list = (faceStruct.processNext != null) ? camera.sortByDynamicBSP(faceStruct, threshold) : faceStruct;
						break;
					case 3:
						list = collectNode(faceStruct);
						break;
				}
				// Дебаг
				if (debug > 0) {
					canvas = parentCanvas.getChildCanvas(true, false);
					if (debug & Debug.EDGES) Debug.drawEdges(camera, canvas, list, 0xFFFFFF);
					if (debug & Debug.BOUNDS) {
						if (space == 1) {
							Debug.drawBounds(camera, canvas, container, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ, 0x99FF00);
						} else if (space == 2) {
							Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ, 0xFF9900);
						}
					}
				}
				// Отрисовка
				canvas = parentCanvas.getChildCanvas(true, false, object, alpha, blendMode, colorTransform, filters);
				for (var face:Face = list; face != null; face = next) {
					var next:Face = face.processNext;
					// Если конец списка или смена материала
					if (next == null || next.material != list.material) {
						// Разрыв на стыке разных материалов
						face.processNext = null;
						// Если материал для части списка не пустой
						if (list.material != null) {
							// Отрисовка
							list.material.draw(camera, canvas, list, object.ml);
						} else {
							// Разрыв связей
							while (list != null) {
								face = list.processNext;
								list.processNext = null;
								list = face;
							}
						}
						list = next;
					}
				}
			}
			faceStruct = null;
		}
	
		private function collectNode(node:Face, result:Face = null):Face {
			var last:Face;
			var negative:Face;
			var positive:Face;
			if (node.offset < 0) {
				negative = node.processNegative;
				positive = node.processPositive;
			} else {
				negative = node.processPositive;
				positive = node.processNegative;
			}
			node.processNegative = null;
			node.processPositive = null;
			if (positive != null) result = collectNode(positive, result);
			if (node.wrapper != null) {
				//for (last = tree; last.processNext != null; last = last.processNext);
				last = node;
				while (last.processNext != null) last = last.processNext;
				last.processNext = result;
				result = node;
			}
			if (negative != null) result = collectNode(negative, result);
			return result;
		}
	
	}
}
