package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Clipping;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Sorting;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	import alternativa.engine3d.materials.TextureMaterial;

	import flash.geom.Matrix;
	import flash.geom.Point;
	import alternativa.engine3d.materials.Material;

	use namespace alternativa3d;
	
	/**
	 * Полигональный объект, состоящий из вершин и граней, построенных по этим вершинам.
	 * <code>SkyBox</code> представляет из себя куб из шести граней, направленных внутрь.
	 * @see alternativa.engine3d.core.Vertex
	 * @see alternativa.engine3d.core.Face
	 */
	public class SkyBox extends Mesh {
		
		/**
		 * Левая сторона.
		 */
		static public const LEFT:String = "left";
		
		/**
		 * Правая сторона.
		 */
		static public const RIGHT:String = "right";
		
		/**
		 * Задняя сторона.
		 */
		static public const BACK:String = "back";
		
		/**
		 * Передняя сторона.
		 */
		static public const FRONT:String = "front";
		
		/**
		 * Нижняя сторона.
		 */
		static public const BOTTOM:String = "bottom";
		
		/**
		 * Верхняя сторона.
		 */
		static public const TOP:String = "top";
		
		private var leftFace:Face;
		private var rightFace:Face;
		private var backFace:Face;
		private var frontFace:Face;
		private var bottomFace:Face;
		private var topFace:Face;
		
		/**
		 * Создаёт новый экземпляр.
		 * @param size Размер по всем трём осям.
		 * @param left Материал для левой стороны.
		 * @param right Материал для правой стороны.
		 * @param back Материал для задней стороны.
		 * @param front Материал для передней стороны.
		 * @param bottom Материал для нижней стороны.
		 * @param top Материал для верхней стороны.
		 * @param uvPadding Отступ от краёв в текстурных координатах.
		 * @see alternativa.engine3d.materials.Material
		 */
		public function SkyBox(size:Number, left:Material = null, right:Material = null, back:Material = null, front:Material = null, bottom:Material = null, top:Material = null, uvPadding:Number = 0) {
			
			size *= 0.5;
			
			var a:Vertex = createVertex(-size, -size, size, uvPadding, uvPadding);
			var b:Vertex = createVertex(-size, -size, -size, uvPadding, 1 - uvPadding);
			var c:Vertex = createVertex(-size, size, -size, 1 - uvPadding, 1 - uvPadding);
			var d:Vertex = createVertex(-size, size, size, 1 - uvPadding, uvPadding);
			leftFace = createQuad(a, b, c, d, left);
			
			a = createVertex(size, size, size, uvPadding, uvPadding);
			b = createVertex(size, size, -size, uvPadding, 1 - uvPadding);
			c = createVertex(size, -size, -size, 1 - uvPadding, 1 - uvPadding);
			d = createVertex(size, -size, size, 1 - uvPadding, uvPadding);
			rightFace = createQuad(a, b, c, d, right);
			
			a = createVertex(size, -size, size, uvPadding, uvPadding);
			b = createVertex(size, -size, -size, uvPadding, 1 - uvPadding);
			c = createVertex(-size, -size, -size, 1 - uvPadding, 1 - uvPadding);
			d = createVertex(-size, -size, size, 1 - uvPadding, uvPadding);
			backFace = createQuad(a, b, c, d, back);
			
			a = createVertex(-size, size, size, uvPadding, uvPadding);
			b = createVertex(-size, size, -size, uvPadding, 1 - uvPadding);
			c = createVertex(size, size, -size, 1 - uvPadding, 1 - uvPadding);
			d = createVertex(size, size, size, 1 - uvPadding, uvPadding);
			frontFace = createQuad(a, b, c, d, front);
			
			a = createVertex(-size, size, -size, uvPadding, uvPadding);
			b = createVertex(-size, -size, -size, uvPadding, 1 - uvPadding);
			c = createVertex(size, -size, -size, 1 - uvPadding, 1 - uvPadding);
			d = createVertex(size, size, -size, 1 - uvPadding, uvPadding);
			bottomFace = createQuad(a, b, c, d, bottom);
			
			a = createVertex(-size, -size, size, uvPadding, uvPadding);
			b = createVertex(-size, size, size, uvPadding, 1 - uvPadding);
			c = createVertex(size, size, size, 1 - uvPadding, 1 - uvPadding);
			d = createVertex(size, -size, size, 1 - uvPadding, uvPadding);
			topFace = createQuad(a, b, c, d, top);
			
			calculateBounds();
			calculateNormals(true);
			
			clipping = Clipping.FACE_CLIPPING;
			sorting = Sorting.NONE;
		}
		
		/**
		 * Возвращает грань по строковому идентификатору.
		 * Можно использовать константы класса <code>SkyBox</code>: <code>SkyBox.LEFT</code>, <code>SkyBox.RIGHT</code>, <code>SkyBox.BACK</code>, <code>SkyBox.FRONT</code>, <code>SkyBox.BOTTOM</code>, <code>SkyBox.TOP</code>.
		 * @param side Идентификатор грани.
		 * @return Грань по идентификатору.
		 * @see alternativa.engine3d.core.Face
		 */
		public function getSide(side:String):Face {
			switch (side) {
				case LEFT:
					return leftFace;
				case RIGHT:
					return rightFace;
				case BACK:
					return backFace;
				case FRONT:
					return frontFace;
				case BOTTOM:
					return bottomFace;
				case TOP:
					return topFace;
			}
			return null;
		}
		
		/**
		 * Трансформирует текстурные координаты грани.
		 * @param side Идентификатор грани.
		 * @param matrix Матрица трансформации.
		 * @see alternativa.engine3d.core.Face
		 */
		public function transformUV(side:String, matrix:Matrix):void {
			var face:Face = getSide(side);
			if (face != null) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var vertex:Vertex = wrapper.vertex;
					var res:Point = matrix.transformPoint(new Point(vertex.u, vertex.v));
					vertex.u = res.x;
					vertex.v = res.y;
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:SkyBox = new SkyBox(0);
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			// Клонирование отметок
			var src:SkyBox = source as SkyBox;
			for (var face:Face = src.faceList, newFace:Face = faceList; face != null; face = face.next, newFace = newFace.next) {
				if (face == src.leftFace) {
					leftFace = newFace;
				} else if (face == src.rightFace) {
					rightFace = newFace;
				} else if (face == src.backFace) {
					backFace = newFace;
				} else if (face == src.frontFace) {
					frontFace = newFace;
				} else if (face == src.bottomFace) {
					bottomFace = newFace;
				} else if (face == src.topFace) {
					topFace = newFace;
				}
			}
		}
		
		private function createVertex(x:Number, y:Number, z:Number, u:Number, v:Number):Vertex {
			var newVertex:Vertex = new Vertex();
			newVertex.next = vertexList;
			vertexList = newVertex;
			newVertex.x = x;
			newVertex.y = y;
			newVertex.z = z;
			newVertex.u = u;
			newVertex.v = v;
			return newVertex;
		}
		
		private function createQuad(a:Vertex, b:Vertex, c:Vertex, d:Vertex, material:Material):Face {
			var newFace:Face = new Face();
			newFace.material = material;
			newFace.next = faceList;
			faceList = newFace;
			newFace.wrapper = new Wrapper();
			newFace.wrapper.vertex = a;
			newFace.wrapper.next = new Wrapper();
			newFace.wrapper.next.vertex = b;
			newFace.wrapper.next.next = new Wrapper();
			newFace.wrapper.next.next.vertex = c;
			newFace.wrapper.next.next.next = new Wrapper();
			newFace.wrapper.next.next.next.vertex = d;
			return newFace;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas):void {
			culling &= ~3;
			super.draw(camera, parentCanvas);
		}
		
	}
}
