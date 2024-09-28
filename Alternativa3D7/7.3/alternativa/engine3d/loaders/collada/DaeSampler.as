package alternativa.engine3d.loaders.collada {
	
	import alternativa.engine3d.animation.MatrixKey;
	import alternativa.engine3d.animation.PointKey;
	import alternativa.engine3d.animation.Track;
	import alternativa.engine3d.animation.ValueKey;
	
	import flash.geom.Matrix3D;
	
	/**
	 * @private
	 */
	public class DaeSampler extends DaeElement {
	
		use namespace collada;
	
		private var times:Vector.<Number>;
		private var values:Vector.<Number>;
		private var timesStride:int;
		private var valuesStride:int;
	
		public function DaeSampler(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		override protected function parseImplementation():Boolean {
			var inputsList:XMLList = data.input;
	
			var inputSource:DaeSource;
			var outputSource:DaeSource;
			for (var i:int = 0, count:int = inputsList.length(); i < count; i++) {
				var input:DaeInput = new DaeInput(inputsList[i], document);
				var semantic:String = input.semantic;
				if (semantic != null) {
					switch (semantic) {
						case "INPUT" :
							inputSource = input.prepareSource(1);
							if (inputSource != null) {
								times = inputSource.numbers;
								timesStride = inputSource.stride;
							}
							break;
						case "OUTPUT" :
							outputSource = input.prepareSource(1);
							if (outputSource != null) {
								values = outputSource.numbers;
								valuesStride = outputSource.stride;
							}
							break;
					}
				}
			}
			return true;
		}
	
		public function parseValuesTrack():Track {
			if (times != null && values != null && timesStride > 0) {
				var track:Track = new Track();
				var count:int = times.length/timesStride;
				for (var i:int = 0; i < count; i++) {
					track.addKey(new ValueKey(times[int(timesStride*i)], values[int(valuesStride*i)]));
				}
				track.sortKeys();
				// TODO:: Всякие исключительные ситуации с индексами
				return track;
			}
			return null;
		}
	
		public function parseMatrixTrack():Track {
			if (times != null && values != null && timesStride != 0) {
				var track:Track = new Track();
				var count:int = times.length/timesStride;
				for (var i:int = 0; i < count; i++) {
					var index:int = valuesStride*i;
					var matrix:Matrix3D = new Matrix3D(Vector.<Number>([values[index], values[index + 4], values[index + 8], values[index + 12],
						values[index + 1], values[index + 5], values[index + 9],  values[index + 13],
						values[index + 2], values[index + 6], values[index + 10], values[index + 14],
						values[index + 3] ,values[index + 7], values[index + 11], values[index + 15]]));
					track.addKey(new MatrixKey(times[i*timesStride], matrix));
				}
				track.sortKeys();
				return track;
			}
			return null;
		}
	
		public function parsePointsTrack():Track {
			if (times != null && values != null && timesStride != 0) {
				var track:Track = new Track();
				var count:int = times.length/timesStride;
				for (var i:int = 0; i < count; i++) {
					var index:int = i*valuesStride;
					track.addKey(new PointKey(times[i*timesStride], values[index], values[index + 1], values[index + 2]));
				}
				track.sortKeys();
				return track;
				// TODO:: Всякие исключительные ситуации с индексами
			}
			return null;
		}
	
	}
}
