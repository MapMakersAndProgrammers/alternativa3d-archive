package alternativa.engine3d.objects {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	
	use namespace alternativa3d;
	
	/**
	 * <code>Joint</code> является составной частью объекта <code>Skin</code>.
	 * Используется в скелетной анимации.
	 * @see alternativa.engine3d.objects.Skin
	 */
	public class Joint extends Object3D {
	
		/**
		 * @private 
		 */
		alternativa3d var joints:Vector.<Joint> = new Vector.<Joint>();
		
		/**
		 * @private 
		 */
		alternativa3d var _numJoints:uint = 0;
	
		/**
		 * @private 
		 */
		alternativa3d var vertexBindingList:VertexBinding;
		
		// Матрица привязки
		
		/**
		 * @private 
		 */
		alternativa3d var ba:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bb:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bc:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bd:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var be:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bf:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bg:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bh:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bi:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bj:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bk:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bl:Number;
		
		/**
		 * Добавляет узел.
		 * @param joint Добавляемый узел.
		 */
		public function addJoint(joint:Joint):void {
			joints[_numJoints] = joint;
			_numJoints++;
		}
		
		/**
		 * Удаляет узел.
		 * @param joint Удаляемый узел.
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
		 */
		public function getJointAt(index:uint):Joint {
			return joints[index];
		}
		
		/**
		 * Количество узлов.
		 */
		public function get numJoints():uint {
			return _numJoints;
		}
		
		/**
		 * Создаёт связь с вершиной и устанавливает вес.
		 * @param vertex Вершина.
		 * @param weight Вес.
		 * @see alternativa.engine3d.core.Vertex
		 */
		public function bindVertex(vertex:Vertex, weight:Number = 1):void {
			if (weight > 0) {
				var vertexBinding:VertexBinding = new VertexBinding();
				vertexBinding.next = vertexBindingList;
				vertexBindingList = vertexBinding;
				vertexBinding.vertex = vertex;
				vertexBinding.weight = weight;
			}
		}
	
		/**
		 * @private 
		 */
		alternativa3d function calculateBindingMatrix(parent:Object3D):void {
			composeAndAppend(parent);
			calculateInverseMatrix();
			ba = ima;
			bb = imb;
			bc = imc;
			bd = imd;
			be = ime;
			bf = imf;
			bg = img;
			bh = imh;
			bi = imi;
			bj = imj;
			bk = imk;
			bl = iml;
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.calculateBindingMatrix(this);
			}
		}
	
		/**
		 * @private
		 * Задает матрицу перевода из кости в скин.
		 */
		alternativa3d function setBindingMatrix(a:Number, b:Number, c:Number, d:Number, e:Number, f:Number, g:Number, h:Number, i:Number, j:Number, k:Number, l:Number):void {
			ba = a;
			bb = b;
			bc = c;
			bd = d;
			be = e;
			bf = f;
			bg = g;
			bh = h;
			bi = i;
			bj = j;
			bk = k;
			bl = l;
		}
	
		/**
		 * @private 
		 */
		alternativa3d function addWeights():void {
			for (var vertexBinding:VertexBinding = vertexBindingList; vertexBinding != null; vertexBinding = vertexBinding.next) vertexBinding.vertex.offset += vertexBinding.weight;
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.addWeights();
			}
		}
	
		/**
		 * @private 
		 */
		alternativa3d function normalizeWeights():void {
			for (var vertexBinding:VertexBinding = vertexBindingList; vertexBinding != null; vertexBinding = vertexBinding.next) vertexBinding.weight /= vertexBinding.vertex.offset;
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.normalizeWeights();
			}
		}
	
		/**
		 * @private 
		 */
		alternativa3d function drawDebug(camera:Camera3D, canvas:Canvas):void {
			var x1:Number = md*camera.viewSizeX/ml;
			var y1:Number = mh*camera.viewSizeY/ml;
			var z:Number;
			var x2:Number;
			var y2:Number;
			var length:Number;
			var perspectiveScaleX:Number = camera.focalLength/camera.viewSizeX;
			var perspectiveScaleY:Number = camera.focalLength/camera.viewSizeY;
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				z = mi*joint.x + mj*joint.y + mk*joint.z + ml;
				x2 = (ma*joint.x + mb*joint.y + mc*joint.z + md)*camera.viewSizeX/z;
				y2 = (me*joint.x + mf*joint.y + mg*joint.z + mh)*camera.viewSizeY/z;
				var dx:Number = (ma*joint.x + mb*joint.y + mc*joint.z)/perspectiveScaleX;
				var dy:Number = (me*joint.x + mf*joint.y + mg*joint.z)/perspectiveScaleY;
				var dz:Number = mi*joint.x + mj*joint.y + mk*joint.z;
				length = Math.sqrt(dx*dx + dy*dy + dz*dz);
				if (ml > 0 && z > 0) {
					Debug.drawBone(canvas, x1, y1, x2, y2, (length/10)*camera.focalLength/ml, 0x0000FF);
				}
				joint.drawDebug(camera, canvas);
			}
			if (_numJoints == 0) {
				length = 0;
				for (var v:VertexBinding = vertexBindingList; v != null; v = v.next) {
					var dot:Number = (v.vertex.cameraX - md)*ma/perspectiveScaleX/perspectiveScaleX + (v.vertex.cameraY - mh)*me/perspectiveScaleY/perspectiveScaleY + (v.vertex.cameraZ - ml)*mi;
					if (dot > length) length = dot;
				}
				if (length > 0) {
					z = mi*length + ml;
					x2 = (ma*length + md)*camera.viewSizeX/z;
					y2 = (me*length + mh)*camera.viewSizeY/z;
					if (ml > 0 && z > 0) {
						Debug.drawBone(canvas, x1, y1, x2, y2, (length/10)*camera.focalLength/ml, 0x0000FF);
					}
				}
			}
		}
	
		/**
		 * @private 
		 */
		alternativa3d function calculateVertices():void {
			// Матрица изменений координат в соответствии с изменением положения кости относительно слепка
			ima = ma*ba + mb*be + mc*bi;
			imb = ma*bb + mb*bf + mc*bj;
			imc = ma*bc + mb*bg + mc*bk;
			imd = ma*bd + mb*bh + mc*bl + md;
			ime = me*ba + mf*be + mg*bi;
			imf = me*bb + mf*bf + mg*bj;
			img = me*bc + mf*bg + mg*bk;
			imh = me*bd + mf*bh + mg*bl + mh;
			imi = mi*ba + mj*be + mk*bi;
			imj = mi*bb + mj*bf + mk*bj;
			imk = mi*bc + mj*bg + mk*bk;
			iml = mi*bd + mj*bh + mk*bl + ml;
			// Расчёт координат
			for (var vertexBinding:VertexBinding = vertexBindingList; vertexBinding != null; vertexBinding = vertexBinding.next) {
				var vertex:Vertex = vertexBinding.vertex;
				vertex.cameraX += (ima*vertex.x + imb*vertex.y + imc*vertex.z + imd)*vertexBinding.weight;
				vertex.cameraY += (ime*vertex.x + imf*vertex.y + img*vertex.z + imh)*vertexBinding.weight;
				vertex.cameraZ += (imi*vertex.x + imj*vertex.y + imk*vertex.z + iml)*vertexBinding.weight;
			}
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.composeAndAppend(this);
				joint.calculateVertices();
			}
		}
	
	}
}
