package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.ColorTransform;
	
	use namespace alternativa3d;
	
	public class Geometry {
	
		public var next:Geometry;
	
		public var faceStruct:Face;
	
		public var transformID:int = 0;
	
		public var numOccluders:int;
	
		public var interactiveObject:Object3D;
	
		// Передаваемые при сплите свойства
		public var alpha:Number;
		public var blendMode:String;
		public var colorTransform:ColorTransform;
		public var filters:Array;
		public var sorting:int;
		public var debug:int = 0;
		public var boundType:int = 0;
		public var viewAligned:Boolean = false;
		public var tma:Number;
		public var tmb:Number;
		public var tmc:Number;
		public var tmd:Number;
		public var tmtx:Number;
		public var tmty:Number;
	
		// Матрица перевода из локальных координат объекта в камеру
		public var ma:Number;
		public var mb:Number;
		public var mc:Number;
		public var md:Number;
		public var me:Number;
		public var mf:Number;
		public var mg:Number;
		public var mh:Number;
		public var mi:Number;
		public var mj:Number;
		public var mk:Number;
		public var ml:Number;
	
		// Матрица перевода из камеры в локальные координаты объекта
		public var ima:Number;
		public var imb:Number;
		public var imc:Number;
		public var imd:Number;
		public var ime:Number;
		public var imf:Number;
		public var img:Number;
		public var imh:Number;
		public var imi:Number;
		public var imj:Number;
		public var imk:Number;
		public var iml:Number;
	
		// AABB
		public var boundMinX:Number;
		public var boundMinY:Number;
		public var boundMinZ:Number;
		public var boundMaxX:Number;
		public var boundMaxY:Number;
		public var boundMaxZ:Number;
	
		// OOBB
		public var boundVertexList:Vertex = Vertex.createList(8);
		public var boundPlaneList:Vertex = Vertex.createList(6);
	
		static private var collector:Geometry;
	
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
			if (faceStruct != null) {
				destroyFaceStruct(faceStruct);
				faceStruct = null;
			}
			interactiveObject = null;
			viewAligned = false;
			colorTransform = null;
			filters = null;
			numOccluders = 0;
			debug = 0;
			transformID = 0;
			boundType = 0;
			next = collector;
			collector = this;
		}
	
		private function destroyFaceStruct(struct:Face):void {
			if (struct.negative != null) {
				destroyFaceStruct(struct.negative);
				struct.negative = null;
			}
			if (struct.positive != null) {
				destroyFaceStruct(struct.positive);
				struct.positive = null;
			}
			//for (var next:Face = struct.processNext; next != null; struct.processNext = null, struct = next, next = struct.processNext);
			var next:Face = struct.processNext;
			while (next != null) {
				struct.processNext = null;
				struct = next;
				next = struct.processNext;
			}
		}
	
		public function calculateAABB(a:Number, b:Number, c:Number, d:Number, e:Number, f:Number, g:Number, h:Number, i:Number, j:Number, k:Number, l:Number):void {
			boundMinX = 1e+22;
			boundMinY = 1e+22;
			boundMinZ = 1e+22;
			boundMaxX = -1e+22;
			boundMaxY = -1e+22;
			boundMaxZ = -1e+22;
			transformID++;
			calculateBB(faceStruct, a, b, c, d, e, f, g, h, i, j, k, l);
			// Тип баунда
			boundType = 1;
		}
	
		public function calculateOOBB():void {
			if (viewAligned) {
	
			} else {
				boundMinX = 1e+22;
				boundMinY = 1e+22;
				boundMinZ = 1e+22;
				boundMaxX = -1e+22;
				boundMaxY = -1e+22;
				boundMaxZ = -1e+22;
				transformID++;
				calculateBB(faceStruct, ima, imb, imc, imd, ime, imf, img, imh, imi, imj, imk, iml);
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
					var x:Number = vertex.x;
					var y:Number = vertex.y;
					var z:Number = vertex.z;
					vertex.cameraX = ma*x + mb*y + mc*z + md;
					vertex.cameraY = me*x + mf*y + mg*z + mh;
					vertex.cameraZ = mi*x + mj*y + mk*z + ml;
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
			}
			// Тип баунда
			boundType = 2;
		}
	
		private function calculateBB(struct:Face, a:Number, b:Number, c:Number, d:Number, e:Number, f:Number, g:Number, h:Number, i:Number, j:Number, k:Number, l:Number):void {
			for (var face:Face = struct; face != null; face = face.processNext) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					if (vertex.transformID != transformID) {
						var cameraX:Number = vertex.cameraX;
						var cameraY:Number = vertex.cameraY;
						var cameraZ:Number = vertex.cameraZ;
						var x:Number = a*cameraX + b*cameraY + c*cameraZ + d;
						var y:Number = e*cameraX + f*cameraY + g*cameraZ + h;
						var z:Number = i*cameraX + j*cameraY + k*cameraZ + l;
						vertex.x = x;
						vertex.y = y;
						vertex.z = z;
						if (x < boundMinX) boundMinX = x;
						if (x > boundMaxX) boundMaxX = x;
						if (y < boundMinY) boundMinY = y;
						if (y > boundMaxY) boundMaxY = y;
						if (z < boundMinZ) boundMinZ = z;
						if (z > boundMaxZ) boundMaxZ = z;
						vertex.transformID = transformID;
					}
				}
			}
			if (struct.negative != null) calculateBB(struct.negative, a, b, c, d, e, f, g, h, i, j, k, l);
			if (struct.positive != null) calculateBB(struct.positive, a, b, c, d, e, f, g, h, i, j, k, l);
		}
	
		public function updateBB(struct:Face):void {
			for (var face:Face = struct; face != null; face = face.processNext) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					if (vertex.transformID != transformID) {
						if (vertex.x < boundMinX) boundMinX = vertex.x;
						if (vertex.x > boundMaxX) boundMaxX = vertex.x;
						if (vertex.y < boundMinY) boundMinY = vertex.y;
						if (vertex.y > boundMaxY) boundMaxY = vertex.y;
						if (vertex.z < boundMinZ) boundMinZ = vertex.z;
						if (vertex.z > boundMaxZ) boundMaxZ = vertex.z;
						vertex.transformID = transformID;
					}
				}
			}
			if (struct.negative != null) updateBB(struct.negative);
			if (struct.positive != null) updateBB(struct.positive);
		}
	
		// Сам объект с другим набором граней остаётся спереди, его next указывает на негативную часть
		public function split(camera:Camera3D, planeX:Number, planeY:Number, planeZ:Number, planeOffset:Number, threshold:Number):void {
			// Разбиение
			var result:Face = faceStruct.create();
			splitFaceStruct(camera, faceStruct, result, planeX, planeY, planeZ, planeOffset, planeOffset - threshold, planeOffset + threshold);
			// Копирование свойств
			if (result.negative != null) {
				var negative:Geometry = create();
				next = negative;
				negative.faceStruct = result.negative;
				result.negative = null;
				negative.ma = ma;
				negative.mb = mb;
				negative.mc = mc;
				negative.md = md;
				negative.me = me;
				negative.mf = mf;
				negative.mg = mg;
				negative.mh = mh;
				negative.mi = mi;
				negative.mj = mj;
				negative.mk = mk;
				negative.ml = ml;
				negative.interactiveObject = interactiveObject;
				negative.alpha = alpha;
				negative.blendMode = blendMode;
				negative.colorTransform = colorTransform;
				negative.filters = filters;
				negative.sorting = sorting;
				negative.debug = debug;
				negative.boundType = boundType;
				negative.viewAligned = viewAligned;
				if (viewAligned) {
					negative.tma = tma;
					negative.tmb = tmb;
					negative.tmc = tmc;
					negative.tmd = tmd;
					negative.tmtx = tmtx;
					negative.tmty = tmty;
				} else {
					negative.ima = ima;
					negative.imb = imb;
					negative.imc = imc;
					negative.imd = imd;
					negative.ime = ime;
					negative.imf = imf;
					negative.img = img;
					negative.imh = imh;
					negative.imi = imi;
					negative.imj = imj;
					negative.imk = imk;
					negative.iml = iml;
				}
				negative.boundMinX = 1e+22;
				negative.boundMinY = 1e+22;
				negative.boundMinZ = 1e+22;
				negative.boundMaxX = -1e+22;
				negative.boundMaxY = -1e+22;
				negative.boundMaxZ = -1e+22;
				negative.transformID = transformID + 1;
				negative.updateBB(negative.faceStruct);
			} else {
				next = null;
			}
			if (result.positive != null) {
				faceStruct = result.positive;
				result.positive = null;
				boundMinX = 1e+22;
				boundMinY = 1e+22;
				boundMinZ = 1e+22;
				boundMaxX = -1e+22;
				boundMaxY = -1e+22;
				boundMaxZ = -1e+22;
				transformID++;
				updateBB(faceStruct);
			} else {
				faceStruct = null;
			}
			result.next = Face.collector;
			Face.collector = result;
		}
	
		// Всегда отсекается негативная часть, поэтому если нужно получить негативную, следует перевернуть плоскость
		public function crop(camera:Camera3D, planeX:Number, planeY:Number, planeZ:Number, planeOffset:Number, threshold:Number):void {
			// Подрезка
			faceStruct = cropFaceStruct(camera, faceStruct, planeX, planeY, planeZ, planeOffset, planeOffset - threshold, planeOffset + threshold);
			if (faceStruct != null) {
				boundMinX = 1e+22;
				boundMinY = 1e+22;
				boundMinZ = 1e+22;
				boundMaxX = -1e+22;
				boundMaxY = -1e+22;
				boundMaxZ = -1e+22;
				transformID++;
				updateBB(faceStruct);
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
			if (struct.negative != null) {
				splitFaceStruct(camera, struct.negative, result, normalX, normalY, normalZ, offset, offsetMin, offsetMax);
				struct.negative = null;
				negativeNegative = result.negative;
				negativePositive = result.positive;
			}
			if (struct.positive != null) {
				splitFaceStruct(camera, struct.positive, result, normalX, normalY, normalZ, offset, offsetMin, offsetMax);
				struct.positive = null;
				positiveNegative = result.negative;
				positivePositive = result.positive;
			}
			// Разделение ноды
			var negativeFirst:Face;
			var negativeLast:Face;
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
					var ao:Number = a.x*normalX + a.y*normalY + a.z*normalZ;
					var bo:Number = b.x*normalX + b.y*normalY + b.z*normalZ;
					var co:Number = c.x*normalX + c.y*normalY + c.z*normalZ;
					var behind:Boolean = ao < offsetMin || bo < offsetMin || co < offsetMin;
					var infront:Boolean = ao > offsetMax || bo > offsetMax || co > offsetMax;
					for (; w != null; w = w.next) {
						v = w.vertex;
						var vo:Number = v.x*normalX + v.y*normalY + v.z*normalZ;
						if (vo < offsetMin) {
							behind = true;
						} else if (vo > offsetMax) {
							infront = true;
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
						var negative:Face = face.create();
						negative.material = face.material;
						camera.lastFace.next = negative;
						camera.lastFace = negative;
						var positive:Face = face.create();
						positive.material = face.material;
						camera.lastFace.next = positive;
						camera.lastFace = positive;
						var wNegative:Wrapper = null;
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
								v2 = v.create();
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
								wNew.vertex = v;
								if (wNegative != null) {
									wNegative.next = wNew;
								} else {
									negative.wrapper = wNew;
								}
								wNegative = wNew;
								wNew = w.create();
								wNew.vertex = v2;
								if (wPositive != null) {
									wPositive.next = wNew;
								} else {
									positive.wrapper = wNew;
								}
								wPositive = wNew;
							}
							if (bo < offsetMin) {
								wNew = w.create();
								wNew.vertex = b;
								if (wNegative != null) {
									wNegative.next = wNew;
								} else {
									negative.wrapper = wNew;
								}
								wNegative = wNew;
							} else if (bo > offsetMax) {
								wNew = w.create();
								wNew.vertex = b;
								if (wPositive != null) {
									wPositive.next = wNew;
								} else {
									positive.wrapper = wNew;
								}
								wPositive = wNew;
							} else {
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
								wNew.vertex = b;
								if (wNegative != null) {
									wNegative.next = wNew;
								} else {
									negative.wrapper = wNew;
								}
								wNegative = wNew;
								wNew = w.create();
								wNew.vertex = v2;
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
				negativeFirst.negative = negativeNegative;
				negativeFirst.positive = positiveNegative;
				result.negative = negativeFirst;
			} else {
				result.negative = (negativeNegative != null) ? negativeNegative : positiveNegative;
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
				positiveFirst.negative = negativePositive;
				positiveFirst.positive = positivePositive;
				result.positive = positiveFirst;
			} else {
				result.positive = (negativePositive != null) ? negativePositive : positivePositive;
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
			if (struct.negative != null) {
				negativePositive = cropFaceStruct(camera, struct.negative, normalX, normalY, normalZ, offset, offsetMin, offsetMax);
				struct.negative = null;
			}
			if (struct.positive != null) {
				positivePositive = cropFaceStruct(camera, struct.positive, normalX, normalY, normalZ, offset, offsetMin, offsetMax);
				struct.positive = null;
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
					var ao:Number = a.x*normalX + a.y*normalY + a.z*normalZ;
					var bo:Number = b.x*normalX + b.y*normalY + b.z*normalZ;
					var co:Number = c.x*normalX + c.y*normalY + c.z*normalZ;
					var behind:Boolean = ao < offsetMin || bo < offsetMin || co < offsetMin;
					var infront:Boolean = ao > offsetMax || bo > offsetMax || co > offsetMax;
					for (; w != null; w = w.next) {
						v = w.vertex;
						var vo:Number = v.x*normalX + v.y*normalY + v.z*normalZ;
						if (vo < offsetMin) {
							behind = true;
						} else if (vo > offsetMax) {
							infront = true;
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
						face.processNext = null;
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
				positiveFirst.negative = negativePositive;
				positiveFirst.positive = positivePositive;
				return positiveFirst;
			} else {
				return (negativePositive != null) ? negativePositive : positivePositive;
			}
		}
	
		public function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas, threshold:Number):void {
			var canvas:Canvas;
			var list:Face;
			if (viewAligned) {
				list = faceStruct;
				// Дебаг
				if (debug > 0) {
					canvas = parentCanvas.getChildCanvas(interactiveObject, true, false);
					if (debug & Debug.EDGES) Debug.drawEdges(camera, canvas, list, (boundType != 2) ? 0xFFFFFF : 0xFF9900);
					if (debug & Debug.BOUNDS) {
						if (boundType == 1) {
							Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ, 0x99FF00);
						}
					}
				}
				// Отрисовка
				canvas = parentCanvas.getChildCanvas(interactiveObject, true, false, alpha, blendMode, colorTransform, filters);
				list.material.drawViewAligned(camera, canvas, list, ml, tma, tmb, tmc, tmd, tmtx, tmty);
			} else {
				// Сортировка
				switch (sorting) {
					case 0:
						list = faceStruct;
						break;
					case 1:
						list = (faceStruct.processNext != null) ? sortByAverageZ(faceStruct) : faceStruct;
						break;
					case 2:
						list = (faceStruct.processNext != null) ? sortByDynamicBSP(faceStruct, camera, threshold) : faceStruct;
						break;
					case 3:
						list = collectNode(faceStruct);
						break;
				}
				// Дебаг
				if (debug > 0) {
					canvas = parentCanvas.getChildCanvas(interactiveObject, true, false);
					if (debug & Debug.EDGES) Debug.drawEdges(camera, canvas, list, 0xFFFFFF);
					if (debug & Debug.BOUNDS) {
						if (boundType == 1) {
							Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ, 0x99FF00);
						} else if (boundType == 2) {
							var oma:Number = object.ma, omb:Number = object.mb, omc:Number = object.mc, omd:Number = object.md, ome:Number = object.me, omf:Number = object.mf, omg:Number = object.mg, omh:Number = object.mh, omi:Number = object.mi, omj:Number = object.mj, omk:Number = object.mk, oml:Number = object.ml;
							object.ma = ma;
							object.mb = mb;
							object.mc = mc;
							object.md = md;
							object.me = me;
							object.mf = mf;
							object.mg = mg;
							object.mh = mh;
							object.mi = mi;
							object.mj = mj;
							object.mk = mk;
							object.ml = ml;
							Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ, 0xFF9900);
							object.ma = oma;
							object.mb = omb;
							object.mc = omc;
							object.md = omd;
							object.me = ome;
							object.mf = omf;
							object.mg = omg;
							object.mh = omh;
							object.mi = omi;
							object.mj = omj;
							object.mk = omk;
							object.ml = oml;
						}
					}
				}
				// Отрисовка
				canvas = parentCanvas.getChildCanvas(interactiveObject, true, false, alpha, blendMode, colorTransform, filters);
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
	
		private function sortByAverageZ(list:Face):Face {
			var num:int;
			var sum:Number;
			var wrapper:Wrapper;
			var left:Face = list;
			var right:Face = list.processNext;
			while (right != null && right.processNext != null) {
				list = list.processNext;
				right = right.processNext.processNext;
			}
			right = list.processNext;
			list.processNext = null;
			if (left.processNext != null) {
				left = sortByAverageZ(left);
			} else {
				num = 0;
				sum = 0;
				for (wrapper = left.wrapper; wrapper != null; wrapper = wrapper.next) {
					num++;
					sum += wrapper.vertex.cameraZ;
				}
				left.distance = sum/num;
			}
			if (right.processNext != null) {
				right = sortByAverageZ(right);
			} else {
				num = 0;
				sum = 0;
				for (wrapper = right.wrapper; wrapper != null; wrapper = wrapper.next) {
					num++;
					sum += wrapper.vertex.cameraZ;
				}
				right.distance = sum/num;
			}
			var flag:Boolean = left.distance > right.distance;
			if (flag) {
				list = left;
				left = left.processNext;
			} else {
				list = right;
				right = right.processNext;
			}
			var last:Face = list;
			while (true) {
				if (left == null) {
					last.processNext = right;
					return list;
				} else if (right == null) {
					last.processNext = left;
					return list;
				}
				if (flag) {
					if (left.distance > right.distance) {
						last = left;
						left = left.processNext;
					} else {
						last.processNext = right;
						last = right;
						right = right.processNext;
						flag = false;
					}
				} else {
					if (right.distance > left.distance) {
						last = right;
						right = right.processNext;
					} else {
						last.processNext = left;
						last = left;
						left = left.processNext;
						flag = true;
					}
				}
			}
			return null;
		}
	
		private function sortByDynamicBSP(list:Face, camera:Camera3D, threshold:Number, result:Face = null):Face {
			var w:Wrapper;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var v:Vertex;
			var splitter:Face = list;
			list = splitter.processNext;
			// Поиск удовлетворяющей нормали
			w = splitter.wrapper;
			a = w.vertex;
			w = w.next;
			b = w.vertex;
			var ax:Number = a.cameraX;
			var ay:Number = a.cameraY;
			var az:Number = a.cameraZ;
			var abx:Number = b.cameraX - ax;
			var aby:Number = b.cameraY - ay;
			var abz:Number = b.cameraZ - az;
			var normalX:Number = 0;
			var normalY:Number = 0;
			var normalZ:Number = 1;
			var offset:Number = az;
			var length:Number = 0;
			for (w = w.next; w != null; w = w.next) {
				v = w.vertex;
				var acx:Number = v.cameraX - ax;
				var acy:Number = v.cameraY - ay;
				var acz:Number = v.cameraZ - az;
				var nx:Number = acz*aby - acy*abz;
				var ny:Number = acx*abz - acz*abx;
				var nz:Number = acy*abx - acx*aby;
				var nl:Number = nx*nx + ny*ny + nz*nz;
				if (nl > threshold) {
					nl = 1/Math.sqrt(nl);
					normalX = nx*nl;
					normalY = ny*nl;
					normalZ = nz*nl;
					offset = ax*normalX + ay*normalY + az*normalZ;
					break;
				} else if (nl > length) {
					nl = 1/Math.sqrt(nl);
					normalX = nx*nl;
					normalY = ny*nl;
					normalZ = nz*nl;
					offset = ax*normalX + ay*normalY + az*normalZ;
					length = nl;
				}
			}
			var offsetMin:Number = offset - threshold;
			var offsetMax:Number = offset + threshold;
			var negativeFirst:Face;
			var negativeLast:Face;
			var splitterLast:Face = splitter;
			var positiveFirst:Face;
			var positiveLast:Face;
			var next:Face;
			for (var face:Face = list; face != null; face = next) {
				next = face.processNext;
				w = face.wrapper;
				a = w.vertex;
				w = w.next;
				b = w.vertex;
				w = w.next;
				c = w.vertex;
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
				if (!behind) {
					if (!infront) {
						splitterLast.processNext = face;
						splitterLast = face;
					} else {
						if (positiveFirst != null) {
							positiveLast.processNext = face;
						} else {
							positiveFirst = face;
						}
						positiveLast = face;
					}
				} else if (!infront) {
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
					var negative:Face = face.create();
					negative.material = face.material;
					camera.lastFace.next = negative;
					camera.lastFace = negative;
					var positive:Face = face.create();
					positive.material = face.material;
					camera.lastFace.next = positive;
					camera.lastFace = positive;
					var wNegative:Wrapper = null;
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
							v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
							v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
							v.cameraZ = a.cameraZ + (b.cameraZ - a.cameraZ)*t;
							v.u = a.u + (b.u - a.u)*t;
							v.v = a.v + (b.v - a.v)*t;
							wNew = w.create();
							wNew.vertex = v;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
							wNew = w.create();
							wNew.vertex = v;
							if (wPositive != null) {
								wPositive.next = wNew;
							} else {
								positive.wrapper = wNew;
							}
							wPositive = wNew;
						}
						if (bo <= offsetMax) {
							wNew = w.create();
							wNew.vertex = b;
							if (wNegative != null) {
								wNegative.next = wNew;
							} else {
								negative.wrapper = wNew;
							}
							wNegative = wNew;
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
			if (positiveFirst != null) {
				positiveLast.processNext = null;
				if (positiveFirst.processNext != null) {
					result = sortByDynamicBSP(positiveFirst, camera, threshold, result);
				} else {
					positiveFirst.processNext = result;
					result = positiveFirst;
				}
			}
			splitterLast.processNext = result;
			result = splitter;
			if (negativeFirst != null) {
				negativeLast.processNext = null;
				if (negativeFirst.processNext != null) {
					result = sortByDynamicBSP(negativeFirst, camera, threshold, result);
				} else {
					negativeFirst.processNext = result;
					result = negativeFirst;
				}
			}
			return result;
		}
	
		private function collectNode(tree:Face, result:Face = null):Face {
			var last:Face;
			var negative:Face;
			var positive:Face;
			if (tree.offset < 0) {
				negative = tree.negative;
				positive = tree.positive;
			} else {
				negative = tree.positive;
				positive = tree.negative;
			}
			tree.negative = null;
			tree.positive = null;
			if (positive != null) result = collectNode(positive, result);
			if (tree.wrapper != null) {
				//for (last = tree; last.processNext != null; last = last.processNext);
				last = tree;
				while (last.processNext != null) last = last.processNext;
				last.processNext = result;
				result = tree;
			}
			if (negative != null) result = collectNode(negative, result);
			return result;
		}
	
	}
}
