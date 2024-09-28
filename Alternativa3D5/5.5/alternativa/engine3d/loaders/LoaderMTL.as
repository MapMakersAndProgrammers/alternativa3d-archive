package alternativa.engine3d.loaders {
	import alternativa.engine3d.*;
	import alternativa.types.Map;
	import alternativa.utils.ColorUtils;
	
	import flash.display.BitmapData;
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
	 * Тип события, возникающего при завершении загрузки модели.
	 */
	[Event (name="complete", type="flash.events.Event")]
	/**
	 * Тип события, возникающего при ошибке загрузки, связанной с вводом-выводом.
	 */
	[Event (name="ioError", type="flash.events.IOErrorEvent")]
	/**
	 * Тип события, возникающего при нарушении безопасности.
	 */
	[Event (name="securityError", type="flash.events.SecurityErrorEvent")]
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
		private static const CMD_MAP_DISSOLVE:String = "map_d";
		
		private static const REGEXP_TRIM:RegExp = /^\s*(.*?)\s*$/;
		private static const REGEXP_SPLIT_FILE:RegExp = /\r*\n/;
		private static const REGEXP_SPLIT_LINE:RegExp = /\s+/;
		
		private static const STATE_IDLE:int = -1;
		private static const STATE_LOADING_LIBRARY:int = 0;
		private static const STATE_LOADING_TEXTURES:int = 1;
		
		// Загрузчик файла MTL
		private var mtlFileLoader:URLLoader;
		// Загрузчик файлов текстур
		private var textureLoader:TextureMapsLoader;
		// Контекст загрузки для bitmapLoader
		private var loaderContext:LoaderContext;
		// Базовый URL файла MTL
		private var baseUrl:String;

		// Библиотека загруженных материалов
		private var _library:Map;
		// Список диффузные текстур. Ключи -- имена материалов, значения -- информация о текстурах.
		private var diffuseMaps:Map;
		// Список карт прозрачности. Ключи -- имена материалов, значения -- информация о картах прозрачности.
		private var dissolveMaps:Map;
		// Имя текущего материала
		private var materialName:String;
		// параметры текущего материала
		private var currentMaterialInfo:MaterialInfo = new MaterialInfo();
		
		private var loaderState:int = STATE_IDLE;
		
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
			if (loaderState == STATE_LOADING_LIBRARY) {
				mtlFileLoader.close();
			}
			if (loaderState == STATE_LOADING_TEXTURES) {
				textureLoader.close();
			}
			loaderState = STATE_IDLE;
		}
		
		/**
		 * Метод очищает внутренние ссылки на загруженные данные чтобы сборщик мусора мог освободить занимаемую ими память. Метод не работает
		 * во время загрузки.
		 */
		public function unload():void {
			if (loaderState == STATE_IDLE) {
				clean();
				_library = null;
			}
		}
		
		/**
		 * 
		 */
		private function clean():void {
			diffuseMaps = null;
			dissolveMaps = null;
			loaderContext = null;
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

			if (mtlFileLoader == null) {
				mtlFileLoader = new URLLoader();
				mtlFileLoader.addEventListener(Event.COMPLETE, parseMTLFile);
				mtlFileLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
				mtlFileLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			}
			close();
			loaderState = STATE_LOADING_LIBRARY;
			mtlFileLoader.load(new URLRequest(url));
		}
		
		/**
		 * Разбор содержимого загруженного файла материалов.
		 */
		private function parseMTLFile(e:Event = null):void {
			loaderState = STATE_IDLE;
			var lines:Array = mtlFileLoader.data.split(REGEXP_SPLIT_FILE);
			_library = new Map();
			diffuseMaps = new Map();
			dissolveMaps = new Map();
			lines.forEach(parseLine);
			defineMaterial();
			
			if (diffuseMaps.isEmpty()) {
				// Текстур нет, загрузка окончена
				complete();
			} else {
				// Загрузка файлов текстур
				loaderState = STATE_LOADING_TEXTURES;
				loadNextBitmap();
			}
		}
		
		/**
		 * Разбор строки файла.
		 * 
		 * @param line строка файла
		 */
		private	function parseLine(line:String, index:int, lines:Array):void {
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
					parseTextureMapLine(diffuseMaps, parts);
					break;
				case CMD_MAP_DISSOLVE:
					parseTextureMapLine(dissolveMaps, parts);
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
		 * Разбор строки, задающей текстурную карту.
		 */
		private function parseTextureMapLine(map:Map, parts:Array):void {
			var info:MTLTextureMapInfo = MTLTextureMapInfo.parse(parts);
			map[materialName] = info;
		}
		
		/**
		 * Загрузка файла следующей текстуры.
		 */
		private function loadNextBitmap():void {
			if (textureLoader == null) {
				textureLoader = new TextureMapsLoader();
				textureLoader.addEventListener(Event.COMPLETE, onBitmapLoadComplete);
				textureLoader.addEventListener(IOErrorEvent.IO_ERROR, onBitmapLoadComplete);
			}
			
			// Установка имени текущего текстурного материала, для которого выполняется загрузка текстуры
			for (materialName in diffuseMaps) {
				break;
			}
			
			var diffuseName:String = baseUrl + diffuseMaps[materialName].fileName;
			var dissolveName:String;
			var dissolveTextureInfo:MTLTextureMapInfo = dissolveMaps[materialName];
			if (dissolveTextureInfo != null) {
				dissolveName = dissolveTextureInfo.fileName;
			}
			
			textureLoader.load(diffuseName, dissolveName, loaderContext);
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
				bmd = textureLoader.bitmapData;
			}
			
			var mtlInfo:MTLTextureMapInfo = diffuseMaps[materialName];
			delete diffuseMaps[materialName];
			var materialInfo:MaterialInfo = _library[materialName];
			
			materialInfo.bitmapData = bmd;
			materialInfo.repeat = mtlInfo.repeat;
			materialInfo.mapOffset = new Point(mtlInfo.offsetU, mtlInfo.offsetV);
			materialInfo.mapSize = new Point(mtlInfo.sizeU, mtlInfo.sizeV);
			materialInfo.textureFileName = mtlInfo.fileName;
	
			if (diffuseMaps.isEmpty()) {
				complete();
			} else {
				loadNextBitmap();
			}
		}
		
		/**
		 * Обработка успешного завершения загрузки.
		 */
		private function complete():void {
			loaderState = STATE_IDLE;
			if (textureLoader != null) {
				textureLoader.unload();
			}
			clean();
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * Обработка ошибки загрузки MTL-файла.
		 */
		private function onError(e:Event):void {
			loaderState = STATE_IDLE;
			dispatchEvent(e);
		}
	}
}