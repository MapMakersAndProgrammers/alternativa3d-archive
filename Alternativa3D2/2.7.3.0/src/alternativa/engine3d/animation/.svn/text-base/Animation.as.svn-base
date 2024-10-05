package alternativa.engine3d.animation {
	import flash.utils.getTimer;

	public class Animation {
	
		public var speed:Number = 1;
	
		protected var _position:Number = 0;
		private var _playing:Boolean = false;
		private var time:int;
	
		/**
		 * ������ ������� ������������ ��������
		 */
		public function play():void {
			time = getTimer();
			_playing = true;
		}
	
		/**
		 * ��������� ������� ��������
		 */
		public function stop():void {
			_playing = false;
		}
	
		/**
		 * ���������� �������� ����������� ������ � ������������ � �������� � ������� ��������
		 */
		public function update():void {
			if (_playing) {
				var t:int = getTimer();
				position += (t - time)*0.001*speed;
				time = t;
				control();
			}
		}
	
		public function get position():Number {
			return _position;
		}
	
		public function set position(value:Number):void {
			_position = value;
			control();
		}

		protected function control():void {
		}
	
		/**
		 * ��������� ��������
		 * @return ������������� ��� ���
		 */
		public function get playing():Boolean {
			return _playing;
		}
		
		/**
		 * Возвращает длину анимации 
		 */
		public function get length():Number {
			return 0;
		}
		
	}
}
