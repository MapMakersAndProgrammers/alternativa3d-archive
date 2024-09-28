package alternativa.engine3d.objects {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.core.Geometry;
	
	use namespace alternativa3d;
	
	public class Joint extends Object3D {
	
		private var joints:Vector.<Joint> = new Vector.<Joint>();
		private var _numJoints:uint = 0;
	
		alternativa3d var vertexBindingList:VertexBinding;
	
		// Матрица привязки
		private var ba:Number;
		private var bb:Number;
		private var bc:Number;
		private var bd:Number;
		private var be:Number;
		private var bf:Number;
		private var bg:Number;
		private var bh:Number;
		private var bi:Number;
		private var bj:Number;
		private var bk:Number;
		private var bl:Number;
	
		alternativa3d function calculateBindingMatrix(parent:Object3D):void {
			composeAndAppend(parent);
			calculateInverseMatrix(this);
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
	
		alternativa3d function addWeights():void {
			for (var vertexBinding:VertexBinding = vertexBindingList; vertexBinding != null; vertexBinding = vertexBinding.next) vertexBinding.vertex.offset += vertexBinding.weight;
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.addWeights();
			}
		}
	
		alternativa3d function normalizeWeights():void {
			for (var vertexBinding:VertexBinding = vertexBindingList; vertexBinding != null; vertexBinding = vertexBinding.next) vertexBinding.weight /= vertexBinding.vertex.offset;
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.normalizeWeights();
			}
		}
	
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			var canvas:Canvas;
			var debug:int;
			composeAndAppend(object);
			calculateVertices();
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.draw(camera, this, parentCanvas);
			}
			// Дебаг
			if (camera.debug && (debug = camera.checkInDebug(this)) > 0) {
				canvas = parentCanvas.getChildCanvas(object, true, false);
				if (debug & Debug.BONES) drawBone(camera, canvas, 0xFFFFFF);
			}
		}
		
		override alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			composeAndAppend(object);
			calculateVertices();
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.getGeometry(camera, this);
			}
			return null;
		}
		
		private function drawBone(camera:Camera3D, canvas:Canvas, color:int):void {
			for (var i:int = 0; i < _numJoints; i++) {
				var x1:Number = 0;
				var y1:Number = 0;
				var z1:Number = 0;
				var bone:Joint = joints[i];
				var x2:Number = bone.x;
				var y2:Number = bone.y;
				var z2:Number = bone.z;
				var cx1:Number = ma*x1 + mb*y1 + mc*z1 + md;
				var cy1:Number = me*x1 + mf*y1 + mg*z1 + mh;
				var cz1:Number = mi*x1 + mj*y1 + mk*z1 + ml;
				var cx2:Number = ma*x2 + mb*y2 + mc*z2 + md;
				var cy2:Number = me*x2 + mf*y2 + mg*z2 + mh;
				var cz2:Number = mi*x2 + mj*y2 + mk*z2 + ml;
				// Проецирование
				var viewSizeX:Number = camera.viewSizeX;
				var viewSizeY:Number = camera.viewSizeY;
				var t1:Number = 1/cz1;
				var t2:Number = 1/cz2;
				var px1:Number = cx1*viewSizeX*t1;
				var py1:Number = cy1*viewSizeY*t1;
				var px2:Number = cx2*viewSizeX*t2;
				var py2:Number = cy2*viewSizeY*t2;
				canvas.gfx.lineStyle(0, color);
				canvas.gfx.moveTo(px1, py1);
				canvas.gfx.lineTo(px2, py2);
			}
		}
	
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
		}
	
		public function bindVertex(vertex:Vertex, weight:Number = 1):void {
			if (weight > 0) {
				var vertexBinding:VertexBinding = new VertexBinding();
				vertexBinding.next = vertexBindingList;
				vertexBindingList = vertexBinding;
				vertexBinding.vertex = vertex;
				vertexBinding.weight = weight;
			}
		}
	
		public function addJoint(joint:Joint):void {
			joints[_numJoints] = joint;
			_numJoints++;
		}
	
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
	
		public function get numJoints():uint {
			return _numJoints;
		}
	
		public function getJointAt(index:uint):Joint {
			return joints[index];
		}
	
		alternativa3d override function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
			composeAndAppend(transformation);
			calculateVertices();
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = joints[i];
				joint.updateBounds(bounds, this);
			}
		}
	
	}
}
