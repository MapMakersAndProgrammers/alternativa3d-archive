package alternativa.engine3d.animation {

	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	import alternativa.engine3d.objects.Joint;
	import alternativa.engine3d.objects.Skin;

	/**
	 * Группа анимаций. Предназначена для объединения и синхронизации анимаций.
	 */
	public class AnimationGroup extends Animation {

		private var _numAnimations:int = 0;
		private var _animations:Vector.<Animation> = new Vector.<Animation>();

		/**
		 * Создает группу анимаций.
		 * 
		 * @param object анимируемый объект
		 * @param weight вес анимации
		 * @param speed скорость проигрывания анимации
		 */
		public function AnimationGroup(object:Object3D = null, weight:Number = 1.0, speed:Number = 1.0) {
			super(object, weight, speed);
		}

		/**
		 * @inheritDoc 
		 */
		override public function updateLength():void {
			super.updateLength();
			for (var i:int = 0; i < _numAnimations; i++) {
				var animation:Animation = _animations[i];
				animation.updateLength();
				var len:Number = animation.length;
				if (len > length) {
					length = len;
				}
			}
		}

		/**
		 * @inheritDoc 
		 */
		override public function prepareBlending():void {
			super.prepareBlending();
			for (var i:int = 0; i < _numAnimations; i++) {
				_animations[i].prepareBlending();
			}
		}

		/**
		 * @inheritDoc 
		 */
		override public function blend(position:Number, weight:Number):void {
			super.blend(position, weight);
			for (var i:int = 0; i < _numAnimations; i++) {
				var animation:Animation = _animations[i];
				if (animation.weight != 0) {
					animation.blend(position*animation.speed, weight*animation.weight); 
				}
			}
		}

		private function getObjectNumChildren(object:Object3D):int {
			if (object is Skin) {
				return Skin(object).numJoints;
			} else if (object is Joint) {
				return Joint(object).numJoints;
			} else if (object is Object3DContainer) {
				return Object3DContainer(object).numChildren;
			}
			return 0;
		}

		private function getObjectChildAt(object:Object3D, index:int):Object3D {
			if (object is Skin) {
				return Skin(object).getJointAt(index);
			} else if (object is Joint) {
				return Joint(object).getJointAt(index);
			} else if (object is Object3DContainer) {
				return Object3DContainer(object).getChildAt(index);
			}
			return null;
		}

		/**
		 * @inheritDoc 
		 */
		override public function clone():Animation {
			var cloned:AnimationGroup = new AnimationGroup(object, weight, speed);
			for (var i:int = 0; i < _numAnimations; i++) {
				cloned.addAnimation(_animations[i].clone());
			}
			cloned.length = length;
			return cloned;
		}

		/**
		 * Создает копию анимации, которая будет анимировать заданную иерархию.
		 * Переносятся и копируются только те анимации, которые анимирует объекты с аналогичными именами
		 * из заданной иерархии.
		 * 
		 * @param object объект, который должен анимироваться копией текущей анимации
		 * @return копия анимации
		 */
		override public function copyTo(object:Object3D):Animation {
			if (object == null) {
				throw new ArgumentError("Object must be not null");
			}
			var base:Object3D = this.object;
			if (base == null) {
				throw new ArgumentError("Base animation object must be not null");
			}
			var group:AnimationGroup = new AnimationGroup(object, weight, speed);
			copyAnimationForEachObject(object, group);
			if (group._numAnimations == 1 && group._animations[0].object == object) {
				// Если только одна анимация и та принадлежит объекту, то вернуть эту анимацию
				return group._animations[0];
			}
			return group;
		}

		private function copyAnimationForEachObject(object:Object3D, group:AnimationGroup):void {
			var i:int;
			var name:String = object.name;
			var from:Object3D;
			if (name != null && name.length > 0) {
				collectAnimations(name, this, group, object);
			}
			var count:int = getObjectNumChildren(object);
			for (i = 0; i < count; i++) {
				var child:Object3D = getObjectChildAt(object, i);
				copyAnimationForEachObject(child, group);
			}
		}

		private function collectAnimations(name:String, animations:AnimationGroup, collector:AnimationGroup, object:Object3D, from:Object3D = null):Object3D {
			for (var i:int = 0; i < animations._numAnimations; i++) {
				var animation:Animation = animations._animations[i];
				var group:AnimationGroup = animation as AnimationGroup;
				if (group != null) {
					from = collectAnimations(name, group, collector, object, from);
				} else {
					if (animation.object != null && animation.object.name == name && (from == null || animation.object == from)) {
						from = animation.object;
						collector.addAnimation(animation.copyTo(object));
					}
				}
			}
			return from;
		}

		/**
		 * @inheritDoc
		 */
		override public function slice(start:Number, end:Number = Number.MAX_VALUE):Animation {
			var group:AnimationGroup = new AnimationGroup(object, weight, speed);
			for (var i:int = 0; i < _numAnimations; i++) {
				var animation:Animation = _animations[i];
				group.addAnimation(animation.slice(start * animation.speed, end * animation.speed));
			}
			group.updateLength();
			return group;
		}

		/**
		 * Добавляет дочернюю анимацию и обновляет длину анимации после этого.
		 */
		public function addAnimation(animation:Animation):Animation {
			if (animation == null) {
				throw new Error("Animation cannot be null");
			}
			_animations[_numAnimations++] = animation;
			if (animation.length > length) {
				length = animation.length;
			}
			return animation;
		}

		/**
		 * Убирает дочернюю анимацию и обновляет длину анимации.
		 */
		public function removeAnimation(animation:Animation):Animation {
			var index:int = _animations.indexOf(animation);
			if (index < 0) throw new ArgumentError("Animation not found");
			_numAnimations--;
			var j:int = index + 1;
			while (index < _numAnimations) {
				_animations[index] = _animations[j];
				index++;
				j++;
			}
			_animations.length = _numAnimations;
			// Пересчитываем длину
			length = 0;
			for (var i:int = 0; i < _numAnimations; i++) {
				var anim:Animation = _animations[i];
				if (anim.length > length) {
					length = anim.length;
				}
			}
			return animation;
		}

		/**
		 * Количество дочерних анимаций. 
		 */
		public function get numAnimations():int {
			return _numAnimations;
		}

		/**
		 * Возвращает анимацию по индексу.
		 */
		public function getAnimationAt(index:int):Animation {
			return _animations[index];
		}

	}
}
