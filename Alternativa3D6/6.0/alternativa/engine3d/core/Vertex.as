package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.types.Matrix3D;
	import alternativa.types.Point3D;
	import alternativa.types.Set;
	
	use namespace alternativa3d;
	
	/**
	 * Вершина полигона в трёхмерном пространстве. Вершина хранит свои координаты, а также ссылки на
	 * полигональный объект и грани этого объекта, которым она принадлежит. 
	 */
	final public class Vertex {
		/**
		 * @private
		 * Меш
		 */
		alternativa3d var _mesh:Mesh;
		/**
		 * @private
		 * Координаты точки
		 */
		alternativa3d var _coords:Point3D = new Point3D();
		/**
		 * @private
		 * Грани
		 */
		alternativa3d var _faces:Set = new Set();
		/**
		 * @private
		 * Координаты в сцене
		 */
		alternativa3d var spaceCoords:Point3D = new Point3D();
		
		/**
		 * Создание экземпляра вершины.
		 * 
		 * @param x координата вершины по оси X
		 * @param y координата вершины по оси Y
		 * @param z координата вершины по оси Z
		 */
		public function Vertex() {}
		
		// Вызывается при изменении координат вершины, как вручную, так и при трансформации меша
		alternativa3d function move():void {
			trace(this, "move");
			
			spaceCoords.copy(_coords);
			spaceCoords.transform(_mesh.spaceMatrix);
			
			delete _mesh._scene.verticesToMove[this];
		}
		
		/**
		 * @private
		 */
		public function set x(value:Number):void {
			if (_coords.x != value) {
				_coords.x = value;
				markToMove();
			}
		}		

		/**
		 * @private
		 */
		public function set y(value:Number):void {
			if (_coords.y != value) {
				_coords.y = value;
				markToMove();
			}
		}

		/**
		 * @private
		 */
		public function set z(value:Number):void {
			if (_coords.z != value) {
				_coords.z = value;
				markToMove();
			}
		}
		
		/**
		 * @private
		 */
		public function set coords(value:Point3D):void {
			if (!_coords.equals(value)) {
				_coords.copy(value);
				markToMove();
			}
		}
		
		/**
		 * Добавление сигнала об изменении координат вершины в сцену.
		 * Также добавляются сигналы на трансформацию для зависимых видимых граней.  
		 */
		private function markToMove():void {
			var scene:Scene3D;
			if (_mesh != null && (scene = _mesh._scene) != null) {
				// Пометка вершины на перемещение
				scene.verticesToMove[this] = true;
				for (var key:* in _faces) {
					var face:Face = key;
					if (face.pointPrimitive != null || face.polyPrimitive != null) {
						// Пометка зависимой грани, если у неё есть примитив
						scene.facesToTransform[face] = true;
					}
				}
			}
		}

		/**
		 * Координата вершины по оси X.
		 */
		public function get x():Number {
			return _coords.x;
		}		

		/**
		 * Координата вершины по оси Y.
		 */
		public function get y():Number {
			return _coords.y;
		}		

		/**
		 * Координата вершины по оси Z.
		 */
		public function get z():Number {
			return _coords.z;
		}
		
		/**
		 * Координаты вершины.
		 */
		public function get coords():Point3D {
			return _coords.clone();
		}
		
		/**
		 * Полигональный объект, которому принадлежит вершина.
		 */
		public function get mesh():Mesh {
			return _mesh;
		}

		/**
		 * Множество граней, которым принадлежит вершина. Каждый элемент множества является объектом класса
		 * <code>altertnativa.engine3d.core.Face</code>.
		 * 
		 * @see Face
		 */		
		public function get faces():Set {
			return _faces.clone();
		}
		
		/**
		 * Идентификатор вершины в полигональном объекте. Если вершина не принадлежит полигональному объекту, возвращается <code>null</code>.
		 */
		public function get id():Object {
			return (_mesh != null) ? _mesh.getVertexId(this) : null;
		}
		
		/**
		 * Строковое представление объекта.
		 * 
		 * @return строковое представление объекта
		 */		
		public function toString():String {
			return "[Vertex ID:" + id + " " + _coords.x.toFixed(2) + ", " + _coords.y.toFixed(2) + ", " + _coords.z.toFixed(2) + "]";
		}
	}
}