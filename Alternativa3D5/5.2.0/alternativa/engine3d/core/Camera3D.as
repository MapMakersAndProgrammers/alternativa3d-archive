package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.engine3d.display.Skin;
	import alternativa.engine3d.display.View;
	import alternativa.engine3d.materials.DrawPoint;
	import alternativa.engine3d.materials.SurfaceMaterial;
	import alternativa.types.Matrix3D;
	import alternativa.types.Point3D;
	import alternativa.types.Set;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	import alternativa.utils.MathUtils;
	
	use namespace alternativa3d;
	
	/**
	 * Камера для отображения 3D-сцены на экране.
	 * 
	 * <p> Направление камеры совпадает с её локальной осью Z, поэтому только что созданная камера смотрит вверх в системе
	 * координат родителя.
	 * 
	 * <p> Для отображения видимой через камеру части сцены на экран, к камере должна быть подключёна область вывода &mdash;
	 * экземпляр класса <code>alternativa.engine3d.display.View</code>. 
	 * 
	 * @see alternativa.engine3d.display.View
	 */
	public class Camera3D extends Object3D {

		/**
		 * @private
		 * Расчёт матрицы пространства камеры
		 */
		alternativa3d var calculateMatrixOperation:Operation = new Operation("calculateMatrix", this, calculateMatrix, Operation.CAMERA_CALCULATE_MATRIX);
		/**
		 * @private
		 * Расчёт плоскостей отсечения
		 */		
		alternativa3d var calculatePlanesOperation:Operation = new Operation("calculatePlanes", this, calculatePlanes, Operation.CAMERA_CALCULATE_PLANES);
		/**
		 * @private
		 * Отрисовка
		 */		
		alternativa3d var renderOperation:Operation = new Operation("render", this, render, Operation.CAMERA_RENDER);

		// Инкремент количества объектов
		private static var counter:uint = 0;
		
		/**
		 * @private
		 * Поле зрения
		 */
		alternativa3d var _fov:Number = Math.PI/2;
		/**
		 * @private
		 * Фокусное расстояние
		 */
		alternativa3d var focalLength:Number;
		/**
		 * @private
		 * Перспективное искажение
		 */
		alternativa3d var focalDistortion:Number;

		/**
		 * @private
		 * Флаги рассчитанности UV-матриц
		 */
		alternativa3d var uvMatricesCalculated:Set = new Set(true);
		
		// Всмомогательные точки для расчёта UV-матриц
		private var textureA:Point3D = new Point3D();
		private var textureB:Point3D = new Point3D();
		private var textureC:Point3D = new Point3D();
		
		/**
		 * @private
		 * Вид из камеры
		 */
		alternativa3d var _view:View;
		
		/**
		 * @private
		 * Режим отрисовки
		 */
		alternativa3d var _orthographic:Boolean = false;
		private var fullDraw:Boolean;
		
		// Масштаб
		private var _zoom:Number = 1;
		
		// Синус половинчатого угла обзора камеры
		private var viewAngle:Number;
		
		// Направление камеры
		private var direction:Point3D = new Point3D(0, 0, 1);
		
		// Обратная трансформация камеры
		private var cameraMatrix:Matrix3D = new Matrix3D();

		// Скины
		private var firstSkin:Skin;
		private var prevSkin:Skin;
		private var currentSkin:Skin;
		
		// Плоскости отсечения
		private var leftPlane:Point3D = new Point3D();
		private var rightPlane:Point3D = new Point3D();
		private var topPlane:Point3D = new Point3D();
		private var bottomPlane:Point3D = new Point3D();
		private var leftOffset:Number;
		private var rightOffset:Number;
		private var topOffset:Number;
		private var bottomOffset:Number;
		
		// Вспомогательные массивы точек для отрисовки
		private var points1:Array = new Array();
		private var points2:Array = new Array();
		
		/**
		 * Создание нового экземпляра камеры.
		 * 
		 * @param name имя экземпляра
		 */
		public function Camera3D(name:String = null) {
			super(name);
		}
		
		/**
		 * @private
		 */
		private function calculateMatrix():void {
			// Расчёт матрицы пространства камеры
			cameraMatrix.copy(transformation);
			cameraMatrix.invert();
			if (_orthographic) {
				cameraMatrix.scale(_zoom, _zoom, _zoom);
			}
			// Направление камеры
			direction.x = transformation.c;
			direction.y = transformation.g;
			direction.z = transformation.k;
			direction.normalize();
		}
		
		/**
		 * @private
		 * Расчёт плоскостей отсечения
		 */
		private function calculatePlanes():void {
			var halfWidth:Number = _view._width*0.5;
			var halfHeight:Number = _view._height*0.5;
			
			var aw:Number = transformation.a*halfWidth;
			var ew:Number = transformation.e*halfWidth;
			var iw:Number = transformation.i*halfWidth;
			var bh:Number = transformation.b*halfHeight;
			var fh:Number = transformation.f*halfHeight;
			var jh:Number = transformation.j*halfHeight;
			if (_orthographic) {
				// Расчёт плоскостей отсечения в изометрии
				aw /= _zoom;
				ew /= _zoom;
				iw /= _zoom;
				bh /= _zoom;
				fh /= _zoom;
				jh /= _zoom;
				
				// Левая плоскость
				leftPlane.x = transformation.f*transformation.k - transformation.j*transformation.g;
				leftPlane.y = transformation.j*transformation.c - transformation.b*transformation.k;
				leftPlane.z = transformation.b*transformation.g - transformation.f*transformation.c;
				leftOffset = (transformation.d - aw)*leftPlane.x + (transformation.h - ew)*leftPlane.y + (transformation.l - iw)*leftPlane.z;
				
				// Правая плоскость
				rightPlane.x = -leftPlane.x;
				rightPlane.y = -leftPlane.y;
				rightPlane.z = -leftPlane.z;
				rightOffset = (transformation.d + aw)*rightPlane.x + (transformation.h + ew)*rightPlane.y + (transformation.l + iw)*rightPlane.z;
				
				// Верхняя плоскость
				topPlane.x = transformation.g*transformation.i - transformation.k*transformation.e;
				topPlane.y = transformation.k*transformation.a - transformation.c*transformation.i;
				topPlane.z = transformation.c*transformation.e - transformation.g*transformation.a;
				topOffset = (transformation.d - bh)*topPlane.x + (transformation.h - fh)*topPlane.y + (transformation.l - jh)*topPlane.z;
				
				// Нижняя плоскость
				bottomPlane.x = -topPlane.x;
				bottomPlane.y = -topPlane.y;
				bottomPlane.z = -topPlane.z;
				bottomOffset = (transformation.d + bh)*bottomPlane.x + (transformation.h + fh)*bottomPlane.y + (transformation.l + jh)*bottomPlane.z;
			} else {
				// Вычисляем расстояние фокуса
				focalLength = Math.sqrt(_view._width*_view._width + _view._height*_view._height)*0.5/Math.tan(0.5*_fov);
				// Вычисляем минимальное (однопиксельное) искажение перспективной коррекции
				focalDistortion = 1/(focalLength*focalLength);
				
				// Расчёт плоскостей отсечения в перспективе
				var cl:Number = transformation.c*focalLength;
				var gl:Number = transformation.g*focalLength;
				var kl:Number = transformation.k*focalLength;
				
				// Угловые вектора пирамиды видимости
				var leftTopX:Number = -aw - bh + cl;
				var leftTopY:Number = -ew - fh + gl;
				var leftTopZ:Number = -iw - jh + kl;
				var rightTopX:Number = aw - bh + cl;
				var rightTopY:Number = ew - fh + gl;
				var rightTopZ:Number = iw - jh + kl;
				var leftBottomX:Number = -aw + bh + cl;
				var leftBottomY:Number = -ew + fh + gl;
				var leftBottomZ:Number = -iw + jh + kl;
				var rightBottomX:Number = aw + bh + cl;
				var rightBottomY:Number = ew + fh + gl;
				var rightBottomZ:Number = iw + jh + kl;
				
				// Левая плоскость
				leftPlane.x = leftBottomY*leftTopZ - leftBottomZ*leftTopY;
				leftPlane.y = leftBottomZ*leftTopX - leftBottomX*leftTopZ;
				leftPlane.z = leftBottomX*leftTopY - leftBottomY*leftTopX;
				leftOffset = transformation.d*leftPlane.x + transformation.h*leftPlane.y + transformation.l*leftPlane.z;

				// Правая плоскость
				rightPlane.x = rightTopY*rightBottomZ - rightTopZ*rightBottomY;
				rightPlane.y = rightTopZ*rightBottomX - rightTopX*rightBottomZ;
				rightPlane.z = rightTopX*rightBottomY - rightTopY*rightBottomX;
				rightOffset = transformation.d*rightPlane.x + transformation.h*rightPlane.y + transformation.l*rightPlane.z;

				// Верхняя плоскость
				topPlane.x = leftTopY*rightTopZ - leftTopZ*rightTopY;
				topPlane.y = leftTopZ*rightTopX - leftTopX*rightTopZ;
				topPlane.z = leftTopX*rightTopY - leftTopY*rightTopX;
				topOffset = transformation.d*topPlane.x + transformation.h*topPlane.y + transformation.l*topPlane.z;

				// Нижняя плоскость
				bottomPlane.x = rightBottomY*leftBottomZ - rightBottomZ*leftBottomY;
				bottomPlane.y = rightBottomZ*leftBottomX - rightBottomX*leftBottomZ;
				bottomPlane.z = rightBottomX*leftBottomY - rightBottomY*leftBottomX;
				bottomOffset = transformation.d*bottomPlane.x + transformation.h*bottomPlane.y + transformation.l*bottomPlane.z;
				
				
				// Расчёт угла конуса
				var length:Number = Math.sqrt(leftTopX*leftTopX + leftTopY*leftTopY + leftTopZ*leftTopZ);
				leftTopX /= length;
				leftTopY /= length;
				leftTopZ /= length;
				length = Math.sqrt(rightTopX*rightTopX + rightTopY*rightTopY + rightTopZ*rightTopZ);
				rightTopX /= length;
				rightTopY /= length;
				rightTopZ /= length;
				length = Math.sqrt(leftBottomX*leftBottomX + leftBottomY*leftBottomY + leftBottomZ*leftBottomZ);
				leftBottomX /= length;
				leftBottomY /= length;
				leftBottomZ /= length;
				length = Math.sqrt(rightBottomX*rightBottomX + rightBottomY*rightBottomY + rightBottomZ*rightBottomZ);
				rightBottomX /= length;
				rightBottomY /= length;
				rightBottomZ /= length;

				viewAngle = leftTopX*direction.x + leftTopY*direction.y + leftTopZ*direction.z;
				var dot:Number = rightTopX*direction.x + rightTopY*direction.y + rightTopZ*direction.z;
				viewAngle = (dot < viewAngle) ? dot : viewAngle;
				dot = leftBottomX*direction.x + leftBottomY*direction.y + leftBottomZ*direction.z;
				viewAngle = (dot < viewAngle) ? dot : viewAngle;
				dot = rightBottomX*direction.x + rightBottomY*direction.y + rightBottomZ*direction.z;
				viewAngle = (dot < viewAngle) ? dot : viewAngle;
				
				viewAngle = Math.sin(Math.acos(viewAngle));
			}
		}
			
		/**
		 * @private
		 */
		private function render():void {
			// Режим отрисовки
			fullDraw = (calculateMatrixOperation.queued || calculatePlanesOperation.queued);

			// Очистка рассчитанных текстурных матриц
			uvMatricesCalculated.clear();
			
			// Отрисовка
			prevSkin = null;
			currentSkin = firstSkin;
			renderBSPNode(_scene.bsp);

			// Удаление ненужных скинов
			while (currentSkin != null) {
 				removeCurrentSkin();
	 		}
		}

		/**
		 * @private
		 */
		private function renderBSPNode(node:BSPNode):void {
			if (node != null) {
				var primitive:*;
				var normal:Point3D = node.normal;
				var cameraAngle:Number = direction.x*normal.x + direction.y*normal.y + direction.z*normal.z;
				var cameraOffset:Number;
				if (!_orthographic) {
					 cameraOffset = globalCoords.x*normal.x + globalCoords.y*normal.y + globalCoords.z*normal.z - node.offset;
				}
				if (node.primitive != null) {
					// В ноде только базовый примитив
					if (_orthographic ? (cameraAngle < 0) : (cameraOffset > 0)) {
						// Камера спереди ноды
						if (_orthographic || cameraAngle < viewAngle) {
							renderBSPNode(node.back);
							drawSkin(node.primitive);
						}
						renderBSPNode(node.front);
					} else {
						// Камера сзади ноды
						if (_orthographic || cameraAngle > -viewAngle) {
							renderBSPNode(node.front);
						}
						renderBSPNode(node.back);
					}
				} else {
					// В ноде несколько примитивов
					if (_orthographic ? (cameraAngle < 0) : (cameraOffset > 0)) {
						// Камера спереди ноды
						if (_orthographic || cameraAngle < viewAngle) {
							renderBSPNode(node.back);
							for (primitive in node.frontPrimitives) {
								drawSkin(primitive);
							}
						}
						renderBSPNode(node.front);
					} else {
						// Камера сзади ноды
						if (_orthographic || cameraAngle > -viewAngle) {
							renderBSPNode(node.front);
							for (primitive in node.backPrimitives) {
								drawSkin(primitive);
							}
						}
						renderBSPNode(node.back);
					}
				}
			}
		}

		/**
		 * @private
		 * Отрисовка скина примитива
		 */
 		private function drawSkin(primitive:PolyPrimitive):void {
 			if (!fullDraw && currentSkin != null && currentSkin.primitive == primitive && !_scene.changedPrimitives[primitive]) {
	 			// Пропуск скина
				prevSkin = currentSkin;
				currentSkin = currentSkin.nextSkin;
			} else {
	 			// Проверка поверхности 
	 			var surface:Surface = primitive.face._surface;
	 			if (surface == null) {
	 				return;
	 			}
	 			// Проверка материала
	 			var material:SurfaceMaterial = surface._material;
 				if (material == null || !material.canDraw(primitive)) {
 					return;
 				}
 				// Отсечение выходящих за окно просмотра частей
 				var i:uint;
 				var length:uint = primitive.num;
 				var primitivePoint:Point3D;
 				var primitiveUV:Point;
 				var point:DrawPoint;
 				var useUV:Boolean = !_orthographic && material.useUV; 
 				if (useUV) {
 					// Формируем список точек и UV-координат полигона
					for (i = 0; i < length; i++) {
						primitivePoint = primitive.points[i];
						primitiveUV = primitive.uvs[i];
						point = points1[i];
						if (point == null) {
							points1[i] = new DrawPoint(primitivePoint.x, primitivePoint.y, primitivePoint.z, primitiveUV.x, primitiveUV.y);
						} else {
							point.x = primitivePoint.x;
							point.y = primitivePoint.y;
							point.z = primitivePoint.z;
							point.u = primitiveUV.x;
							point.v = primitiveUV.y;
						}
	 				}
 				} else {
	 				// Формируем список точек полигона
					for (i = 0; i < length; i++) {	
						primitivePoint = primitive.points[i];
						point = points1[i];
						if (point == null) {
							points1[i] = new DrawPoint(primitivePoint.x, primitivePoint.y, primitivePoint.z);
						} else {
							point.x = primitivePoint.x;
							point.y = primitivePoint.y;
							point.z = primitivePoint.z;
						}
	 				}
	 			}
 				// Отсечение по левой стороне
 				length = clip(length, points1, points2, leftPlane, leftOffset, useUV);
 				if (length < 3) {
 					return;
 				}
 				// Отсечение по правой стороне
 				length = clip(length, points2, points1, rightPlane, rightOffset, useUV);
 				if (length < 3) {
 					return;
 				}
 				// Отсечение по верхней стороне
 				length = clip(length, points1, points2, topPlane, topOffset, useUV);
 				if (length < 3) {
 					return;
 				}
 				// Отсечение по нижней стороне
 				length = clip(length, points2, points1, bottomPlane, bottomOffset, useUV);
 				if (length < 3) {
 					return;
 				}
	 					
 				if (fullDraw || _scene.changedPrimitives[primitive]) {

					// Если конец списка скинов
 					if (currentSkin == null) {
						// Добавляем скин в конец 
 						addCurrentSkin();
 					} else {
 						if (fullDraw || _scene.changedPrimitives[currentSkin.primitive]) {
							// Очистка скина
							currentSkin.material.clear(currentSkin);
	 					} else {
							// Вставка скина перед текущим
	 						insertCurrentSkin();
	 					}
 					}
 					
 					// Переводим координаты в систему камеры
 					var x:Number;
	 				var y:Number;
	 				var z:Number;
 					for (i = 0; i < length; i++) {
 						point = points1[i];
 						x = point.x;
 						y = point.y;
 						z = point.z;
 						point.x = cameraMatrix.a*x + cameraMatrix.b*y + cameraMatrix.c*z + cameraMatrix.d;
						point.y = cameraMatrix.e*x + cameraMatrix.f*y + cameraMatrix.g*z + cameraMatrix.h;
						point.z = cameraMatrix.i*x + cameraMatrix.j*y + cameraMatrix.k*z + cameraMatrix.l;
 					}
 					
					// Назначаем скину примитив и материал
					currentSkin.primitive = primitive;
					currentSkin.material = material;
					material.draw(this, currentSkin, length, points1);
					
		 			// Переключаемся на следующий скин
		 			prevSkin = currentSkin;
		 			currentSkin = currentSkin.nextSkin;
 					
 				} else {
 					
					// Удаление ненужных скинов
					while (currentSkin != null && _scene.changedPrimitives[currentSkin.primitive]) {
		 				removeCurrentSkin();
		 			}
	
		 			// Переключение на следующий скин
		 			if (currentSkin != null) {
			 			prevSkin = currentSkin;
		 				currentSkin = currentSkin.nextSkin;
		 			}
 					
 				}
 			}
 		}
 		
		/**
		 * @private
		 * Отсечение полигона плоскостью.
		 */
		private function clip(length:uint, points1:Array, points2:Array, plane:Point3D, offset:Number, calculateUV:Boolean):uint {
			var i:uint;
			var k:Number;
			var index:uint = 0;
			var point:DrawPoint;
			var point1:DrawPoint;
			var point2:DrawPoint;
			var offset1:Number;
			var offset2:Number;
			
			point1 = points1[length - 1];
			offset1 = plane.x*point1.x + plane.y*point1.y + plane.z*point1.z - offset;
			
			if (calculateUV) {

				for (i = 0; i < length; i++) {
	
					point2 = points1[i];
					offset2 = plane.x*point2.x + plane.y*point2.y + plane.z*point2.z - offset;
					
					if (offset2 > 0) {
						if (offset1 <= 0) {
							k = offset2/(offset2 - offset1);
							point = points2[index];
							if (point == null) {
								point = new DrawPoint(point2.x - (point2.x - point1.x)*k, point2.y - (point2.y - point1.y)*k, point2.z - (point2.z - point1.z)*k, point2.u - (point2.u - point1.u)*k, point2.v - (point2.v - point1.v)*k);
								points2[index] = point;
							} else {
								point.x = point2.x - (point2.x - point1.x)*k;
								point.y = point2.y - (point2.y - point1.y)*k;
								point.z = point2.z - (point2.z - point1.z)*k;
								point.u = point2.u - (point2.u - point1.u)*k;
								point.v = point2.v - (point2.v - point1.v)*k;
							}
							index++;
						}
						point = points2[index];
						if (point == null) {
							point = new DrawPoint(point2.x, point2.y, point2.z, point2.u, point2.v);
							points2[index] = point;
						} else {
							point.x = point2.x;
							point.y = point2.y;
							point.z = point2.z;
							point.u = point2.u;
							point.v = point2.v;
						}
						index++;
					} else {
						if (offset1 > 0) {
							k = offset2/(offset2 - offset1);
							point = points2[index];
							if (point == null) {
								point = new DrawPoint(point2.x - (point2.x - point1.x)*k, point2.y - (point2.y - point1.y)*k, point2.z - (point2.z - point1.z)*k, point2.u - (point2.u - point1.u)*k, point2.v - (point2.v - point1.v)*k);
								points2[index] = point;
							} else {
								point.x = point2.x - (point2.x - point1.x)*k;
								point.y = point2.y - (point2.y - point1.y)*k;
								point.z = point2.z - (point2.z - point1.z)*k;
								point.u = point2.u - (point2.u - point1.u)*k;
								point.v = point2.v - (point2.v - point1.v)*k;
							}
							index++;
						}
					}
					offset1 = offset2;
					point1 = point2;
				}
				
			} else {
	
				for (i = 0; i < length; i++) {
	
					point2 = points1[i];
					offset2 = plane.x*point2.x + plane.y*point2.y + plane.z*point2.z - offset;
					
					if (offset2 > 0) {
						if (offset1 <= 0) {
							k = offset2/(offset2 - offset1);
							point = points2[index];
							if (point == null) {
								point = new DrawPoint(point2.x - (point2.x - point1.x)*k, point2.y - (point2.y - point1.y)*k, point2.z - (point2.z - point1.z)*k);
								points2[index] = point;
							} else {
								point.x = point2.x - (point2.x - point1.x)*k;
								point.y = point2.y - (point2.y - point1.y)*k;
								point.z = point2.z - (point2.z - point1.z)*k;
							}
							index++;
						}
						point = points2[index];
						if (point == null) {
							point = new DrawPoint(point2.x, point2.y, point2.z);
							points2[index] = point;
						} else {
							point.x = point2.x;
							point.y = point2.y;
							point.z = point2.z;
						}
						index++;
					} else {
						if (offset1 > 0) {
							k = offset2/(offset2 - offset1);
							point = points2[index];
							if (point == null) {
								point = new DrawPoint(point2.x - (point2.x - point1.x)*k, point2.y - (point2.y - point1.y)*k, point2.z - (point2.z - point1.z)*k);
								points2[index] = point;
							} else {
								point.x = point2.x - (point2.x - point1.x)*k;
								point.y = point2.y - (point2.y - point1.y)*k;
								point.z = point2.z - (point2.z - point1.z)*k;
							}
							index++;
						}
					}
					offset1 = offset2;
					point1 = point2;
				}
			}
			return index;
		}

		/**
		 * @private
		 * Добавление текущего скина.
		 */
		private function addCurrentSkin():void {
 			currentSkin = Skin.createSkin();
 			_view.canvas.addChild(currentSkin);
 			if (prevSkin == null) {
 				firstSkin = currentSkin;
 			} else {
 				prevSkin.nextSkin = currentSkin;
 			}
		}
		
		/**
		 * @private
		 * Вставляем под текущий скин.
		 */
		private function insertCurrentSkin():void {
			var skin:Skin = Skin.createSkin();
 			_view.canvas.addChildAt(skin, _view.canvas.getChildIndex(currentSkin));
 			skin.nextSkin = currentSkin;
 			if (prevSkin == null) {
 				firstSkin = skin;
 			} else {
 				prevSkin.nextSkin = skin;
 			}
 			currentSkin = skin;
		}
		
		/**
		 * @private
		 * Удаляет текущий скин.
		 */
		private function removeCurrentSkin():void {
			// Сохраняем следующий
			var next:Skin = currentSkin.nextSkin;
			// Удаляем из канваса
			_view.canvas.removeChild(currentSkin);
			// Очистка скина
			if (currentSkin.material != null) {
				currentSkin.material.clear(currentSkin);
			}
			// Зачищаем ссылки
			currentSkin.nextSkin = null;
			currentSkin.primitive = null;
			currentSkin.material = null;
			// Удаляем
			Skin.destroySkin(currentSkin);
			// Следующий устанавливаем текущим
			currentSkin = next;
			// Устанавливаем связь от предыдущего скина
			if (prevSkin == null) {
		 		firstSkin = currentSkin;
		 	} else {
		 		prevSkin.nextSkin = currentSkin;
			}
		}
		
		/**
		 * @private
		 */		
		alternativa3d function calculateUVMatrix(face:Face, width:uint, height:uint):void {

			// Расчёт точек базового примитива в координатах камеры
			var point:Point3D = face.primitive.points[0];
			textureA.x = cameraMatrix.a*point.x + cameraMatrix.b*point.y + cameraMatrix.c*point.z;
			textureA.y = cameraMatrix.e*point.x + cameraMatrix.f*point.y + cameraMatrix.g*point.z;
			point = face.primitive.points[1];
			textureB.x = cameraMatrix.a*point.x + cameraMatrix.b*point.y + cameraMatrix.c*point.z;
			textureB.y = cameraMatrix.e*point.x + cameraMatrix.f*point.y + cameraMatrix.g*point.z;
			point = face.primitive.points[2];
			textureC.x = cameraMatrix.a*point.x + cameraMatrix.b*point.y + cameraMatrix.c*point.z;
			textureC.y = cameraMatrix.e*point.x + cameraMatrix.f*point.y + cameraMatrix.g*point.z;
			
			// Находим AB и AC
			var abx:Number = textureB.x - textureA.x;
			var aby:Number = textureB.y - textureA.y;
			var acx:Number = textureC.x - textureA.x;
			var acy:Number = textureC.y - textureA.y;

			// Расчёт текстурной матрицы
			var uvMatrixBase:Matrix = face.uvMatrixBase;
			var uvMatrix:Matrix = face.uvMatrix;
			uvMatrix.a = (uvMatrixBase.a*abx + uvMatrixBase.b*acx)/width;
			uvMatrix.b = (uvMatrixBase.a*aby + uvMatrixBase.b*acy)/width;
			uvMatrix.c = -(uvMatrixBase.c*abx + uvMatrixBase.d*acx)/height;
			uvMatrix.d = -(uvMatrixBase.c*aby + uvMatrixBase.d*acy)/height;
			uvMatrix.tx = (uvMatrixBase.tx + uvMatrixBase.c)*abx + (uvMatrixBase.ty + uvMatrixBase.d)*acx + textureA.x + cameraMatrix.d;
			uvMatrix.ty = (uvMatrixBase.tx + uvMatrixBase.c)*aby + (uvMatrixBase.ty + uvMatrixBase.d)*acy + textureA.y + cameraMatrix.h;
			
			// Помечаем, как рассчитанную
			uvMatricesCalculated[face] = true;
		}
		
		/**
		 * Поле вывода, в котором происходит отрисовка камеры.
		 */
		public function get view():View {
			return _view;
		}

		/**
		 * @private
		 */
		public function set view(value:View):void {
			if (value != _view) {
				if (_view != null) {
					_view.camera = null;
				}
				if (value != null) {
					value.camera = this;
				}
			}
		}
		
		/**
		 * Включение режима аксонометрической проекции.
		 * 
		 * @default false
		 */		
		public function get orthographic():Boolean {
			return _orthographic;
		}
		
		/**
		 * @private
		 */		
		public function set orthographic(value:Boolean):void {
			if (_orthographic != value) {
				// Отправляем сигнал об изменении типа камеры
				addOperationToScene(calculateMatrixOperation);
				// Сохраняем новое значение
				_orthographic = value;
			}
		}
		
		/**
		 * Угол поля зрения в радианах в режиме перспективной проекции. При изменении FOV изменяется фокусное расстояние
		 * камеры по формуле <code>f = d/tan(fov/2)</code>, где <code>d</code> является половиной диагонали поля вывода.
		 * Угол зрения ограничен диапазоном 0-180 градусов.
		 */
		public function get fov():Number {
			return _fov;
		}
		
		/**
		 * @private
		 */
		public function set fov(value:Number):void {
			value = (value < 0) ? 0 : ((value > (Math.PI - 0.0001)) ? (Math.PI - 0.0001) : value);
			if (_fov != value) {
				// Если перспектива
				if (!_orthographic) {
					// Отправляем сигнал об изменении плоскостей отсечения
					addOperationToScene(calculatePlanesOperation);
				}
				// Сохраняем новое значение
				_fov = value;
			}
		}

		/**
		 * Коэффициент увеличения изображения в режиме аксонометрической проекции.
		 */
		public function get zoom():Number {
			return _zoom;
		}		

		/**
		 * @private
		 */
		public function set zoom(value:Number):void {
			value = (value < 0) ? 0 : value;
			if (_zoom != value) {
				// Если изометрия
				if (_orthographic) {
					// Отправляем сигнал об изменении zoom
					addOperationToScene(calculateMatrixOperation);
				}
				// Сохраняем новое значение
				_zoom = value;
			}
		}

		/**
		 * @inheritDoc
		 */
		override protected function addToScene(scene:Scene3D):void {
			super.addToScene(scene);
			if (_view != null) {
				// Отправляем операцию расчёта плоскостей отсечения
				scene.addOperation(calculatePlanesOperation);
				// Подписываемся на сигналы сцены
				scene.changePrimitivesOperation.addSequel(renderOperation);
			}
		}

		/**
		 * @inheritDoc
		 */
		override protected function removeFromScene(scene:Scene3D):void {
			super.removeFromScene(scene);
			
			// Удаляем все операции из очереди
			scene.removeOperation(calculateMatrixOperation);
			scene.removeOperation(calculatePlanesOperation);
			scene.removeOperation(renderOperation);
			
			if (_view != null) {
				// Отписываемся от сигналов сцены
				scene.changePrimitivesOperation.removeSequel(renderOperation);
			}
		}

		/**
		 * @private
		 */
		alternativa3d function addToView(view:View):void {
			// Сохраняем первый скин
			firstSkin = (view.canvas.numChildren > 0) ? Skin(view.canvas.getChildAt(0)) : null;
			
			// Подписка на свои операции

			// При изменении камеры пересчёт матрицы
			calculateTransformationOperation.addSequel(calculateMatrixOperation);
			// При изменении матрицы или FOV пересчёт плоскостей отсечения
			calculateMatrixOperation.addSequel(calculatePlanesOperation);
			// При изменении плоскостей перерисовка
			calculatePlanesOperation.addSequel(renderOperation);

			if (_scene != null) {
				// Отправляем сигнал перерисовки
				_scene.addOperation(calculateMatrixOperation);
				// Подписываемся на сигналы сцены
				_scene.changePrimitivesOperation.addSequel(renderOperation);
			}
			
			// Сохраняем вид
			_view = view;
		}

		/**
		 * @private
		 */
		alternativa3d function removeFromView(view:View):void {
			// Сброс ссылки на первый скин
			firstSkin = null;
			
			// Отписка от своих операций

			// При изменении камеры пересчёт матрицы
			calculateTransformationOperation.removeSequel(calculateMatrixOperation);
			// При изменении матрицы или FOV пересчёт плоскостей отсечения
			calculateMatrixOperation.removeSequel(calculatePlanesOperation);
			// При изменении плоскостей перерисовка
			calculatePlanesOperation.removeSequel(renderOperation);
			
			if (_scene != null) {
				// Удаляем все операции из очереди
				_scene.removeOperation(calculateMatrixOperation);
				_scene.removeOperation(calculatePlanesOperation);
				_scene.removeOperation(renderOperation);
				// Отписываемся от сигналов сцены
				_scene.changePrimitivesOperation.removeSequel(renderOperation);
			}
			// Удаляем ссылку на вид
			_view = null;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function defaultName():String {
			return "camera" + ++counter;
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function createEmptyObject():Object3D {
			return new Camera3D();
		}
		
		/**
		 * @inheritDoc
		 */
		protected override function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			
			var src:Camera3D = Camera3D(source);
			orthographic = src._orthographic;
			zoom = src._zoom;
			fov = src._fov;
		}
	}
}