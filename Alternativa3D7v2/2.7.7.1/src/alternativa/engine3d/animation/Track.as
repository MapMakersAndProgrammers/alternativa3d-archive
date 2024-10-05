package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.keys.Key;

	use namespace alternativa3d;

	/**
	 * Временная шкала с ключевыми кадрами.
	 */
	public class Track {

		/**
		 * Ключевые кадры.
		 */
		public var keyList:Key;

		/**
		 * Добавляет ключевой кадр.
		 */
		public function addKey(key:Key):void {
			key.next = keyList;
			keyList = key;
		}

		/**
		 * Сортирует ключевые кадры по времени. 
		 */
		public function sortKeys():void {
			keyList = sortKeysByTime(keyList);
		}

		/**
		 * Возвращает кадр соответствующий заданному времени.
		 *  
		 * @param time время кадра.
		 * @param key если не <code>null</code>, результат будет записан в этот объект.
		 */
		public function getKey(time:Number, key:Key = null):Key {
			var prev:Key;
			var next:Key = keyList;
			while (next != null && next.time < time) {
				prev = next;
				next = next.next;
			}
			if (prev != null) return prev.interpolate(time, next, key);
			if (next != null) return next.interpolate(time, null, key);
			return null;
		}

		private function sortKeysByTime(list:Key):Key {
			var left:Key = list;
			var right:Key = list.next;
			while (right != null && right.next != null) {
				list = list.next;
				right = right.next.next;
			}
			right = list.next;
			list.next = null;
			if (left.next != null) {
				left = sortKeysByTime(left);
			}
			if (right.next != null) {
				right = sortKeysByTime(right);
			}
			var flag:Boolean = left.time < right.time;
			if (flag) {
				list = left;
				left = left.next;
			} else {
				list = right;
				right = right.next;
			}
			var last:Key = list;
			while (true) {
				if (left == null) {
					last.next = right;
					return list;
				} else if (right == null) {
					last.next = left;
					return list;
				}
				if (flag) {
					if (left.time < right.time) {
						last = left;
						left = left.next;
					} else {
						last.next = right;
						last = right;
						right = right.next;
						flag = false;
					}
				} else {
					if (right.time < left.time) {
						last = right;
						right = right.next;
					} else {
						last.next = left;
						last = left;
						left = left.next;
						flag = true;
					}
				}
			}
			return null;
		}

		/**
		 * Возвращает время последнего ключевого кадра.
		 */
		public function get length():Number {
			if (keyList != null) {
				var key:Key = keyList;
				while (key.next != null) {
					key = key.next;
				}
				return key.time;
			} else {
				return 0;
			}
		}

		/**
		 * Возвращает часть трека в промежутке между start и end.
		 * Ключи в треке должны быть отсортированы.
		 *
		 * @param start начало времени промежутка трека
		 * @param end конец времени промежутка трека
		 * @return часть трека
		 */
		public function slice(start:Number, end:Number = Number.MAX_VALUE):Track {
			var track:Track = new Track();
			var prev:Key;
			var next:Key = keyList;
			while (next != null && next.time <= start) {
				prev = next;
				next = next.next;
			}
			var key:Key;
			if (prev != null) {
				key = prev.interpolate(start, next);
			} else {
				if (next != null) {
					// Время до начала анимации
					key = next.interpolate(next.time, next.next);
					start = next.time;
				} else {
					// Пустой трек
					return track;
				}
			}
			key.time -= start;
			track.keyList = key;
			prev = next;
			next = next.next;
			while (next != null && next.time < end) {
				key.next = next.interpolate(next.time, next.next);
				key = key.next;
				key.time -= start;
				prev = next;
				next = next.next;
			}
			if (next != null) {
				// Время между prev.time и next.time
				key.next = prev.interpolate(end, next);
				key.next.time -= start;
			} else {
				// Последний ключ
				key.next = prev.interpolate(prev.time, null);
				key.next.time -= start;
			}
			return track;
		}

	}
}
