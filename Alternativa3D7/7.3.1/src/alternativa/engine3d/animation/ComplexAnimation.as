package alternativa.engine3d.animation {
	public class ComplexAnimation extends Animation {
	
		private var _numAnimations:int;
		private var animations:Vector.<Animation>;
	
		public function ComplexAnimation() {
			animations = new Vector.<Animation>();
		}
	
		public function addAnimation(animation:Animation):Animation {
			if (animation == null) {
				throw new Error("Animation cannot be null");
			}
			animations[_numAnimations++] = animation;
			return animation;
		}
	
		public function removeAnimation(animation:Animation):Animation {
			var index:int = animations.indexOf(animation);
			if (index < 0) throw new ArgumentError("Animation not found");
			_numAnimations--;
			var j:int = index + 1;
			while (index < _numAnimations) {
				animations[index] = animations[j];
				index++;
				j++;
			}
			animations.length = _numAnimations;
			return animation;
		}

		public function get numAnimations():int {
			return _numAnimations;
		}

		public function getAnimationAt(index:int):Animation {
			return animations[index];
		}

		override protected function control():void {
			for (var i:int = 0; i < _numAnimations; i++) {
				var animation:Animation = animations[i];
				if (animation.playing) {
					animation.position = _position;
				}
			}
		}

		override public function get length():Number {
			var maxLen:Number = 0;
			for (var i:int = 0; i < _numAnimations; i++) {
				var time:Number = animations[i].length;
				if (time > maxLen) {
					maxLen = time;
				}
			}
			return maxLen;
		}

	}
}
