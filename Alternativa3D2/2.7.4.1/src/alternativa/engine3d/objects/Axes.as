package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Canvas;
	import alternativa.engine3d.core.Object3D;
	
	use namespace alternativa3d;
	
	/**
	 * Вспомогательный объект, иллюстрирующий систему координат
	 */
	public class Axes extends Object3D {
	
		public var axisLength:Number;
		public var lineThickness:Number;
		public var dotRadius:Number;
		public var textSize:Number;
	
		public function Axes(axisLength:Number = 30, lineThickness:Number = 0, dotRadius:Number = 2, textSize:Number = 10):void {
			this.axisLength = axisLength;
			this.lineThickness = lineThickness;
			this.dotRadius = dotRadius;
			this.textSize = textSize;
			boundMinX = -dotRadius;
			boundMinY = -dotRadius;
			boundMinZ = -dotRadius;
			boundMaxX = dotRadius;
			boundMaxY = dotRadius;
			boundMaxZ = dotRadius;
		}
	
		/**
		 * @private
		 */
		override alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
			/*
			 var p:Vector.<Number> = Vector.<Number>([0, 0, 0, axisLength, 0, 0, 0, axisLength, 0, 0, 0, axisLength]);
			 var d:Vector.<Number> = new Vector.<Number>(8);
			 object.transformation.transformVectors(p, p);
	
			 // Центр за камерой
			 if (p[2] < camera.nearClipping) return;
	
			 Utils3D.projectVectors(camera.projectionMatrix, p, d, new Vector.<Number>());
			 var size:Number = camera.viewSize/p[2];
	
			 // Подготовка канваса
			 var canvas:Canvas = parentCanvas.getChildCanvas(true, false, object.alpha, object.blendMode, object.colorTransform, object.filters);
	
			 var gfx:Graphics = canvas.gfx;
			 var text:TextField;
	
			 // Ось X
			 if (p[5] >= camera.nearClipping) {
			 gfx.lineStyle(lineThickness*size, 0xFF0000);
			 gfx.moveTo(d[0], d[1]);
			 gfx.lineTo(d[2], d[3]);
	
			 text = new TextField();
			 text.autoSize = TextFieldAutoSize.LEFT;
			 text.selectable = false;
			 text.x = d[2];
			 text.y = d[3];
			 text.text = "X";
			 text.setTextFormat(new TextFormat("Tahoma", textSize*size, 0xFF0000));
	
			 canvas.addChild(text);
			 canvas._numChildren++;
			 }
	
			 // Ось Y
			 if (p[8] >= camera.nearClipping) {
			 gfx.lineStyle(lineThickness*size, 0x00FF00);
			 gfx.moveTo(d[0], d[1]);
			 gfx.lineTo(d[4], d[5]);
	
			 text = new TextField();
			 text.autoSize = TextFieldAutoSize.LEFT;
			 text.selectable = false;
			 text.x = d[4];
			 text.y = d[5];
			 text.text = "Y";
			 text.setTextFormat(new TextFormat("Tahoma", textSize*size, 0x00FF00));
	
			 canvas.addChild(text);
			 canvas._numChildren++;
			 }
	
			 // Ось Z
			 if (p[11] >= camera.nearClipping) {
			 gfx.lineStyle(lineThickness*size, 0x0000FF);
			 gfx.moveTo(d[0], d[1]);
			 gfx.lineTo(d[6], d[7]);
	
			 text = new TextField();
			 text.autoSize = TextFieldAutoSize.LEFT;
			 text.selectable = false;
			 text.x = d[6];
			 text.y = d[7];
			 text.text = "Z";
			 text.setTextFormat(new TextFormat("Tahoma", textSize*size, 0x0000FF));
	
			 canvas.addChild(text);
			 canvas._numChildren++;
			 }
	
			 // Начало координат
			 gfx.lineStyle();
			 gfx.beginFill(0xFFFFFF);
			 gfx.drawCircle(d[0], d[1], dotRadius*size);
			 */
			//debugDrawBoundRaduis(camera, object, canvas);
		}
	
	}
}
