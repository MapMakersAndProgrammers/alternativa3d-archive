package alternativa.engine3d.objects {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	
	import flash.geom.Matrix3D;

	use namespace alternativa3d;

	public class Joint extends Object3D {

		private var _joints:Vector.<Joint>;
		private var _numJoints:int = 0;

		private var bindingMatrix:Matrix3D;
		
		alternativa3d var localMatrix:Matrix3D = new Matrix3D();
		
		alternativa3d var index:int;
		
		public function setBindingMatrix(matrix:Matrix3D):void {
			bindingMatrix = matrix;
		}

		public function calculateMatrix():void {
			for (var i:int = 0; i < _numJoints; i++) {
				var joint:Joint = _joints[i];
				joint.composeMatrix();
				joint.projectionMatrix.identity();
				joint.projectionMatrix.append(joint.cameraMatrix);
				joint.projectionMatrix.append(projectionMatrix);
				joint.localMatrix.identity();
				joint.localMatrix.append(joint.cameraMatrix);
				joint.localMatrix.append(localMatrix);
				joint.calculateMatrix();
				if (joint.bindingMatrix != null) {
					joint.projectionMatrix.prepend(joint.bindingMatrix);
					joint.localMatrix.prepend(joint.bindingMatrix);
				}
			}
		}

		public function addJoint(joint:Joint):Joint {
			if (joint == null) {
				throw new Error("Joint cannot be null");
			}
			if (_joints == null) {
				_joints = new Vector.<Joint>();
			}
			_joints[_numJoints++] = joint;
			return joint;
		}

		public function removeJoint(joint:Joint):Joint {
			var index:int = _joints.indexOf(joint);
			if (index < 0) throw new ArgumentError("Joint not found");
			_numJoints--;
			var j:int = index + 1;
			while (index < _numJoints) {
				_joints[index] = _joints[j];
				index++;
				j++;
			}
			if (_numJoints <= 0) {
				_joints = null;
			} else {
				_joints.length = _numJoints;
			}
			return joint;
		}

		public function get numJoints():int {
			return _numJoints;
		}

		public function getJointAt(index:int):Joint {
			return _joints[index];
		}
		
		override public function clone():Object3D {
			var res:Joint = new Joint();
			res.cloneBaseProperties(this);
			return res;
		}

		override protected function cloneBaseProperties(source:Object3D):void {
			super.cloneBaseProperties(source);
			var sourceJoint:Joint = Joint(source);
			_numJoints = sourceJoint._numJoints;
			if (_numJoints > 0) {
				_joints = new Vector.<Joint>(_numJoints);
				for (var i:int = 0; i < _numJoints; i++) {
					_joints[i] = Joint(sourceJoint._joints[i].clone());
				}
			}
			if (sourceJoint.bindingMatrix != null) {
				bindingMatrix = sourceJoint.bindingMatrix.clone();
			}
		}

	}
}
