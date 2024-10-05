package alternativa.engine3d.loaders {
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.system.LoaderContext;
	
	/**
	 * Событие рассылается после окончания загрузки сцены.
	 * 
	 * @eventType flash.events.Event.COMPLETE
	 */
	[Event (name="complete", type="flash.events.Event")]
	/**
	 * Тип события, рассылаемого при возникновении ошибки загрузки текстуры.
	 * 
	 * @eventType flash.events.IOErrorEvent.IO_ERROR
	 */
	[Event (name="ioError", type="flash.events.IOErrorEvent")]
	
	/**
	 * @private
	 * Пакетный загрузчик текстур. Используется загрузчиками внешних сцен для получения битмапов текстур материалов.
	 */
	public class TextureMapsBatchLoader extends EventDispatcher {
		/**
		 * Текстура-заглушка для замены незагруженных текстур.
		 */
		public static var stubBitmapData:BitmapData;
		
		// Загрузчик файлов текстур.
		private var loader:TextureMapsLoader;
		// Контекст безопасности загрузчика.
		private var loaderContext:LoaderContext;
		// Базовый URL файлов текстур.
		private var baseUrl:String;
		// Пакет с описанием текстур материалов.
		private var batch:Object;
		// Список имён материалов.
		private var materialNames:Array;
		// Общее количество файлов текстур.
		private var totalFiles:int;
		// Номер текущего 
		private var currentFileNumber:int;
		// Индекс текущего материала.
		private var materialIndex:int;
		// Результирующий список битмапов для каждого материала.
		private var _textures:Object;
		
		/**
		 * Создаёт новый экземпляр загрузчика.
		 */
		public function TextureMapsBatchLoader() {
		}
		
		/**
		 * Результирующий список битмапов для каждого материала. Ключами являются имена материалов, значениями -- объекты класса BitmapData.
		 */
		public function get textures():Object {
			return _textures;
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

		/**
		 * Прекращает текущую загрузку.
		 */
		public function close():void {
			if (loader != null) {
				loader.close();
			}
		}
		
		/**
		 * Очищает внутренние ссылки на объекты.
		 */
		private function clean():void {
			loaderContext = null;
			batch = null;
			materialNames = null;
		}
		
		/**
		 * Очищает ссылку на загруженный список текстур материалов.
		 */
		public function unload():void {
			_textures = null;
		}
		
		/**
		 * Загружает текстуры для материалов.
		 * 
		 * @param baseURL базовый URL файлов текстур
		 * @param batch массив соответствий имён текстурных материалов и их текстур, описываемых объектами класса TextureMapsInfo
		 * @param loaderContext LoaderContext для загрузки файлов текстур
		 */
		public function load(baseURL:String, batch:Object, loaderContext:LoaderContext):void {
			this.baseUrl = baseURL;
			this.batch = batch;
			this.loaderContext = loaderContext;
			
			if (loader == null) {
				loader = new TextureMapsLoader();
				loader.addEventListener(Event.COMPLETE, onMaterialTexturesLoadingComplete);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onMaterialTexturesLoadingComplete);
			} else {
				close();
			}
			// Получение массива имён материалов и подсчёт количества файлов текстур
			totalFiles = 0;
			materialNames = new Array();
			for (var materialName:String in batch) {
				materialNames.push(materialName);
				var info:TextureMapsInfo = batch[materialName];
				totalFiles += info.opacityMapFileName == null ? 1 : 2;
			}
			// Старт загрузки
			materialIndex = 0;
			_textures = {};
			loadNextTextureFile();
		}
		
		/**
		 * Загружает очередной файл с текстурой.
		 */
		private function loadNextTextureFile():void {
			var info:TextureMapsInfo = batch[materialNames[materialIndex]];
			loader.load(baseUrl + info.diffuseMapFileName, info.opacityMapFileName == null || info.opacityMapFileName == "" ? null : baseUrl + info.opacityMapFileName, loaderContext);
		}
		
		/**
		 * Ретранслирует событие окончания загрузки текстуры.
		 */
		private function onTextureLoadingComplete(e:Event):void {
			dispatchEvent(e);
		}

		/**
		 * Обрабатывает завершение загрузки текстуры материала.
		 */
		private function onMaterialTexturesLoadingComplete(e:Event):void {
			// В зависимости от полученного события устанавливается загруженное изображение или битмап-заглушка
			if (e is IOErrorEvent) {
				_textures[materialNames[materialIndex]] = getStubBitmapData();
				dispatchEvent(e);
			} else {
				_textures[materialNames[materialIndex]] = loader.bitmapData;
			}
			if ((++materialIndex) == materialNames.length) {
				// Загружены текстуры для всех материалов, отправляется сообщение о завершении
				clean(); 
				dispatchEvent(new Event(Event.COMPLETE));
			} else {
				loadNextTextureFile();
			}
		}
		
	}
}