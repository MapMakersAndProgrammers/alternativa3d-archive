package alternativa.engine3d.physics {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.BSPNode;
	import alternativa.engine3d.core.PolyPrimitive;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.types.Point3D;
	import alternativa.types.Set;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 * Класс реализует алгоритм определения столкновений сферы с полигонами сцены.
	 */
	public class SphereCollider	{
		
		// Максимальное кол-во попыток найти выход от столкновений со сценой   
		private static const maxCollisions:uint = 5000;
		
		private var scene:Scene3D;
		
		private var collisionSource:Point3D;
		private var collisionVector:Point3D;
		private var collisionDestination:Point3D = new Point3D();
		private var collisionRadius:Number;
		private var collisionPlanes:Array = new Array();
		private var collisionPlanePoint:Point3D = new Point3D();
		private var collisionPrimitive:PolyPrimitive;
		private var collisionPrimitivePoint:Point3D = new Point3D();
		private var collisionPrimitiveNearest:PolyPrimitive;
		private var collisionPrimitiveNearestLengthSqr:Number;
		private var collisionPoint:Point3D = new Point3D();
		private var collisionNormal:Point3D = new Point3D();
		private var collisionOffset:Number;
		private var coords:Point3D = new Point3D();
		// Погрешность определения расстояния
		private var _offsetThreshold:Number = 0.01;
		
		public var ignoreSet:Set;

		/**
		 * Создание экземпляра класса.
		 * 
		 * @param scene сцена, в которой определяется столкновение
		 */
		public function SphereCollider(scene:Scene3D, radius:Number = 0) {
			if (scene == null) {
				throw new Error("SphereCollider: scene is null");
			}
			this.scene = scene;
			collisionRadius = radius;
		}
		
		/**
		 * Установка радиуса сферы
		 * 
		 * @param value радиус сферы
		 */
		public function set sphereRadius(value:Number):void {
			collisionRadius = value;
		}

		/**
		 * Получение радиуса сферы
		 * 
		 * @return радиус сферы
		 */
		public function get sphereRadius():Number {
			return collisionRadius;
		}
		
		/**
		 * Установка погрешности определения расстояний.
		 * 
		 * @param threshold погрешность определения расстояний
		 */		
		public function set offsetThreshold(threshold:Number):void {
			_offsetThreshold = threshold;
		}
		
		/**
		 * Получение погрешности определения расстояний.
		 * 
		 * @return погрешность определения расстояний
		 */
		public function get offsetThreshold():Number {
			return _offsetThreshold;
		}
		
		/**
		 * @inherit
		 */
		public function calculateDestination(source:Point3D, velocity:Point3D, destination:Point3D):void {
			// Расчеты не производятся, если скорость мала
			if (velocity.x <= _offsetThreshold && velocity.x >= -_offsetThreshold &&
					velocity.y <= _offsetThreshold && velocity.y >= -_offsetThreshold &&
					velocity.z <= _offsetThreshold && velocity.z >= -_offsetThreshold) {
				destination.x = source.x;
				destination.y = source.y;
				destination.z = source.z;
				return;
			}

			coords.x = source.x;
			coords.y = source.y;
			coords.z = source.z;
			
			destination.x = source.x + velocity.x;
			destination.y = source.y + velocity.y;
			destination.z = source.z + velocity.z;
			// TODO: Подумать на счёт критериев принудительного выхода из возникшего бесконечного цикла
			// Если после maxCollisions ходов выход не найден, то остаемся на старом месте
			var collisions:uint = 0;
			do {
				var collision:Collision = calculateCollision(coords, velocity);
				if (collision != null) {
					// Вынос точки назначения из-за плоскости столкновения на высоту радиуса сферы над плоскостью по направлению нормали
					var offset:Number = collisionRadius + _offsetThreshold + collision.offset - destination.x*collision.normal.x - destination.y*collision.normal.y - destination.z*collision.normal.z;
					destination.x += collision.normal.x * offset;
					destination.y += collision.normal.y * offset;
					destination.z += collision.normal.z * offset;
					// Коррекция текущих кординат центра сферы для следующей итерации 
					coords.x = collision.point.x + collision.normal.x * (collisionRadius + _offsetThreshold);
					coords.y = collision.point.y + collision.normal.y * (collisionRadius + _offsetThreshold);
					coords.z = collision.point.z + collision.normal.z * (collisionRadius + _offsetThreshold);
					// Коррекция вектора скорости. Результирующий вектор направлен вдоль плоскости столкновения.
					velocity.x = destination.x - coords.x;
					velocity.y = destination.y - coords.y;
					velocity.z = destination.z - coords.z;
					// Если смещение слишком мало, останавливаемся
					if (velocity.x <= _offsetThreshold && velocity.x >= -_offsetThreshold &&
							velocity.y <= _offsetThreshold && velocity.y >= -_offsetThreshold &&
							velocity.z <= _offsetThreshold && velocity.z >= -_offsetThreshold) {
						velocity.x = 0;
						velocity.y = 0;
						velocity.z = 0;
						break;
					}
				}
			} while ((collision != null) && (++collisions < maxCollisions));
			if (collisions == maxCollisions) {
				destination.x = source.x;
				destination.y = source.y;
				destination.z = source.z;
			}
		}
		
		/**
		 * Определение столкновения сферы с полигонами сцены.
		 * 
		 * @param source исходная точка положения сферы в сцене
		 * @param vector вектор скорости сферы в сцене
		 * 
		 * @return объект, содержащий параметры столкновения или <code>null</code> в случае отсутствия столкновений 
		 */		
		public function calculateCollision(source:Point3D, vector:Point3D):Collision {
			collisionSource = source;
			collisionVector = vector;
			collisionDestination.x = collisionSource.x + collisionVector.x;
			collisionDestination.y = collisionSource.y + collisionVector.y;
			collisionDestination.z = collisionSource.z + collisionVector.z;
			
			// Собираем потенциальные плоскости столкновения
			collectCollisionPlanes(scene.bsp);
			
			// Перебираем плоскости по мере удалённости
			collisionPlanes.sortOn("sourceOffset", Array.NUMERIC | Array.DESCENDING);
			var plane:CollisionPlane;
			// Пока не найдём столкновение с примитивом или плоскости не кончатся
			while ((plane = collisionPlanes.pop()) != null && collisionPrimitive == null) {
				calculateCollisionWithPlane(plane);
			}			
			
			var collision:Collision;
			if (collisionPrimitive != null) {
				collision = new Collision();
				collision.face = collisionPrimitive.face;
				collision.normal = collisionNormal.clone();
				collision.point = collisionPoint.clone();
				collision.offset = collisionOffset;
			}
			
			collisionSource = null;
			collisionVector = null;
			collisionPrimitive = null;
			var length:uint = collisionPlanes.length;
			for (var i:uint = 0; i < length; i++) {
				collisionPlanes.pop();
			}
			return collision;
		}

		/**
		 * @private
		 * Сбор потенциальных плоскостей столкновения.
		 * 
		 * @param node текущий узел BSP-дерева
		 */
		private function collectCollisionPlanes(node:BSPNode):void {
			if (node != null) {
				var sourceOffset:Number = collisionSource.x * node.normal.x + collisionSource.y * node.normal.y + collisionSource.z * node.normal.z - node.offset;
				var destinationOffset:Number = collisionDestination.x * node.normal.x + collisionDestination.y * node.normal.y + collisionDestination.z * node.normal.z - node.offset;
				var plane:CollisionPlane; 

				if (sourceOffset >= 0) {
					// Перед нодой
					
					// Проверяем передние ноды
					collectCollisionPlanes(node.front);
					
					if (destinationOffset < collisionRadius) {

						// Нашли пересечение с плоскостью
						plane = new CollisionPlane();
						plane.node = node;
						plane.infront = true;
						plane.sourceOffset = sourceOffset;
						plane.destinationOffset = destinationOffset;
						collisionPlanes.push(plane);

						// Проверяем задние ноды
						collectCollisionPlanes(node.back);
					}
					
				} else {
					// За нодой

					// Проверяем задние ноды
					collectCollisionPlanes(node.back);
					
					if (-destinationOffset < collisionRadius) {
						
						// Если в ноде есть сзади примитивы
						if (node.backPrimitives != null) {
							// Нашли пересечение с плоскостью
							plane = new CollisionPlane();
							plane.node = node;
							plane.infront = false;
							plane.sourceOffset = -sourceOffset;
							plane.destinationOffset = -destinationOffset;
							collisionPlanes.push(plane);
						}

						// Проверяем передние ноды
						collectCollisionPlanes(node.front);
					}
				}
			}
		}
		
		/**
		 * @private
		 * Определение пересечения сферы с примитивами, лежащими в заданной плоскости. 
		 * 
		 * @param plane плоскость, содержащая примитивы для проверки 
		 */		
		private function calculateCollisionWithPlane(plane:CollisionPlane):void {
			collisionPlanePoint.copy(collisionSource);

			var normal:Point3D = plane.node.normal;
			// Если сфера врезана в плоскость
			if (plane.sourceOffset <= collisionRadius) {
				if (plane.infront) {
					collisionPlanePoint.x -= normal.x * plane.sourceOffset;
					collisionPlanePoint.y -= normal.y * plane.sourceOffset;
					collisionPlanePoint.z -= normal.z * plane.sourceOffset;
				} else {
					collisionPlanePoint.x += normal.x * plane.sourceOffset;
					collisionPlanePoint.y += normal.y * plane.sourceOffset;
					collisionPlanePoint.z += normal.z * plane.sourceOffset;
				}
			} else {
				// Находим центр сферы во время столкновения с плоскостью
				var time:Number = (plane.sourceOffset - collisionRadius) / (plane.sourceOffset - plane.destinationOffset);
				collisionPlanePoint.x = collisionSource.x + collisionVector.x * time;
				collisionPlanePoint.y = collisionSource.y + collisionVector.y * time;
				collisionPlanePoint.z = collisionSource.z + collisionVector.z * time;
				
				// Устанавливаем точку пересечения cферы с плоскостью
				if (plane.infront) {
					collisionPlanePoint.x -= normal.x * collisionRadius;
					collisionPlanePoint.y -= normal.y * collisionRadius;
					collisionPlanePoint.z -= normal.z * collisionRadius;
				} else {
					collisionPlanePoint.x += normal.x * collisionRadius;
					collisionPlanePoint.y += normal.y * collisionRadius;
					collisionPlanePoint.z += normal.z * collisionRadius;
				}
			}

			// Проверяем примитивы плоскости
			var primitive:*;
			collisionPrimitiveNearestLengthSqr = Number.MAX_VALUE;
			collisionPrimitiveNearest = null;
			if (plane.infront) {
				if (plane.node.primitive != null) {
					if (ignoreSet == null || ignoreSet[plane.node.primitive.face._mesh] == undefined) {
						calculateCollisionWithPrimitive(plane.node.primitive);
					}
				} else {
					for (primitive in plane.node.frontPrimitives) {
						if (ignoreSet == null || ignoreSet[primitive.face._mesh] == undefined) {
							calculateCollisionWithPrimitive(primitive);
							if (collisionPrimitive != null) break;
						}
					}
				}
			} else {
				for (primitive in plane.node.backPrimitives) {
					if (ignoreSet == null || ignoreSet[primitive.face._mesh] == undefined) {
						calculateCollisionWithPrimitive(primitive);
						if (collisionPrimitive != null) break;
					}
				}
			}

			if (collisionPrimitive != null) {
				// Если точка пересечения попала в примитив

				// Нормаль плоскости при столкновении - нормаль плоскости
				if (plane.infront) {
					collisionNormal.x = normal.x;
					collisionNormal.y = normal.y;
					collisionNormal.z = normal.z;
					collisionOffset = plane.node.offset;
				} else {
					collisionNormal.x = -normal.x;
					collisionNormal.y = -normal.y;
					collisionNormal.z = -normal.z;
					collisionOffset = -plane.node.offset;
				}
				
				// Точка столкновения в точке столкновения с плоскостью
				collisionPoint.x = collisionPlanePoint.x;
				collisionPoint.y = collisionPlanePoint.y;
				collisionPoint.z = collisionPlanePoint.z;
				
			} else {
				// Если точка пересечения не попала ни в один примитив, проверяем столкновение с ближайшей
				
				// Вектор из ближайшей точки в центр сферы
				var nearestPointToSourceX:Number = collisionSource.x - collisionPrimitivePoint.x;
				var nearestPointToSourceY:Number = collisionSource.y - collisionPrimitivePoint.y; 
				var nearestPointToSourceZ:Number = collisionSource.z - collisionPrimitivePoint.z;

				// Если движение в сторону точки
				if (nearestPointToSourceX * collisionVector.x + nearestPointToSourceY * collisionVector.y + nearestPointToSourceZ * collisionVector.z <= 0) {
					
					// Ищем нормализованный вектор обратного направления
					var vectorLength:Number = Math.sqrt(collisionVector.x * collisionVector.x + collisionVector.y * collisionVector.y + collisionVector.z * collisionVector.z);
					var vectorX:Number = -collisionVector.x / vectorLength;
					var vectorY:Number = -collisionVector.y / vectorLength;
					var vectorZ:Number = -collisionVector.z / vectorLength;
					
					// Длина вектора из ближайшей точки в центр сферы
					var nearestPointToSourceLengthSqr:Number = nearestPointToSourceX * nearestPointToSourceX + nearestPointToSourceY * nearestPointToSourceY + nearestPointToSourceZ * nearestPointToSourceZ;
					
					// Проекция вектора из ближайшей точки в центр сферы на нормализованный вектор обратного направления
					var projectionLength:Number = nearestPointToSourceX * vectorX + nearestPointToSourceY * vectorY + nearestPointToSourceZ * vectorZ;
					
					var projectionInsideSphereLengthSqr:Number = collisionRadius * collisionRadius - nearestPointToSourceLengthSqr + projectionLength * projectionLength;
					
					if (projectionInsideSphereLengthSqr > 0) {
						// Находим расстояние из ближайшей точки до сферы
						var distance:Number = projectionLength - Math.sqrt(projectionInsideSphereLengthSqr);
						
						if (distance < vectorLength) {
							// Столкновение сферы с ближайшей точкой произошло
		
							// Точка столкновения в ближайшей точке
							collisionPoint.x = collisionPrimitivePoint.x;
							collisionPoint.y = collisionPrimitivePoint.y;
							collisionPoint.z = collisionPrimitivePoint.z;
														
							// Находим нормаль плоскости столкновения
							var nearestPointToSourceLength:Number = Math.sqrt(nearestPointToSourceLengthSqr);
							collisionNormal.x = nearestPointToSourceX / nearestPointToSourceLength;
							collisionNormal.y = nearestPointToSourceY / nearestPointToSourceLength;
							collisionNormal.z = nearestPointToSourceZ / nearestPointToSourceLength;
							
							// Смещение плоскости столкновения
							collisionOffset = collisionPoint.x * collisionNormal.x + collisionPoint.y * collisionNormal.y + collisionPoint.z * collisionNormal.z; 
							collisionPrimitive = collisionPrimitiveNearest;
						}
					}
				}
			}
		}

		/**
		 * @private
		 * Определение столкновения с примитивом.
		 * 
		 * @param primitive примитив, столкновение с которым проверяется
		 */
		private function calculateCollisionWithPrimitive(primitive:PolyPrimitive):void {

			var length:uint = primitive.num;
			var points:Array = primitive.points;
			var normal:Point3D = primitive.face.globalNormal;
			var inside:Boolean = true;

			for (var i:uint = 0; i < length; i++) {
				
				var p1:Point3D = points[i];
				var p2:Point3D = points[(i < length - 1) ? (i + 1) : 0];
				
				var edgeX:Number = p2.x - p1.x;
				var edgeY:Number = p2.y - p1.y;
				var edgeZ:Number = p2.z - p1.z;

				var vectorX:Number = collisionPlanePoint.x - p1.x;
				var vectorY:Number = collisionPlanePoint.y - p1.y;
				var vectorZ:Number = collisionPlanePoint.z - p1.z;

				var crossX:Number = vectorY * edgeZ - vectorZ * edgeY;
				var crossY:Number = vectorZ * edgeX - vectorX * edgeZ;
				var crossZ:Number = vectorX * edgeY - vectorY * edgeX;
				
				if (crossX * normal.x + crossY * normal.y + crossZ * normal.z > 0) {
					// Точка за пределами полигона
					inside = false;
					
					var edgeLengthSqr:Number = edgeX * edgeX + edgeY * edgeY + edgeZ * edgeZ;
					var edgeDistanceSqr:Number = (crossX * crossX + crossY * crossY + crossZ * crossZ) / edgeLengthSqr;
					
					// Если расстояние до прямой меньше текущего ближайшего
					if (edgeDistanceSqr < collisionPrimitiveNearestLengthSqr) {
						
						// Ищем нормализованный вектор ребра
						var edgeLength:Number = Math.sqrt(edgeLengthSqr);
						var edgeNormX:Number = edgeX / edgeLength;
						var edgeNormY:Number = edgeY / edgeLength;
						var edgeNormZ:Number = edgeZ / edgeLength;

						// Находим расстояние до точки перпендикуляра вдоль ребра
						var t:Number = edgeNormX * vectorX + edgeNormY * vectorY + edgeNormZ * vectorZ;

						var vectorLengthSqr:Number;
						if (t < 0) {
							// Ближайшая точка - первая
							vectorLengthSqr = vectorX * vectorX + vectorY * vectorY + vectorZ * vectorZ;
							if (vectorLengthSqr < collisionPrimitiveNearestLengthSqr) {
								collisionPrimitiveNearestLengthSqr = vectorLengthSqr;
								collisionPrimitivePoint.x = p1.x;
								collisionPrimitivePoint.y = p1.y;
								collisionPrimitivePoint.z = p1.z;
								collisionPrimitiveNearest = primitive;
							}
						} else {
							if (t > edgeLength) {
								// Ближайшая точка - вторая
								vectorX = collisionPlanePoint.x - p2.x;
								vectorY = collisionPlanePoint.y - p2.y;
								vectorZ = collisionPlanePoint.z - p2.z;
								vectorLengthSqr = vectorX * vectorX + vectorY * vectorY + vectorZ * vectorZ;
								if (vectorLengthSqr < collisionPrimitiveNearestLengthSqr) {
									collisionPrimitiveNearestLengthSqr = vectorLengthSqr;
									collisionPrimitivePoint.x = p2.x;
									collisionPrimitivePoint.y = p2.y;
									collisionPrimitivePoint.z = p2.z;
									collisionPrimitiveNearest = primitive;
								}
							} else {
								// Ближайшая точка на ребре
								collisionPrimitiveNearestLengthSqr = edgeDistanceSqr;
								collisionPrimitivePoint.x = p1.x + edgeNormX * t;
								collisionPrimitivePoint.y = p1.y + edgeNormY * t;
								collisionPrimitivePoint.z = p1.z + edgeNormZ * t;
								collisionPrimitiveNearest = primitive;
							}
						}
					}
				}
			}
			
			// Если попали в примитив
			if (inside) {
				collisionPrimitive = primitive;
			}
		}
	}
}