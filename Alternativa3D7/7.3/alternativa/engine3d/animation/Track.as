package alternativa.engine3d.animation {
	import alternativa.engine3d.alternativa3d;
	
	use namespace alternativa3d;
	
	public class Track {
	
		public var keyList:Key;
	
		public function addKey(key:Key):void {
			key.next = keyList;
			keyList = key;
		}
	
		public function sortKeys():void {
			keyList = sortKeysByTime(keyList);
		}
	
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
	
	}
}
