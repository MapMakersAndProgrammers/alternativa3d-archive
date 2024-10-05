package com.alternativagame.engine3d.material {
	import com.alternativagame.engine3d.Math3D;
	import com.alternativagame.type.RGB;
	
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	public class SpriteMaterial extends ObjectMaterial {
		
		// Массив фаз
		private var states:Array = new Array();
		
		// Сглаженность
		public var smoothing:Boolean; 
		
		// Цвет самосвечения материала
		public var selfIllumination:RGB = new RGB();

		// Флаги искажения спрайта
		public var scale:Boolean;
		public var rotate:Boolean;
	
		public function SpriteMaterial(smoothing:Boolean = false, scale:Boolean = false, rotate:Boolean = false) {
			this.smoothing = smoothing;
			this.scale = scale;
			this.rotate = rotate;
		} 
		
		public function setPhase(bitmapData:BitmapData, pivot:Point = null, state:String = "default", pitch:Number = 0, yaw:Number = 0):void {
			
			// Добавляем состояние, если надо
			if (states[state] == undefined) {
				states[state] = new Array();
			}
			
			states[state].push(new SpritePhase(bitmapData, pivot, pitch, yaw));
		} 

		// Возвращает фазу
		public function getPhase(state:String = "default", pitch:Number = 0, yaw:Number = 0):SpritePhase {
			var res:SpritePhase = null;
			
			// Проверка на наличие состояние
			if (states[state] != undefined) {
				var phases:Array = states[state];
				var num:uint = phases.length;

				var i:uint;
				var phase:SpritePhase;
				var resPitch:Number;
				var currentDiff:Number;
				
				// Находим ближайший pitch
				var minDiff:Number = Number.MAX_VALUE;
				for (i = 0; i < num; i++) {
					phase = phases[i];
					currentDiff = Math.abs(phase.pitch - pitch);
					if (currentDiff < minDiff) {
						minDiff = currentDiff;
						resPitch = phase.pitch;
					}
				}
				
				// Находим ближайший yaw и сохраняем результат
				minDiff = Number.MAX_VALUE;
				for (i = 0; i < num; i++) {
					phase = phases[i];
					if (phase.pitch == resPitch) {
						currentDiff = Math.abs(Math3D.deltaAngle(phase.yaw, yaw)); 
						if (currentDiff < minDiff) {
							minDiff = currentDiff;
							res = phase;
						}
					}
				}
			}
			
			return res;
		}
		
		// Клон
		override public function clone():Material {
			var res:SpriteMaterial = new SpriteMaterial();
			cloneParams(res);
			return res;
		}
		
		// Клонировать параметры
		override protected function cloneParams(material:*):void {
			var mat:SpriteMaterial = SpriteMaterial(material);
			super.cloneParams(mat);
			mat.smoothing = smoothing;
			mat.selfIllumination = selfIllumination.clone();
			mat.scale = scale;
			mat.rotate = rotate;
			for (var state:String in states) {
				for (var i:uint = 0; i < states[state].length; i++) {
					var phase:SpritePhase = states[state][i];
					mat.setPhase(phase.bitmapData, phase.pivot.clone(), state, phase.pitch, phase.yaw);
				}
			}
		}
		
	}
}