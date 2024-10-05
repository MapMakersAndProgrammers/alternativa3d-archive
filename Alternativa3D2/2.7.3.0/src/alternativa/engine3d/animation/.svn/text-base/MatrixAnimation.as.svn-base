package alternativa.engine3d.animation {
	public class MatrixAnimation extends ObjectAnimation {
	
		public var matrix:Track;
	
		private var matrixKey:MatrixKey = new MatrixKey(0, null);
	
		override protected function control():void {
			if (matrix != null) {
				matrix.getKey(_position, matrixKey);
				object.setMatrix(matrixKey.matrix);
			}
		}
	
		override public function get length():Number {
			return (matrix != null) ? matrix.length : 0;
		}
	
	}
}
