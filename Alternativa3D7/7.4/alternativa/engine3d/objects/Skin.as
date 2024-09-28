package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	
	use namespace alternativa3d;
	
	public class Skin extends Mesh {
	
		private var joints:Vector.<Joint> = new Vector.<Joint>();
		private var _numJoints:uint = 0;
	
		public function calculateBindingMatrices():void {
			ma = 1;
			mb = 0;
			mc = 0;
			md = 0;
			me = 0;
			mf = 1;
			mg = 0;
			mh = 0;
			mi = 0;
			mj = 0;
			mk = 1;
			ml = 0;
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.calculateBindingMatrix(this);
			}
		}
	
		public function normalizeWeights():void {
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) vertex.offset = 0;
			var joint:Joint;
			for (var i:int = 0; i < _numJoints; i++) {
				joint = joints[i];
				joint.addWeights();
			}
			for (i = 0; i < _numJoints; i++) {
				joint = joints[i];
				joint.normalizeWeights();
			}
		}
	
		public function addJoint(joint:Joint):void {
			joints[_numJoints++] = joint;
		}
	
		public function removeJoint(joint:Joint):void {
			var i:int = joints.indexOf(joint);
			if (i < 0) throw new ArgumentError("Joint not found");
			_numJoints--;
			var j:int = i + 1;
			while (i < _numJoints) {
				joints[i] = joints[j];
				i++;
				j++;
			}
			joints.length = _numJoints;
		}
	
		public function get numJoints():uint {
			return _numJoints;
		}
	
		public function getJointAt(index:uint):Joint {
			return joints[index];
		}
	
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var canvas:Canvas;
			var debug:int;
			var list:Face;
			var vertex:Vertex;
			// Коррекция куллинга
			var culling:int = object.culling;
			if (clipping == 0) {
				if (culling & 1) return;
				culling = 0;
			}
			// Обнуление вершин
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.cameraX = 0;
				vertex.cameraY = 0;
				vertex.cameraZ = 0;
				vertex.drawID = 0;
			}
			// Расчёт координат вершин
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.draw(camera, object, parentCanvas);
			}
			// Отсечение по нормалям
			var last:Face;
			for (var face:Face = faceList; face != null; face = face.next) {
				var a:Vertex = face.wrapper.vertex;
				var b:Vertex = face.wrapper.next.vertex;
				var c:Vertex = face.wrapper.next.next.vertex;
				var abx:Number = b.cameraX - a.cameraX;
				var aby:Number = b.cameraY - a.cameraY;
				var abz:Number = b.cameraZ - a.cameraZ;
				var acx:Number = c.cameraX - a.cameraX;
				var acy:Number = c.cameraY - a.cameraY;
				var acz:Number = c.cameraZ - a.cameraZ;
				if ((acz*aby - acy*abz)*a.cameraX + (acx*abz - acz*abx)*a.cameraY + (acy*abx - acx*aby)*a.cameraZ < 0) {
					if (list != null) {
						last.processNext = face;
					} else {
						list = face;
					}
					last = face;
				}
			}
			if (last != null) {
				last.processNext = null;
			}
			if (list == null) return;
	
			// Отсечение по пирамиде видимости
			if (culling > 0) {
				if (clipping == 1) {
					list = cull(list, culling, camera);
				} else {
					list = clip(list, culling, camera);
				}
				if (list == null) return;
			}
			// Сортировка
			if (list.processNext != null) {
				if (sorting == 1) {
					list = sortByAverageZ(list);
				} else if (sorting == 2) {
					list = sortByDynamicBSP(list, camera, threshold);
				}
			}
			// Дебаг
			if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
				canvas = parentCanvas.getChildCanvas(object, true, false);
				if (debug & Debug.EDGES) Debug.drawEdges(camera, canvas, list, 0xFFFFFF);
				if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
			}
			// Отрисовка
			canvas = parentCanvas.getChildCanvas(object, true, false, object.alpha, object.blendMode, object.colorTransform, object.filters);
			for (face = list; face != null; face = next) {
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
	
		override alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			// Обнуление вершин
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.cameraX = 0;
				vertex.cameraY = 0;
				vertex.cameraZ = 0;
			}
			// Расчёт координат вершин
			if (transformation == null) {
				ma = 1;
				mb = 0;
				mc = 0;
				md = 0;
				me = 0;
				mf = 1;
				mg = 0;
				mh = 0;
				mi = 0;
				mj = 0;
				mk = 1;
				ml = 0;
				transformation = this;
			}
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.updateBounds(bounds, transformation);
			}
			// Расширение баунда
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) {
				if (vertex.cameraX < bounds.boundMinX) bounds.boundMinX = vertex.cameraX;
				if (vertex.cameraX > bounds.boundMaxX) bounds.boundMaxX = vertex.cameraX;
				if (vertex.cameraY < bounds.boundMinY) bounds.boundMinY = vertex.cameraY;
				if (vertex.cameraY > bounds.boundMaxY) bounds.boundMaxY = vertex.cameraY;
				if (vertex.cameraZ < bounds.boundMinZ) bounds.boundMinZ = vertex.cameraZ;
				if (vertex.cameraZ > bounds.boundMaxZ) bounds.boundMaxZ = vertex.cameraZ;
			}
		}
	
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			var vertex:Vertex;
			// Коррекция куллинга
			var culling:int = object.culling;
			if (clipping == 0) {
				if (culling & 1) return null;
				culling = 0;
			}
			// Расчёт инверсной матрицы камеры
			calculateInverseMatrix(object);
			// Обнуление вершин
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.cameraX = 0;
				vertex.cameraY = 0;
				vertex.cameraZ = 0;
				vertex.transformID = 1;
				//trace(vertex.transformID);
				vertex.drawID = 0;
			}
			// Расчёт координат вершин
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.getGeometry(camera, object);
			}
			// Получение клона видимой геометрии
			var struct:Face;
			if (sorting == 3) {
				return null;
			} else {
				if (faceList == null) return null;
				struct = calculateFaces(faceList, culling, camera, object.ma, object.mb, object.mc, object.md, object.me, object.mf, object.mg, object.mh, object.mi, object.mj, object.mk, object.ml);
			}
			// Зачистка после ремапа
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
			// Создание геометрии
			if (struct != null) {
				var geometry:Geometry = Geometry.create();
				geometry.interactiveObject = object;
				geometry.faceStruct = struct;
				geometry.ma = object.ma;
				geometry.mb = object.mb;
				geometry.mc = object.mc;
				geometry.md = object.md;
				geometry.me = object.me;
				geometry.mf = object.mf;
				geometry.mg = object.mg;
				geometry.mh = object.mh;
				geometry.mi = object.mi;
				geometry.mj = object.mj;
				geometry.mk = object.mk;
				geometry.ml = object.ml;
				geometry.ima = ima;
				geometry.imb = imb;
				geometry.imc = imc;
				geometry.imd = imd;
				geometry.ime = ime;
				geometry.imf = imf;
				geometry.img = img;
				geometry.imh = imh;
				geometry.imi = imi;
				geometry.imj = imj;
				geometry.imk = imk;
				geometry.iml = iml;
				geometry.alpha = object.alpha;
				geometry.blendMode = object.blendMode;
				geometry.colorTransform = object.colorTransform;
				geometry.filters = object.filters;
				geometry.sorting = sorting;
				if (camera.debug) geometry.debug = camera.checkInDebug(this);
				return geometry;
			} else {
				return null;
			}
		}
		
		override protected function calculateFaces(struct:Face, culling:int, camera:Camera3D, ma:Number, mb:Number, mc:Number, md:Number, me:Number, mf:Number, mg:Number, mh:Number, mi:Number, mj:Number, mk:Number, ml:Number):Face {
			var first:Face;
			var last:Face;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var d:Wrapper;
			var v:Vertex;
			var w:Wrapper;
			var wFirst:Wrapper;
			var wLast:Wrapper;
			var wNext:Wrapper;
			var wNew:Wrapper;
			var ax:Number;
			var ay:Number;
			var az:Number;
			var bx:Number;
			var by:Number;
			var bz:Number;
			var cx:Number;
			var cy:Number;
			var cz:Number;
			var c1:Boolean = (culling & 1) > 0;
			var c2:Boolean = (culling & 2) > 0;
			var c4:Boolean = (culling & 4) > 0;
			var c8:Boolean = (culling & 8) > 0;
			var c16:Boolean = (culling & 16) > 0;
			var c32:Boolean = (culling & 32) > 0;
			var near:Number = camera.nearClipping;
			var far:Number = camera.farClipping;
			var needX:Boolean = c4 || c8;
			var needY:Boolean = c16 || c32;
			var t:Number;
			// Перебор оригинальных граней
			for (var face:Face = struct; face != null; face = face.next) {
				// Отсечение по нормали
				d = face.wrapper;
				a = d.vertex;
				d = d.next;
				b = d.vertex;
				d = d.next;
				c = d.vertex;
				d = d.next;
				var abx:Number = b.cameraX - a.cameraX;
				var aby:Number = b.cameraY - a.cameraY;
				var abz:Number = b.cameraZ - a.cameraZ;
				var acx:Number = c.cameraX - a.cameraX;
				var acy:Number = c.cameraY - a.cameraY;
				var acz:Number = c.cameraZ - a.cameraZ;
				if ((acz*aby - acy*abz)*a.cameraX + (acx*abz - acz*abx)*a.cameraY + (acy*abx - acx*aby)*a.cameraZ >= 0) continue;
				var faceCulling:int = 0;
				// Отсечение по пирамиде видимости
				if (culling > 0) {
					if (needX) {
						ax = a.cameraX;
						bx = b.cameraX;
						cx = c.cameraX;
					}
					if (needY) {
						ay = a.cameraY;
						by = b.cameraY;
						cy = c.cameraY;
					}
					az = a.cameraZ;
					bz = b.cameraZ;
					cz = c.cameraZ;
					// Куллинг
					if (clipping == 1) {
						if (c1) {
							if (az <= near || bz <= near || cz <= near) continue;
							for (w = d; w != null; w = w.next) {
								if (w.vertex.cameraZ <= near) break;
							}
							if (w != null) continue;
						}
						if (c2 && az >= far && bz >= far && cz >= far) {
							for (w = d; w != null; w = w.next) {
								if (w.vertex.cameraZ < far) break;
							}
							if (w == null) continue;
						}
						if (c4 && az <= -ax && bz <= -bx && cz <= -cx) {
							for (w = d; w != null; w = w.next) {
								v = w.vertex;
								if (-v.cameraX < v.cameraZ) break;
							}
							if (w == null) continue;
						}
						if (c8 && az <= ax && bz <= bx && cz <= cx) {
							for (w = d; w != null; w = w.next) {
								v = w.vertex;
								if (v.cameraX < v.cameraZ) break;
							}
							if (w == null) continue;
						}
						if (c16 && az <= -ay && bz <= -by && cz <= -cy) {
							for (w = d; w != null; w = w.next) {
								v = w.vertex;
								if (-v.cameraY < v.cameraZ) break;
							}
							if (w == null) continue;
						}
						if (c32 && az <= ay && bz <= by && cz <= cy) {
							for (w = d; w != null; w = w.next) {
								v = w.vertex;
								if (v.cameraY < v.cameraZ) break;
							}
							if (w == null) continue;
						}
						// Клиппинг
					} else {
						if (c1) {
							if (az <= near && bz <= near && cz <= near) {
								for (w = d; w != null; w = w.next) {
									if (w.vertex.cameraZ > near) {
										faceCulling |= 1;
										break;
									}
								}
								if (w == null) continue;
							} else if (az > near && bz > near && cz > near) {
								for (w = d; w != null; w = w.next) {
									if (w.vertex.cameraZ <= near) {
										faceCulling |= 1;
										break;
									}
								}
							} else {
								faceCulling |= 1;
							}
						}
						if (c2) {
							if (az >= far && bz >= far && cz >= far) {
								for (w = d; w != null; w = w.next) {
									if (w.vertex.cameraZ < far) {
										faceCulling |= 2;
										break;
									}
								}
								if (w == null) continue;
							} else if (az < far && bz < far && cz < far) {
								for (w = d; w != null; w = w.next) {
									if (w.vertex.cameraZ >= far) {
										faceCulling |= 2;
										break;
									}
								}
							} else {
								faceCulling |= 2;
							}
						}
						if (c4) {
							if (az <= -ax && bz <= -bx && cz <= -cx) {
								for (w = d; w != null; w = w.next) {
									v = w.vertex;
									if (-v.cameraX < v.cameraZ) {
										faceCulling |= 4;
										break;
									}
								}
								if (w == null) continue;
							} else if (az > -ax && bz > -bx && cz > -cx) {
								for (w = d; w != null; w = w.next) {
									v = w.vertex;
									if (-v.cameraX >= v.cameraZ) {
										faceCulling |= 4;
										break;
									}
								}
							} else {
								faceCulling |= 4;
							}
						}
						if (c8) {
							if (az <= ax && bz <= bx && cz <= cx) {
								for (w = d; w != null; w = w.next) {
									v = w.vertex;
									if (v.cameraX < v.cameraZ) {
										faceCulling |= 8;
										break;
									}
								}
								if (w == null) continue;
							} else if (az > ax && bz > bx && cz > cx) {
								for (w = d; w != null; w = w.next) {
									v = w.vertex;
									if (v.cameraX >= v.cameraZ) {
										faceCulling |= 8;
										break;
									}
								}
							} else {
								faceCulling |= 8;
							}
						}
						if (c16) {
							if (az <= -ay && bz <= -by && cz <= -cy) {
								for (w = d; w != null; w = w.next) {
									v = w.vertex;
									if (-v.cameraY < v.cameraZ) {
										faceCulling |= 16;
										break;
									}
								}
								if (w == null) continue;
							} else if (az > -ay && bz > -by && cz > -cy) {
								for (w = d; w != null; w = w.next) {
									v = w.vertex;
									if (-v.cameraY >= v.cameraZ) {
										faceCulling |= 16;
										break;
									}
								}
							} else {
								faceCulling |= 16;
							}
						}
						if (c32) {
							if (az <= ay && bz <= by && cz <= cy) {
								for (w = d; w != null; w = w.next) {
									v = w.vertex;
									if (v.cameraY < v.cameraZ) {
										faceCulling |= 32;
										break;
									}
								}
								if (w == null) continue;
							} else if (az > ay && bz > by && cz > cy) {
								for (w = d; w != null; w = w.next) {
									v = w.vertex;
									if (v.cameraY >= v.cameraZ) {
										faceCulling |= 32;
										break;
									}
								}
							} else {
								faceCulling |= 32;
							}
						}
						if (faceCulling > 0) {
							wFirst = null;
							wLast = null;
							w = face.wrapper;
							while (w != null) {
								wNew = w.create();
								wNew.vertex = w.vertex;
								if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
								wLast = wNew;
								w = w.next;
							}
							// Клиппинг по передней стороне
							if (faceCulling & 1) {
								a = wLast.vertex;
								az = a.cameraZ;
								for (w = wFirst,wFirst = null,wLast = null; w != null; w = wNext) {
									wNext = w.next;
									b = w.vertex;
									bz = b.cameraZ;
									if (bz > near && az <= near || bz <= near && az > near) {
										t = (near - az)/(bz - az);
										v = b.create();
										camera.lastVertex.next = v;
										camera.lastVertex = v;
										v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
										v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
										v.cameraZ = az + (bz - az)*t;
										v.u = a.u + (b.u - a.u)*t;
										v.v = a.v + (b.v - a.v)*t;
										wNew = w.create();
										wNew.vertex = v;
										if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
										wLast = wNew;
									}
									if (bz > near) {
										if (wFirst != null) wLast.next = w; else wFirst = w;
										wLast = w;
										w.next = null;
									} else {
										w.vertex = null;
										w.next = Wrapper.collector;
										Wrapper.collector = w;
									}
									a = b;
									az = bz;
								}
								if (wFirst == null) continue;
							}
							// Клиппинг по задней стороне
							if (faceCulling & 2) {
								a = wLast.vertex;
								az = a.cameraZ;
								for (w = wFirst,wFirst = null,wLast = null; w != null; w = wNext) {
									wNext = w.next;
									b = w.vertex;
									bz = b.cameraZ;
									if (bz < far && az >= far || bz >= far && az < far) {
										t = (far - az)/(bz - az);
										v = b.create();
										camera.lastVertex.next = v;
										camera.lastVertex = v;
										v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
										v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
										v.cameraZ = az + (bz - az)*t;
										v.u = a.u + (b.u - a.u)*t;
										v.v = a.v + (b.v - a.v)*t;
										wNew = w.create();
										wNew.vertex = v;
										if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
										wLast = wNew;
									}
									if (bz < far) {
										if (wFirst != null) wLast.next = w; else wFirst = w;
										wLast = w;
										w.next = null;
									} else {
										w.vertex = null;
										w.next = Wrapper.collector;
										Wrapper.collector = w;
									}
									a = b;
									az = bz;
								}
								if (wFirst == null) continue;
							}
							// Клиппинг по левой стороне
							if (faceCulling & 4) {
								a = wLast.vertex;
								ax = a.cameraX;
								az = a.cameraZ;
								for (w = wFirst,wFirst = null,wLast = null; w != null; w = wNext) {
									wNext = w.next;
									b = w.vertex;
									bx = b.cameraX;
									bz = b.cameraZ;
									if (bz > -bx && az <= -ax || bz <= -bx && az > -ax) {
										t = (ax + az)/(ax + az - bx - bz);
										v = b.create();
										camera.lastVertex.next = v;
										camera.lastVertex = v;
										v.cameraX = ax + (bx - ax)*t;
										v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
										v.cameraZ = az + (bz - az)*t;
										v.u = a.u + (b.u - a.u)*t;
										v.v = a.v + (b.v - a.v)*t;
										wNew = w.create();
										wNew.vertex = v;
										if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
										wLast = wNew;
									}
									if (bz > -bx) {
										if (wFirst != null) wLast.next = w; else wFirst = w;
										wLast = w;
										w.next = null;
									} else {
										w.vertex = null;
										w.next = Wrapper.collector;
										Wrapper.collector = w;
									}
									a = b;
									ax = bx;
									az = bz;
								}
								if (wFirst == null) continue;
							}
							// Клипинг по правой стороне
							if (faceCulling & 8) {
								a = wLast.vertex;
								ax = a.cameraX;
								az = a.cameraZ;
								for (w = wFirst,wFirst = null,wLast = null; w != null; w = wNext) {
									wNext = w.next;
									b = w.vertex;
									bx = b.cameraX;
									bz = b.cameraZ;
									if (bz > bx && az <= ax || bz <= bx && az > ax) {
										t = (az - ax)/(az - ax + bx - bz);
										v = b.create();
										camera.lastVertex.next = v;
										camera.lastVertex = v;
										v.cameraX = ax + (bx - ax)*t;
										v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
										v.cameraZ = az + (bz - az)*t;
										v.u = a.u + (b.u - a.u)*t;
										v.v = a.v + (b.v - a.v)*t;
										wNew = w.create();
										wNew.vertex = v;
										if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
										wLast = wNew;
									}
									if (bz > bx) {
										if (wFirst != null) wLast.next = w; else wFirst = w;
										wLast = w;
										w.next = null;
									} else {
										w.vertex = null;
										w.next = Wrapper.collector;
										Wrapper.collector = w;
									}
									a = b;
									ax = bx;
									az = bz;
								}
								if (wFirst == null) continue;
							}
							// Клипинг по верхней стороне
							if (faceCulling & 16) {
								a = wLast.vertex;
								ay = a.cameraY;
								az = a.cameraZ;
								for (w = wFirst,wFirst = null,wLast = null; w != null; w = wNext) {
									wNext = w.next;
									b = w.vertex;
									by = b.cameraY;
									bz = b.cameraZ;
									if (bz > -by && az <= -ay || bz <= -by && az > -ay) {
										t = (ay + az)/(ay + az - by - bz);
										v = b.create();
										camera.lastVertex.next = v;
										camera.lastVertex = v;
										v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
										v.cameraY = ay + (by - ay)*t;
										v.cameraZ = az + (bz - az)*t;
										v.u = a.u + (b.u - a.u)*t;
										v.v = a.v + (b.v - a.v)*t;
										wNew = w.create();
										wNew.vertex = v;
										if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
										wLast = wNew;
									}
									if (bz > -by) {
										if (wFirst != null) wLast.next = w; else wFirst = w;
										wLast = w;
										w.next = null;
									} else {
										w.vertex = null;
										w.next = Wrapper.collector;
										Wrapper.collector = w;
									}
									a = b;
									ay = by;
									az = bz;
								}
								if (wFirst == null) continue;
							}
							// Клипинг по нижней стороне
							if (faceCulling & 32) {
								a = wLast.vertex;
								ay = a.cameraY;
								az = a.cameraZ;
								for (w = wFirst,wFirst = null,wLast = null; w != null; w = wNext) {
									wNext = w.next;
									b = w.vertex;
									by = b.cameraY;
									bz = b.cameraZ;
									if (bz > by && az <= ay || bz <= by && az > ay) {
										t = (az - ay)/(az - ay + by - bz);
										v = b.create();
										camera.lastVertex.next = v;
										camera.lastVertex = v;
										v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
										v.cameraY = ay + (by - ay)*t;
										v.cameraZ = az + (bz - az)*t;
										v.u = a.u + (b.u - a.u)*t;
										v.v = a.v + (b.v - a.v)*t;
										wNew = w.create();
										wNew.vertex = v;
										if (wFirst != null) wLast.next = wNew; else wFirst = wNew;
										wLast = wNew;
									}
									if (bz > by) {
										if (wFirst != null) wLast.next = w; else wFirst = w;
										wLast = w;
										w.next = null;
									} else {
										w.vertex = null;
										w.next = Wrapper.collector;
										Wrapper.collector = w;
									}
									a = b;
									ay = by;
									az = bz;
								}
								if (wFirst == null) continue;
							}
						}
					}
				}
				var newFace:Face = face.create();
				camera.lastFace.next = newFace;
				camera.lastFace = newFace;
				newFace.material = face.material;
				var newVertex:Vertex;
				if (faceCulling > 0) {
					for (w = wFirst; w != null; w = w.next) {
						v = w.vertex;
						if (v.value != null) {
							w.vertex = v.value;
						} else if (v.transformID > 0) {
							newVertex = v.create();
							camera.lastVertex.next = newVertex;
							camera.lastVertex = newVertex;
							newVertex.cameraX = v.cameraX;
							newVertex.cameraY = v.cameraY;
							newVertex.cameraZ = v.cameraZ;
							newVertex.u = v.u;
							newVertex.v = v.v;
							v.value = newVertex;
							w.vertex = newVertex;
						}
					}
				} else {
					wFirst = null;
					for (w = face.wrapper; w != null; w = w.next) {
						wNew = w.create();
						v = w.vertex;
						if (v.value == null) {
							newVertex = v.create();
							camera.lastVertex.next = newVertex;
							camera.lastVertex = newVertex;
							newVertex.cameraX = v.cameraX;
							newVertex.cameraY = v.cameraY;
							newVertex.cameraZ = v.cameraZ;
							newVertex.u = v.u;
							newVertex.v = v.v;
							v.value = newVertex;
						}
						wNew.vertex = v.value;
						if (wFirst != null) {
							wLast.next = wNew;
						} else {
							wFirst = wNew;
						}
						wLast = wNew;
					}
				}
				newFace.wrapper = wFirst;
				if (first != null) {
					last.processNext = newFace;
				} else {
					first = newFace;
				}
				last = newFace;
			}
			return first;
		}
		
	}
}
