package alternativa.engine3d.objects {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	public class Bone extends Mesh {
		
		public var localTransform:Vector.<Vector3D>;
		/**
		 * @private 
		 */
		alternativa3d var localMatrix:Matrix3D;
		
		/**
		 * @private 
		 */
		alternativa3d var length:Number;
		/**
		 * @private 
		 */
		alternativa3d var distance:Number;
		/**
		 * @private 
		 */
		alternativa3d var _numChildren:uint = 0;
		/**
		 * @private 
		 */
		alternativa3d var children:Vector.<Bone> = new Vector.<Bone>();
		
		public function Bone(length:Number, distance:Number) {
			this.length = length;
			this.distance = distance;
		}
		
		public function addChild(child:Bone):void {
			children[_numChildren++] = child;
			child.localTransform = child.matrix.decompose();
			child.localMatrix = new Matrix3D();
		}
		
		public function calculateMatrix():void {
			for (var i:int = 0; i < _numChildren; i++) {
				var child:Bone = children[i]; 
				child.matrix.identity();
				child.matrix.prepend(matrix);
				child.localMatrix.recompose(child.localTransform);
				child.matrix.prepend(child.localMatrix);
				child.calculateMatrix();
			}
		}
		
	}
}
