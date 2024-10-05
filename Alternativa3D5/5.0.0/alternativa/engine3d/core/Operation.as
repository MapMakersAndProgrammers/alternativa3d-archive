package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.types.Set;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class Operation {
		
		alternativa3d static const OBJECT_CALCULATE_TRANSFORMATION:uint = 1;
		alternativa3d static const OBJECT_CALCULATE_MOBILITY:uint = 2;
		alternativa3d static const VERTEX_CALCULATE_COORDS:uint = 3;
		alternativa3d static const FACE_CALCULATE_NORMAL:uint = 4;
		alternativa3d static const FACE_CALCULATE_UV:uint = 5;
		alternativa3d static const FACE_UPDATE_PRIMITIVE:uint = 6;
		alternativa3d static const SCENE_CALCULATE_BSP:uint = 7;
		alternativa3d static const FACE_UPDATE_MATERIAL:uint = 8;
		alternativa3d static const FACE_CALCULATE_FRAGMENTS_UV:uint = 9;
		alternativa3d static const CAMERA_CALCULATE_MATRIX:uint = 10;
		alternativa3d static const CAMERA_CALCULATE_PLANES:uint = 11;
		alternativa3d static const CAMERA_RENDER:uint = 12;
		alternativa3d static const SCENE_CLEAR_PRIMITIVES:uint = 13;
		
		// Объект
		alternativa3d var object:Object;
		
		// Метод
		alternativa3d var method:Function;
		
		// Название метода
		alternativa3d var name:String;

		// Последствия
		private var sequel:Operation; 
		private var sequels:Set;
		
		// Приоритет операции
		public var priority:uint;
		
		// Уровень объекта (необязательный)
		public var level:uint = 0;
		
		// Находится ли операция в очереди
		alternativa3d var queued:Boolean = false;
		
		public function Operation(name:String, object:Object = null, method:Function = null, priority:uint = 0, level:uint = 0) {
			this.object = object;
			this.method = method;
			this.name = name;
			this.priority = priority;
			this.level = level;
		}
		
		// Добавить последствие
		alternativa3d function addSequel(operation:Operation):void {
			if (sequel == null) {
				if (sequels == null) {
					sequel = operation;
				} else {
					sequels[operation] = true;
				}
			} else {
				if (sequel != operation) {
					sequels = new Set(true);
					sequels[sequel] = true;
					sequels[operation] = true;
					sequel = null;
				}
			}
		}

		// Удалить последствие
		alternativa3d function removeSequel(operation:Operation):void {
			if (sequel == null) {
				if (sequels != null) {
					delete sequels[operation];
					var key:*;
					var single:Boolean = false;
					for (key in sequels) {
						if (single) {
							single = false;
							break;
						}
						single = true;
					}
					if (single) {
						sequel = key;
						sequels = null;
					}
				}
			} else {
				if (sequel == operation) {
					sequel = null;
				}
			}
		}
		
		alternativa3d function collectSequels(collector:Array):void {
			if (sequel == null) {
				// Проверяем последствия
				for (var key:* in sequels) {
					var operation:Operation = key;
					// Если операция ещё не в очереди
					if (!operation.queued) {
						// Добавляем её в очередь
						collector.push(operation);
						// Устанавливаем флаг очереди
						operation.queued = true;
						// Вызываем добавление в очередь её последствий
						operation.collectSequels(collector);
					}
				}
			} else {
				if (!sequel.queued) {
					collector.push(sequel);
					sequel.queued = true;
					sequel.collectSequels(collector);
				}
			}
		}
		
		
		public function toString():String {
			return "[Operation " + priority + "/" + level + " " + object + "." + name + "]";
		}
		
	}
}