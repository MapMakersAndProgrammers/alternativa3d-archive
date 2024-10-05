package alternativa.engine3d.loaders {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.loaders.events.TexturesLoaderEvent;
	
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Texture3D;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	
	public class TexturesLoader extends EventDispatcher{
		
		private var textures3D:Object = new Object();
		private var bitmapDatas:Object = new Object();
		
		private var currentBitmapDatas:Vector.<BitmapData>;
		private var currentTextures3D:Vector.<Texture3D>;
		private var currentUrl:String;

		private var loader:Loader;
		private var urlList:Vector.<String>;
		private var counter:int = 0;
		private var context3D:Context3D;
		
		public function TexturesLoader() {
		}
		
		public function loadTexture(url:String, context3D:Context3D = null):void {
			urlList = Vector.<String>([url]);
			this.context3D = context3D;
			currentBitmapDatas = new Vector.<BitmapData>(1);
			currentTextures3D = new Vector.<Texture3D>(1);
			loadNext();	
		}
		
		public function loadTextures(urls:Vector.<String>, context3D:Context3D = null):void {
			urlList = urls;
			this.context3D = context3D;
			currentBitmapDatas = new Vector.<BitmapData>(urlList.length);
			currentTextures3D = new Vector.<Texture3D>(urlList.length);
			loadNext();
		}
		
		public function getTexture3D(url:String):Texture3D {
			return textures3D[url];
		}
		
		private function loadNext(e:Event = null):void {
			var bitmapData:BitmapData;
			var texture3D:Texture3D;
			if (e != null && !(e is ErrorEvent)) {
				bitmapData = e.target.content.bitmapData;
				bitmapDatas[currentUrl] = bitmapData;
				currentBitmapDatas[counter - 1] = bitmapData;
				if (context3D) {
					texture3D = createTexture(bitmapData);
					currentTextures3D[counter - 1] = texture3D;
				}
			} else if (e is ErrorEvent) {
				trace("Missing: " + currentUrl);
			}

			if (counter < urlList.length) {
				currentUrl = urlList[counter++];
				bitmapData = bitmapDatas[currentUrl];
				if (bitmapData) {
					currentBitmapDatas[counter - 1] = bitmapData;
					if (context3D) {
						texture3D = textures3D[currentUrl];
						if (texture3D) {
							currentTextures3D[counter - 1] = texture3D;
						} else {
							texture3D = createTexture(bitmapData);
							currentTextures3D.push(texture3D);
						}
					}
					loadNext();
				} else {
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadNext);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.DISK_ERROR, loadNext);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadNext);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, loadNext);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, loadNext);
					loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadNext);
					loader.load(new URLRequest(currentUrl));
				}
				
			} else {
				onTexturesLoad();
			}
		}
		
		private function onTexturesLoad():void {
			counter = 0;
			dispatchEvent(new TexturesLoaderEvent(Event.COMPLETE, currentBitmapDatas, currentTextures3D));
		}
		
		public function clean():void {
			textures3D = new Object();
			bitmapDatas = new Object();
			currentBitmapDatas = null;
			currentTextures3D = null;
		}
		
		private function createTexture(value:BitmapData):Texture3D {
			if (value == null) return null;
			var texture:Texture3D = context3D.createTexture(value.width, value.height, Context3DTextureFormat.BGRA, false);
			uploadMipMaps(texture, value.clone());
			textures3D[currentUrl] = texture;
			return texture;
		}
		
		protected function uploadMipMaps(texture:Texture3D, bmp:BitmapData):void {
			var level:int = 0;
			texture.upload(bmp, level++);
			
			if (bmp.width % 2 > 0 || bmp.height % 2 > 0) return;
			
			var filter:ConvolutionFilter = new ConvolutionFilter(2, 2, [1, 1, 1, 1], 4, 0, false, true);
			filter.preserveAlpha = false;
			var m:Matrix = new Matrix(0.5, 0, 0, 0.5);
			var rect:Rectangle = new Rectangle();
			var point:Point = new Point();
			var current:BitmapData = bmp;
			rect.width = bmp.width;
			rect.height = bmp.height;
			do {
				bmp.applyFilter(current, rect, point, filter);
				if (rect.width > 1) {
					rect.width >>= 1;
				}
				if (rect.height > 1) {
				rect.height >>= 1;
				}
				current = new BitmapData(rect.width, rect.height, false, 0);
				current.draw(bmp, m, null, null, null, false);
				texture.upload(current, level++);
			} while (rect.width != 1 || rect.height != 1); 
			
//			current.fillRect(rect, 0xffc000);
//			trace("S");
//				rect.width >>= 1;
//				rect.height >>= 1;
//				texture.upload(current, level++);
//			}
			
			
			bmp.dispose();
			current.dispose();
			
		}

	}
}