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

	/**
	 * Класс выполняет парсинг xml коллады.
	 */
	public class ParserCollada {
	
		/**
		 * Список объектов.
		 */
		public var objects:Vector.<Object3D>;
		/**
		 *  Список родителей объектов. Количество и порядок расположения элементов соответствует массиву objects.
		 *
		 * @see #objects
		 */
		public var parents:Vector.<Object3D>;
		/**
		 * Список корневых (без родителей) объектов.
		 */
		public var hierarchy:Vector.<Object3D>;
		/**
		 * Список камер.
		 */
		public var cameras:Vector.<Camera3D>;
		/**
		 * Список всех материалов.
		 *
		 * @see #textureMaterials
		 */
		public var materials:Vector.<Material>;
		/**
		 * Список текстурных материалов.
		 * Можно использовать класс MaterialLoader для загрузки текстур этих материалов.
		 *
		 * @see #materials
		 * @see MaterialLoader
		 */
		public var textureMaterials:Vector.<TextureMaterial>;
		/**
		 * Массив анимаций.
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
			hierarchy = null;
			cameras = null;
			animations = null;
			materials = null;
			textureMaterials = null;
		}
	
		/**
		 * Инициализация перед парсингом.
		 */
		private function init(data:XML):DaeDocument {
			clean();

			objects = new Vector.<Object3D>();
			parents = new Vector.<Object3D>();
			hierarchy = new Vector.<Object3D>();
			cameras = new Vector.<Camera3D>();
			animations = new Vector.<Animation>();
			materials = new Vector.<Material>();
			textureMaterials = new Vector.<TextureMaterial>();
			return new DaeDocument(data);
		}

		/**
		 * Метод распарсивает xml коллады и заполняет массивы objects, parents, hierarchy, cameras, materials, textureMaterials, animations.
		 * Для загрузки текстур сцены можно использовать класс MaterialLoader.
		 *
		 * @param data xml содержимое коллады
		 * @param baseURL адрес относительно которого выполняется поиск текстур. Путь к файлу коллады.
		 * Должен соответствовать спецификации URI. Например file:///C:/test.dae или /C:/test.dae для полных путей или test.dae, ./test.dae для относительных.
		 * @param skipEmptyObjects при значении <code>true</code> объекты без содержимого не будут создаваться без необходимости.
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
		 *			 var objects:Vector.<Object3D> = collada.hierarchy;
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
		 * @see #hierarchy
		 * @see #cameras
		 * @see #materials
		 * @see #textureMaterials
		 */
		public function parse(data:XML, baseURL:String = null, skipEmptyObjects:Boolean = true):void {
			var document:DaeDocument = init(data);
			if (document.scene != null) {
				parseNodes(document.scene.nodes, null, skipEmptyObjects);
				parseMaterials(document.materials, baseURL);
			}
		}

		/**
		 * Метод распарсивает xml коллады и заполняет массивы objects, parents, hierarchy, cameras, materials, textureMaterials, animations.
		 * Для загрузки текстур сцены можно использовать класс MaterialLoader.
		 * После парсинга для объектов, которые содержат детей, но не являются контейнерами, будут созданы контейнеры.
		 *
		 * @param data xml содержимое коллады
		 * @param baseURL адрес относительно которого выполняется поиск текстур. Путь к файлу коллады.
		 * Должен соответствовать спецификации URI. Например file:///C:/test.dae или /C:/test.dae для полных путей или test.dae, ./test.dae для относительных.
		 * @param skipEmptyObjects при значении <code>true</code> объекты без содержимого не будут создаваться без необходимости.
		 *
		 * @see MaterialLoader
		 * @see #objects
		 * @see #parents
		 * @see #hierarchy
		 * @see #cameras
		 * @see #materials
		 * @see #textureMaterials
		 */
		public function parseForAnimation(data:XML, baseURL:String = null, skipEmptyObjects:Boolean = true):void {
			var document:DaeDocument = init(data);
			if (document.scene != null) {
				parseNodesForAnimation(document.scene.nodes, null, skipEmptyObjects);
				parseMaterials(document.materials, baseURL);
			}
		}

		/**
		 * Метод распарсивает xml коллады и заполняет массивы objects, parents, hierarchy, cameras, materials, textureMaterials, animations.
		 * Для загрузки текстур сцены можно использовать класс MaterialLoader.
		 * После парсинга объекты, у которых родитель не является контейнером, будут переведены в систему координат ближайшего родительского контейнера.
		 *
		 * @param data xml содержимое коллады
		 * @param baseURL адрес относительно которого выполняется поиск текстур. Путь к файлу коллады.
		 * Должен соответствовать спецификации URI. Например file:///C:/test.dae или /C:/test.dae для полных путей или test.dae, ./test.dae для относительных.
		 * @param skipEmptyObjects при значении <code>true</code> объекты без содержимого не будут создаваться без необходимости.
		 *
		 * @see MaterialLoader
		 * @see #objects
		 * @see #parents
		 * @see #hierarchy
		 * @see #cameras
		 * @see #materials
		 * @see #textureMaterials
		 */
		public function parseForStatic(data:XML, baseURL:String = null, skipEmptyObjects:Boolean = true):void {
			var document:DaeDocument = init(data);
			if (document.scene != null) {
				parseNodesForStatic(document.scene.nodes, null, null, skipEmptyObjects);
				parseMaterials(document.materials, baseURL);
			}
		}

		/**
		 * Проверяет есть ли в иерархии объекты с заданными параметрами
		 *
		 * @param skipEmptyObjects Если установлен в <code>true</code>, будет пропускать ноды без объектов
		 * @param skinsOnly Если установлен в <code>true</code>, будут пропускаться все ноды кроме тех, что содержат скин. 
		 */
		private function hasSignifiantChildren(node:DaeNode, skipEmptyObjects:Boolean, skinsOnly:Boolean):Boolean {
			var nodes:Vector.<DaeNode> = node.nodes;
			for (var i:int = 0, count:int = nodes.length; i < count; i++) {
				var child:DaeNode = nodes[i];
				child.parse();
				if (child.skins != null) {
					return true;
				} else {
					if (!skinsOnly && !node.skinOrRootJoint && (!skipEmptyObjects || child.objects != null)) {
						return true;
					}
				}
				if (hasSignifiantChildren(child, skipEmptyObjects, skinsOnly)) {
					return true;
				}
			}
			return false;
		}

		/**
		 * Добавляет компоненты анимированного объекта в списки objects, parents, hierarchy, cameras, animations и в родительский контейнер.
		 */
		private function addObject(animatedObject:DaeAnimatedObject, parent:Object3D):Object3D {
			var object:Object3D = animatedObject.object;
			this.objects.push(object);
			this.parents.push(parent);
			if (parent == null) {
				this.hierarchy.push(object);
			}
			var container:Object3DContainer = parent as Object3DContainer;
			if (container != null) {
				container.addChild(object);
			}
			if (object is Camera3D) {
				this.cameras.push(object as Camera3D);
			}
			if (animatedObject.animation != null) {
				animatedObject.animation.updateLength();
				this.animations.push(animatedObject.animation);
			}
			return object;
		}

		/**
		 * Добавляет объекты в списки  objects, parents, hierarchy, cameras, animations и в родительский контейнер.
		 *
		 * @return первый объект
		 */
		private function addObjects(animatedObjects:Vector.<DaeAnimatedObject>, parent:Object3D):Object3D {
			var first:Object3D = addObject(animatedObjects[0], parent);
			for (var i:int = 1, count:int = animatedObjects.length; i < count; i++) {
				addObject(animatedObjects[i], parent);
			}
			return first;
		}


		private function parseNodes(nodes:Vector.<DaeNode>, parent:Object3D, skipEmptyObjects:Boolean,  skinsOnly:Boolean = false):void {
			for (var i:int = 0, count:int = nodes.length; i < count; i++) {
				var node:DaeNode = nodes[i];
				node.parse();
				var object:Object3D;
				if (node.skins != null) {
					object = addObjects(node.skins, parent);
				} else {
					if (!node.skinOrRootJoint && !skinsOnly) {
						if (node.objects != null) {
							object = addObjects(node.objects, parent);
						} else {
							if (!skipEmptyObjects) {
								object = new Object3D();
								object.name = node.name;
								object = addObject(node.applyAnimation(node.applyTransformations(object)), parent);
							}
						}
					}
				}
				// Если это кость или скин, парсим только скины у детей
				skinsOnly = skinsOnly || node.skinOrRootJoint;
				if (object == null) {
					if (hasSignifiantChildren(node, skipEmptyObjects,  skinsOnly)) {
						object = new Object3D();
						object.name = node.name;
						parseNodes(node.nodes, addObject(node.applyAnimation(node.applyTransformations(object)), parent), skipEmptyObjects, skinsOnly);
					}
				} else {
					parseNodes(node.nodes, object, skipEmptyObjects, skinsOnly);
				}
			}
		}

		private function parseNodesForAnimation(nodes:Vector.<DaeNode>, parent:Object3DContainer, skipEmptyObjects:Boolean, skinsOnly:Boolean = false):void {
			for (var i:int = 0, count:int = nodes.length; i < count; i++) {
				var node:DaeNode = nodes[i];
				node.parse();
				var container:Object3DContainer = null;
				if (node.skins != null) {
					// Основная кость скина
					addObjects(node.skins, parent);
				} else {
					if (!node.skinOrRootJoint && !skinsOnly) {
						if (node.objects != null) {
							container = addObjects(node.objects, parent) as Object3DContainer;
						} else {
							// Нет объектов в ноде
							if (!skipEmptyObjects) {
								var object:Object3D = new Object3D();
								object.name = node.name;
								addObject(node.applyAnimation(node.applyTransformations(object)), parent);
							}
						}
					}
				}
				// Парсим детей
				// Если это кость или скин, парсим только скины у детей
				skinsOnly = skinsOnly || node.skinOrRootJoint;
				if (container == null) {
					if (hasSignifiantChildren(node, skipEmptyObjects, skinsOnly)) {
						container = new Object3DContainer();
						if (node.name != null) {
							container.name = node.name + "-container";
						}
						addObject(node.applyAnimation(node.applyTransformations(container)), parent);
						parseNodesForAnimation(node.nodes, container, skipEmptyObjects, skinsOnly);
					}
				} else {
					parseNodesForAnimation(node.nodes, container, skipEmptyObjects, skinsOnly);
				}
			}
		}

		private function appendMatrixToObjects(objects:Vector.<DaeAnimatedObject>, append:Matrix3D):void {
			for (var i:int = 0, count:int = objects.length; i < count; i++) {
				var object:Object3D = objects[i].object;
				var matrix:Matrix3D = object.getMatrix();
				matrix.append(append);
				object.setMatrix(matrix);
			}
		}

		private function parseNodesForStatic(nodes:Vector.<DaeNode>, parent:Object3DContainer, toParentMatrix:Matrix3D, skipEmptyObjects:Boolean, skinsOnly:Boolean = false):void {
			for (var i:int = 0, count:int = nodes.length; i < count; i++) {
				var node:DaeNode = nodes[i];
				node.parse();
				var container:Object3DContainer = null;
				if (node.skins != null) {
					if (toParentMatrix != null) {
						appendMatrixToObjects(node.skins, toParentMatrix);
					}
					// Основная кость скина
					addObjects(node.skins, parent);
				} else {
					if (!node.skinOrRootJoint && !skinsOnly) {
						if (node.objects != null) {
							if (toParentMatrix != null) {
								appendMatrixToObjects(node.skins, toParentMatrix);
							}
							container = addObjects(node.objects, parent) as Object3DContainer;
						} else {
							// Нет объектов в ноде
							if (!skipEmptyObjects) {
								var object:Object3D = new Object3DContainer();
								object.name = node.name;
								addObject(node.applyAnimation(node.applyTransformations(object, null, toParentMatrix)), parent);
							}
						}
					}
				}
				// Парсим детей
				// Если это кость или скин, парсим только скины у детей
				skinsOnly = skinsOnly || node.skinOrRootJoint;
				if (container == null) {
					if (toParentMatrix == null) {
						toParentMatrix = node.getMatrix();
					} else {
						toParentMatrix.append(node.getMatrix());
					}
					parseNodesForStatic(node.nodes, parent, toParentMatrix, skipEmptyObjects, skinsOnly);
				} else {
					parseNodesForStatic(node.nodes, container, null, skipEmptyObjects, skinsOnly);
				}
			}
		}

		private function parseMaterials(materials:Object, baseURL:String):void {
			var tmaterial:TextureMaterial;
			for each (var material:DaeMaterial in materials) {
				if (material.used) {
					material.parse();
					this.materials.push(material.material);
					if (material.material is TextureMaterial) {
						tmaterial = material.material as TextureMaterial;
						if (tmaterial.texture == null) {
							// Филлы тоже задаются текстурным материалом на данный момент
							textureMaterials.push(tmaterial);
						}
					}
				}
			}
			if (baseURL != null) {
				baseURL = fixURL(baseURL);
				var end:int = baseURL.lastIndexOf("/");
				var base:String = (end < 0) ? "" : baseURL.substring(0, end + 1);
				for each (tmaterial in textureMaterials) {
					if (tmaterial.diffuseMapURL != null) {
						tmaterial.diffuseMapURL = resolveURL(fixURL(tmaterial.diffuseMapURL), base);
					}
					if (tmaterial.opacityMapURL != null) {
						tmaterial.opacityMapURL = resolveURL(fixURL(tmaterial.opacityMapURL), base);
					}
				}
			} else {
				for each (tmaterial in textureMaterials) {
					if (tmaterial.diffuseMapURL != null) {
						tmaterial.diffuseMapURL = fixURL(tmaterial.diffuseMapURL);
					}
					if (tmaterial.opacityMapURL != null) {
						tmaterial.opacityMapURL = fixURL(tmaterial.opacityMapURL);
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
	
		/**
		 * Возвращает объект из массива object по его имени.
		 */
		public function getObjectByName(name:String):Object3D {
			for (var i:int = 0, count:int = objects.length; i < count; i++) {
				var object:Object3D = objects[i];
				if (object.name == name) {
					return object;
				}
			}
			return null;
		}

		/**
		 * Возвращает анимацию из массива animation по объекту на который она ссылается. 
		 */
		public function getAnimationByObject(object:Object3D):Animation {
			for (var i:int = 0, count:int = animations.length; i < count; i++) {
				var animation:Animation = animations[i];
				if (animation.object == object) {
					return animation;
				}
			}
			return null;
		}

	}
}
