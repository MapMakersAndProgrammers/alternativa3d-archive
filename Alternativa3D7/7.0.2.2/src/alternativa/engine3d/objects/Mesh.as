package alternativa.engine3d.objects {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BSPNode;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.MipMap;
	import alternativa.engine3d.core.Object3D;
	
	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.geom.Utils3D;
	
	use namespace alternativa3d;
	
	/**
	 * Полигональный объект
	 */
	public class Mesh extends Object3D {
		
		static public var debug:Boolean = false;
		
		static public var numDrawingTriangles:int = 0;
		
		/**
		 * Режим представления полигонов. 
		 * Если false, в indices записаны треугольники (тройки индексов).
		 * Если true, в indices записаны многоугольники в виде: количество вершин грани, индексы вершин
		 */
		public var poly:Boolean = false; // Режим полигонов
		
		/**
		 * Количество вершин 
		 */
		public var numVertices:int = 0;
		/**
		 * Количество граней
		 */
		public var numFaces:int = 0;
		/**
		 * Вершины в виде x, y, z 
		 */
		public var vertices:Vector.<Number>;
		/**
		 * Индексы вершин 
		 */
		public var indices:Vector.<int>;
		/**
		 * UV-координаты в виде u, v, t 
		 */
		public var uvts:Vector.<Number>;
		/**
		 * UV-координаты в виде u, v 
		 */
		public var uvs:Vector.<Number>; // Нужен только для отрисовки без перспективной коррекции

		public var texture:BitmapData;
		public var smooth:Boolean = false;
		public var repeatTexture:Boolean = true;
		public var perspectiveCorrection:Boolean = false;
		/**
		 * Режим отсечения объекта по пирамиде видимости камеры.
		 * 0 - весь объект
		 * 1 - по граням
		 * 2 - клиппинг граней по пирамиде видимости камеры 
		 */
		public var clipping:int = 0; // 0 - весь объект, 1 - по граням, 2 - с обрезкой
		/**
		 * Режим отсечения граней по направлению к камере
		 * 0 - отсечение происходит только на этапе отрисовки треугольников внутри drawTriangles
		 * 1 - отсечение по предрасчитанным нормалям. Для расчёта нормалей нужен calculateNormals()
		 * 2 - отсечение по динамически расчитываемым временным нормалям
		 */
		public var backfaceCulling:int = 0; // 0 - нативный, 1 - по предрасчитанным нормалям, 2 - динамический
		/**
		 * Режим сортировки полигонов
		 * 0 - без сортировки
		 * 1 - сортировка по средним Z
		 * 2 - проход по предрасчитанному BSP. Для расчёта BSP нужен calculateBSP()
		 */
		public var sorting:int = 0; // 0 - без сортировки, 1 - Z-сортировка, 2 - BSP
		/**
		 * Применение мипмаппинга
		 * 0 - без мипмаппинга
		 * 1 - мипмаппинг по удалённости от камеры. Требуется установка свойства mipMap
		 */
		public var mipMapping:int = 0; // 0 - без мипмаппинга, 1 - по дальности от центра
		
		public var mipMap:MipMap;
		/**
		 * Нормали в виде: x, y, z, offset 
		 */
		public var normals:Vector.<Number>; // На каждую нормаль - 4 значения, XYZ + offset
		/**
		 * Корневой узел BSP-дерева 
		 */
		public var bsp:BSPNode;
		/**
		 * Геометрическая погрешность при расчёте BSP-дерева 
		 */
		public var threshold:Number = 0.1;
		
		/**
		 * @private 
		 */
		alternativa3d var cameraVertices:Vector.<Number> = new Vector.<Number>();
		/**
		 * @private 
		 */
		alternativa3d var projectedVertices:Vector.<Number> = new Vector.<Number>();
		
		// Вспомогательные вектора
		static private const polygon:Vector.<int> = new Vector.<int>();
		static private const sortingStack:Vector.<int> = new Vector.<int>();
		static private const sortingMap:Vector.<int> = new Vector.<int>();
		static private const sortingAverageZ:Vector.<Number> = new Vector.<Number>();
		static private const indices1:Vector.<int> = new Vector.<int>();
		static private const indices2:Vector.<int> = new Vector.<int>();
		static private const fragments:Vector.<int> = new Vector.<int>();
		static private var fragmentsRealLength:int = 0;
		static private var fragmentsLength:int;
		protected var sourceIndices:Vector.<int>;
		protected var sourceIndicesLength:int;
		protected var resultIndices:Vector.<int>;
		protected var resultIndicesLength:int;
		protected var debugIndices:Vector.<int> = new Vector.<int>();
		protected var debugIndicesLength:int;
		
		public function createEmptyGeometry(numVertices:uint, numFaces:uint):void {
			this.numVertices = numVertices;
			this.numFaces = numFaces;
			vertices = new Vector.<Number>(numVertices*3);
			indices = new Vector.<int>(numFaces*3);
			uvts = new Vector.<Number>(numVertices*3);
			uvs = new Vector.<Number>(numVertices << 1);
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function get canDraw():Boolean {
			return (texture != null || mipMap != null) && numFaces > 0;
		}
		
		static private const inverseCameraMatrix:Matrix3D = new Matrix3D();
		static private const cameraCenter:Vector.<Number> = new Vector.<Number>(3, true);
		/**
		 * @private 
		 */
		alternativa3d var cameraX:Number;
		/**
		 * @private 
		 */
		alternativa3d var cameraY:Number;
		/**
		 * @private 
		 */
		alternativa3d var cameraZ:Number;
		/**
		 * @private 
		 */
		alternativa3d function calculateInverseCameraMatrix(matrix:Matrix3D):void {
			// Определение центра камеры в объекте
			inverseCameraMatrix.identity();
			inverseCameraMatrix.prepend(matrix);
			inverseCameraMatrix.invert();
			cameraCenter[0] = cameraCenter[1] = cameraCenter[2] = 0;
			inverseCameraMatrix.transformVectors(cameraCenter, cameraCenter);
			cameraX = cameraCenter[0], cameraY = cameraCenter[1], cameraZ = cameraCenter[2];
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			//var canvas:Canvas = parentCanvas.getChildCanvas();
			//canvas.clear();
			//object.drawBoundBox(camera, canvas, 0xFF00FF);
			//return;
			
			// Выход по объектному клиппингу
			if (clipping == 0 && (object.culling & 1)) return;
			// Подготовка к отсечению по предрасчитанным нормалям
			if (backfaceCulling == 1 || sorting == 2) calculateInverseCameraMatrix(object.cameraMatrix);
			// Перевод в координаты камеры
			object.cameraMatrix.transformVectors(vertices, cameraVertices);
			// Полная отрисовка
			if (object.culling == 0 || clipping == 0) {
				// Без сортировки
				if (sorting == 0) {
					resultIndices = indices, resultIndicesLength = poly ? indices.length : numFaces*3;
					if (backfaceCulling == 0) {
						if (poly) triangulate();
					} else {
						if (poly) {
							backfaceCullPolygons();
							if (resultIndicesLength > 0) triangulate();
						} else {
							backfaceCullTriangles();
						}
					}
				// Сортировка по средним Z
				} else if (sorting == 1) {
					resultIndices = indices, resultIndicesLength = poly ? indices.length : numFaces*3;
					if (backfaceCulling == 0) {
						if (poly) sortPolygons() else sortTriangles();
					} else {
						if (poly) {
							backfaceCullPolygons();
							if (resultIndicesLength > 0) sortPolygons();
						} else {
							backfaceCullTriangles();
							if (resultIndicesLength > 0) sortTriangles();
						}
					}
				// BSP
				} else {
					resultIndices = indices2, resultIndicesLength = 0;
					collectNode(bsp);
					if (debug) {
						debugIndicesLength = 0;
						debugNode(bsp, object.culling, camera.nearClipping, camera.farClipping);
						sourceIndices = debugIndices, sourceIndicesLength = debugIndicesLength;
					}
				}
				// Отрисовка
				if (resultIndicesLength > 0) {
					Utils3D.projectVectors(camera.projectionMatrix, cameraVertices, projectedVertices, uvts);
					drawGraphics(camera, object, parentCanvas);
				}
			// Куллинг
			} else if (clipping == 1) {
				// Без сортировки
				if (sorting == 0) {
					resultIndices = indices, resultIndicesLength = poly ? indices.length : numFaces*3;
					if (poly) {
						cullPolygons(object.culling, camera.nearClipping, camera.farClipping);
						if (resultIndicesLength > 0) triangulate(); 
					} else {
						cullTriangles(object.culling, camera.nearClipping, camera.farClipping);
					}
				// Сортировка по средним Z
				} else if (sorting == 1) {
					resultIndices = indices, resultIndicesLength = poly ? indices.length : numFaces*3;
					if (poly) {
						cullPolygons(object.culling, camera.nearClipping, camera.farClipping);
						if (resultIndicesLength > 0) sortPolygons();
					} else {
						cullTriangles(object.culling, camera.nearClipping, camera.farClipping);
						if (resultIndicesLength > 0) sortTriangles();
					}
				// BSP
				} else {
					resultIndices = indices2, resultIndicesLength = 0;
					cullNode(bsp, object.culling, camera.nearClipping, camera.farClipping);
					if (debug) {
						var len:int = resultIndicesLength;
						var bfk:int = backfaceCulling;
						backfaceCulling = 0;
						debugIndicesLength = 0;
						debugNode(bsp, object.culling, camera.nearClipping, camera.farClipping);
						resultIndices = debugIndices, resultIndicesLength = debugIndicesLength;
						cullPolygons(object.culling, camera.nearClipping, camera.farClipping);
						sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength;
						resultIndices = indices2, resultIndicesLength = len, backfaceCulling = bfk;
					}
				}
				// Отрисовка
				if (resultIndicesLength > 0) {
					Utils3D.projectVectors(camera.projectionMatrix, cameraVertices, projectedVertices, uvts);
					cropVertices(object.culling, camera);
					drawGraphics(camera, object, parentCanvas);
				}
			// Клиппинг
			} else {
				// Без сортировки
				if (sorting == 0) {
					resultIndices = indices, resultIndicesLength = poly ? indices.length : numFaces*3;
					if (poly) {
						clipPolygons(object.culling, camera.nearClipping, camera.farClipping);
						if (resultIndicesLength > 0) triangulate(); 
					} else {
						clipTriangles(object.culling, camera.nearClipping, camera.farClipping);
					}
				// Сортировка по средним Z
				} else if (sorting == 1) {
					resultIndices = indices, resultIndicesLength = poly ? indices.length : numFaces*3;
					if (poly) {
						clipPolygons(object.culling, camera.nearClipping, camera.farClipping);
						if (resultIndicesLength > 0) sortPolygons();
					} else {
						clipTriangles(object.culling, camera.nearClipping, camera.farClipping);
						if (resultIndicesLength > 0) sortTriangles();
					}
				// BSP
				} else {
					resultIndices = indices2, resultIndicesLength = 0;
					var v:int = clipNode(bsp, object.culling, camera.nearClipping, camera.farClipping, numVertices);
					if (debug) {
						len = resultIndicesLength;
						var num:int = numVertices;
						numVertices = v;
						bfk = backfaceCulling;
						backfaceCulling = 0;
						debugIndicesLength = 0;
						debugNode(bsp, object.culling, camera.nearClipping, camera.farClipping);
						resultIndices = debugIndices, resultIndicesLength = debugIndicesLength;
						clipPolygons(object.culling, camera.nearClipping, camera.farClipping);
						sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength;
						resultIndices = indices2, resultIndicesLength = len, numVertices = num, backfaceCulling = bfk;
					}
				}
				// Отрисовка
				if (resultIndicesLength > 0) {
					Utils3D.projectVectors(camera.projectionMatrix, cameraVertices, projectedVertices, uvts);
					cropVertices(object.culling, camera);
					drawGraphics(camera, object, parentCanvas);
				}
				// Подрезка вершин и UV
				cameraVertices.length = uvts.length = numVertices*3;
				projectedVertices.length = uvs.length = numVertices << 1;
			}
			// Затенение
			/*var cameraPosition:Vector3D = object.cameraMatrix.position;
			if (cameraPosition.z > camera.farFalloff) {
				var falloff:Number = (camera.farClipping - cameraPosition.z)/(camera.farClipping - camera.farFalloff);
				canvas.transform.colorTransform = new ColorTransform(falloff, falloff, falloff);
				canvas.modifiedColorTransform = true;
			}*/
		}
		
		// Сбор треугольников BSP-дерева
		private function collectNode(node:BSPNode):void {
			var ni:int = node.normal << 2;
			if (cameraX*normals[ni++] + cameraY*normals[ni++] + cameraZ*normals[ni++] > normals[ni]) {
				if (node.negative != null) collectNode(node.negative);
				// Проход по ноде
				for (var i:uint = 0, triangles:Vector.<int> = node.triangles, trianglesLength:int = node.trianglesLength; i < trianglesLength;) resultIndices[resultIndicesLength++] = triangles[i++];
				if (node.positive != null) collectNode(node.positive);
			} else {
				if (node.positive != null) collectNode(node.positive);
				if (node.negative != null) collectNode(node.negative);
			}
		}
		
		// Куллинг треугольников BSP-дерева
		private function cullNode(node:BSPNode, culling:int, near:Number, far:Number):void {
			var ni:int = node.normal << 2;
			if (cameraX*normals[ni++] + cameraY*normals[ni++] + cameraZ*normals[ni++] > normals[ni]) {
				if (node.negative != null) cullNode(node.negative, culling, near, far);
				// Проход по ноде
				for (var i:int = 0, x:Boolean = (culling & 12) > 0, y:Boolean = (culling & 48) > 0, triangles:Vector.<int> = node.triangles, trianglesLength:int = node.trianglesLength; i < trianglesLength;) {
					var a:int = triangles[i++], b:int = triangles[i++], c:int = triangles[i++], ai:int = a*3, bi:int = b*3, ci:int = c*3;
					if (x) var ax:Number = cameraVertices[ai], bx:Number = cameraVertices[bi], cx:Number = cameraVertices[ci];
					if (y) var ay:Number = cameraVertices[int(ai + 1)], by:Number = cameraVertices[int(bi + 1)], cy:Number = cameraVertices[int(ci + 1)];
					var az:Number = cameraVertices[int(ai + 2)], bz:Number = cameraVertices[int(bi + 2)], cz:Number = cameraVertices[int(ci + 2)];
					if ((az <= near || bz <= near || cz <= near) || az >= far && bz >= far && cz >= far || az <= -ax && bz <= -bx && cz <= -cx || az <= ax && bz <= bx && cz <= cx || az <= -ay && bz <= -by && cz <= -cy || az <= ay && bz <= by && cz <= cy) continue;
					resultIndices[resultIndicesLength++] = a, resultIndices[resultIndicesLength++] = b, resultIndices[resultIndicesLength++] = c;
				}
				if (node.positive != null) cullNode(node.positive, culling, near, far);
			} else {
				if (node.positive != null) cullNode(node.positive, culling, near, far);
				if (node.negative != null) cullNode(node.negative, culling, near, far);
			}
		}
		
		// Клиппинг полигонов BSP-дерева
		private function clipNode(node:BSPNode, culling:int, near:Number, far:Number, v:int):int {
			var ni:int = node.normal << 2;
			if (cameraX*normals[ni++] + cameraY*normals[ni++] + cameraZ*normals[ni++] > normals[ni]) {
				if (node.negative != null) v = clipNode(node.negative, culling, near, far, v);
				// Проход по ноде
				var infront:Boolean, behind:Boolean, inside:Boolean, a:int, b:int, c:int, ai:int, bi:int, ax:Number, ay:Number, az:Number, bx:Number, by:Number, bz:Number;
				for (var i:int = 0, k:int = 0, j:int, num1:int, num2:int = 0, vi:int, vj:int, t:Number, au:Number, av:Number, polygons:Vector.<int> = node.polygons, polygonsLength:int = node.polygonsLength; i < polygonsLength; i = k) {
					k = (num1 = polygons[i++]) + i;
					var insideNear:Boolean = true;
					if (culling & 1) {
						for (j = i; j < k; j++) if ((inside = cameraVertices[int(polygons[j]*3 + 2)] > near) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideNear = false;
						infront = false, behind = false;
					}
					var insideFar:Boolean = true;
					if (culling & 2) {
						for (j = i; j < k; j++) if ((inside = cameraVertices[int(polygons[j]*3 + 2)] < far) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideFar = false;
						infront = false, behind = false;
					}	
					var insideLeft:Boolean = true;
					if (culling & 4) {
						for (j = i; j < k; j++) if ((inside = -cameraVertices[vi = int(polygons[j]*3)] < cameraVertices[int(vi + 2)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideLeft = false;
						infront = false, behind = false;
					}	
					var insideRight:Boolean = true;
					if (culling & 8) {
						for (j = i; j < k; j++) if ((inside = cameraVertices[vi = int(polygons[j]*3)] < cameraVertices[int(vi + 2)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideRight = false;
						infront = false, behind = false;
					}	
					var insideTop:Boolean = true;
					if (culling & 16) {
						for (j = i; j < k; j++) if ((inside = -cameraVertices[vi = int(polygons[j]*3 + 1)] < cameraVertices[int(vi + 1)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideTop = false;
						infront = false, behind = false;
					}	
					var insideBottom:Boolean = true;
					if (culling & 32) {
						for (j = i; j < k; j++) if ((inside = cameraVertices[vi = int(polygons[j]*3 + 1)] < cameraVertices[int(vi + 1)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideBottom = false;
					}	
					// Полное вхождение
					if (insideNear && insideFar && insideLeft && insideRight && insideTop && insideBottom) {
						// Триангуляция
						for (j = i, a = polygons[j++], b = polygons[j++]; j < k;) resultIndices[resultIndicesLength++] = a, resultIndices[resultIndicesLength++] = b, resultIndices[resultIndicesLength++] = b = polygons[j++];
					} else {
						// Заполняем полигон
						for (j = i; j < k;) polygon[int(j - i)] = polygons[j++];
						// Клипинг по ниар
						if (!insideNear) {
							for (j = 1, a = c = polygon[0], ai = a*3, az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
								b = (j < num1) ? polygon[j] : c, bi = b*3, bz = cameraVertices[int(bi + 2)];
								if (bz > near && az <= near || bz <= near && az > near) t = (near - az)/(bz - az), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = near, uvts[vi] = 0;
								if (bz > near) polygon[num2++] = b;
								a = b, ai = bi,	az = bz;
							}
							if (num2 == 0) continue;
							num1 = num2, num2 = 0;
						}
						// Клипинг по фар
						if (!insideFar) {
							for (j = 1, a = c = polygon[0],	ai = a*3, az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
								b = (j < num1) ? polygon[j] : c, bi = b*3, bz = cameraVertices[int(bi + 2)];
								if (bz <= far && az > far || bz > far && az <= far) t = (far - az)/(bz - az), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = far, uvts[vi] = 0;
								if (bz <= far) polygon[num2++] = b;
								a = b, ai = bi,	az = bz;
							}
							if (num2 == 0) continue;
							num1 = num2, num2 = 0;
						}
						// Клипинг по левой стороне
						if (!insideLeft) {
							for (j = 1, a = c = polygon[0],	ai = a*3, ax = cameraVertices[ai], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
								b = (j < num1) ? polygon[j] : c, bi = b*3, bx = cameraVertices[bi], bz = cameraVertices[int(bi + 2)];
								if (bz > -bx && az <= -ax || bz <= -bx && az > -ax) t = (ax + az)/(ax + az - bx - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = ax + (bx - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
								if (bz > -bx) polygon[num2++] = b;
								a = b, ai = bi,	ax = bx, az = bz;
							}
							if (num2 == 0) continue;
							num1 = num2, num2 = 0;
						}
						// Клипинг по правой стороне
						if (!insideRight) {
							for (j = 1, a = c = polygon[0],	ai = a*3, ax = cameraVertices[ai], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
								b = (j < num1) ? polygon[j] : c, bi = b*3, bx = cameraVertices[bi], bz = cameraVertices[int(bi + 2)];
								if (bz > bx && az <= ax || bz <= bx && az > ax) t = (az - ax)/(az - ax + bx - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = ax + (bx - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
								if (bz > bx) polygon[num2++] = b;
								a = b, ai = bi,	ax = bx, az = bz;
							}
							if (num2 == 0) continue;
							num1 = num2, num2 = 0;
						}
						// Клипинг по верхней стороне
						if (!insideTop) {
							for (j = 1, a = c = polygon[0],	ai = a*3, ay = cameraVertices[int(ai + 1)], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
								b = (j < num1) ? polygon[j] : c, bi = b*3, by = cameraVertices[int(bi + 1)], bz = cameraVertices[int(bi + 2)];
								if (bz > -by && az <= -ay || bz <= -by && az > -ay) t = (ay + az)/(ay + az - by - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = ay + (by - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
								if (bz > -by) polygon[num2++] = b;
								a = b, ai = bi,	ay = by, az = bz;
							}
							if (num2 == 0) continue;
							num1 = num2, num2 = 0;
						}
						// Клипинг по нижней стороне
						if (!insideBottom) {
							for (j = 1, a = c = polygon[0],	ai = a*3, ay = cameraVertices[int(ai + 1)], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
								b = (j < num1) ? polygon[j] : c, bi = b*3, by = cameraVertices[int(bi + 1)], bz = cameraVertices[int(bi + 2)];
							  	if (bz > by && az <= ay || bz <= by && az > ay) t = (az - ay)/(az - ay + by - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = ay + (by - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
								if (bz > by) polygon[num2++] = b;
								a = b, ai = bi,	ay = by, az = bz;
							}
							if (num2 == 0) continue;
							num1 = num2, num2 = 0;
						}
						// Триангуляция полигона
						for (j = 2, a = polygon[0], b = polygon[1]; j < num1;) resultIndices[resultIndicesLength++] = a, resultIndices[resultIndicesLength++] = b, resultIndices[resultIndicesLength++] = b = polygon[j++];
					}
				}
				if (node.positive != null) v = clipNode(node.positive, culling, near, far, v);
			} else {
				if (node.positive != null) v = clipNode(node.positive, culling, near, far, v);
				if (node.negative != null) v = clipNode(node.negative, culling, near, far, v);
			}
			return v;
		}
		
		// Сбор полигонов BSP-дерева для дебага
		private function debugNode(node:BSPNode, culling:int, near:Number, far:Number):void {
			var ni:int = node.normal << 2;
			if (cameraX*normals[ni++] + cameraY*normals[ni++] + cameraZ*normals[ni++] > normals[ni]) for (var i:uint = 0; i < node.polygonsLength;) debugIndices[debugIndicesLength++] = node.polygons[i++];
			if (node.negative != null) debugNode(node.negative, culling, near, far);
			if (node.positive != null) debugNode(node.positive, culling, near, far);
		}
		
		// Отсечение треугольников по нормалям
		private function backfaceCullTriangles():void {
			sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength, resultIndices = (sourceIndices == indices1) ? indices2 : indices1, resultIndicesLength = 0;
			var i:int = 0;
			if (backfaceCulling == 1) {
				// Отсечение по предрасчитанным нормалям
				for (var ni:int = 0; i < sourceIndicesLength;) {
					if (normals[ni++]*cameraX + normals[ni++]*cameraY + normals[ni++]*cameraZ > normals[ni++]) resultIndices[resultIndicesLength++] = sourceIndices[i++], resultIndices[resultIndicesLength++] = sourceIndices[i++], resultIndices[resultIndicesLength++] = sourceIndices[i++] else i += 3;
				}
			} else {
				// Отсечение по динамическим нормалям
				for (var vi:int = 0; i < sourceIndicesLength;) {
					var ax:Number = cameraVertices[vi = int(sourceIndices[i]*3)], ay:Number = cameraVertices[++vi], az:Number = cameraVertices[++vi], abx:Number = cameraVertices[vi = int(sourceIndices[int(i + 1)]*3)] - ax, aby:Number = cameraVertices[++vi] - ay, abz:Number = cameraVertices[++vi] - az, acx:Number = cameraVertices[vi = int(sourceIndices[int(i + 2)]*3)] - ax, acy:Number = cameraVertices[++vi] - ay, acz:Number = cameraVertices[++vi] - az;
					if ((acz*aby - acy*abz)*ax + (acx*abz - acz*abx)*ay + (acy*abx - acx*aby)*az < 0) resultIndices[resultIndicesLength++] = sourceIndices[i++], resultIndices[resultIndicesLength++] = sourceIndices[i++], resultIndices[resultIndicesLength++] = sourceIndices[i++] else i += 3;
				}
			}
		}
		
		// Отсечение полигонов по нормалям
		private function backfaceCullPolygons():void {
			sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength, resultIndices = (sourceIndices == indices1) ? indices2 : indices1, resultIndicesLength = 0;
			var i:int = 0, k:int = 0;
			if (backfaceCulling == 1) {
				// Отсечение по предрасчитанным нормалям
				for (var ni:int = 0; i < sourceIndicesLength;) {
					if (i == k) {
						k = sourceIndices[i++] + i;
						if (normals[ni++]*cameraX + normals[ni++]*cameraY + normals[ni++]*cameraZ > normals[ni++]) {
							resultIndices[resultIndicesLength++] = sourceIndices[int(i - 1)];
						} else {
							i = k;
							continue;
						}
					}
					resultIndices[resultIndicesLength++] = sourceIndices[i++];
				}
			} else {
				// Отсечение по динамическим нормалям
				for (var vi:int = 0; i < sourceIndicesLength;) {
					if (i == k) {
						k = sourceIndices[i++] + i;
						var ax:Number = cameraVertices[vi = int(sourceIndices[i]*3)], ay:Number = cameraVertices[++vi], az:Number = cameraVertices[++vi], abx:Number = cameraVertices[vi = int(sourceIndices[int(i + 1)]*3)] - ax, aby:Number = cameraVertices[++vi] - ay, abz:Number = cameraVertices[++vi] - az, acx:Number = cameraVertices[vi = int(sourceIndices[int(i + 2)]*3)] - ax, acy:Number = cameraVertices[++vi] - ay, acz:Number = cameraVertices[++vi] - az;
						if ((acz*aby - acy*abz)*ax + (acx*abz - acz*abx)*ay + (acy*abx - acx*aby)*az < 0) {
							resultIndices[resultIndicesLength++] = sourceIndices[int(i - 1)];
						} else {
							i = k;
							continue;
						}
					}
					resultIndices[resultIndicesLength++] = sourceIndices[i++];
				}
			}
		}
		
		// Отсечение треугольников по пирамиде видимости
		private function cullTriangles(culling:int, near:Number, far:Number):void {
			sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength, resultIndices = (sourceIndices == indices1) ? indices2 : indices1, resultIndicesLength = 0;
			var x:Boolean = (culling & 12) > 0 || backfaceCulling == 2, y:Boolean = (culling & 48) > 0 || backfaceCulling == 2;
			for (var i:int = 0, ni:int = 0; i < sourceIndicesLength;) {
				if (backfaceCulling == 1 && normals[ni++]*cameraX + normals[ni++]*cameraY + normals[ni++]*cameraZ <= normals[ni++]) {
					i += 3;
					continue;
				}
				var a:int = sourceIndices[i++], b:int = sourceIndices[i++], c:int = sourceIndices[i++], ai:int = a*3, bi:int = b*3, ci:int = c*3;
				if (x) var ax:Number = cameraVertices[ai], bx:Number = cameraVertices[bi], cx:Number = cameraVertices[ci];
				if (y) var ay:Number = cameraVertices[int(ai + 1)], by:Number = cameraVertices[int(bi + 1)], cy:Number = cameraVertices[int(ci + 1)];
				var az:Number = cameraVertices[int(ai + 2)], bz:Number = cameraVertices[int(bi + 2)], cz:Number = cameraVertices[int(ci + 2)];
				if ((az <= near || bz <= near || cz <= near) || az >= far && bz >= far && cz >= far || az <= -ax && bz <= -bx && cz <= -cx || az <= ax && bz <= bx && cz <= cx || az <= -ay && bz <= -by && cz <= -cy || az <= ay && bz <= by && cz <= cy) continue;
				if (backfaceCulling == 2) {
					var abx:Number = bx - ax, aby:Number = by - ay, abz:Number = bz - az, acx:Number = cx - ax, acy:Number = cy - ay, acz:Number = cz - az;
					if ((acz*aby - acy*abz)*ax + (acx*abz - acz*abx)*ay + (acy*abx - acx*aby)*az >= 0) continue;
				}
				resultIndices[resultIndicesLength++] = a, resultIndices[resultIndicesLength++] = b, resultIndices[resultIndicesLength++] = c;
			}
		}
		
		// Отсечение полигонов по пирамиде видимости
		private function cullPolygons(culling:int, near:Number, far:Number):void {
			sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength, resultIndices = (sourceIndices == indices1) ? indices2 : indices1, resultIndicesLength = 0;
			for (var i:int = 0, k:int = 0, j:int, ni:int, num:int, vi:int; i < sourceIndicesLength; i = k) {
				k = (num = sourceIndices[i++]) + i;
				if (backfaceCulling == 1 && normals[ni++]*cameraX + normals[ni++]*cameraY + normals[ni++]*cameraZ <= normals[ni++]) continue;
				if (backfaceCulling == 2) {
					var ax:Number = cameraVertices[vi = int(sourceIndices[i]*3)], ay:Number = cameraVertices[++vi], az:Number = cameraVertices[++vi], abx:Number = cameraVertices[vi = int(sourceIndices[int(i + 1)]*3)] - ax, aby:Number = cameraVertices[++vi] - ay, abz:Number = cameraVertices[++vi] - az, acx:Number = cameraVertices[vi = int(sourceIndices[int(i + 2)]*3)] - ax, acy:Number = cameraVertices[++vi] - ay, acz:Number = cameraVertices[++vi] - az;
					if ((acz*aby - acy*abz)*ax + (acx*abz - acz*abx)*ay + (acy*abx - acx*aby)*az >= 0) continue;
				}
				if (culling & 1) {
					for (j = i; j < k; j++) if (cameraVertices[int(sourceIndices[j]*3 + 2)] <= near) break;
					if (j < k) continue;
				}
				if (culling & 2) {
					for (j = i; j < k; j++) if (cameraVertices[int(sourceIndices[j]*3 + 2)] < far) break;
					if (j == k) continue;
				}
				if (culling & 4) {
					for (j = i; j < k; j++) if (-cameraVertices[vi = int(sourceIndices[j]*3)] < cameraVertices[int(vi + 2)]) break;
					if (j == k) continue;
				}
				if (culling & 8) {
					for (j = i; j < k; j++) if (cameraVertices[vi = int(sourceIndices[j]*3)] < cameraVertices[int(vi + 2)]) break;
					if (j == k) continue;
				}
				if (culling & 16) {
					for (j = i; j < k; j++) if (-cameraVertices[vi = int(sourceIndices[j]*3 + 1)] < cameraVertices[int(vi + 1)]) break;
					if (j == k) continue;
				}
				if (culling & 32) {
					for (j = i; j < k; j++) if (cameraVertices[vi = int(sourceIndices[j]*3 + 1)] < cameraVertices[int(vi + 1)]) break;
					if (j == k) continue;
				}
				resultIndices[resultIndicesLength++] = num;
				for (j = i; j < k;) resultIndices[resultIndicesLength++] = sourceIndices[j++];
			}
		}
		
		private function clipTriangles(culling:int, near:Number, far:Number):void {
			sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength, resultIndices = (sourceIndices == indices1) ? indices2 : indices1, resultIndicesLength = 0;
			var x:Boolean = (culling & 12) > 0 || backfaceCulling == 2, y:Boolean = (culling & 48) > 0 || backfaceCulling == 2;
			for (var i:int = 0, j:int, ni:int = 0, v:int = numVertices, vi:int, vj:int, t:Number, au:Number, av:Number, num1:int, num2:int; i < sourceIndicesLength;) {
				if (backfaceCulling == 1 && normals[ni++]*cameraX + normals[ni++]*cameraY + normals[ni++]*cameraZ <= normals[ni++]) {
					i += 3;
					continue;
				}
				var a:int = sourceIndices[i++], b:int = sourceIndices[i++], c:int = sourceIndices[i++], ai:int = a*3, bi:int = b*3, ci:int = c*3;
				if (x) var ax:Number = cameraVertices[ai], bx:Number = cameraVertices[bi], cx:Number = cameraVertices[ci];
				if (y) var ay:Number = cameraVertices[int(ai + 1)], by:Number = cameraVertices[int(bi + 1)], cy:Number = cameraVertices[int(ci + 1)];
				var az:Number = cameraVertices[int(ai + 2)], bz:Number = cameraVertices[int(bi + 2)], cz:Number = cameraVertices[int(ci + 2)];
				// За пределами пирамиды видимости
				if (az <= near && bz <= near && cz <= near || az >= far && bz >= far && cz >= far || az <= -ax && bz <= -bx && cz <= -cx || az <= ax && bz <= bx && cz <= cx || az <= -ay && bz <= -by && cz <= -cy || az <= ay && bz <= by && cz <= cy) continue;
				if (backfaceCulling == 2) {
					var abx:Number = bx - ax, aby:Number = by - ay, abz:Number = bz - az, acx:Number = cx - ax, acy:Number = cy - ay, acz:Number = cz - az;
					if ((acz*aby - acy*abz)*ax + (acx*abz - acz*abx)*ay + (acy*abx - acx*aby)*az >= 0) continue;
				}
				// Полностью в пирамиде видимости
				var insideNear:Boolean = !(culling & 1) || az > near && bz > near && cz > near, insideFar:Boolean = !(culling & 2) || az < far && bz < far && cz < far, insideLeft:Boolean = !(culling & 4) || az > -ax && bz > -bx && cz > -cx, insideRight:Boolean = !(culling & 8) || az > ax && bz > bx && cz > cx, insideTop:Boolean = !(culling & 16) || az > -ay && bz > -by && cz > -cy, insideBottom:Boolean = !(culling & 32) || az > ay && bz > by && cz > cy;
				if (insideNear && insideFar && insideLeft && insideRight && insideTop && insideBottom) {
					resultIndices[resultIndicesLength++] = a, resultIndices[resultIndicesLength++] = b, resultIndices[resultIndicesLength++] = c;
				} else {
					// Заполняем полигон
					polygon[0] = a,	polygon[1] = b,	polygon[2] = c,	num1 = 3, num2 = 0;
					// Клипинг по ниар
					if (!insideNear) {
						for (j = 1, a = c = polygon[0], ai = a*3, az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, bz = cameraVertices[int(bi + 2)];
							if (bz > near && az <= near || bz <= near && az > near) t = (near - az)/(bz - az), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = near, uvts[vi] = 0;
							if (bz > near) polygon[num2++] = b;
							a = b, ai = bi,	az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по фар
					if (!insideFar) {
						for (j = 1, a = c = polygon[0], ai = a*3, az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, bz = cameraVertices[int(bi + 2)];
							if (bz <= far && az > far || bz > far && az <= far) t = (far - az)/(bz - az), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = far, uvts[vi] = 0;
							if (bz <= far) polygon[num2++] = b;
							a = b, ai = bi,	az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по левой стороне
					if (!insideLeft) {
						for (j = 1, a = c = polygon[0],	ai = a*3, ax = cameraVertices[ai], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, bx = cameraVertices[bi], bz = cameraVertices[int(bi + 2)];
							if (bz > -bx && az <= -ax || bz <= -bx && az > -ax) t = (ax + az)/(ax + az - bx - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = ax + (bx - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
							if (bz > -bx) polygon[num2++] = b;
							a = b, ai = bi,	ax = bx, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по правой стороне
					if (!insideRight) {
						for (j = 1, a = c = polygon[0],	ai = a*3, ax = cameraVertices[ai], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, bx = cameraVertices[bi], bz = cameraVertices[int(bi + 2)];
							if (bz > bx && az <= ax || bz <= bx && az > ax) t = (az - ax)/(az - ax + bx - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = ax + (bx - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
							if (bz > bx) polygon[num2++] = b;
							a = b, ai = bi,	ax = bx, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по верхней стороне
					if (!insideTop) {
						for (j = 1, a = c = polygon[0],	ai = a*3, ay = cameraVertices[int(ai + 1)], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, by = cameraVertices[int(bi + 1)], bz = cameraVertices[int(bi + 2)];
							if (bz > -by && az <= -ay || bz <= -by && az > -ay) t = (ay + az)/(ay + az - by - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = ay + (by - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
							if (bz > -by) polygon[num2++] = b;
							a = b, ai = bi,	ay = by, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по нижней стороне
					if (!insideBottom) {
						for (j = 1, a = c = polygon[0],	ai = a*3, ay = cameraVertices[int(ai + 1)], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, by = cameraVertices[int(bi + 1)], bz = cameraVertices[int(bi + 2)];
						  	if (bz > by && az <= ay || bz <= by && az > ay) t = (az - ay)/(az - ay + by - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = ay + (by - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
							if (bz > by) polygon[num2++] = b;
							a = b, ai = bi,	ay = by, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Триангуляция полигона
					for (j = 2, a = polygon[0], b = polygon[1]; j < num1;) resultIndices[resultIndicesLength++] = a, resultIndices[resultIndicesLength++] = b, resultIndices[resultIndicesLength++] = b = polygon[j++];
				}
			}
		}
		
		private function clipPolygons(culling:int, near:Number, far:Number):void {
			sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength, resultIndices = (sourceIndices == indices1) ? indices2 : indices1, resultIndicesLength = 0;
			var infront:Boolean, behind:Boolean, inside:Boolean, a:int, b:int, c:int, ai:int, bi:int, bx:Number, by:Number, bz:Number;
			for (var i:int = 0, k:int = 0, j:int, ni:int = 0, num1:int, num2:int = 0, v:int = numVertices, vi:int, vj:int, t:Number, au:Number, av:Number; i < sourceIndicesLength; i = k) {
				k = (num1 = sourceIndices[i++]) + i;
				if (backfaceCulling == 1 && normals[ni++]*cameraX + normals[ni++]*cameraY + normals[ni++]*cameraZ <= normals[ni++]) continue;
				if (backfaceCulling == 2) {
					var ax:Number = cameraVertices[vi = int(sourceIndices[i]*3)], ay:Number = cameraVertices[++vi], az:Number = cameraVertices[++vi], abx:Number = cameraVertices[vi = int(sourceIndices[int(i + 1)]*3)] - ax, aby:Number = cameraVertices[++vi] - ay, abz:Number = cameraVertices[++vi] - az, acx:Number = cameraVertices[vi = int(sourceIndices[int(i + 2)]*3)] - ax, acy:Number = cameraVertices[++vi] - ay, acz:Number = cameraVertices[++vi] - az;
					if ((acz*aby - acy*abz)*ax + (acx*abz - acz*abx)*ay + (acy*abx - acx*aby)*az >= 0) continue;
				}
				// Отсечение
				var insideNear:Boolean = true;
				if (culling & 1) {
					for (j = i; j < k; j++) if ((inside = cameraVertices[int(sourceIndices[j]*3 + 2)] > near) && (infront = true) && behind || !inside && (behind = true) && infront) break;
					if (behind) if (!infront) continue; else insideNear = false;
					infront = false, behind = false;
				}
				var insideFar:Boolean = true;
				if (culling & 2) {
					for (j = i; j < k; j++) if ((inside = cameraVertices[int(sourceIndices[j]*3 + 2)] < far) && (infront = true) && behind || !inside && (behind = true) && infront) break;
					if (behind) if (!infront) continue; else insideFar = false;
					infront = false, behind = false;
				}	
				var insideLeft:Boolean = true;
				if (culling & 4) {
					for (j = i; j < k; j++) if ((inside = -cameraVertices[vi = int(sourceIndices[j]*3)] < cameraVertices[int(vi + 2)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
					if (behind) if (!infront) continue; else insideLeft = false;
					infront = false, behind = false;
				}	
				var insideRight:Boolean = true;
				if (culling & 8) {
					for (j = i; j < k; j++) if ((inside = cameraVertices[vi = int(sourceIndices[j]*3)] < cameraVertices[int(vi + 2)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
					if (behind) if (!infront) continue; else insideRight = false;
					infront = false, behind = false;
				}	
				var insideTop:Boolean = true;
				if (culling & 16) {
					for (j = i; j < k; j++) if ((inside = -cameraVertices[vi = int(sourceIndices[j]*3 + 1)] < cameraVertices[int(vi + 1)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
					if (behind) if (!infront) continue; else insideTop = false;
					infront = false, behind = false;
				}	
				var insideBottom:Boolean = true;
				if (culling & 32) {
					for (j = i; j < k; j++) if ((inside = cameraVertices[vi = int(sourceIndices[j]*3 + 1)] < cameraVertices[int(vi + 1)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
					if (behind) if (!infront) continue; else insideBottom = false;
				}	
				// Полное вхождение
				if (insideNear && insideFar && insideLeft && insideRight && insideTop && insideBottom) {
					resultIndices[resultIndicesLength++] = num1;
					for (j = i; j < k;) resultIndices[resultIndicesLength++] = sourceIndices[j++];
				} else {
					// Заполняем полигон
					for (j = i; j < k;) polygon[int(j - i)] = sourceIndices[j++];
					// Клипинг по ниар
					if (!insideNear) {
						for (j = 1, a = c = polygon[0], ai = a*3, az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, bz = cameraVertices[int(bi + 2)];
							if (bz > near && az <= near || bz <= near && az > near) t = (near - az)/(bz - az), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = near, uvts[vi] = 0;
							if (bz > near) polygon[num2++] = b;
							a = b, ai = bi,	az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по фар
					if (!insideFar) {
						for (j = 1, a = c = polygon[0],	ai = a*3, az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, bz = cameraVertices[int(bi + 2)];
							if (bz <= far && az > far || bz > far && az <= far) t = (far - az)/(bz - az), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = far, uvts[vi] = 0;
							if (bz <= far) polygon[num2++] = b;
							a = b, ai = bi,	az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по левой стороне
					if (!insideLeft) {
						for (j = 1, a = c = polygon[0],	ai = a*3, ax = cameraVertices[ai], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, bx = cameraVertices[bi], bz = cameraVertices[int(bi + 2)];
							if (bz > -bx && az <= -ax || bz <= -bx && az > -ax) t = (ax + az)/(ax + az - bx - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = ax + (bx - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
							if (bz > -bx) polygon[num2++] = b;
							a = b, ai = bi,	ax = bx, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по правой стороне
					if (!insideRight) {
						for (j = 1, a = c = polygon[0],	ai = a*3, ax = cameraVertices[ai], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, bx = cameraVertices[bi], bz = cameraVertices[int(bi + 2)];
							if (bz > bx && az <= ax || bz <= bx && az > ax) t = (az - ax)/(az - ax + bx - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = ax + (bx - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = (ay = cameraVertices[int(ai + 1)]) + (cameraVertices[int(bi + 1)] - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
							if (bz > bx) polygon[num2++] = b;
							a = b, ai = bi,	ax = bx, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по верхней стороне
					if (!insideTop) {
						for (j = 1, a = c = polygon[0],	ai = a*3, ay = cameraVertices[int(ai + 1)], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, by = cameraVertices[int(bi + 1)], bz = cameraVertices[int(bi + 2)];
							if (bz > -by && az <= -ay || bz <= -by && az > -ay) t = (ay + az)/(ay + az - by - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = ay + (by - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
							if (bz > -by) polygon[num2++] = b;
							a = b, ai = bi,	ay = by, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по нижней стороне
					if (!insideBottom) {
						for (j = 1, a = c = polygon[0],	ai = a*3, ay = cameraVertices[int(ai + 1)], az = cameraVertices[int(ai + 2)]; j <= num1; j++) {
							b = (j < num1) ? polygon[j] : c, bi = b*3, by = cameraVertices[int(bi + 1)], bz = cameraVertices[int(bi + 2)];
						  	if (bz > by && az <= ay || bz <= by && az > ay) t = (az - ay)/(az - ay + by - bz), polygon[num2++] = v, cameraVertices[vi = int(v*3)] = (ax = cameraVertices[ai]) + (cameraVertices[bi] - ax)*t, uvts[vi++] = uvs[vj = v++ << 1] = (au = uvts[ai]) + (uvts[bi] - au)*t, cameraVertices[vi] = ay + (by - ay)*t, uvts[vi++] = uvs[++vj] = (av = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - av)*t, cameraVertices[vi] = az + (bz - az)*t, uvts[vi] = 0;
							if (bz > by) polygon[num2++] = b;
							a = b, ai = bi,	ay = by, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Копирование полигона
					resultIndices[resultIndicesLength++] = num1;
					for (j = 0; j < num1;) resultIndices[resultIndicesLength++] = polygon[j++];
				}
			}
		}
		
		// Триангуляция полигонов для отрисовки
		private function triangulate():void {
			sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength, resultIndices = (sourceIndices == indices1) ? indices2 : indices1, resultIndicesLength = 0;
			for (var i:int = 0, k:int = 0, a:int, b:int; i < sourceIndicesLength;) {
				if (i == k) k = sourceIndices[i++] + i, a = sourceIndices[i++], b = sourceIndices[i++];
				resultIndices[resultIndicesLength++] = a, resultIndices[resultIndicesLength++] = b, resultIndices[resultIndicesLength++] = b = sourceIndices[i++];
			}
		}

		private function sortTriangles():void {
			sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength, resultIndices = (sourceIndices == indices1) ? indices2 : indices1, resultIndicesLength = 0;
			// Ищем средние Z и готовим карту сортировки
			for (var i:int = 0, n:int, k:int, map:Vector.<int> = sortingMap, averageZ:Vector.<Number> = sortingAverageZ; i < sourceIndicesLength;) map[n = int(i/3)] = i, averageZ[n] = cameraVertices[int(sourceIndices[i++]*3 + 2)] + cameraVertices[int(sourceIndices[i++]*3 + 2)] + cameraVertices[int(sourceIndices[i++]*3 + 2)];
			// Сортировка
			sortAverageZ(0, n++);
			// Перестановка граней по карте сортировки
			for (i = 0; i < n;) resultIndices[resultIndicesLength++] = sourceIndices[k = map[i++]], resultIndices[resultIndicesLength++] = sourceIndices[++k], resultIndices[resultIndicesLength++] = sourceIndices[++k];
		}

		private function sortPolygons():void {
			sourceIndices = resultIndices, sourceIndicesLength = resultIndicesLength, resultIndices = (sourceIndices == indices1) ? indices2 : indices1, resultIndicesLength = 0;
			// Ищем средние Z и готовим карту сортировки
			for (var i:int = 0, j:int, n:int = 0, num:int, k:int = 0, z:Number, a:int, b:int, map:Vector.<int> = sortingMap, averageZ:Vector.<Number> = sortingAverageZ; i < sourceIndicesLength;) {
				if (i == k) map[n] = i, k = (numDrawingTriangles = sourceIndices[i++]) + i, z = 0;
				z += cameraVertices[int(sourceIndices[i]*3 + 2)];
				if (++i == k) averageZ[n++] = z/numDrawingTriangles;
			}
			// Сортировка
			sortAverageZ(0, n - 1);
			// Перестановка граней по карте сортировки и триангуляция
			for (i = 0; i < n; i++) for (j = map[i], k = sourceIndices[j] + ++j, a = sourceIndices[j++], b = sourceIndices[j++]; j < k;) resultIndices[resultIndicesLength++] = a, resultIndices[resultIndicesLength++] = b, resultIndices[resultIndicesLength++] = b = sourceIndices[j++];
		}
		
		private function sortAverageZ(l:int, r:int):void {
			var i:int, j:int, stack:Vector.<int> = sortingStack, map:Vector.<int> = sortingMap, averageZ:Vector.<Number> = sortingAverageZ, stackIndex:int, left:Number, median:Number, right:Number, mapIndex:int;
			for (stack[0] = l, stack[1] = r, stackIndex = 2; stackIndex > 0;) {
				j = r = stack[--stackIndex], i = l = stack[--stackIndex], median = averageZ[(r + l) >> 1];
				for (;i <= j;) {
	 				for (;(left = averageZ[i]) > median; i++);
	 				for (;(right = averageZ[j]) < median; j--);
	 				if (i <= j) mapIndex = map[i], map[i] = map[j], map[j] = mapIndex, averageZ[i++] = right, averageZ[j--] = left;
	 			}
				if (l < j) stack[stackIndex++] = l, stack[stackIndex++] = j;
				if (i < r) stack[stackIndex++] = i, stack[stackIndex++] = r;
			}
		}
		
		// Коррекция области перерисовки
		private function cropVertices(culling:int, camera:Camera3D):void {
			// Коррекция ширины и высоты с учётом ошибки вычислений
			var w:Number = camera.width/2 + 0.1, h:Number = camera.height/2 + 0.1, nearDist:Number = camera.nearClipping;
			var i:int, j:int, projectedVerticesLength:int = projectedVertices.length, c:Number;
			if (clipping == 1) {
				if (culling & 1) {
					for (i = 0, j = 2; i < projectedVerticesLength; i += 2, j += 3) {
						if (cameraVertices[j] <= nearDist) {
							projectedVertices[i] = (cameraVertices[int(j - 2)] < 0) ? -w : w;
							projectedVertices[int(i + 1)] = (cameraVertices[int(j - 1)] < 0) ? -h : h;
						}
					}
				}
			} else {
				if (culling & 1) {
					if (culling & 12 && culling & 48) {
						for (i = 0, j = 2; i < projectedVerticesLength; i++, j += 3) {
							if (cameraVertices[j] < 0) {
								projectedVertices[i] = (cameraVertices[int(j - 2)] < 0) ? -w : w;
								projectedVertices[++i] = (cameraVertices[int(j - 1)] < 0) ? -h : h;
							} else {
								if ((c = projectedVertices[i]) < -w) projectedVertices[i] = -w;
								else if (c > w) projectedVertices[i] = w;
								if ((c = projectedVertices[++i]) < -h) projectedVertices[i] = -h;
								else if (c > h) projectedVertices[i] = h;
							}
						}
					} else if (culling & 12) {
						for (i = 0, j = 2; i < projectedVerticesLength; i += 2, j += 3) {
							if (cameraVertices[j] < 0) {
								projectedVertices[i] = (cameraVertices[int(j - 2)] < 0) ? -w : w;
								projectedVertices[int(i + 1)] = (cameraVertices[int(j - 1)] < 0) ? -h : h;
							} else {
								if ((c = projectedVertices[i]) < -w) projectedVertices[i] = -w;
								else if (c > w) projectedVertices[i] = w;
							}
						}
					} else if (culling & 48) {
						for (i = 1, j = 2; i < projectedVerticesLength; i += 2, j += 3) {
							if (cameraVertices[j] < 0) {
								projectedVertices[int(i - 1)] = (cameraVertices[int(j - 2)] < 0) ? -w : w;
								projectedVertices[i] = (cameraVertices[int(j - 1)] < 0) ? -h : h;
							} else {
								if ((c = projectedVertices[i]) < -h) projectedVertices[i] = -h;
								else if (c > h) projectedVertices[i] = h;
							}
						}
					}
				} else {
					if (culling & 4 && culling & 8) {
						for (i = 0; i < projectedVerticesLength; i += 2) {				
							if ((c = projectedVertices[i]) < -w) projectedVertices[i] = -w;
							else if (c > w) projectedVertices[i] = w;
						}
					} else if (culling & 4) {
						for (i = 0; i < projectedVerticesLength; i += 2) if (projectedVertices[i] < -w) projectedVertices[i] = -w;
					} else if (culling & 8) {
						for (i = 0; i < projectedVerticesLength; i += 2) if (projectedVertices[i] > w) projectedVertices[i] = w;
					}
					if (culling & 16 && culling & 32) {
						for (i = 1; i < projectedVerticesLength; i += 2) {				
							if ((c = projectedVertices[i]) < -h) projectedVertices[i] = -h;
							else if (c > h) projectedVertices[i] = h;
						}
					} else if (culling & 16) {
						for (i = 1; i < projectedVerticesLength; i += 2) if (projectedVertices[i] < -h) projectedVertices[i] = -h;
					} else if (culling & 32) {
						for (i = 1; i < projectedVerticesLength; i += 2) if (projectedVertices[i] > h) projectedVertices[i] = h;
					}
				}
			}
		}
		
		/**
		 * @private 
		 */
		alternativa3d function getMipTexture(camera:Camera3D, object:Object3D):BitmapData {
			// Находим расстояние до объекта
			cameraCenter[0] = cameraCenter[1] = cameraCenter[2] = 0;
			object.cameraMatrix.transformVectors(cameraCenter, cameraCenter);
			return mipMap.textures[mipMap.getLevel(cameraCenter[2], camera)];
		}
		
		// Отрисовка полигонов в канвас
		protected function drawGraphics(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Подрезка
			resultIndices.length = resultIndicesLength;
			
			numDrawingTriangles += resultIndicesLength/3;
			
			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, object.alpha, object.blendMode, object.colorTransform, object.filters);
			// Отрисовка
			canvas.gfx.beginBitmapFill((mipMapping == 0) ? texture : getMipTexture(camera, object), null, repeatTexture, smooth);
			if (debug) {
				if (sorting != 2) {
					if (poly) {
						canvas.gfx.drawTriangles(projectedVertices, resultIndices, perspectiveCorrection ? uvts : uvs, "positive");
						canvas.gfx.endFill();
						canvas.gfx.lineStyle(0, 0xFFFFFF);
						for (var i:int = 0, j:int = 0, k:int = 0, n:int; i < sourceIndicesLength;) {
							if (i == k) {
								k = sourceIndices[i++] + i;
								var ax:Number = projectedVertices[n = sourceIndices[i] << 1];
								var ay:Number = projectedVertices[++n];
								var abx:Number = projectedVertices[n = sourceIndices[int(i + 1)] << 1] - ax;
								var aby:Number = projectedVertices[++n] - ay;
								var acx:Number = projectedVertices[n = sourceIndices[int(i + 2)] << 1] - ax;
								var acy:Number = projectedVertices[++n] - ay;
								if (abx*acy - aby*acx >= 0) {
									i = k;
									continue;
								}
								canvas.gfx.moveTo(projectedVertices[j = sourceIndices[int(k - 1)] << 1], projectedVertices[++j]);
							}
							canvas.gfx.lineTo(projectedVertices[j = sourceIndices[i++] << 1], projectedVertices[++j]);
						}
					} else {
						canvas.gfx.lineStyle(0, 0xFFFFFF);
						canvas.gfx.drawTriangles(projectedVertices, resultIndices, perspectiveCorrection ? uvts : uvs, "positive");
					}
				} else {
					canvas.gfx.drawTriangles(projectedVertices, resultIndices, perspectiveCorrection ? uvts : uvs, "positive");
					canvas.gfx.endFill();
					canvas.gfx.lineStyle(0, 0xFFFFFF);
					for (i = 0, j = 0, k = 0; i < sourceIndicesLength;) {
						if (i == k) {
							k = sourceIndices[i++] + i;
							canvas.gfx.moveTo(projectedVertices[j = sourceIndices[int(k - 1)] << 1], projectedVertices[++j]);
						}
						canvas.gfx.lineTo(projectedVertices[j = sourceIndices[i++] << 1], projectedVertices[++j]);
					}
				}

				object.drawBoundBox(camera, canvas);
/*
				// Вершины
				canvas.gfx.lineStyle();
				for (i = 0, length = projectedVertices.length; i < length;) {
					canvas.gfx.beginFill(0xFFFF00);
					canvas.gfx.drawCircle(projectedVertices[i++], projectedVertices[i++], 2);
					canvas.gfx.endFill();
				}
*/			
			} else {
				canvas.gfx.drawTriangles(projectedVertices, resultIndices, perspectiveCorrection ? uvts : uvs, "positive");
			}
		}
		
		/**
		 * Расчёт нормалей 
		 * @param normalize Флаг нормализации
		 */
		public function calculateNormals(normalize:Boolean = false):void {
			// Подготавливаем массив нормалей
			if (normals == null) normals = new Vector.<Number>() else normals.length = numFaces << 2;
			// Расчитываем нормали
			for (var i:int = 0, j:int = 0, num:int = 3, vi:int, nl:Number, indicesLength:int = indices.length; i < indicesLength; i += num) {
				if (poly) num = indices[i++];
				// Получаем координаты A
				var ax:Number = vertices[vi = int(indices[i]*3)];
				var ay:Number = vertices[++vi];
				var az:Number = vertices[++vi];
				// Получаем вектор AB
				var abx:Number = vertices[vi = int(indices[int(i + 1)]*3)] - ax;
				var aby:Number = vertices[++vi] - ay;
				var abz:Number = vertices[++vi] - az;
				// Получаем вектор AC
				var acx:Number = vertices[vi = int(indices[int(i + 2)]*3)] - ax;
				var acy:Number = vertices[++vi] - ay;
				var acz:Number = vertices[++vi] - az;
				// Считаем нормаль
				var nx:Number = acz*aby - acy*abz;
				var ny:Number = acx*abz - acz*abx;
				var nz:Number = acy*abx - acx*aby;
				// Нормализуем
				if (normalize && (nl = Math.sqrt(nx*nx + ny*ny + nz*nz)) > 0) {
					nx /= nl;
					ny /= nl;
					nz /= nl;
				}
				// Сохраняем нормаль и смещение
				normals[j++] = nx; 
				normals[j++] = ny; 
				normals[j++] = nz; 
				normals[j++] = ax*nx + ay*ny + az*nz;
			}
		}
		
		/**
		 * Расчёт локального BSP-дерева 
		 * @param splitAnalysis Флаг сплит-анализа. 
		 * Если он включен, дерево построится с наименьшим количеством распилов, но построение будет медленнее
		 */
		public function calculateBSP(splitAnalysis:Boolean = false):void {
			// Отправка старого дерева в коллектор
			if (bsp != null) {
				bsp.destroy();
				bsp = null;
			}
			if (numFaces == 0) return;
			// Подготовка к построению нового дерева
			fragmentsLength = 0;
			for (var i:int = 0, k:int = 0, ni:int = 0, num:int, indicesLength:int = indices.length; i < indicesLength; i++) {
				if (i == k) k = (num = poly ? indices[i++] : 3) + i, fragments[fragmentsLength++] = (ni << 16) + num, ni += 4;
				fragments[fragmentsLength++] = indices[i];
			}
			// Построение дерева
			bsp = split(0, fragmentsLength, splitAnalysis ? findSplitter(0, fragmentsLength) : 0, splitAnalysis);
		}
		
		private function split(begin:int, end:int, splitter:int, splitAnalysis:Boolean):BSPNode {
			// Построение ноды
			var mi:int = fragments[splitter], ni:int = mi >> 16, num:int = mi & 0xFFFF;
			var node:BSPNode = BSPNode.create();
			node.normal = ni >> 2;
			node.addFragment(fragments, splitter + 1, splitter + num + 1);
			// Если в куче только сплиттер
			if (end - begin == num + 1) return node;
			// Подготовка к разделению
			var normalX:Number = normals[ni++], normalY:Number = normals[ni++], normalZ:Number = normals[ni++], offset:Number = normals[ni];
			var reserve:int = end - begin + ((end - begin) >> 2);
			var negativeBegin:int = fragmentsLength, negativeEnd:int = negativeBegin, positiveBegin:int = fragmentsLength + reserve, positiveEnd:int = positiveBegin;
			if ((fragmentsLength = positiveBegin + reserve) > fragmentsRealLength) fragments.length = fragmentsRealLength = fragmentsLength;
			// Перебираем грани
			for (var i:int = begin, j1:int = negativeEnd, j2:int = positiveEnd, k:int = begin, vi:int = numVertices*3, vj:int = numVertices << 1, infront:Boolean, behind:Boolean, t:Number, uv:Number; i < end;) {
				if (i == k) {
					// Пропуск сплиттера
					if (i == splitter) {
						i += (fragments[i] & 0xFFFF) + 1;
						if (i == end) break;
					}
					// Подготовка к разбиению
					mi = fragments[i], ni = mi >> 16, num = mi & 0xFFFF, k = num + ++i, j1++, j2++, infront = false, behind = false;
					// Первая точка ребра
					var a:int = fragments[int(k - 1)], ai:int = a*3;
					var ax:Number = vertices[ai], ay:Number = vertices[int(ai + 1)], az:Number = vertices[int(ai + 2)];
					var ao:Number = ax*normalX + ay*normalY + az*normalZ - offset;
				}
				// Вторая точка ребра
				var b:int = fragments[i], bi:int = b*3;
				var bx:Number = vertices[bi], by:Number = vertices[int(bi + 1)], bz:Number = vertices[int(bi + 2)];
				var bo:Number = bx*normalX + by*normalY + bz*normalZ - offset;
				// Рассечение ребра
				if (ao < -threshold && bo > threshold || bo < -threshold && ao > threshold) t = ao/(ao - bo), vertices[vi] = ax + (bx - ax)*t, uvts[vi++] = uvs[vj++] = (uv = uvts[ai]) + (uvts[bi] - uv)*t, vertices[vi] = ay + (by - ay)*t, uvts[vi++] = uvs[vj++] = (uv = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - uv)*t, vertices[vi] = az + (bz - az)*t, uvts[vi++] = 0, fragments[j1++] = fragments[j2++] = numVertices++;
				// Добавление точки
				if (bo < -threshold) {
					fragments[j1++] = b, behind = true;
				} else if (bo > threshold) {
					fragments[j2++] = b, infront = true;
				} else {
					fragments[j1++] = fragments[j2++] = b;
				}
				// Анализ разбиения
				if (++i == k) {
					if (infront && behind) {
						// Фрагмент распилился
						fragments[negativeEnd] = (ni << 16) + j1 - negativeEnd - 1, negativeEnd = j1;
						fragments[positiveEnd] = (ni << 16) + j2 - positiveEnd - 1, positiveEnd = j2;
					} else if (infront) {
						// Фрагмент спереди
						fragments[positiveEnd] = (ni << 16) + j2 - positiveEnd - 1, positiveEnd = j2, j1 = negativeEnd;
					} else if (behind || normalX*normals[ni] + normalY*normals[int(ni + 1)] + normalZ*normals[int(ni + 2)] < 0) {
						// Фрагмент сзади или противонаправлен ноде
						fragments[negativeEnd] = (ni << 16) + j1 - negativeEnd - 1, negativeEnd = j1, j2 = positiveEnd;
					} else {
						// Фрагмент в плоскости ноды и сонаправлен с ней
						node.addFragment(fragments, k - num, k);
						j1 = negativeEnd, j2 = positiveEnd;
					}
				} else {
					a = b, ai = bi, ax = bx, ay = by, az = bz, ao = bo;
				}
			}
			// Разделение заднй части
			if (negativeEnd > negativeBegin) node.negative = split(negativeBegin, negativeEnd, splitAnalysis ? findSplitter(negativeBegin, negativeEnd) : negativeBegin, splitAnalysis);
			// Разделение передней части
			if (positiveEnd > positiveBegin) node.positive = split(positiveBegin, positiveEnd, splitAnalysis ? findSplitter(positiveBegin, positiveEnd) : positiveBegin, splitAnalysis);
			return node;
		}
		
		private function findSplitter(begin:int, end:int):int {
			var splitter:int, bestSplits:int = int.MAX_VALUE;
			// Перебираем нормали
			for (var i:int = begin, vi:int; i < end; i += (mi & 0xFFFF) + 1) {
				var currentSplits:int = 0, mi:int = fragments[i], ni:int = mi >> 16, normalX:Number = normals[ni++], normalY:Number = normals[ni++], normalZ:Number = normals[ni++], offset:Number = normals[ni];
				// Перебираем точки граней
				for (var j:int = begin, k:int = begin, num:int, infront:Boolean, behind:Boolean; j < end;) {
					if (j == k) k = (fragments[j] & 0xFFFF) + ++j, infront = false, behind = false;
					var o:Number = vertices[vi = int(fragments[j]*3)]*normalX + vertices[++vi]*normalY + vertices[++vi]*normalZ - offset;
					if (o < -threshold) {
						behind = true;
						if (infront) j = k - 1;
					} else if (o > threshold) {
						infront = true;
						if (behind) j = k - 1;
					}
					if (++j == k) {
						if (behind && infront) {
							currentSplits++;
							if (currentSplits >= bestSplits) break;
						}
					}
				}
				// Если найдена плоскость лучше текущей
				if (currentSplits < bestSplits) {
					splitter = i, bestSplits = currentSplits;
					// Если плоскость ничего не распиливает
					if (bestSplits == 0) break;
				}
			}
			return splitter;
		}
		
		override public function calculateBoundBox(matrix:Matrix3D = null, boundBox:BoundBox = null):BoundBox {
			var v:Vector.<Number> = vertices;
			// Если указана матрица трансформации, переводим
			if (matrix != null) {
				matrix.transformVectors(vertices, cameraVertices);
				v = cameraVertices;
			}
			// Если указан баунд-бокс
			if (boundBox != null) {
				boundBox.infinity();
			} else {
				boundBox = new BoundBox();
			}
			// Ищем баунд-бокс
			for (var i:int = 0, length:int = numVertices*3; i < length;) {
				boundBox.addPoint(v[i++], v[i++], v[i++]);
			}
			return boundBox;
		}
/*		
		public function calculateRadius(axis:Vector3D):Number {
			var i:int, length:int = vertices.length, c:Number, radius:Number, maxRadius:Number;
			if (axis == Vector3D.X_AXIS) {
				
			} else if (axis == Vector3D.Y_AXIS) {
				
			} else if (axis == Vector3D.Z_AXIS) {
				for (i = 0; i < length; i++) {
					if ((radius = (c = vertices[i++])*c + (c = vertices[i++])*c) > maxRadius) maxRadius = radius;
				}
			}
			return Math.sqrt(maxRadius);
		}
*/		
		/**
		 * Копирование свойств другого меша. Осторожно, свойства будут иметь прямые ссылки на свойства копируемого меша.
		 * @param mesh Объект копирования
		 */
		public function copyFrom(mesh:Mesh):void {
			
			alpha = mesh.alpha;
			blendMode = mesh.blendMode;
			
			poly = mesh.poly;
			
			numVertices = mesh.numVertices;
			numFaces = mesh.numFaces;
			vertices = mesh.vertices;
			indices = mesh.indices;
			uvts = mesh.uvts;
			uvs = mesh.uvs;
			
			texture = mesh.texture;
			mipMap = mesh.mipMap;

			smooth = mesh.smooth;
			repeatTexture = mesh.repeatTexture;
			perspectiveCorrection = mesh.perspectiveCorrection;
			
			backfaceCulling = mesh.backfaceCulling;
			clipping = mesh.clipping;
			sorting = mesh.sorting;
			mipMapping = mesh.mipMapping;
			
			matrix.identity();
			matrix.prepend(mesh.matrix);
			if (_boundBox != null) {
				_boundBox.copyFrom(mesh._boundBox);
			} else {
				_boundBox = mesh._boundBox;
			}
			
			normals = mesh.normals;
			bsp = mesh.bsp;
		}
		
		public function generateClass(className:String = "GeneratedMesh", packageName:String = "", textureName:String = null):String {
			
			var header:String = "package" + ((packageName != "") ? (" " + packageName + " ") : " ") + "{\r\r";
			
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
			
			constructor += "\t\t\tuvs = Vector.<Number>([";
			length = numVertices << 1;
			n = 0;
			for (i = 0; i < length; i++) {
				constructor += uvs[i];
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
			constructor += "\t\t\tperspectiveCorrection = " + (perspectiveCorrection ? "true" : "false") +";\r";
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

			return header + imports + classHeader + embeds + constructor + footer;
		}
		
		// Объединение вершин
		/**
		 * Объединение вершин с одинаковыми координатами 
		 * @param distanceThreshold Погрешность, в пределах которой координаты считаются одинаковыми
		 * @param uvThreshold Погрешность, в пределах которой UV-координаты считаются одинаковыми
		 */
		public function weldVertices(distanceThreshold:Number = 0, uvThreshold:Number = 0):void {
			var i:int, j:int, k:int, t:int;
			
			// Карта соответствий
			var weld:Vector.<int> = new Vector.<int>(numVertices = vertices.length/3);
			for (i = 0; i < numVertices; i++) weld[i] = i;
			
			// Ненужные индексы
			var uselessIndices:Vector.<int> = new Vector.<int>();
			var numUselessIndices:uint = 0;
			
			// Сравнение вершин по координатам и UV
			for (i = 0; i < numVertices - 1; i++) {
				if (weld[i] == i) {
					var ax:Number = vertices[k = i*3];
					var ay:Number = vertices[k + 1];
					var az:Number = vertices[k + 2];
					var au:Number = uvts[k];
					var av:Number = uvts[k + 1];
					for (j = i + 1; j < numVertices; j++) {
						if (weld[j] == j) {
							var bx:Number = vertices[k = j*3];
							var by:Number = vertices[k + 1];
							var bz:Number = vertices[k + 2];
							var bu:Number = uvts[k];
							var bv:Number = uvts[k + 1];
							if ((ax - bx <= distanceThreshold) && (ax - bx >= -distanceThreshold) && (ay - by <= distanceThreshold) && (ay - by >= -distanceThreshold) && (az - bz <= distanceThreshold) && (az - bz >= -distanceThreshold) && (au - bu <= uvThreshold) && (au - bu >= -uvThreshold) && (av - bv <= uvThreshold) && (av - bv >= -uvThreshold)) {
								weld[j] = i;
								uselessIndices[numUselessIndices++] = j;
							}
						}
					}
				}
			}
			
			// Удаление ненужных вершин и UV
			for (i = 0, j = 0; j < numVertices; j++) {
				if (weld[j] == j) {
					if (i != j) {
						vertices[k = i*3] = vertices[t = j*3];
						vertices[k + 1] = vertices[t + 1];
						vertices[k + 2] = vertices[t + 2];
						uvts[k] = uvts[t];
						uvts[k + 1] = uvts[t + 1];
						uvs[k = i*2] = uvs[t = j*2];
						uvs[k + 1] = uvs[t + 1];
					}
					i++;
				}
			}
			vertices.length = i*3;
			uvts.length = i*3;
			uvs.length = i*2;
			numVertices = i;

			// Корректировка индексов
			uselessIndices.sort(function compare(x:int, y:int):Number {return x - y;});
			var numIndices:int = indices.length;
			for (i = 0, j = 0; i < numIndices; i++) {
				j = (poly && i == j) ? (indices[i++] + i) : j;
				k = t = weld[indices[i]];
				for (var u:int = 0; u < numUselessIndices; u++) {
					if (k > uselessIndices[u]) {
						t--;
					} else {
						break;
					}
				}
				indices[i] = t;
			}
		}
		
		/**
		 * Объединение треугольников в многоугольники
		 * После вызова этого метода флаг poly становится true
		 * @param angleThreshold Допустимый угол в радианах между нормалями, чтобы считать, что объединяемые грани в одной плоскости
		 * @param uvThreshold Допустимая разница uv-координат, чтобы считать, что объединяемые грани состыковываются по UV
		 * @param convexThreshold Величина, уменьшающая допустимый угол между смежными рёбрами объединяемых граней
		 */
		public function convertToPoly(angleThreshold:Number = 0, uvThreshold:Number = 0, convexThreshold:Number = 0):void {

			if (poly) return;
			
			var digitThreshold:Number = 0.001;
			angleThreshold = Math.cos(angleThreshold) - digitThreshold;
			uvThreshold += digitThreshold;
			convexThreshold = Math.cos(Math.PI - convexThreshold) - digitThreshold;
			
			var i:int, j:int, n:int, k:int, t:int;
			
			// Вспомогательные флаги
			var contains:Vector.<int> = new Vector.<int>(numFaces = indices.length/3);
			
			// Расчёт нормалей и матриц uv-трансформации
			var normals:Vector.<Number> = new Vector.<Number>(numFaces*3);
			var matrices:Vector.<Number> = new Vector.<Number>(numFaces*8);
			for (i = 0; i < numFaces; i++) {
				// Нахождение нормали
				var ax:Number = vertices[k = indices[t = i*3]*3];
				var ay:Number = vertices[k + 1];
				var az:Number = vertices[k + 2];
				var au:Number = uvts[k];
				var av:Number = uvts[k + 1];
				var abx:Number = vertices[k = indices[t + 1]*3] - ax;
				var aby:Number = vertices[k + 1] - ay;
				var abz:Number = vertices[k + 2] - az;
				var abu:Number = uvts[k] - au;
				var abv:Number = uvts[k + 1] - av;
				var acx:Number = vertices[k = indices[t + 2]*3] - ax;
				var acy:Number = vertices[k + 1] - ay;
				var acz:Number = vertices[k + 2] - az;
				var acu:Number = uvts[k] - au;
				var acv:Number = uvts[k + 1] - av;
				var nx:Number = acz*aby - acy*abz;
				var ny:Number = acx*abz - acz*abx;
				var nz:Number = acy*abx - acx*aby;
				var nl:Number = Math.sqrt(nx*nx + ny*ny + nz*nz);
				// Если грань не вырождена
				if (nl > digitThreshold) {
					contains[i] = 1;
					// Нормализация и сохранение нормали
					normals[t] = nx /= nl;
					normals[t + 1] = ny /= nl;
					normals[t + 2] = nz /= nl;
					// Нахождение обратной матрицы грани
					var det:Number = -nx*acy*abz + acx*ny*abz + nx*aby*acz - abx*ny*acz - acx*aby*nz + abx*acy*nz;
					var ma:Number = (-ny*acz + acy*nz)/det;
					var mb:Number = (nx*acz - acx*nz)/det;
					var mc:Number = (-nx*acy + acx*ny)/det;
					var md:Number = (ax*ny*acz - nx*ay*acz - ax*acy*nz + acx*ay*nz + nx*acy*az - acx*ny*az)/det;
					var me:Number = (ny*abz - aby*nz)/det;
					var mf:Number = (-nx*abz + abx*nz)/det;
					var mg:Number = (nx*aby - abx*ny)/det;
					var mh:Number = (nx*ay*abz - ax*ny*abz + ax*aby*nz - abx*ay*nz - nx*aby*az + abx*ny*az)/det;
					// Умножение прямой uv-матрицы на обратную матрицу грани и сохранение матрицы uv-трансформации
					matrices[t = i*8] = abu*ma + acu*me;
					matrices[t + 1] = abu*mb + acu*mf;
					matrices[t + 2] = abu*mc + acu*mg;
					matrices[t + 3] = abu*md + acu*mh + au;
					matrices[t + 4] = abv*ma + acv*me;
					matrices[t + 5] = abv*mb + acv*mf;
					matrices[t + 6] = abv*mc + acv*mg;
					matrices[t + 7] = abv*md + acv*mh + av;
				}
			} 
			
			// Разбиение граней на группы по углу, UV и соседству
			var islands:Vector.<Vector.<Vector.<int>>> = new Vector.<Vector.<Vector.<int>>>();
			var numIslands:int = 0;
			var island:Vector.<Vector.<int>>;
			var islandLength:int;
			var f:Vector.<int>, fLen:int, fi:int, fj:int;
			var s:Vector.<int>, sLen:int, si:int, sj:int;
			for (i = 0; i < numFaces; i++) {
				if (contains[i] > 0) {
					contains[i] = 0;
					// Создание группы
					island = new Vector.<Vector.<int>>();
					islands[numIslands] = island;
					// Создание грани и добавление в группу
					f = new Vector.<int>(3);
					f[0] = indices[k = i*3];
					f[1] = indices[k + 1];
					f[2] = indices[k + 2];
					island[0] = f;
					islandLength = 1;
					normals[t = numIslands++*3] = nx = normals[k = i*3];
					normals[t + 1] = ny = normals[k + 1];
					normals[t + 2] = nz = normals[k + 2];
					ma = matrices[k = i*8];
					mb = matrices[k + 1];
					mc = matrices[k + 2];
					md = matrices[k + 3];
					me = matrices[k + 4];
					mf = matrices[k + 5];
					mg = matrices[k + 6];
					mh = matrices[k + 7];
					// Перебор и дополнение группы
					for (n = 0; n < islandLength; n++) {
						f = island[n];
						var a1:int = f[0];
						var b1:int = f[1];
						var c1:int = f[2];
						for (j = i + 1; j < numFaces; j++) {
							if (contains[j] > 0) {
								// Если грани сонаправлены
								if (nx*normals[k = j*3] + ny*normals[k + 1] + nz*normals[k + 2] >= angleThreshold) {
									var a2:int = indices[k];
									var b2:int = indices[k + 1];
									var c2:int = indices[k + 2];
									// Если грани соседние
									if ((k = (a1 == c2 && b1 == b2 || b1 == c2 && c1 == b2 || c1 == c2 && a1 == b2) ? a2 : ((a1 == a2 && b1 == c2 || b1 == a2 && c1 == c2 || c1 == a2 && a1 == c2) ? b2 : ((a1 == b2 && b1 == a2 || b1 == b2 && c1 == a2 || c1 == b2 && a1 == a2) ? c2 : -1))) >= 0) {
										ax = vertices[k *= 3];
										ay = vertices[k + 1];
										az = vertices[k + 2];
										au = uvts[k];
										av = uvts[k + 1];
										var bu:Number = ma*ax + mb*ay + mc*az + md;
										var bv:Number = me*ax + mf*ay + mg*az + mh;
										// Если совпадают по UV
										if ((au - bu <= uvThreshold) && (au - bu >= -uvThreshold) && (av - bv <= uvThreshold) && (av - bv >= -uvThreshold)) {
											contains[j] = 0;
											s = new Vector.<int>(3);
											s[0] = a2;
											s[1] = b2;
											s[2] = c2;
											island[islandLength++] = s;
										}
									}
								}
							}
						}
					}
				}
			}
			
			poly = true;
			numFaces = 0;
			
			// Объединение
			var numIndices:int = 0;
			var faces1:Vector.<Vector.<int>> = new Vector.<Vector.<int>>();
			var faces2:Vector.<Vector.<int>> = new Vector.<Vector.<int>>();
			for (n = 0; n < numIslands; n++) {
				island = islands[n];
				islandLength = island.length;
				nx = normals[k = n*3];
				ny = normals[k + 1];
				nz = normals[k + 2];
				// Дополнение вспомогательных списков, если нужно
				for (i = faces1.length; i < islandLength; i++) {
					faces1[i] = new Vector.<int>();
					faces2[i] = new Vector.<int>();
				}
				var numFaces1:int = islandLength;
				var numFaces2:int = 0;
				// Копирование граней из группы в первый список
				for (i = 0; i < islandLength; i++) {
					f = island[i];
					fLen = f.length;
					s = faces1[i];
					for (j = 0; j < fLen; j++) s[j] = f[j];
					s.length = fLen;
				}
				// Объединение
				do {
					// Подготовка к итерации
					var weld:Boolean = false;
					for (i = 0; i < numFaces1; i++) contains[i] = 1;
					// Попытки объединить текущую грань со всеми следующими 
					for (i = 0; i < numFaces1; i++) {
						if (contains[i] > 0) {
							f = faces1[i];
							fLen = f.length;
							for (j = i + 1; j < numFaces1; j++) {
								if (contains[j] > 0) {
									s = faces1[j];
									sLen = s.length;
									// Проверка на соседство
									for (fi = 0; fi < fLen; fi++) {
										a1 = f[fi];
										b1 = f[fj = (fi < fLen - 1) ? (fi + 1) : 0];
										for (si = 0; si < sLen; si++) {
											a2 = s[si];
											b2 = s[sj = (si < sLen - 1) ? (si + 1) : 0];
											if (a1 == b2 && b1 == a2) break;
										}
										if (si < sLen) break;
									}
									// Если грань соседняя
									if (fi < fLen) {
										// Расширение граней объединеия
										while (true) {
											fj = (fj < fLen - 1) ? (fj + 1) : 0;
											si = (si > 0) ? (si - 1) : (sLen - 1);
											b2 = f[fj];
											c2 = s[si];
											if (b2 == c2) a2 = c2 else break;
										}
										while (true) {
											sj = (sj < sLen - 1) ? (sj + 1) : 0;
											fi = (fi > 0) ? (fi - 1) : (fLen - 1);
											b1 = s[sj];
											c1 = f[fi];
											if (b1 == c1) a1 = c1 else break;
										}
										// Первый перегиб
										ax = vertices[k = a1*3];
										ay = vertices[k + 1];
										az = vertices[k + 2];
										abx = vertices[k = b1*3] - ax;
										aby = vertices[k + 1] - ay;
										abz = vertices[k + 2] - az;
										acx = vertices[k = c1*3] - ax;
										acy = vertices[k + 1] - ay;
										acz = vertices[k + 2] - az;
										var crx:Number = aby*acz - abz*acy;
										var cry:Number = abz*acx - abx*acz;
										var crz:Number = abx*acy - aby*acx;
										var zeroCross:Boolean = crx < digitThreshold && crx > -digitThreshold && cry < digitThreshold && cry > -digitThreshold && crz < digitThreshold && crz > -digitThreshold;
										if (zeroCross && abx*acx + aby*acy + abz*acz > 0 || !zeroCross && nx*crx + ny*cry + nz*crz < 0) continue;
										nl = 1/Math.sqrt(abx*abx + aby*aby + abz*abz);
										abx *= nl; aby *= nl; abz *= nl;
										nl = 1/Math.sqrt(acx*acx + acy*acy + acz*acz);
										acx *= nl; acy *= nl; acz *= nl;
										if (abx*acx + aby*acy + abz*acz < convexThreshold) continue;
										// Второй перегиб
										ax = vertices[k = a2*3];
										ay = vertices[k + 1];
										az = vertices[k + 2];
										abx = vertices[k = b2*3] - ax;
										aby = vertices[k + 1] - ay;
										abz = vertices[k + 2] - az;
										acx = vertices[k = c2*3] - ax;
										acy = vertices[k + 1] - ay;
										acz = vertices[k + 2] - az;
										crx = aby*acz - abz*acy;
										cry = abz*acx - abx*acz;
										crz = abx*acy - aby*acx;
										zeroCross = crx < digitThreshold && crx > -digitThreshold && cry < digitThreshold && cry > -digitThreshold && crz < digitThreshold && crz > -digitThreshold;
										if (zeroCross && abx*acx + aby*acy + abz*acz > 0 || !zeroCross && nx*crx + ny*cry + nz*crz < 0) continue;
										nl = 1/Math.sqrt(abx*abx + aby*aby + abz*abz);
										abx *= nl; aby *= nl; abz *= nl;
										nl = 1/Math.sqrt(acx*acx + acy*acy + acz*acz);
										acx *= nl; acy *= nl; acz *= nl;
										if (abx*acx + aby*acy + abz*acz < convexThreshold) continue;
										// Объединение
										var fs:Vector.<int> = faces2[numFaces2++];
										var fsLen:int = 0;
										fs[fsLen++] = a2;
										while (true) {
											fs[fsLen++] = f[fj];
											if (fj != fi) fj = (fj < fLen - 1) ? (fj + 1) : 0 else break;
										}
										fs[fsLen++] = a1;
										while (true) {
											fs[fsLen++] = s[sj];
											if (sj != si) sj = (sj < sLen - 1) ? (sj + 1) : 0 else break;
										}
										fs.length = fsLen;
										contains[j] = 0;
										weld = true;
										break;
									}
								}
							}
							// Если не было объединения
							if (j == numFaces1) {
								s = faces2[numFaces2++];
								for (fi = 0; fi < fLen; fi++) s[fi] = f[fi];
								s.length = fLen;
							}
						}
					}
					// Переброс списков
					island = faces1;
					faces1 = faces2;
					numFaces1 = numFaces2;
					faces2 = island;
					numFaces2 = 0;
				} while (weld);
				// Запись индексов в полигональной форме
				for (i = 0; i < numFaces1; i++) {
					f = faces1[i];
					fLen = f.length;
					indices[numIndices++] = fLen;
					if (fLen > 3) {
						// Определение наилучшей последовательности
						var max:Number = -Number.MAX_VALUE;
						for (fi = 0; fi < fLen; fi++) {
							ax = vertices[k = f[fi]*3];
							ay = vertices[k + 1];
							az = vertices[k + 2];
							abx = vertices[k = f[fj = (fi < fLen - 1) ? (fi + 1) : 0]*3] - ax;
							aby = vertices[k + 1] - ay;
							abz = vertices[k + 2] - az;
							acx = vertices[k = f[(fj < fLen - 1) ? (fj + 1) : 0]*3] - ax;
							acy = vertices[k + 1] - ay;
							acz = vertices[k + 2] - az;
							crx = aby*acz - abz*acy;
							cry = abz*acx - abx*acz;
							crz = abx*acy - aby*acx;
							nl = Math.sqrt(crx*crx + cry*cry + crz*crz);
							if (nl > max) {
								max = nl;
								j = fi;
							}
						}
						for (fi = j; fi < fLen; fi++) indices[numIndices++] = f[fi];
						for (fi = 0; fi < j; fi++) indices[numIndices++] = f[fi];
					} else {
						for (fi = 0; fi < fLen; fi++) indices[numIndices++] = f[fi];
					}
					numFaces++;
				}
			}
			indices.length = numIndices;
		}
		
	}
}
