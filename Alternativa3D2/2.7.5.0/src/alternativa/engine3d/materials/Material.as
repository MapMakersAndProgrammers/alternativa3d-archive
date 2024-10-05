package alternativa.engine3d.materials {
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Face;
	
	use namespace alternativa3d;
	
	/**
	 * Базовый класс материалов.
	 * Материал назначается граням полигональных объектов или спрайтам.
	 * @see alternativa.engine3d.core.Face
	 * @see alternativa.engine3d.objects.Sprite3D
	 */
	public class Material {
	
		/**
		 * Имя материала.
		 */
		public var name:String;
	
		/**
		 * @private 
		 */
		alternativa3d function draw(camera:Camera3D, canvas:Canvas, list:Face, distance:Number):void {
			clearLinks(list);
		}
	
		/**
		 * @private 
		 */
		alternativa3d function drawViewAligned(camera:Camera3D, canvas:Canvas, list:Face, distance:Number, a:Number, b:Number, c:Number, d:Number, tx:Number, ty:Number):void {
			clearLinks(list);
		}
	
		/**
		 * @private 
		 */
		alternativa3d function clearLinks(list:Face):void {
			while (list != null) {
				var next:Face = list.processNext;
				list.processNext = null;
				list = next;
			}
		}
	
	}
}
