package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.VG;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.materials.Material;
	import flash.display.Sprite;
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;
	
	/**
	 * Плоский, всегда развёрнутый к камере трёхмерный объект.
	 */
	public class Sprite3D extends Object3D {
	
		/**
		 * Материал спрайта.
		 * @see alternativa.engine3d.materials.Material
		 */
		public var material:Material;
		
		/**
		 * Координата X точки привязки.
		 * Свойство может принимать значения от <code>0</code> до <code>1</code>.
		 * Значение по умолчанию <code>0.5</code>.
		 */
		public var originX:Number = 0.5;
		
		/**
		 * Координата Y точки привязки.
		 * Свойство может принимать значения от <code>0</code> до <code>1</code>.
		 * Значение по умолчанию <code>0.5</code>.
		 */
		public var originY:Number = 0.5;
		
		/**
		 * Режим сортировки.
		 * Можно использовать следующие константы <code>Sorting</code> для указания свойства <code>sorting</code>: <code>Sorting.NONE</code>, <code>Sorting.AVERAGE_Z</code>, <code>Sorting.DYNAMIC_BSP</code>.
		 * При обычной отрисовке свойство не имеет смысла, но если спрайт является дочерним объектом <code>ConflictContainer</code>, то в случае сортировки на уровне полигонов оно играет роль.
		 * Значение по умолчанию <code>Sorting.NONE</code>.
		 * @see alternativa.engine3d.core.Sorting
		 * @see alternativa.engine3d.containers.ConflictContainer
		 */
		public var sorting:int = 0;
		
		/**
		 * Режим отсечения объекта по пирамиде видимости камеры.
		 * Можно использовать следующие константы <code>Clipping</code> для указания свойства <code>clipping</code>: <code>Clipping.BOUND_CULLING</code>, <code>Clipping.FACE_CULLING</code>, <code>Clipping.FACE_CLIPPING</code>.
		 * Значение по умолчанию <code>Clipping.FACE_CLIPPING</code>.
		 * @see alternativa.engine3d.core.Clipping
		 */
		public var clipping:int = 2;
		
		/**
		 * Угол поворота в плоскости экрана.
		 * Свойство задаётся в радианах.
		 */
		public var rotation:Number = 0;
		
		/**
		 * Ширина спрайта.
		 */
		public var width:Number;
		
		/**
		 * Высота спрайта.
		 */
		public var height:Number;
		
		/**
		 * Свойство отвечает за зависимость размера на экране от удалённости от камеры.
		 * Если <code>false</code>, размер на экране всегда будет одинаковым, независимо от расстояния до камеры.
		 * Значение по умолчанию <code>true</code>.
		 */
		public var perspectiveScale:Boolean = true;
		
		// Текстурная матрица
		static private var tma:Number;
		static private var tmb:Number;
		static private var tmc:Number;
		static private var tmd:Number;
		static private var tmtx:Number;
		static private var tmty:Number;
	
		/**
		 * Создаёт новый экземпляр.
		 * @param width Ширина спрайта.
		 * @param height Высота спрайта.
		 * @param material Материал.
		 * @see alternativa.engine3d.materials.Material
		 */
		public function Sprite3D(width:Number, height:Number, material:Material = null) {
			this.width = width;
			this.height = height;
			this.material = material;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function calculateResolution(textureWidth:int, textureHeight:int, type:int = 1, matrix:Matrix3D = null):Number {
			var w:Number = width;
			var h:Number = height;
			if (matrix != null) {
				var object:Object3D = new Object3D();
				object.matrix = matrix;
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
		
		/**
		 * @inheritDoc
		 */
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
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas):void {
			if (material == null) return;
			var canvas:Canvas;
			var debug:int;
			var face:Face = calculateFace(camera);
			if (face != null) {
				// Дебаг
				if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
					canvas = parentCanvas.getChildCanvas(true, false);
					if (debug & Debug.EDGES) Debug.drawEdges(camera, canvas, face, 0xFFFFFF);
					if (debug & Debug.BOUNDS) Debug.drawBounds(camera, canvas, this, boundMinX, boundMinY, boundMinZ, boundMaxX, boundMaxY, boundMaxZ);
				}
				// Отрисовка
				canvas = parentCanvas.getChildCanvas(true, false, this, alpha, blendMode, colorTransform, filters);
				material.drawViewAligned(camera, canvas, face, ml, tma, tmb, tmc, tmd, tmtx, tmty);
			}
		}
	
		/**
		 * @private 
		 */
		override alternativa3d function getVG(camera:Camera3D):VG {
			if (material == null) return null;
			var face:Face = calculateFace(camera);
			if (face != null) {
				return VG.create(this, face, sorting, camera.debug ? camera.checkInDebug(this) : 0, true, tma, tmb, tmc, tmd, tmtx, tmty);
			} else {
				return null;
			}
		}
	
		private function calculateFace(camera:Camera3D):Face {
			culling &= 60;
			var z:Number = ml;
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
			ax = ma/perspectiveScaleX;
			ay = me/perspectiveScaleY;
			az = mi;
			size = Math.sqrt(ax*ax + ay*ay + az*az);
			ax = mb/perspectiveScaleX;
			ay = mf/perspectiveScaleY;
			az = mj;
			size += Math.sqrt(ax*ax + ay*ay + az*az);
			ax = mc/perspectiveScaleX;
			ay = mg/perspectiveScaleY;
			az = mk;
			size += Math.sqrt(ax*ax + ay*ay + az*az);
			size /= 3;
			// Учёт флага масштабирования
			if (!perspectiveScale) size /= projectionZ;
			// Если не задано вращение
			if (rotation == 0) {
				// Размеры спрайта в матрице камеры
				var cameraWidth:Number = size*width*perspectiveScaleX;
				var cameraHeight:Number = size*height*perspectiveScaleY;
				ax = md - originX*cameraWidth;
				ay = mh - originY*cameraHeight;
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
				ax = md - originX*cameraWidthX - originY*cameraHeightX;
				ay = mh - originX*cameraWidthY - originY*cameraHeightY;
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
	
		/**
		 * @private 
		 */
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
	
	}
}
