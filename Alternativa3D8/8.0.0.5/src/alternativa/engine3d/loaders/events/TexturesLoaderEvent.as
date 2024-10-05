package alternativa.engine3d.loaders.events {
	
	import __AS3__.vec.Vector;
	
	import flash.display.BitmapData;
	import flash.display3D.Texture3D;
	import flash.events.Event;

	public class TexturesLoaderEvent extends Event {
		private var bitmapDatas:Vector.<BitmapData>;
		private var textures3D:Vector.<Texture3D>;
		
		public function TexturesLoaderEvent(type:String, bitmapDatas:Vector.<BitmapData>, textures3D:Vector.<Texture3D> = null) {
			this.bitmapDatas = bitmapDatas;
			this.textures3D = textures3D;
			super(type, false, false);
		}
		
		public function getBitmapDatas():Vector.<BitmapData> {
			return bitmapDatas;
		}
		
		public function getTextures3D():Vector.<Texture3D> {
			return textures3D;
		}
		
	}
}