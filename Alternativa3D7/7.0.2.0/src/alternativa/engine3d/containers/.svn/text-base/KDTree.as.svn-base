package alternativa.engine3d.containers {
	
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.KDNode;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	import alternativa.engine3d.objects.KDObject;
	import alternativa.engine3d.objects.Occluder;
	import alternativa.engine3d.objects.Reference;
	import alternativa.engine3d.objects.WireBoundBox;
	import alternativa.engine3d.objects.WireQuad;
	
	import flash.display.DisplayObject;
	import flash.geom.Matrix3D;
	
	use namespace alternativa3d;
		
	/**
	 * Контейнер, дочерние объекты которого помещены в бинарную древовидную структуру.
	 * Для построения дерева нужно добавить статические дочерние объекты 
	 * с помощью addStaticChild(), затем вызвать createTree(). По баундам статических объектов
	 * построится ориентированная по осям бинарная древовидная структура (KD - частный случай BSP).
	 * Динамические объекты, можно в любое время добавлять addDynamicChild() и удалять removeDynamicChild().
	 * Объекты, добавленные с помощью addChild() будут отрисовываться поверх всего в порядке добавления.
	 */
	public class KDTree extends Object3DContainer {
		
		/**
		 * Геометрическая погрешность. 
		 */
		public var threshold:Number = 0.1;
		
		/**
		 * @private 
		 */
		alternativa3d var _numStaticChildren:int = 0;
		/**
		 * @private 
		 */
		alternativa3d var _numDynamicChildren:int = 0;
		/**
		 * @private 
		 */
		alternativa3d var staticChildren:Vector.<Object3D> = new Vector.<Object3D>();
		/**
		 * @private 
		 */
		alternativa3d var dynamicChildren:Vector.<Object3D> = new Vector.<Object3D>();
		
		private var rootNode:KDNode;
		
		static private const kdObjects:Vector.<KDObject> = new Vector.<KDObject>();
		static private var kdObjectsRealLength:int;
		private var kdObjectsLength:int;
		
		// Камера в контейнере
		static private const inverseCameraMatrix:Matrix3D = new Matrix3D();
		private var cameraX:Number;
		private var cameraY:Number;
		private var cameraZ:Number;		
		
		// Плоскости отсечения
		static private const cameraPlanes:Vector.<Number> = new Vector.<Number>(21, true);
		private var nearPlaneX:Number;
		private var nearPlaneY:Number;
		private var nearPlaneZ:Number;
		private var nearPlaneOffset:Number;
		private var farPlaneX:Number;
		private var farPlaneY:Number;
		private var farPlaneZ:Number;
		private var farPlaneOffset:Number;
		private var leftPlaneX:Number;
		private var leftPlaneY:Number;
		private var leftPlaneZ:Number;
		private var leftPlaneOffset:Number;
		private var rightPlaneX:Number;
		private var rightPlaneY:Number;
		private var rightPlaneZ:Number;
		private var rightPlaneOffset:Number;
		private var topPlaneX:Number;
		private var topPlaneY:Number;
		private var topPlaneZ:Number;
		private var topPlaneOffset:Number;
		private var bottomPlaneX:Number;
		private var bottomPlaneY:Number;
		private var bottomPlaneZ:Number;
		private var bottomPlaneOffset:Number;

		// Перекрытия
		private var occluders:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
		private var numOccluders:int;
		static private var edgeOccluder:Vector.<Number> = new Vector.<Number>();
		
		/**
		 * @private 
		 */
		override alternativa3d function get canDraw():Boolean {
			return _numChildren > 0 || rootNode != null || _numDynamicChildren > 0;
		}
		
		/**
		 * Построение дерева на базе добавленных статических дочерних объектов. 
		 * @param boundBox Изначально заданный баунд. 
		 * Он расширяется, если статические объекты не помещаются в него. 
		 */
		public function createTree(boundBox:BoundBox = null):void {
			if (_numStaticChildren == 0) return;
			// Создаём корневую ноду
			rootNode = new KDNode();
			rootNode.objects = new Vector.<Object3D>();
			rootNode.bounds = new Vector.<BoundBox>();
			rootNode.numObjects = 0;
			// Расчитываем баунды объектов и рутовой ноды
			var rootNodeBoundBox:BoundBox = rootNode.boundBox = (boundBox != null) ? boundBox : new BoundBox();
			// Сначала добавляем не окклюдеры
			var staticOccluders:Vector.<Object3D> = new Vector.<Object3D>(), staticOccludersLength:int = 0;
			for (var i:int = 0; i < _numStaticChildren; i++) {
				var child:Object3D = staticChildren[i];
				// Поиск оригинального объекта
				var source:Object3D = child;
				while (source is Reference) source = (source as Reference).referenceObject;
				// Если окклюдер
				if (source is Occluder) {
					staticOccluders[staticOccludersLength++] = child;
				} else {
					var childBoundBox:BoundBox = child.calculateBoundBox(child.matrix);
					rootNode.objects[rootNode.numObjects] = child, rootNode.bounds[rootNode.numObjects++] = childBoundBox;
					rootNodeBoundBox.addBoundBox(childBoundBox);
				}
			}
			// Добавляем окклюдеры
			for (i = 0; i < staticOccludersLength; i++) {
				child = staticOccluders[i];
				childBoundBox = child.calculateBoundBox(child.matrix);
				rootNode.objects[rootNode.numObjects] = child, rootNode.bounds[rootNode.numObjects++] = childBoundBox;
				rootNodeBoundBox.addBoundBox(childBoundBox);
			}
			// Разделяем рутовую ноду
			splitNode(rootNode);
		}
		
		public function traceTree():void {
			traceNode("", rootNode);
		}
		
		private function traceNode(str:String, node:KDNode):void {
			if (node == null) return;
			trace(str, (node.axis == 0) ? "X" : ((node.axis == 1) ? "Y" : "Z"), "objs:", node.objects);
			traceNode(str + "-", node.negative);
			traceNode(str + "-", node.positive);
		}
		
		/**
		 * Для отображения нод дерева. Метод нужно вызвать один раз после построения дерева. 
		 */
		public function addWireBounds(container:Object3DContainer, alphaCoeff:Number = 0.8):void {
			if (rootNode != null) {
				var w:WireBoundBox = new WireBoundBox();
				w.boundBox = rootNode.boundBox;
				container.addChild(w);
				
				addNodeWireBounds(container, rootNode, 1, alphaCoeff);
			}
		}
		
		private function addNodeWireBounds(container:Object3DContainer, node:KDNode, alpha:Number, alphaCoeff:Number):void {
			if (node == null) return;
			
			var w:WireQuad = new WireQuad();
			w.alpha = alpha;
			if (node.axis == 0) {
				w.vertices = Vector.<Number>([
					node.coord, node.boundBox.minY, node.boundBox.minZ,
					node.coord, node.boundBox.minY, node.boundBox.maxZ,
					node.coord, node.boundBox.maxY, node.boundBox.maxZ,
					node.coord, node.boundBox.maxY, node.boundBox.minZ,
					]);
				w.color = 0xFF0000;
			} else if (node.axis == 1) {
				w.vertices = Vector.<Number>([
					node.boundBox.minX, node.coord, node.boundBox.minZ,
					node.boundBox.minX, node.coord, node.boundBox.maxZ,
					node.boundBox.maxX, node.coord, node.boundBox.maxZ,
					node.boundBox.maxX, node.coord, node.boundBox.minZ,
					]);
				w.color = 0x00FF00;
			} else {
				w.vertices = Vector.<Number>([
					node.boundBox.minX, node.boundBox.minY, node.coord,
					node.boundBox.minX, node.boundBox.maxY, node.coord,
					node.boundBox.maxX, node.boundBox.maxY, node.coord,
					node.boundBox.maxX, node.boundBox.minY, node.coord,
					]);
				w.color = 0x0000FF;
			}
			container.addChild(w);
			
			alpha *= alphaCoeff;

			addNodeWireBounds(container, node.negative, alpha, alphaCoeff);
			addNodeWireBounds(container, node.positive, alpha, alphaCoeff);
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			// Определяем видимые объекты
			numVisibleChildren = 0;
			calculateVisibleChildren(camera, object);
			// Если есть видимые дочерние объекты, расчитываем порядок отрисовки
			if (numVisibleChildren > 0) calculateOrder(camera, object);
			// Отрисовка видимых объектов
			drawVisibleChildren(camera, object, parentCanvas);
		}
		
		// Отрисовка KD-дерева
		override protected function drawBack(camera:Camera3D, object:Object3D, canvas:Canvas):void {
			// Подготовка камеры к отсечению в координатах контейнера
			if (rootNode != null || _numDynamicChildren > 0) {

				// Матрица камеры в контейнере
				inverseCameraMatrix.identity();
				inverseCameraMatrix.prepend(object.cameraMatrix);
				inverseCameraMatrix.invert();
				
				// Перевод плоскостей камеры в пространство контейнера
				cameraPlanes[0] = cameraPlanes[1] = cameraPlanes[2] = cameraPlanes[3] = cameraPlanes[4] = cameraPlanes[6] = cameraPlanes[7] = 0;
				cameraPlanes[5] = camera.nearClipping;
				cameraPlanes[8] = camera.farClipping;
				cameraPlanes[9] = cameraPlanes[10] = cameraPlanes[13] = cameraPlanes[18] = -1;
				cameraPlanes[11] = cameraPlanes[12] = cameraPlanes[14] = cameraPlanes[15] = cameraPlanes[16] = cameraPlanes[17] = cameraPlanes[19] = cameraPlanes[20] = 1;
				inverseCameraMatrix.transformVectors(cameraPlanes, cameraPlanes);
				
				// Расчёт координат камеры в контейнере
				cameraX = cameraPlanes[0];
				cameraY = cameraPlanes[1];
				cameraZ = cameraPlanes[2];
	
				// Ближняя плоскость
				var bax:Number = cameraPlanes[9] - cameraPlanes[12];
				var bay:Number = cameraPlanes[10] - cameraPlanes[13];
				var baz:Number = cameraPlanes[11] - cameraPlanes[14];
				var bcx:Number = cameraPlanes[15] - cameraPlanes[12];
				var bcy:Number = cameraPlanes[16] - cameraPlanes[13];
				var bcz:Number = cameraPlanes[17] - cameraPlanes[14];
				nearPlaneX = bcy*baz - bcz*bay;
				nearPlaneY = bcz*bax - bcx*baz;
				nearPlaneZ = bcx*bay - bcy*bax;
				nearPlaneOffset = cameraPlanes[3]*nearPlaneX + cameraPlanes[4]*nearPlaneY + cameraPlanes[5]*nearPlaneZ;
				
				// Дальняя плоскость
				farPlaneX = -nearPlaneX;
				farPlaneY = -nearPlaneY;
				farPlaneZ = -nearPlaneZ;
				farPlaneOffset = cameraPlanes[6]*farPlaneX + cameraPlanes[7]*farPlaneY + cameraPlanes[8]*farPlaneZ;
	
				// Рёбра пирамиды
				var ax:Number = cameraPlanes[9] - cameraX;
				var ay:Number = cameraPlanes[10] - cameraY;
				var az:Number = cameraPlanes[11] - cameraZ;
				var bx:Number = cameraPlanes[12] - cameraX;
				var by:Number = cameraPlanes[13] - cameraY;
				var bz:Number = cameraPlanes[14] - cameraZ;
				var cx:Number = cameraPlanes[15] - cameraX;
				var cy:Number = cameraPlanes[16] - cameraY;
				var cz:Number = cameraPlanes[17] - cameraZ;
				var dx:Number = cameraPlanes[18] - cameraX;
				var dy:Number = cameraPlanes[19] - cameraY;
				var dz:Number = cameraPlanes[20] - cameraZ;
	
				// Левая плоскость
				leftPlaneX = dy*az - dz*ay;
				leftPlaneY = dz*ax - dx*az;
				leftPlaneZ = dx*ay - dy*ax;
				leftPlaneOffset = cameraX*leftPlaneX + cameraY*leftPlaneY + cameraZ*leftPlaneZ;
				
				// Правая плоскость
				rightPlaneX = by*cz - bz*cy;
				rightPlaneY = bz*cx - bx*cz;
				rightPlaneZ = bx*cy - by*cx;
				rightPlaneOffset = cameraX*rightPlaneX + cameraY*rightPlaneY + cameraZ*rightPlaneZ;
	  
				// Верхняя плоскость
				topPlaneX = ay*bz - az*by;
				topPlaneY = az*bx - ax*bz;
				topPlaneZ = ax*by - ay*bx;
				topPlaneOffset = cameraX*topPlaneX + cameraY*topPlaneY + cameraZ*topPlaneZ;
	
				// Нижняя плоскость
				bottomPlaneX = cy*dz - cz*dy;
				bottomPlaneY = cz*dx - cx*dz;
				bottomPlaneZ = cx*dy - cy*dx;
				bottomPlaneOffset = cameraX*bottomPlaneX + cameraY*bottomPlaneY + cameraZ*bottomPlaneZ;
				
				// Окклюдеры
				numOccluders = 0;
				if (camera.numOccluders > 0) updateOccluders(camera);
			}
			// Подготовка динамических объектов
			kdObjectsLength = 0;
			KDObject.normalsSetLength = 0;
			if (_numDynamicChildren > 0) {
				var kdObject:KDObject;
				for (var i:int = 0; i < _numDynamicChildren; i++) {
					var child:Object3D = dynamicChildren[i];
					if (child.visible && child.canDraw) {
						child.cameraMatrix.identity();
						child.cameraMatrix.prepend(object.cameraMatrix);
						child.cameraMatrix.prepend(child.matrix);
						// Если объект попадает в пирамиду видимости
						if (child.cullingInCamera(camera, object.culling) >= 0) {
							// Создаём KD-объект
							if ((kdObject = KDObject.createFrom(child, camera, inverseCameraMatrix)) != null) kdObjects[kdObjectsLength++] = kdObject;
						}
					}
				}
				// Если необходимо, увеличиваем реальный размер массива KD-объектов
				if (kdObjectsLength > kdObjectsRealLength) kdObjectsRealLength = kdObjectsLength;
			}
			if (rootNode != null) {
				// Отрисовка дерева
				var culling:int;
				if ((culling = cullingInContainer(camera, rootNode.boundBox, object.culling)) >= 0) {
					drawNode(rootNode, culling, camera, object, canvas, 0, kdObjectsLength);
				}
			} else {
				// Отрисовка только динамических объектов
				if (kdObjectsLength > 0) {
					if (kdObjectsLength > 1) {
						drawKDObjects(camera, object, canvas, 0, kdObjectsLength);
					} else {
						(kdObject = kdObjects[0]).draw(camera, object, canvas),	kdObjects[0] = null, kdObject.destroy();
					}
				}
			}
		}
		
		private function updateOccluders(camera:Camera3D):void {
			for (var o:int = numOccluders, occluder:Vector.<Number>; o < camera.numOccluders; o++) {
				var cameraEdgeOccluder:Vector.<Number> = camera.occlusionEdges[o], edgeOccluderLength:int = cameraEdgeOccluder.length;
				edgeOccluder.length = edgeOccluderLength;
				// Перевод точек рёбер окклюдеров в пространство контейнера
				inverseCameraMatrix.transformVectors(cameraEdgeOccluder, edgeOccluder);
				// Создание окклюдера в контейнере
				if (occluders.length > numOccluders) occluder = occluders[numOccluders++] else occluder = occluders[numOccluders++] = new Vector.<Number>();
				// Построение плоскостей отсечения
				for (var i:int = 0, ni:int = 0, nx:Number, ny:Number, nz:Number; i < edgeOccluderLength;) {
					var ax:Number = edgeOccluder[i++] - cameraX, ay:Number = edgeOccluder[i++] - cameraY, az:Number = edgeOccluder[i++] - cameraZ, bx:Number = edgeOccluder[i++] - cameraX, by:Number = edgeOccluder[i++] - cameraY, bz:Number = edgeOccluder[i++] - cameraZ;
					occluder[ni++] = nx = bz*ay - by*az, occluder[ni++] = ny = bx*az - bz*ax, occluder[ni++] = nz = by*ax - bx*ay, occluder[ni++] = cameraX*nx + cameraY*ny + cameraZ*nz;
				}
				occluder.length = ni;
			}	
		}
		
		private function cullingInContainer(camera:Camera3D, boundBox:BoundBox, culling:int):int {
			if (camera.occludedAll) return -1;
			if (culling > 0) {
				// Отсечение по ниар
				if (culling & 1) {
					if (nearPlaneX >= 0) if (nearPlaneY >= 0) if (nearPlaneZ >= 0) {
						if (boundBox.maxX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.maxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.minX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.minZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundBox.maxX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.minZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.minX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.maxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else if (nearPlaneZ >= 0) {
						if (boundBox.maxX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.maxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.minX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.minZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundBox.maxX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.minZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.minX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.maxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else if (nearPlaneY >= 0) if (nearPlaneZ >= 0) {
						if (boundBox.minX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.maxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.maxX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.minZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundBox.minX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.minZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.maxX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.maxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else if (nearPlaneZ >= 0) {
						if (boundBox.minX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.maxZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.maxX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.minZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					} else {
						if (boundBox.minX*nearPlaneX + boundBox.minY*nearPlaneY + boundBox.minZ*nearPlaneZ <= nearPlaneOffset) return -1;
						if (boundBox.maxX*nearPlaneX + boundBox.maxY*nearPlaneY + boundBox.maxZ*nearPlaneZ > nearPlaneOffset) culling &= 62;
					}
				}
				// Отсечение по фар
				if (culling & 2) {
					if (farPlaneX >= 0) if (farPlaneY >= 0) if (farPlaneZ >= 0) {
						if (boundBox.maxX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.maxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.minX*farPlaneX + boundBox.minY*farPlaneY + boundBox.minZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundBox.maxX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.minZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.minX*farPlaneX + boundBox.minY*farPlaneY + boundBox.maxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else if (farPlaneZ >= 0) {
						if (boundBox.maxX*farPlaneX + boundBox.minY*farPlaneY + boundBox.maxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.minX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.minZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundBox.maxX*farPlaneX + boundBox.minY*farPlaneY + boundBox.minZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.minX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.maxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else if (farPlaneY >= 0) if (farPlaneZ >= 0) {
						if (boundBox.minX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.maxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.maxX*farPlaneX + boundBox.minY*farPlaneY + boundBox.minZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundBox.minX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.minZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.maxX*farPlaneX + boundBox.minY*farPlaneY + boundBox.maxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else if (farPlaneZ >= 0) {
						if (boundBox.minX*farPlaneX + boundBox.minY*farPlaneY + boundBox.maxZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.maxX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.minZ*farPlaneZ > farPlaneOffset) culling &= 61;
					} else {
						if (boundBox.minX*farPlaneX + boundBox.minY*farPlaneY + boundBox.minZ*farPlaneZ <= farPlaneOffset) return -1;
						if (boundBox.maxX*farPlaneX + boundBox.maxY*farPlaneY + boundBox.maxZ*farPlaneZ > farPlaneOffset) culling &= 61;
					}
				}
				// Отсечение по левой стороне
				if (culling & 4) {
					if (leftPlaneX >= 0) if (leftPlaneY >= 0) if (leftPlaneZ >= 0) {
						if (boundBox.maxX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.maxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.minX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.minZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundBox.maxX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.minZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.minX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.maxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else if (leftPlaneZ >= 0) {
						if (boundBox.maxX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.maxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.minX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.minZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundBox.maxX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.minZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.minX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.maxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else if (leftPlaneY >= 0) if (leftPlaneZ >= 0) {
						if (boundBox.minX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.maxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.maxX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.minZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundBox.minX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.minZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.maxX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.maxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else if (leftPlaneZ >= 0) {
						if (boundBox.minX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.maxZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.maxX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.minZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					} else {
						if (boundBox.minX*leftPlaneX + boundBox.minY*leftPlaneY + boundBox.minZ*leftPlaneZ <= leftPlaneOffset) return -1;
						if (boundBox.maxX*leftPlaneX + boundBox.maxY*leftPlaneY + boundBox.maxZ*leftPlaneZ > leftPlaneOffset) culling &= 59;
					}
				}
				// Отсечение по правой стороне
				if (culling & 8) {
					if (rightPlaneX >= 0) if (rightPlaneY >= 0) if (rightPlaneZ >= 0) {
						if (boundBox.maxX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.maxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.minX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.minZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundBox.maxX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.minZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.minX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.maxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else if (rightPlaneZ >= 0) {
						if (boundBox.maxX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.maxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.minX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.minZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundBox.maxX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.minZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.minX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.maxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else if (rightPlaneY >= 0) if (rightPlaneZ >= 0) {
						if (boundBox.minX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.maxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.maxX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.minZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundBox.minX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.minZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.maxX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.maxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else if (rightPlaneZ >= 0) {
						if (boundBox.minX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.maxZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.maxX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.minZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					} else {
						if (boundBox.minX*rightPlaneX + boundBox.minY*rightPlaneY + boundBox.minZ*rightPlaneZ <= rightPlaneOffset) return -1;
						if (boundBox.maxX*rightPlaneX + boundBox.maxY*rightPlaneY + boundBox.maxZ*rightPlaneZ > rightPlaneOffset) culling &= 55;
					}
				}
				// Отсечение по верхней стороне
				if (culling & 16) {
					if (topPlaneX >= 0) if (topPlaneY >= 0) if (topPlaneZ >= 0) {
						if (boundBox.maxX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.maxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.minX*topPlaneX + boundBox.minY*topPlaneY + boundBox.minZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundBox.maxX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.minZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.minX*topPlaneX + boundBox.minY*topPlaneY + boundBox.maxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else if (topPlaneZ >= 0) {
						if (boundBox.maxX*topPlaneX + boundBox.minY*topPlaneY + boundBox.maxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.minX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.minZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundBox.maxX*topPlaneX + boundBox.minY*topPlaneY + boundBox.minZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.minX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.maxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else if (topPlaneY >= 0) if (topPlaneZ >= 0) {
						if (boundBox.minX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.maxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.maxX*topPlaneX + boundBox.minY*topPlaneY + boundBox.minZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundBox.minX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.minZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.maxX*topPlaneX + boundBox.minY*topPlaneY + boundBox.maxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else if (topPlaneZ >= 0) {
						if (boundBox.minX*topPlaneX + boundBox.minY*topPlaneY + boundBox.maxZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.maxX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.minZ*topPlaneZ > topPlaneOffset) culling &= 47;
					} else {
						if (boundBox.minX*topPlaneX + boundBox.minY*topPlaneY + boundBox.minZ*topPlaneZ <= topPlaneOffset) return -1;
						if (boundBox.maxX*topPlaneX + boundBox.maxY*topPlaneY + boundBox.maxZ*topPlaneZ > topPlaneOffset) culling &= 47;
					}
				}
				// Отсечение по нижней стороне
				if (culling & 32) {
					if (bottomPlaneX >= 0) if (bottomPlaneY >= 0) if (bottomPlaneZ >= 0) {
						if (boundBox.maxX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.minX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.minZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundBox.maxX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.minZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.minX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else if (bottomPlaneZ >= 0) {
						if (boundBox.maxX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.minX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.minZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundBox.maxX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.minZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.minX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else if (bottomPlaneY >= 0) if (bottomPlaneZ >= 0) {
						if (boundBox.minX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.maxX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.minZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundBox.minX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.minZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.maxX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else if (bottomPlaneZ >= 0) {
						if (boundBox.minX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.maxX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.minZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					} else {
						if (boundBox.minX*bottomPlaneX + boundBox.minY*bottomPlaneY + boundBox.minZ*bottomPlaneZ <= bottomPlaneOffset) return -1;
						if (boundBox.maxX*bottomPlaneX + boundBox.maxY*bottomPlaneY + boundBox.maxZ*bottomPlaneZ > bottomPlaneOffset) culling &= 31;
					}
				}
			}
			// Отсечение по окклюдерам
			for (var o:int = 0; o < numOccluders; o++) {
				var occluder:Vector.<Number> = occluders[o], occluderLength:int = occluder.length;
				for (var ni:int = 0; ni < occluderLength; ni += 4) {
					var nx:Number = occluder[ni], ny:Number = occluder[int(ni + 1)], nz:Number = occluder[int(ni + 2)], no:Number = occluder[int(ni + 3)];
					if (nx >= 0) if (ny >= 0) if (nz >= 0) {
						if (boundBox.maxX*nx + boundBox.maxY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.maxX*nx + boundBox.maxY*ny + boundBox.minZ*nz > no) break;
					} else if (nz >= 0) {
						if (boundBox.maxX*nx + boundBox.minY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.maxX*nx + boundBox.minY*ny + boundBox.minZ*nz > no) break;
					} else if (ny >= 0) if (nz >= 0) {
						if (boundBox.minX*nx + boundBox.maxY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.minX*nx + boundBox.maxY*ny + boundBox.minZ*nz > no) break;
					} else if (nz >= 0) {
						if (boundBox.minX*nx + boundBox.minY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.minX*nx + boundBox.minY*ny + boundBox.minZ*nz > no) break;
					}
				}
				if (ni == occluderLength) return -1;
			}
			return culling;
		}
		
		private function cullKDObject(camera:Camera3D, kdObject:KDObject):Boolean {
			if (camera.occludedAll) return true;
			for (var o:int = kdObject.numCheckedOccluders, boundBox:BoundBox = kdObject._boundBox; o < numOccluders; o++) {
				var occluder:Vector.<Number> = occluders[o], occluderLength:int = occluder.length;
				for (var ni:int = 0; ni < occluderLength; ni += 4) {
					var nx:Number = occluder[ni], ny:Number = occluder[int(ni + 1)], nz:Number = occluder[int(ni + 2)], no:Number = occluder[int(ni + 3)];
					if (nx >= 0) if (ny >= 0) if (nz >= 0) {
						if (boundBox.maxX*nx + boundBox.maxY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.maxX*nx + boundBox.maxY*ny + boundBox.minZ*nz > no) break;
					} else if (nz >= 0) {
						if (boundBox.maxX*nx + boundBox.minY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.maxX*nx + boundBox.minY*ny + boundBox.minZ*nz > no) break;
					} else if (ny >= 0) if (nz >= 0) {
						if (boundBox.minX*nx + boundBox.maxY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.minX*nx + boundBox.maxY*ny + boundBox.minZ*nz > no) break;
					} else if (nz >= 0) {
						if (boundBox.minX*nx + boundBox.minY*ny + boundBox.maxZ*nz > no) break;
					} else {
						if (boundBox.minX*nx + boundBox.minY*ny + boundBox.minZ*nz > no) break;
					}
				}
				if (ni == occluderLength) return true;
			}
			kdObject.numCheckedOccluders = numOccluders;
			return false;
		}
			
		// Отрисовка ноды
		private function drawNode(node:KDNode, culling:int, camera:Camera3D, object:Object3D, canvas:Canvas, begin:int, end:int):void {
			var kdObject:KDObject, i:int, nodeObjects:Vector.<Object3D> = node.objects, nodeNumObjects:int = node.numObjects, nodeNumNonOccluders:int = node.numNonOccluders, staticChild:Object3D, displayObject:DisplayObject;
			var negativeBegin:int, negativeEnd:int, nodeBegin:int, nodeEnd:int, positiveBegin:int, positiveEnd:int;
			if (camera.occludedAll) {
				for (i = begin; i < end; i++) kdObject = kdObjects[i], kdObjects[i] = null, kdObject.destroy();
				return;
			}
			if (node.negative != null) {
				// Узловая нода
				var negativeCulling:int = (culling > 0 || numOccluders > 0) ? cullingInContainer(camera, node.negative.boundBox, culling) : 0;
				var positiveCulling:int = (culling > 0 || numOccluders > 0) ? cullingInContainer(camera, node.positive.boundBox, culling) : 0;
				var axisX:Boolean = node.axis == 0, axisY:Boolean = node.axis == 1;
				var min:Number, max:Number;
				var negative:KDObject, positive:KDObject;
				// Если видны обе дочерние ноды
				if (negativeCulling >= 0 && positiveCulling >= 0) {
					// Если есть динамические объекты
					if (begin < end) {
						// Делаем резерв для KD-объектов
						negativeBegin = negativeEnd = kdObjectsLength, nodeBegin = nodeEnd = negativeBegin + end - begin, positiveBegin = positiveEnd = nodeBegin + end - begin;
						if ((kdObjectsLength = positiveBegin + end - begin) > kdObjectsRealLength) kdObjects.length = kdObjectsRealLength = kdObjectsLength;
						// Разделяем
						for (i = begin; i < end; i++) {
							kdObject = kdObjects[i], kdObjects[i] = null;
							// Проверка с окклюдерами
							if (kdObject.numCheckedOccluders < numOccluders && cullKDObject(camera, kdObject)) {
								kdObject.destroy();
								continue;
							}
							min = axisX ? kdObject._boundBox.minX : (axisY ? kdObject._boundBox.minY : kdObject._boundBox.minZ);
							max = axisX ? kdObject._boundBox.maxX : (axisY ? kdObject._boundBox.maxY : kdObject._boundBox.maxZ);
							if (max <= node.maxCoord) {
								if (min < node.minCoord) kdObjects[negativeEnd++] = kdObject;
								else kdObjects[nodeEnd++] = kdObject;
							} else {
								if (min >= node.minCoord) kdObjects[positiveEnd++] = kdObject;
								else {
									// Попилился
									kdObject.split(axisX, axisY, node.coord, threshold, negative = kdObject.create(), positive = kdObject.create()), kdObject.destroy();
									if (negative.numVertices > 0) kdObjects[negativeEnd++] = negative else negative.destroy();
									if (positive.numVertices > 0) kdObjects[positiveEnd++] = positive else positive.destroy();
								}
							}
						}
					}
					// Отрисовка дочерних нод и объектов в плоскости
					if (axisX && cameraX > node.coord || axisY && cameraY > node.coord || !axisX && !axisY && cameraZ > node.coord) {
						// Отрисовка позитивной ноды
						drawNode(node.positive, positiveCulling, camera, object, canvas, positiveBegin, positiveEnd);
						// Отрисовка динамических объектов в ноде
						for (i = nodeBegin; i < nodeEnd; i++) {
							kdObject = kdObjects[i], kdObjects[i] = null;
							// Проверка с окклюдерами и отрисовка
							if (kdObject.numCheckedOccluders == numOccluders || !cullKDObject(camera, kdObject)) kdObject.draw(camera, object, canvas);
							kdObject.destroy();
						}
						// Отрисовка плоских статических объектов в ноде
						for (i = 0; i < nodeNumObjects; i++) {
							staticChild = nodeObjects[i]; 
							if (staticChild.visible && staticChild.canDraw && ((staticChild.culling = culling) == 0 && numOccluders == 0 || (staticChild.culling = cullingInContainer(camera, node.bounds[i], culling)) >= 0)) {
								staticChild.cameraMatrix.identity();
								staticChild.cameraMatrix.prepend(object.cameraMatrix);
								staticChild.cameraMatrix.prepend(staticChild.matrix);
								staticChild.draw(camera, staticChild, canvas);
							}
						}
						// Обновление окклюдеров
						if (nodeNumObjects > nodeNumNonOccluders) updateOccluders(camera);
						// Отрисовка негативной ноды
						drawNode(node.negative, negativeCulling, camera, object, canvas, negativeBegin, negativeEnd); 
					} else {
						// Отрисовка негативной ноды
						drawNode(node.negative, negativeCulling, camera, object, canvas, negativeBegin, negativeEnd);
						// Отрисовка динамических объектов в ноде
						for (i = nodeBegin; i < nodeEnd; i++) {
							kdObject = kdObjects[i], kdObjects[i] = null;
							// Проверка с окклюдерами и отрисовка
							if (kdObject.numCheckedOccluders == numOccluders || !cullKDObject(camera, kdObject)) kdObject.draw(camera, object, canvas);
							kdObject.destroy();
						}
						// Отрисовка статических объектов в ноде
						for (i = 0; i < nodeNumObjects; i++) {
							staticChild = nodeObjects[i]; 
							if (staticChild.visible && staticChild.canDraw && ((staticChild.culling = culling) == 0 && numOccluders == 0 || (staticChild.culling = cullingInContainer(camera, node.bounds[i], culling)) >= 0)) {
								staticChild.cameraMatrix.identity();
								staticChild.cameraMatrix.prepend(object.cameraMatrix);
								staticChild.cameraMatrix.prepend(staticChild.matrix);
								staticChild.draw(camera, staticChild, canvas);
							}
						}
						// Обновление окклюдеров
						if (nodeNumObjects > nodeNumNonOccluders) updateOccluders(camera);
						// Отрисовка позитивной ноды
						drawNode(node.positive, positiveCulling, camera, object, canvas, positiveBegin, positiveEnd);
					}
				} else {
					// Если видна только негативная
					if (negativeCulling >= 0) {
						// Если есть динамические объекты
						if (begin < end) {
							// Делаем резерв для KD-объектов
							negativeBegin = negativeEnd = kdObjectsLength;
							if ((kdObjectsLength = negativeBegin + end - begin) > kdObjectsRealLength) kdObjects.length = kdObjectsRealLength = kdObjectsLength;
							// Разделяем
							for (i = begin; i < end; i++) {
								kdObject = kdObjects[i], kdObjects[i] = null;
								// Проверка с окклюдерами
								if (kdObject.numCheckedOccluders < numOccluders && cullKDObject(camera, kdObject)) {
									kdObject.destroy();
									continue;
								}
								min = axisX ? kdObject._boundBox.minX : (axisY ? kdObject._boundBox.minY : kdObject._boundBox.minZ);
								max = axisX ? kdObject._boundBox.maxX : (axisY ? kdObject._boundBox.maxY : kdObject._boundBox.maxZ);
								if (max <= node.maxCoord) kdObjects[negativeEnd++] = kdObject;
								else if (min < node.minCoord) {
									// Подрезаем
									kdObject.crop(axisX, axisY, node.coord, threshold, false, negative = kdObject.create()), kdObject.destroy();
									if (negative.verticesLength > 0) kdObjects[negativeEnd++] = negative else negative.destroy();
								}
							}
						}
						// Отрисовка негативной ноды
						drawNode(node.negative, negativeCulling, camera, object, canvas, negativeBegin, negativeEnd);
					// Если видна только позитивная
					} else if (positiveCulling >= 0) {
						// Если есть динамические объекты
						if (begin < end) {
							// Делаем резерв для KD-объектов
							positiveBegin = positiveEnd = kdObjectsLength;
							if ((kdObjectsLength = positiveBegin + end - begin) > kdObjectsRealLength) kdObjects.length = kdObjectsRealLength = kdObjectsLength;
							// Разделяем
							for (i = begin; i < end; i++) {
								kdObject = kdObjects[i], kdObjects[i] = null;
								// Проверка с окклюдерами
								if (kdObject.numCheckedOccluders < numOccluders && cullKDObject(camera, kdObject)) {
									kdObject.destroy();
									continue;
								}
								min = axisX ? kdObject._boundBox.minX : (axisY ? kdObject._boundBox.minY : kdObject._boundBox.minZ);
								max = axisX ? kdObject._boundBox.maxX : (axisY ? kdObject._boundBox.maxY : kdObject._boundBox.maxZ);
								if (min >= node.minCoord) kdObjects[positiveEnd++] = kdObject;
								else if (max > node.maxCoord) {
									// Подрезаем
									kdObject.crop(axisX, axisY, node.coord, threshold, true, positive = kdObject.create()), kdObject.destroy();
									if (positive.verticesLength > 0) kdObjects[positiveEnd++] = positive else positive.destroy();
								}
							}
						}
						// Отрисовка позитивной ноды
						drawNode(node.positive, positiveCulling, camera, object, canvas, positiveBegin, positiveEnd);
					}
				}
			} else {
				// Конечная нода
				// Если есть статические объекты, не считая окклюдеры
				if (nodeNumNonOccluders > 0) {
					// Если есть конфликт
					if (nodeNumNonOccluders > 1 || begin < end) {
						// Делаем резерв для KD-объектов
						nodeBegin = nodeEnd = kdObjectsLength;
						if ((kdObjectsLength = nodeBegin + nodeNumNonOccluders + end - begin) > kdObjectsRealLength) kdObjects.length = kdObjectsRealLength = kdObjectsLength;
						// Собираем статики
						for (i = 0; i < nodeNumNonOccluders; i++) {
							staticChild = nodeObjects[i];
							if (staticChild.visible && staticChild.canDraw && ((staticChild.culling = culling) == 0 && numOccluders == 0 || (staticChild.culling = cullingInContainer(camera, node.bounds[i], culling)) >= 0)) {
								staticChild.cameraMatrix.identity();
								staticChild.cameraMatrix.prepend(object.cameraMatrix);
								staticChild.cameraMatrix.prepend(staticChild.matrix);
								// Создаём KD-объект
								if ((kdObject = KDObject.createFrom(staticChild, camera)) != null) kdObjects[nodeEnd++] = kdObject;
							}
						}
						// Собираем динамики
						for (i = begin; i < end; i++) {
							kdObject = kdObjects[i], kdObjects[i] = null;
							// Проверка с окклюдерами
							if (kdObject.numCheckedOccluders < numOccluders && cullKDObject(camera, kdObject)) {
								kdObject.destroy();
								continue;
							}
							kdObjects[nodeEnd++] = kdObject;
							// Подрезаем массив вершин
							kdObject.vertices.length = kdObject.verticesLength;
							// Переводим координаты в матрицу камеры
							object.cameraMatrix.transformVectors(kdObject.vertices, kdObject.vertices);
						}
						// Разруливаем конфликт
						if (nodeEnd > nodeBegin) KDObject.drawConflict(camera, object, canvas, kdObjects, nodeBegin, nodeEnd, threshold);
					} else {
						// Если только один статик
						staticChild = nodeObjects[i];
						if (staticChild.visible && staticChild.canDraw) {
							staticChild.cameraMatrix.identity();
							staticChild.cameraMatrix.prepend(object.cameraMatrix);
							staticChild.cameraMatrix.prepend(staticChild.matrix);
							staticChild.culling = culling;
							staticChild.draw(camera, staticChild, canvas);
						}
					}
				// Если нет статических объектов
				} else {
					// Если есть динамические объекты
					if (begin < end) {
						// Если динамических объектов несколько
						if (end - begin > 1) {
							// Если есть окклюдеры
							if (numOccluders > 0) {
								// Делаем резерв для KD-объектов
								nodeBegin = nodeEnd = kdObjectsLength;
								if ((kdObjectsLength = nodeBegin + nodeNumNonOccluders + end - begin) > kdObjectsRealLength) kdObjects.length = kdObjectsRealLength = kdObjectsLength;
								for (i = begin; i < end; i++) {
									kdObject = kdObjects[i], kdObjects[i] = null;
									// Проверка с окклюдерами
									if (kdObject.numCheckedOccluders < numOccluders && cullKDObject(camera, kdObject)) {
										kdObject.destroy();
										continue;
									}
									kdObjects[nodeEnd++] = kdObject;
								}
								// Если остались объекты
								if (nodeEnd > nodeBegin) {
									// Если оставшихся объектов несколько
									if (nodeEnd - nodeBegin > 1) {
										drawKDObjects(camera, object, canvas, nodeBegin, nodeEnd);
									} else {
										kdObject = kdObjects[nodeBegin], kdObjects[nodeBegin] = null;
										kdObject.draw(camera, object, canvas), kdObject.destroy();
									}
								}
							} else {
								drawKDObjects(camera, object, canvas, begin, end);
							}
						} else {
							kdObject = kdObjects[begin], kdObjects[begin] = null;
							// Проверка с окклюдерами и отрисовка
							if (kdObject.numCheckedOccluders == numOccluders || !cullKDObject(camera, kdObject)) kdObject.draw(camera, object, canvas);
							kdObject.destroy();
						}
					}
				}
				// Если в ноде есть окклюдеры
				if (nodeNumObjects > nodeNumNonOccluders) {
					for (i = nodeNumNonOccluders; i < nodeNumObjects; i++) {
						staticChild = nodeObjects[i];
						if (staticChild.visible && staticChild.canDraw && ((staticChild.culling = culling) == 0 && numOccluders == 0 || (staticChild.culling = cullingInContainer(camera, node.bounds[i], culling)) >= 0)) {
							staticChild.cameraMatrix.identity();
							staticChild.cameraMatrix.prepend(object.cameraMatrix);
							staticChild.cameraMatrix.prepend(staticChild.matrix);
							staticChild.draw(camera, staticChild, canvas);
						}
					}
					// Обновление окклюдеров
					updateOccluders(camera);
				}
			}
		}
		
		// Отрисовка динамических объектов
		/**
		 * @private 
		 */
		alternativa3d function drawKDObjects(camera:Camera3D, object:Object3D, canvas:Canvas, begin:int, end:int):void {
			// Ищем сплит
			var i:int, j:int, kdObject:KDObject;
			var boundBox:BoundBox, comparedBoundBox:BoundBox;
			var infront:Boolean, behind:Boolean;
			var coord:Number, coordMin:Number, coordMax:Number;
			var axisX:Boolean, axisY:Boolean;
			for (i = begin; i < end; i++) {
				boundBox = (kdObjects[i] as KDObject)._boundBox;
				// Сплиты по оси X
				coord = boundBox.minX, coordMin = coord - threshold, coordMax = coord + threshold, behind = false, infront = false;
				for (j = begin; j < end; j++) if ((comparedBoundBox = (kdObjects[j] as KDObject)._boundBox).maxX <= coordMax) behind = true else if (comparedBoundBox.minX >= coordMin) infront = true else break;
				if (j == end && behind && infront) {
					axisX = true, axisY = false;
					break;
				}
				coord = boundBox.maxX, coordMin = coord - threshold, coordMax = coord + threshold, behind = false, infront = false;
				for (j = begin; j < end; j++) if ((comparedBoundBox = (kdObjects[j] as KDObject)._boundBox).maxX <= coordMax) behind = true else if (comparedBoundBox.minX >= coordMin) infront = true else break;
				if (j == end && behind && infront) {
					axisX = true, axisY = false;
					break;
				}
				// Сплиты по оси Y
				coord = boundBox.minY, coordMin = coord - threshold, coordMax = coord + threshold, behind = false, infront = false;
				for (j = begin; j < end; j++) if ((comparedBoundBox = (kdObjects[j] as KDObject)._boundBox).maxY <= coordMax) behind = true else if (comparedBoundBox.minY >= coordMin) infront = true else break;
				if (j == end && behind && infront) {
					axisX = false, axisY = true;
					break;
				}
				coord = boundBox.maxY, coordMin = coord - threshold, coordMax = coord + threshold, behind = false, infront = false;
				for (j = begin; j < end; j++) if ((comparedBoundBox = (kdObjects[j] as KDObject)._boundBox).maxY <= coordMax) behind = true else if (comparedBoundBox.minY >= coordMin) infront = true else break;
				if (j == end && behind && infront) {
					axisX = false, axisY = true;
					break;
				}
				// Сплиты по оси Z
				coord = boundBox.minZ, coordMin = coord - threshold, coordMax = coord + threshold, behind = false, infront = false;
				for (j = begin; j < end; j++) if ((comparedBoundBox = (kdObjects[j] as KDObject)._boundBox).maxZ <= coordMax) behind = true else if (comparedBoundBox.minZ >= coordMin) infront = true else break;
				if (j == end && behind && infront) {
					axisX = false, axisY = false;
					break;
				}
				coord = boundBox.maxZ, coordMin = coord - threshold, coordMax = coord + threshold, behind = false, infront = false;
				for (j = begin; j < end; j++) if ((comparedBoundBox = (kdObjects[j] as KDObject)._boundBox).maxZ <= coordMax) behind = true else if (comparedBoundBox.minZ >= coordMin) infront = true else break;
				if (j == end && behind && infront) {
					axisX = false, axisY = false;
					break;
				}
			}
			// Если найден сплит
			if (i < end) {
				// Делаем резерв для разделённых KD-объектов 
				var negativeBegin:int = kdObjectsLength, negativeEnd:int = negativeBegin, nodeBegin:int = negativeBegin + end - begin, nodeEnd:int = nodeBegin, positiveBegin:int = nodeBegin + end - begin, positiveEnd:int = positiveBegin;
				if ((kdObjectsLength = positiveBegin + end - begin) > kdObjectsRealLength) kdObjects.length = kdObjectsRealLength = kdObjectsLength;
				// Разделяем KD-объекты
				for (i = begin; i < end; i++) {
					kdObject = kdObjects[i], kdObjects[i] = null;
					var min:Number = axisX ? kdObject._boundBox.minX : (axisY ? kdObject._boundBox.minY : kdObject._boundBox.minZ);
					var max:Number = axisX ? kdObject._boundBox.maxX : (axisY ? kdObject._boundBox.maxY : kdObject._boundBox.maxZ);
					if (max <= coordMax) {
						if (min < coordMin) kdObjects[negativeEnd++] = kdObject	else kdObjects[nodeEnd++] = kdObject;
					} else kdObjects[positiveEnd++] = kdObject;
				}
				// Определяем положение камеры
				if (axisX && cameraX > coord || axisY && cameraY > coord || !axisX && !axisY && cameraZ > coord) {
					// Отрисовка объектов спереди
					if (positiveEnd > positiveBegin) {
						if (positiveEnd - positiveBegin > 1) {
							drawKDObjects(camera, object, canvas, positiveBegin, positiveEnd);
						} else {
							(kdObject = kdObjects[positiveBegin]).draw(camera, object, canvas),	kdObjects[positiveBegin] = null, kdObject.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					for (i = nodeBegin; i < nodeEnd; i++) (kdObject = kdObjects[i]).draw(camera, object, canvas), kdObjects[i] = null, kdObject.destroy();
					// Отрисовка объектов сзади
					if (negativeEnd > negativeBegin) {
						if (negativeEnd - negativeBegin > 1) {
							drawKDObjects(camera, object, canvas, negativeBegin, negativeEnd);
						} else {
							(kdObject = kdObjects[negativeBegin]).draw(camera, object, canvas),	kdObjects[negativeBegin] = null, kdObject.destroy();
						}
					}
				} else {
					// Отрисовка объектов сзади
					if (negativeEnd > negativeBegin) {
						if (negativeEnd - negativeBegin > 1) {
							drawKDObjects(camera, object, canvas, negativeBegin, negativeEnd);
						} else {
							(kdObject = kdObjects[negativeBegin]).draw(camera, object, canvas),	kdObjects[negativeBegin] = null, kdObject.destroy();
						}
					}
					// Отрисовка объектов в плоскости
					for (i = nodeBegin; i < nodeEnd; i++) (kdObject = kdObjects[i]).draw(camera, object, canvas), kdObjects[i] = null, kdObject.destroy();
					// Отрисовка объектов спереди
					if (positiveEnd > positiveBegin) {
						if (positiveEnd - positiveBegin > 1) {
							drawKDObjects(camera, object, canvas, positiveBegin, positiveEnd);
						} else {
							(kdObject = kdObjects[positiveBegin]).draw(camera, object, canvas),	kdObjects[positiveBegin] = null, kdObject.destroy();
						}
					}
				}
			} else {
				// Переводим в камеру
				for (i = begin; i < end; i++) {
					kdObject = kdObjects[i];
					// Подрезаем массив вершин
					kdObject.vertices.length = kdObject.verticesLength;
					// Переводим координаты в матрицу камеры
					object.cameraMatrix.transformVectors(kdObject.vertices, kdObject.vertices);
				}
				// Разруливаем конфликт
				KDObject.drawConflict(camera, object, canvas, kdObjects, begin, end, threshold);
			}
		}
			
		private var splitAxis:int;
		private var splitCoord:Number;
		private var splitCost:Number;
		static private const nodeBoundBoxThreshold:BoundBox = new BoundBox();
		static private const splitCoordsX:Vector.<Number> = new Vector.<Number>();
		static private const splitCoordsY:Vector.<Number> = new Vector.<Number>();
		static private const splitCoordsZ:Vector.<Number> = new Vector.<Number>();
		private function splitNode(node:KDNode):void {

			var object:Object3D, boundBox:BoundBox, i:int, j:int, k:int, c1:Number, c2:Number, coordMin:Number, coordMax:Number, area:Number, areaNegative:Number, areaPositive:Number, numNegative:int, numPositive:int, conflict:Boolean, cost:Number;
			var nodeBoundBox:BoundBox = node.boundBox;

			// Подготовка баунда с погрешностями
			nodeBoundBoxThreshold.minX = nodeBoundBox.minX + threshold;
			nodeBoundBoxThreshold.minY = nodeBoundBox.minY + threshold;
			nodeBoundBoxThreshold.minZ = nodeBoundBox.minZ + threshold;
			nodeBoundBoxThreshold.maxX = nodeBoundBox.maxX - threshold;
			nodeBoundBoxThreshold.maxY = nodeBoundBox.maxY - threshold;
			nodeBoundBoxThreshold.maxZ = nodeBoundBox.maxZ - threshold;
			var doubleThreshold:Number = threshold + threshold;

			// Собираем опорные координаты
			var numSplitCoordsX:int = 0, numSplitCoordsY:int = 0, numSplitCoordsZ:int = 0;
			for (i = 0; i < node.numObjects; i++) {
				boundBox = node.bounds[i];
				if (boundBox.maxX - boundBox.minX <= doubleThreshold) {
					if (boundBox.minX <= nodeBoundBoxThreshold.minX) splitCoordsX[numSplitCoordsX++] = nodeBoundBox.minX;
					else if (boundBox.maxX >= nodeBoundBoxThreshold.maxX) splitCoordsX[numSplitCoordsX++] = nodeBoundBox.maxX;
					else splitCoordsX[numSplitCoordsX++] = (boundBox.minX + boundBox.maxX)*0.5;
				} else {
					if (boundBox.minX > nodeBoundBoxThreshold.minX) splitCoordsX[numSplitCoordsX++] = boundBox.minX;
					if (boundBox.maxX < nodeBoundBoxThreshold.maxX) splitCoordsX[numSplitCoordsX++] = boundBox.maxX;
				}
				if (boundBox.maxY - boundBox.minY <= doubleThreshold) {
					if (boundBox.minY <= nodeBoundBoxThreshold.minY) splitCoordsY[numSplitCoordsY++] = nodeBoundBox.minY;
					else if (boundBox.maxY >= nodeBoundBoxThreshold.maxY) splitCoordsY[numSplitCoordsY++] = nodeBoundBox.maxY;
					else splitCoordsY[numSplitCoordsY++] = (boundBox.minY + boundBox.maxY)*0.5;
				} else {
					if (boundBox.minY > nodeBoundBoxThreshold.minY) splitCoordsY[numSplitCoordsY++] = boundBox.minY;
					if (boundBox.maxY < nodeBoundBoxThreshold.maxY) splitCoordsY[numSplitCoordsY++] = boundBox.maxY;
				}
				if (boundBox.maxZ - boundBox.minZ <= doubleThreshold) {
					if (boundBox.minZ <= nodeBoundBoxThreshold.minZ) splitCoordsZ[numSplitCoordsZ++] = nodeBoundBox.minZ;
					else if (boundBox.maxZ >= nodeBoundBoxThreshold.maxZ) splitCoordsZ[numSplitCoordsZ++] = nodeBoundBox.maxZ;
					else splitCoordsZ[numSplitCoordsZ++] = (boundBox.minZ + boundBox.maxZ)*0.5;
				} else {
					if (boundBox.minZ > nodeBoundBoxThreshold.minZ) splitCoordsZ[numSplitCoordsZ++] = boundBox.minZ;
					if (boundBox.maxZ < nodeBoundBoxThreshold.maxZ) splitCoordsZ[numSplitCoordsZ++] = boundBox.maxZ;
				}
			}
			
			// Убираем дубликаты координат, ищем наилучший сплит
			splitAxis = -1; splitCost = Number.MAX_VALUE;
			i = 0; area = (nodeBoundBox.maxY - nodeBoundBox.minY)*(nodeBoundBox.maxZ - nodeBoundBox.minZ);
			while (i < numSplitCoordsX) {
				if (!isNaN(c1 = splitCoordsX[i++])) {
					coordMin = c1 - threshold;
					coordMax = c1 + threshold;
					areaNegative = area*(c1 - nodeBoundBox.minX);
					areaPositive = area*(nodeBoundBox.maxX - c1);
					numNegative = numPositive = 0;
					conflict = false;
					// Проверяем объекты
					for (j = 0; j < node.numObjects; j++) {
						boundBox = node.bounds[j];
						if (boundBox.maxX <= coordMax) {
							if (boundBox.minX < coordMin) numNegative++;
						} else {
							if (boundBox.minX >= coordMin) numPositive++; else {conflict = true; break;}
						}
					}
					// Если хороший сплит, сохраняем
					if (!conflict && (cost = areaNegative*numNegative + areaPositive*numPositive) < splitCost) {
						splitCost = cost;
						splitAxis = 0;
						splitCoord = c1;
					}
					j = i;
					while (++j < numSplitCoordsX) if ((c2 = splitCoordsX[j]) >= c1 - threshold && c2 <= c1 + threshold) splitCoordsX[j] = NaN;
				} 
			}
			i = 0; area = (nodeBoundBox.maxX - nodeBoundBox.minX)*(nodeBoundBox.maxZ - nodeBoundBox.minZ);
			while (i < numSplitCoordsY) {
				if (!isNaN(c1 = splitCoordsY[i++])) {
					coordMin = c1 - threshold;
					coordMax = c1 + threshold;
					areaNegative = area*(c1 - nodeBoundBox.minY);
					areaPositive = area*(nodeBoundBox.maxY - c1);
					numNegative = numPositive = 0;
					conflict = false;
					// Проверяем объекты
					for (j = 0; j < node.numObjects; j++) {
						boundBox = node.bounds[j];
						if (boundBox.maxY <= coordMax) {
							if (boundBox.minY < coordMin) numNegative++;
						} else {
							if (boundBox.minY >= coordMin) numPositive++; else {conflict = true; break;}
						}
					}
					// Если хороший сплит, сохраняем
					if (!conflict && (cost = areaNegative*numNegative + areaPositive*numPositive) < splitCost) {
						splitCost = cost;
						splitAxis = 1;
						splitCoord = c1;
					}
					j = i;
					while (++j < numSplitCoordsY) if ((c2 = splitCoordsY[j]) >= c1 - threshold && c2 <= c1 + threshold) splitCoordsY[j] = NaN;
				} 
			}
			i = 0; area = (nodeBoundBox.maxX - nodeBoundBox.minX)*(nodeBoundBox.maxY - nodeBoundBox.minY);
			while (i < numSplitCoordsZ) {
				if (!isNaN(c1 = splitCoordsZ[i++])) {
					coordMin = c1 - threshold;
					coordMax = c1 + threshold;
					areaNegative = area*(c1 - nodeBoundBox.minZ);
					areaPositive = area*(nodeBoundBox.maxZ - c1);
					numNegative = numPositive = 0;
					conflict = false;
					// Проверяем объекты
					for (j = 0; j < node.numObjects; j++) {
						boundBox = node.bounds[j];
						if (boundBox.maxZ <= coordMax) {
							if (boundBox.minZ < coordMin) numNegative++;
						} else {
							if (boundBox.minZ >= coordMin) numPositive++; else {conflict = true; break;}
						}
					}
					// Если хороший сплит, сохраняем
					if (!conflict && (cost = areaNegative*numNegative + areaPositive*numPositive) < splitCost) {
						splitCost = cost;
						splitAxis = 2;
						splitCoord = c1;
					}
					j = i;
					while (++j < numSplitCoordsZ) if ((c2 = splitCoordsZ[j]) >= c1 - threshold && c2 <= c1 + threshold) splitCoordsZ[j] = NaN;
				}
			}

			// Если сплит не найден, выходим
			if (splitAxis < 0) {
				// Находим, откуда начинаются окклюдеры
				for (i = 0; i < node.numObjects; i++) {
					object = node.objects[i];
					// Поиск оригинального объекта
					while (object is Reference) object = (object as Reference).referenceObject;
					if (object is Occluder) break;
				}
				node.numNonOccluders = i;
				return;
			}
			
			// Разделяем ноду
			var axisX:Boolean = splitAxis == 0, axisY:Boolean = splitAxis == 1;
			node.axis = splitAxis;
			node.coord = splitCoord;
			node.minCoord = coordMin = splitCoord - threshold;
			node.maxCoord = coordMax = splitCoord + threshold;
			
			// Создаём дочерние ноды
			node.negative = new KDNode();
			node.positive = new KDNode();
			node.negative.boundBox = nodeBoundBox.clone();
			node.positive.boundBox = nodeBoundBox.clone();
			node.negative.numObjects = 0;
			node.positive.numObjects = 0;
			if (axisX) node.negative.boundBox.maxX = node.positive.boundBox.minX = splitCoord;
			else if (axisY) node.negative.boundBox.maxY = node.positive.boundBox.minY = splitCoord;
			else node.negative.boundBox.maxZ = node.positive.boundBox.minZ = splitCoord;

			// Распределяем объекты по дочерним нодам
			for (i = 0; i < node.numObjects; i++) {
				object = node.objects[i];
				boundBox = node.bounds[i];
				var min:Number = axisX ? boundBox.minX : (axisY ? boundBox.minY : boundBox.minZ);
				var max:Number = axisX ? boundBox.maxX : (axisY ? boundBox.maxY : boundBox.maxZ);
				if (max <= coordMax) {
					if (min < coordMin) {
						// Объект в негативной стороне
						if (node.negative.objects == null) node.negative.objects = new Vector.<Object3D>(), node.negative.bounds = new Vector.<BoundBox>();
						node.negative.objects[node.negative.numObjects] = object, node.negative.bounds[node.negative.numObjects++] = boundBox;
						node.objects[i] = null, node.bounds[i] = null;
					} else {
						// Остаётся в ноде
					}
				} else {
					if (min >= coordMin) {
						// Объект в положительной стороне
						if (node.positive.objects == null) node.positive.objects = new Vector.<Object3D>(), node.positive.bounds = new Vector.<BoundBox>();
						node.positive.objects[node.positive.numObjects] = object, node.positive.bounds[node.positive.numObjects++] = boundBox;
						node.objects[i] = null, node.bounds[i] = null;
					} else {
						// Распилился
					}
				}
			}
			
			// Очистка списка объектов
			for (i = 0, j = 0; i < node.numObjects; i++) if (node.objects[i] != null) node.objects[j] = node.objects[i], node.bounds[j++] = node.bounds[i];
			if (j > 0) {
				node.numObjects = node.objects.length = node.bounds.length = j;
				// Находим, откуда начинаются окклюдеры
				for (i = 0; i < node.numObjects; i++) {
					object = node.objects[i];
					// Поиск оригинального объекта
					while (object is Reference) object = (object as Reference).referenceObject;
					if (object is Occluder) break;
				}
				node.numNonOccluders = i;
			} else {
				node.numObjects = node.numNonOccluders = 0, node.objects = null, node.bounds = null;
			}
			
			// Разделение дочерних нод
			if (node.negative.objects != null) splitNode(node.negative);
			if (node.positive.objects != null) splitNode(node.positive);
		}
		
		public function addStaticChild(child:Object3D):void {
			staticChildren[_numStaticChildren++] = child;
			child._parent = this; 
		}
		
		public function removeStaticChild(child:Object3D):void {
			var i:int = staticChildren.indexOf(child);
			if (i < 0) throw new ArgumentError();
			_numStaticChildren--;
			for (; i < _numStaticChildren; i++) staticChildren[i] = staticChildren[int(i + 1)];
			staticChildren.length = _numStaticChildren;
			child._parent = null;
		}
		
		public function getStaticChildAt(index:uint):Object3D {
			return staticChildren[index];
		}

		public function get numStaticChildren():uint {
			return _numStaticChildren;
		}
		
		public function addDynamicChild(child:Object3D):void {
			dynamicChildren[_numDynamicChildren++] = child;
			child._parent = this; 
		}
		
		public function removeDynamicChild(child:Object3D):void {
			var i:int = dynamicChildren.indexOf(child);
			if (i < 0) throw new ArgumentError();
			_numDynamicChildren--;
			for (; i < _numDynamicChildren; i++) dynamicChildren[i] = dynamicChildren[int(i + 1)];
			dynamicChildren.length = _numDynamicChildren;
			child._parent = null;
		}
		
		public function getDynamicChildAt(index:uint):Object3D {
			return dynamicChildren[index];
		}

		public function get numDynamicChildren():uint {
			return _numDynamicChildren;
		}
		
	}
}