package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Fragment;
	import alternativa.engine3d.core.Geometry;
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
		public var texture:BitmapData;
		public var smooth:Boolean = false;
		/**
		 * Режим сортировки на случай конфликта
		 * 0 - без сортировки
		 * 1 - сортировка по средним Z
		 * 2 - проход по предрасчитанному BSP. Для расчёта BSP нужен calculateBSP()
		 * 3 - построение динамического BSP при отрисовке
		 */
		public var sorting:int = 0;
		/**
		 * Применение мипмаппинга
		 * 0 - без мипмаппинга
		 * 1 - мипмаппинг по удалённости от камеры. Требуется установка свойства mipMap
		 */
		public var mipMapping:int = 0;
		public var mipMap:MipMap;
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
		public var clipping:int = 0;
		/**
		 * Угол поворота в радианах в плоскости экрана 
		 */
		public var rotation:Number = 0;
		/**
		 * Зависимость размера на экране от удалённости от камеры
		 */
		public var perspectiveScale:Boolean = true;
		
		// Вспомогательные
		static private const vertices:Vector.<Number> = new Vector.<Number>();
		static private const axes:Vector.<Number> = Vector.<Number>([0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]);
		static private const cameraAxes:Vector.<Number> = new Vector.<Number>(12, true);
		static private const textureMatrix:Matrix = new Matrix();
		static private var drawTexture:BitmapData;
		private var projectionX:Number;
		private var projectionY:Number;
		
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var verticesLength:int = calculateVertices(object, camera);
			if (verticesLength > 0) {
				var canvas:Canvas = parentCanvas.getChildCanvas(true, false, object.alpha, object.blendMode, object.colorTransform, object.filters);
				canvas.gfx.beginBitmapFill(drawTexture, textureMatrix, false, smooth);
				var x:Number = vertices[0]*projectionX;
				var y:Number = vertices[1]*projectionY;
				if (rotation == 0) {
					canvas.gfx.drawRect(x, y, vertices[6]*projectionX - x, vertices[7]*projectionY - y);
				} else {
					canvas.gfx.moveTo(x, y);
					for (var i:int = 3; i < verticesLength; i++) {
						x = vertices[i]*projectionX; i++;
						y = vertices[i]*projectionY; i++;
						canvas.gfx.lineTo(x, y);
					}
				}
			}
		}
		
		override alternativa3d function debug(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var debugResult:int = camera.checkInDebug(this);
			if (debugResult == 0) return;
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false);
			var i:int, length:int, x:Number, y:Number, t:Number = 0.1;
			// Рёбра
			if (debugResult & Debug.EDGES) {
				if ((length = calculateVertices(object, camera)) > 0) {
					if (canvas == null) canvas = parentCanvas.getChildCanvas(true, false);
					canvas.gfx.lineStyle(0, 0xFFFFFF);
					if (rotation == 0) {
						x = vertices[0]*projectionX, y = vertices[1]*projectionY;
						canvas.gfx.drawRect(x, y, vertices[6]*projectionX - x, vertices[7]*projectionY - y);
					} else {
						// Отрисовка
						canvas.gfx.moveTo(vertices[length - 3]*projectionX, vertices[length - 2]*projectionY);
						for (i = 0; i < length; i++) canvas.gfx.lineTo(vertices[i++]*projectionX, vertices[i++]*projectionY);
					}
				}
			}
			// Вершины
			if (debugResult & Debug.VERTICES) {
				if ((length = calculateVertices(object, camera)) > 0) {
					if (canvas == null) canvas = parentCanvas.getChildCanvas(true, false);
					canvas.gfx.lineStyle();
					if (rotation == 0) {
						var x1:Number = vertices[0]*projectionX, y1:Number = vertices[1]*projectionY;
						var x2:Number = vertices[6]*projectionX, y2:Number = vertices[7]*projectionY;
						if (x1 > -camera.viewSizeX + t && x1 < camera.viewSizeX - t && y1 > -camera.viewSizeY + t && y1 < camera.viewSizeY - t) {
							canvas.gfx.beginFill(0xFFFF00);
							canvas.gfx.drawCircle(x1, y1, 2);
						}
						if (x1 > -camera.viewSizeX + t && x1 < camera.viewSizeX - t && y2 > -camera.viewSizeY + t && y2 < camera.viewSizeY - t) {
							canvas.gfx.beginFill(0xFFFF00);
							canvas.gfx.drawCircle(x1, y2, 2);
						}
						if (x2 > -camera.viewSizeX + t && x2 < camera.viewSizeX - t && y2 > -camera.viewSizeY + t && y2 < camera.viewSizeY - t) {
							canvas.gfx.beginFill(0xFFFF00);
							canvas.gfx.drawCircle(x2, y2, 2);
						}
						if (x2 > -camera.viewSizeX + t && x2 < camera.viewSizeX - t && y1 > -camera.viewSizeY + t && y1 < camera.viewSizeY - t) {
							canvas.gfx.beginFill(0xFFFF00);
							canvas.gfx.drawCircle(x2, y1, 2);
						}
					} else {
						for (i = 0; i < length; i++) {
							x = vertices[i++]*projectionX, y = vertices[i++]*projectionY;
							if (x > -camera.viewSizeX + t && x < camera.viewSizeX - t && y > -camera.viewSizeY + t && y < camera.viewSizeY - t) {
								canvas.gfx.beginFill(0xFFFF00);
								canvas.gfx.drawCircle(x, y, 2);
							}
						}
					}
				}
			}
			// Оси, центры, имена, баунды
			if (debugResult & Debug.AXES) object.drawAxes(camera, canvas);
			if (debugResult & Debug.CENTERS) object.drawCenter(camera, canvas);
			if (debugResult & Debug.NAMES) object.drawName(camera, canvas);
			if (debugResult & Debug.BOUNDS) object.drawBoundBox(camera, canvas);
		}
		
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			var verticesLength:int = calculateVertices(object, camera);
			if (verticesLength > 0) {
				var geometry:Geometry = Geometry.create();
				geometry.fragment = Fragment.create();
				geometry.numVertices = verticesLength/3;
				geometry.fragment.num = geometry.numVertices;
				geometry.verticesLength = verticesLength;
				if (geometry.uvts.length < verticesLength) {
					geometry.uvts.length = verticesLength;
				}
				for (var i:int = 0, j:int = 0; i < geometry.numVertices; i++) {
					geometry.vertices[j] = vertices[j]; j++;
					geometry.vertices[j] = vertices[j]; j++;
					geometry.vertices[j] = vertices[j]; j++;
					geometry.fragment.indices[i] = i;
				}
				geometry.cameraMatrix.identity();
				geometry.cameraMatrix.prepend(object.cameraMatrix);
				geometry.alpha = object.alpha;
				geometry.blendMode = object.blendMode;
				geometry.colorTransform = object.colorTransform;
				geometry.filters = object.filters;
				geometry.sorting = sorting;
				geometry.texture = drawTexture;
				geometry.repeatTexture = false;
				geometry.smooth = smooth;
				if (camera.debugMode) {
					geometry.debugResult = camera.checkInDebug(this);
				}
				geometry.viewAligned = true;
				geometry.textureMatrix.a = textureMatrix.a;
				geometry.textureMatrix.b = textureMatrix.b;
				geometry.textureMatrix.c = textureMatrix.c;
				geometry.textureMatrix.d = textureMatrix.d;
				geometry.textureMatrix.tx = textureMatrix.tx;
				geometry.textureMatrix.ty = textureMatrix.ty;
				geometry.projectionX = projectionX;
				geometry.projectionY = projectionY;
				return geometry;
			} else {
				return null;
			}
		}
		
		private function calculateVertices(object:Object3D, camera:Camera3D):int {
			// Трансформация локальных осей в камеру
			object.cameraMatrix.transformVectors(axes, cameraAxes);
			var x:Number = cameraAxes[0];
			var y:Number = cameraAxes[1];
			var z:Number = cameraAxes[2];
			if (z <= camera.nearClipping || z >= camera.farClipping) return 0;
			// Проекция
			projectionX = camera.viewSizeX/z;
			projectionY = camera.viewSizeY/z;
			var projectionZ:Number = camera.focalLength/z;
			// Нахождение среднего размера спрайта
			var ax:Number = (cameraAxes[3] - x)/camera.perspectiveScaleX;
			var ay:Number = (cameraAxes[4] - y)/camera.perspectiveScaleY;
			var az:Number = cameraAxes[5] - z;
			var size:Number = Math.sqrt(ax*ax + ay*ay + az*az); 
			ax = (cameraAxes[6] - x)/camera.perspectiveScaleX;
			ay = (cameraAxes[7] - y)/camera.perspectiveScaleY;
			az = cameraAxes[8] - z;
			size += Math.sqrt(ax*ax + ay*ay + az*az);
			ax = (cameraAxes[9] - x)/camera.perspectiveScaleX;
			ay = (cameraAxes[10] - y)/camera.perspectiveScaleY;
			az = cameraAxes[11] - z;
			size += Math.sqrt(ax*ax + ay*ay + az*az);
			size /= 3;
			// Определение текстуры и коррекция размера
			if (mipMapping == 0) {
				drawTexture = texture;
			} else {
				var level:int = mipMap.getLevel(z/size, camera);
				size *= Math.pow(2, level);
				drawTexture = mipMap.textures[level];
			}
			// Учёт флага масштабирования
			if (!perspectiveScale) {
				size /= projectionZ;
			}
			var x1:Number;
			var y1:Number;
			var x2:Number;
			var y2:Number;
			// Если не задано вращение
			if (rotation == 0) {
				// Размеры спрайта в матрице камеры
				var cameraWidth:Number = size*drawTexture.width*camera.perspectiveScaleX;
				var cameraHeight:Number = size*drawTexture.height*camera.perspectiveScaleY;
				
				// Расчёт вершин в матрице камеры
				x1 = x - originX*cameraWidth;
				y1 = y - originY*cameraHeight;
				x2 = x1 + cameraWidth;
				y2 = y1 + cameraHeight;

				// Отсечение по вьюпорту
				if (object.culling > 0 && (x1 > z || y1 > z || x2 < -z || y2 < -z)) return 0; 
				
				// Подготовка матрицы отрисовки
				textureMatrix.a = textureMatrix.d = size*projectionZ;
				textureMatrix.b = textureMatrix.c = 0;
				textureMatrix.tx = x1*projectionX;
				textureMatrix.ty = y1*projectionY;
				
				// Подрезка
				if (clipping == 2) {
					if (x1 < -z) x1 = -z;
					if (y1 < -z) y1 = -z;
					if (x2 > z) x2 = z;
					if (y2 > z) y2 = z;
				}

				// Заполняем вершины
				vertices[0] = x1;
				vertices[1] = y1;
				vertices[2] = z;
				vertices[3] = x1;
				vertices[4] = y2;
				vertices[5] = z;
				vertices[6] = x2;
				vertices[7] = y2;
				vertices[8] = z;
				vertices[9] = x2;
				vertices[10] = y1;
				vertices[11] = z;
				
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
				vertices[0] = x1 = x - originX*cameraWidthX - originY*cameraHeightX;
				vertices[1] = y1 = y - originX*cameraWidthY - originY*cameraHeightY;
				vertices[2] = z;
				vertices[3] = x1 + cameraHeightX;
				vertices[4] = y1 + cameraHeightY;
				vertices[5] = z;
				vertices[6] = x1 + cameraWidthX + cameraHeightX;
				vertices[7] = y1 + cameraWidthY + cameraHeightY;
				vertices[8] = z;
				vertices[9] = x1 + cameraWidthX;
				vertices[10] = y1 + cameraWidthY;
				vertices[11] = z;
				
				if (object.culling > 0) {
					// Отсечение по вьюпорту
					var i:int, infront:Boolean, behind:Boolean, inside:Boolean;
					var clipLeft:Boolean = false;
					if (object.culling & 4) {
						for (i = 0; i < length; i += 3) if ((inside = -vertices[i] < z) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) return 0; else clipLeft = true;
						infront = false; behind = false;
					}	
					var clipRight:Boolean = false;
					if (object.culling & 8) {
						for (i = 0; i < length; i += 3) if ((inside = vertices[i] < z) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) return 0; else clipRight = true;
						infront = false; behind = false;
					}	
					var clipTop:Boolean = false;
					if (object.culling & 16) {
						for (i = 1; i < length; i += 3) if ((inside = -vertices[i] < z) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) return 0; else clipTop = true;
						infront = false; behind = false;
					}	
					var clipBottom:Boolean = false;
					if (object.culling & 32) {
						for (i = 1; i < length; i += 3) if ((inside = vertices[i] < z) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) return 0; else clipBottom = true;
					}
					// Подрезка
					if (clipping == 2) {
						var n:int = 0, t:Number, bx:Number, by:Number;
						if (clipLeft) {
							ax = x = vertices[0]; ay = y = vertices[1];
							for (i = 3; i <= length; i++) {
								if (i < length) {
									bx = vertices[i++]; by = vertices[i++];
								} else {
									bx = x; by = y;
								}
								if (-bx < z && -ax >= z || -bx >= z && -ax < z) {
									t = (ax + z)/(ax - bx);
									vertices[n++] = ax + (bx - ax)*t;
									vertices[n++] = ay + (by - ay)*t;
									vertices[n++] = z;
								}
								if (-bx < z) {
									vertices[n++] = bx; vertices[n++] = by; vertices[n++] = z;
								}
								ax = bx; ay = by;
							}
							if (n == 0) return 0;
							length = n; n = 0;
						}
						if (clipRight) {
							ax = x = vertices[0]; ay = y = vertices[1];
							for (i = 3; i <= length; i++) {
								if (i < length) {
									bx = vertices[i++]; by = vertices[i++];
								} else {
									bx = x; by = y;
								}
								if (bx < z && ax >= z || bx >= z && ax < z) {
									t = (z - ax)/(bx - ax);
									vertices[n++] = ax + (bx - ax)*t;
									vertices[n++] = ay + (by - ay)*t;
									vertices[n++] = z;
								}
								if (bx < z) {
									vertices[n++] = bx; vertices[n++] = by; vertices[n++] = z;
								}
								ax = bx; ay = by;
							}
							if (n == 0) return 0;
							length = n; n = 0;
						}
						if (clipTop) {
							ax = x = vertices[0]; ay = y = vertices[1];
							for (i = 3; i <= length; i++) {
								if (i < length) {
									bx = vertices[i++]; by = vertices[i++];
								} else {
									bx = x; by = y;
								}
								if (-by < z && -ay >= z || -by >= z && -ay < z) {
									t = (ay + z)/(ay - by);
									vertices[n++] = ax + (bx - ax)*t;
									vertices[n++] = ay + (by - ay)*t;
									vertices[n++] = z;
								}
								if (-by < z) {
									vertices[n++] = bx; vertices[n++] = by; vertices[n++] = z;
								}
								ax = bx; ay = by;
							}
							if (n == 0) return 0;
							length = n; n = 0;
						}
						if (clipBottom) {
							ax = x = vertices[0]; ay = y = vertices[1];
							for (i = 3; i <= length; i++) {
								if (i < length) {
									bx = vertices[i++]; by = vertices[i++];
								} else {
									bx = x; by = y;
								}
								if (by < z && ay >= z || by >= z && ay < z) {
									t = (z - ay)/(by - ay);
									vertices[n++] = ax + (bx - ax)*t;
									vertices[n++] = ay + (by - ay)*t;
									vertices[n++] = z;
								}
								if (by < z) {
									vertices[n++] = bx; vertices[n++] = by; vertices[n++] = z;
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
