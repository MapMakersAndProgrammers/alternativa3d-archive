package alternativa.engine3d.loaders {
	import alternativa.engine3d.loaders.events.LoaderEvent;
	import alternativa.engine3d.loaders.events.LoaderProgressEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;

	/**
	 * Событие посылается, когда начинается загрузка ресурса.
	 * 
	 * @eventType flash.events.Event.OPEN
	 */
	[Event (name="open", type="flash.events.Event")]
	/**
	 * Событие посылается, когда загрузка ресурса успешно завершена.
	 * 
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event (name="complete", type="flash.events.Event")]
	/**
	 * Событие посылается при возникновении ошибки загрузки.
	 * 
	 * @eventType flash.events.IOErrorEvent.IO_ERROR
	 */
	[Event (name="ioError", type="flash.events.IOErrorEvent")]
	/**
	 * Событие посылается, когда начинается загрузка очередной части ресурса.
	 * 
	 * @eventType alternativa.engine3d.loaders.events.LoaderEvent.PART_OPEN
	 */
	[Event (name="partOpen", type="alternativa.engine3d.loaders.events.LoaderEvent")]
	/**
	 * Событие посылается, когда загрузка очередной части ресурса успешно завершена.
	 * 
	 * @eventType alternativa.engine3d.loaders.events.LoaderEvent.PART_COMPLETE
	 */
	[Event (name="partComplete", type="alternativa.engine3d.loaders.events.LoaderEvent")]
	/**
	 * Событие посылается для отображения прогресса загрузки.
	 * 
	 * @eventType alternativa.engine3d.loaders.events.LoaderProgressEvent.LOADER_PROGRESS
	 */
	[Event (name="loaderProgress", type="alternativa.engine3d.loaders.events.LoaderProgressEvent")]

	/**
	 * Загрузчик текстуры, состоящей из одного или двух файлов. В случае, если указан второй файл, он используется для заполнения альфа-канала
	 * получаемой текстуры.
	 */
	public class TextureLoader extends EventDispatcher {
		
		private static const IDLE:int = -1;
		private static const LOADING_DIFFUSE_MAP:int = 0;
		private static const LOADING_ALPHA_MAP:int = 1;
		
		private var state:int = IDLE;
		private var bitmapLoader:Loader;
		private var loaderContext:LoaderContext;
		private var alphaTextureUrl:String;
		private var _bitmapData:BitmapData;
		
		/**
		 * Создаёт новый экземпляр. Если указан URL диффузной части текстуры, то сразу начинается загрузка.
		 * 
		 * @param diffuseTextureUrl URL диффузной части текстуры
		 * @param alphaTextureUrl URL карты прозрачности
		 * @param loaderContext LoaderContext, используемый при загрузке
		 */
		public function TextureLoader(diffuseTextureUrl:String = null, alphaTextureUrl:String = null, loaderContext:LoaderContext = null) {
			if (diffuseTextureUrl != null) {
				load(diffuseTextureUrl, alphaTextureUrl, loaderContext);
			}
		}
		
		/**
		 * Загруженная текстура.
		 */
		public function get bitmapData():BitmapData {
			return _bitmapData;
		}
		
		/**
		 * Загрузка текстурных карт. При успешной загрузке посылается сообщение <code>Event.COMPLETE</code>.
		 * 
		 * @param diffuseTextureUrl URL файла диффузной карты
		 * @param alphaTextureUrl URL файла карты прозрачности 
		 * @param loaderContext LoaderContext, используемый при загрузке
		 */		
		public function load(diffuseTextureUrl:String, alphaTextureUrl:String = null, loaderContext:LoaderContext = null):void {
			this.alphaTextureUrl = alphaTextureUrl == "" ? null : alphaTextureUrl;
			this.loaderContext = loaderContext;
			if (bitmapLoader == null) {
				bitmapLoader = new Loader();
			} else {
				close();
			}
			
			var loaderInfo:LoaderInfo = bitmapLoader.contentLoaderInfo;
			loaderInfo.addEventListener(Event.OPEN, onPartLoadingOpen);
			loaderInfo.addEventListener(ProgressEvent.PROGRESS, onPartLoadingProgress);
			loaderInfo.addEventListener(Event.COMPLETE, onPartLoadingComplete);
			loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			
			loadPart(LOADING_DIFFUSE_MAP, diffuseTextureUrl);
		}

		/**
		 * Прекращвет текущую загрузку. Если нет активных загрузок, не происходит ничего.
		 */
		public function close():void {
			if (state != IDLE) {
				_bitmapData = null;
				alphaTextureUrl = null;
				loaderContext = null;
				state = IDLE;
				bitmapLoader.close();
				removeListeners();
			}
		}

		/**
		 * Очищает внутренние ссылки на загруженные объекты, чтобы сборщик мусора смог их удалить.
		 */
		public function unload():void {
			if (state == IDLE && bitmapLoader != null) {
				bitmapLoader.unload();
				loaderContext = null;
				_bitmapData = null;
			}
		}
		
		/**
		 * Очищает временные внутренние ссылки.
		 */
		private function cleanup():void {
			removeListeners();
			alphaTextureUrl = null;
			loaderContext = null;
		}

		/**
		 * Запускает загрузку части текстуры.
		 * 
		 * @param state фаза загрузки
		 * @param url URL загружаемого файла
		 */		
		private function loadPart(state:int, url:String):void {
			this.state = state;
			bitmapLoader.load(new URLRequest(url), loaderContext);
		}
		
		/**
		 * Обрабатывает начало загрузки очередной части текстуры.
		 */
		private function onPartLoadingOpen(e:Event):void {
			if (_bitmapData == null && hasEventListener(Event.OPEN)) {
				dispatchEvent(new Event(Event.OPEN));
			}
			if (hasEventListener(LoaderEvent.PART_OPEN)) {
				dispatchEvent(new LoaderEvent(LoaderEvent.PART_OPEN, 2, state == LOADING_DIFFUSE_MAP ? 0 : 1));
			}
		}
		
		/**
		 * 
		 */
		private function onPartLoadingProgress(e:ProgressEvent):void {
			if (hasEventListener(LoaderProgressEvent.LOADER_PROGRESS)) {
				var partNumber:int = state == LOADING_DIFFUSE_MAP ? 0 : 1;
				var totalProgress:Number = 0.5*(partNumber + e.bytesLoaded/e.bytesTotal);
				dispatchEvent(new LoaderProgressEvent(LoaderProgressEvent.LOADER_PROGRESS, 2, partNumber, totalProgress, e.bytesLoaded, e.bytesTotal));
			}
		}
		
		/**
		 * 
		 */		
		private function onPartLoadingComplete(e:Event):void {
			switch (state) {
				case LOADING_DIFFUSE_MAP: {
					// Загрузилась диффузная текстура. При необходимости загружается карта прозрачности.
					_bitmapData = Bitmap(bitmapLoader.content).bitmapData;
					dispatchPartComplete(0);
					if (alphaTextureUrl != null) {
						loadPart(LOADING_ALPHA_MAP, alphaTextureUrl);
					} else {
						complete();
					}
					break;
				}
				case LOADING_ALPHA_MAP: {
					// Загрузилась карта прозрачности. Выполняется копирование прозрачности в альфа-канал диффузной текстуры.
					var tmpBmd:BitmapData = _bitmapData;
					_bitmapData = new BitmapData(_bitmapData.width, _bitmapData.height);
					_bitmapData.copyPixels(tmpBmd, tmpBmd.rect, new Point());
					
					var alpha:BitmapData = Bitmap(bitmapLoader.content).bitmapData;
					if (_bitmapData.width != alpha.width || _bitmapData.height != alpha.height) {
						tmpBmd.draw(alpha, new Matrix(_bitmapData.width / alpha.width, 0, 0, _bitmapData.height / alpha.height), null, BlendMode.NORMAL, null, true);
						alpha.dispose();
						alpha = tmpBmd;
					}
					_bitmapData.copyChannel(alpha, alpha.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
					alpha.dispose();
					dispatchPartComplete(1);
					complete();
					break;
				}
			}
		}
		
		/**
		 * Создаёт событие завершения загрузки части текстуры.
		 * 
		 * @param partnNumber номер загруженной части текстуры
		 */
		private function dispatchPartComplete(partNumber:int):void {
			if (hasEventListener(LoaderEvent.PART_COMPLETE)) {
				dispatchEvent(new LoaderEvent(LoaderEvent.PART_COMPLETE, 2, partNumber));
			}
		}

		/**
		 * 
		 */
		private function onLoadError(e:Event):void {
			state = IDLE;
			cleanup();
			dispatchEvent(e);
		}
		
		/**
		 * 
		 */
		private function complete():void {
			state = IDLE;
			cleanup();
			bitmapLoader.unload();
			if (hasEventListener(Event.COMPLETE)) {
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		/**
		 * Удаляет слушатели загрузчика.
		 */
		private function removeListeners():void {
			var loaderInfo:LoaderInfo = bitmapLoader.contentLoaderInfo;
			loaderInfo.removeEventListener(Event.OPEN, onPartLoadingOpen);
			loaderInfo.removeEventListener(ProgressEvent.PROGRESS, onPartLoadingProgress);
			loaderInfo.removeEventListener(Event.COMPLETE, onPartLoadingComplete);
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		}
	}
}