package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.lights.DirectionalLight;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	use namespace alternativa3d;
	public class Object3D extends EventDispatcher {
		
		/**
		 * Имя объекта.
		 */
		public var name:String;
		
		/**
		 * Флаг видимости объекта.
		 */
		public var visible:Boolean = true;
		
		/**
		 * Координата X.
		 */
		public var x:Number = 0;
		
		/**
		 * Координата Y.
		 */
		public var y:Number = 0;
		
		/**
		 * Координата Z.
		 */
		public var z:Number = 0;
		
		/**
		 * Угол поворота вокруг оси X.
		 * Указывается в радианах.
		 */
		public var rotationX:Number = 0;
		
		/**
		 * Угол поворота вокруг оси Y.
		 * Указывается в радианах.
		 */
		public var rotationY:Number = 0;
		
		/**
		 * Угол поворота вокруг оси Z.
		 * Указывается в радианах.
		 */
		public var rotationZ:Number = 0;
		
		/**
		 * Коэффициент масштабирования по оси X.
		 */
		public var scaleX:Number = 1;
		
		/**
		 * Коэффициент масштабирования по оси Y.
		 */
		public var scaleY:Number = 1;
		
		/**
		 * Коэффициент масштабирования по оси Z.
		 */
		public var scaleZ:Number = 1;
		
		/**
		 * Левая граница объекта в его системе координат.
		 */
		public var boundMinX:Number = -1e+22;
		
		/**
		 * Задняя граница объекта в его системе координат.
		 */
		public var boundMinY:Number = -1e+22;
		
		/**
		 * Нижняя граница объекта в его системе координат.
		 */
		public var boundMinZ:Number = -1e+22;
		
		/**
		 * Правая граница объекта в его системе координат.
		 */
		public var boundMaxX:Number = 1e+22;
		
		/**
		 * Передняя граница объекта в его системе координат.
		 */
		public var boundMaxY:Number = 1e+22;
		
		/**
		 * Верхняя граница объекта в его системе координат.
		 */
		public var boundMaxZ:Number = 1e+22;

		alternativa3d var cameraMatrix:Matrix3D = new Matrix3D();
		alternativa3d var cameraMatrixData:Vector.<Number> = new Vector.<Number>(16);
		alternativa3d var projectionMatrix:Matrix3D = new Matrix3D();
		alternativa3d var _parent:Object3DContainer;
		alternativa3d var next:Object3D;
		alternativa3d var culling:int = 0;
		alternativa3d var distance:Number;
		alternativa3d var weightsSum:Vector.<Number>;
		
		alternativa3d function get isTransparent():Boolean {
			return false;
		}
		
		/**
		 * Возвращает родительский объект <code>Object3DContainer</code>.
		 */
		public function get parent():Object3DContainer {
			return _parent;
		}

		/**
		 * Объект <code>Matrix3D</code>, содержащий значения, влияющие на масштабирование, поворот и перемещение объекта.
		 */
		public function get matrix():Matrix3D {
			var m:Matrix3D = new Matrix3D();
			var t:Vector3D = new Vector3D(x, y, z);
			var r:Vector3D = new Vector3D(rotationX, rotationY, rotationZ);
			var s:Vector3D = new Vector3D(scaleX, scaleY, scaleZ);
			var v:Vector.<Vector3D> = new Vector.<Vector3D>();
			v[0] = t;
			v[1] = r;
			v[2] = s;
			m.recompose(v);
			return m;
		}
	
		/**
		 * @private
		 */
		public function set matrix(value:Matrix3D):void {
			var v:Vector.<Vector3D> = value.decompose();
			var t:Vector3D = v[0];
			var r:Vector3D = v[1];
			var s:Vector3D = v[2];
			x = t.x;
			y = t.y;
			z = t.z;
			rotationX = r.x;
			rotationY = r.y;
			rotationZ = r.z;
			scaleX = s.x;
			scaleY = s.y;
			scaleZ = s.z;
		}
		
		/**
		 * Расчитывает границы объекта в его системе координат.
		 */
		public function calculateBounds():void {
			// Выворачивание баунда
			boundMinX = 1e+22;
			boundMinY = 1e+22;
			boundMinZ = 1e+22;
			boundMaxX = -1e+22;
			boundMaxY = -1e+22;
			boundMaxZ = -1e+22;
			// Заполнение баунда
			updateBounds(this, null);
			// Если баунд вывернут
			if (boundMinX > boundMaxX) {
				boundMinX = -1e+22;
				boundMinY = -1e+22;
				boundMinZ = -1e+22;
				boundMaxX = 1e+22;
				boundMaxY = 1e+22;
				boundMaxZ = 1e+22;
			}
		}
		
		/**
		 * Преобразует точку из локальных координат в глобальные.
		 * @param point Точка в локальных координатах объекта.
		 * @return Точка в глобальном пространстве.
		 */
		/*public function localToGlobal(point:Vector3D):Vector3D {
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				appendMatrix(root);
			}
			var res:Vector3D = new Vector3D();
			res.x = ma*point.x + mb*point.y + mc*point.z + md;
			res.y = me*point.x + mf*point.y + mg*point.z + mh;
			res.z = mi*point.x + mj*point.y + mk*point.z + ml;
			return res;
		}*/
		
		/**
		 * Преобразует точку из глобальной системы координат в локальные координаты объекта.
		 * @param point Точка в глобальном пространстве.
		 * @return Точка в локальных координатах объекта.
		 */
		/*public function globalToLocal(point:Vector3D):Vector3D {
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				appendMatrix(root);
			}
			invertMatrix();
			var res:Vector3D = new Vector3D();
			res.x = ma*point.x + mb*point.y + mc*point.z + md;
			res.y = me*point.x + mf*point.y + mg*point.z + mh;
			res.z = mi*point.x + mj*point.y + mk*point.z + ml;
			return res;
		}*/
		
		/**
		 * Осуществляет поиск пересечение луча с объектом.
		 * @param origin Начало луча.
		 * @param direction Направление луча.
		 * @param exludedObjects Ассоциативный массив, ключами которого являются экземпляры <code>Object3D</code> и его наследников. Объекты, содержащиеся в этом массиве будут исключены из проверки.
		 * @param camera Камера для правильного поиска пересечения луча с объектами <code>Sprite3D</code>. Эти объекты всегда повёрнуты к камере. Если камера не указана, результат пересечения луча со спрайтом будет <code>null</code>.
		 * @return Результат поиска пересечения — объект <code>RayIntersectionData</code>. Если пересечения нет, будет возвращён <code>null</code>.
		 * @see RayIntersectionData
		 * @see alternativa.engine3d.objects.Sprite3D
		 */
		public function intersectRay(origin:Vector3D, direction:Vector3D, exludedObjects:Dictionary = null, camera:Camera3D = null):RayIntersectionData {
			return null;
		}
		
		/**
		 * Возвращает объект, являющийся точной копией исходного объекта.
		 * @return Клон исходного объекта.
		 */
		public function clone():Object3D {
			var res:Object3D = new Object3D();
			res.cloneBaseProperties(this);
			return res;
		}
	
		/**
		 * Копирует базовые свойства. Метод вызывается внутри <code>clone()</code>.
		 * @param source Объект, с которого копируются базовые свойства.
		 */
		protected function cloneBaseProperties(source:Object3D):void {
			name = source.name;
			visible = source.visible;
			distance = source.distance;
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
		}
		
		/**
		 * Возвращает строковое представление заданного объекта.
		 * @return Строковое представление объекта.
		 */
		override public function toString():String {
			var className:String = getQualifiedClassName(this);
			return "[" + className.substr(className.indexOf("::") + 2) + " " + name + "]";
		}
		
		// Переопределяемые закрытые методы
		
		/**
		 * @private 
		 */
		alternativa3d function draw(camera:Camera3D):void {
		}
	
		/**
		 * @private 
		 */
		alternativa3d function drawInShadowMap(camera:Camera3D, light:DirectionalLight):void {
		}
	
		/**
		 * @private 
		 */
		alternativa3d function updateBounds(bounds:Object3D, matrix:Matrix3D = null):void {
		}
		
		/**
		 * @private 
		 */
		alternativa3d function composeMatrix():void {
			var cosX:Number = Math.cos(rotationX);
			var sinX:Number = Math.sin(rotationX);
			var cosY:Number = Math.cos(rotationY);
			var sinY:Number = Math.sin(rotationY);
			var cosZ:Number = Math.cos(rotationZ);
			var sinZ:Number = Math.sin(rotationZ);
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			var cosYscaleX:Number = cosY*scaleX;
			var sinXscaleY:Number = sinX*scaleY;
			var cosXscaleY:Number = cosX*scaleY;
			var cosXscaleZ:Number = cosX*scaleZ;
			var sinXscaleZ:Number = sinX*scaleZ;
			cameraMatrixData[0] = cosZ*cosYscaleX;
			cameraMatrixData[4] = cosZsinY*sinXscaleY - sinZ*cosXscaleY;
			cameraMatrixData[8] = cosZsinY*cosXscaleZ + sinZ*sinXscaleZ;
			cameraMatrixData[12] = x;
			cameraMatrixData[1] = sinZ*cosYscaleX;
			cameraMatrixData[5] = sinZsinY*sinXscaleY + cosZ*cosXscaleY;
			cameraMatrixData[9] = sinZsinY*cosXscaleZ - cosZ*sinXscaleZ;
			cameraMatrixData[13] = y;
			cameraMatrixData[2] = -sinY*scaleX;
			cameraMatrixData[6] = cosY*sinXscaleY;
			cameraMatrixData[10] = cosY*cosXscaleZ;
			cameraMatrixData[14] = z;
			cameraMatrixData[3] = 0;
			cameraMatrixData[7] = 0;
			cameraMatrixData[11] = 0;
			cameraMatrixData[15] = 1;
			cameraMatrix.rawData = cameraMatrixData;
		}
		
		static private const boundVertices:Vector.<Number> = new Vector.<Number>(24);
		
		alternativa3d function cullingInCamera(camera:Camera3D, culling:int):int {
			if (culling > 0) {
				var i:int;
				var infront:Boolean;
				var behind:Boolean;
				// Заполнение
				boundVertices[0] = boundMinX;
				boundVertices[1] = boundMinY;
				boundVertices[2] = boundMinZ;
				boundVertices[3] = boundMaxX;
				boundVertices[4] = boundMinY;
				boundVertices[5] = boundMinZ;
				boundVertices[6] = boundMinX;
				boundVertices[7] = boundMaxY;
				boundVertices[8] = boundMinZ;
				boundVertices[9] = boundMaxX;
				boundVertices[10] = boundMaxY;
				boundVertices[11] = boundMinZ;
				boundVertices[12] = boundMinX;
				boundVertices[13] = boundMinY;
				boundVertices[14] = boundMaxZ;
				boundVertices[15] = boundMaxX;
				boundVertices[16] = boundMinY;
				boundVertices[17] = boundMaxZ;
				boundVertices[18] = boundMinX;
				boundVertices[19] = boundMaxY;
				boundVertices[20] = boundMaxZ;
				boundVertices[21] = boundMaxX;
				boundVertices[22] = boundMaxY;
				boundVertices[23] = boundMaxZ;
				// Трансформация в камеру
				cameraMatrix.transformVectors(boundVertices, boundVertices);
				// Коррекция под 90 градусов
				var sx:Number = camera.focalLength*2/camera.view._width;
				var sy:Number = camera.focalLength*2/camera.view._height;
				for (i = 0; i < 24; i += 2) {
					boundVertices[i] *= sx; i++;
					boundVertices[i] *= sy;
				}
				// Куллинг
				if (culling & 1) {
					for (i = 2, infront = false, behind = false; i <= 23; i += 3) {
						if (boundVertices[i] > camera.nearClipping) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 62;
					}
				}
				if (culling & 2) {
					for (i = 2, infront = false, behind = false; i <= 23; i += 3) {
						if (boundVertices[i] < camera.farClipping) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 61;
					}
				}
				if (culling & 4) {
					for (i = 0, infront = false, behind = false; i <= 21; i += 3) {
						if (-boundVertices[i] < boundVertices[int(i + 2)]) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 59;
					}
				}
				if (culling & 8) {
					for (i = 0, infront = false, behind = false; i <= 21; i += 3) {
						if (boundVertices[i] < boundVertices[int(i + 2)]) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 55;
					}
				}
				if (culling & 16) {
					for (i = 1, infront = false, behind = false; i <= 22; i += 3) {
						if (-boundVertices[i] < boundVertices[int(i + 1)]) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 47;
					}
				}
				if (culling & 32) {
					for (i = 1, infront = false, behind = false; i <= 22; i += 3) {
						if (boundVertices[i] < boundVertices[int(i + 1)]) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 31;
					}
				}
			}
			this.culling = culling;
			return culling;
		}
		
		/**
		 * @private 
		 */
		/*alternativa3d function cullingInCamera(camera:Camera3D, culling:int):int {
			if (camera.occludedAll) return -1;
			var numOccluders:int = camera.numOccluders;
			var vertex:Vertex;
			// Расчёт точек баунда в координатах камеры
			if (culling > 0 || numOccluders > 0) {
				// Заполнение
				vertex = boundVertexList;
				vertex.x = boundMinX;
				vertex.y = boundMinY;
				vertex.z = boundMinZ;
				vertex = vertex.next;
				vertex.x = boundMaxX;
				vertex.y = boundMinY;
				vertex.z = boundMinZ;
				vertex = vertex.next;
				vertex.x = boundMinX;
				vertex.y = boundMaxY;
				vertex.z = boundMinZ;
				vertex = vertex.next;
				vertex.x = boundMaxX;
				vertex.y = boundMaxY;
				vertex.z = boundMinZ;
				vertex = vertex.next;
				vertex.x = boundMinX;
				vertex.y = boundMinY;
				vertex.z = boundMaxZ;
				vertex = vertex.next;
				vertex.x = boundMaxX;
				vertex.y = boundMinY;
				vertex.z = boundMaxZ;
				vertex = vertex.next;
				vertex.x = boundMinX;
				vertex.y = boundMaxY;
				vertex.z = boundMaxZ;
				vertex = vertex.next;
				vertex.x = boundMaxX;
				vertex.y = boundMaxY;
				vertex.z = boundMaxZ;
				// Трансформация в камеру
				for (vertex = boundVertexList; vertex != null; vertex = vertex.next) {
					var x:Number = vertex.x;
					var y:Number = vertex.y;
					var z:Number = vertex.z;
					vertex.cameraX = ma*x + mb*y + mc*z + md;
					vertex.cameraY = me*x + mf*y + mg*z + mh;
					vertex.cameraZ = mi*x + mj*y + mk*z + ml;
				}
			}
			// Куллинг
			if (culling > 0) {
				var infront:Boolean;
				var behind:Boolean;
				if (culling & 1) {
					var near:Number = camera.nearClipping;
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (vertex.cameraZ > near) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 62;
					}
				}
				if (culling & 2) {
					var far:Number = camera.farClipping;
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (vertex.cameraZ < far) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 61;
					}
				}
				if (culling & 4) {
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (-vertex.cameraX < vertex.cameraZ) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 59;
					}
				}
				if (culling & 8) {
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (vertex.cameraX < vertex.cameraZ) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 55;
					}
				}
				if (culling & 16) {
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (-vertex.cameraY < vertex.cameraZ) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 47;
					}
				}
				if (culling & 32) {
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (vertex.cameraY < vertex.cameraZ) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 31;
					}
				}
			}
			// Окклюдинг
			if (numOccluders > 0) {
				for (var i:int = 0; i < numOccluders; i++) {
					for (var plane:Vertex = camera.occluders[i]; plane != null; plane = plane.next) {
						for (vertex = boundVertexList; vertex != null; vertex = vertex.next) {
							if (plane.cameraX*vertex.cameraX + plane.cameraY*vertex.cameraY + plane.cameraZ*vertex.cameraZ >= 0) break;
						}
						if (vertex != null) break;
					}
					if (plane == null) return -1;
				}
			}
			this.culling = culling;
			return culling;
		}*/
		
		/*protected function composeRenderMatrix():void {
			if (matrix != null) {
				cameraMatrix.identity();
				cameraMatrix.append(matrix);
			} else {
				composeVectors[0] = translation;
				composeVectors[1] = rotation;
				composeVectors[2] = scale;
				cameraMatrix.recompose(composeVectors);
			}
		}*/

		/*public function draw(camera:Camera3D, parent:Object3DContainer = null):void {
		}*/

		/**
		 * Возвращает объект, являющийся точной копией исходного объекта.
		 * @return Клон исходного объекта.
		 */
		/*public function clone():Object3D {
			var res:Object3D = new Object3D();
			res.cloneBaseProperties(this);
			return res;
		}*/

		/**
		 * Копирует базовые свойства. Метод вызывается внутри <code>clone()</code>.
		 * @param source Объект, с которого копируются базовые свойства.
		 */
		/*protected function cloneBaseProperties(source:Object3D):void {
			name = source.name;
			visible = source.visible;
			if (source.matrix != null) {
				matrix = source.matrix.clone();
			} else {
				translation.x = source.translation.x;
				translation.y = source.translation.y;
				translation.z = source.translation.z;
				rotation.x = source.rotation.x;
				rotation.y = source.rotation.y;
				rotation.z = source.rotation.z;
				scale.x = source.scale.x;
				scale.y = source.scale.y;
				scale.z = source.scale.z;
			}
		}*/

	}
}
