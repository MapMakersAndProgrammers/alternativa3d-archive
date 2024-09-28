package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.engine3d.display.Canvas;
	import alternativa.engine3d.display.DisplayItem;
	import alternativa.engine3d.display.Skin;
	import alternativa.engine3d.display.View;
	import alternativa.engine3d.sorting.Node;
	import alternativa.types.Matrix3D;
	import alternativa.types.Set;
	import alternativa.utils.MathUtils;
	
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	use namespace alternativa3d;
	
	public class Camera3D extends Object3D {

		// Инкремент количества объектов
		private static var counter:uint = 0;
		
		/**
		 * @private
		 * Поле зрения
		 */
		alternativa3d var _fov:Number = MathUtils.DEG90;
		/**
		 * @private
		 * Фокусное расстояние
		 */
		alternativa3d var focalLength:Number;
		/**
		 * @private
		 * Перспективное искажение
		 */
		alternativa3d var focalDistortion:Number;
		
		/**
		 * @private
		 * Вид из камеры
		 */
		alternativa3d var _view:View;

		//Половина ширины вьюпорта
		private var halfWidth:Number;
		
		//Половина высоты вьюпорта
		private var halfHeight:Number;
		
		/**
		 * @private
		 * Режим отрисовки
		 */
		alternativa3d var _orthographic:Boolean = false;
		
		/**
		 * @private
		 * Матрица перевода из системы координат камеры в глобальную
		 */		
		alternativa3d var globalMatrix:Matrix3D = new Matrix3D();
		/**
		 * @private
		 * Матрица перевода из глобальной системы координат в систему камеры
		 */		
		alternativa3d var inverseGlobalMatrix:Matrix3D = new Matrix3D();
		
		// Масштаб
		alternativa3d var _zoom:Number = 1;
		
		// Реестр отрисованных канвасов
		private var canvases:Dictionary = new Dictionary();
		
		// Список канвасов на удаление
		private var canvasesToRemove:Set = new Set();
		
		/**
		 * Создание экземпляра камеры.
		 * 
		 * @param name имя экземпляра
		 */
		public function Camera3D(name:String = null) {
			super(name);
		}
		
		override protected function transform():void {
			super.transform();
			// Если есть вьюпорт
			if (_view != null) {
				// Помечаем камеру на глобальную трансформацию
				_scene.camerasToRender[this] = true;
			}
		}

		override protected function move():void {
			super.move();
			// Если есть вьюпорт
			if (_view != null) {
				// Помечаем камеру на глобальную трансформацию
				_scene.camerasToRender[this] = true;
			}
		}
		
		alternativa3d function render():void {
			trace(this, "render");
			
			// Если у пространства сцены есть материал
			if (_scene._space._material != null) {

				// Расчитываем половины ширины и высоты вьюпорта
				halfWidth = _view._width*0.5;
				halfHeight = _view._height*0.5;
				
				// Если перспектива
				if (!_orthographic) {
					// Вычисляем фокусное расстояние
					focalLength = Math.sqrt(halfWidth*halfWidth + halfHeight*halfHeight)/Math.tan(0.5*_fov);
					// Вычисляем минимальное (однопиксельное) искажение перспективной коррекции
					focalDistortion = 1/(focalLength*focalLength);
				}
				
				// Расчитываем глобальную трансформацию
				globalMatrix.copy(spaceMatrix);
				globalMatrix.combine(space.globalMatrix);
				
				// Расчитываем инверсную глобальную трансформацию
				inverseGlobalMatrix.copy(globalMatrix);
				inverseGlobalMatrix.invert();
				
				// Создание канваса пространства сцены, если его ещё нет
				if (_view.canvas == null) {
					_view.canvas = Canvas.create();
					_view.addChild(_view.canvas);
					_view.canvas.x = halfWidth;
					_view.canvas.y = halfHeight;
					canvases[_scene._space] = _view.canvas;
				}
				
				// Отрисовка пространства сцены
				renderSpace(_scene._space, _view.canvas);
				
			} else {
				// Зачищаем канвас вьюпорта
				removeViewCanvas();
			}
			
			// Снимаем пометки об отрисовке
			delete _scene.camerasToRender[this];
		}
		
		private function renderSpace(space:Space, canvas:Canvas):void {
			trace("render space", space);
			
			// Если пространство сцены
			if (space.space == null) {
				// Берём в качестве матриц пространства глобальные
				space.inverseCameraMatrix.copy(globalMatrix);
				space.cameraMatrix.copy(inverseGlobalMatrix);
			} else {
				// Считаем матрицу перевода из системы координат пространства в систему камеры
				space.cameraMatrix.copy(space.globalMatrix)
				space.cameraMatrix.combine(inverseGlobalMatrix);
				// Считаем матрицу перевода из системы координат камеры в систему пространства
				space.inverseCameraMatrix.copy(space.cameraMatrix);
				space.inverseCameraMatrix.invert();
			}

			// Направление камеры в пространстве
			space.direction.x = space.inverseCameraMatrix.c;
			space.direction.y = space.inverseCameraMatrix.g;
			space.direction.z = space.inverseCameraMatrix.k;
			
			// Расчёт направления и плоскостей отсечения в пространстве
			if (_orthographic) {
				// Масштабируем матрицу камеры
				space.cameraMatrix.scale(_zoom, _zoom, _zoom);
				// Расчёт плоскостей отсечения
				space.calculateOrthographicPlanes(halfWidth, halfHeight, _zoom)
			} else {
				// Нормализуем направление камеры
				space.direction.normalize();
				// Расчёт плоскостей отсечения
				space.calculatePerspectivePlanes(halfWidth, halfHeight, focalLength)
			}

			// Отрисовка BSP-дерева
			/*if (space.root != null) {
				canvas.previousItem = null;
				canvas.currentItem = canvas.firstItem;
				renderNode(space.root, canvas);
			}*/
			
			// Удаление помеченных канвасов
			for (var key:* in canvasesToRemove) {
				var c:Canvas = key;
				var parent:DisplayObjectContainer = c.parent;
				// Если есть объект перед канвасом
				if (c.previous != null) {
					// Устанавливаем ему ссылку на следующий
					c.previous.next = c.next;
				} else {
					// Устанавливаем первый объект в родительском канвасе
					(parent as Canvas).firstItem = c.next;
				}
				// Если после канваса есть канвас
				if (c.next is Canvas) {
					(c.next as Canvas).previous = c.previous;
				}
				// Удаляем из списка отображения
				parent.removeChild(c);
				// Отправляем на реиспользование
				Canvas.destroy(c);
			}

			// Удаление лишних отрисовочных объектов
			if (canvas.previous != null) {
				// Обрываем список
				canvas.previous.next = null;
			}
			var item:DisplayItem = canvas.currentItem;
			while (item != null) {
				// Сохраняем следующий
				var next:DisplayItem = item.next;
				// Удаляем из канваса
				canvas.removeChild(item);
				// Удаляем
				(item is Skin) ? Skin.destroy(item as Skin) : Canvas.destroy(item as Canvas);
				// Следующий устанавливаем текущим
				item = next;
			}
		}
		
		private function renderNode(node:Node, container:Canvas):void {
/*			
			var primitives:Set;
			if (node is DistanceNode) {
				primitives = (node as DistanceNode).primitives;
				for (var key:* in primitives) {
					// Если точечный примитив грани
					if (key is FaceDistancePrimitive) {
						var face:Face = (key as FaceDistancePrimitive).face;
						var skin:Skin;
						// Пропускаем канвасы и помечаем их на удаление
						while (container.currentItem is Canvas) {
							// Помечаем на удаление
							canvasesToRemove[container.currentItem] = true;
							// Переключаемся на следующий объект
							container.previousItem = container.currentItem;
							container.currentItem = container.currentItem.next;
						}
						
						// Если есть текущий объект
						if (container.currentItem != null) {
							// Берём текущий скин 
							skin = container.currentItem as Skin;
							// Переключаемся на следующий объект
							container.previousItem = skin;
							container.currentItem = skin.next;
						} else {
							// Создаём новый скин
							skin = Skin.create();
							// Вставляем скин в конец
				 			container.addChild(skin);
				 			
				 			// Обновление списка в текущем канвасе
				 			if (container.previousItem != null) {
				 				container.previousItem.next = skin;
				 			} else {
				 				container.firstItem = skin;
				 			}
				 			
				 			// Переключаемся на следующий объект
							container.previousItem = skin;
						}
						
						// Отрисовка скина
						// ...
						skin.graphics.beginFill(0xFFFF00, 0.3);
						skin.graphics.drawCircle(0, 0, Math.random()*100);
						
					} else {
						// Если примитив объекта
						if (key is SpriteDistancePrimitive) {
							
						} else {
							// Если примитив пространства
							var space:Space = (key as SpaceDistancePrimitive).space;
							var canvas:Canvas;
							
							// Если канвас есть в реестре
							if ((canvas = canvases[space]) != null) {
								// Если канвасы не совпадают
								if (canvas != container.currentItem) {
									// Разорвать связи с соседними объектами
									// Если есть объект перед канвасом
									if (canvas.previous != null) {
										// Устанавливаем ему ссылку на следующий
										canvas.previous.next = canvas.next;
									} else {
										// Устанавливаем первый объект в родительском канвасе
										(canvas.parent as Canvas).firstItem = canvas.next;
									}
									// Если после канваса есть канвас
									if (canvas.next is Canvas) {
										(canvas.next as Canvas).previous = canvas.previous;
									}
									
									// Создать новые связи
						 			// Установка связи со следующим объектом
						 			canvas.next = container.currentItem;
						 			// Установка связи с предыдущим объектом
						 			canvas.previous = container.previousItem;
						 			
						 			// Обновление списка в текущем канвасе
						 			if (container.previousItem != null) {
						 				container.previousItem.next = canvas;
						 			} else {
						 				container.firstItem = canvas;
						 			}
						 			
									// Если есть текущий объект
									if (container.currentItem != null) {
										// Вставляем канвас перед текущим объектом
							 			container.addChildAt(canvas, container.getChildIndex(container.currentItem));
							 			if (container.currentItem is Canvas) {
							 				(container.currentItem as Canvas).previous = canvas;
							 			}
									} else {
										// Вставляем канвас в конец
							 			container.addChild(canvas);
									}
									
						 			// Переключаемся на следующий объект
						 			container.previousItem = canvas;
						 			
						 			// Удалить канвас из списка на удаление
						 			delete canvasesToRemove[canvas];
								} else {
						 			// Переключаемся на следующий объект
						 			container.previousItem = canvas;
						 			container.currentItem = canvas.next;
								}
							} else {
								// Создаём новый канвас
								canvas = new Canvas();
								// Сохраняем его в реестр
								canvases[space] = canvas;
							
								// Создать связи
					 			// Установка связи со следующим объектом
					 			canvas.next = container.currentItem;
					 			// Установка связи с предыдущим объектом
					 			canvas.previous = container.previousItem;
					 			
					 			// Обновление списка в текущем канвасе
					 			if (container.previousItem != null) {
					 				container.previousItem.next = canvas;
					 			} else {
					 				container.firstItem = canvas;
					 			}
					 			
								// Если есть текущий объект
								if (container.currentItem != null) {
									// Вставляем канвас перед текущим объектом
						 			container.addChildAt(canvas, container.getChildIndex(container.currentItem));
						 			if (container.currentItem is Canvas) {
						 				(container.currentItem as Canvas).previous = canvas;
						 			}
								} else {
									// Вставляем канвас в конец
						 			container.addChild(canvas);
								}
								
					 			// Переключаемся на следующий объект
					 			container.previousItem = canvas;
							}
							
							// Отрисовка пространства в канвас
							renderSpace(space, canvas);
						}
					}
				}
			} else {
				
			}
*/			
		}

		alternativa3d function updateSpace(space:Space):void {
			trace(this, "updateSpace", space);
			
			
			
		}

		alternativa3d function updateSpaceMaterial(space:Space):void {
			trace(this, "updateSpaceMaterial", space);
			
			// Если канвас нарисован, перерисовать его
			var canvas:Canvas;
			if ((canvas = canvases[space]) != null) {
				space._material.draw(canvas);
			}
		}
		
		
		override protected function addToScene():void {
			super.addToScene();

			// Добавляем камеру в реестр сцены
			if (_view != null) {
				_scene.cameras[this] = true;
			}
		}

		override protected function removeFromScene():void {
			super.removeFromScene();
			
			// Если у камеры есть вьюпорт			
			if (_view != null) {
				
				// Зачищаем канвас вьюпорта
				removeViewCanvas();
				
				// Удаляем камеру из реестра сцены
				delete _scene.cameras[this];
				
				// Удаляем все пометки в сцене
				delete _scene.camerasToRender[this];
			}
		}
		
		private function removeViewCanvas():void {
			if (_view.canvas != null) {
				_view.removeChild(_view.canvas);
				Canvas.destroy(_view.canvas);
				_view.canvas = null;
				delete canvases[_scene._space];
			}
		}
		
		/**
		 * Поле вывода, в котором происходит отрисовка камеры.
		 */
		public function get view():View {
			return _view;
		}

		/**
		 * @private
		 */
		public function set view(value:View):void {
			if (value != _view) {
				// Если был вьюпорт
				if (_view != null) {
					// Зачищаем канвас вьюпорта
					removeViewCanvas();
					// Удалить в нём ссылку на камеру
					_view._camera = null;
				}
				// Если назначается вьюпорт
				if (value != null) {
					// Если у вьюпорта была камера
					if (value._camera != null) {
						// Отцепить от у неё вьюпорт
						value._camera.view = null;
					}
					// Сохранить во вьюпорте ссылку на камеру
					value._camera = this;
					// Если есть сцена
					if (_scene != null) {
						// Добавляем камеру в реестр сцены
						_scene.cameras[this] = true;
						// Помечаем камеру на отрисовку
						_scene.camerasToRender[this] = true;
					}
				} else {
					if (_scene != null) {
						// Удаляем камеру из реестра сцены
						delete _scene.cameras[this];
					}
				}
				// Сохраняем вьюпорт
				_view = value;
			}
		}
		
		/**
		 * Включение режима аксонометрической проекции.
		 * 
		 * @default false
		 */		
		public function get orthographic():Boolean {
			return _orthographic;
		}
		
		/**
		 * @private
		 */		
		public function set orthographic(value:Boolean):void {
			if (_orthographic != value) {
				// Отправляем сигнал об изменении типа камеры
				// ...
				// Сохраняем новое значение
				_orthographic = value;
			}
		}
		
		/**
		 * Угол поля зрения в радианах в режиме перспективной проекции. При изменении FOV изменяется фокусное расстояние
		 * камеры по формуле <code>f = d/tan(fov/2)</code>, где <code>d</code> является половиной диагонали поля вывода.
		 * Угол зрения ограничен диапазоном 0-180 градусов.
		 */
		public function get fov():Number {
			return _fov;
		}
		
		/**
		 * @private
		 */
		public function set fov(value:Number):void {
			value = (value < 0) ? 0 : ((value > (Math.PI - 0.0001)) ? (Math.PI - 0.0001) : value);
			if (_fov != value) {
				// Если перспектива
				if (!_orthographic) {
					// Отправляем сигнал об изменении плоскостей отсечения
					// ...
				}
				// Сохраняем новое значение
				_fov = value;
			}
		}

		/**
		 * Коэффициент увеличения изображения в режиме аксонометрической проекции.
		 */
		public function get zoom():Number {
			return _zoom;
		}		

		/**
		 * @private
		 */
		public function set zoom(value:Number):void {
			value = (value < 0) ? 0 : value;
			if (_zoom != value) {
				// Если изометрия
				if (_orthographic) {
					// Отправляем сигнал об изменении zoom
					// ...
				}
				// Сохраняем новое значение
				_zoom = value;
			}
		}

		/**
		 * @inheritDoc
		 */
		override protected function defaultName():String {
			return "camera" + ++counter;
		}
		
	}
}