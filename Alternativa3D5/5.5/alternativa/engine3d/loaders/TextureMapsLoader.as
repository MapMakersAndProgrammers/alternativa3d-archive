package alternativa.engine3d.loaders {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.Loader;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;

	/**
	 * Тип события, возникающего при завершении загрузки.
	 */
	[Event (name="complete", type="flash.events.Event")]
	/**
	 * Тип события, возникающего при ошибке загрузки, связанной с вводом-выводом.
	 */
	[Event (name="ioError", type="flash.events.IOErrorEvent")]
	/**
	 * @private
	 * Класс для загрузки битмапов диффузной текустуры и карты прозрачности.
	 */
	public class TextureMapsLoader extends EventDispatcher {
		
		private static const STATE_IDLE:int = -1;
		private static const STATE_LOADING_DIFFUSE_MAP:int = 0;
		private static const STATE_LOADING_ALPHA_MAP:int = 1;
		
		private var bitmapLoader:Loader;
		private var _bitmapData:BitmapData;
		private var alphaTextureUrl:String;
		private var loaderContext:LoaderContext;

		private var loaderState:int = STATE_IDLE;
		
		/**
		 * 
		 */
		public function TextureMapsLoader() {
		}
		
		/**
		 * Загрузка текстурных карт. При успешной загрузке посылается сообщение <code>Event.COMPLETE</code>.
		 * 
		 * @param diffuseTextureUrl URL файла диффузной карты
		 * @param alphaTextureUrl URL файла карты прозрачности 
		 * @param loaderContext
		 */		
		public function load(diffuseTextureUrl:String, alphaTextureUrl:String = null, loaderContext:LoaderContext = null):void {
			this.alphaTextureUrl = alphaTextureUrl;
			this.loaderContext = loaderContext;
			if (bitmapLoader == null) {
				bitmapLoader = new Loader();
				bitmapLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
				bitmapLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			} else {
				close();
			}
			startLoading(STATE_LOADING_DIFFUSE_MAP, diffuseTextureUrl);
		}

		/**
		 * Запуск загрузки файла текстуры.
		 * 
		 * @param state фаза загрузки
		 * @param url URL загружаемого файла
		 */		
		private function startLoading(state:int, url:String):void {
			loaderState = state;
			bitmapLoader.load(new URLRequest(url), loaderContext);
		}
		
		/**
		 * 
		 */		
		private function onLoadComplete(e:Event):void {
			switch (loaderState) {
				case STATE_LOADING_DIFFUSE_MAP:
					// Загрузилась диффузная текстура. При необходимости загружается карта прозрачности.
					_bitmapData = Bitmap(bitmapLoader.content).bitmapData;
					if (alphaTextureUrl != null) {
						startLoading(STATE_LOADING_ALPHA_MAP, alphaTextureUrl);
					} else {
						complete();
					}
					break;
				case STATE_LOADING_ALPHA_MAP:
					// Загрузилась карта прозрачности. Выполняется копирование прозрачности в альфа-канал диффузной текстуры.
					var tmpBmp:BitmapData = _bitmapData;
					_bitmapData = new BitmapData(_bitmapData.width, _bitmapData.height);
					_bitmapData.copyPixels(tmpBmp, tmpBmp.rect, new Point());
					
					var alpha:BitmapData = Bitmap(bitmapLoader.content).bitmapData;
					if (_bitmapData.width != alpha.width || _bitmapData.height != alpha.height) {
						tmpBmp.draw(alpha, new Matrix(_bitmapData.width / alpha.width, 0, 0, _bitmapData.height / alpha.height), null, BlendMode.NORMAL, null, true);
						alpha.dispose();
						alpha = tmpBmp;
					}
					_bitmapData.copyChannel(alpha, alpha.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
					alpha.dispose();
					complete();
					break;
			}
		}

		/**
		 * 
		 */
		private function onLoadError(e:Event):void {
			loaderState = STATE_IDLE;
			dispatchEvent(e);
		}
		
		/**
		 * 
		 */
		private function complete():void {
			loaderState = STATE_IDLE;
			loaderContext = null;
			bitmapLoader.unload();
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * Загруженная текстура.
		 */
		public function get bitmapData():BitmapData {
			return _bitmapData;
		}
		
		/**
		 * Прекращение загрузки.
		 */
		public function close():void {
			if (loaderState != STATE_IDLE) {
				loaderState = STATE_IDLE;
				bitmapLoader.close();
			}
		}

		/**
		 * Очищает внутренние ссылки на загруженные объекты, чтобы сборщик мусора смог их удалить.
		 */
		public function unload():void {
			if (bitmapLoader != null && loaderState == STATE_IDLE) {
				bitmapLoader.unload();
				loaderContext = null;
				_bitmapData = null;
			}
		}
	}
}