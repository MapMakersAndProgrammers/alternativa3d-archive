package alternativa.engine3d.containers {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Fragment;
	import alternativa.engine3d.core.Geometry;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.geom.Utils3D;
	
	use namespace alternativa3d;

	public class BSPTree extends ConflictContainer {
		
		private var root:BSPNode;
		
		private var vertices:Vector.<Number> = new Vector.<Number>();
		private var uvts:Vector.<Number> = new Vector.<Number>();
		private var cameraVertices:Vector.<Number> = new Vector.<Number>();
		private	var verticesLength:int = 0;
		private var numVertices:int = 0;
		
		private var textures:Vector.<BitmapData> = new Vector.<BitmapData>();
		
		private var index:int;
		private var firstDrawCall:DrawCall = new DrawCall();
		private var drawCall:DrawCall = firstDrawCall;
		
		private var projectedVertices:Vector.<Number> = new Vector.<Number>();
		private var drawIndices:Vector.<int> = new Vector.<int>();
		private var drawIndicesLength:int = 0;
	
		override alternativa3d function get canDraw():Boolean {
			return _numChildren > 0 || root != null;
		}
		
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Если есть корневая нода
			if (root != null) {
				// Расчёт инверсной матрицы камеры и позицци камеры в контейнере
				calculateInverseCameraMatrix(object.cameraMatrix);
				// Расчёт плоскостей камеры в контейнере
				calculateCameraPlanes(camera, true);
				// Проверка на видимость рутовой ноды
				var culling:int = cullingInContainer(camera, root.boundBox, object.culling);
				if (culling >= 0) {
					// Подготовка канваса
					var canvas:Canvas = parentCanvas.getChildCanvas(false, true, object.alpha, object.blendMode, object.colorTransform, object.filters);
					canvas.numDraws = 0;
					// Окклюдеры
					numOccluders = 0;
					if (camera.numOccluders > 0) {
						updateOccluders(camera);
					}
					// Сбор видимой геометрии
					var geometry:Geometry = getGeometry(camera, object);
					var current:Geometry = geometry;
					while (current != null) {
						current.vertices.length = current.verticesLength;
						inverseCameraMatrix.transformVectors(current.vertices, current.vertices);
						current.calculateAABB();
						current = current.next;
					}
					// Сброс
					index = -1;
					// Трансформация в камеру
					cameraMatrix.transformVectors(vertices, cameraVertices);
					// Проход по дереву
					verticesLength = numVertices*3;
					drawNode(root, culling, camera, object, canvas, geometry);
					// Проецирование
					cameraVertices.length = verticesLength;
					uvts.length = verticesLength;
					projectedVertices.length = verticesLength/3 << 1;
					Utils3D.projectVectors(camera.projectionMatrix, cameraVertices, projectedVertices, uvts);
					// Отрисовка
					while (drawCall != firstDrawCall) {
						
						drawIndicesLength = 0;
						
						var curr:Fragment = drawCall.fragment;
						var last:Fragment;
						do {
							var indices:Vector.<int> = curr.indices;
							var num:int = curr.num;
							var a:int = indices[0];
							var b:int = indices[1];
							for (var i:int = 2; i < num; i++) {
								drawIndices[drawIndicesLength] = a;
								drawIndicesLength++;
								drawIndices[drawIndicesLength] = b;
								drawIndicesLength++;
								var c:int = indices[i];
								drawIndices[drawIndicesLength] = c;
								drawIndicesLength++;
								b = c;
							}
							last = curr;
							curr = curr.next;
						} while (curr != null);
						last.next = Fragment.collector;
						Fragment.collector = drawCall.fragment;
						drawCall.fragment = null;
						
						canvas.gfx.beginBitmapFill(drawCall.texture, null, true, true);
						drawIndices.length = drawIndicesLength;
						camera.numTriangles += drawIndicesLength/3;
						canvas.gfx.drawTriangles(projectedVertices, drawIndices, uvts, "none");
						
						drawCall.texture = null;
						drawCall.canvas = null;
						drawCall = drawCall.prev;
					}
					// Если была отрисовка
					if (canvas.numDraws > 0) {
						canvas.removeChildren(canvas.numDraws);
					} else {
						parentCanvas.numDraws--;
					}
				} else {
					super.draw(camera, object, parentCanvas);
				}
			} else {
				super.draw(camera, object, parentCanvas);
			}
		}
		
		private function drawNode(node:BSPNode, culling:int, camera:Camera3D, object:Object3D, canvas:Canvas, geometry:Geometry):void {
			var i:int;
			var next:Geometry;
			var negative:Geometry;
			var middle:Geometry;
			var positive:Geometry;
			var negativePart:Geometry;
			var positivePart:Geometry;
			var staticChild:Object3D;
			
			// Узловая нода
			if (node.negative != null) {
				
				var cameraAngle:Number = directionX*node.normalX + directionY*node.normalY + directionZ*node.normalZ;
				
				// Камера сзади ноды
				if (cameraX*node.normalX + cameraY*node.normalY + cameraZ*node.normalZ <= node.offset) {
					drawNode(node.negative, culling, camera, object, canvas, geometry);
					// Если видно переднюю ноду
					if (cameraAngle > -viewAngle) {
						drawNode(node.positive, culling, camera, object, canvas, geometry);
					}
				// Камера спереди ноды
				} else {
					var fragment:Fragment;
					drawNode(node.positive, culling, camera, object, canvas, geometry);
					// Если индекс ноды не совпадает с текущим
					if (node.index != index) {
						if (drawCall.next == null) {
							drawCall.next = new DrawCall();
							drawCall.next.prev = drawCall;
						}
						fragment = clip(node.indices, node.indicesLength, culling, camera.nearClipping, camera.farClipping);
						if (fragment != null) {
							// Новый отрисовочный вызов
							index = node.index;
							drawCall = drawCall.next;
							drawCall.fragment = fragment;
							drawCall.texture = textures[index];
							drawCall.canvas = canvas.getChildCanvas(true, false);
						}
					} else {
						fragment = clip(node.indices, node.indicesLength, culling, camera.nearClipping, camera.farClipping);
						if (fragment != null) {
							var last:Fragment = fragment;
							while (last.next != null) {
								last = last.next;
							}
							last.next = drawCall.fragment;
							drawCall.fragment = fragment;
						}
					}
					// Если видно заднюю ноду
					if (cameraAngle < viewAngle) {
						drawNode(node.negative, culling, camera, object, canvas, geometry);
					}
				}
				
				
			// Конечная нода	
			} else {
				if (node.numObjects > 0 || geometry != null) {
					
					index = -1;
					
				}
			}
		}
		
		private function clip(sourceIndices:Vector.<int>, sourceIndicesLength:int, culling:int, near:Number, far:Number):Fragment {
			var res:Fragment;
			for (var i:int = 0, k:int = 0; i < sourceIndicesLength; i = k) {
				
				k = sourceIndices[i++] + i;
				
				var fragment:Fragment = Fragment.create();
				for (var j:int = i; j < k; j++) {
					fragment.indices[fragment.num] = sourceIndices[j];
					fragment.num++;
				}
				
				fragment.next = res;
				res = fragment;
				
			}
			
			return res;
		}
		
		
		static private const objects:Vector.<Object3D> = new Vector.<Object3D>();
		static private const bounds:Vector.<BoundBox> = new Vector.<BoundBox>();
		static private var objectsLength:int = 0;
		static private const normals:Vector.<Number> = new Vector.<Number>();
		static private const fragments:Vector.<int> = new Vector.<int>();
		static private var fragmentsLength:int = 0;
		static private const planePoints:Vector.<Number> = new Vector.<Number>(9);
		static private const inverseMatrix:Matrix3D = new Matrix3D();
		
		public function createTree(meshes:Vector.<Mesh>, staticObjects:Vector.<Object3D>, boundBox:BoundBox = null):void {
			var i:int;
			var j:int;
			var k:int;
			var ni:int = 0;
			var meshVertices:Vector.<Number> = new Vector.<Number>();
			var meshVerticesLength:int;
			var numFragments:int = 0;
			verticesLength = 0;
			numVertices = 0;
			fragmentsLength = 0;
			objectsLength = 0;
			var objectBoundBox:BoundBox;
			if (boundBox == null) {
				boundBox = new BoundBox();
			}
			// Перебор мешей
			for (i = 0; i < meshes.length; i++) {
				var mesh:Mesh = meshes[i];
				objectBoundBox = mesh.calculateBoundBox(mesh.matrix);
				boundBox.addBoundBox(objectBoundBox);
				// Конвертация в полигональный вид
				if (!mesh.poly) {
					mesh.weldVertices(0.1, 0.01);
					mesh.convertToPoly(0.01, 0.01, 0);
				}
				// Трансформация в координаты контейнера
				meshVerticesLength = mesh.numVertices*3;
				meshVertices.length = meshVerticesLength;
				mesh.matrix.transformVectors(mesh.vertices, meshVertices);
				// Добавление вершин и UV
				for (j = 0; j < meshVerticesLength; j++) {
					vertices[verticesLength] = meshVertices[j];
					uvts[verticesLength] = mesh.uvts[j];
					verticesLength++;
				}
				// Добавление граней
				var meshIndicesLength:int = mesh.indices.length;
				for (j = 0, k = 0; j < meshIndicesLength; j++) {
					if (j == k) {
						var num:int = mesh.indices[j]; j++;
						k += num + 1;
						// Кодирование нормали (16 бит), номера меша (8 бит) и количества вершин в грани (8 бит)
						fragments[fragmentsLength] = (numFragments << 16) + (i << 8) + num;
						fragmentsLength++;
						numFragments++;
						// Расчёт нормали
						var v:int = j;
						var vi:int = mesh.indices[v]*3; v++;
						var ax:Number = meshVertices[vi]; vi++;
						var ay:Number = meshVertices[vi]; vi++;
						var az:Number = meshVertices[vi];
						vi = mesh.indices[v]*3; v++;
						var abx:Number = meshVertices[vi] - ax; vi++;
						var aby:Number = meshVertices[vi] - ay; vi++;
						var abz:Number = meshVertices[vi] - az;
						vi = mesh.indices[v]*3;
						var acx:Number = meshVertices[vi] - ax; vi++;
						var acy:Number = meshVertices[vi] - ay; vi++;
						var acz:Number = meshVertices[vi] - az;
						var nx:Number = acz*aby - acy*abz;
						var ny:Number = acx*abz - acz*abx;
						var nz:Number = acy*abx - acx*aby;
						var nl:Number = 1/Math.sqrt(nx*nx + ny*ny + nz*nz);
						nx *= nl;
						ny *= nl;
						nz *= nl;
						normals[ni] = nx; ni++; 
						normals[ni] = ny; ni++;
						normals[ni] = nz; ni++;
						normals[ni] = ax*nx + ay*ny + az*nz; ni++;
					}
					fragments[fragmentsLength] = numVertices + mesh.indices[j];
					fragmentsLength++;
				}
				numVertices = verticesLength/3;
				// Сохранение текстуры
				textures[i] = mesh.texture;
			}
			vertices.length = verticesLength;
			// Перебор статических объектов
			for (i = 0; i < staticObjects.length; i++) {
				var object:Object3D = staticObjects[i];
				objectBoundBox = object.calculateBoundBox(object.matrix);
				boundBox.addBoundBox(objectBoundBox);
				objects[objectsLength] = object;
				bounds[objectsLength] = objectBoundBox;
				objectsLength++;
			}
			// Создание дерева
			if (fragmentsLength > 0) {
				root = createNode(0, fragmentsLength, 0, objectsLength);
				root.boundBox = boundBox;
			} else if (objectsLength > 0) {
				root = new BSPNode();
				root.boundBox = boundBox;
				for (i = 0; i < objectsLength; i++) {
					root.objects[root.numObjects] = objects[i];
					root.bounds[root.numObjects] = bounds[i];
					root.numObjects++;
				}
			}
			// Очистка вспомогательных векторов
			objects.length = 0;
			bounds.length = 0;
			normals.length = 0;
			fragments.length = 0;
		}
		
		private function createNode(begin:int, end:int, objectsBegin:int, objectsEnd:int):BSPNode {
			var i:int;
			var j:int;
			var k:int;
			var num:int;
			var vi:int;
			var mi:int;
			var n:int;
			var ni:int;
			var infront:Boolean;
			var behind:Boolean;
			var ii:int;
			var normalX:Number;
			var normalY:Number;
			var normalZ:Number;
			var offset:Number;
			var a:int;
			var ai:int;
			var ax:Number;
			var ay:Number;
			var az:Number;
			var ao:Number;
			var b:int;
			var bi:int;
			var bx:Number;
			var by:Number;
			var bz:Number;
			var bo:Number;
			// Определение сплиттера
			var splitter:int;
			var bestSplits:int = int.MAX_VALUE;
			// Перебираем нормали
			for (i = begin; i < end; i += (mi & 0xFF) + 1) {
				var currentSplits:int = 0;
				mi = fragments[i];
				n = mi >> 16;
				ni = n << 2;
				normalX = normals[ni]; ni++;
				normalY = normals[ni]; ni++;
				normalZ = normals[ni]; ni++;
				offset = normals[ni];
				// Перебираем точки граней
				for (j = begin, k = begin; j < end;) {
					if (j == k) {
						k = (fragments[j] & 0xFF) + ++j;
						infront = false;
						behind = false;
					}
					vi = fragments[j]*3;
					ax = vertices[vi]; vi++;
					ay = vertices[vi]; vi++;
					az = vertices[vi];
					ao = ax*normalX + ay*normalY + az*normalZ - offset;
					if (ao < -threshold) {
						behind = true;
						if (infront) {
							j = k - 1;
						}
					} else if (ao > threshold) {
						infront = true;
						if (behind) {
							j = k - 1;
						}
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
					splitter = i;
					bestSplits = currentSplits;
					// Если плоскость ничего не распиливает
					if (bestSplits == 0) break;
				}
			}
			// Построение ноды
			var node:BSPNode = new BSPNode();
			mi = fragments[splitter];
			n = mi >> 16;
			node.index = (mi >> 8) & 0xFF;
			num = mi & 0xFF;
			ni = n << 2;
			node.normalX = normals[ni++];
			node.normalY = normals[ni++];
			node.normalZ = normals[ni++];
			node.offset = normals[ni];
			node.offsetMin = node.offset - threshold;
			node.offsetMax = node.offset + threshold;
			// Разделение объектов
			var negativeObjectsBegin:int = objectsLength;
			var negativeObjectsEnd:int = negativeObjectsBegin;
			var positiveObjectsBegin:int = objectsLength + objectsEnd - objectsBegin;
			var positiveObjectsEnd:int = negativeObjectsBegin;
			objectsLength = positiveObjectsBegin + objectsEnd - objectsBegin;
			objects.length = objectsLength;
			bounds.length = objectsLength;
			for (i = objectsBegin; i < objectsEnd; i++) {
				var object:Object3D = objects[i];
				var boundBox:BoundBox = bounds[i];
				infront = false;
				behind = false;
				if (node.normalX >= 0) if (node.normalY >= 0) if (node.normalZ >= 0) {
					if (boundBox.maxX*node.normalX + boundBox.maxY*node.normalY + boundBox.maxZ*node.normalZ <= node.offsetMax) behind = true;
					else if (boundBox.minX*node.normalX + boundBox.minY*node.normalY + boundBox.minZ*node.normalZ >= node.offsetMin) infront = true;
				} else {
					if (boundBox.maxX*node.normalX + boundBox.maxY*node.normalY + boundBox.minZ*node.normalZ <= node.offsetMax) behind = true;
					else if (boundBox.minX*node.normalX + boundBox.minY*node.normalY + boundBox.maxZ*node.normalZ >= node.offsetMin) infront = true;
				} else if (node.normalZ >= 0) {
					if (boundBox.maxX*node.normalX + boundBox.minY*node.normalY + boundBox.maxZ*node.normalZ <= node.offsetMax) behind = true;
					else if (boundBox.minX*node.normalX + boundBox.maxY*node.normalY + boundBox.minZ*node.normalZ >= node.offsetMin) infront = true;
				} else {
					if (boundBox.maxX*node.normalX + boundBox.minY*node.normalY + boundBox.minZ*node.normalZ <= node.offsetMax) behind = true;
					else if (boundBox.minX*node.normalX + boundBox.maxY*node.normalY + boundBox.maxZ*node.normalZ >= node.offsetMin) infront = true;
				} else if (node.normalY >= 0) if (node.normalZ >= 0) {
					if (boundBox.minX*node.normalX + boundBox.maxY*node.normalY + boundBox.maxZ*node.normalZ <= node.offsetMax) behind = true;
					else if (boundBox.maxX*node.normalX + boundBox.minY*node.normalY + boundBox.minZ*node.normalZ >= node.offsetMin) infront = true;
				} else {
					if (boundBox.minX*node.normalX + boundBox.maxY*node.normalY + boundBox.minZ*node.normalZ <= node.offsetMax) behind = true;
					else if (boundBox.maxX*node.normalX + boundBox.minY*node.normalY + boundBox.maxZ*node.normalZ >= node.offsetMin) infront = true;
				} else if (node.normalZ >= 0) {
					if (boundBox.minX*node.normalX + boundBox.minY*node.normalY + boundBox.maxZ*node.normalZ <= node.offsetMax) behind = true;
					else if (boundBox.maxX*node.normalX + boundBox.maxY*node.normalY + boundBox.minZ*node.normalZ >= node.offsetMin) infront = true;
				} else {
					if (boundBox.minX*node.normalX + boundBox.minY*node.normalY + boundBox.minZ*node.normalZ <= node.offsetMax) behind = true;
					else if (boundBox.maxX*node.normalX + boundBox.maxY*node.normalY + boundBox.maxZ*node.normalZ >= node.offsetMin) infront = true;
				}
				if (behind) {
					objects[negativeObjectsEnd] = object;
					bounds[negativeObjectsEnd] = boundBox;
					negativeObjectsEnd++;
				} else if (infront) {
					objects[positiveObjectsEnd] = object;
					bounds[positiveObjectsEnd] = boundBox;
					positiveObjectsEnd++;
				} else {
					ii = splitter + 1;
					ai = fragments[ii]*3;
					planePoints[0] = vertices[ai]; ai++;
					planePoints[1] = vertices[ai]; ai++;
					planePoints[2] = vertices[ai];
					ii = splitter + 2;
					ai = fragments[ii]*3;
					planePoints[3] = vertices[ai]; ai++;
					planePoints[4] = vertices[ai]; ai++;
					planePoints[5] = vertices[ai];
					ii = splitter + 3;
					ai = fragments[ii]*3;
					planePoints[6] = vertices[ai]; ai++;
					planePoints[7] = vertices[ai]; ai++;
					planePoints[8] = vertices[ai];
					inverseMatrix.identity();
					inverseMatrix.prepend(object.matrix);
					inverseMatrix.invert();
					inverseMatrix.transformVectors(planePoints, planePoints);
					ax = planePoints[0];
					ay = planePoints[1];
					az = planePoints[2];
					var abx:Number = planePoints[3] - ax;
					var aby:Number = planePoints[4] - ay;
					var abz:Number = planePoints[5] - az;
					var acx:Number = planePoints[6] - ax;
					var acy:Number = planePoints[7] - ay;
					var acz:Number = planePoints[8] - az;
					normalX = acz*aby - acy*abz;
					normalY = acx*abz - acz*abx;
					normalZ = acy*abx - acx*aby;
					offset = 1/Math.sqrt(normalX*normalX + normalY*normalY + normalZ*normalZ);
					normalX *= offset;
					normalY *= offset;
					normalZ *= offset;
					offset = ax*normalX + ay*normalY + az*normalZ;
					var parts:Vector.<Object3D> = object.split(normalX, normalY, normalZ, offset, threshold);
					object = parts[0];
					if (object != null) {
						objects[negativeObjectsEnd] = object;
						bounds[negativeObjectsEnd] = object.calculateBoundBox(object.matrix);
						negativeObjectsEnd++;
					}
					object = parts[1];
					if (object != null) {
						objects[positiveObjectsEnd] = object;
						bounds[positiveObjectsEnd] = object.calculateBoundBox(object.matrix);
						positiveObjectsEnd++;
					}
				}
			}
			// Добавление сплиттера в ноду
			k = splitter + num + 1;
			node.indices[node.indicesLength] = num;
			node.indicesLength++;
			for (i = splitter + 1; i < k; i++) {
				node.indices[node.indicesLength] = fragments[i];
				node.indicesLength++;
			}
			// Разделение фрагментов
			var reserve:int = end - begin + ((end - begin) >> 2);
			var negativeBegin:int = fragmentsLength;
			var negativeEnd:int = negativeBegin;
			var positiveBegin:int = fragmentsLength + reserve;
			var positiveEnd:int = positiveBegin;
			if (end - begin > num + 1) {
				fragmentsLength = positiveBegin + reserve;
				fragments.length = fragmentsLength;
				var j1:int = negativeEnd;
				var j2:int = positiveEnd;
				for (i = begin, k = begin, vi = numVertices*3; i < end;) {
					if (i == k) {
						// Пропуск сплиттера
						if (i == splitter) {
							i += (fragments[i] & 0xFF) + 1;
							if (i == end) break;
						}
						// Подготовка к разбиению
						mi = fragments[i];
						num = mi & 0xFF;
						k = num + ++i;
						j1++;
						j2++;
						infront = false;
						behind = false;
						// Первая точка ребра
						ii = k - 1;
						a = fragments[ii];
						ai = a*3;
						ax = vertices[ai]; ii = ai + 1;
						ay = vertices[ii]; ii++;
						az = vertices[ii];
						ao = ax*node.normalX + ay*node.normalY + az*node.normalZ - node.offset;
					}
					// Вторая точка ребра
					b = fragments[i];
					bi = b*3;
					bx = vertices[bi]; ii = bi + 1;
					by = vertices[ii]; ii++;
					bz = vertices[ii];
					bo = bx*node.normalX + by*node.normalY + bz*node.normalZ - node.offset;
					// Рассечение ребра
					if (ao < -threshold && bo > threshold || bo < -threshold && ao > threshold) {
						var t:Number = ao/(ao - bo);
						var au:Number = uvts[ai]; ii = ai + 1;
						var av:Number = uvts[ii];
						var bu:Number = uvts[bi]; ii = bi + 1;
						var bv:Number = uvts[ii];
						vertices[vi] = ax + (bx - ax)*t;
						uvts[vi] = au + (bu - au)*t; vi++;
						vertices[vi] = ay + (by - ay)*t;
						uvts[vi] = av + (bv - av)*t; vi++;
						vertices[vi] = az + (bz - az)*t;
						uvts[vi] = 0; vi++;
						fragments[j1] = numVertices; j1++;
						fragments[j2] = numVertices; j2++;
						numVertices++;
					}
					// Добавление точки
					if (bo < -threshold) {
						fragments[j1] = b; j1++;
						behind = true;
					} else if (bo > threshold) {
						fragments[j2] = b; j2++;
						infront = true;
					} else {
						fragments[j1] = b; j1++;
						fragments[j2] = b; j2++;
					}
					// Анализ разбиения
					if (++i == k) {
						n = mi >> 16;
						ii = (mi >> 8) & 0xFF;
						if (infront && behind) {
							// Фрагмент распилился
							fragments[negativeEnd] = (n << 16) + (ii << 8) + j1 - negativeEnd - 1;
							negativeEnd = j1;
							fragments[positiveEnd] = (n << 16) + (ii << 8) + j2 - positiveEnd - 1;
							positiveEnd = j2;
						} else if (infront) {
							// Фрагмент спереди
							fragments[positiveEnd] = (n << 16) + (ii << 8) + j2 - positiveEnd - 1;
							positiveEnd = j2;
							j1 = negativeEnd;
						} else if (behind) {
							// Фрагмент сзади
							fragments[negativeEnd] = (n << 16) + (ii << 8) + j1 - negativeEnd - 1;
							negativeEnd = j1;
							j2 = positiveEnd;
						} else {
							// Фрагмент в плоскости ноды
							ni = n << 2;
							normalX = normals[ni]; ni++;
							normalY = normals[ni]; ni++;
							normalZ = normals[ni];
							if (node.index == ii && node.normalX*normalX + node.normalY*normalY + node.normalZ*normalZ > 0) {
								// Фрагмент того же меша и сонаправлен ноде
								node.indices[node.indicesLength] = num;
								node.indicesLength++;
								for (j = k - num; j < k; j++) {
									node.indices[node.indicesLength] = fragments[j];
									node.indicesLength++;
								}
								j1 = negativeEnd;
								j2 = positiveEnd;
							} else {
								// Фрагмент другого меша или противонаправлен ноде
								fragments[negativeEnd] = (n << 16) + (ii << 8) + j1 - negativeEnd - 1;
								negativeEnd = j1;
								j2 = positiveEnd;
							}
						}
					} else {
						a = b;
						ai = bi;
						ax = bx;
						ay = by;
						az = bz;
						ao = bo;
					}
				}
			}
			// Разделение заднй части
			if (negativeEnd > negativeBegin) {
				node.negative = createNode(negativeBegin, negativeEnd, negativeObjectsBegin, negativeObjectsEnd);
			} else {
				node.negative = new BSPNode();
				for (i = negativeObjectsBegin; i < negativeObjectsEnd; i++) {
					node.negative.objects[node.negative.numObjects] = objects[i];
					node.negative.bounds[node.negative.numObjects] = bounds[i];
					node.negative.numObjects++;
				}
			}
			// Разделение передней части
			if (positiveEnd > positiveBegin) {
				node.positive = createNode(positiveBegin, positiveEnd, positiveObjectsBegin, positiveObjectsEnd);
			} else {
				node.positive = new BSPNode();
				for (i = positiveObjectsBegin; i < positiveObjectsEnd; i++) {
					node.positive.objects[node.positive.numObjects] = objects[i];
					node.positive.bounds[node.positive.numObjects] = bounds[i];
					node.positive.numObjects++;
				}
			}
			return node;
		}
		
		
	}
}

import __AS3__.vec.Vector;
import alternativa.engine3d.core.BoundBox;
import alternativa.engine3d.core.Object3D;
import alternativa.engine3d.core.Canvas;
import flash.display.BitmapData;
import alternativa.engine3d.core.Fragment;

class BSPNode {

	public var negative:BSPNode;
	public var positive:BSPNode;
	
	public var normalX:Number;
	public var normalY:Number;
	public var normalZ:Number;
	public var offset:Number;
	public var offsetMin:Number;
	public var offsetMax:Number;
	
	public var index:int;
	
	public var indices:Vector.<int> = new Vector.<int>();
	public var indicesLength:int = 0;
	
	public var boundBox:BoundBox;
	
	public var objects:Vector.<Object3D>;
	public var bounds:Vector.<BoundBox>;
	
	public var numObjects:int = 0;
	
}

class DrawCall {
	
	public var next:DrawCall;
	public var prev:DrawCall;
	
	public var texture:BitmapData;
	
	public var canvas:Canvas;
	
	public var fragment:Fragment;
	
	//public var indices:Vector.<int> = new Vector.<int>();
	//public var indicesLength:int = 0;
	
}
