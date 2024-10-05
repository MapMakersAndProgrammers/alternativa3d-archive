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
	import flash.display.Sprite;
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;
	
	/**
	 * Плоский, всегда развёрнутый к камере трёхмерный объект
	 */
	public class Sprite3D extends Object3D {
	
		/**
		 * Материал
		 */
		public var material:Material;
		/**
		 * Режим сортировки на случай конфликта
		 * 0 - без сортировки
		 * 1 - сортировка по средним Z
		 * 2 - построение динамического BSP при отрисовке
		 * 3 - проход по предрасчитанному BSP
		 */
		public var sorting:int = 0;
		/**
		 * X точки привязки
		 */
		public var originX:Number = 0.5;
		/**
		 * Y точки привязки
		 */
		public var originY:Number = 0.5;
		/**
		 * Режим отсечения объекта по пирамиде видимости камеры.
		 * 0 - весь объект
		 * 2 - клиппинг граней по пирамиде видимости камеры
		 */
		public var clipping:int = 2;
		/**
		 * Угол поворота в радианах в плоскости экрана
		 */
		public var rotation:Number = 0;
		/**
		 * Ширина
		 */
		public var width:Number;
		/**
		 * Высота
		 */
		public var height:Number;
		/**
		 * Зависимость размера на экране от удалённости от камеры
		 */
		public var perspectiveScale:Boolean = true;
		
		// Текстурная матрица
		static private var tma:Number;
		static private var tmb:Number;
		static private var tmc:Number;
		static private var tmd:Number;
		static private var tmtx:Number;
		static private var tmty:Number;
	
		public function Sprite3D(width:Number = 100, height:Number = 100, material:Material = null) {
			this.width = width;
			this.height = height;
			this.material = material;
		}
		
		public function calculateResolution(textureWidth:int, textureHeight:int, type:int = 1, matrix:Matrix3D = null):Number {
			var w:Number = width;
			var h:Number = height;
			if (matrix != null) {
				var object:Object3D = new Object3D();
				object.setMatrix(matrix);
				object.composeMatrix();
				var scale:Number = (Math.sqrt(object.ma*object.ma + object.me*object.me + object.mi*object.mi) + Math.sqrt(object.mb*object.mb + object.mf*object.mf + object.mj*object.mj) +  Math.sqrt(object.mc*object.mc + object.mg*object.mg + object.mk*object.mk))/3;
				w *= scale;
				h *= scale;
			}
			w /= textureWidth;
			h /= textureHeight;
			if (type == 0) {
				return w;
			} else if (type == 1) {
				return (w + h)/2;
			} else if (type == 2) {
				return (w < h) ? w : h;
			} else {
				return (w > h) ? w : h;
			}
		}
		
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			if (material == null) return;
			var canvas:Canvas;
			var debug:int;
			var face:Face = calculateFace(camera, object);
			if (face != null) {
				// Дебаг
				if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
					canvas = parentCanvas.getChildCanvas(object, true, false);
					if (debug & Debug.EDGES) Debug.drawEdges(camera, canvas, face, 0xFFFFFF);
					if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, object, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
				}
				// Отрисовка
				canvas = parentCanvas.getChildCanvas(object, true, false, object.alpha, object.blendMode, object.colorTransform, object.filters);
				material.drawViewAligned(camera, canvas, face, object.ml, tma, tmb, tmc, tmd, tmtx, tmty);
			}
		}
	
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			if (material == null) return null;
			var face:Face = calculateFace(camera, object);
			if (face != null) {
				var geometry:Geometry = Geometry.create();
				geometry.interactiveObject = object;
				geometry.faceStruct = face;
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
				geometry.alpha = object.alpha;
				geometry.blendMode = object.blendMode;
				geometry.colorTransform = object.colorTransform;
				geometry.filters = object.filters;
				geometry.sorting = sorting;
				geometry.viewAligned = true;
				geometry.tma = tma;
				geometry.tmb = tmb;
				geometry.tmc = tmc;
				geometry.tmd = tmd;
				geometry.tmtx = tmtx;
				geometry.tmty = tmty;
				if (camera.debug) geometry.debug = camera.checkInDebug(this);
				return geometry;
			} else {
				return null;
			}
		}
	
		private function calculateFace(camera:Camera3D, object:Object3D):Face {
			var culling:int = object.culling & 60;
			var z:Number = object.ml;
			var size:Number;
			var ax:Number;
			var ay:Number;
			var az:Number;
			var bx:Number;
			var by:Number;
			var cx:Number;
			var cy:Number;
			var dx:Number;
			var dy:Number;
			var first:Vertex;
			var last:Vertex;
			// Выход по ближнему или дальнему расстоянию отсечения
			if (z <= camera.nearClipping || z >= camera.farClipping) return null;
			// Проекция
			var projectionX:Number = camera.viewSizeX/z;
			var projectionY:Number = camera.viewSizeY/z;
			var projectionZ:Number = camera.focalLength/z;
			// Учёт искажения матрицы камеры под 90 градусов
			var perspectiveScaleX:Number = camera.focalLength/camera.viewSizeX;
			var perspectiveScaleY:Number = camera.focalLength/camera.viewSizeY;
			// Нахождение среднего размера спрайта
			ax = object.ma/perspectiveScaleX;
			ay = object.me/perspectiveScaleY;
			az = object.mi;
			size = Math.sqrt(ax*ax + ay*ay + az*az);
			ax = object.mb/perspectiveScaleX;
			ay = object.mf/perspectiveScaleY;
			az = object.mj;
			size += Math.sqrt(ax*ax + ay*ay + az*az);
			ax = object.mc/perspectiveScaleX;
			ay = object.mg/perspectiveScaleY;
			az = object.mk;
			size += Math.sqrt(ax*ax + ay*ay + az*az);
			size /= 3;
			// Учёт флага масштабирования
			if (!perspectiveScale) size /= projectionZ;
			// Если не задано вращение
			if (rotation == 0) {
				// Размеры спрайта в матрице камеры
				var cameraWidth:Number = size*width*perspectiveScaleX;
				var cameraHeight:Number = size*height*perspectiveScaleY;
				ax = object.md - originX*cameraWidth;
				ay = object.mh - originY*cameraHeight;
				cx = ax + cameraWidth;
				cy = ay + cameraHeight;
				// Подготовка смещения матрицы отрисовки
				tmtx = ax*projectionX;
				tmty = ay*projectionY;
				// Отсечение по пирамиде видимости
				if (culling > 0) {
					if (ax > z || ay > z || cx < -z || cy < -z) return null;
					if (clipping == 2) {
						if (ax < -z) ax = -z;
						if (ay < -z) ay = -z;
						if (cx > z) cx = z;
						if (cy > z) cy = z;
					}
				}
				// Создание вершин
				first = Vertex.createList(4);
				last = first;
				last.cameraX = ax;
				last.cameraY = ay;
				last.cameraZ = z;
				last = last.next;
				last.cameraX = ax;
				last.cameraY = cy;
				last.cameraZ = z;
				last = last.next;
				last.cameraX = cx;
				last.cameraY = cy;
				last.cameraZ = z;
				last = last.next;
				last.cameraX = cx;
				last.cameraY = ay;
				last.cameraZ = z;
				// Подготовка матрицы отрисовки
				tma = size*projectionZ*width;
				tmb = 0;
				tmc = 0;
				tmd = size*projectionZ*height;
			} else {
				// Расчёт векторов ширины и высоты
				var sin:Number = -Math.sin(rotation)*size;
				var cos:Number = Math.cos(rotation)*size;
				var cameraWidthX:Number = cos*width*perspectiveScaleX;
				var cameraWidthY:Number = -sin*width*perspectiveScaleY;
				var cameraHeightX:Number = sin*height*perspectiveScaleX;
				var cameraHeightY:Number = cos*height*perspectiveScaleY;
				ax = object.md - originX*cameraWidthX - originY*cameraHeightX;
				ay = object.mh - originX*cameraWidthY - originY*cameraHeightY;
				bx = ax + cameraHeightX;
				by = ay + cameraHeightY;
				cx = ax + cameraWidthX + cameraHeightX;
				cy = ay + cameraWidthY + cameraHeightY;
				dx = ax + cameraWidthX;
				dy = ay + cameraWidthY;
				// Подготовка смещения матрицы отрисовки
				tmtx = ax*projectionX;
				tmty = ay*projectionY;
				// Отсечение по пирамиде видимости
				if (culling > 0) {
					if (clipping == 1) {
						if ((culling & 4) && z <= -ax && z <= -bx && z <= -cx && z <= -dx) return null;
						if ((culling & 8) && z <= ax && z <= bx && z <= cx && z <= dx) return null;
						if ((culling & 16) && z <= -ay && z <= -by && z <= -cy && z <= -dy) return null;
						if ((culling & 32) && z <= ay && z <= by && z <= cy && z <= dy) return null;
						// Создание вершин
						first = Vertex.createList(4);
						last = first;
						last.cameraX = ax;
						last.cameraY = ay;
						last.cameraZ = z;
						last = last.next;
						last.cameraX = ax + cameraHeightX;
						last.cameraY = ay + cameraHeightY;
						last.cameraZ = z;
						last = last.next;
						last.cameraX = ax + cameraWidthX + cameraHeightX;
						last.cameraY = ay + cameraWidthY + cameraHeightY;
						last.cameraZ = z;
						last = last.next;
						last.cameraX = ax + cameraWidthX;
						last.cameraY = ay + cameraWidthY;
						last.cameraZ = z;
					} else {
						if (culling & 4) {
							if (z <= -ax && z <= -bx && z <= -cx && z <= -dx) {
								return null;
							} else if (z > -ax && z > -bx && z > -cx && z > -dx) {
								culling &= 59;
							}
						}
						if (culling & 8) {
							if (z <= ax && z <= bx && z <= cx && z <= dx) {
								return null;
							} else if (z > ax && z > bx && z > cx && z > dx) {
								culling &= 55;
							}
						}
						if (culling & 16) {
							if (z <= -ay && z <= -by && z <= -cy && z <= -dy) {
								return null;
							} else if (z > -ay && z > -by && z > -cy && z > -dy) {
								culling &= 47;
							}
						}
						if (culling & 32) {
							if (z <= ay && z <= by && z <= cy && z <= dy) {
								return null;
							} else if (z > ay && z > by && z > cy && z > dy) {
								culling &= 31;
							}
						}
						// Создание вершин
						first = Vertex.createList(4);
						last = first;
						last.cameraX = ax;
						last.cameraY = ay;
						last.cameraZ = z;
						last = last.next;
						last.cameraX = ax + cameraHeightX;
						last.cameraY = ay + cameraHeightY;
						last.cameraZ = z;
						last = last.next;
						last.cameraX = ax + cameraWidthX + cameraHeightX;
						last.cameraY = ay + cameraWidthY + cameraHeightY;
						last.cameraZ = z;
						last = last.next;
						last.cameraX = ax + cameraWidthX;
						last.cameraY = ay + cameraWidthY;
						last.cameraZ = z;
						if (culling > 0) {
							var t:Number;
							var a:Vertex;
							var b:Vertex;
							var v:Vertex;
							var next:Vertex;
							// Клиппинг по левой стороне
							if (culling & 4) {
								a = last;
								ax = a.cameraX;
								for (b = first,first = null,last = null; b != null; b = next) {
									next = b.next;
									bx = b.cameraX;
									if (z > -bx && z <= -ax || z <= -bx && z > -ax) {
										t = (ax + z)/(ax - bx);
										v = b.create();
										v.cameraX = ax + (bx - ax)*t;
										v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
										v.cameraZ = z;
										if (first != null) last.next = v; else first = v;
										last = v;
									}
									if (z > -bx) {
										if (first != null) last.next = b; else first = b;
										last = b;
										b.next = null;
									} else {
										b.next = Vertex.collector;
										Vertex.collector = b;
									}
									a = b;
									ax = bx;
								}
								if (first == null) return null;
							}
							// Клиппинг по правой стороне
							if (culling & 8) {
								a = last;
								ax = a.cameraX;
								for (b = first,first = null,last = null; b != null; b = next) {
									next = b.next;
									bx = b.cameraX;
									if (z > bx && z <= ax || z <= bx && z > ax) {
										t = (z - ax)/(bx - ax);
										v = b.create();
										v.cameraX = ax + (bx - ax)*t;
										v.cameraY = a.cameraY + (b.cameraY - a.cameraY)*t;
										v.cameraZ = z;
										if (first != null) last.next = v; else first = v;
										last = v;
									}
									if (z > bx) {
										if (first != null) last.next = b; else first = b;
										last = b;
										b.next = null;
									} else {
										b.next = Vertex.collector;
										Vertex.collector = b;
									}
									a = b;
									ax = bx;
								}
								if (first == null) return null;
							}
							// Клиппинг по верхней стороне
							if (culling & 16) {
								a = last;
								ay = a.cameraY;
								for (b = first,first = null,last = null; b != null; b = next) {
									next = b.next;
									by = b.cameraY;
									if (z > -by && z <= -ay || z <= -by && z > -ay) {
										t = (ay + z)/(ay - by);
										v = b.create();
										v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
										v.cameraY = ay + (by - ay)*t;
										v.cameraZ = z;
										if (first != null) last.next = v; else first = v;
										last = v;
									}
									if (z > -by) {
										if (first != null) last.next = b; else first = b;
										last = b;
										b.next = null;
									} else {
										b.next = Vertex.collector;
										Vertex.collector = b;
									}
									a = b;
									ay = by;
								}
								if (first == null) return null;
							}
							// Клиппинг по нижней стороне
							if (culling & 32) {
								a = last;
								ay = a.cameraY;
								for (b = first,first = null,last = null; b != null; b = next) {
									next = b.next;
									by = b.cameraY;
									if (z > by && z <= ay || z <= by && z > ay) {
										t = (z - ay)/(by - ay);
										v = b.create();
										v.cameraX = a.cameraX + (b.cameraX - a.cameraX)*t;
										v.cameraY = ay + (by - ay)*t;
										v.cameraZ = z;
										if (first != null) last.next = v; else first = v;
										last = v;
									}
									if (z > by) {
										if (first != null) last.next = b; else first = b;
										last = b;
										b.next = null;
									} else {
										b.next = Vertex.collector;
										Vertex.collector = b;
									}
									a = b;
									ay = by;
								}
								if (first == null) return null;
							}
						}
					}
				} else {
					// Создание вершин
					first = Vertex.createList(4);
					last = first;
					last.cameraX = ax;
					last.cameraY = ay;
					last.cameraZ = z;
					last = last.next;
					last.cameraX = ax + cameraHeightX;
					last.cameraY = ay + cameraHeightY;
					last.cameraZ = z;
					last = last.next;
					last.cameraX = ax + cameraWidthX + cameraHeightX;
					last.cameraY = ay + cameraWidthY + cameraHeightY;
					last.cameraZ = z;
					last = last.next;
					last.cameraX = ax + cameraWidthX;
					last.cameraY = ay + cameraWidthY;
					last.cameraZ = z;
				}
				// Подготовка матрицы отрисовки
				tma = cos*projectionZ*width;
				tmb = -sin*projectionZ*width;
				tmc = sin*projectionZ*height;
				tmd = cos*projectionZ*height;
			}
			// Отправка на отложенное удаление
			camera.lastVertex.next = first;
			camera.lastVertex = last;
			// Создание грани
			var face:Face = Face.create();
			face.material = material;
			camera.lastFace.next = face;
			camera.lastFace = face;
			var wrapper:Wrapper = Wrapper.create();
			face.wrapper = wrapper;
			wrapper.vertex = first;
			for (first = first.next; first != null; first = first.next) {
				wrapper.next = wrapper.create();
				wrapper = wrapper.next;
				wrapper.vertex = first;
			}
			return face;
		}
	
		override alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			// Расчёт локального радиуса
			var w:Number = ((originX >= 0.5) ? originX : (1 - originX))*width;
			var h:Number = ((originY >= 0.5) ? originY : (1 - originY))*height;
			var radius:Number = Math.sqrt(w*w + h*h);
			var cx:Number = 0;
			var cy:Number = 0;
			var cz:Number = 0;
			if (transformation != null) {
				// Нахождение среднего размера спрайта
				var ax:Number = transformation.ma;
				var ay:Number = transformation.me;
				var az:Number = transformation.mi;
				var size:Number = Math.sqrt(ax*ax + ay*ay + az*az);
				ax = transformation.mb;
				ay = transformation.mf;
				az = transformation.mj;
				size += Math.sqrt(ax*ax + ay*ay + az*az);
				ax = transformation.mc;
				ay = transformation.mg;
				az = transformation.mk;
				size += Math.sqrt(ax*ax + ay*ay + az*az);
				radius *= size/3;
				cx = transformation.md;
				cy = transformation.mh;
				cz = transformation.ml;
			}
			if (cx - radius < bounds.boundMinX) bounds.boundMinX = cx - radius;
			if (cx + radius > bounds.boundMaxX) bounds.boundMaxX = cx + radius;
			if (cy - radius < bounds.boundMinY) bounds.boundMinY = cy - radius;
			if (cy + radius > bounds.boundMaxY) bounds.boundMaxY = cy + radius;
			if (cz - radius < bounds.boundMinZ) bounds.boundMinZ = cz - radius;
			if (cz + radius > bounds.boundMaxZ) bounds.boundMaxZ = cz + radius;
		}
	
		public function copyFrom(source:Sprite3D):void {
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
	
			material = source.material;
			originX = source.originX;
			originY = source.originY;
			rotation = source.rotation;
			perspectiveScale = source.perspectiveScale;
		}
		
		override public function clone():Object3D {
			var sprite:Sprite3D = new Sprite3D(width, height, material);
			sprite.cloneBaseProperties(this);
			sprite.clipping = clipping;
			sprite.sorting = sorting;
			sprite.originX = originX;
			sprite.originY = originY;
			sprite.rotation = rotation;
			sprite.perspectiveScale = perspectiveScale;
			return sprite;
		}

	}
}
