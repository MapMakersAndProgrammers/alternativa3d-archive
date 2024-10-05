package alternativa.engine3d.loaders {
	import alternativa.engine3d.*;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Surface;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.TextureMaterialPrecision;
	import alternativa.types.Map;
	import alternativa.types.Point3D;
	import alternativa.types.Texture;
	
	import flash.display.BlendMode;
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
	 * Загрузчик моделей из файла в формате OBJ. Так как OBJ не поддерживает иерархию объектов, все загруженные
	 * модели помещаются в один контейнер <code>Object3D</code>.
	 * <p>
	 * Поддерживаюся следующие команды формата OBJ:
	 * <p>
	 * <table border="1" style="border-collapse: collapse">
	 * <tr>
	 *   <th width="30%">Команда</th>
	 *   <th>Описание</th>
	 *   <th>Действие</th></tr>
	 * <tr>
	 *   <td>o object_name</td>
	 *   <td>Объявление нового объекта с именем object_name</td>
	 *   <td>Если для текущего объекта были определены грани, то команда создаёт новый текущий объект с указанным именем,
	 *       иначе у текущего объекта просто меняется имя на указанное.</td>
	 * </tr>
	 * <tr>
	 *   <td>v x y z</td>
	 *   <td>Объявление вершины с координатами x y z</td>
	 *   <td>Вершина помещается в общий список вершин сцены для дальнейшего использования</td>
	 * </tr>
	 * <tr>
	 *   <td>vt u [v]</td>
	 *   <td>Объявление текстурной вершины с координатами u v</td>
	 *   <td>Вершина помещается в общий список текстурных вершин сцены для дальнейшего использования</td>
	 * </tr>
	 * <tr>
	 *   <td>f v0[/vt0] v1[/vt1] ... vN[/vtN]</td>
	 *   <td>Объявление грани, состоящей из указанных вершин и опционально имеющую заданные текстурные координаты для вершин.</td>
	 *   <td>Грань добавляется к текущему активному объекту. Если есть активный материал, то грань также добавляется в поверхность
	 *       текущего объекта, соответствующую текущему материалу.</td>
	 * </tr>
	 * <tr>
	 *   <td>usemtl material_name</td>
	 *   <td>Установка текущего материала с именем material_name</td>
	 *   <td>С момента установки текущего материала все грани, создаваемые в текущем объекте будут помещаться в поверхность,
	 *       соотвествующую этому материалу и имеющую идентификатор, совпадающий с его именем.</td>
	 * </tr>
	 * <tr>
	 *   <td>mtllib file1 file2 ...</td>
	 *   <td>Объявление файлов, содержащих определения материалов</td>
	 *   <td>Выполняется загрузка файлов и формирование библиотеки материалов</td>
	 * </tr>
	 * </table>
	 * 
	 * <p>
	 * Пример использования:
	 * <pre>
	 * var loader:LoaderOBJ = new LoaderOBJ();
	 * loader.addEventListener(Event.COMPLETE, onLoadingComplete);
	 * loader.load("foo.obj");
	 * 
	 * function onLoadingComplete(e:Event):void {
	 *   scene.root.addChild(e.target.content);
	 * }
	 * </pre>
	 */
	public class LoaderOBJ extends EventDispatcher {
		
		private static const COMMENT_CHAR:String = "#";
		
		private static const CMD_OBJECT_NAME:String = "o";
		private static const CMD_GROUP_NAME:String = "g";
		private static const CMD_VERTEX:String = "v";
		private static const CMD_TEXTURE_VERTEX:String = "vt";
		private static const CMD_FACE:String = "f";
		private static const CMD_MATERIAL_LIB:String = "mtllib";
		private static const CMD_USE_MATERIAL:String = "usemtl";

		private static const REGEXP_TRIM:RegExp = /^\s*(.*?)\s*$/;
		private static const REGEXP_SPLIT_FILE:RegExp = /\r*\n/;
		private static const REGEXP_SPLIT_LINE:RegExp = /\s+/;
		
		private var basePath:String;
		private var objLoader:URLLoader;
		private var mtlLoader:LoaderMTL;
		private var loaderContext:LoaderContext;
		private var loadMaterials:Boolean;
		// Объект, содержащий все определённые в obj файле объекты
		private var _content:Object3D;
		// Текущий конструируемый объект
		private var currentObject:Mesh;
		// Стартовый индекс вершины в глобальном массиве вершин для текущего объекта
		private var vIndexStart:int = 0;
		// Стартовый индекс текстурной вершины в глобальном массиве текстурных вершин для текущего объекта
		private var vtIndexStart:int = 0;
		// Глобальный массив вершин, определённых во входном файле
		private var globalVertices:Array;
		// Глобальный массив текстурных вершин, определённых во входном файле
		private var globalTextureVertices:Array;
		// Имя текущего активного материала. Если значение равно null, то активного материала нет. 
		private var currentMaterialName:String;
		// Массив граней текущего объекта, которым назначен текущий материал
		private var materialFaces:Array;
		// Массив имён файлов, содержащих определения материалов
		private var materialFileNames:Array;
		private var currentMaterialFileIndex:int;
		private var materialLibrary:Map;
		
		/**
		 * Сглаживание текстур при увеличении масштаба.
		 * 
		 * @see alternativa.engine3d.materials.TextureMaterial
		 */		
		public var smooth:Boolean = false;
		/**
		 * Режим наложения цвета для создаваемых текстурных материалов.
		 * 
		 * @see alternativa.engine3d.materials.TextureMaterial
		 */
		public var blendMode:String = BlendMode.NORMAL;
		/**
		 * Точность перспективной коррекции для создаваемых текстурных материалов.
		 * 
		 * @see alternativa.engine3d.materials.TextureMaterial
		 */		
		public var precision:Number = TextureMaterialPrecision.MEDIUM;

		/**
		 * Устанавливаемый уровень мобильности загруженных объектов.
		 */		
		public var mobility:int = 0;

		/**
		 * При установленном значении <code>true</code> выполняется преобразование координат геометрических вершин посредством
		 * поворота на 90 градусов относительно оси X. Смысл флага в преобразовании системы координат, в которой вверх направлена
		 * ось <code>Y</code>, в систему координат, использующуюся в Alternativa3D (вверх направлена ось <code>Z</code>). 
		 */		
		public var rotateModel:Boolean;
		
		/**
		 * Создаёт новый экземпляр загрузчика.
		 */
		public function LoaderOBJ() {
		}
		
		/**
		 * Контейнер, содержащий все загруженные из OBJ-файла модели.
		 */
		public function get content():Object3D {
			return _content;
		}
		
		/**
		 * Прекращение текущей загрузки.
		 */
		public function close():void {
			try {
				objLoader.close();
			} catch (e:Error) {
			}
			mtlLoader.close();
		}
		
		/**
		 * Загрузка сцены из OBJ-файла по указанному адресу. По окончании загрузки посылается сообщение <code>Event.COMPLETE</code>,
		 * после чего контейнер с загруженными объектами становится доступным через свойство <code>content</code>.
		 * <p>
		 * При возникновении ошибок, связанных с вводом-выводом или с безопасностью, посылаются сообщения <code>IOErrorEvent.IO_ERROR</code> и 
		 * <code>SecurityErrorEvent.SECURITY_ERROR</code> соответственно.
		 * <p>
		 * @param url URL OBJ-файла 
		 * @param loadMaterials флаг загрузки материалов. Если указано значение <code>true</code>, будут обработаны все файлы
		 * 		материалов, указанные в исходном OBJ-файле.
		 * @param context LoaderContext для загрузки файлов текстур
		 * 
		 * @see #content
		 */
		public function load(url:String, loadMaterials:Boolean = true, context:LoaderContext = null):void {
			_content = null;
			this.loadMaterials = loadMaterials;
			this.loaderContext = context;
			basePath = url.substring(0, url.lastIndexOf("/") + 1);
			if (objLoader == null) {
				objLoader = new URLLoader();
				objLoader.addEventListener(Event.COMPLETE, onObjLoadComplete);
				objLoader.addEventListener(IOErrorEvent.IO_ERROR, onObjLoadError);
				objLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onObjLoadError);
			} else {
				close();
			}
			objLoader.load(new URLRequest(url));
		}
		
		/**
		 * Обработка окончания загрузки obj файла.
		 * 
		 * @param e
		 */
		private function onObjLoadComplete(e:Event):void {
			parse(objLoader.data);
		}

		/**
		 * Обработка ошибки при загрузке.
		 * 
		 * @param e
		 */
		private function onObjLoadError(e:ErrorEvent):void {
			dispatchEvent(e);
		}
		
		/**
		 * Метод выполняет разбор данных, полученных из obj файла.
		 * 
		 * @param s содержимое obj файла 
		 * @param materialLibrary библиотека материалов
		 * @return объект, содержащий все трёхмерные объекты, определённые в obj файле
		 */
		private function parse(data:String):void {
			_content = new Object3D();
			currentObject = new Mesh();
			currentObject.mobility = mobility;
			_content.addChild(currentObject);
			
			globalVertices = new Array();
			globalTextureVertices = new Array();
			materialFileNames = new Array();
			
			var lines:Array = data.split(REGEXP_SPLIT_FILE);
			for each (var line:String in lines) {
				parseLine(line);
			}
			moveFacesToSurface();
			// Вся геометрия загружена и сформирована. Выполняется загрузка информации о материалах.
			if (loadMaterials && materialFileNames.length > 0) {
				loadMaterialsLibrary();
			} else {
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		/**
		 * 
		 */
		private function parseLine(line:String):void {
			line = line.replace(REGEXP_TRIM,"$1");
			if (line.length == 0 || line.charAt(0) == COMMENT_CHAR) {
				return;
			}
			var parts:Array = line.split(REGEXP_SPLIT_LINE);
			switch (parts[0]) {
				// Объявление нового объекта
				case CMD_OBJECT_NAME:
					defineObject(parts[1]);
					break;
				// Объявление вершины
				case CMD_VERTEX:
					globalVertices.push(new Point3D(Number(parts[1]), Number(parts[2]), Number(parts[3])));
					break;
				// Объявление текстурной вершины
				case CMD_TEXTURE_VERTEX:
					globalTextureVertices.push(new Point3D(Number(parts[1]), Number(parts[2]), Number(parts[3])));
					break;
				// Объявление грани
				case CMD_FACE:
					createFace(parts);
					break;
				case CMD_MATERIAL_LIB:
					storeMaterialFileNames(parts);
					break;
				case CMD_USE_MATERIAL:
					setNewMaterial(parts);
					break;
			}
		}
		
		/**
		 * Объявление нового объекта.
		 * 
		 * @param objectName имя объекта
		 */
		private function defineObject(objectName:String):void {
			if (currentObject.faces.length == 0) {
				// Если у текущего объекта нет граней, то он остаётся текущим, но меняется имя
				currentObject.name = objectName;
			} else {
				// Если у текущего объекта есть грани, то обявление нового имени создаёт новый объект
				moveFacesToSurface();
				currentObject = new Mesh(objectName);
				currentObject.mobility = mobility;
				_content.addChild(currentObject);
			}
			vIndexStart = globalVertices.length;
			vtIndexStart = globalTextureVertices.length;
		}
		
		/**
		 * Создание грани в текущем объекте.
		 * 
		 * @param parts массив, содержащий индексы вершин грани, начиная с элемента с индексом 1 
		 */		
		private function createFace(parts:Array):void {
			// Стартовый индекс вершины в объекте для добавляемой грани
			var startVertexIndex:int = currentObject.vertices.length;
			// Создание вершин в объекте
			var faceVertexCount:int = parts.length - 1;
			var vtIndices:Array = new Array(3);
			// Массив идентификаторов вершин грани
			var faceVertices:Array = new Array(faceVertexCount);
			for (var i:int = 0; i < faceVertexCount; i++) {
				var indices:Array = parts[i + 1].split("/");
				// Создание вершины
				var vIdx:int = int(indices[0]);
				// Если индекс положительный, то его значение уменьшается на единицу, т.к. в obj формате индексация начинается с 1.
				// Если индекс отрицательный, то выполняется смещение на его значение назад от стартового глобального индекса вершин для текущего объекта.
				var actualIndex:int = vIdx > 0 ? vIdx - 1 : vIndexStart + vIdx;
				
				var vertex:Vertex = currentObject.vertices[actualIndex];
				// Если вершины нет в объекте, она добавляется
				if (vertex == null) {
					var p:Point3D = globalVertices[actualIndex];
					if (rotateModel) {
						// В формате obj направление "вверх" совпадает с осью Y, поэтому выполняется поворот координат на 90 градусов по оси X 
						vertex = currentObject.createVertex(p.x, -p.z, p.y, actualIndex);
					} else {
						vertex = currentObject.createVertex(p.x, p.y, p.z, actualIndex);
					}
				}
				faceVertices[i] = vertex;
				
				// Запись индекса текстурной вершины
				if (i < 3) {
					vtIndices[i] = int(indices[1]);
				}
			}
			// Создание грани
			var face:Face = currentObject.createFace(faceVertices, currentObject.faces.length);
			// Установка uv координат
			if (vtIndices[0] != 0) {
				p = globalTextureVertices[vtIndices[0] - 1];
				face.aUV = new Point(p.x, p.y);
				p = globalTextureVertices[vtIndices[1] - 1];
				face.bUV = new Point(p.x, p.y);
				p = globalTextureVertices[vtIndices[2] - 1];
				face.cUV = new Point(p.x, p.y);
			}
			// Если есть активный материал, то грань заносится в массив для последующего формирования поверхности в объекте
			if (currentMaterialName != null) {
				materialFaces.push(face);
			}
		}
		
		/**
		 * Загрузка библиотек материалов.
		 * 
		 * @param parts массив, содержащий имена файлов материалов, начиная с элемента с индексом 1
		 */
		private function storeMaterialFileNames(parts:Array):void {
			for (var i:int = 1; i < parts.length; i++) {
				materialFileNames.push(parts[i]);
			}
		}

		/**
		 * Установка нового текущего материала.
		 * 
		 * @param parts массив, во втором элементе которого содержится имя материала
		 */
		private function setNewMaterial(parts:Array):void {
			// Все сохранённые грани добавляются в соответствующую поверхность текущего объекта
			moveFacesToSurface();
			// Установка нового текущего материала
			currentMaterialName = parts[1];
		}
		
		/**
		 * Добавление всех граней с текущим материалом в поверхность с идентификатором, совпадающим с именем материала. 
		 */
		private function moveFacesToSurface():void {
			if (currentMaterialName != null && materialFaces.length > 0) {
				if (currentObject.hasSurface(currentMaterialName)) {
					// При наличии поверхности с таким идентификатором, грани добавляются в неё
					var surface:Surface = currentObject.getSurfaceById(currentMaterialName);
					for each (var face:* in materialFaces) {
						surface.addFace(face);
					}
				} else {
					// При отсутствии поверхности с таким идентификатором, создатся новая поверхность
					currentObject.createSurface(materialFaces, currentMaterialName);
				}
			}
			materialFaces = [];
		}
		
		/**
		 * Загрузка материалов.
		 */
		private function loadMaterialsLibrary():void {
			if (mtlLoader == null) {
				mtlLoader = new LoaderMTL();
				mtlLoader.addEventListener(Event.COMPLETE, onMaterialFileLoadComplete);
				mtlLoader.addEventListener(IOErrorEvent.IO_ERROR, onObjLoadError);
				mtlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onObjLoadError);
			}
			materialLibrary = new Map();
			
			currentMaterialFileIndex = -1;
			loadNextMaterialFile();
		}
		
		/**
		 * Обработка успешной загрузки библиотеки материалов.
		 */
		private function onMaterialFileLoadComplete(e:Event):void {
			materialLibrary.concat(mtlLoader.library);
			// Загрузка следующего файла материалов
			loadNextMaterialFile();
		}
		
		/**
		 * 
		 */
		private function loadNextMaterialFile():void {
			currentMaterialFileIndex++;
			if (currentMaterialFileIndex == materialFileNames.length) {
				setMaterials();
				dispatchEvent(new Event(Event.COMPLETE));
			} else {
				mtlLoader.load(basePath + materialFileNames[currentMaterialFileIndex], loaderContext);
			}
		}
		
		/**
		 * Установка материалов.
		 */
		private function setMaterials():void {
			if (materialLibrary != null) {
				for (var objectKey:* in _content.children) {
					var object:Mesh = objectKey;
					for (var surfaceKey:* in object.surfaces) {
						var surface:Surface = object.surfaces[surfaceKey];
						// Поверхности имеют идентификаторы, соответствующие именам материалов
						var materialInfo:MaterialInfo = materialLibrary[surfaceKey];
						if (materialInfo != null) {
							if (materialInfo.bitmapData == null) {
								surface.material = new FillMaterial(materialInfo.color, materialInfo.alpha, blendMode);
							} else {
								surface.material = new TextureMaterial(new Texture(materialInfo.bitmapData, materialInfo.textureFileName), materialInfo.alpha, materialInfo.repeat, (materialInfo.bitmapData != LoaderMTL.stubBitmapData) ? smooth : false, blendMode, -1, 0, precision);
								transformUVs(surface, materialInfo.mapOffset, materialInfo.mapSize);
							}
						}
					}
				}
			}
		}
		
		/**
		 * Метод выполняет преобразование UV-координат текстурированных граней. В связи с тем, что в формате MRL предусмотрено
		 * масштабирование и смещение текстурной карты в UV-пространстве, а в движке такой фунциональности нет, необходимо
		 * эмулировать преобразования текстуры преобразованием UV-координат граней. Преобразования выполняются исходя из предположения,
		 * что текстурное пространство сначала масштабируется относительно центра, а затем сдвигается на указанную величину
		 * смещения.
		 * 
		 * @param surface поверхность, грани которой обрабатываюся
		 * @param mapOffset смещение текстурной карты. Значение mapOffset.x указывает смещение по U, значение mapOffset.y
		 * 		указывает смещение по V.
		 * @param mapSize коэффициенты масштабирования текстурной карты. Значение mapSize.x указывает коэффициент масштабирования
		 * 		по оси U, значение mapSize.y указывает коэффициент масштабирования по оси V. 
		 */
		private function transformUVs(surface:Surface, mapOffset:Point, mapSize:Point):void {
			for (var key:* in surface.faces) {
				var face:Face = key;
				var uv:Point = face.aUV;
				if (uv != null) {
					uv.x = 0.5 + (uv.x - 0.5 - mapOffset.x) * mapSize.x;
					uv.y = 0.5 + (uv.y - 0.5 - mapOffset.y) * mapSize.y;
					face.aUV = uv;
					uv = face.bUV;
					uv.x = 0.5 + (uv.x - 0.5 - mapOffset.x) * mapSize.x;
					uv.y = 0.5 + (uv.y - 0.5 - mapOffset.y) * mapSize.y;
					face.bUV = uv;
					uv = face.cUV;
					uv.x = 0.5 + (uv.x - 0.5 - mapOffset.x) * mapSize.x;
					uv.y = 0.5 + (uv.y - 0.5 - mapOffset.y) * mapSize.y;
					face.cUV = uv;
				}
			}
		}
	}
}