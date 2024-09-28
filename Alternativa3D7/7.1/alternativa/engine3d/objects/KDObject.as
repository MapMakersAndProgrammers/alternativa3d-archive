package alternativa.engine3d.objects {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BSPNode;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Utils3D;
	import alternativa.engine3d.core.Debug;

	use namespace alternativa3d;
	
	/**
	 * Вспомогательный объект, использующийся для разрещения конфликтов сортировки в KDTree
	 */
	public class KDObject extends Object3D {

		static private const collector:Vector.<KDObject> = new Vector.<KDObject>();
		static private var collectorLength:int = 0;

		static private const verticesMap:Vector.<int> = new Vector.<int>();
		static private const drawIndices:Vector.<int> = new Vector.<int>();
		static private var drawIndicesLength:int;
		static private const drawMatrix:Matrix3D = new Matrix3D();
		
		static private const averageZ:Vector.<Number> = new Vector.<Number>();
		static private const sortingMap:Vector.<int> = new Vector.<int>();
		static private const sortingStack:Vector.<int> = new Vector.<int>();
		
		/**
		 * @private 
		 */
		alternativa3d var vertices:Vector.<Number> = new Vector.<Number>();
		/**
		 * @private 
		 */
		alternativa3d var verticesLength:int;
		/**
		 * @private 
		 */
		alternativa3d var numVertices:int;
		private var projectedVertices:Vector.<Number> = new Vector.<Number>();
		private var uvts:Vector.<Number> = new Vector.<Number>();

		private var indices:Vector.<int> = new Vector.<int>();
		private var indicesLength:int;

		private var bsp:BSPNode;
		private var priority:int;
		
		private var texture:BitmapData;
		private var smooth:Boolean;
		private var repeatTexture:Boolean;
		
		/**
		 * @private 
		 */
		alternativa3d var viewAligned:Boolean;
		private var debugResult:int;
		private var textureMatrix:Matrix = new Matrix();
		private var projectionX:Number;
		private var projectionY:Number;
		private var z:Number;
		
		//private var single:Boolean;
		//private var poly:Boolean;
		//private var perspectiveCorrection:Boolean;
		
		/**
		 * @private 
		 */
		alternativa3d var numCheckedOccluders:int;
		
		public function KDObject() {
			boundBox = new BoundBox();
		}
		
		/**
		 * @private 
		 */
		alternativa3d function create():KDObject {
			return (collectorLength > 0) ? collector[--collectorLength] : new KDObject();
		}
		
		/**
		 * @private 
		 */
		alternativa3d function destroy():void {
			debugResult = 0;
			indicesLength = numVertices = verticesLength = 0;
			texture = null, colorTransform = null;
			if (bsp != null) bsp.destroy(), bsp = null;
			collector[collectorLength++] = this;
		}
		
		/**
		 * @private 
		 */
		static alternativa3d function createFrom(object:Object3D, camera:Camera3D, matrix:Matrix3D = null):KDObject {
			var source:Object3D = object, result:KDObject = (collectorLength > 0) ? collector[--collectorLength] : new KDObject();
			// Поиск оригинального объекта
			while (source is Reference) source = (source as Reference).referenceObject;
			// Дебаг
			if (camera.debugMode) result.debugResult = camera.checkInDebug(source);
			// Меш
			if (source is Mesh) {
				var mesh:Mesh = source as Mesh;
				// Перевод в координаты камеры
				object.cameraMatrix.transformVectors(mesh.vertices, mesh.cameraVertices);
				// Расчёт координат камеры в меше
				mesh.calculateInverseCameraMatrix(object.cameraMatrix);
				// Подготовка к ремапу
				for (var i:int = 0; i < mesh.numVertices;) verticesMap[i++] = -1;
				// Создание BSP-дерева
				if (mesh.bsp != null) {
					result.bsp = result.clipNode(mesh.bsp, mesh, object.culling, camera.nearClipping, camera.farClipping);
					// Установка приоритета
					result.priority = (matrix == null) ? 0 : 1;
				// Сбор полигонов
				} else {
					if (mesh.poly) {
						result.clip(mesh, object.culling, camera.nearClipping, camera.farClipping);
					} else {
						throw new Error("Пока можно использовать только полигональные меши");
					}
					// Установка приоритета
					result.priority = 2;
				}
				// Подрезаем массивы в меше
				if (object.culling > 0) mesh.cameraVertices.length = mesh.uvts.length = mesh.numVertices*3,	mesh.uvs.length = mesh.numVertices << 1;
				// Если объект виден
				if (result.numVertices > 0) {
					// Подрезка вершин
					result.vertices.length = result.verticesLength;
					// Перевод динамика в KD-дерево
					if (matrix != null) {
						// Трансформация вершин в KD-дерево
						matrix.transformVectors(result.vertices, result.vertices);
						// Расчёт баунда в KD-дереве
						var boundBox:BoundBox = result._boundBox;
						boundBox.minX = boundBox.minY = boundBox.minZ = Number.MAX_VALUE;
						boundBox.maxX = boundBox.maxY = boundBox.maxZ = -Number.MAX_VALUE;
						for (var v:int = 0, c:Number; v < result.verticesLength;) {
							if ((c = result.vertices[v++]) < boundBox.minX) boundBox.minX = c;
							if (c > boundBox.maxX) boundBox.maxX = c;
							if ((c = result.vertices[v++]) < boundBox.minY) boundBox.minY = c;
							if (c > boundBox.maxY) boundBox.maxY = c;
							if ((c = result.vertices[v++]) < boundBox.minZ) boundBox.minZ = c;
							if (c > boundBox.maxZ) boundBox.maxZ = c;
						}
					} else if (result.debugResult & Debug.BOUNDS) {
						// Расчёт баунда для отображения конфликтной зоны в дебаге
						var objectInverseCameraMatrix:Matrix3D = Mesh.inverseCameraMatrix.clone();
						objectInverseCameraMatrix.append(object.matrix);
						var vs:Vector.<Number> = new Vector.<Number>();
						objectInverseCameraMatrix.transformVectors(result.vertices, vs);
						boundBox = result._boundBox;
						boundBox.minX = boundBox.minY = boundBox.minZ = Number.MAX_VALUE;
						boundBox.maxX = boundBox.maxY = boundBox.maxZ = -Number.MAX_VALUE;
						for (v = 0; v < result.verticesLength;) {
							if ((c = vs[v++]) < boundBox.minX) boundBox.minX = c;
							if (c > boundBox.maxX) boundBox.maxX = c;
							if ((c = vs[v++]) < boundBox.minY) boundBox.minY = c;
							if (c > boundBox.maxY) boundBox.maxY = c;
							if ((c = vs[v++]) < boundBox.minZ) boundBox.minZ = c;
							if (c > boundBox.maxZ) boundBox.maxZ = c;
						}
					}
					// Копирование свойств меша
					result.texture = (mesh.mipMapping == 0) ? mesh.texture : mesh.getMipTexture(camera, object); 
					result.smooth = mesh.smooth;
					result.repeatTexture = mesh.repeatTexture;
					result.viewAligned = false;
					//res.poly = mesh.poly;
					//res.perspectiveCorrection = mesh.perspectiveCorrection;
				} else {
					result.destroy();
					return null;
				}
			// Спрайт
			} else if (source is Sprite3D) {
				var sprite:Sprite3D = source as Sprite3D;
				// Назначение текстуры для анимированных спрайтов (костыль)
				if (sprite is AnimSprite) {
					var animSprite:AnimSprite = (sprite as AnimSprite);
					if (sprite.mipMapping == 0) sprite.texture = animSprite.textures[animSprite.frame]; else sprite.mipMap = animSprite.mipMaps[animSprite.frame];
				}
				// Вершины спрайта
				var spriteVertices:Vector.<Number> = Sprite3D.vertices;
				var spriteVerticesLength:int = sprite.calculateVertices(object, camera);
				// Если объект виден
				if (spriteVerticesLength > 0) {
					// Подрезка вершин
					spriteVertices.length = spriteVerticesLength;
					// Установка числа вершин
					result.verticesLength = spriteVerticesLength, result.numVertices = spriteVerticesLength/3;
					if (result.uvts.length < spriteVerticesLength) result.uvts.length = spriteVerticesLength;
					// Заполнение индексов
					result.indices[result.indicesLength++] = result.numVertices;
					for (i = 0; i < result.numVertices; i++) result.indices[result.indicesLength++] = i;
					// Копирование параметров
					result.texture = sprite.drawTexture;
					result.smooth = sprite.smooth;
					result.viewAligned = true;
					var m:Matrix = Sprite3D.textureMatrix; result.textureMatrix.a = m.a, result.textureMatrix.b = m.b, result.textureMatrix.c = m.c, result.textureMatrix.d = m.d, result.textureMatrix.tx = m.tx, result.textureMatrix.ty = m.ty;
					result.projectionX = sprite.projectionX;
					result.projectionY = sprite.projectionY;
					result.z = spriteVertices[2];
					// Установка приоритета
					result.priority = 2;
					// Перевод динамика в KD-дерево
					if (matrix != null) matrix.transformVectors(spriteVertices, spriteVertices);
					// Копирование вершин и расчёт баунда в KD-дереве
					boundBox = result._boundBox;
					boundBox.minX = boundBox.minY = boundBox.minZ = Number.MAX_VALUE;
					boundBox.maxX = boundBox.maxY = boundBox.maxZ = -Number.MAX_VALUE;
					for (v = 0; v < spriteVerticesLength;) {
						if ((c = result.vertices[v] = spriteVertices[v++]) < boundBox.minX) boundBox.minX = c;
						if (c > boundBox.maxX) boundBox.maxX = c;
						if ((c = result.vertices[v] = spriteVertices[v++]) < boundBox.minY) boundBox.minY = c;
						if (c > boundBox.maxY) boundBox.maxY = c;
						if ((c = result.vertices[v] = spriteVertices[v++]) < boundBox.minZ) boundBox.minZ = c;
						if (c > boundBox.maxZ) boundBox.maxZ = c;
					}
				} else {
					result.destroy();
					return null;
				}
			// Не меш и не спрайт
			} else {
				result.destroy();
				return null;
			}
			// Копирование общих свойств
			result.alpha = object.alpha;
			result.blendMode = object.blendMode;
			result.colorTransform = object.colorTransform;
			result.filters = object.filters;
			result.numCheckedOccluders = 0;
			return result;
		}
		
		static private const polygon:Vector.<int> = new Vector.<int>();
		private function clip(mesh:Mesh, culling:int, near:Number, far:Number):void {
			var meshVertices:Vector.<Number> = mesh.cameraVertices, meshUVTs:Vector.<Number> = mesh.uvts, polygons:Vector.<int> = mesh.indices, polygonsLength:int = mesh.indices.length;
			var i:int = 0, k:int = 0, n:int, m:int, num1:int, num2:int = 0, vi:int, ni:int = 0;
			var infront:Boolean, behind:Boolean, inside:Boolean;
			for (var v:int = mesh.numVertices; i < polygonsLength; i = k) {
				k = (num1 = polygons[i++]) + i;
				// Отсечение backface
				if (mesh.backfaceCulling == 2) {
					if (mesh.normals[ni++]*mesh.cameraX + mesh.normals[ni++]*mesh.cameraY + mesh.normals[ni++]*mesh.cameraZ <= mesh.normals[ni++]) continue;
				} else {
					var ax:Number = meshVertices[vi = int(polygons[i]*3)], ay:Number = meshVertices[++vi], az:Number = meshVertices[++vi], abx:Number = meshVertices[vi = int(polygons[int(i + 1)]*3)] - ax, aby:Number = meshVertices[++vi] - ay, abz:Number = meshVertices[++vi] - az, acx:Number = meshVertices[vi = int(polygons[int(i + 2)]*3)] - ax, acy:Number = meshVertices[++vi] - ay, acz:Number = meshVertices[++vi] - az;
					if ((acz*aby - acy*abz)*ax + (acx*abz - acz*abx)*ay + (acy*abx - acx*aby)*az >= 0) continue;
				}
				// Отсечение
				if (culling > 0) {
					var insideNear:Boolean = true;
					if (culling & 1) {
						for (n = i; n < k; n++) if ((inside = meshVertices[int(polygons[n]*3 + 2)] > near) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideNear = false;
						infront = false, behind = false;
					}
					var insideFar:Boolean = true;
					if (culling & 2) {
						for (n = i; n < k; n++) if ((inside = meshVertices[int(polygons[n]*3 + 2)] < far) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideFar = false;
						infront = false, behind = false;
					}
					var insideLeft:Boolean = true;
					if (culling & 4) {
						for (n = i; n < k; n++) if ((inside = -meshVertices[vi = int(polygons[n]*3)] < meshVertices[int(vi + 2)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideLeft = false;
						infront = false, behind = false;
					}
					var insideRight:Boolean = true;
					if (culling & 8) {
						for (n = i; n < k; n++) if ((inside = meshVertices[vi = int(polygons[n]*3)] < meshVertices[int(vi + 2)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideRight = false;
						infront = false, behind = false;
					}
					var insideTop:Boolean = true;
					if (culling & 16) {
						for (n = i; n < k; n++) if ((inside = -meshVertices[vi = int(polygons[n]*3 + 1)] < meshVertices[int(vi + 1)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideTop = false;
						infront = false, behind = false;
					}
					var insideBottom:Boolean = true;
					if (culling & 32) {
						for (n = i; n < k; n++) if ((inside = meshVertices[vi = int(polygons[n]*3 + 1)] < meshVertices[int(vi + 1)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
						if (behind) if (!infront) continue; else insideBottom = false;
					}
				}
				// Полное вхождение
				if (culling == 0 || insideNear && insideFar && insideLeft && insideRight && insideTop && insideBottom) {
					// Копирование полигона и ремап
					indices[indicesLength++] = num1;
					for (n = i; n < k; n++) {
						if (verticesMap[m = polygons[n]] < 0) {
							vertices[verticesLength] = meshVertices[vi = int(m*3)],
							uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi];
							indices[indicesLength++] = verticesMap[m] = numVertices++;
						} else {
							indices[indicesLength++] = verticesMap[m];
						}
					}
				} else {
					// Заполняем полигон
					for (n = i; n < k; n++) polygon[n - i] = polygons[n];
					var t:Number, au:Number, av:Number;
					var a:int, b:int, c:int, ai:int, bi:int, bx:Number, by:Number, bz:Number;
					// Клипинг по ниар
					if (!insideNear) {
						a = c = polygon[0],	ai = a*3, az = meshVertices[int(ai + 2)];
						for (n = 1; n <= num1; n++) {
							b = (n < num1) ? polygon[n] : c, bi = b*3, bz = meshVertices[int(bi + 2)];
							if (bz > near && az <= near || bz <= near && az > near) t = (near - az)/(bz - az), polygon[num2++] = v,	meshVertices[vi = int(v++*3)] = (ax = meshVertices[ai]) + (meshVertices[bi] - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = (ay = meshVertices[int(ai + 1)]) + (meshVertices[int(bi + 1)] - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = near, meshUVTs[vi] = 0;
							if (bz > near) polygon[num2++] = b;
							a = b, ai = bi,	az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по фар
					if (!insideFar) {
						a = c = polygon[0],	ai = a*3, az = meshVertices[int(ai + 2)];
						for (n = 1; n <= num1; n++) {
							b = (n < num1) ? polygon[n] : c, bi = b*3, bz = meshVertices[int(bi + 2)];
							if (bz <= far && az > far || bz > far && az <= far) t = (far - az)/(bz - az), polygon[num2++] = v, meshVertices[vi = int(v++*3)] = (ax = meshVertices[ai]) + (meshVertices[bi] - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = (ay = meshVertices[int(ai + 1)]) + (meshVertices[int(bi + 1)] - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t,	meshVertices[vi] = far,	meshUVTs[vi] = 0;
							if (bz <= far) polygon[num2++] = b;
							a = b, ai = bi,	az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по левой стороне
					if (!insideLeft) {
						a = c = polygon[0],	ai = a*3, ax = meshVertices[ai], az = meshVertices[int(ai + 2)];
						for (n = 1; n <= num1; n++) {
							b = (n < num1) ? polygon[n] : c, bi = b*3, bx = meshVertices[bi], bz = meshVertices[int(bi + 2)];
							if (bz > -bx && az <= -ax || bz <= -bx && az > -ax) t = (ax + az)/(ax + az - bx - bz), polygon[num2++] = v,	meshVertices[vi = int(v++*3)] = ax + (bx - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = (ay = meshVertices[int(ai + 1)]) + (meshVertices[int(bi + 1)] - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = az + (bz - az)*t, meshUVTs[vi] = 0;
							if (bz > -bx) polygon[num2++] = b;
							a = b, ai = bi,	ax = bx, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по правой стороне
					if (!insideRight) {
						a = c = polygon[0],	ai = a*3, ax = meshVertices[ai], az = meshVertices[int(ai + 2)];
						for (n = 1; n <= num1; n++) {
							b = (n < num1) ? polygon[n] : c, bi = b*3, bx = meshVertices[bi], bz = meshVertices[int(bi + 2)];
							if (bz > bx && az <= ax || bz <= bx && az > ax) t = (az - ax)/(az - ax + bx - bz), polygon[num2++] = v, meshVertices[vi = int(v++*3)] = ax + (bx - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = (ay = meshVertices[int(ai + 1)]) + (meshVertices[int(bi + 1)] - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = az + (bz - az)*t, meshUVTs[vi] = 0;
							if (bz > bx) polygon[num2++] = b;
							a = b, ai = bi,	ax = bx, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по верхней стороне
					if (!insideTop) {
						a = c = polygon[0],	ai = a*3, ay = meshVertices[int(ai + 1)], az = meshVertices[int(ai + 2)];
						for (n = 1; n <= num1; n++) {
							b = (n < num1) ? polygon[n] : c, bi = b*3, by = meshVertices[int(bi + 1)], bz = meshVertices[int(bi + 2)];
							if (bz > -by && az <= -ay || bz <= -by && az > -ay) t = (ay + az)/(ay + az - by - bz), polygon[num2++] = v, meshVertices[vi = int(v++*3)] = (ax = meshVertices[ai]) + (meshVertices[bi] - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = ay + (by - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = az + (bz - az)*t, meshUVTs[vi] = 0;
							if (bz > -by) polygon[num2++] = b;
							a = b, ai = bi,	ay = by, az = bz;
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Клипинг по нижней стороне
					if (!insideBottom) {
						a = c = polygon[0],	ai = a*3, ay = meshVertices[int(ai + 1)], az = meshVertices[int(ai + 2)];
						for (n = 1; n <= num1; n++) {
							b = (n < num1) ? polygon[n] : c, bi = b*3, by = meshVertices[int(bi + 1)], bz = meshVertices[int(bi + 2)];
						  	if (bz > by && az <= ay || bz <= by && az > ay) t = (az - ay)/(az - ay + by - bz), polygon[num2++] = v, meshVertices[vi = int(v++*3)] = (ax = meshVertices[ai]) + (meshVertices[bi] - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = ay + (by - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = az + (bz - az)*t, meshUVTs[vi] = 0;
							if (bz > by) polygon[num2++] = b;
							a = b, ai = bi,	ay = by, az = bz;
							
						}
						if (num2 == 0) continue;
						num1 = num2, num2 = 0;
					}
					// Копирование полигона и ремап
					indices[indicesLength++] = num1;
					for (n = 0; n < num1; n++) {
						if ((m = polygon[n]) < mesh.numVertices) {
							if (verticesMap[m] < 0) {
								vertices[verticesLength] = meshVertices[vi = int(m*3)],	uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi];
								indices[indicesLength++] = verticesMap[m] = numVertices++;
							} else {
								indices[indicesLength++] = verticesMap[m];
							}
						} else {
							vertices[verticesLength] = meshVertices[vi = int(m*3)], uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi];
							indices[indicesLength++] = numVertices++;
						}
					}
				}
			}
		}
		
		static private var newNode:BSPNode = BSPNode.create();
		private function clipNode(node:BSPNode, mesh:Mesh, culling:int, near:Number, far:Number):BSPNode {
			if (node != null) {
				// Проход по дочерним нодам
				var negative:BSPNode = clipNode(node.negative, mesh, culling, near, far);
				var positive:BSPNode = clipNode(node.positive, mesh, culling, near, far);
				// Определение положения камеры
				var cameraInfront:Boolean = mesh.cameraX*node.normalX + mesh.cameraY*node.normalY + mesh.cameraZ*node.normalZ > node.offset;
				var meshVertices:Vector.<Number> = mesh.cameraVertices, meshUVTs:Vector.<Number> = mesh.uvts, polygons:Vector.<int> = node.polygons, polygonsLength:int = node.polygonsLength, newPolygons:Vector.<int> = newNode.polygons;
				// Если камера спереди
				if (cameraInfront) {
					var i:int = 0, j:int = 0, k:int = 0, n:int, m:int, num1:int, num2:int = 0, vi:int;
					var infront:Boolean, behind:Boolean, inside:Boolean;
					// Если объект виден целиком
					if (culling == 0) {
						// Копирование полигонов и ремап
						for (; i < polygonsLength; i++) {
							if (i == k) num1 = polygons[i++], newPolygons[j++] = num1, k = num1 + i;
							if (verticesMap[m = polygons[i]] < 0) {
								vertices[verticesLength] = meshVertices[vi = int(m*3)],	uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi],
								uvts[verticesLength++] = meshUVTs[vi];
								newPolygons[j++] = verticesMap[m] = numVertices++;
							} else {
								newPolygons[j++] = verticesMap[m];
							}
						}
					} else {
						// Клиппинг
						for (var v:int = mesh.numVertices; i < polygonsLength; i = k) {
							k = (num1 = polygons[i++]) + i;
							// Отсечение
							var insideNear:Boolean = true;
							if (culling & 1) {
								for (n = i; n < k; n++) if ((inside = meshVertices[int(polygons[n]*3 + 2)] > near) && (infront = true) && behind || !inside && (behind = true) && infront) break;
								if (behind) if (!infront) continue; else insideNear = false;
								infront = false, behind = false;
							}
							var insideFar:Boolean = true;
							if (culling & 2) {
								for (n = i; n < k; n++) if ((inside = meshVertices[int(polygons[n]*3 + 2)] < far) && (infront = true) && behind || !inside && (behind = true) && infront) break;
								if (behind) if (!infront) continue; else insideFar = false;
								infront = false, behind = false;
							}	
							var insideLeft:Boolean = true;
							if (culling & 4) {
								for (n = i; n < k; n++) if ((inside = -meshVertices[vi = int(polygons[n]*3)] < meshVertices[int(vi + 2)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
								if (behind) if (!infront) continue; else insideLeft = false;
								infront = false, behind = false;
							}	
							var insideRight:Boolean = true;
							if (culling & 8) {
								for (n = i; n < k; n++) if ((inside = meshVertices[vi = int(polygons[n]*3)] < meshVertices[int(vi + 2)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
								if (behind) if (!infront) continue; else insideRight = false;
								infront = false, behind = false;
							}	
							var insideTop:Boolean = true;
							if (culling & 16) {
								for (n = i; n < k; n++) if ((inside = -meshVertices[vi = int(polygons[n]*3 + 1)] < meshVertices[int(vi + 1)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
								if (behind) if (!infront) continue; else insideTop = false;
								infront = false, behind = false;
							}	
							var insideBottom:Boolean = true;
							if (culling & 32) {
								for (n = i; n < k; n++) if ((inside = meshVertices[vi = int(polygons[n]*3 + 1)] < meshVertices[int(vi + 1)]) && (infront = true) && behind || !inside && (behind = true) && infront) break;
								if (behind) if (!infront) continue; else insideBottom = false;
							}	
							// Полное вхождение
							if (insideNear && insideFar && insideLeft && insideRight && insideTop && insideBottom) {
								// Копирование полигона и ремап
								newPolygons[j++] = num1;
								for (n = i; n < k; n++) {
									if (verticesMap[m = polygons[n]] < 0) {
										vertices[verticesLength] = meshVertices[vi = int(m*3)],
										uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi];
										newPolygons[j++] = verticesMap[m] = numVertices++;
									} else {
										newPolygons[j++] = verticesMap[m];
									}
								}
							} else {
								// Заполняем полигон
								for (n = i; n < k; n++) polygon[n - i] = polygons[n];
								var t:Number, au:Number, av:Number;
								var a:int, b:int, c:int, ai:int, bi:int, ax:Number, ay:Number, az:Number, bx:Number, by:Number, bz:Number;
								// Клипинг по ниар
								if (!insideNear) {
									a = c = polygon[0],	ai = a*3, az = meshVertices[int(ai + 2)];
									for (n = 1; n <= num1; n++) {
										b = (n < num1) ? polygon[n] : c, bi = b*3, bz = meshVertices[int(bi + 2)];
										if (bz > near && az <= near || bz <= near && az > near) t = (near - az)/(bz - az), polygon[num2++] = v,	meshVertices[vi = int(v++*3)] = (ax = meshVertices[ai]) + (meshVertices[bi] - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = (ay = meshVertices[int(ai + 1)]) + (meshVertices[int(bi + 1)] - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = near, meshUVTs[vi] = 0;
										if (bz > near) polygon[num2++] = b;
										a = b, ai = bi,	az = bz;
									}
									if (num2 == 0) continue;
									num1 = num2, num2 = 0;
								}
								// Клипинг по фар
								if (!insideFar) {
									a = c = polygon[0],	ai = a*3, az = meshVertices[int(ai + 2)];
									for (n = 1; n <= num1; n++) {
										b = (n < num1) ? polygon[n] : c, bi = b*3, bz = meshVertices[int(bi + 2)];
										if (bz <= far && az > far || bz > far && az <= far) t = (far - az)/(bz - az), polygon[num2++] = v, meshVertices[vi = int(v++*3)] = (ax = meshVertices[ai]) + (meshVertices[bi] - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = (ay = meshVertices[int(ai + 1)]) + (meshVertices[int(bi + 1)] - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t,	meshVertices[vi] = far,	meshUVTs[vi] = 0;
										if (bz <= far) polygon[num2++] = b;
										a = b, ai = bi,	az = bz;
									}
									if (num2 == 0) continue;
									num1 = num2, num2 = 0;
								}
								// Клипинг по левой стороне
								if (!insideLeft) {
									a = c = polygon[0],	ai = a*3, ax = meshVertices[ai], az = meshVertices[int(ai + 2)];
									for (n = 1; n <= num1; n++) {
										b = (n < num1) ? polygon[n] : c, bi = b*3, bx = meshVertices[bi], bz = meshVertices[int(bi + 2)];
										if (bz > -bx && az <= -ax || bz <= -bx && az > -ax) t = (ax + az)/(ax + az - bx - bz), polygon[num2++] = v,	meshVertices[vi = int(v++*3)] = ax + (bx - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = (ay = meshVertices[int(ai + 1)]) + (meshVertices[int(bi + 1)] - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = az + (bz - az)*t, meshUVTs[vi] = 0;
										if (bz > -bx) polygon[num2++] = b;
										a = b, ai = bi,	ax = bx, az = bz;
									}
									if (num2 == 0) continue;
									num1 = num2, num2 = 0;
								}
								// Клипинг по правой стороне
								if (!insideRight) {
									a = c = polygon[0],	ai = a*3, ax = meshVertices[ai], az = meshVertices[int(ai + 2)];
									for (n = 1; n <= num1; n++) {
										b = (n < num1) ? polygon[n] : c, bi = b*3, bx = meshVertices[bi], bz = meshVertices[int(bi + 2)];
										if (bz > bx && az <= ax || bz <= bx && az > ax) t = (az - ax)/(az - ax + bx - bz), polygon[num2++] = v, meshVertices[vi = int(v++*3)] = ax + (bx - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = (ay = meshVertices[int(ai + 1)]) + (meshVertices[int(bi + 1)] - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = az + (bz - az)*t, meshUVTs[vi] = 0;
										if (bz > bx) polygon[num2++] = b;
										a = b, ai = bi,	ax = bx, az = bz;
									}
									if (num2 == 0) continue;
									num1 = num2, num2 = 0;
								}
								// Клипинг по верхней стороне
								if (!insideTop) {
									a = c = polygon[0],	ai = a*3, ay = meshVertices[int(ai + 1)], az = meshVertices[int(ai + 2)];
									for (n = 1; n <= num1; n++) {
										b = (n < num1) ? polygon[n] : c, bi = b*3, by = meshVertices[int(bi + 1)], bz = meshVertices[int(bi + 2)];
										if (bz > -by && az <= -ay || bz <= -by && az > -ay) t = (ay + az)/(ay + az - by - bz), polygon[num2++] = v, meshVertices[vi = int(v++*3)] = (ax = meshVertices[ai]) + (meshVertices[bi] - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = ay + (by - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = az + (bz - az)*t, meshUVTs[vi] = 0;
										if (bz > -by) polygon[num2++] = b;
										a = b, ai = bi,	ay = by, az = bz;
									}
									if (num2 == 0) continue;
									num1 = num2, num2 = 0;
								}
								// Клипинг по нижней стороне
								if (!insideBottom) {
									a = c = polygon[0],	ai = a*3, ay = meshVertices[int(ai + 1)], az = meshVertices[int(ai + 2)];
									for (n = 1; n <= num1; n++) {
										b = (n < num1) ? polygon[n] : c, bi = b*3, by = meshVertices[int(bi + 1)], bz = meshVertices[int(bi + 2)];
									  	if (bz > by && az <= ay || bz <= by && az > ay) t = (az - ay)/(az - ay + by - bz), polygon[num2++] = v, meshVertices[vi = int(v++*3)] = (ax = meshVertices[ai]) + (meshVertices[bi] - ax)*t, meshUVTs[vi++] = (au = meshUVTs[ai]) + (meshUVTs[bi] - au)*t, meshVertices[vi] = ay + (by - ay)*t, meshUVTs[vi++] = (av = meshUVTs[int(ai + 1)]) + (meshUVTs[int(bi + 1)] - av)*t, meshVertices[vi] = az + (bz - az)*t, meshUVTs[vi] = 0;
										if (bz > by) polygon[num2++] = b;
										a = b, ai = bi,	ay = by, az = bz;
										
									}
									if (num2 == 0) continue;
									num1 = num2, num2 = 0;
								}
								// Копирование полигона и ремап
								newPolygons[j++] = num1;
								for (n = 0; n < num1; n++) {
									if ((m = polygon[n]) < mesh.numVertices) {
										if (verticesMap[m] < 0) {
											vertices[verticesLength] = meshVertices[vi = int(m*3)],	uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi];
											newPolygons[j++] = verticesMap[m] = numVertices++;
										} else {
											newPolygons[j++] = verticesMap[m];
										}
									} else {
										vertices[verticesLength] = meshVertices[vi = int(m*3)], uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi++], vertices[verticesLength] = meshVertices[vi], uvts[verticesLength++] = meshUVTs[vi];
										newPolygons[j++] = numVertices++;
									}
								}
							}
						}
					}
				}
				// Если нода видна или есть видимые дочерние ноды
				if (j > 0 || negative != null && positive != null) {
					var res:BSPNode = newNode;
					newNode = node.create();
					res.negative = negative;
					res.positive = positive;
					res.polygonsLength = j;
					res.cameraInfront = cameraInfront;
					
					ai = polygons[1]*3, res.ax = meshVertices[ai++], res.ay = meshVertices[ai++], res.az = meshVertices[ai];
					ai = polygons[2]*3, res.abx = meshVertices[ai++] - res.ax, res.aby = meshVertices[ai++] - res.ay, res.abz = meshVertices[ai] - res.az;
					ai = polygons[3]*3, res.acx = meshVertices[ai++] - res.ax, res.acy = meshVertices[ai++] - res.ay, res.acz = meshVertices[ai] - res.az;
					
					return res;
				} else {
					return (negative != null) ? negative : positive;
				}
			} else return null;
		}

		/**
		 * @private 
		 */
		alternativa3d function split(axisX:Boolean, axisY:Boolean, coord:Number, threshold:Number, negative:KDObject, positive:KDObject):void {
			// Сплит баунда
			var negativeBoundBox:BoundBox = negative._boundBox, positiveBoundBox:BoundBox = positive._boundBox;
			if (axisX) {
				negativeBoundBox.minX = _boundBox.minX,	negativeBoundBox.minY = _boundBox.minY, negativeBoundBox.minZ = _boundBox.minZ,	negativeBoundBox.maxX = coord, negativeBoundBox.maxY = _boundBox.maxY,	negativeBoundBox.maxZ = _boundBox.maxZ,	positiveBoundBox.minX = coord, positiveBoundBox.minY = _boundBox.minY,	positiveBoundBox.minZ = _boundBox.minZ, positiveBoundBox.maxX = _boundBox.maxX,	positiveBoundBox.maxY = _boundBox.maxY,	positiveBoundBox.maxZ = _boundBox.maxZ;
			} else if (axisY) {
				negativeBoundBox.minX = _boundBox.minX,	negativeBoundBox.minY = _boundBox.minY,	negativeBoundBox.minZ = _boundBox.minZ,	negativeBoundBox.maxX = _boundBox.maxX,	negativeBoundBox.maxY = coord, negativeBoundBox.maxZ = _boundBox.maxZ,	positiveBoundBox.minX = _boundBox.minX,	positiveBoundBox.minY = coord, positiveBoundBox.minZ = _boundBox.minZ, positiveBoundBox.maxX = _boundBox.maxX, positiveBoundBox.maxY = _boundBox.maxY,	positiveBoundBox.maxZ = _boundBox.maxZ;
			} else {
				negativeBoundBox.minX = _boundBox.minX,	negativeBoundBox.minY = _boundBox.minY,	negativeBoundBox.minZ = _boundBox.minZ,	negativeBoundBox.maxX = _boundBox.maxX,	negativeBoundBox.maxY = _boundBox.maxY,	negativeBoundBox.maxZ = coord, positiveBoundBox.minX = _boundBox.minX,	positiveBoundBox.minY = _boundBox.minY, positiveBoundBox.minZ = coord, positiveBoundBox.maxX = _boundBox.maxX,	positiveBoundBox.maxY = _boundBox.maxY, positiveBoundBox.maxZ = _boundBox.maxZ;
			}
			// Подготовка к ремапу
			for (i = 0; i < numVertices;) verticesMap[i++] = -1;
			// Разбиение BSP
			if (bsp != null) {
				splitNode(bsp, axisX, axisY, coord, threshold, negative, positive);
				if (bsp.negative != null) negative.bsp = bsp.negative, bsp.negative = null;
				if (bsp.positive != null) positive.bsp = bsp.positive, bsp.positive = null;
			// Разбиение полигонов
			} else {
				var negativeIndices:Vector.<int> = negative.indices, positiveIndices:Vector.<int> = positive.indices;
				var negativeVertices:Vector.<Number> = negative.vertices, negativeUVTs:Vector.<Number> = negative.uvts, positiveVertices:Vector.<Number> = positive.vertices, positiveUVTs:Vector.<Number> = positive.uvts;
				for (var i:int = 0, j1:int = 0, j2:int = 0, k:int = 0, v1:int = 0, vi1:int = 0, v2:int = 0, vi2:int = 0, t:Number, uv:Number; i < indicesLength;) {
					if (i == k) {
						// Подготовка к разбиению
						var infront:Boolean = false, behind:Boolean = false;
						k = indices[i++] + i, negativeIndices[j1++] = positiveIndices[j2++] = 0;
						// Первая точка ребра
						var a:int = indices[int(k - 1)], ai:int = a*3;
						var ax:Number = vertices[ai], ay:Number = vertices[int(ai + 1)], az:Number = vertices[int(ai + 2)], ac:Number = axisX ? ax : (axisY ? ay : az);
					}
					// Вторая точка ребра
					var b:int = indices[i], bi:int = b*3;
					var bx:Number = vertices[bi], by:Number = vertices[int(bi + 1)], bz:Number = vertices[int(bi + 2)], bc:Number = axisX ? bx : (axisY ? by : bz);
					// Рассечение ребра
					if (bc > coord + threshold && ac < coord - threshold || bc < coord - threshold && ac > coord + threshold) t = (ac - coord)/(ac - bc), negativeVertices[vi1] = positiveVertices[vi2] = ax + (bx - ax)*t, negativeUVTs[vi1++] = positiveUVTs[vi2++] = (uv = uvts[ai]) + (uvts[bi] - uv)*t, negativeVertices[vi1] = positiveVertices[vi2] = ay + (by - ay)*t, negativeUVTs[vi1++] = positiveUVTs[vi2++] = (uv = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - uv)*t, negativeVertices[vi1] = positiveVertices[vi2] = az + (bz - az)*t, negativeUVTs[vi1++] = positiveUVTs[vi2++] = 0, negativeIndices[j1++] = v1++, positiveIndices[j2++] = v2++;
					// Добавление точки
					if (bc < coord - threshold) {
						if (verticesMap[b] < 0) {
							negativeVertices[vi1] = bx, negativeUVTs[vi1++] = uvts[bi], negativeVertices[vi1] = by, negativeUVTs[vi1++] = uvts[int(bi + 1)], negativeVertices[vi1] = bz, negativeUVTs[vi1++] = 0, negativeIndices[j1++] = verticesMap[b] = v1++;
						} else {
							negativeIndices[j1++] = verticesMap[b];
						}
						behind = true;
					} else if (bc > coord + threshold) {
						if (verticesMap[b] < 0) {
							positiveVertices[vi2] = bx, positiveUVTs[vi2++] = uvts[bi], positiveVertices[vi2] = by, positiveUVTs[vi2++] = uvts[int(bi + 1)], positiveVertices[vi2] = bz, positiveUVTs[vi2++] = 0, positiveIndices[j2++] = verticesMap[b] = v2++;
						} else {
							positiveIndices[j2++] = verticesMap[b];
						}
						infront = true;
					} else {
						negativeVertices[vi1] = positiveVertices[vi2] = bx, negativeUVTs[vi1++] = positiveUVTs[vi2++] = uvts[bi], negativeVertices[vi1] = positiveVertices[vi2] = by, negativeUVTs[vi1++] = positiveUVTs[vi2++] = uvts[int(bi + 1)], negativeVertices[vi1] = positiveVertices[vi2] = bz, negativeUVTs[vi1++] = positiveUVTs[vi2++] = 0, negativeIndices[j1++] = v1++, positiveIndices[j2++] = v2++;
					}
					// Анализ разбиения
					if (++i == k) {
						if (behind && j1 > negative.indicesLength + 1) {
							negativeIndices[negative.indicesLength] = j1 - negative.indicesLength - 1;
							negative.indicesLength = j1, negative.numVertices = v1, negative.verticesLength = vi1;
						} else {
							j1 = negative.indicesLength, v1 = negative.numVertices,	vi1 = negative.verticesLength;
						}
						if (infront && j2 > positive.indicesLength + 1 || !behind && !infront) {
							positiveIndices[positive.indicesLength] = j2 - positive.indicesLength - 1;
							positive.indicesLength = j2, positive.numVertices = v2, positive.verticesLength = vi2;
						} else {
							j2 = positive.indicesLength, v2 = positive.numVertices,	vi2 = positive.verticesLength;
						}
					} else {
						a = b, ai = bi, ax = bx, ay = by, az = bz, ac = bc;
					}
				}
			}
			// Копирование свойств
			if (negative.numVertices > 0) {
				// Копируем параметры
				negative.priority = priority;
				negative.texture = texture;
				negative.smooth = smooth;
				negative.repeatTexture = repeatTexture;
				negative.debugResult = debugResult;
				negative.viewAligned = viewAligned;
				if (viewAligned) {
					negative.textureMatrix.a = textureMatrix.a, negative.textureMatrix.b = textureMatrix.b, negative.textureMatrix.c = textureMatrix.c, negative.textureMatrix.d = textureMatrix.d, negative.textureMatrix.tx = textureMatrix.tx, negative.textureMatrix.ty = textureMatrix.ty;
					negative.projectionX = projectionX;
					negative.projectionY = projectionY;
					negative.z = z;
				}
				negative.alpha = alpha;
				negative.blendMode = blendMode;
				negative.colorTransform = colorTransform;
				negative.filters = filters;
				negative.numCheckedOccluders = 0;
			}
			if (positive.numVertices > 0) {
				// Копируем параметры
				positive.priority = priority;
				positive.texture = texture;
				positive.smooth = smooth;
				positive.repeatTexture = repeatTexture;
				positive.debugResult = debugResult;
				positive.viewAligned = viewAligned;
				if (viewAligned) {
					positive.textureMatrix.a = textureMatrix.a, positive.textureMatrix.b = textureMatrix.b, positive.textureMatrix.c = textureMatrix.c, positive.textureMatrix.d = textureMatrix.d, positive.textureMatrix.tx = textureMatrix.tx, positive.textureMatrix.ty = textureMatrix.ty;
					positive.projectionX = projectionX;
					positive.projectionY = projectionY;
					positive.z = z;
				}
				positive.alpha = alpha;
				positive.blendMode = blendMode;
				positive.colorTransform = colorTransform;
				positive.filters = filters;
				positive.numCheckedOccluders = 0;
			}
		}
		
		static private var newNegativeNode:BSPNode = BSPNode.create();
		static private var newPositiveNode:BSPNode = BSPNode.create();
		private function splitNode(node:BSPNode, axisX:Boolean, axisY:Boolean, coord:Number, threshold:Number, negative:KDObject, positive:KDObject):void {
			// Проход по дочерним нодам
			if (node.negative != null) {
				splitNode(node.negative, axisX, axisY, coord, threshold, negative, positive);
				var negativeNegative:BSPNode = node.negative.negative, negativePositive:BSPNode = node.negative.positive;
				node.negative.negative = null, node.negative.positive = null, node.negative.destroy();
			}
			if (node.positive != null) {
				splitNode(node.positive, axisX, axisY, coord, threshold, negative, positive);
				var positiveNegative:BSPNode = node.positive.negative, positivePositive:BSPNode = node.positive.positive;
				node.positive.negative = null, node.positive.positive = null, node.positive.destroy();
			}
			// Разбиение
			var nodePolygons:Vector.<int> = node.polygons, nodePolygonsLength:int = node.polygonsLength, newNegativeNodePolygons:Vector.<int> = newNegativeNode.polygons, newPositiveNodePolygons:Vector.<int> = newPositiveNode.polygons;
			var negativeVertices:Vector.<Number> = negative.vertices, negativeUVTs:Vector.<Number> = negative.uvts, positiveVertices:Vector.<Number> = positive.vertices, positiveUVTs:Vector.<Number> = positive.uvts;
			for (var i:int = 0, j1:int = 0, j2:int = 0, k:int = 0, v1:int = negative.numVertices, vi1:int = negative.verticesLength, v2:int = positive.numVertices, vi2:int = positive.verticesLength, t:Number, uv:Number; i < nodePolygonsLength;) {
				if (i == k) {
					// Подготовка к разбиению
					var infront:Boolean = false, behind:Boolean = false;
					k = nodePolygons[i++] + i, newNegativeNodePolygons[j1++] = newPositiveNodePolygons[j2++] = 0;
					// Первая точка ребра
					var a:int = nodePolygons[int(k - 1)], ai:int = a*3;
					var ax:Number = vertices[ai], ay:Number = vertices[int(ai + 1)], az:Number = vertices[int(ai + 2)], ac:Number = axisX ? ax : (axisY ? ay : az);
				}
				// Вторая точка ребра
				var b:int = nodePolygons[i], bi:int = b*3;
				var bx:Number = vertices[bi], by:Number = vertices[int(bi + 1)], bz:Number = vertices[int(bi + 2)], bc:Number = axisX ? bx : (axisY ? by : bz);
				// Рассечение ребра
				if (bc > coord + threshold && ac < coord - threshold || bc < coord - threshold && ac > coord + threshold) t = (ac - coord)/(ac - bc), negativeVertices[vi1] = positiveVertices[vi2] = ax + (bx - ax)*t, negativeUVTs[vi1++] = positiveUVTs[vi2++] = (uv = uvts[ai]) + (uvts[bi] - uv)*t, negativeVertices[vi1] = positiveVertices[vi2] = ay + (by - ay)*t, negativeUVTs[vi1++] = positiveUVTs[vi2++] = (uv = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - uv)*t, negativeVertices[vi1] = positiveVertices[vi2] = az + (bz - az)*t, negativeUVTs[vi1++] = positiveUVTs[vi2++] = 0, newNegativeNodePolygons[j1++] = v1++, newPositiveNodePolygons[j2++] = v2++;
				// Добавление точки
				if (bc < coord - threshold) {
					if (verticesMap[b] < 0) {
						negativeVertices[vi1] = bx, negativeUVTs[vi1++] = uvts[bi], negativeVertices[vi1] = by, negativeUVTs[vi1++] = uvts[int(bi + 1)], negativeVertices[vi1] = bz, negativeUVTs[vi1++] = 0, newNegativeNodePolygons[j1++] = verticesMap[b] = v1++;
					} else {
						newNegativeNodePolygons[j1++] = verticesMap[b];
					}
					behind = true;
				} else if (bc > coord + threshold) {
					if (verticesMap[b] < 0) {
						positiveVertices[vi2] = bx, positiveUVTs[vi2++] = uvts[bi], positiveVertices[vi2] = by, positiveUVTs[vi2++] = uvts[int(bi + 1)], positiveVertices[vi2] = bz, positiveUVTs[vi2++] = 0, newPositiveNodePolygons[j2++] = verticesMap[b] = v2++;
					} else {
						newPositiveNodePolygons[j2++] = verticesMap[b];
					}
					infront = true;
				} else {
					negativeVertices[vi1] = positiveVertices[vi2] = bx, negativeUVTs[vi1++] = positiveUVTs[vi2++] = uvts[bi], negativeVertices[vi1] = positiveVertices[vi2] = by, negativeUVTs[vi1++] = positiveUVTs[vi2++] = uvts[int(bi + 1)], negativeVertices[vi1] = positiveVertices[vi2] = bz, negativeUVTs[vi1++] = positiveUVTs[vi2++] = 0, newNegativeNodePolygons[j1++] = v1++, newPositiveNodePolygons[j2++] = v2++;
				}
				// Анализ разбиения
				if (++i == k) {
					if (behind && j1 > newNegativeNode.polygonsLength + 1) {
						newNegativeNodePolygons[newNegativeNode.polygonsLength] = j1 - newNegativeNode.polygonsLength - 1;
						newNegativeNode.polygonsLength = j1, negative.numVertices = v1, negative.verticesLength = vi1;
					} else {
						j1 = newNegativeNode.polygonsLength, v1 = negative.numVertices,	vi1 = negative.verticesLength;
					}
					if (infront && j2 > newPositiveNode.polygonsLength + 1 || !behind && !infront) {
						newPositiveNodePolygons[newPositiveNode.polygonsLength] = j2 - newPositiveNode.polygonsLength - 1;
						newPositiveNode.polygonsLength = j2, positive.numVertices = v2, positive.verticesLength = vi2;
					} else {
						j2 = newPositiveNode.polygonsLength, v2 = positive.numVertices,	vi2 = positive.verticesLength;
					}
				} else {
					a = b, ai = bi, ax = bx, ay = by, az = bz, ac = bc;
				}
			}
			// Если в негативе от сплита есть полигоны ноды или полигоны дочерних нод
			if (j1 > 0 || negativeNegative != null && positiveNegative != null) {
				node.negative = newNegativeNode;
				newNegativeNode = node.create();
				
				node.negative.ax = node.ax, node.negative.ay = node.ay, node.negative.az = node.az;
				node.negative.abx = node.abx, node.negative.aby = node.aby, node.negative.abz = node.abz;
				node.negative.acx = node.acx, node.negative.acy = node.acy, node.negative.acz = node.acz;
				
				node.negative.negative = negativeNegative;
				node.negative.positive = positiveNegative;
				node.negative.cameraInfront = node.cameraInfront;
			} else {
				node.negative = (negativeNegative != null) ? negativeNegative : positiveNegative;
			}
			// Если в позитиве от сплита есть полигоны ноды или полигоны дочерних нод
			if (j2 > 0 || negativePositive != null && positivePositive != null) {
				node.positive = newPositiveNode;
				newPositiveNode = node.create();
				
				node.positive.ax = node.ax, node.positive.ay = node.ay, node.positive.az = node.az;
				node.positive.abx = node.abx, node.positive.aby = node.aby, node.positive.abz = node.abz;
				node.positive.acx = node.acx, node.positive.acy = node.acy, node.positive.acz = node.acz;
				
				node.positive.negative = negativePositive;
				node.positive.positive = positivePositive;
				node.positive.cameraInfront = node.cameraInfront;
			} else {
				node.positive = (negativePositive != null) ? negativePositive : positivePositive;
			}
		}
		
		/**
		 * @private 
		 */
		alternativa3d function crop(axisX:Boolean, axisY:Boolean, coord:Number, threshold:Number, inPositive:Boolean, result:KDObject):void {
			// Сплит баунда
			var resultBoundBox:BoundBox = result._boundBox;
			if (axisX) {
				if (inPositive) resultBoundBox.minX = coord, resultBoundBox.maxX = _boundBox.maxX else resultBoundBox.minX = _boundBox.minX, resultBoundBox.maxX = coord;
				resultBoundBox.minY = _boundBox.minY, resultBoundBox.maxY = _boundBox.maxY, resultBoundBox.minZ = _boundBox.minZ, resultBoundBox.maxZ = _boundBox.maxZ;
			} else if (axisY) {
				if (inPositive) resultBoundBox.minY = coord, resultBoundBox.maxY = _boundBox.maxY else resultBoundBox.minY = _boundBox.minY, resultBoundBox.maxY = coord;
				resultBoundBox.minX = _boundBox.minX, resultBoundBox.maxX = _boundBox.maxX, resultBoundBox.minZ = _boundBox.minZ, resultBoundBox.maxZ = _boundBox.maxZ;
			} else {
				if (inPositive) resultBoundBox.minZ = coord, resultBoundBox.maxZ = _boundBox.maxZ else resultBoundBox.minZ = _boundBox.minZ, resultBoundBox.maxZ = coord;
				resultBoundBox.minX = _boundBox.minX, resultBoundBox.maxX = _boundBox.maxX, resultBoundBox.minY = _boundBox.minY, resultBoundBox.maxY = _boundBox.maxY;
			}
			// Подготовка к ремапу
			for (i = 0; i < numVertices;) verticesMap[i++] = -1;
			// Разбиение BSP
			if (bsp != null) {
				result.bsp = cropNode(bsp, axisX, axisY, coord, threshold, inPositive, result);
			// Разбиение полигонов
			} else {
				var resultIndices:Vector.<int> = result.indices, resultVertices:Vector.<Number> = result.vertices, resultUVTs:Vector.<Number> = result.uvts;
				for (var i:int = 0, j:int = 0, k:int = 0, v:int = 0, vi:int = 0, t:Number, uv:Number; i < indicesLength;) {
					if (i == k) {
						// Подготовка к разбиению
						k = indices[i++] + i, resultIndices[j++] = 0;
						// Первая точка ребра
						var a:int = indices[int(k - 1)], ai:int = a*3;
						var ax:Number = vertices[ai], ay:Number = vertices[int(ai + 1)], az:Number = vertices[int(ai + 2)], ac:Number = axisX ? ax : (axisY ? ay : az);
					}
					// Вторая точка ребра
					var b:int = indices[i], bi:int = b*3;
					var bx:Number = vertices[bi], by:Number = vertices[int(bi + 1)], bz:Number = vertices[int(bi + 2)], bc:Number = axisX ? bx : (axisY ? by : bz);
					// Рассечение ребра
					if (inPositive && (ac <= coord && bc > coord || bc <= coord && ac > coord) || !inPositive && (ac < coord && bc >= coord || bc < coord && ac >= coord)) t = (ac - coord)/(ac - bc), resultVertices[vi] = ax + (bx - ax)*t, resultUVTs[vi++] = (uv = uvts[ai]) + (uvts[bi] - uv)*t, resultVertices[vi] = ay + (by - ay)*t, resultUVTs[vi++] = (uv = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - uv)*t, resultVertices[vi] = az + (bz - az)*t, resultUVTs[vi++] = 0, resultIndices[j++] = v++;
					// Добавление точки
					if (inPositive && bc > coord || !inPositive && bc < coord) {
						if (verticesMap[b] < 0) {
							resultVertices[vi] = bx, resultUVTs[vi++] = uvts[bi], resultVertices[vi] = by, resultUVTs[vi++] = uvts[int(bi + 1)], resultVertices[vi] = bz, resultUVTs[vi++] = 0, resultIndices[j++] = verticesMap[b] = v++;
						} else {
							resultIndices[j++] = verticesMap[b];
						}
					}
					// Анализ разбиения
					if (++i == k) {
						if (j > result.indicesLength + 1) {
							resultIndices[result.indicesLength] = j - result.indicesLength - 1;
							result.indicesLength = j, result.numVertices = v, result.verticesLength = vi;
						} else {
							j = result.indicesLength;
						}
					} else {
						a = b, ai = bi, ax = bx, ay = by, az = bz, ac = bc;
					}
				}
			}
			// Копирование свойств
			if (result.numVertices > 0) {
				// Копируем параметры
				result.priority = priority;
				result.texture = texture;
				result.smooth = smooth;
				result.repeatTexture = repeatTexture;
				result.debugResult = debugResult;
				result.viewAligned = viewAligned;
				if (viewAligned) {
					result.textureMatrix.a = textureMatrix.a, result.textureMatrix.b = textureMatrix.b, result.textureMatrix.c = textureMatrix.c, result.textureMatrix.d = textureMatrix.d, result.textureMatrix.tx = textureMatrix.tx, result.textureMatrix.ty = textureMatrix.ty;
					result.projectionX = projectionX;
					result.projectionY = projectionY;
					result.z = z;
				}
				result.alpha = alpha;
				result.blendMode = blendMode;
				result.colorTransform = colorTransform;
				result.filters = filters;
				result.numCheckedOccluders = 0;
			}
		}

		private function cropNode(node:BSPNode, axisX:Boolean, axisY:Boolean, coord:Number, threshold:Number, inPositive:Boolean, result:KDObject):BSPNode {
			if (node != null) {
				// Проход по дочерним нодам
				var negative:BSPNode = cropNode(node.negative, axisX, axisY, coord, threshold, inPositive, result);
				var positive:BSPNode = cropNode(node.positive, axisX, axisY, coord, threshold, inPositive, result);
				// Разбиение
				var nodePolygons:Vector.<int> = node.polygons, nodePolygonsLength:int = node.polygonsLength, newNodePolygons:Vector.<int> = newNode.polygons;
				var resultVertices:Vector.<Number> = result.vertices, resultUVTs:Vector.<Number> = result.uvts;
				for (var i:int = 0, j:int = 0, k:int = 0, v:int = result.numVertices, vi:int = result.verticesLength, t:Number, uv:Number; i < nodePolygonsLength;) {
					if (i == k) {
						// Подготовка к разбиению
						k = nodePolygons[i++] + i, newNodePolygons[j++] = 0;
						// Первая точка ребра
						var a:int = nodePolygons[int(k - 1)], ai:int = a*3;
						var ax:Number = vertices[ai], ay:Number = vertices[int(ai + 1)], az:Number = vertices[int(ai + 2)], ac:Number = axisX ? ax : (axisY ? ay : az);
					}
					// Вторая точка ребра
					var b:int = nodePolygons[i], bi:int = b*3;
					var bx:Number = vertices[bi], by:Number = vertices[int(bi + 1)], bz:Number = vertices[int(bi + 2)], bc:Number = axisX ? bx : (axisY ? by : bz);
					
					// Рассечение ребра
					if (inPositive && (ac <= coord && bc > coord || bc <= coord && ac > coord) || !inPositive && (ac < coord && bc >= coord || bc < coord && ac >= coord)) t = (ac - coord)/(ac - bc), resultVertices[vi] = ax + (bx - ax)*t, resultUVTs[vi++] = (uv = uvts[ai]) + (uvts[bi] - uv)*t, resultVertices[vi] = ay + (by - ay)*t, resultUVTs[vi++] = (uv = uvts[int(ai + 1)]) + (uvts[int(bi + 1)] - uv)*t, resultVertices[vi] = az + (bz - az)*t, resultUVTs[vi++] = 0, newNodePolygons[j++] = v++;
					// Добавление точки
					if (inPositive && bc > coord || !inPositive && bc < coord) {
						if (verticesMap[b] < 0) {
							resultVertices[vi] = bx, resultUVTs[vi++] = uvts[bi], resultVertices[vi] = by, resultUVTs[vi++] = uvts[int(bi + 1)], resultVertices[vi] = bz, resultUVTs[vi++] = 0, newNodePolygons[j++] = verticesMap[b] = v++;
						} else {
							newNodePolygons[j++] = verticesMap[b];
						}
					}
					// Анализ разбиения
					if (++i == k) {
						if (j > newNode.polygonsLength + 1) {
							newNodePolygons[newNode.polygonsLength] = j - newNode.polygonsLength - 1;
							newNode.polygonsLength = j, result.numVertices = v, result.verticesLength = vi;
						} else {
							j = newNode.polygonsLength;
						}
					} else {
						a = b, ai = bi, ax = bx, ay = by, az = bz, ac = bc;
					}
				}
				// Если нода видна или есть видимые дочерние ноды
				if (j > 0 || negative != null && positive != null) {
					var res:BSPNode = newNode;
					newNode = node.create();

					res.ax = node.ax, res.ay = node.ay, res.az = node.az;
					res.abx = node.abx, res.aby = node.aby, res.abz = node.abz;
					res.acx = node.acx, res.acy = node.acy, res.acz = node.acz;

					res.negative = negative;
					res.positive = positive;
					res.polygonsLength = j;
					res.cameraInfront = node.cameraInfront;
					return res;
				} else {
					return (negative != null) ? negative : positive;
				}
			} else return null;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Дебаг
			var debugCanvas:Canvas = (debugResult > 0) ? parentCanvas.getChildCanvas(true, false) : null;
			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, alpha, blendMode, colorTransform, filters);
			// Меш
			if (!viewAligned) {
				// Подрезка
				drawIndicesLength = 0;
				vertices.length = uvts.length = verticesLength;
				projectedVertices.length = numVertices << 1;
				// Если BSP
				if (bsp != null) {
					// Перевод координат в камеру
					drawMatrix.identity();
					drawMatrix.prepend(object.cameraMatrix);
					drawMatrix.append(camera.projectionMatrix);
					Utils3D.projectVectors(drawMatrix, vertices, projectedVertices, uvts);
					drawNode(bsp);
				} else {
					// Перевод координат в камеру
					object.cameraMatrix.transformVectors(vertices, vertices);
					Utils3D.projectVectors(camera.projectionMatrix, vertices, projectedVertices, uvts);
					// Сбор средних Z
					for (var i:int = 0, j:int = 0, n:int = 0, num:int, k:int = 0, z:Number, a:int, b:int; i < indicesLength;) {
						if (i == k) sortingMap[n] = i, k = (num = indices[i++]) + i, z = 0;
						z += vertices[int(indices[i]*3 + 2)];
						if (++i == k) averageZ[n++] = z/num;
					}
					// Сортировка
					var sortingStackIndex:int, sortingLeft:Number, sortingMedian:Number, sortingRight:Number, sortingMapIndex:int, l:int = 0, r:int = n - 1;
					for (sortingStack[0] = l, sortingStack[1] = r, sortingStackIndex = 2; sortingStackIndex > 0;) {
						j = r = sortingStack[--sortingStackIndex], i = l = sortingStack[--sortingStackIndex], sortingMedian = averageZ[(r + l) >> 1];
						for (;i <= j;) {
			 				for (;(sortingLeft = averageZ[i]) > sortingMedian; i++);
			 				for (;(sortingRight = averageZ[j]) < sortingMedian; j--);
			 				if (i <= j) sortingMapIndex = sortingMap[i], sortingMap[i] = sortingMap[j], sortingMap[j] = sortingMapIndex, averageZ[i++] = sortingRight, averageZ[j--] = sortingLeft;
			 			}
						if (l < j) sortingStack[sortingStackIndex++] = l, sortingStack[sortingStackIndex++] = j;
						if (i < r) sortingStack[sortingStackIndex++] = i, sortingStack[sortingStackIndex++] = r;
					}
					// Триангуляция
					for (i = 0; i < n; i++) {
						j = indices[k = sortingMap[i]] + ++k;
						a = indices[k++], b = indices[k++];
						for (; k < j;) drawIndices[drawIndicesLength++] = a, drawIndices[drawIndicesLength++] = b, drawIndices[drawIndicesLength++] = b = indices[k++];
					}
				}
				// Отрисовка
				canvas.gfx.beginBitmapFill(texture, null, repeatTexture, smooth);
				drawIndices.length = drawIndicesLength;
				camera.numTriangles += drawIndicesLength/3;
				canvas.gfx.drawTriangles(projectedVertices, drawIndices, uvts, "positive");
				// Дебаг
				if (debugResult & Debug.EDGES) {
					debugCanvas.gfx.lineStyle(0, 0xFFFFFF);
					debugCanvas.gfx.drawTriangles(projectedVertices, drawIndices, uvts, "positive");
				}
			// Спрайт
			} else {
				// Переводим координаты в камеру
				vertices.length = verticesLength;
				object.cameraMatrix.transformVectors(vertices, vertices);
				// Отрисовка
				canvas.gfx.beginBitmapFill(texture, textureMatrix, false, smooth);
				canvas.gfx.moveTo(vertices[verticesLength - 3]*projectionX, vertices[verticesLength - 2]*projectionY);
				for (i = 0; i < verticesLength; i++) canvas.gfx.lineTo(vertices[i++]*projectionX, vertices[i++]*projectionY);
				// Дебаг
				if (debugResult & Debug.EDGES) {
					debugCanvas.gfx.lineStyle(0, 0xFFFFFF);
					debugCanvas.gfx.moveTo(vertices[verticesLength - 3]*projectionX, vertices[verticesLength - 2]*projectionY);
					for (i = 0; i < verticesLength; i++) debugCanvas.gfx.lineTo(vertices[i++]*projectionX, vertices[i++]*projectionY);
				}
			}
			// Дебаг
			if (debugResult & Debug.BOUNDS) {
				var containerBoundBox:BoundBox = object._boundBox;
				object._boundBox = _boundBox;
				object.drawBoundBox(camera, debugCanvas, 0x99FF00);
				object._boundBox = containerBoundBox;				
			}
		}
		
		private function drawNode(node:BSPNode):void {
			if (node != null) {
				if (node.cameraInfront) {
					drawNode(node.negative);
					for (var i:int = 0, k:int = 0, a:int, b:int, polygons:Vector.<int> = node.polygons, polygonsLength:int = node.polygonsLength; i < polygonsLength;) {
						if (i == k) k = polygons[i++] + i, a = polygons[i++], b = polygons[i++];
						drawIndices[drawIndicesLength++] = a, drawIndices[drawIndicesLength++] = b,	drawIndices[drawIndicesLength++] = b = polygons[i++];
					}
					drawNode(node.positive);
				} else {
					drawNode(node.positive);
					drawNode(node.negative);
				}
			}
		}
		
		private function drawPart(camera:Camera3D, object:Object3D, parentCanvas:Canvas, indices:Vector.<int>, begin:int, end:int):void {
			// Дебаг
			var debugCanvas:Canvas = (debugResult > 0) ? parentCanvas.getChildCanvas(true, false) : null;
			// Подготовка канваса
			var canvas:Canvas = parentCanvas.getChildCanvas(true, false, alpha, blendMode, colorTransform, filters);
			// Меш
			if (!viewAligned) {
				drawIndicesLength = 0;
				// Триангуляция
				for (var i:int = begin, k:int = begin, a:int, b:int, vi:int; i < end;) {
					if (i == k) k = indices[i++] + i, a = indices[i++], b = indices[i++];
					drawIndices[drawIndicesLength++] = a, drawIndices[drawIndicesLength++] = b,	drawIndices[drawIndicesLength++] = b = indices[i++];
				}
				// Отрисовка
				canvas.gfx.beginBitmapFill(texture, null, repeatTexture, smooth);
				drawIndices.length = drawIndicesLength;
				camera.numTriangles += drawIndicesLength/3;
				canvas.gfx.drawTriangles(projectedVertices, drawIndices, uvts, "positive");
				// Дебаг
				if (debugResult & Debug.EDGES) {
					debugCanvas.gfx.lineStyle(0, 0xFF9999);
					debugCanvas.gfx.drawTriangles(projectedVertices, drawIndices, uvts, "positive");
				}
			// Спрайт
			} else {
				// Отрисовка
				canvas.gfx.beginBitmapFill(texture, textureMatrix, false, smooth);
				for (i = begin, k = begin; i < end; i++) {
					if (i == k) k = indices[i++] + i, canvas.gfx.moveTo(vertices[vi = int(indices[int(k - 1)]*3)]*projectionX, vertices[++vi]*projectionY);
					canvas.gfx.lineTo(vertices[vi = int(indices[i]*3)]*projectionX, vertices[++vi]*projectionY);
				}
				// Дебаг
				if (debugResult & Debug.EDGES) {
					debugCanvas.gfx.lineStyle(0, 0xFF9999);
					for (i = begin, k = begin; i < end; i++) {
						if (i == k) k = indices[i++] + i, debugCanvas.gfx.moveTo(vertices[vi = int(indices[int(k - 1)]*3)]*projectionX, vertices[++vi]*projectionY);
						debugCanvas.gfx.lineTo(vertices[vi = int(indices[i]*3)]*projectionX, vertices[++vi]*projectionY);
					}
				}
			}
			// Дебаг
			if (debugResult & Debug.BOUNDS) {
				var containerBoundBox:BoundBox = object._boundBox;
				object._boundBox = _boundBox;
				object.drawBoundBox(camera, debugCanvas, 0xFF0000);
				object._boundBox = containerBoundBox;				
			}
		}
		
		/**
		 * @private 
		 */
		static alternativa3d function drawConflict(camera:Camera3D, object:Object3D, canvas:Canvas, kdObjects:Vector.<KDObject>, begin:int, end:int, threshold:Number):void {
			var i:int, j:int, k:int, n:int, mi:int, num:int, v:int, z:Number, index:int;
			var sortingStackIndex:int, sortingLeft:Number, sortingMedian:Number, sortingRight:Number, sortingObjectLeft:KDObject, sortingObjectMedian:int, sortingObjectRight:KDObject, sortingMapIndex:int, l:int, r:int;
			// Сортировка объектов по приоритету
			for (l = begin, r = end - 1, sortingStack[0] = l, sortingStack[1] = r, sortingStackIndex = 2; sortingStackIndex > 0;) {
				j = r = sortingStack[--sortingStackIndex], i = l = sortingStack[--sortingStackIndex], sortingObjectMedian = (kdObjects[(r + l) >> 1] as KDObject).priority;
				for (;i <= j;) {
	 				for (;(sortingObjectLeft = kdObjects[i]).priority > sortingObjectMedian; i++);
	 				for (;(sortingObjectRight = kdObjects[j]).priority < sortingObjectMedian; j--);
	 				if (i <= j) kdObjects[i++] = sortingObjectRight, kdObjects[j--] = sortingObjectLeft;
	 			}
				if (l < j) sortingStack[sortingStackIndex++] = l, sortingStack[sortingStackIndex++] = j;
				if (i < r) sortingStack[sortingStackIndex++] = i, sortingStack[sortingStackIndex++] = r;
			}
			
			// Сбор фрагментов, сортирующихся по средним Z
			for (i = begin, index = end, n = 0, sourceFragmentsLength = 0; i < end; i++) {
				var kdObject:KDObject = kdObjects[i], indices:Vector.<int> = kdObject.indices, indicesLength:int = kdObject.indicesLength, vertices:Vector.<Number> = kdObject.vertices;
				if (kdObject.bsp == null) {
					// Сбор средних Z
					for (j = 0, k = 0; j < indicesLength;) {
						if (j == k) sortingMap[n] = sourceFragmentsLength, k = (num = indices[j++]) + j, z = 0, sourceFragments[sourceFragmentsLength++] = (i << 16) + num;
						z += vertices[int((v = indices[j])*3 + 2)], sourceFragments[sourceFragmentsLength++] = v;
						if (++j == k) averageZ[n++] = z/num;
					}
				} else {
					index = i;
					break;
				}
			}
			// Если есть фрагмены, сортирующиеся по средним Z
			if (index > begin) {
				// Сортировка фрагментов разных объектов
				for (l = 0, r = n - 1, sortingStack[0] = l, sortingStack[1] = r, sortingStackIndex = 2; sortingStackIndex > 0;) {
					j = r = sortingStack[--sortingStackIndex], i = l = sortingStack[--sortingStackIndex], sortingMedian = averageZ[(r + l) >> 1];
					for (;i <= j;) {
		 				for (;(sortingLeft = averageZ[i]) > sortingMedian; i++);
		 				for (;(sortingRight = averageZ[j]) < sortingMedian; j--);
		 				if (i <= j) sortingMapIndex = sortingMap[i], sortingMap[i] = sortingMap[j], sortingMap[j] = sortingMapIndex, averageZ[i++] = sortingRight, averageZ[j--] = sortingLeft;
		 			}
					if (l < j) sortingStack[sortingStackIndex++] = l, sortingStack[sortingStackIndex++] = j;
					if (i < r) sortingStack[sortingStackIndex++] = i, sortingStack[sortingStackIndex++] = r;
				}
				// Перестановка фрагментов по карте сортировки
				for (i = 0; i < n; i++) {
					num = ((resultFragments[resultFragmentsLength++] = sourceFragments[k = sortingMap[i]]) & 0xFFFF) + ++k;
					for (; k < num;) resultFragments[resultFragmentsLength++] = sourceFragments[k++];
				}
			}
			// Итоговый сбор последовательности фрагментов
			for (i = index; i < end; i++) {
				sourceFragments = resultFragments, sourceFragmentsLength = resultFragmentsLength, sourceFragmentsRealLength = sourceFragments.length;
				resultFragments = (sourceFragments == fragments1) ? fragments2 : fragments1, resultFragmentsLength = 0;
				kdObject = kdObjects[i];
				kdObject.collectNode(kdObject.bsp, kdObjects, i << 16, threshold, 0, sourceFragmentsLength);
			}
			// Проецирование
			for (i = begin; i < end; i++) {
				kdObject = kdObjects[i];
				if (!kdObject.viewAligned) {
					kdObject.uvts.length = kdObject.verticesLength;
					kdObject.projectedVertices.length = kdObject.numVertices << 1;
					Utils3D.projectVectors(camera.projectionMatrix, kdObject.vertices, kdObject.projectedVertices, kdObject.uvts);
				}
			}
			/*
			// Сбор отрисовочных вызовов
			for (k = 0, i = -1, sourceFragmentsLength = 0; k < resultFragmentsLength;) {
				mi = resultFragments[k], j = mi >> 16, num = mi & 0xFFFF;
				if (i != j) i = j, sourceFragments[sourceFragmentsLength++] = (j << 16) + k;
				resultFragments[k] = num, k = num + ++k;
			}
			// Отрисовка
			for (i = sourceFragmentsLength - 1; i >= 0; i--) (kdObjects[(mi = sourceFragments[i]) >> 16] as KDObject).drawPart(camera, object, canvas, resultFragments, k = mi & 0xFFFF, resultFragmentsLength), resultFragmentsLength = k;
			*/
			// Сбор отрисовочных вызовов
			for (k = 0, i = -1, sourceFragmentsLength = 0; k < resultFragmentsLength;) {
				mi = resultFragments[k], j = mi >> 16, num = mi & 0xFFFF;
				if (i != j) i = j, sourceFragments[sourceFragmentsLength++] = k, sourceFragments[sourceFragmentsLength++] = j;
				resultFragments[k] = num, k = num + ++k;
			}
			// Отрисовка
			for (i = sourceFragmentsLength - 1; i >= 0;) {
				j = sourceFragments[i--];
				(kdObjects[j] as KDObject).drawPart(camera, object, canvas, resultFragments, k = sourceFragments[i--], resultFragmentsLength);
				resultFragmentsLength = k;
			}
			// Зачистка
			for (i = begin; i < end; i++) (kdObjects[i] as KDObject).destroy(), kdObjects[i] = null;
		}
		
		static private const fragments1:Vector.<int> = new Vector.<int>();
		static private const fragments2:Vector.<int> = new Vector.<int>();
		
		static private var sourceFragments:Vector.<int> = fragments1;
		static private var sourceFragmentsLength:int = 0;
		static private var sourceFragmentsRealLength:int = 0;
		
		static private var resultFragments:Vector.<int> = fragments2;
		static private var resultFragmentsLength:int = 0;
		
		private function collectNode(node:BSPNode, kdObjects:Vector.<KDObject>, index:int, threshold:Number, begin:int, end:int):void {
			if (node != null) {
				// Разделение кучи
				if (end > begin) {
					var normalX:Number = node.acz*node.aby - node.acy*node.abz;
					var normalY:Number = node.acx*node.abz - node.acz*node.abx;
					var normalZ:Number = node.acy*node.abx - node.acx*node.aby;
					var normalL:Number = Math.sqrt(normalX*normalX + normalY*normalY + normalZ*normalZ);
					if (normalL > 0) normalX /= normalL, normalY /= normalL, normalZ /= normalL;
					var offset:Number = node.ax*normalX + node.ay*normalY + node.az*normalZ;
					var reserve:int = end - begin + ((end - begin) >> 2);
					var negativeBegin:int = sourceFragmentsLength;
					var negativeEnd:int = negativeBegin;
					var positiveBegin:int = sourceFragmentsLength + reserve;
					var positiveEnd:int = positiveBegin;
					if ((sourceFragmentsLength = positiveBegin + reserve) > sourceFragmentsRealLength) sourceFragments.length = sourceFragmentsRealLength = sourceFragmentsLength;
					// Перебираем грани разных объектов
					for (var i:int = begin, j1:int = negativeEnd, j2:int = positiveEnd, k:int = begin, t:Number, uv:Number; i < end;) {
						if (i == k) {
							// Подготовка к разбиению
							var mi:int = sourceFragments[i], oi:int = mi >> 16, num:int = mi & 0xFFFF;
							var kdObject:KDObject = kdObjects[oi], kdObjectVertices:Vector.<Number> = kdObject.vertices, kdObjectUVTs:Vector.<Number> = kdObject.uvts;
							var v:int = kdObject.numVertices, vi:int = kdObject.verticesLength;
							var infront:Boolean = false, behind:Boolean = false;
							k = num + ++i, j1++, j2++, oi = oi << 16;
							// Первая точка ребра
							var a:int = sourceFragments[int(k - 1)], ai:int = a*3;
							var ax:Number = kdObjectVertices[ai], ay:Number = kdObjectVertices[int(ai + 1)], az:Number = kdObjectVertices[int(ai + 2)];
							var ao:Number = ax*normalX + ay*normalY + az*normalZ - offset;
						}
						// Вторая точка ребра
						var b:int = sourceFragments[i], bi:int = b*3;
						var bx:Number = kdObjectVertices[bi], by:Number = kdObjectVertices[int(bi + 1)], bz:Number = kdObjectVertices[int(bi + 2)];
						var bo:Number = bx*normalX + by*normalY + bz*normalZ - offset;
						// Рассечение ребра
						if (ao < -threshold && bo > threshold || bo < -threshold && ao > threshold) t = ao/(ao - bo), kdObjectVertices[vi] = ax + (bx - ax)*t, kdObjectUVTs[vi++] = (uv = kdObjectUVTs[ai]) + (kdObjectUVTs[bi] - uv)*t, kdObjectVertices[vi] = ay + (by - ay)*t, kdObjectUVTs[vi++] = (uv = kdObjectUVTs[int(ai + 1)]) + (kdObjectUVTs[int(bi + 1)] - uv)*t, kdObjectVertices[vi] = az + (bz - az)*t, kdObjectUVTs[vi++] = 0, sourceFragments[j1++] = sourceFragments[j2++] = v++;
						// Добавление точки
						if (bo < -threshold) {
							sourceFragments[j1++] = b, behind = true;
						} else if (bo > threshold) {
							sourceFragments[j2++] = b, infront = true;
						} else {
							sourceFragments[j1++] = sourceFragments[j2++] = b;
						}
						// Анализ разбиения
						if (++i == k) {
							if (behind && infront) kdObject.numVertices = v, kdObject.verticesLength = vi;
							if (behind && j1 > negativeEnd + 1) {
								sourceFragments[negativeEnd] = oi + j1 - negativeEnd - 1, negativeEnd = j1;
							} else {
								j1 = negativeEnd;
							}
							if (infront && j2 > positiveEnd + 1 || !behind && !infront) {
								sourceFragments[positiveEnd] = oi + j2 - positiveEnd - 1, positiveEnd = j2;
							} else {
								j2 = positiveEnd;
							}
						} else {
							a = b, ai = bi, ax = bx, ay = by, az = bz, ao = bo;
						}
					}
				}
				// Проход по дочерним нодам
				if (node.cameraInfront) {
					collectNode(node.negative, kdObjects, index, threshold, negativeBegin, negativeEnd);
					// Сбор фрагментов ноды
					var polygons:Vector.<int> = node.polygons, polygonsLength:int = node.polygonsLength;
					for (i = 0, k = 0; i < polygonsLength; i++) {
						if (i == k) num = polygons[i], k = num + ++i, resultFragments[resultFragmentsLength++] = index + num;
						resultFragments[resultFragmentsLength++] = polygons[i];
					}
					collectNode(node.positive, kdObjects, index, threshold, positiveBegin, positiveEnd);
				} else {
					collectNode(node.positive, kdObjects, index, threshold, positiveBegin, positiveEnd);
					collectNode(node.negative, kdObjects, index, threshold, negativeBegin, negativeEnd);
				}
			} else {
				for (i = begin, k = begin; i < end; i++) resultFragments[resultFragmentsLength++] = sourceFragments[i];
			}
		}
		
	}
}
