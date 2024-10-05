package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.VG;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Wrapper;
	
	use namespace alternativa3d;
	
	/**
	 * Полигональный объект, состоящий из вершин и граней, построенных по этим вершинам.
	 * Также в него входят объекты <code>Joint</code>, которые имеют связи с вершинами и могут выстраиваться в иерархию.
	 * @see alternativa.engine3d.objects.Joint
	 * @see alternativa.engine3d.core.Vertex
	 * @see alternativa.engine3d.core.Face
	 */
	public class Skin extends Mesh {
	
		private var joints:Vector.<Joint> = new Vector.<Joint>();
		private var _numJoints:uint = 0;
	
		/**
		 * Добавляет узел.
		 * @param joint Добавляемый узел.
		 * @see alternativa.engine3d.objects.Joint
		 */
		public function addJoint(joint:Joint):void {
			joints[_numJoints++] = joint;
		}
	
		/**
		 * Удаляет узел.
		 * @param joint Удаляемый узел.
		 * @see alternativa.engine3d.objects.Joint
		 */
		public function removeJoint(joint:Joint):void {
			var i:int = joints.indexOf(joint);
			if (i < 0) throw new ArgumentError("Joint not found");
			_numJoints--;
			var j:int = i + 1;
			while (i < _numJoints) {
				joints[i] = joints[j];
				i++;
				j++;
			}
			joints.length = _numJoints;
		}
	
		/**
		 * Возвращает узел, существующий в заданной позиции.
		 * @param index Заданная позиция.
		 * @return Узел с заданной позицией.
		 * @see alternativa.engine3d.objects.Joint
		 */
		public function getJointAt(index:uint):Joint {
			return joints[index];
		}
		
		/**
		 * Количество узлов.
		 * @see alternativa.engine3d.objects.Joint
		 */
		public function get numJoints():uint {
			return _numJoints;
		}
	
		/**
		 * Расчитывает матрицы узлов.
		 * @see alternativa.engine3d.objects.Joint
		 */
		public function calculateBindingMatrices():void {
			ma = 1;
			mb = 0;
			mc = 0;
			md = 0;
			me = 0;
			mf = 1;
			mg = 0;
			mh = 0;
			mi = 0;
			mj = 0;
			mk = 1;
			ml = 0;
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.calculateBindingMatrix(this);
			}
		}
	
		/**
		 * Нормализует веса.
		 */
		public function normalizeWeights():void {
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) vertex.offset = 0;
			var joint:Joint;
			for (var i:int = 0; i < _numJoints; i++) {
				joint = joints[i];
				joint.addWeights();
			}
			for (i = 0; i < _numJoints; i++) {
				joint = joints[i];
				joint.normalizeWeights();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var skin:Skin = new Skin();
			skin.cloneBaseProperties(this);
			skin.clipping = clipping;
			skin.sorting = sorting;
			skin.threshold = threshold;
			// Клонирование вершин
			var vertex:Vertex;
			var lastVertex:Vertex;
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				var newVertex:Vertex = new Vertex();
				newVertex.x = vertex.x;
				newVertex.y = vertex.y;
				newVertex.z = vertex.z;
				newVertex.u = vertex.u;
				newVertex.v = vertex.v;
				vertex.value = newVertex;
				if (lastVertex != null) {
					lastVertex.next = newVertex;
				} else {
					skin.vertexList = newVertex;
				}
				lastVertex = newVertex;
			}
			// Клонирование граней
			var lastFace:Face;
			for (var face:Face = faceList; face != null; face = face.next) {
				var newFace:Face = new Face();
				newFace.material = face.material;
				newFace.normalX = face.normalX;
				newFace.normalY = face.normalY;
				newFace.normalZ = face.normalZ;
				newFace.offset = face.offset;
				// Клонирование обёрток
				var lastWrapper:Wrapper = null;
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var newWrapper:Wrapper = new Wrapper();
					newWrapper.vertex = wrapper.vertex.value;
					if (lastWrapper != null) {
						lastWrapper.next = newWrapper;
					} else {
						newFace.wrapper = newWrapper;
					}
					lastWrapper = newWrapper;
				}
				if (lastFace != null) {
					lastFace.next = newFace;
				} else {
					skin.faceList = newFace;
				}
				lastFace = newFace;
			}
			// Клонирование костей
			for (var i:int = 0; i < _numJoints; i++) {
				skin.joints[skin._numJoints++] = cloneJoint(joints[i]);
			}
			// Сброс после ремапа
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
			return skin;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function prepareFaces(camera:Camera3D):Face {
			var first:Face;
			var last:Face;
			// Обнуление вершин
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.cameraX = 0;
				vertex.cameraY = 0;
				vertex.cameraZ = 0;
				vertex.drawId = 0;
			}
			// Расчёт координат вершин
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.composeAndAppend(this);
				joint.calculateVertices();
			}
			// Отсечение по нормалям
			for (var face:Face = faceList; face != null; face = face.next) {
				var a:Vertex = face.wrapper.vertex;
				var b:Vertex = face.wrapper.next.vertex;
				var c:Vertex = face.wrapper.next.next.vertex;
				var abx:Number = b.cameraX - a.cameraX;
				var aby:Number = b.cameraY - a.cameraY;
				var abz:Number = b.cameraZ - a.cameraZ;
				var acx:Number = c.cameraX - a.cameraX;
				var acy:Number = c.cameraY - a.cameraY;
				var acz:Number = c.cameraZ - a.cameraZ;
				if ((acz*aby - acy*abz)*a.cameraX + (acx*abz - acz*abx)*a.cameraY + (acy*abx - acx*aby)*a.cameraZ < 0) {
					if (first != null) {
						last.processNext = face;
					} else {
						first = face;
					}
					last = face;
				}
			}
			if (last != null) last.processNext = null;
			return first;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function drawDebug(camera:Camera3D, canvas:Canvas, list:Face, debug:int):void {
			super.drawDebug(camera, canvas, list, debug);
			if (debug & Debug.BONES) {
				for (var i:int = 0; i < _numJoints; i++) {
					var joint:Joint = joints[i];
					joint.drawDebug(camera, canvas);
				}
			}
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			// Обнуление вершин
			for (vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.cameraX = 0;
				vertex.cameraY = 0;
				vertex.cameraZ = 0;
			}
			// Расчёт координат вершин
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				if (transformation != null) {
					joint.composeAndAppend(transformation);
				} else {
					joint.composeMatrix();
				}
				joint.calculateVertices();
			}
			// Расширение баунда
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) {
				if (vertex.cameraX < bounds.boundMinX) bounds.boundMinX = vertex.cameraX;
				if (vertex.cameraX > bounds.boundMaxX) bounds.boundMaxX = vertex.cameraX;
				if (vertex.cameraY < bounds.boundMinY) bounds.boundMinY = vertex.cameraY;
				if (vertex.cameraY > bounds.boundMaxY) bounds.boundMaxY = vertex.cameraY;
				if (vertex.cameraZ < bounds.boundMinZ) bounds.boundMinZ = vertex.cameraZ;
				if (vertex.cameraZ > bounds.boundMaxZ) bounds.boundMaxZ = vertex.cameraZ;
			}
		}
		
		private function cloneJoint(joint:Joint):Joint {
			var res:Joint = new Joint();
			res.name = joint.name;
			res.x = joint.x;
			res.y = joint.y;
			res.z = joint.z;
			res.rotationX = joint.rotationX;
			res.rotationY = joint.rotationY;
			res.rotationZ = joint.rotationZ;
			res.scaleX = joint.scaleX;
			res.scaleY = joint.scaleY;
			res.scaleZ = joint.scaleZ;
			res.ba = joint.ba;
			res.bb = joint.bb;
			res.bc = joint.bc;
			res.bd = joint.bd;
			res.be = joint.be;
			res.bf = joint.bf;
			res.bg = joint.bg;
			res.bh = joint.bh;
			res.bi = joint.bi;
			res.bj = joint.bj;
			res.bk = joint.bk;
			res.bl = joint.bl;
			if (joint is Bone) {
				Bone(res).length = Bone(joint).length;
				Bone(res).distance = Bone(joint).distance;
				Bone(res).lx = Bone(joint).lx;
				Bone(res).ly = Bone(joint).ly;
				Bone(res).lz = Bone(joint).lz;
				Bone(res).ldot = Bone(joint).ldot;
			}
			var lastBinding:VertexBinding;
			for (var binding:VertexBinding = joint.vertexBindingList; binding != null; binding = binding.next) {
				var newBinding:VertexBinding = new VertexBinding();
				newBinding.vertex = binding.vertex.value;
				newBinding.weight = binding.weight;
				if (lastBinding != null) {
					lastBinding.next = newBinding;
				} else {
					res.vertexBindingList = newBinding;
				}
				lastBinding = newBinding;
			}
			for (var i:int = 0; i < joint._numJoints; i++) {
				res.joints[res._numJoints++] = cloneJoint(joint.joints[i]);
			}
			return res;
		}
		
	}
}
