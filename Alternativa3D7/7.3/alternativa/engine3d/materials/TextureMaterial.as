package alternativa.engine3d.materials {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	
	import flash.display.BitmapData;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	use namespace alternativa3d;
	
	public class TextureMaterial extends Material {
	
		static private const filter:ConvolutionFilter = new ConvolutionFilter(2, 2, [1, 1, 1, 1], 4, 0, false, true);
		static private const matrix:Matrix = new Matrix();
		static private const rect:Rectangle = new Rectangle();
		static private const point:Point = new Point();
	
		static protected var drawVertices:Vector.<Number> = new Vector.<Number>();
		static protected var drawUVTs:Vector.<Number> = new Vector.<Number>();
		static protected var drawIndices:Vector.<int> = new Vector.<int>();
	
		public var diffuseMapURL:String;
		public var opacityMapURL:String;
	
		public var texture:BitmapData;
	
		public var repeat:Boolean = false;
		public var smooth:Boolean = true;
	
		public var mipMapping:int = 0;
	
		public var resolution:Number = 1;
	
		public var threshold:Number = 0.01;
		
		public var correctUV:Boolean = false;
		
		alternativa3d var mipMap:Vector.<BitmapData>;
		alternativa3d var numMaps:int = 0;
	
		public function TextureMaterial(texture:BitmapData = null, repeat:Boolean = false, smooth:Boolean = true) {
			this.texture = texture;
			this.repeat = repeat;
			this.smooth = smooth;
		}
	
		override alternativa3d function draw(camera:Camera3D, canvas:Canvas, list:Face, distance:Number):void {
			var face:Face;
			var next:Face;
			var last:Face;
			var wrapper:Wrapper;
			var vertex:Vertex;
			var a:int;
			var b:int;
			var c:int;
			var t:Number;
			var f:Number;
			var j:int;
			var mu:Number;
			var mv:Number;
			var du:Number;
			var dv:Number;
			var drawTexture:BitmapData;
			var viewSizeX:Number = camera.viewSizeX;
			var viewSizeY:Number = camera.viewSizeY;
			var vertices:Vector.<Number> = drawVertices;
			var uvts:Vector.<Number> = drawUVTs;
			var indices:Vector.<int> = drawIndices;
			var numVertices:int;
			var verticesLength:int;
			var uvtsLength:int;
			var indicesLength:int;
			var numDraws:int = camera.numDraws;
			var numPolygons:int = camera.numPolygons;
			var numTriangles:int = camera.numTriangles;
			// Если нет текстуры, нужно просто расцепить список
			if (texture == null) {
				clearLinks(list);
				return;
			}
			// Мипмаппинг
			if (mipMapping < 2) {
				numDraws++;
				numVertices = 0;
				verticesLength = 0;
				uvtsLength = 0;
				indicesLength = 0;
				for (face = list; face != null; face = next) {
					next = face.processNext;
					face.processNext = null;
					wrapper = face.wrapper;
					vertex = wrapper.vertex;
					if (vertex.drawID != numDraws) {
						t = 1/vertex.cameraZ;
						vertices[verticesLength] = vertex.cameraX*viewSizeX*t;
						verticesLength++;
						vertices[verticesLength] = vertex.cameraY*viewSizeY*t;
						verticesLength++;
						uvts[uvtsLength] = vertex.u;
						uvtsLength++;
						uvts[uvtsLength] = vertex.v;
						uvtsLength++;
						uvts[uvtsLength] = t;
						uvtsLength++;
						a = numVertices;
						vertex.index = numVertices++;
						vertex.drawID = numDraws;
					} else {
						a = vertex.index;
					}
					wrapper = wrapper.next;
					vertex = wrapper.vertex;
					if (vertex.drawID != numDraws) {
						t = 1/vertex.cameraZ;
						vertices[verticesLength] = vertex.cameraX*viewSizeX*t;
						verticesLength++;
						vertices[verticesLength] = vertex.cameraY*viewSizeY*t;
						verticesLength++;
						uvts[uvtsLength] = vertex.u;
						uvtsLength++;
						uvts[uvtsLength] = vertex.v;
						uvtsLength++;
						uvts[uvtsLength] = t;
						uvtsLength++;
						b = numVertices;
						vertex.index = numVertices++;
						vertex.drawID = numDraws;
					} else {
						b = vertex.index;
					}
					for (wrapper = wrapper.next; wrapper != null; wrapper = wrapper.next) {
						vertex = wrapper.vertex;
						if (vertex.drawID != numDraws) {
							t = 1/vertex.cameraZ;
							vertices[verticesLength] = vertex.cameraX*viewSizeX*t;
							verticesLength++;
							vertices[verticesLength] = vertex.cameraY*viewSizeY*t;
							verticesLength++;
							uvts[uvtsLength] = vertex.u;
							uvtsLength++;
							uvts[uvtsLength] = vertex.v;
							uvtsLength++;
							uvts[uvtsLength] = t;
							uvtsLength++;
							c = numVertices;
							vertex.index = numVertices++;
							vertex.drawID = numDraws;
						} else {
							c = vertex.index;
						}
						drawIndices[indicesLength] = a;
						indicesLength++;
						drawIndices[indicesLength] = b;
						indicesLength++;
						drawIndices[indicesLength] = c;
						indicesLength++;
						b = c;
						numTriangles++;
					}
					numPolygons++;
				}
				// Подрезка
				vertices.length = verticesLength;
				uvts.length = uvtsLength;
				indices.length = indicesLength;
				// Отрисовка
				if (mipMapping == 0) {
					// Без мипмаппинга
					drawTexture = texture;
				} else {
					// Мипмаппинг по удалённости объекта от камеры
					f = camera.focalLength*resolution;
					var level:int = (distance >= f) ? (1 + Math.log(distance/f)*1.442695040888963387) : 0;
					if (level >= numMaps) level = numMaps - 1;
					drawTexture = mipMap[level];
				}
				if (correctUV) {
					du = -0.5/(drawTexture.width - 1);
					dv = -0.5/(drawTexture.height - 1);
					mu = 1 - du - du;
					mv = 1 - dv - dv;
					for (j = 0; j < uvtsLength; j++) {
						uvts[j] = uvts[j]*mu + du; j++;
						uvts[j] = uvts[j]*mv + dv; j++;
					}
				}
				canvas.gfx.beginBitmapFill(drawTexture, null, repeat, smooth);
				canvas.gfx.drawTriangles(vertices, indices, uvts, "none");
			} else {
				// Расчёт Z-баунда
				var z:Number;
				var min:Number = 1e+22;
				var max:Number = -1;
				for (face = list; face != null; face = face.processNext) {
					for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
						z = wrapper.vertex.cameraZ;
						if (z < min) min = z;
						if (z > max) max = z;
					}
				}
				// Расстояние нулевого мипа
				f = camera.focalLength*resolution;
				// Минимальный и максимальный уровень
				var minLevel:int = (min >= f) ? (1 + Math.log(min/f)*1.442695040888963387) : 0;
				if (minLevel >= numMaps) minLevel = numMaps - 1;
				var maxLevel:int = (max >= f) ? (1 + Math.log(max/f)*1.442695040888963387) : 0;
				if (maxLevel >= numMaps) maxLevel = numMaps - 1;
				// Рассечение Z-плоскостями начиная с дальних и отрисовка
				z = f*Math.pow(2, maxLevel - 1);
				var temporaryWrapper:Wrapper;
				for (var i:int = maxLevel; i >= minLevel; i--) {
					numDraws++;
					numVertices = 0;
					verticesLength = 0;
					uvtsLength = 0;
					indicesLength = 0;
					var zMin:Number = z - threshold;
					var zMax:Number = z + threshold;
					for (face = list,list = null,last = null; face != null; face = next) {
						next = face.processNext;
						face.processNext = null;
						wrapper = null;
						if (i == minLevel) {
							wrapper = face.wrapper;
						} else {
							var w:Wrapper = face.wrapper;
							var az:Number = w.vertex.cameraZ;
							w = w.next;
							var bz:Number = w.vertex.cameraZ;
							w = w.next;
							var cz:Number = w.vertex.cameraZ;
							w = w.next;
							var behind:Boolean = az < zMin || bz < zMin || cz < zMin;
							var infront:Boolean = az > zMax || bz > zMax || cz > zMax;
							for (; w != null; w = w.next) {
								var vz:Number = w.vertex.cameraZ;
								if (vz < zMin) {
									behind = true;
								} else if (vz > zMax) {
									infront = true;
								}
							}
							if (!behind) {
								wrapper = face.wrapper;
							} else if (!infront) {
								if (list != null) {
									last.processNext = face;
								} else {
									list = face;
								}
								last = face;
							} else {
								var negative:Face = face.create();
								camera.lastFace.next = negative;
								camera.lastFace = negative;
								var wNegative:Wrapper = null;
								var wPositive:Wrapper = null;
								var wNew:Wrapper;
								//for (w = face.wrapper.next.next; w.next != null; w = w.next);
								w = face.wrapper.next.next;
								while (w.next != null) w = w.next;
								var va:Vertex = w.vertex;
								az = va.cameraZ;
								for (w = face.wrapper; w != null; w = w.next) {
									var vb:Vertex = w.vertex;
									bz = vb.cameraZ;
									if (az < zMin && bz > zMax || az > zMax && bz < zMin) {
										t = (z - az)/(bz - az);
										var v:Vertex = vb.create();
										camera.lastVertex.next = v;
										camera.lastVertex = v;
										v.cameraX = va.cameraX + (vb.cameraX - va.cameraX)*t;
										v.cameraY = va.cameraY + (vb.cameraY - va.cameraY)*t;
										v.cameraZ = z;
										v.u = va.u + (vb.u - va.u)*t;
										v.v = va.v + (vb.v - va.v)*t;
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
											wrapper = wNew;
										}
										wPositive = wNew;
									}
									if (bz <= zMax) {
										wNew = w.create();
										wNew.vertex = vb;
										if (wNegative != null) {
											wNegative.next = wNew;
										} else {
											negative.wrapper = wNew;
										}
										wNegative = wNew;
									}
									if (bz >= zMin) {
										wNew = w.create();
										wNew.vertex = vb;
										if (wPositive != null) {
											wPositive.next = wNew;
										} else {
											wrapper = wNew;
										}
										wPositive = wNew;
									}
									va = vb;
									az = bz;
								}
								if (list != null) {
									last.processNext = negative;
								} else {
									list = negative;
								}
								last = negative;
								temporaryWrapper = wrapper;
							}
						}
						if (wrapper != null) {
							vertex = wrapper.vertex;
							if (vertex.drawID != numDraws) {
								t = 1/vertex.cameraZ;
								vertices[verticesLength] = vertex.cameraX*viewSizeX*t;
								verticesLength++;
								vertices[verticesLength] = vertex.cameraY*viewSizeY*t;
								verticesLength++;
								uvts[uvtsLength] = vertex.u;
								uvtsLength++;
								uvts[uvtsLength] = vertex.v;
								uvtsLength++;
								uvts[uvtsLength] = t;
								uvtsLength++;
								a = numVertices;
								vertex.index = numVertices++;
								vertex.drawID = numDraws;
							} else {
								a = vertex.index;
							}
							wrapper = wrapper.next;
							vertex = wrapper.vertex;
							if (vertex.drawID != numDraws) {
								t = 1/vertex.cameraZ;
								vertices[verticesLength] = vertex.cameraX*viewSizeX*t;
								verticesLength++;
								vertices[verticesLength] = vertex.cameraY*viewSizeY*t;
								verticesLength++;
								uvts[uvtsLength] = vertex.u;
								uvtsLength++;
								uvts[uvtsLength] = vertex.v;
								uvtsLength++;
								uvts[uvtsLength] = t;
								uvtsLength++;
								b = numVertices;
								vertex.index = numVertices++;
								vertex.drawID = numDraws;
							} else {
								b = vertex.index;
							}
							for (wrapper = wrapper.next; wrapper != null; wrapper = wrapper.next) {
								vertex = wrapper.vertex;
								if (vertex.drawID != numDraws) {
									t = 1/vertex.cameraZ;
									vertices[verticesLength] = vertex.cameraX*viewSizeX*t;
									verticesLength++;
									vertices[verticesLength] = vertex.cameraY*viewSizeY*t;
									verticesLength++;
									uvts[uvtsLength] = vertex.u;
									uvtsLength++;
									uvts[uvtsLength] = vertex.v;
									uvtsLength++;
									uvts[uvtsLength] = t;
									uvtsLength++;
									c = numVertices;
									vertex.index = numVertices++;
									vertex.drawID = numDraws;
								} else {
									c = vertex.index;
								}
								drawIndices[indicesLength] = a;
								indicesLength++;
								drawIndices[indicesLength] = b;
								indicesLength++;
								drawIndices[indicesLength] = c;
								indicesLength++;
								b = c;
								numTriangles++;
							}
							numPolygons++;
							if (temporaryWrapper != null) {
								//for (wrapper = temporaryWrapper; wrapper != null; wrapper.vertex = null, wrapper = wrapper.next);
								wrapper = temporaryWrapper;
								while (wrapper != null) {
									wrapper.vertex = null;
									wrapper = wrapper.next;
								}
								camera.lastWrapper.next = temporaryWrapper;
								camera.lastWrapper = wPositive;
								temporaryWrapper = null;
							}
						}
					}
					// Следующая плоскость
					z *= 0.5;
					// Подрезка
					vertices.length = verticesLength;
					uvts.length = uvtsLength;
					indices.length = indicesLength;
					// Отрисовка
					drawTexture = mipMap[i];
					if (correctUV) {
						du = -0.5/(drawTexture.width - 1);
						dv = -0.5/(drawTexture.height - 1);
						mu = 1 - du - du;
						mv = 1 - dv - dv;
						for (j = 0; j < uvtsLength; j++) {
							uvts[j] = uvts[j]*mu + du; j++;
							uvts[j] = uvts[j]*mv + dv; j++;
						}
					}
					canvas.gfx.beginBitmapFill(drawTexture, null, repeat, smooth);
					canvas.gfx.drawTriangles(vertices, indices, uvts, "none");
				}
			}
			camera.numDraws = numDraws;
			camera.numPolygons = numPolygons;
			camera.numTriangles = numTriangles;
		}
	
		override alternativa3d function drawViewAligned(camera:Camera3D, canvas:Canvas, list:Face, distance:Number, a:Number, b:Number, c:Number, d:Number, tx:Number, ty:Number):void {
			var viewSizeX:Number = camera.viewSizeX;
			var viewSizeY:Number = camera.viewSizeY;
			var face:Face;
			var next:Face;
			// Если нет текстуры, нужно просто расцепить список
			if (texture == null) {
				clearLinks(list);
				return;
			}
			var drawTexure:BitmapData;
			if (mipMapping == 0) {
				// Без мипмаппинга
				drawTexure = texture;
			} else {
				// Мипмаппинг по удалённости объекта от камеры
				var f:Number = camera.focalLength*resolution;
				var level:int = (distance >= f) ? (1 + Math.log(distance/f)*1.442695040888963387) : 0;
				if (level >= numMaps) level = numMaps - 1;
				drawTexure = mipMap[level];
			}
			// Коррекция матрицы
			var tw:Number = drawTexure.width;
			var th:Number = drawTexure.height;
			matrix.a = a/tw;
			matrix.b = b/tw;
			matrix.c = c/th;
			matrix.d = d/th;
			matrix.tx = tx;
			matrix.ty = ty;
			// Отрисовка
			canvas.gfx.beginBitmapFill(drawTexure, matrix, repeat, smooth);
			for (face = list; face != null; face = next) {
				next = face.processNext;
				face.processNext = null;
				var wrapper:Wrapper = face.wrapper;
				var vertex:Vertex = wrapper.vertex;
				canvas.gfx.moveTo(vertex.cameraX*viewSizeX/distance, vertex.cameraY*viewSizeY/distance);
				var numVertices:int = -1;
				for (wrapper = wrapper.next; wrapper != null; wrapper = wrapper.next) {
					vertex = wrapper.vertex;
					canvas.gfx.lineTo(vertex.cameraX*viewSizeX/distance, vertex.cameraY*viewSizeY/distance);
					numVertices++;
				}
				camera.numTriangles += numVertices;
				camera.numPolygons++;
			}
			camera.numDraws++;
		}
	
		public function disposeMipMap():void {
			if (numMaps > 0) {
				for (numMaps--; numMaps > 0; numMaps--) {
					(mipMap[numMaps] as BitmapData).dispose();
				}
				mipMap = null;
			}
		}
	
		public function calculateMipMaps(maxLevel:int = 12):void {
			if (numMaps > 0) {
				for (numMaps--; numMaps > 0; numMaps--) (mipMap[numMaps] as BitmapData).dispose();
			} else {
				mipMap = new Vector.<BitmapData>();
			}
			matrix.identity();
			mipMap[numMaps] = texture;
			numMaps++;
			filter.preserveAlpha = !texture.transparent;
			var bmp:BitmapData = (texture.width*texture.height > 16777215) ? texture.clone() : new BitmapData(texture.width, texture.height, texture.transparent);
			var current:BitmapData = texture;
			var w:Number = rect.width = texture.width;
			var h:Number = rect.height = texture.height;
			while (numMaps <= maxLevel && w > 1 && h > 1 && rect.width > 1 && rect.height > 1) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width = w >> 1;
				rect.height = h >> 1;
				matrix.a = rect.width/w;
				matrix.d = rect.height/h;
				w *= 0.5;
				h *= 0.5;
				current = new BitmapData(rect.width, rect.height, texture.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				mipMap[numMaps] = current;
				numMaps++;
			}
			bmp.dispose();
			mipMap.length = numMaps;
		}
	
	}
}
