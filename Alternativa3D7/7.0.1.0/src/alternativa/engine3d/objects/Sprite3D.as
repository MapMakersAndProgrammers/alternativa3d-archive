package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.MipMap;
	import alternativa.engine3d.core.Object3D;
	
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;

	use namespace alternativa3d;
	
	/**
	 * Плоский, всегда развёрнутый к камере трёхмерный объект
	 */
	public class Sprite3D extends Object3D {
		
		static public var debug:Boolean = false;
		
		static private const axes:Vector.<Number> = Vector.<Number>([0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]);
		static private const cameraAxes:Vector.<Number> = new Vector.<Number>(12, true);
		/**
		 * @private
		 */
		static alternativa3d const textureMatrix:Matrix = new Matrix();
		/**
		 * @private
		 */
		static alternativa3d const vertices:Vector.<Number> = new Vector.<Number>();
		/**
		 * @private
		 */
		alternativa3d var drawTexture:BitmapData;
		/**
		 * @private
		 */
		alternativa3d var projectionX:Number;
		/**
		 * @private
		 */
		alternativa3d var projectionY:Number;
		
		public var texture:BitmapData;
		public var mipMap:MipMap;
		/**
		 * X точки привязки 
		 */
		public var originX:Number = 0.5;
		/**
		 * Y точки привязки 
		 */
		public var originY:Number = 0.5;
		public var smooth:Boolean = false;
		/**
		 * Режим отсечения объекта по пирамиде видимости камеры.
		 * 0 - весь объект
		 * 2 - клиппинг граней по пирамиде видимости камеры 
		 */
		public var clipping:int = 0; // 0 - весь объект, 2 - с обрезкой 
		public var mipMapping:int = 0; // 0 - без мипмаппинга, 1 - по дальности
		/**
		 * Угол поворота в радианах в плоскости экрана 
		 */
		public var rotation:Number = 0;
		/**
		 * Зависимость размера на экране от удалённости от камеры
		 */
		public var perspectiveScale:Boolean = true;
		
		/**
		 * @private
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			
			var length:int;
			if ((length = calculateVertices(object, camera)) == 0) return;
			
			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, object.alpha, object.blendMode, object.colorTransform, object.filters);

			canvas.gfx.beginBitmapFill(drawTexture, textureMatrix, false, smooth);
			if (debug) canvas.gfx.lineStyle(0, 0xFFFFFF);
			
			if (rotation == 0) {
				// Простая отрисовка
				var x:Number = vertices[0]*projectionX, y:Number = vertices[1]*projectionY;
				canvas.gfx.drawRect(x, y, vertices[6]*projectionX - x, vertices[7]*projectionY - y);
			} else {
				// Отрисовка
				canvas.gfx.moveTo(vertices[length - 3]*projectionX, vertices[length - 2]*projectionY);
				for (var i:int = 0; i < length; i++) canvas.gfx.lineTo(vertices[i++]*projectionX, vertices[i++]*projectionY);
			}

			if (debug) object.drawBoundBox(camera, canvas);
		}

		/**
		 * @private
		 */
		alternativa3d function calculateVertices(object:Object3D, camera:Camera3D):int {

			// Получение матрицы и позиции
			object.cameraMatrix.transformVectors(axes, cameraAxes);
			var cz:Number = cameraAxes[2];
			
			if (cz < camera.nearClipping || cz > camera.farClipping) return 0;
			var cx:Number = cameraAxes[0];
			var cy:Number = cameraAxes[1];
			
			// Нахождение среднего размера спрайта
			var ax:Number = (cameraAxes[3] - cx)*camera.invertPerspectiveScaleX;
			var ay:Number = (cameraAxes[4] - cy)*camera.invertPerspectiveScaleY;
			var az:Number = cameraAxes[5] - cz;
			var size:Number = Math.sqrt(ax*ax + ay*ay + az*az); 
			ax = (cameraAxes[6] - cx)*camera.invertPerspectiveScaleX;
			ay = (cameraAxes[7] - cy)*camera.invertPerspectiveScaleY;
			az = cameraAxes[8] - cz;
			size += Math.sqrt(ax*ax + ay*ay + az*az);
			ax = (cameraAxes[9] - cx)*camera.invertPerspectiveScaleX;
			ay = (cameraAxes[10] - cy)*camera.invertPerspectiveScaleY;
			az = cameraAxes[11] - cz;
			size = (size + Math.sqrt(ax*ax + ay*ay + az*az))/3;
			
			// Определение текстуры и коррекция размера
			var level:int;
			if (mipMapping == 0) {
				drawTexture = texture;
			} else {
				size *= Math.pow(2, level = mipMap.getLevel(cz/size, camera));
				drawTexture = mipMap.textures[level];
			}
			
			// Проекция на экран
			var projectionZ:Number = camera.focalLength/cz;
			projectionX = camera.viewSizeX/cz;
			projectionY = camera.viewSizeY/cz;
			
			if (!perspectiveScale) size /= projectionZ;
			
			var x1:Number, y1:Number, x2:Number, y2:Number;

			if (rotation == 0) {
				
				// Размеры спрайта в матрице камеры
				var cameraWidth:Number = drawTexture.width*camera.perspectiveScaleX*size;
				var cameraHeight:Number = drawTexture.height*camera.perspectiveScaleY*size;
				
				// Расчёт вершин в матрице камеры
				x1 = cx - originX*cameraWidth;
				y1 = cy - originY*cameraHeight;
				x2 = x1 + cameraWidth;
				y2 = y1 + cameraHeight;

				// Отсечение по вьюпорту
				if (object.culling > 0 && (x1 > cz || y1 > cz || x2 < -cz || y2 < -cz)) return 0; 
				
				// Подготовка матрицы отрисовки
				textureMatrix.a = textureMatrix.d = size*projectionZ;
				textureMatrix.b = textureMatrix.c = 0;
				textureMatrix.tx = x1*projectionX;
				textureMatrix.ty = y1*projectionY;
				
				// Подрезка
				if (clipping == 2) {
					if (x1 < -cz) x1 = -cz;
					if (y1 < -cz) y1 = -cz;
					if (x2 > cz) x2 = cz;
					if (y2 > cz) y2 = cz;
				}

				// Заполняем вершины
				vertices[0] = x1;
				vertices[1] = y1;
				vertices[2] = cz;
				vertices[3] = x1;
				vertices[4] = y2;
				vertices[5] = cz;
				vertices[6] = x2;
				vertices[7] = y2;
				vertices[8] = cz;
				vertices[9] = x2;
				vertices[10] = y1;
				vertices[11] = cz;
				
				return 12;
				
			} else {
			
				// Размер спрайта в камере без коррекции под FOV90
				var textureWidth:Number = drawTexture.width;
				var textureHeight:Number = drawTexture.height;

				// Расчёт векторов ширины и высоты
				var sin:Number = Math.sin(rotation)*size;
				var cos:Number = Math.cos(rotation)*size;
				var cameraWidthX:Number = cos*textureWidth*camera.perspectiveScaleX;
				var cameraWidthY:Number = -sin*textureWidth*camera.perspectiveScaleY;
				var cameraHeightX:Number = sin*textureHeight*camera.perspectiveScaleX;
				var cameraHeightY:Number = cos*textureHeight*camera.perspectiveScaleY;
				
				// Заполняем вершины
				var length:int = 12;
				vertices[0] = x1 = cx - originX*cameraWidthX - originY*cameraHeightX;
				vertices[1] = y1 = cy - originX*cameraWidthY - originY*cameraHeightY;
				vertices[2] = cz;
				vertices[3] = x1 + cameraHeightX;
				vertices[4] = y1 + cameraHeightY;
				vertices[5] = cz;
				vertices[6] = x1 + cameraWidthX + cameraHeightX;
				vertices[7] = y1 + cameraWidthY + cameraHeightY;
				vertices[8] = cz;
				vertices[9] = x1 + cameraWidthX;
				vertices[10] = y1 + cameraWidthY;
				vertices[11] = cz;
				
				if (object.culling > 0) {
					// Отсечение по вьюпорту
					var i:int, infront:Boolean, behind:Boolean, inside:Boolean;
					var clipLeft:Boolean = false;
					if (object.culling & 4) {
						for (i = 0; i < length; i += 3) if ((inside = -vertices[i] < cz) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) return 0; else clipLeft = true;
						infront = false; behind = false;
					}	
					var clipRight:Boolean = false;
					if (object.culling & 8) {
						for (i = 0; i < length; i += 3) if ((inside = vertices[i] < cz) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) return 0; else clipRight = true;
						infront = false; behind = false;
					}	
					var clipTop:Boolean = false;
					if (object.culling & 16) {
						for (i = 1; i < length; i += 3) if ((inside = -vertices[i] < cz) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) return 0; else clipTop = true;
						infront = false; behind = false;
					}	
					var clipBottom:Boolean = false;
					if (object.culling & 32) {
						for (i = 1; i < length; i += 3) if ((inside = vertices[i] < cz) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) return 0; else clipBottom = true;
					}
					// Подрезка
					if (clipping == 2) {
						var n:int = 0, t:Number, bx:Number, by:Number;
						if (clipLeft) {
							ax = cx = vertices[0]; ay = cy = vertices[1];
							for (i = 3; i <= length; i++) {
								if (i < length) {
									bx = vertices[i++]; by = vertices[i++];
								} else {
									bx = cx; by = cy;
								}
								if (-bx < cz && -ax >= cz || -bx >= cz && -ax < cz) {
									t = (ax + cz)/(ax - bx);
									vertices[n++] = ax + (bx - ax)*t;
									vertices[n++] = ay + (by - ay)*t;
									vertices[n++] = cz;
								}
								if (-bx < cz) {
									vertices[n++] = bx; vertices[n++] = by; vertices[n++] = cz;
								}
								ax = bx; ay = by;
							}
							if (n == 0) return 0;
							length = n; n = 0;
						}
						if (clipRight) {
							ax = cx = vertices[0]; ay = cy = vertices[1];
							for (i = 3; i <= length; i++) {
								if (i < length) {
									bx = vertices[i++]; by = vertices[i++];
								} else {
									bx = cx; by = cy;
								}
								if (bx < cz && ax >= cz || bx >= cz && ax < cz) {
									t = (cz - ax)/(bx - ax);
									vertices[n++] = ax + (bx - ax)*t;
									vertices[n++] = ay + (by - ay)*t;
									vertices[n++] = cz;
								}
								if (bx < cz) {
									vertices[n++] = bx; vertices[n++] = by; vertices[n++] = cz;
								}
								ax = bx; ay = by;
							}
							if (n == 0) return 0;
							length = n; n = 0;
						}
						if (clipTop) {
							ax = cx = vertices[0]; ay = cy = vertices[1];
							for (i = 3; i <= length; i++) {
								if (i < length) {
									bx = vertices[i++]; by = vertices[i++];
								} else {
									bx = cx; by = cy;
								}
								if (-by < cz && -ay >= cz || -by >= cz && -ay < cz) {
									t = (ay + cz)/(ay - by);
									vertices[n++] = ax + (bx - ax)*t;
									vertices[n++] = ay + (by - ay)*t;
									vertices[n++] = cz;
								}
								if (-by < cz) {
									vertices[n++] = bx; vertices[n++] = by; vertices[n++] = cz;
								}
								ax = bx; ay = by;
							}
							if (n == 0) return 0;
							length = n; n = 0;
						}
						if (clipBottom) {
							ax = cx = vertices[0]; ay = cy = vertices[1];
							for (i = 3; i <= length; i++) {
								if (i < length) {
									bx = vertices[i++]; by = vertices[i++];
								} else {
									bx = cx; by = cy;
								}
								if (by < cz && ay >= cz || by >= cz && ay < cz) {
									t = (cz - ay)/(by - ay);
									vertices[n++] = ax + (bx - ax)*t;
									vertices[n++] = ay + (by - ay)*t;
									vertices[n++] = cz;
								}
								if (by < cz) {
									vertices[n++] = bx; vertices[n++] = by; vertices[n++] = cz;
								}
								ax = bx; ay = by;
							}
							if (n == 0) return 0;
							length = n; n = 0;
						}
					}
				}
				
				// Подготовка матрицы отрисовки
				textureMatrix.a = textureMatrix.d = cos*projectionZ;
				textureMatrix.b = -sin*projectionZ;
				textureMatrix.c = sin*projectionZ;
				textureMatrix.tx = x1*projectionX;
				textureMatrix.ty = y1*projectionY;
				
				return length;
				
			}
		}
		
		override public function calculateBoundBox(matrix:Matrix3D = null, boundBox:BoundBox = null):BoundBox {
			// Если указан баунд-бокс
			if (boundBox != null) {
				boundBox.infinity();
			} else {
				boundBox = new BoundBox();
			}
			// Расчёт локального радиуса
			var t:BitmapData = (mipMapping == 0) ? texture : mipMap.textures[0];
			var w:Number = ((originX >= 0.5) ? originX : (1 - originX))*t.width;
			var h:Number = ((originY >= 0.5) ? originY : (1 - originY))*t.height;
			var radius:Number = Math.sqrt(w*w + h*h);
			// Если указана матрица трансформации, переводим
			if (matrix != null) {
				matrix.transformVectors(axes, cameraAxes);
				var cz:Number = cameraAxes[2];
				var cx:Number = cameraAxes[0];
				var cy:Number = cameraAxes[1];
				// Нахождение среднего размера спрайта
				var ax:Number = cameraAxes[3] - cx;
				var ay:Number = cameraAxes[4] - cy;
				var az:Number = cameraAxes[5] - cz;
				var size:Number = Math.sqrt(ax*ax + ay*ay + az*az); 
				ax = cameraAxes[6] - cx;
				ay = cameraAxes[7] - cy;
				az = cameraAxes[8] - cz;
				size += Math.sqrt(ax*ax + ay*ay + az*az);
				ax = cameraAxes[9] - cx;
				ay = cameraAxes[10] - cy;
				az = cameraAxes[11] - cz;
				size = radius*(size + Math.sqrt(ax*ax + ay*ay + az*az))/3;
				boundBox.setSize(cx - size, cy - size, cz - size, cx + size, cy + size, cz + size);
			} else {
				boundBox.setSize(-radius, -radius, -radius, radius, radius, radius);
			}
			return boundBox;
		}
		
		public function copyFrom(source:Sprite3D):void {
			visible = source.visible;
			alpha = source.alpha;
			blendMode = source.blendMode;
			originX = source.originX;
			originY = source.originY;
			smooth = source.smooth;
			clipping = source.clipping;
			rotation = source.rotation;
			perspectiveScale = source.perspectiveScale;
			texture = source.texture;
			mipMapping = source.mipMapping;
			mipMap = source.mipMap;
			matrix.identity();
			matrix.append(source.matrix);
			if (source.boundBox != null) {
				if (boundBox == null) boundBox = new BoundBox();
				boundBox.copyFrom(source.boundBox);
			} else boundBox = null;
		}
		
	}
}