package alternativa.engine3d.loaders {
	import alternativa.engine3d.*;
	import alternativa.types.Map;
	import alternativa.utils.ColorUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	use namespace alternativa3d;
	
	/**
	 * @private
	 * Загрузчик библиотеки материалов из файлов в формате MTL material format (Lightwave, OBJ).
	 * <p>
	 * На данный момент обеспечивается загрузка цвета, прозрачности и диффузной текстуры материала.
	 */
	internal class LoaderMTL extends EventDispatcher {
		
		private static const COMMENT_CHAR:String = "#";
		private static const CMD_NEW_MATERIAL:String = "newmtl";
		private static const CMD_DIFFUSE_REFLECTIVITY:String = "Kd";
		private static const CMD_DISSOLVE:String = "d";
		private static const CMD_MAP_DIFFUSE:String = "map_Kd";
		
		private static const REGEXP_TRIM:RegExp = /^\s*(.*)\s*$/;
		private static const REGEXP_SPLIT_FILE:RegExp = /\r*\n/;
		private static const REGEXP_SPLIT_LINE:RegExp = /\s+/;
		
		// Загрузчик файла MTL
		private var fileLoader:URLLoader;
		// Загрузчик файлов текстур
		private var bitmapLoader:Loader;
		// Контекст загрузки для bitmapLoader
		private var loaderContext:LoaderContext;
		// Базовый URL файла MTL
		private var baseUrl:String;

		// Библиотека загруженных материалов
		private var _library:Map;
		// Список материалов, имеющих диффузные текстуры
		private var diffuseMaps:Map;
		// Имя текущего материала
		private var materialName:String;
		// параметры текущего материала
		private var currentMaterialInfo:MaterialInfo = new MaterialInfo();
		
		alternativa3d static var stubBitmapData:BitmapData;
		
		/**
		 * Создаёт новый экземпляр класса.
		 */
		public function LoaderMTL() {
		}
		
		/**
		 * Прекращение текущей загрузки.
		 */
		public function close():void {
			try {
				fileLoader.close();
			} catch (e:Error) {
			}
		}
		
		/**
		 * Библиотека материалов. Ключами являются наименования материалов, значениями -- объекты, наследники класса
		 * <code>alternativa.engine3d.loaders.MaterialInfo</code>.
		 * @see alternativa.engine3d.loaders.MaterialInfo
		 */
		public function get library():Map {
			return _library;
		}
		
		/**
		 * Метод выполняет загрузку файла материалов, разбор его содержимого, загрузку текстур при необходимости и
		 * формирование библиотеки материалов. После окончания работы метода посылается сообщение
		 * <code>Event.COMPLETE</code> и становится доступна библиотека материалов через свойство <code>library</code>.
		 * <p>
		 * При возникновении ошибок, связанных с вводом-выводом или с безопасностью, посылаются сообщения <code>IOErrorEvent.IO_ERROR</code> и 
		 * <code>SecurityErrorEvent.SECURITY_ERROR</code> соответственно.
		 * <p>
		 * Если происходит ошибка при загрузке файла текстуры, то соответствующая текстура заменяется на текстуру-заглушку.
		 * <p>
		 * @param url URL MTL-файла
		 * @param loaderContext LoaderContext для загрузки файлов текстур
		 *  
		 * @see #library
		 */
		public function load(url:String, loaderContext:LoaderContext = null):void {
			this.loaderContext = loaderContext;
			baseUrl = url.substring(0, url.lastIndexOf("/") + 1);

			if (fileLoader == null) {
				fileLoader = new URLLoader();
				fileLoader.addEventListener(Event.COMPLETE, parseMTLFile);
				fileLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
				fileLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);

				bitmapLoader = new Loader();
				bitmapLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBitmapLoadComplete);
				bitmapLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onBitmapLoadComplete);
				bitmapLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onBitmapLoadComplete);
			}
			
			try {
				fileLoader.close();
				bitmapLoader.close();
			} catch (e:Error) {
				// Пропуск ошибки при попытке закрытия неактивных загрузчиков
			}
			
			fileLoader.load(new URLRequest(url));
		}
		
		/**
		 * Разбор содержимого загруженного файла материалов.
		 */
		private function parseMTLFile(e:Event = null):void {
			var lines:Array = fileLoader.data.split(REGEXP_SPLIT_FILE);
			_library = new Map();
			diffuseMaps = new Map();
			for each (var line:String in lines) {
				parseLine(line);
			}
			defineMaterial();
			
			if (diffuseMaps.isEmpty()) {
				// Текстур нет, загрузка окончена
				dispatchEvent(new Event(Event.COMPLETE));
			} else {
				// Загрузка файлов текстур
				loadNextBitmap();
			}
		}
		
		/**
		 * Разбор строки файла.
		 * 
		 * @param line строка файла
		 */
		private	function parseLine(line:String):void {
			line = line.replace(REGEXP_TRIM,"$1")
			if (line.length == 0 || line.charAt(0) == COMMENT_CHAR) {
				return;
			}
			var parts:Array = line.split(REGEXP_SPLIT_LINE);
			switch (parts[0]) {
				case CMD_NEW_MATERIAL:
					defineMaterial(parts);
					break;
				case CMD_DIFFUSE_REFLECTIVITY:
					readDiffuseReflectivity(parts);
					break;
				case CMD_DISSOLVE:
					readAlpha(parts);
					break;
				case CMD_MAP_DIFFUSE:
					parseDiffuseMapLine(parts);
					break;
			}
		}
		
		/**
		 * Определение нового материала.
		 */		
		private function defineMaterial(parts:Array = null):void {
			if (materialName != null) {
				_library[materialName] = currentMaterialInfo;
			}
			if (parts != null) {
				materialName = parts[1];
				currentMaterialInfo = new MaterialInfo();
			}
		}
		
		/**
		 * Чтение коэффициентов диффузного отражения. Считываются только коэффициенты, заданные в формате r g b. Для текущей
		 * версии движка данные коэффициенты преобразуются в цвет материала.
		 */
		private function readDiffuseReflectivity(parts:Array):void {
			var r:Number = Number(parts[1]);
			// Проверка, заданы ли коэффициенты в виде r g b
			if (!isNaN(r)) {
				var g:Number = Number(parts[2]);
				var b:Number = Number(parts[3]);
				currentMaterialInfo.color = ColorUtils.rgb(255 * r, 255 * g, 255 * b); 
			}
		}

		/**
		 * Чтение коэффициента непрозрачности. Считывается только коэффициент, заданный числом
		 * (не поддерживается параметр -halo).
		 */
		private function readAlpha(parts:Array):void {
			var alpha:Number = Number(parts[1]);
			if (!isNaN(alpha)) {
				currentMaterialInfo.alpha = alpha;
			}
		}
		
		/**
		 * Разбор строки, задающей текстурную карту для диффузного отражения.
		 */
		private function parseDiffuseMapLine(parts:Array):void {
			var info:MTLTextureMapInfo = MTLTextureMapInfo.parse(parts);
			diffuseMaps[materialName] = info;
		}
		
		/**
		 * Загрузка файла следующей текстуры.
		 */
		private function loadNextBitmap():void {
			// Установка имени текущего текстурного материала, для которого выполняется загрузка текстуры
			for (materialName in diffuseMaps) {
				break;
			}
			bitmapLoader.load(new URLRequest(baseUrl + diffuseMaps[materialName].fileName), loaderContext);
		}
		
		/**
		 * 
		 */
		private function createStubBitmap():void {
			if (stubBitmapData == null) {
				var size:uint = 10;
				stubBitmapData = new BitmapData(size, size, false, 0);
				for (var i:uint = 0; i < size; i++) {
					for (var j:uint = 0; j < size; j+=2) {
						stubBitmapData.setPixel((i % 2) ? j : (j+1), i, 0xFF00FF);
					}
				}
			}
		}
		
		/**
		 * Обработка результата загрузки файла текстуры.
		 */
		private function onBitmapLoadComplete(e:Event):void {
			var bmd:BitmapData;
			
			if (e is ErrorEvent) {
				if (stubBitmapData == null) {
					createStubBitmap();
				}
				bmd = stubBitmapData;
			} else {
				bmd = Bitmap(bitmapLoader.content).bitmapData;
			}
			
			var mtlInfo:MTLTextureMapInfo = diffuseMaps[materialName];
			delete diffuseMaps[materialName];
			var info:MaterialInfo = _library[materialName];
			
			info.bitmapData = bmd;
			info.repeat = mtlInfo.repeat;
			info.mapOffset = new Point(mtlInfo.offsetU, mtlInfo.offsetV);
			info.mapSize = new Point(mtlInfo.sizeU, mtlInfo.sizeV);
			info.textureFileName = mtlInfo.fileName;
	
			if (diffuseMaps.isEmpty()) {
				dispatchEvent(new Event(Event.COMPLETE));
			} else {
				loadNextBitmap();
			}
		}
		
		/**
		 * 
		 * @param e
		 */
		private function onError(e:IOErrorEvent):void {
			dispatchEvent(e);
		}
	}
}