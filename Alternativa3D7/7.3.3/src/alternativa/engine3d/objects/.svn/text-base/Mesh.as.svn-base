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
	import alternativa.engine3d.materials.Material;
	
	import flash.utils.Dictionary;
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;
	
	/**
	 * Полигональный объект
	 */
	public class Mesh extends Object3D {
	
		/**
		 * Режим отсечения объекта по пирамиде видимости камеры.
		 * 0 - весь объект
		 * 1 - по граням
		 * 2 - клиппинг граней по пирамиде видимости камеры
		 */
		public var clipping:int = 2;
		/**
		 * Режим сортировки полигонов
		 * 0 - без сортировки
		 * 1 - сортировка по средним Z
		 * 2 - построение динамического BSP при отрисовке
		 * 3 - проход по предрасчитанному BSP. Для расчёта BSP нужен calculateBSP()
		 */
		public var sorting:int = 1;
		/**
		 * Геометрическая погрешность при расчёте BSP-дерева
		 */
		public var threshold:Number = 0.01;
	
		public var faceList:Face;
		public var vertexList:Vertex;
	
		public var faceTree:Face;
		public var bspVertexList:Vertex;
	
		protected var transformID:int = 0;
	
		public function addVertex(x:Number, y:Number, z:Number, u:Number, v:Number):Vertex {
			var vertex:Vertex = new Vertex();
			vertex.x = x;
			vertex.y = y;
			vertex.z = z;
			vertex.u = u;
			vertex.v = v;
			vertex.next = vertexList;
			vertexList = vertex;
			return vertex;
		}
	
		public function removeVertex(vertex:Vertex):void {
			if (vertexList == vertex) vertexList = vertex.next;
			for (var v:Vertex = vertexList; v != null; v = v.next) {
				if (v.next == vertex) {
					v.next = v.next.next;
					return;
				}
			}
		}
	
		public function addFace(vertices:Vector.<Vertex>, material:Material = null):Face {
			var face:Face = new Face();
			face.next = faceList;
			faceList = face;
			face.material = material;
			var wrapper:Wrapper = new Wrapper();
			face.wrapper = wrapper;
			wrapper.vertex = vertices[0];
			var length:int = vertices.length;
			for (var i:int = 1; i < length; i++) {
				wrapper.next = new Wrapper();
				wrapper = wrapper.next;
				wrapper.vertex = vertices[i];
			}
			return face;
		}
	
		public function addTriFace(v1:Vertex, v2:Vertex, v3:Vertex, material:Material = null):Face {
			var face:Face = new Face();
			face.next = faceList;
			faceList = face;
			face.material = material;
			var wrapper:Wrapper = new Wrapper();
			face.wrapper = wrapper;
			wrapper.vertex = v1;
			wrapper.next = new Wrapper();
			wrapper = wrapper.next;
			wrapper.vertex = v2;
			wrapper.next = new Wrapper();
			wrapper = wrapper.next;
			wrapper.vertex = v3;
			return face;
		}
	
		public function addQuadFace(v1:Vertex, v2:Vertex, v3:Vertex, v4:Vertex, material:Material = null):Face {
			var face:Face = new Face();
			face.next = faceList;
			faceList = face;
			face.material = material;
			var wrapper:Wrapper = new Wrapper();
			face.wrapper = wrapper;
			wrapper.vertex = v1;
			wrapper.next = new Wrapper();
			wrapper = wrapper.next;
			wrapper.vertex = v2;
			wrapper.next = new Wrapper();
			wrapper = wrapper.next;
			wrapper.vertex = v3;
			wrapper.next = new Wrapper();
			wrapper = wrapper.next;
			wrapper.vertex = v4;
			return face;
		}
	
		public function addGeometryByIndices(vertices:Vector.<Number>, uvs:Vector.<Number>, indices:Vector.<int>, material:Material = null):void {
			var i:int, j:int, k:int;
			var length:int = vertices.length/3;
			var verts:Vector.<Vertex> = new Vector.<Vertex>(length);
			var vertex:Vertex;
			for (i = 0,j = 0,k = 0; i < length; i++) {
				vertex = new Vertex();
				vertex.x = vertices[j];
				j++;
				vertex.y = vertices[j];
				j++;
				vertex.z = vertices[j];
				j++;
				vertex.u = uvs[k];
				k++;
				vertex.v = uvs[k];
				k++;
				verts[i] = vertex;
				vertex.next = vertexList;
				vertexList = vertex;
			}
			length = indices.length/3;
			var face:Face;
			for (i = 0,j = 0; i < length; i++) {
				face = new Face();
				face.next = faceList;
				faceList = face;
				face.material = material;
				var wrapper:Wrapper = new Wrapper();
				face.wrapper = wrapper;
				k = indices[j];
				wrapper.vertex = verts[k];
				j++;
				wrapper.next = new Wrapper();
				wrapper = wrapper.next;
				k = indices[j];
				wrapper.vertex = verts[k];
				j++;
				wrapper.next = new Wrapper();
				wrapper = wrapper.next;
				k = indices[j];
				wrapper.vertex = verts[k];
				j++;
			}
		}
	
		public function addGeometryByVectors(vertices:Vector.<Vertex>, faces:Vector.<Face>):void {
			var i:int;
			var length:int = vertices.length;
			var vertex:Vertex;
			for (i = 0; i < length; i++) {
				vertex = vertices[i];
				vertex.next = vertexList;
				vertexList = vertex;
			}
			length = faces.length;
			var face:Face;
			for (i = 0; i < length; i++) {
				face = faces[i];
				face.next = faceList;
				faceList = face;
			}
		}
	
		public function setMaterialToAllFaces(material:Material = null):void {
			for (var face:Face = faceList; face != null; face = face.next) {
				face.material = material;
			}
			if (faceTree != null) {
				setMaterialToTree(faceTree, material);
			}
		}
	
		private function setMaterialToTree(tree:Face, material:Material):void {
			for (var face:Face = tree; face != null; face = face.next) {
				face.material = material;
			}
			if (tree.negative != null) {
				setMaterialToTree(tree.negative, material);
			}
			if (tree.positive != null) {
				setMaterialToTree(tree.positive, material);
			}
		}
		
		/**
		 * @param textureWidth
		 * @param textureHeight
		 * @param type 0 - по первому ребру, 1 - среднее значение, 2 - минимальное значение, 3 - максимальное значение
		 * @param matrix трансформация
		 * @return resolution 
		 */
		public function calculateResolution(textureWidth:int, textureHeight:int, type:int = 1, matrix:Matrix3D = null):Number {
			if (faceList != null) {
				var object:Object3D;
				if (matrix != null) {
					object = new Object3D();
					object.setMatrix(matrix);
					object.composeMatrix();
				}
				var min:Number = 1e+22;
				var max:Number = 0;
				var sum:Number = 0;
				var num:int = 0;
				for (var face:Face = faceList; face != null; face = face.next) {
					for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
						var a:Vertex = wrapper.vertex;
						var b:Vertex = wrapper.next != null ? wrapper.next.vertex : face.wrapper.vertex;
						var dx:Number = (matrix != null) ? (object.ma*(b.x - a.x) + object.mb*(b.y - a.y) + object.mc*(b.z - a.z)) : (b.x - a.x);
						var dy:Number = (matrix != null) ? (object.me*(b.x - a.x) + object.mf*(b.y - a.y) + object.mg*(b.z - a.z)) : (b.y - a.y);
						var dz:Number = (matrix != null) ? (object.mi*(b.x - a.x) + object.mj*(b.y - a.y) + object.mk*(b.z - a.z)) : (b.z - a.z);
						var du:Number = (b.u - a.u)*textureWidth;
						var dv:Number = (b.v - a.v)*textureHeight;
						var res:Number = Math.sqrt(dx*dx + dy*dy + dz*dz)/Math.sqrt(du*du + dv*dv);
						if (res < min) min = res;
						if (res > max) max = res;
						sum += res;
						num++;
						if (type == 0) return sum;
					}
				}
				return (type == 1) ? sum/num : ((type == 2) ? min : max);
			}
			return 1;
		}
		
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var canvas:Canvas;
			var debug:int;
			var list:Face;
			var vertex:Vertex;
			// Сброс итератора трансформаций
			if (transformID > 500000000) {
				transformID = 0;
				//for (vertex = vertexList; vertex != null; vertex.transformID = 0, vertex = vertex.next);
				vertex = vertexList;
				while (vertex != null) {
					vertex.transformID = 0;
					vertex = vertex.next;
				}
				//for (vertex = bspVertexList; vertex != null; vertex.transformID = 0, vertex = vertex.next);
				vertex = bspVertexList;
				while (vertex != null) {
					vertex.transformID = 0;
					vertex = vertex.next;
				}
			}
			// Коррекция куллинга
			var culling:int = object.culling;
			if (clipping == 0) {
				if (culling & 1) return;
				culling = 0;
			}
			// Расчёт инверсной матрицы камеры
			calculateInverseMatrix(object);
			// Отсечение по нормалям
			if (sorting == 3) {
				if (faceTree == null) return;
				list = collectNode(faceTree);
			} else {
				if (faceList == null) return;
				list = backfaceCull(faceList);
			}
			if (list == null) return;
			// Трансформация в камеру
			transformID++;
			transform(list, object.ma, object.mb, object.mc, object.md, object.me, object.mf, object.mg, object.mh, object.mi, object.mj, object.mk, object.ml);
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
	
		protected function transform(list:Face, ma:Number, mb:Number, mc:Number, md:Number, me:Number, mf:Number, mg:Number, mh:Number, mi:Number, mj:Number, mk:Number, ml:Number):void {
			// Трансформация вершин граней
			for (var face:Face = list; face != null; face = face.processNext) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					if (vertex.transformID != transformID) {
						var x:Number = vertex.x;
						var y:Number = vertex.y;
						var z:Number = vertex.z;
						vertex.cameraX = ma*x + mb*y + mc*z + md;
						vertex.cameraY = me*x + mf*y + mg*z + mh;
						vertex.cameraZ = mi*x + mj*y + mk*z + ml;
						vertex.transformID = transformID;
						vertex.drawID = 0;
					}
				}
			}
		}
	
		private function collectNode(tree:Face, readyList:Face = null):Face {
			if (tree.normalX*imd + tree.normalY*imh + tree.normalZ*iml > tree.offset) {
				if (tree.positive != null) readyList = collectNode(tree.positive, readyList);
				for (var face:Face = tree; face != null; face = face.next) {
					face.processNext = readyList;
					readyList = face;
				}
				if (tree.negative != null) readyList = collectNode(tree.negative, readyList);
			} else {
				if (tree.negative != null) readyList = collectNode(tree.negative, readyList);
				if (tree.positive != null) readyList = collectNode(tree.positive, readyList);
			}
			return readyList;
		}
	
		private function backfaceCull(list:Face):Face {
			var first:Face;
			var last:Face;
			for (var face:Face = list; face != null; face = face.next) {
				if (face.normalX*imd + face.normalY*imh + face.normalZ*iml > face.offset) {
					if (first != null) {
						last.processNext = face;
					} else {
						first = face;
					}
					last = face;
				}
			}
			if (last != null) {
				last.processNext = null;
			}
			return first;
		}
	
		protected function cull(list:Face, culling:int, camera:Camera3D):Face {
			var first:Face;
			var last:Face;
			var next:Face;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var d:Wrapper;
			var v:Vertex;
			var w:Wrapper;
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
			for (var face:Face = list; face != null; face = next) {
				next = face.processNext;
				d = face.wrapper;
				a = d.vertex;
				d = d.next;
				b = d.vertex;
				d = d.next;
				c = d.vertex;
				d = d.next;
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
				if (c1) {
					if (az <= near || bz <= near || cz <= near) {
						face.processNext = null;
						continue;
					}
					for (w = d; w != null; w = w.next) {
						if (w.vertex.cameraZ <= near) break;
					}
					if (w != null) {
						face.processNext = null;
						continue;
					}
				}
				if (c2 && az >= far && bz >= far && cz >= far) {
					for (w = d; w != null; w = w.next) {
						if (w.vertex.cameraZ < far) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (c4 && az <= -ax && bz <= -bx && cz <= -cx) {
					for (w = d; w != null; w = w.next) {
						v = w.vertex;
						if (-v.cameraX < v.cameraZ) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (c8 && az <= ax && bz <= bx && cz <= cx) {
					for (w = d; w != null; w = w.next) {
						v = w.vertex;
						if (v.cameraX < v.cameraZ) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (c16 && az <= -ay && bz <= -by && cz <= -cy) {
					for (w = d; w != null; w = w.next) {
						v = w.vertex;
						if (-v.cameraY < v.cameraZ) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (c32 && az <= ay && bz <= by && cz <= cy) {
					for (w = d; w != null; w = w.next) {
						v = w.vertex;
						if (v.cameraY < v.cameraZ) break;
					}
					if (w == null) {
						face.processNext = null;
						continue;
					}
				}
				if (first != null) {
					last.processNext = face;
				} else {
					first = face;
				}
				last = face;
			}
			if (last != null) {
				last.processNext = null;
			}
			return first;
		}
	
		protected function clip(list:Face, culling:int, camera:Camera3D):Face {
			var first:Face;
			var last:Face;
			var next:Face;
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
			var faceCulling:int;
			var t:Number;
			for (var face:Face = list; face != null; face = next) {
				next = face.processNext;
				d = face.wrapper;
				a = d.vertex;
				d = d.next;
				b = d.vertex;
				d = d.next;
				c = d.vertex;
				d = d.next;
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
				faceCulling = 0;
				if (c1) {
					if (az <= near && bz <= near && cz <= near) {
						for (w = d; w != null; w = w.next) {
							if (w.vertex.cameraZ > near) {
								faceCulling |= 1;
								break;
							}
						}
						if (w == null) {
							face.processNext = null;
							continue;
						}
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
						if (w == null) {
							face.processNext = null;
							continue;
						}
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
						if (w == null) {
							face.processNext = null;
							continue;
						}
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
						if (w == null) {
							face.processNext = null;
							continue;
						}
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
						if (w == null) {
							face.processNext = null;
							continue;
						}
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
						if (w == null) {
							face.processNext = null;
							continue;
						}
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
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
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
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
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
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
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
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
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
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
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
						if (wFirst == null) {
							face.processNext = null;
							continue;
						}
					}
					face.processNext = null;
					var newFace:Face = face.create();
					newFace.material = face.material;
					camera.lastFace.next = newFace;
					camera.lastFace = newFace;
					newFace.wrapper = wFirst;
					face = newFace;
				}
				if (first != null) {
					last.processNext = face;
				} else {
					first = face;
				}
				last = face;
			}
			if (last != null) {
				last.processNext = null;
			}
			return first;
		}
	
		protected function sortByAverageZ(list:Face):Face {
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
	
		protected function sortByDynamicBSP(list:Face, camera:Camera3D, threshold:Number, result:Face = null):Face {
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
	
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			var vertex:Vertex;
			// Сброс итератора трансформаций
			if (transformID > 500000000) {
				transformID = 0;
				//for (vertex = vertexList; vertex != null; vertex.transformID = 0, vertex = vertex.next);
				vertex = vertexList;
				while (vertex != null) {
					vertex.transformID = 0;
					vertex = vertex.next;
				}
				//for (vertex = bspVertexList; vertex != null; vertex.transformID = 0, vertex = vertex.next);
				vertex = bspVertexList;
				while (vertex != null) {
					vertex.transformID = 0;
					vertex = vertex.next;
				}
			}
			// Коррекция куллинга
			var culling:int = object.culling;
			if (clipping == 0) {
				if (culling & 1) return null;
				culling = 0;
			}
			// Расчёт инверсной матрицы камеры
			calculateInverseMatrix(object);
			// Инкркмент итератора трансформаций
			transformID++;
			// Получение клона видимой геометрии
			var struct:Face;
			if (sorting == 3) {
				if (faceTree == null) return null;
				struct = calculateFaces(faceTree, culling, camera, object.ma, object.mb, object.mc, object.md, object.me, object.mf, object.mg, object.mh, object.mi, object.mj, object.mk, object.ml);
			} else {
				if (faceList == null) return null;
				struct = calculateFaces(faceList, culling, camera, object.ma, object.mb, object.mc, object.md, object.me, object.mf, object.mg, object.mh, object.mi, object.mj, object.mk, object.ml);
			}
			// Зачистка после ремапа
			for (vertex = (sorting == 3) ? bspVertexList : vertexList; vertex != null; vertex = vertex.next) {
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
	
		protected function calculateFaces(struct:Face, culling:int, camera:Camera3D, ma:Number, mb:Number, mc:Number, md:Number, me:Number, mf:Number, mg:Number, mh:Number, mi:Number, mj:Number, mk:Number, ml:Number):Face {
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
			// Если не BSP или нода видна
			if (sorting != 3 || imd*struct.normalX + imh*struct.normalY + iml*struct.normalZ > struct.offset) {
				// Перебор оригинальных граней
				for (var face:Face = struct; face != null; face = face.next) {
					// Отсечение по нормали
					if (sorting != 3 && imd*face.normalX + imh*face.normalY + iml*face.normalZ <= face.offset) continue;
					// Трансформация
					for (w = face.wrapper; w != null; w = w.next) {
						v = w.vertex;
						if (v.transformID != transformID) {
							ax = v.x;
							ay = v.y;
							az = v.z;
							v.cameraX = ma*ax + mb*ay + mc*az + md;
							v.cameraY = me*ax + mf*ay + mg*az + mh;
							v.cameraZ = mi*ax + mj*ay + mk*az + ml;
							v.transformID = transformID;
						}
					}
					var faceCulling:int = 0;
					// Отсечение по пирамиде видимости
					if (culling > 0) {
						d = face.wrapper;
						a = d.vertex;
						d = d.next;
						b = d.vertex;
						d = d.next;
						c = d.vertex;
						d = d.next;
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
			}
			// Если BSP
			if (sorting == 3) {
				var negative:Face = (struct.negative != null) ? calculateFaces(struct.negative, culling, camera, ma, mb, mc, md, me, mf, mg, mh, mi, mj, mk, ml) : null;
				var positive:Face = (struct.positive != null) ? calculateFaces(struct.positive, culling, camera, ma, mb, mc, md, me, mf, mg, mh, mi, mj, mk, ml) : null;
				// Если нода видна или есть видимые дочерние ноды
				if (first != null || negative != null && positive != null) {
					if (first == null) {
						// Создание пустой ноды
						first = struct.create();
						camera.lastFace.next = first;
						camera.lastFace = first;
					}
					// Расчёт нормали
					w = struct.wrapper;
					a = w.vertex;
					w = w.next;
					b = w.vertex;
					w = w.next;
					c = w.vertex;
					if (a.transformID != transformID) {
						ax = a.x;
						ay = a.y;
						az = a.z;
						a.cameraX = ma*ax + mb*ay + mc*az + md;
						a.cameraY = me*ax + mf*ay + mg*az + mh;
						a.cameraZ = mi*ax + mj*ay + mk*az + ml;
						a.transformID = transformID;
					}
					if (b.transformID != transformID) {
						ax = b.x;
						ay = b.y;
						az = b.z;
						b.cameraX = ma*ax + mb*ay + mc*az + md;
						b.cameraY = me*ax + mf*ay + mg*az + mh;
						b.cameraZ = mi*ax + mj*ay + mk*az + ml;
						b.transformID = transformID;
					}
					if (c.transformID != transformID) {
						ax = c.x;
						ay = c.y;
						az = c.z;
						c.cameraX = ma*ax + mb*ay + mc*az + md;
						c.cameraY = me*ax + mf*ay + mg*az + mh;
						c.cameraZ = mi*ax + mj*ay + mk*az + ml;
						c.transformID = transformID;
					}
					ax = a.cameraX;
					ay = a.cameraY;
					az = a.cameraZ;
					var abx:Number = b.cameraX - ax;
					var aby:Number = b.cameraY - ay;
					var abz:Number = b.cameraZ - az;
					var acx:Number = c.cameraX - ax;
					var acy:Number = c.cameraY - ay;
					var acz:Number = c.cameraZ - az;
					var nx:Number = acz*aby - acy*abz;
					var ny:Number = acx*abz - acz*abx;
					var nz:Number = acy*abx - acx*aby;
					var nl:Number = nx*nx + ny*ny + nz*nz;
					if (nl > 0) {
						nl = 1/Math.sqrt(length);
						nx *= nl;
						ny *= nl;
						nz *= nl;
					}
					first.normalX = nx;
					first.normalY = ny;
					first.normalZ = nz;
					first.offset = ax*nx + ay*ny + az*nz;
					first.negative = negative;
					first.positive = positive;
				} else {
					first = (negative != null) ? negative : positive;
				}
			}
			return first;
		}
	
		/**
		 * Расчёт нормалей
		 * @param normalize Флаг нормализации
		 */
		public function calculateNormals(normalize:Boolean = false):void {
			for (var face:Face = faceList; face != null; face = face.next) {
				var w:Wrapper = face.wrapper;
				var a:Vertex = w.vertex;
				w = w.next;
				var b:Vertex = w.vertex;
				w = w.next;
				var c:Vertex = w.vertex;
				var abx:Number = b.x - a.x;
				var aby:Number = b.y - a.y;
				var abz:Number = b.z - a.z;
				var acx:Number = c.x - a.x;
				var acy:Number = c.y - a.y;
				var acz:Number = c.z - a.z;
				var nx:Number = acz*aby - acy*abz;
				var ny:Number = acx*abz - acz*abx;
				var nz:Number = acy*abx - acx*aby;
				if (normalize) {
					var length:Number = nx*nx + ny*ny + nz*nz;
					if (length > 0.001) {
						length = 1/Math.sqrt(length);
						nx *= length;
						ny *= length;
						nz *= length;
					}
				}
				face.normalX = nx;
				face.normalY = ny;
				face.normalZ = nz;
				face.offset = a.x*nx + a.y*ny + a.z*nz;
			}
		}
	
		public function optimizeForDynamicBSP(iterations:int = 1):void {
			var list:Face = faceList;
			var last:Face;
			for (var i:int = 0; i < iterations; i++) {
				var prev:Face = null;
				for (var face:Face = list; face != null; face = face.next) {
					var normalX:Number = face.normalX;
					var normalY:Number = face.normalY;
					var normalZ:Number = face.normalZ;
					var offset:Number = face.offset;
					var offsetMin:Number = offset - threshold;
					var offsetMax:Number = offset + threshold;
					var splits:int = 0;
					for (var f:Face = list; f != null; f = f.next) {
						if (f != face) {
							var w:Wrapper = f.wrapper;
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
								var v:Vertex = w.vertex;
								var vo:Number = v.x*normalX + v.y*normalY + v.z*normalZ;
								if (vo < offsetMin) {
									behind = true;
									if (infront) break;
								} else if (vo > offsetMax) {
									infront = true;
									if (behind) break;
								}
							}
							if (infront && behind) {
								splits++;
								if (splits > i) break;
							}
						}
					}
					if (f == null) {
						if (prev != null) {
							prev.next = face.next;
						} else {
							list = face.next;
						}
						if (last != null) {
							last.next = face;
						} else {
							faceList = face;
						}
						last = face;
					} else {
						prev = face;
					}
				}
				if (list == null) break;
			}
			if (last != null) {
				last.next = list;
			}
		}
	
		/**
		 * Расчёт локального BSP-дерева
		 * @param splitAnalysis Флаг сплит-анализа.
		 * Если он включен, дерево построится с наименьшим количеством распилов, но построение будет медленнее
		 */
		public function calculateBSP(splitAnalysis:Boolean = false):void {
			var first:Face;
			var last:Face;
			var face:Face;
			var wrapper:Wrapper;
			for (face = faceList; face != null; face = face.next) {
				var newFace:Face = new Face();
				newFace.material = face.material;
				var lastWrapper:Wrapper = null;
				for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var newWrapper:Wrapper = new Wrapper();
					var vertex:Vertex = wrapper.vertex;
					if (vertex.value == null) {
						var newVertex:Vertex = new Vertex();
						newVertex.next = bspVertexList;
						bspVertexList = newVertex;
						newVertex.x = vertex.x;
						newVertex.y = vertex.y;
						newVertex.z = vertex.z;
						newVertex.u = vertex.u;
						newVertex.v = vertex.v;
						vertex.value = newVertex;
					}
					newWrapper.vertex = vertex.value;
					if (lastWrapper != null) {
						lastWrapper.next = newWrapper;
					} else {
						newFace.wrapper = newWrapper;
					}
					lastWrapper = newWrapper;
				}
				newFace.calculateBestSequenceAndNormal();
				if (first != null) {
					last.next = newFace;
				} else {
					first = newFace;
				}
				last = newFace;
			}
			// Зануление мапы
			for (face = faceList; face != null; face = face.next) {
				for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					wrapper.vertex.value = null;
				}
			}
			// Построение дерева
			faceTree = (first != null) ? ((first.next != null) ? createNode(first, splitAnalysis) : first) : null;
		}
	
		private function createNode(list:Face, splitAnalysis:Boolean):Face {
			var w:Wrapper;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var v:Vertex;
			var behind:Boolean;
			var infront:Boolean;
			var ao:Number;
			var bo:Number;
			var co:Number;
			var vo:Number;
			var normalX:Number;
			var normalY:Number;
			var normalZ:Number;
			var offset:Number;
			var offsetMin:Number;
			var offsetMax:Number;
			var splitter:Face = list;
			if (splitAnalysis) {
				var bestSplits:int = int.MAX_VALUE;
				for (var face:Face = list; face != null; face = face.next) {
					normalX = face.normalX;
					normalY = face.normalY;
					normalZ = face.normalZ;
					offset = face.offset;
					offsetMin = offset - threshold;
					offsetMax = offset + threshold;
					var splits:int = 0;
					for (var f:Face = list; f != null; f = f.next) {
						if (f != face) {
							w = f.wrapper;
							a = w.vertex;
							w = w.next;
							b = w.vertex;
							w = w.next;
							c = w.vertex;
							w = w.next;
							ao = a.x*normalX + a.y*normalY + a.z*normalZ;
							bo = b.x*normalX + b.y*normalY + b.z*normalZ;
							co = c.x*normalX + c.y*normalY + c.z*normalZ;
							behind = ao < offsetMin || bo < offsetMin || co < offsetMin;
							infront = ao > offsetMax || bo > offsetMax || co > offsetMax;
							for (; w != null; w = w.next) {
								v = w.vertex;
								vo = v.x*normalX + v.y*normalY + v.z*normalZ;
								if (vo < offsetMin) {
									behind = true;
									if (infront) break;
								} else if (vo > offsetMax) {
									infront = true;
									if (behind) break;
								}
							}
							if (infront && behind) {
								splits++;
								if (splits >= bestSplits) break;
							}
						}
					}
					if (splits < bestSplits) {
						splitter = face;
						bestSplits = splits;
						if (bestSplits == 0) break;
					}
				}
			}
			var negativeFirst:Face;
			var negativeLast:Face;
			var splitterLast:Face = splitter;
			var splitterNext:Face = splitter.next;
			var positiveFirst:Face;
			var positiveLast:Face;
			normalX = splitter.normalX;
			normalY = splitter.normalY;
			normalZ = splitter.normalZ;
			offset = splitter.offset;
			offsetMin = offset - threshold;
			offsetMax = offset + threshold;
			while (list != null) {
				if (list != splitter) {
					var next:Face = list.next;
					w = list.wrapper;
					a = w.vertex;
					w = w.next;
					b = w.vertex;
					w = w.next;
					c = w.vertex;
					w = w.next;
					ao = a.x*normalX + a.y*normalY + a.z*normalZ;
					bo = b.x*normalX + b.y*normalY + b.z*normalZ;
					co = c.x*normalX + c.y*normalY + c.z*normalZ;
					behind = ao < offsetMin || bo < offsetMin || co < offsetMin;
					infront = ao > offsetMax || bo > offsetMax || co > offsetMax;
					for (; w != null; w = w.next) {
						v = w.vertex;
						vo = v.x*normalX + v.y*normalY + v.z*normalZ;
						if (vo < offsetMin) {
							behind = true;
						} else if (vo > offsetMax) {
							infront = true;
						}
						v.offset = vo;
					}
					if (!behind) {
						if (!infront) {
							if (list.normalX*normalX + list.normalY*normalY + list.normalZ*normalZ > 0) {
								splitterLast.next = list;
								splitterLast = list;
							} else {
								if (negativeFirst != null) {
									negativeLast.next = list;
								} else {
									negativeFirst = list;
								}
								negativeLast = list;
							}
						} else {
							if (positiveFirst != null) {
								positiveLast.next = list;
							} else {
								positiveFirst = list;
							}
							positiveLast = list;
						}
					} else if (!infront) {
						if (negativeFirst != null) {
							negativeLast.next = list;
						} else {
							negativeFirst = list;
						}
						negativeLast = list;
					} else {
						a.offset = ao;
						b.offset = bo;
						c.offset = co;
						var negative:Face = new Face();
						var positive:Face = new Face();
						var wNegative:Wrapper = null;
						var wPositive:Wrapper = null;
						var wNew:Wrapper;
						w = list.wrapper.next.next;
						while (w.next != null) {
							w = w.next;
						}
						a = w.vertex;
						ao = a.offset;
						for (w = list.wrapper; w != null; w = w.next) {
							b = w.vertex;
							bo = b.offset;
							if (ao < offsetMin && bo > offsetMax || ao > offsetMax && bo < offsetMin) {
								var t:Number = (offset - ao)/(bo - ao);
								v = new Vertex();
								v.next = bspVertexList;
								bspVertexList = v;
								v.x = a.x + (b.x - a.x)*t;
								v.y = a.y + (b.y - a.y)*t;
								v.z = a.z + (b.z - a.z)*t;
								v.u = a.u + (b.u - a.u)*t;
								v.v = a.v + (b.v - a.v)*t;
								wNew = new Wrapper();
								wNew.vertex = v;
								if (wNegative != null) {
									wNegative.next = wNew;
								} else {
									negative.wrapper = wNew;
								}
								wNegative = wNew;
								wNew = new Wrapper();
								wNew.vertex = v;
								if (wPositive != null) {
									wPositive.next = wNew;
								} else {
									positive.wrapper = wNew;
								}
								wPositive = wNew;
							}
							if (bo <= offsetMax) {
								wNew = new Wrapper();
								wNew.vertex = b;
								if (wNegative != null) {
									wNegative.next = wNew;
								} else {
									negative.wrapper = wNew;
								}
								wNegative = wNew;
							}
							if (bo >= offsetMin) {
								wNew = new Wrapper();
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
						negative.material = list.material;
						negative.calculateBestSequenceAndNormal();
						if (negativeFirst != null) {
							negativeLast.next = negative;
						} else {
							negativeFirst = negative;
						}
						negativeLast = negative;
						positive.material = list.material;
						positive.calculateBestSequenceAndNormal();
						if (positiveFirst != null) {
							positiveLast.next = positive;
						} else {
							positiveFirst = positive;
						}
						positiveLast = positive;
					}
					list = next;
				} else {
					list = splitterNext;
				}
			}
			if (negativeFirst != null) {
				negativeLast.next = null;
				splitter.negative = (negativeFirst.next != null) ? createNode(negativeFirst, splitAnalysis) : negativeFirst;
			} else {
				splitter.negative = null;
			}
			if (positiveFirst != null) {
				positiveLast.next = null;
				splitter.positive = (positiveFirst.next != null) ? createNode(positiveFirst, splitAnalysis) : positiveFirst;
			} else {
				splitter.positive = null;
			}
			splitterLast.next = null;
			return splitter;
		}
	
		override alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) {
				if (transformation != null) {
					vertex.cameraX = transformation.ma*vertex.x + transformation.mb*vertex.y + transformation.mc*vertex.z + transformation.md;
					vertex.cameraY = transformation.me*vertex.x + transformation.mf*vertex.y + transformation.mg*vertex.z + transformation.mh;
					vertex.cameraZ = transformation.mi*vertex.x + transformation.mj*vertex.y + transformation.mk*vertex.z + transformation.ml;
				} else {
					vertex.cameraX = vertex.x;
					vertex.cameraY = vertex.y;
					vertex.cameraZ = vertex.z;
				}
				if (vertex.cameraX < bounds.boundMinX) bounds.boundMinX = vertex.cameraX;
				if (vertex.cameraX > bounds.boundMaxX) bounds.boundMaxX = vertex.cameraX;
				if (vertex.cameraY < bounds.boundMinY) bounds.boundMinY = vertex.cameraY;
				if (vertex.cameraY > bounds.boundMaxY) bounds.boundMaxY = vertex.cameraY;
				if (vertex.cameraZ < bounds.boundMinZ) bounds.boundMinZ = vertex.cameraZ;
				if (vertex.cameraZ > bounds.boundMaxZ) bounds.boundMaxZ = vertex.cameraZ;
			}
		}
	
		/**
		 * Копирование свойств другого меша. Осторожно, свойства будут иметь прямые ссылки на свойства копируемого меша.
		 * @param source Объект копирования
		 */
		public function copyFrom(source:Mesh):void {
			name = source.name;
			visible = source.visible;
			alpha = source.alpha;
			blendMode = source.blendMode;
			colorTransform = source.colorTransform;
			filters = source.filters;
			x = source.x;
			y = source.y;
			z = source.z;
			rotationX = source.rotationX;
			rotationY = source.rotationY;
			rotationZ = source.rotationZ;
			scaleX = source.scaleX;
			scaleY = source.scaleY;
			scaleZ = source.scaleZ;
			boundMinX = source.boundMinX;
			boundMinY = source.boundMinY;
			boundMinZ = source.boundMinZ;
			boundMaxX = source.boundMaxX;
			boundMaxY = source.boundMaxY;
			boundMaxZ = source.boundMaxZ;
	
			clipping = source.clipping;
			sorting = source.sorting;
	
			faceList = source.faceList;
			vertexList = source.vertexList;
			faceTree = source.faceTree;
			bspVertexList = source.bspVertexList;
		}
	
		override public function clone():Object3D {
			var mesh:Mesh = new Mesh();
			mesh.cloneBaseProperties(this);
			mesh.clipping = clipping;
			mesh.sorting = sorting;
			var vertex:Vertex;
			// Клонирование вершин
			var lastVertex:Vertex;
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				var newVertex:Vertex = new Vertex();
				newVertex.x = vertex.x;
				newVertex.y = vertex.y;
				newVertex.z = vertex.z;
				newVertex.u = vertex.u;
				newVertex.v = vertex.v;
				vertex.value = newVertex;
				if (lastVertex != null) {
					lastVertex.next = newVertex;
				} else {
					mesh.vertexList = newVertex;
				}
				lastVertex = newVertex;
			}
			// Клонирование граней
			var lastFace:Face;
			for (var face:Face = faceList; face != null; face = face.next) {
				var newFace:Face = new Face();
				newFace.material = face.material;
				newFace.normalX = face.normalX;
				newFace.normalY = face.normalY;
				newFace.normalZ = face.normalZ;
				newFace.offset = face.offset;
				// Клонирование обёрток
				var lastWrapper:Wrapper = null;
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var newWrapper:Wrapper = new Wrapper();
					newWrapper.vertex = wrapper.vertex.value;
					if (lastWrapper != null) {
						lastWrapper.next = newWrapper;
					} else {
						newFace.wrapper = newWrapper;
					}
					lastWrapper = newWrapper;
				}
				if (lastFace != null) {
					lastFace.next = newFace;
				} else {
					mesh.faceList = newFace;
				}
				lastFace = newFace;
			}
			// Сброс после ремапа
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
			return mesh;
		}
	
		public function generateClass(className:String = "GeneratedMesh", packageName:String = "", textureName:String = null):String {
	
			/*var header:String = "package" + ((packageName != "") ? (" " + packageName + " ") : " ") + "{\r\r";
	
			 var importSet:Object = new Object();
			 importSet["__AS3__.vec.Vector"] = true;
			 importSet["alternativa.engine3d.core.Mesh"] = true;
	
			 var footer:String = "\t\t}\r\t}\r}";
	
			 var classHeader:String = "\tpublic class "+ className + " extends Mesh {\r\r";
	
			 var constructor:String = "\t\tpublic function " + className + "() {\r";
	
			 constructor += "\t\t\tnumVertices = " + numVertices +";\r";
			 constructor += "\t\t\tnumFaces = " + numFaces +";\r";
			 constructor += "\t\t\tvertices = Vector.<Number>([";
			 var length:uint = numVertices*3;
			 var n:int = 0;
	
			 var i:int;
	
			 for (i = 0; i < length; i++) {
			 constructor += vertices[i];
			 if (i != length - 1) {
			 constructor += ", ";
			 if (n++ > 48) {
			 constructor += "\r\t\t\t\t";
			 n = 0;
			 }
			 }
			 }
			 constructor += "]);\r";
	
			 constructor += "\t\t\tindices = Vector.<int>([";
			 length = numFaces*3;
			 n = 0;
			 for (i = 0; i < length; i++) {
			 constructor += indices[i];
			 if (i != length - 1) {
			 constructor += ", ";
			 if (n++ > 48) {
			 constructor += "\r\t\t\t\t";
			 n = 0;
			 }
			 }
			 }
			 constructor += "]);\r";
	
	
			 constructor += "\t\t\tuvts = Vector.<Number>([";
			 length = numVertices*3;
			 n = 0;
			 for (i = 0; i < length; i++) {
			 constructor += uvts[i];
			 if (i != length - 1) {
			 constructor += ", ";
			 if (n++ > 48) {
			 constructor += "\r\t\t\t\t";
			 n = 0;
			 }
			 }
			 }
			 constructor += "]);\r";
	
			 var embeds:String = "";
			 if (textureName != null) {
			 importSet["flash.display.BitmapData"] = true;
			 var bmpName:String = textureName.charAt(0).toUpperCase() + textureName.substr(1);
			 embeds += "\t\t[Embed(source=\"" + textureName + "\")] private static const bmp" + bmpName + ":Class;\r";
			 embeds += "\t\tprivate static const " + textureName + ":BitmapData = new bmp" + bmpName + "().bitmapData;\r\r";
			 constructor += "\t\t\ttexture = " + textureName + ";\r\r";
			 }
	
			 constructor += "\t\t\tclipping = " + clipping +";\r";
			 constructor += "\t\t\trepeatTexture = " + (repeatTexture ? "true" : "false") +";\r\r";
	
			 constructor += "\t\t\tmatrix.rawData = Vector.<Number>([" + matrix.rawData + "]);\r";
			 if (_boundBox != null) {
			 importSet["alternativa.engine3d.bounds.BoundBox"] = true;
			 constructor += "\t\t\t_boundBox = new BoundBox(" + _boundBox.minX + ", " + _boundBox.minY + ", " + _boundBox.minZ + ", " + _boundBox.maxX + ", " + _boundBox.maxY + ", " + _boundBox.maxZ + ");\r";
			 }
	
			 var imports:String = "";
	
			 var importArray:Array = new Array();
			 for (var key:* in importSet) {
			 importArray.push(key);
			 }
			 importArray.sort();
	
			 var newLine:Boolean = false;
			 length = importArray.length;
			 for (i = 0; i < length; i++) {
			 var pack:String = importArray[i];
			 var current:String = pack.substr(0, pack.indexOf("."));
			 imports += (current != prev && prev != null) ? "\r" : "";
			 imports += "\timport " + pack + ";\r";
			 var prev:String = current;
			 newLine = true;
			 }
			 imports += newLine ? "\r" : "";
	
			 return header + imports + classHeader + embeds + constructor + footer;*/
			return "Method is not realized";
		}
	
		/**
		 * Объединение вершин с одинаковыми координатами и uv
		 * @param distanceThreshold Погрешность, в пределах которой координаты считаются одинаковыми
		 * @param uvThreshold Погрешность, в пределах которой UV-координаты считаются одинаковыми
		 */
		public function weldVertices(distanceThreshold:Number = 0, uvThreshold:Number = 0):void {
			// Заполнение массива вершин
			transformID++;
			var face:Face;
			var wrapper:Wrapper;
			var vertex:Vertex;
			var vertices:Vector.<Vertex> = new Vector.<Vertex>();
			var verticesLength:int = 0;
			for (face = faceList; face != null; face = face.next) {
				for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					vertex = wrapper.vertex;
					if (vertex.transformID != transformID) {
						vertices[verticesLength] = vertex;
						verticesLength++;
						vertex.transformID = transformID;
					}
				}
			}
			// Группировка
			var stack:Vector.<int> = new Vector.<int>();
	
			function group(begin:int, end:int, depth:int):void {
				var i:int;
				var j:int;
				var threshold:Number;
				switch (depth) {
					case 0: // x
						for (i = begin; i < end; i++) {
							vertex = vertices[i];
							vertex.offset = vertex.x;
						}
						threshold = distanceThreshold;
						break;
					case 1: // y
						for (i = begin; i < end; i++) {
							vertex = vertices[i];
							vertex.offset = vertex.y;
						}
						threshold = distanceThreshold;
						break;
					case 2: // z
						for (i = begin; i < end; i++) {
							vertex = vertices[i];
							vertex.offset = vertex.z;
						}
						threshold = distanceThreshold;
						break;
					case 3: // u
						for (i = begin; i < end; i++) {
							vertex = vertices[i];
							vertex.offset = vertex.u;
						}
						threshold = uvThreshold;
						break;
					case 4: // v
						for (i = begin; i < end; i++) {
							vertex = vertices[i];
							vertex.offset = vertex.v;
						}
						threshold = uvThreshold;
						break;
				}
				// Сортировка
				stack[0] = begin;
				stack[1] = end - 1;
				var index:int = 2;
				while (index > 0) {
					index--;
					var r:int = stack[index];
					j = r;
					index--;
					var l:int = stack[index];
					i = l;
					vertex = vertices[(r + l) >> 1];
					var median:Number = vertex.offset;
					while (i <= j) {
						var left:Vertex = vertices[i];
						while (left.offset > median) {
							i++;
							left = vertices[i];
						}
						var right:Vertex = vertices[j];
						while (right.offset < median) {
							j--;
							right = vertices[j];
						}
						if (i <= j) {
							vertices[i] = right;
							vertices[j] = left;
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
				// Разбиение на группы дальше
				i = begin;
				vertex = vertices[i];
				for (j = i + 1; j < end; j++) {
					var compared:Vertex = vertices[j];
					if (vertex.offset - compared.offset > threshold) {
						if (depth < 4 && j - i > 1) {
							group(i, j, depth + 1);
						}
						i = j;
						vertex = vertices[i];
					} else if (depth == 4) {
						compared.value = vertex;
					}
				}
				if (depth < 4 && j - i > 1) {
					group(i, j, depth + 1);
				}
			}
	
			group(0, verticesLength, 0);
			// Замена вершин
			for (face = faceList; face != null; face = face.next) {
				for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					vertex = wrapper.vertex;
					if (vertex.value != null) {
						wrapper.vertex = vertex.value;
					}
				}
			}
			// Создание нового списка вершин
			vertexList = null;
			transformID++;
			for (face = faceList; face != null; face = face.next) {
				for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					vertex = wrapper.vertex;
					if (vertex.transformID != transformID) {
						vertex.next = vertexList;
						vertexList = vertex;
						vertex.transformID = transformID;
					}
				}
			}
			// Здесь может быть удаление дубликатов из меша
		}
	
		/**
		 * Объединение соседних граней, находящихся в одной плоскости
		 * @param angleThreshold Допустимый угол в радианах между нормалями, чтобы считать, что объединяемые грани в одной плоскости
		 * @param uvThreshold Допустимая разница uv-координат, чтобы считать, что объединяемые грани состыковываются по UV
		 * @param convexThreshold Величина, уменьшающая допустимый угол между смежными рёбрами объединяемых граней
		 */
		public function weldFaces(angleThreshold:Number = 0, uvThreshold:Number = 0, convexThreshold:Number = 0, pairWeld:Boolean = false):void {
			var i:int;
			var j:int;
			var key:*;
			var sibling:Face;
			var face:Face;
			var next:Face;
			var wp:Wrapper;
			var sp:Wrapper;
			var w:Wrapper;
			var s:Wrapper;
			var wn:Wrapper;
			var sn:Wrapper;
			var wm:Wrapper;
			var sm:Wrapper;
			var vertex:Vertex;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var abx:Number;
			var aby:Number;
			var abz:Number;
			var abu:Number;
			var abv:Number;
			var acx:Number;
			var acy:Number;
			var acz:Number;
			var acu:Number;
			var acv:Number;
			var nx:Number;
			var ny:Number;
			var nz:Number;
			var nl:Number;
			var dictionary:Dictionary;
			// Последняя грань в результирующем списке
			var last:Face;
			// Погрешность
			var digitThreshold:Number = 0.001;
			angleThreshold = Math.cos(angleThreshold) - digitThreshold;
			uvThreshold += digitThreshold;
			convexThreshold = Math.cos(Math.PI - convexThreshold) - digitThreshold;
			// Грани
			var faces:Dictionary = new Dictionary();
			// Карта соответствий vertex:faces(dictionary)
			var map:Dictionary = new Dictionary();
			for (face = faceList,faceList = null; face != null; face = next) {
				next = face.next;
				face.next = null;
				// Расчёт нормали
				a = face.wrapper.vertex;
				b = face.wrapper.next.vertex;
				c = face.wrapper.next.next.vertex;
				abx = b.x - a.x;
				aby = b.y - a.y;
				abz = b.z - a.z;
				acx = c.x - a.x;
				acy = c.y - a.y;
				acz = c.z - a.z;
				nx = acz*aby - acy*abz;
				ny = acx*abz - acz*abx;
				nz = acy*abx - acx*aby;
				nl = nx*nx + ny*ny + nz*nz;
				if (nl > digitThreshold) {
					nl = 1/Math.sqrt(nl);
					nx *= nl;
					ny *= nl;
					nz *= nl;
					face.normalX = nx;
					face.normalY = ny;
					face.normalZ = nz;
					face.offset = a.x*nx + a.y*ny + a.z*nz;
					faces[face] = true;
					for (wn = face.wrapper; wn != null; wn = wn.next) {
						vertex = wn.vertex;
						dictionary = map[vertex];
						if (dictionary == null) {
							dictionary = new Dictionary();
							map[vertex] = dictionary;
						}
						dictionary[face] = true;
					}
				}
			}
			// Остров
			var island:Vector.<Face> = new Vector.<Face>();
			// Соседи текущей грани
			var siblings:Dictionary = new Dictionary();
			// Грани, которые точно не входят в текущий остров
			var unfit:Dictionary = new Dictionary();
			while (true) {
				// Получение первой попавшейся грани
				face = null;
				for (key in faces) {
					face = key;
					delete faces[key];
					break;
				}
				if (face == null) break;
				// Создани острова
				var num:int = 0;
				island[num] = face;
				num++;
				a = face.wrapper.vertex;
				b = face.wrapper.next.vertex;
				c = face.wrapper.next.next.vertex;
				abx = b.x - a.x;
				aby = b.y - a.y;
				abz = b.z - a.z;
				abu = b.u - a.u;
				abv = b.v - a.v;
				acx = c.x - a.x;
				acy = c.y - a.y;
				acz = c.z - a.z;
				acu = c.u - a.u;
				acv = c.v - a.v;
				nx = face.normalX;
				ny = face.normalY;
				nz = face.normalZ;
				// Нахождение матрицы uv-трансформации
				var det:Number = -nx*acy*abz + acx*ny*abz + nx*aby*acz - abx*ny*acz - acx*aby*nz + abx*acy*nz;
				var ima:Number = (-ny*acz + acy*nz)/det;
				var imb:Number = (nx*acz - acx*nz)/det;
				var imc:Number = (-nx*acy + acx*ny)/det;
				var imd:Number = (a.x*ny*acz - nx*a.y*acz - a.x*acy*nz + acx*a.y*nz + nx*acy*a.z - acx*ny*a.z)/det;
				var ime:Number = (ny*abz - aby*nz)/det;
				var imf:Number = (-nx*abz + abx*nz)/det;
				var img:Number = (nx*aby - abx*ny)/det;
				var imh:Number = (nx*a.y*abz - a.x*ny*abz + a.x*aby*nz - abx*a.y*nz - nx*aby*a.z + abx*ny*a.z)/det;
				var ma:Number = abu*ima + acu*ime;
				var mb:Number = abu*imb + acu*imf;
				var mc:Number = abu*imc + acu*img;
				var md:Number = abu*imd + acu*imh + a.u;
				var me:Number = abv*ima + acv*ime;
				var mf:Number = abv*imb + acv*imf;
				var mg:Number = abv*imc + acv*img;
				var mh:Number = abv*imd + acv*imh + a.v;
				for (key in unfit) {
					delete unfit[key];
				}
				for (i = 0; i < num; i++) {
					face = island[i];
					for (key in siblings) {
						delete siblings[key];
					}
					// Сбор потенциальных соседей грани
					for (w = face.wrapper; w != null; w = w.next) {
						for (key in map[w.vertex]) {
							if (faces[key] && !unfit[key]) {
								siblings[key] = true;
							}
						}
					}
					for (key in siblings) {
						sibling = key;
						// Если совпадают по нормалям
						if (nx*sibling.normalX + ny*sibling.normalY + nz*sibling.normalZ >= angleThreshold) {
							for (s = sibling.wrapper; s != null; s = s.next) {
								vertex = s.vertex;
								var du:Number = ma*vertex.x + mb*vertex.y + mc*vertex.z + md - vertex.u;
								var dv:Number = me*vertex.x + mf*vertex.y + mg*vertex.z + mh - vertex.v;
								if (du > uvThreshold || du < -uvThreshold || dv > uvThreshold || dv < -uvThreshold) break;
							}
							// Если совпадают по UV
							if (s == null) {
								// Проверка на соседство
								for (w = face.wrapper; w != null; w = w.next) {
									wn = (w.next != null) ? w.next : face.wrapper;
									for (s = sibling.wrapper; s != null; s = s.next) {
										sn = (s.next != null) ? s.next : sibling.wrapper;
										if (w.vertex == sn.vertex && wn.vertex == s.vertex) break;
									}
									if (s != null) break;
								}
								// Добавление в остров
								if (w != null) {
									island[num] = sibling;
									num++;
									delete faces[sibling];
								}
							} else {
								unfit[sibling] = true;
							}
						} else {
							unfit[sibling] = true;
						}
					}
				}
				// Если в острове только одна грань
				if (num == 1) {
					face = island[0];
					if (last != null) {
						last.next = face;
					} else {
						faceList = face;
					}
					last = face;
					// Объединение острова
				} else {
					while (true) {
						var weld:Boolean = false;
						// Перебор граней острова
						for (i = 0; i < num - 1; i++) {
							face = island[i];
							if (face != null) {
								// Попытки объединить текущую грань с остальными
								for (j = 1; j < num; j++) {
									sibling = island[j];
									if (sibling != null) {
										// Поиск общего ребра
										for (w = face.wrapper; w != null; w = w.next) {
											wn = (w.next != null) ? w.next : face.wrapper;
											for (s = sibling.wrapper; s != null; s = s.next) {
												sn = (s.next != null) ? s.next : sibling.wrapper;
												if (w.vertex == sn.vertex && wn.vertex == s.vertex) break;
											}
											if (s != null) break;
										}
										// Если ребро найдено
										if (w != null) {
											// Расширение граней объединеия
											while (true) {
												wm = (wn.next != null) ? wn.next : face.wrapper;
												//for (sp = sibling.wrapper; sp.next != s && sp.next != null; sp = sp.next);
												sp = sibling.wrapper;
												while (sp.next != s && sp.next != null) sp = sp.next;
												if (wm.vertex == sp.vertex) {
													wn = wm;
													s = sp;
												} else break;
											}
											while (true) {
												//for (wp = face.wrapper; wp.next != w && wp.next != null; wp = wp.next);
												wp = face.wrapper;
												while (wp.next != w && wp.next != null) wp = wp.next;
												sm = (sn.next != null) ? sn.next : sibling.wrapper;
												if (wp.vertex == sm.vertex) {
													w = wp;
													sn = sm;
												} else break;
											}
											// Первый перегиб
											a = w.vertex;
											b = sm.vertex;
											c = wp.vertex;
											abx = b.x - a.x;
											aby = b.y - a.y;
											abz = b.z - a.z;
											acx = c.x - a.x;
											acy = c.y - a.y;
											acz = c.z - a.z;
											nx = acz*aby - acy*abz;
											ny = acx*abz - acz*abx;
											nz = acy*abx - acx*aby;
											if (nx < digitThreshold && nx > -digitThreshold && ny < digitThreshold && ny > -digitThreshold && nz < digitThreshold && nz > -digitThreshold) {
												if (abx*acx + aby*acy + abz*acz > 0) continue;
											} else {
												if (face.normalX*nx + face.normalY*ny + face.normalZ*nz < 0) continue;
											}
											nl = 1/Math.sqrt(abx*abx + aby*aby + abz*abz);
											abx *= nl;
											aby *= nl;
											abz *= nl;
											nl = 1/Math.sqrt(acx*acx + acy*acy + acz*acz);
											acx *= nl;
											acy *= nl;
											acz *= nl;
											if (abx*acx + aby*acy + abz*acz < convexThreshold) continue;
											// Второй перегиб
											a = s.vertex;
											b = wm.vertex;
											c = sp.vertex;
											abx = b.x - a.x;
											aby = b.y - a.y;
											abz = b.z - a.z;
											acx = c.x - a.x;
											acy = c.y - a.y;
											acz = c.z - a.z;
											nx = acz*aby - acy*abz;
											ny = acx*abz - acz*abx;
											nz = acy*abx - acx*aby;
											if (nx < digitThreshold && nx > -digitThreshold && ny < digitThreshold && ny > -digitThreshold && nz < digitThreshold && nz > -digitThreshold) {
												if (abx*acx + aby*acy + abz*acz > 0) continue;
											} else {
												if (face.normalX*nx + face.normalY*ny + face.normalZ*nz < 0) continue;
											}
											nl = 1/Math.sqrt(abx*abx + aby*aby + abz*abz);
											abx *= nl;
											aby *= nl;
											abz *= nl;
											nl = 1/Math.sqrt(acx*acx + acy*acy + acz*acz);
											acx *= nl;
											acy *= nl;
											acz *= nl;
											if (abx*acx + aby*acy + abz*acz < convexThreshold) continue;
											// Объединение
											weld = true;
											var newFace:Face = new Face();
											newFace.material = face.material;
											newFace.normalX = face.normalX;
											newFace.normalY = face.normalY;
											newFace.normalZ = face.normalZ;
											newFace.offset = face.offset;
											// Здесь может быть удаление промежуточных вершин из меша
											wm = null;
											for (; wn != w; wn = (wn.next != null) ? wn.next : face.wrapper) {
												sm = new Wrapper();
												sm.vertex = wn.vertex;
												if (wm != null) {
													wm.next = sm;
												} else {
													newFace.wrapper = sm;
												}
												wm = sm;
											}
											for (; sn != s; sn = (sn.next != null) ? sn.next : sibling.wrapper) {
												sm = new Wrapper();
												sm.vertex = sn.vertex;
												if (wm != null) {
													wm.next = sm;
												} else {
													newFace.wrapper = sm;
												}
												wm = sm;
											}
											island[i] = newFace;
											island[j] = null;
											face = newFace;
											// Если, то собираться будет парами, иначе к одной прицепляется максимально (это чуть бустрее)
											if (pairWeld) break;
										}
									}
								}
							}
						}
						if (!weld) break;
					}
					// Сбор объединённых граней
					for (i = 0; i < num; i++) {
						face = island[i];
						if (face != null) {
							// Определение лучшей последовательности вершин
							face.calculateBestSequenceAndNormal();
							// Добавление
							if (last != null) {
								last.next = face;
							} else {
								faceList = face;
							}
							last = face;
						}
					}
				}
			}
		}
	
	}
}
