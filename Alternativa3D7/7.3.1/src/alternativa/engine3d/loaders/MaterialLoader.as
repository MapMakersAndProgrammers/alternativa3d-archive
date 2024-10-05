package alternativa.engine3d.loaders {
	import alternativa.engine3d.loaders.events.LoaderErrorEvent;
	import alternativa.engine3d.loaders.events.LoaderEvent;
	import alternativa.engine3d.loaders.events.LoaderProgressEvent;
	import alternativa.engine3d.materials.TextureMaterial;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.Loader;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	/**
	 * Рассылается вначале загрузки очередного материала.
	 *
	 * @eventType alternativa.engine3d.loaders.events.LoaderEvent.PART_OPEN
	 */
	[Event (name="partOpen", type="alternativa.engine3d.loaders.events.LoaderEvent")]
	/**
	 * Рассылается после окончания этапа очередного материала.
	 * В событии в свойстве target содержится загруженный материал.
	 *
	 * @eventType alternativa.engine3d.loaders.events.LoaderEvent.PART_COMPLETE
	 */
	[Event (name="partComplete", type="alternativa.engine3d.loaders.events.LoaderEvent")]
	/**
	 * Рассылается после окончания загрузки всех материалов.
	 *
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event (name="complete", type="flash.events.Event")]
	/**
	 * Рассылается, если в процессе загрузки возникает ошибка.
	 *
	 * @eventType alternativa.engine3d.loaders.events.LoaderErrorEvent.LOADER_ERROR
	 */
	[Event (name="loaderError", type="alternativa.engine3d.loaders.events.LoaderErrorEvent")]
	
	/**
	 * Загрузчик текстур материалов
	 */
	public class MaterialLoader extends EventDispatcher {
	
		static private var stub:BitmapData;
	
		private var loader:Loader;
		private var context:LoaderContext;
	
		private var materials:Vector.<TextureMaterial>;
		private var urls:Vector.<String>;
		private var filesTotal:int;
		private var filesLoaded:int;
	
		private var diffuse:BitmapData;
		private var currentURL:String;
		private var index:int;
	
		/**
		 * Начинает загрузку текстур материалов
		 *
		 * @param materials список материалов для загрузки их текстур
		 * @param context
		 */
		public function load(materials:Vector.<TextureMaterial>, context:LoaderContext = null):void {
			this.context = context;
			this.materials = materials;
			urls = new Vector.<String>();
			for (var i:int = 0, j:int = 0; i < materials.length; i++) {
				var material:TextureMaterial = materials[i];
				urls[j++] = material.diffuseMapURL;
				filesTotal++;
				if (material.opacityMapURL != null) {
					urls[j++] = material.opacityMapURL;
					filesTotal++;
				} else {
					urls[j++] = null;
				}
			}
			filesLoaded = 0;
			index = -1;
			loadNext(null);
		}
	
		/**
		 * Останавливает загрузку и выполняет зачистку загрузчика.
		 */
		public function close():void {
			destroyLoader();
			materials = null;
			urls = null;
			diffuse = null;
			currentURL = null;
			context = null;
		}
	
		private function destroyLoader():void {
			if (loader != null) {
				loader.unload();
				loader.contentLoaderInfo.removeEventListener(Event.OPEN, onPartOpen);
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadNext);
				loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onFileProgress);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.DISK_ERROR, loadNext);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loadNext);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.NETWORK_ERROR, loadNext);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.VERIFY_ERROR, loadNext);
				loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loadNext);
				loader = null;
			}
		}
	
		private function loadNext(e:Event):void {
			if (index >= 0) {
				if (index % 2 == 0) {
					// Завершение загрузки диффузии
					if (e is ErrorEvent) {
						diffuse = getStub();
						onFileError((e as ErrorEvent).text);
					} else {
						diffuse = (loader.content as Bitmap).bitmapData;
					}
					filesLoaded++;
				} else {
					// Завершение загрузки альфы
					var material:TextureMaterial = materials[(index - 1) >> 1];
					if (e == null) {
						material.texture = diffuse;
					} else {
						if (e is ErrorEvent) {
							material.texture = diffuse;
							onFileError((e as ErrorEvent).text);
						} else {
							material.texture = merge(diffuse, (loader.content as Bitmap).bitmapData);
						}
						filesLoaded++;
					}
					onPartComplete((index - 1) >> 1, material);
					diffuse = null;
				}
				destroyLoader();
			}
			if (++index >= urls.length) {
				// Завершение всей загрузки
				close();
				if (hasEventListener(Event.COMPLETE)) {
					dispatchEvent(new Event(Event.COMPLETE));
				}
			} else {
				// Загрузка следующего файла
				currentURL = urls[index];
				if (currentURL != null && (diffuse == null || diffuse != stub)) {
					loader = new Loader();
					if (index % 2 == 0) {
						loader.contentLoaderInfo.addEventListener(Event.OPEN, onPartOpen);
					}
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadNext);
					loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onFileProgress);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.DISK_ERROR, loadNext);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadNext);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, loadNext);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, loadNext);
					loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadNext);
					loader.load(new URLRequest(currentURL), context);
				} else {
					loadNext(null);
				}
			}
		}
	
		private function onPartOpen(e:Event):void {
			if (hasEventListener(LoaderEvent.PART_OPEN)) {
				dispatchEvent(new LoaderEvent(LoaderEvent.PART_OPEN, urls.length >> 1, index >> 1, materials[index >> 1]));
			}
		}
	
		private function onPartComplete(partsLoaded:int, material:TextureMaterial):void {
			if (hasEventListener(LoaderEvent.PART_COMPLETE)) {
				dispatchEvent(new LoaderEvent(LoaderEvent.PART_COMPLETE, urls.length >> 1, partsLoaded, material));
			}
		}
	
		private function onFileProgress(e:ProgressEvent):void {
			if (hasEventListener(LoaderProgressEvent.LOADER_PROGRESS)) {
				dispatchEvent(new LoaderProgressEvent(LoaderProgressEvent.LOADER_PROGRESS, filesTotal, filesLoaded, (filesLoaded + e.bytesLoaded/e.bytesTotal)/filesTotal, e.bytesLoaded, e.bytesTotal));
			}
		}
	
		private function onFileError(text:String):void {
			if (hasEventListener(LoaderErrorEvent.LOADER_ERROR)) {
				dispatchEvent(new LoaderErrorEvent(LoaderErrorEvent.LOADER_ERROR, currentURL, text));
			}
		}
	
		private function merge(diffuse:BitmapData, alpha:BitmapData):BitmapData {
			var res:BitmapData = new BitmapData(diffuse.width, diffuse.height);
			res.copyPixels(diffuse, diffuse.rect, new Point());
			if (diffuse.width != alpha.width || diffuse.height != alpha.height) {
				diffuse.draw(alpha, new Matrix(diffuse.width/alpha.width, 0, 0, diffuse.height/alpha.height), null, BlendMode.NORMAL, null, true);
				alpha.dispose();
				alpha = diffuse;
			} else {
				diffuse.dispose();
			}
			res.copyChannel(alpha, alpha.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
			alpha.dispose();
			return res;
		}
	
		private function getStub():BitmapData {
			if (stub == null) {
				var size:uint = 20;
				stub = new BitmapData(size, size, false, 0);
				for (var i:uint = 0; i < size; i++) {
					for (var j:uint = 0; j < size; j += 2) {
						stub.setPixel((i % 2) ? j : (j + 1), i, 0xFF00FF);
					}
				}
			}
			return stub;
		}
	
	}
}
