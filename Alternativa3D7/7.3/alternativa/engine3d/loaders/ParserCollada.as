package alternativa.engine3d.loaders {
	import alternativa.engine3d.animation.Animation;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Object3DContainer;
	import alternativa.engine3d.loaders.collada.DaeAnimatedObject;
	import alternativa.engine3d.loaders.collada.DaeDocument;
	import alternativa.engine3d.loaders.collada.DaeMaterial;
	import alternativa.engine3d.loaders.collada.DaeNode;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.TextureMaterial;

	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;

	/**
	 * Класс выполняет парсинг xml коллады.
	 */
	public class ParserCollada {
	
		/**
		 * Список объектов из коллады
		 */
		public var objects:Vector.<Object3D>;
		/**
		 *  Список родителей объектов из коллады. Количество и порядок расположения элементов соответствует массиву objects.
		 *
		 * @see #objects
		 */
		public var parents:Vector.<Object3D>;
		/**
		 * Список камер из коллады
		 */
		public var cameras:Vector.<Camera3D>;
		/**
		 * Список всех материалов из коллады
		 *
		 * @see #textureMaterials
		 */
		public var materials:Vector.<Material>;
		/**
		 * Список текстурных материалов из коллады.
		 * Можно использовать класс MaterialLoader для загрузки текстур этих материалов.
		 *
		 * @see #materials
		 * @see MaterialLoader
		 */
		public var textureMaterials:Vector.<TextureMaterial>;
	
	//	/**
	//	 * Корневые объекты. Массив доступен после создания иерархии.
	//	 * @see #makeHierarchyForStatic()
	//	 * @see #makeHierarchyForAnimation()
	//	 */
	//	public var hierarchy:Vector.<Object3D>;
		
		/**
		 * Массив анимационных контроллеров. Количество и порядок расположения элементов соответствует массиву objects.
		 */
		public var animations:Vector.<Animation>;
	
		/**
		 * Создает экземпляр парсера
		 */
		public function ParserCollada() {
		}
	
		/**
		 * Зачищает все ссылки на внешние объекты.
		 */
		public function clean():void {
			objects = null;
			parents = null;
			cameras = null;
			materials = null;
			textureMaterials = null;
	//		hierarchy = null;
			animations = null;
		}
	
		/**
		 * Создает для объектов из массивов objects и parents родительские связи,
		 * считает матрицу объектам в координатах родительского контейнера и заполняет массив корневых объектов.
		 * Значения в массивах objects, parents и animations обновляются.
		 *
		 * @param skipObject3Ds при значении <code>true</code> объекты типа Object3D не будут добавлены в родительский контейнер.
		 *
		 * @return массив корневых объектов (контейнеры и объекты без родителей)
		 */
		public function makeHierarchyForStatic(skipObject3Ds:Boolean = true):Vector.<Object3D> {
			var hierarchy:Vector.<Object3D> = new Vector.<Object3D>();
			var i:int;
			var count:int = objects.length;
			for (i = 0; i < count; i++) {
				var object:Object3D = objects[i];
				var parent:Object3D = parents[i];
				if (parent != null) {
					if (parent is Object3DContainer) {
						(parent as Object3DContainer).addChild(object);
					} else {
						var mat:Matrix3D = object.getMatrix();
						var pmat:Matrix3D = parent.getMatrix();
						mat.append(pmat);
						object.setMatrix(mat);
						if ((object as Object).constructor != Object3D || !skipObject3Ds) {
							var container:Object3DContainer = findParentContainer(parent);
							if (container != null) {
								parents[i] = container;
								container.addChild(object);
							} else {
								parents[i] = null;
								hierarchy.push(object);
							}
						} else {
							objects[i] = null;
						}
					}
				} else {
					if ((object as Object).constructor != Object3D || !skipObject3Ds) {
						hierarchy.push(object);
					} else {
						objects[i] = null;
					}
				}
			}
			if (skipObject3Ds) {
				// Удаляем пропущенные объекты
				var j:int;
				for (i = 0, j = 0; i < count; i++) {
					if (objects[i] != null) {
						objects[j] = objects[i];
						parents[j] = parents[i];
						animations[j] = animations[i];
						j++;
					}
				}
				objects.length = j;
				parents.length = j;
				animations.length = j;
			}
			return hierarchy;
		}
	
		/**
		 * Создает для объектов из массивов objects и parents родительские связи,
		 * создает контейнеры для объектов у которых родитель не является контейнером.
		 * Значения в массивах objects, parents и animations обновляются.
		 *
		 * @return массив корневых объектов (контейнеры и объекты без родителей)
		 */
		public function makeHierarchyForAnimation():Vector.<Object3D> {
			var hierarchy:Vector.<Object3D> = new Vector.<Object3D>();
			// Словарь замены парентов на контейнеры
			var parentReplace:Dictionary = new Dictionary();
			var i:int;
			var count:int = objects.length;
			for (i = 0; i < count; i++) {
				var object:Object3D = objects[i];
				var parent:Object3D = parents[i];
				if (parent != null) {
					if (parent is Object3DContainer) {
						(parent as Object3DContainer).addChild(object);
					} else {
						var container:Object3DContainer = parentReplace[parent];
						if (container == null) {
							container = new Object3DContainer();
							if (parent.name != null) {
								container.name = parent.name + "-container";
							}
							container.setMatrix(parent.getMatrix());
							parentReplace[parent] = container;
							objects.push(container);
							if (parent.parent == null) {
								hierarchy.push(container);
								parents.push(null);
							} else {
								parent.parent.addChild(container);
								parents.push(parent.parent);
							}
							animations.push(null);
						}
						container.addChild(object);
						parents[i] = container;
					}
				} else {
					hierarchy.push(object);
				}
			}
			return hierarchy;
		}
	
		/**
		 * @private
		 */
		private function findParentContainer(object:Object3D):Object3DContainer {
			var index:int = objects.indexOf(object);
			var parent:Object3D;
			while ((parent = parents[index]) != null) {
				if (parent is Object3DContainer) {
					return Object3DContainer(parent);
				}
				index = objects.indexOf(parent);
			}
			return null;
		}
	
		/**
		 * Метод распарсивает xml коллады и заполняет массивы objects, parents, cameras, materials, textureMaterials, animations.
		 * Для загрузки текстур сцены можно использовать класс MaterialLoader.
		 *
		 * @param data xml содержимое коллады
		 * @param baseURL адрес относительно которого выполняется поиск текстур. Путь к файлу коллады.
		 * Должен соответствовать спецификации URI. Например file:///C:/test.dae или /C:/test.dae для полных путей или test.dae, ./test.dae для относительных.
		 *
		 * @example Пример загрузки файла коллады, парсинга, загрузки текстур и создания иерархии:
		 * <listing version="3.0">package {
			 *
		 *	import alternativa.engine3d.containers.AverageZContainer;
		 *	import alternativa.engine3d.core.Object3D;
		 *	import alternativa.engine3d.core.Object3DContainer;
		 *	import alternativa.engine3d.loaders.MaterialLoader;
		 *	import alternativa.engine3d.loaders.ParserCollada;
		 *
		 *	import flash.display.Sprite;
		 *	import flash.events.Event;
		 *	import flash.geom.Matrix3D;
		 *	import flash.net.URLLoader;
		 *	import flash.net.URLRequest;
		 *
		 *	public class ColladaExample extends Sprite {
			 *
		 *		private const modelURL:String = "model.dae";
		 *
		 *		private var loader:URLLoader;
		 *		private var materialLoader:MaterialLoader;
		 *
		 *		public function ColladaExample() {
			 *			loader = new URLLoader();
		 *			loader.addEventListener(Event.COMPLETE, onModelLoad);
		 *			loader.load(new URLRequest(modelURL));
		 *		}
		 *
		 *		private function onModelLoad(e:Event):void {
			 *			var collada:ParserCollada = new ParserCollada();
		 *			collada.parse(XML(loader.data), modelURL);
		 *
		 *			var container:AverageZContainer = new AverageZContainer();
		 *			 // Создаем иерархию объектов
		 *			 var objects:Vector.<Object3D> = collada.makeHierarchy();
		 *			 for (var o:int = 0, count:int = objects.length; o < count; o++) {
			 *				 container.addChild(objects[o]);
		 *			 }
		 *
		 *			// Начинаем загрузку текстур материалов
		 *			materialLoader = new MaterialLoader();
		 *			materialLoader.addEventListener(Event.COMPLETE, onMaterialsLoad);
		 *			materialLoader.load(collada.textureMaterials);
		 *		}
		 *
		 *		private function onMaterialsLoad(e:Event):void {
			 *			trace("Loading complete");
		 *		}
		 *
		 *	}}</listing>
		 *
		 * @see MaterialLoader
		 * @see #objects
		 * @see #parents
		 * @see #cameras
		 * @see #materials
		 * @see #textureMaterials
		 */
		public function parse(data:XML, baseURL:String = null):void {
			clean();
			//			var t:int = getTimer();
			var document:DaeDocument = new DaeDocument(data);
			//			t = getTimer() - t;
			//			trace("TIME INIT:", t);
			objects = new Vector.<Object3D>();
			parents = new Vector.<Object3D>();
			cameras = new Vector.<Camera3D>();
			materials = new Vector.<Material>();
			animations = new Vector.<Animation>();
			textureMaterials = new Vector.<TextureMaterial>();
			if (document.scene != null) {
				//				t = getTimer();
				parseNodes(document.scene.nodes);
				parseMaterials(document.materials);
				//				t = getTimer() - t;
				//				trace("TIME PARSING:", t);
			}
	
			var material:TextureMaterial;
			if (baseURL != null) {
				baseURL = fixURL(baseURL);
				var end:int = baseURL.lastIndexOf("/");
				var base:String = (end < 0) ? "" : baseURL.substring(0, end + 1);
				for each (material in textureMaterials) {
					if (material.diffuseMapURL != null) {
						material.diffuseMapURL = resolveURL(fixURL(material.diffuseMapURL), base);
					}
					if (material.opacityMapURL != null) {
						material.opacityMapURL = resolveURL(fixURL(material.opacityMapURL), base);
					}
				}
			} else {
				for each (material in textureMaterials) {
					if (material.diffuseMapURL != null) {
						material.diffuseMapURL = fixURL(material.diffuseMapURL);
					}
					if (material.opacityMapURL != null) {
						material.opacityMapURL = fixURL(material.opacityMapURL);
					}
				}
			}
	
		}
	
		private function parseNodes(nodes:Vector.<DaeNode>, parent:Object3D = null):void {
			for (var i:int = 0, count:int = nodes.length; i < count; i++) {
				var node:DaeNode = nodes[i];
				var j:int;
				var num:int;
				node.parse();
				var animatedObjects:Vector.<DaeAnimatedObject>;
				var animatedObject:DaeAnimatedObject;
				var object:Object3D;
				if (node.skins != null) {
					// Рутовая кость скина
					animatedObjects = node.skins;
					num = animatedObjects.length;
					for (j = 0; j < num; j++) {
						animatedObject = animatedObjects[j];
						object = animatedObject.object;
						this.objects.push(object);
						this.parents.push(parent);
						this.animations.push(animatedObject.animation);
					}
				} else {
					if (!node.skiped) {
						animatedObjects = node.objects;
						num = animatedObjects.length;  // >= 1
						for (j = 0; j < num; j++) {
							animatedObject = animatedObjects[j];
							object = animatedObject.object;
							this.objects.push(object);
							this.parents.push(parent);
							if (object is Camera3D) {
								this.cameras.push(object as Camera3D);
							}
							this.animations.push(animatedObject.animation);
						}
						parseNodes(node.nodes, animatedObjects[0].object);
					}
				}
			}
		}
	
		private function parseMaterials(materials:Object):void {
			for each (var material:DaeMaterial in materials) {
				if (material.used) {
					material.parse();
					this.materials.push(material.material);
					if (material.material is TextureMaterial) {
						var tmaterial:TextureMaterial = material.material as TextureMaterial;
						if (tmaterial.texture == null) {
							// Филлы тоже задаются текстурным материалом на данный момент
							textureMaterials.push(tmaterial);
						}
					}
				}
			}
		}
	
		/**
		 * @private
		 * Приводит урл к следующему виду:
		 * Обратные слеши в пути заменяет на прямые
		 * Три прямых слеша после схемы file:
		 */
		private function fixURL(url:String):String {
			var pathStart:int = url.indexOf("://");
			pathStart = (pathStart < 0) ? 0 : pathStart + 3;
			var pathEnd:int = url.indexOf("?", pathStart);
			pathEnd = (pathEnd < 0) ? url.indexOf("#", pathStart) : pathEnd;
			var path:String = url.substring(pathStart, (pathEnd < 0) ? 0x7FFFFFFF : pathEnd);
			path = path.replace(/\\/g, "/");
			var fileIndex:int = url.indexOf("file://");
			if (fileIndex >= 0) {
				if (url.charAt(pathStart) == "/") {
					return "file://" + path + ((pathEnd >= 0) ? url.substring(pathEnd) : "");
				}
				return "file:///" + path + ((pathEnd >= 0) ? url.substring(pathEnd) : "");
			}
			return url.substring(0, pathStart) + path + ((pathEnd >= 0) ? url.substring(pathEnd) : "");
		}
	
		//		public function resolveTest(url:String, base:String):void {
		//			trace('was::"' + base + '" "' + url + '"');
		//			trace('now::"' + resolveURL(fixURL(url), fixURL(base)) + '"');
		//		}
	
		/**
		 * @private
		 */
		private function mergePath(path:String, base:String, relative:Boolean = false):String {
			var baseParts:Array = base.split("/");
			var parts:Array = path.split("/");
			for (var i:int = 0, count:int = parts.length; i < count; i++) {
				var part:String = parts[i];
				if (part == "..") {
					var basePart:String = baseParts.pop();
					while (basePart == "." || basePart == "" && basePart != null) basePart = baseParts.pop();
					if (relative) {
						if (basePart == "..") {
							baseParts.push("..", "..");
						} else if (basePart == null) {
							baseParts.push("..");
						}
					}
				} else {
					baseParts.push(part);
				}
			}
			return baseParts.join("/");
		}
	
		/**
		 * @private
		 * Конвертирует относительные пути в полные
		 */
		private function resolveURL(url:String, base:String):String {
			// http://labs.apache.org/webarch/uri/rfc/rfc3986.html
			if (url.charAt(0) == "." && url.charAt(1) == "/") {
				// Файл в той же папке
				return base + url.substring(2);
			} else if (url.charAt(0) == "/") {
				// Полный путь
				return url;
			} else if (url.charAt(0) == "." && url.charAt(1) == ".") {
				// Выше по уровню
				var queryAndFragmentIndex:int = url.indexOf("?");
				queryAndFragmentIndex = (queryAndFragmentIndex < 0) ? url.indexOf("#") : queryAndFragmentIndex;
				var path:String;
				var queryAndFragment:String;
				if (queryAndFragmentIndex < 0) {
					queryAndFragment = "";
					path = url;
				} else {
					queryAndFragment = url.substring(queryAndFragmentIndex);
					path = url.substring(0, queryAndFragmentIndex);
				}
				// Делим базовый урл на составные части
				var bPath:String;
				var bSlashIndex:int = base.indexOf("/");
				var bShemeIndex:int = base.indexOf(":");
				var bAuthorityIndex:int = base.indexOf("//");
				if (bAuthorityIndex < 0 || bAuthorityIndex > bSlashIndex) {
					if (bShemeIndex >= 0 && bShemeIndex < bSlashIndex) {
						// Присутствует схема, нет домена
						var bSheme:String = base.substring(0, bShemeIndex + 1);
						bPath = base.substring(bShemeIndex + 1);
						if (bPath.charAt(0) == "/") {
							return bSheme + "/" + mergePath(path, bPath.substring(1), false) + queryAndFragment;
						} else {
							return bSheme + mergePath(path, bPath, false) + queryAndFragment;
						}
					} else {
						// Нет схемы, нет домена
						if (base.charAt(0) == "/") {
							return "/" + mergePath(path, base.substring(1), false) + queryAndFragment;
						} else {
							return mergePath(path, base, true) + queryAndFragment;
						}
					}
				} else {
					bSlashIndex = base.indexOf("/", bAuthorityIndex + 2);
					var bAuthority:String;
					if (bSlashIndex >= 0) {
						bAuthority = base.substring(0, bSlashIndex + 1);
						bPath = base.substring(bSlashIndex + 1);
						return bAuthority + mergePath(path, bPath, false) + queryAndFragment;
					} else {
						bAuthority = base;
						return bAuthority + "/" + mergePath(path, "", false);
					}
				}
			}
			var shemeIndex:int = url.indexOf(":");
			var slashIndex:int = url.indexOf("/");
			if (shemeIndex >= 0 && (shemeIndex < slashIndex || slashIndex < 0)) {
				// Содержит схему
				return url;
			}
			return base + "/" + url;
		}
	
		public function getObjectByName(name:String):Object3D {
			for (var i:int = 0, count:int = objects.length; i < count; i++) {
				var object:Object3D = objects[i];
				if (object.name == name) {
					return object;
				}
			}
			return null;
		}
	
	}
}
