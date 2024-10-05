package com.alternativagame.engine3d.object.light {
	import com.alternativagame.engine3d.material.HelperMaterial;
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.engine3d.skin.OmniSkin;
	import com.alternativagame.type.RGB;
	import com.alternativagame.type.Vector;
	import com.alternativagame.engine3d.skin.Skin;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.engine3d.engine3d;
	
	use namespace engine3d;

	public class Omni3D extends Light3D {

		use namespace engine3d;

		// Расстояния влияния источника света
		private var _near:Number;
		private var _far:Number;

		// Квадраты расстояний влияния
		engine3d var nearSqr:Number;
		engine3d var farSqr:Number;
		
		// Предпросчитанная обратная разница расстояний влияния
		engine3d var farNearSqr:Number;
		
		// Параметры в системе камеры
		engine3d var canvasNear:Number;
		engine3d var canvasFar:Number;
		engine3d var canvasNearSqr:Number;
		engine3d var canvasFarSqr:Number;
		engine3d var canvasFarNearSqr:Number;
		
		// Часто изменяемый источник
		private var _mobile:Boolean = false;

		public function Omni3D(color:RGB = null, near:Number = 0, far:Number = 100, material:HelperMaterial = null) {
			super(color, material);
			_near = near;
			_far = far;
			calculateParams();
		}
		
		override protected function updateTransform():void {
			super.updateTransform();
			calculateCanvasParams();			 
		}
		
		override protected function createSkin():Skin {
			return new OmniSkin(this);
		}
		
		// Освещение в заданной точке (null, если нет)
		override engine3d function getLightColor(coords:Vector, normal:Vector):RGB {
			// Находим вектор до точки из источника
			var vector:Vector = new Vector(coords.x - transform.d, coords.y - transform.h, coords.z - transform.l);
			// Находим квадрат расстояния
			var length:Number = Math3D.vectorLengthSquare(vector);
			
			// Если за пределами влияния
			if (length > canvasFarSqr) {
				return null;
			} else {
				Math3D.normalize(vector);
				var res:RGB = calculateLightColor(normal, vector);
				// Если в промежутке near и far  
				if (res != null && length > canvasNearSqr) {
					res.multiply(canvasFarNearSqr*(canvasFarSqr - length));
				}
				return res; 
			}
		}
		
		// Обновление предпросчитанных параметров
		private function calculateParams():void {
			nearSqr = _near * _near;
			farSqr = _far * _far;
			farNearSqr = 1/(farSqr - nearSqr);
		}
		
		// Обновление предпросчитанных параметров с учётом масштаба камеры
		private function calculateCanvasParams():void {
			canvasNear = _near * view.zoom;
			canvasFar = _far * view.zoom;
			canvasNearSqr = canvasNear * canvasNear;
			canvasFarSqr = canvasFar * canvasFar;
			canvasFarNearSqr = 1/(canvasFarSqr - canvasNearSqr);
		}
		
		public function set near(value:Number):void {
			_near = value;
			calculateParams();
			updateSkin();
			applyToSolidObjects();
		}
		
		public function get near():Number {
			return _near;
		}

		public function set far(value:Number):void {
			_far = value;
			calculateParams();
			updateSkin();
			applyToSolidObjects();
		}

		public function get far():Number {
			return _far;
		}
		
		public function get mobile():Boolean {
			return _mobile;
		}
		
		public function set mobile(value:Boolean):void {
			if (_mobile != value) {
				_mobile = value;
				applyToSolidObjects();
			}			
		}
		
		// Клон
		override public function clone():Object3D {
			var res:Omni3D = new Omni3D();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(object:*):void {
			var obj:Omni3D = Omni3D(object);
			super.cloneParams(obj);
			obj.far = far;
			obj.near = near;
			obj.mobile = mobile;
		}
		
	}
}