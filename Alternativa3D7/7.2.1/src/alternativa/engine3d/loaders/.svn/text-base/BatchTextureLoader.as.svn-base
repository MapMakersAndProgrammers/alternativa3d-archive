package alternativa.engine3d.loaders {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.loaders.events.BatchTextureLoaderErrorEvent;
	import alternativa.engine3d.loaders.events.LoaderEvent;
	import alternativa.engine3d.loaders.events.LoaderProgressEvent;
	
	import flash.display.BitmapData;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.system.LoaderContext;
	
	/**
	 * Событие посылается, когда начинается загрузка пакета.
	 * 
	 * @eventType flash.events.Event.OPEN
	 */
	[Event (name="open", type="flash.events.Event")]
	/**
	 * Событие посылается, когда загрузка пакета успешно завершена.
	 * 
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event (name="complete", type="flash.events.Event")]
	/**
	 * Событие посылается при возникновении ошибки загрузки.
	 * 
	 * @eventType alternativa.engine3d.loaders.events.BatchTextureLoaderErrorEvent.LOADER_ERROR
	 */
	[Event (name="loaderError", type="alternativa.engine3d.loaders.events.BatchTextureLoaderErrorEvent")]
	/**
	 * Событие посылается, когда начинается загрузка очередной текстуры.
	 * 
	 * @eventType alternativa.engine3d.loaders.events.LoaderEvent.PART_OPEN
	 */
	[Event (name="partOpen", type="alternativa.engine3d.loaders.events.LoaderEvent")]
	/**
	 * Событие посылается, когда загрузка очередной текстуры успешно завершена.
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
	 * @private
	 * Пакетный загрузчик текстур.
	 * 
	 * При возникновении ошибки во время загрузки очередной текстуры, пакетный загрузчик заменяет соответствующую текстуру изображением-заглушкой и
	 * генерирует событие ошибки пакетного загрузчика. Пользователь пакетного загрузчика в обработчике ошибки может решить, прерывать ли процесс
	 * загрузки вызовом метода close() или нет.
	 */
	public class BatchTextureLoader extends EventDispatcher {
		/**
		 * Текстура-заглушка для замены незагруженных текстур.
		 */
		private static var stubBitmapData:BitmapData;
		
		private static const IDLE:int = 0;
		private static const LOADING:int = 1;
		
		// Состояние загрузчика
		private var state:int = IDLE;
		
		// Загрузчик текстур
		private var textureLoader:TextureLoader;
		// Контекст безопасности загрузчика
		private var loaderContext:LoaderContext;
		// Базовый URL файлов текстур
		private var baseURL:String;
		// Пакет с описанием текстур материалов (textureName => TextureInfo)
		private var batch:Object;
		// Список имён текстур в пакете
		private var textureNames:Vector.<String>;
		// Индекс текущего материала.
		private var textureIndex:int;
		// Общее количество загружаемых текстур
		private var numTextures:int;
		// Результирующая таблица (textureName => BitmapData)
		private var _textures:Object;
		
		/**
		 * Создаёт новый экземпляр загрузчика.
		 */
		public function BatchTextureLoader() {
		}
		
		/**
		 * Результирующая таблица битмапов. Ключами являются имена текстур, значениями -- объекты класса BitmapData.
		 */
		public function get textures():Object {
			return _textures;
		}
		
		/**
		 * Прекращает текущую загрузку.
		 */
		public function close():void {
			if (state == LOADING) {
				textureLoader.close();
				cleanup();
				_textures = null;
				state = IDLE;
			}
		}
		
		/**
		 * Очищает ссылку на загруженный список текстур материалов.
		 */
		public function unload():void {
			_textures = null;
		}
		
		/**
		 * Запускает загрузку.
		 * 
		 * @param baseURL базовый URL файлов текстур
		 * @param batch описание пакета текстур -- таблица textureName => TextureInfo
		 * @param loaderContext LoaderContext для загрузки
		 */
		public function load(baseURL:String, batch:Object, loaderContext:LoaderContext = null):void {
			if (baseURL == null) {
				throw ArgumentError("Parameter baseURL cannot be null");
			}
			if (batch == null) {
				throw ArgumentError("Parameter batch cannot be null");
			}
			
			this.baseURL = baseURL;
			this.batch = batch;
			this.loaderContext = loaderContext;
			
			if (textureLoader == null) {
				textureLoader = new TextureLoader();
			} else {
				close();
			}
			textureLoader.addEventListener(Event.OPEN, onTextureLoadingStart);
			textureLoader.addEventListener(LoaderProgressEvent.LOADER_PROGRESS, onProgress);
			textureLoader.addEventListener(Event.COMPLETE, onTextureLoadingComplete);
			textureLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoadingError);

			// Получение массива имён текстур
			textureNames = new Vector.<String>();
			for (var textureName:String in batch) {
				textureNames.push(textureName);
			}
			numTextures = textureNames.length;
			// Старт загрузки
			textureIndex = 0;
			_textures = {};
			
			if (hasEventListener(Event.OPEN)) {
				dispatchEvent(new Event(Event.OPEN));
			}
			
			state = LOADING;
			loadNextTexture();
		}

		/**
		 * Запускает загрузку очередной текстуры.
		 */
		private function loadNextTexture():void {
			var info:TextureInfo = batch[textureNames[textureIndex]];
			var opacityMapFileUrl:String = info.opacityMapFileName == null || info.opacityMapFileName == "" ? null : baseURL + info.opacityMapFileName;
			textureLoader.load(baseURL + info.diffuseMapFileName, opacityMapFileUrl, loaderContext);
		}

		/**
		 * 
		 */
		private function onTextureLoadingStart(e:Event):void {
			if (hasEventListener(LoaderEvent.PART_OPEN)) {
				dispatchEvent(new LoaderEvent(LoaderEvent.PART_OPEN, numTextures, textureIndex));
			}
		}

		/**
		 * 
		 */
		private function onProgress(e:LoaderProgressEvent):void {
			if (hasEventListener(LoaderProgressEvent.LOADER_PROGRESS)) {
				var totalProgress:Number = (textureIndex + e.totalProgress)/numTextures;
				dispatchEvent(new LoaderProgressEvent(LoaderProgressEvent.LOADER_PROGRESS, numTextures, textureIndex, totalProgress, e.bytesLoaded, e.bytesTotal));
			}
		}

		/**
		 * Обрабатывает завершение загрузки текстуры.
		 */
		private function onTextureLoadingComplete(e:Event):void {
			_textures[textureNames[textureIndex]] = textureLoader.bitmapData;
			tryNextTexure();
		}

		/**
		 * Обрабатывает ошибку при загрузке текстуры. Незагруженная текстура заменяется изображением-заглушкой и
		 * генерируется событие ошибки пакетного загрузчика.
		 */
		private function onLoadingError(e:ErrorEvent):void {
			var textureName:String = textureNames[textureIndex];
			_textures[textureName] = getStubBitmapData();
			dispatchEvent(new BatchTextureLoaderErrorEvent(BatchTextureLoaderErrorEvent.LOADER_ERROR, textureName, e.text));
			tryNextTexure();
		}
		
		/**
		 * 
		 */
		private function tryNextTexure():void {
			// Проверка состояния необходима, т.к. оно могло измениться в результате вызова метода close() в обработчике события ошибки загрузки
			if (state == IDLE) return;
			
			if (hasEventListener(LoaderEvent.PART_COMPLETE)) {
				dispatchEvent(new LoaderEvent(LoaderEvent.PART_COMPLETE, numTextures, textureIndex));
			}
			if (++textureIndex == numTextures) {
				// Загружены все текстуры, отправляется сообщение о завершении
				cleanup();
				removeEventListeners();
				state = IDLE;
				if (hasEventListener(Event.COMPLETE)) {
					dispatchEvent(new Event(Event.COMPLETE));
				}
			} else {
				loadNextTexture();
			}
		}
		
		/**
		 * 
		 */
		private function removeEventListeners():void {
			textureLoader.removeEventListener(Event.OPEN, onTextureLoadingStart);
			textureLoader.removeEventListener(LoaderProgressEvent.LOADER_PROGRESS, onProgress);
			textureLoader.removeEventListener(Event.COMPLETE, onTextureLoadingComplete);
			textureLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
		}
		
		/**
		 * Очищает внутренние ссылки на объекты.
		 */
		private function cleanup():void {
			loaderContext = null;
			textureNames = null;
		}
		
		/**
		 * Метод для получения текстуры-заглушки.
		 * 	
		 * @return текстура-заглушка для замещения незагруженных текстур
		 */
		private function getStubBitmapData():BitmapData {
			if (stubBitmapData == null) {
				var size:uint = 20;
				stubBitmapData = new BitmapData(size, size, false, 0);
				for (var i:uint = 0; i < size; i++) {
					for (var j:uint = 0; j < size; j += 2) {
						stubBitmapData.setPixel((i%2) ? j : (j + 1), i, 0xFF00FF);
					}
				}
			}
			return stubBitmapData;
		}
		
	}
}