package alternativa.engine3d.animation {

	import __AS3__.vec.Vector;
	
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
		 * @private
		 * Возвращает путь к объекту относительно некоторого родительского объекта.
		 *
		 * @param target объект для поиска, должен иметь имя
		 * @param base родительский объект. Может быть экземпляром классов Skin, Joint.
		 *
		 * @return путь до объекта в виде вектора имен проиндексированого в порядке увеличения  
		 */
		private function getPathByTarget(target:Object3D, base:Object3D):Vector.<String> {
			var i:int, count:int;
			for (i = 0, count = getObjectNumChildren(base); i < count; i++) {
				var child:Object3D = getObjectChildAt(base, i);
				if (child == target) {
					return Vector.<String>([target.name]);
				} else {
					var founded:Vector.<String> = getPathByTarget(target, child);
					if (founded != null) {
						if (child.name != null && child.name.length > 0) {
							founded.push(child.name);
						}
						return founded;
					}
				}
			}
			return null;
		}

		private function getTargetByPath(path:Vector.<String>, base:Object3D):Object3D {
			var i:int, count:int;
			var name:String = path[path.length - 1];
			for (i = 0, count = getObjectNumChildren(base); i < count; i++) {
				var child:Object3D = getObjectChildAt(base, i);
				if (child.name == null || child.name.length == 0) {
					// Ищем внутри
					var founded:Object3D = getTargetByPath(path, child);
					if (founded != null) {
						return founded;
					}
				} else {
					if (child.name == name) {
						if (path.length == 1) {
							// Нашли объект
							return child;
						}
						path.pop();
						// Ищем внутри
						return getTargetByPath(path, child);
					}
				}
			}
			return null;
		}

		private function formatPath(path:Vector.<String>):String {
			path.reverse();
			return path.join("/");
		}

		/**
		 * Переносит анимацию с одной иерархии на другую с такой же структурой.
		 * Соответствие объектов определяется по их именам. Объекты без имен пропускаются при поиске соответствия.
		 * 
		 * @param object экземпляр любого из классов Object3DContainer, Skin, Joint на который производится перенос анимации.
		 * 
		 * @throw ArgumentError переменная object не может быть равна <code>null</code>
		 * @throw ArgumentError анимация не ссылается ни на один объект
		 * @throw Error аналогичный объект не найден в другой иерархии
		 * @throw Error один из объектов в дочерней анимации не является потомком объекта анимации
		 * @throw Error один из объектов в дочерней анимации не имеет имени
		 */
		override public function reassign(object:Object3D):void {
			if (object == null) {
				throw new ArgumentError("Object must be not null");
			}
			var base:Object3D = this.object;
			if (base == null) {
				throw new ArgumentError("Base animation object must be not null");
			}
			var i:int;
			var animation:Animation;
			for (i = 0; i < _numAnimations; i++) {
				animation = _animations[i];
				if (animation.object == base) {
					// Если дочерняя анимация ссылается на объект родительской анимации, просто переназначаем на новый объект
					animation.reassign(object);
				} else {
					var child:Object3D = animation.object;
					if (child != null && child.name != null && child.name.length > 0) {
						// Собираем путь до объекта
						var path:Vector.<String> = getPathByTarget(child, base);
						if (path != null) {
							var target:Object3D = getTargetByPath(path, object);
							if (target != null) {
								animation.reassign(target);
							} else {
								throw new Error('Similiar object of animation at index ' + i + ' not found in target by path:"' + formatPath(path) + '"');
							}
						} else {
							throw new Error("Object of animation at index " + i + " is not child of object from base animation");
						}
					} else {
						if (child != null) {
							throw new Error("Object of animation at index " + i + " dont have name");
						}
					}
				}
			}
			super.reassign(object);
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
		 * Добавляет дочернюю анимацию и обновляет длину анимации.
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
