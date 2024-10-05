package alternativa.engine3d.core {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix3D;
	import flash.utils.getQualifiedClassName;
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	
	/**
	 * Событие рассылается когда пользователь последовательно нажимает и отпускает левую кнопку мыши над одним и тем же объектом.
	 * Между нажатием и отпусканием кнопки могут происходить любые другие события.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.CLICK
	 */
	[Event (name="click", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Событие рассылается когда пользователь последовательно 2 раза в нажимает и отпускает левую кнопку мыши над одним и тем же объектом.
	 * Событие сработает только если время между первым и вторым кликом вписывается в заданный в системе временной интервал.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.DOUBLE_CLICK
	 */
	[Event (name="doubleClick", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Событие рассылается когда пользователь нажимает левую кнопку мыши над объектом.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_DOWN
	 */
	[Event (name="mouseDown", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Событие рассылается когда пользователь отпускает левую кнопку мыши над объектом.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_UP
	 */
	[Event (name="mouseUp", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Событие рассылается когда пользователь наводит курсор мыши на объект.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_OVER
	 */
	[Event (name="mouseOver", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Событие рассылается когда пользователь уводит курсор мыши с объекта.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_OUT
	 */
	[Event (name="mouseOut", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Событие рассылается когда пользователь наводит курсор мыши на объект.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.ROLL_OVER
	 */
	[Event (name="rollOver", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Событие рассылается когда пользователь уводит курсор мыши с объекта.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.ROLL_OUT
	 */
	[Event (name="rollOut", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Событие рассылается когда пользователь перемещает курсор мыши над объектом.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_MOVE
	 */
	[Event (name="mouseMove", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Событие рассылается когда пользователь вращает колесо мыши над объектом.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_WHEEL
	 */
	[Event (name="mouseWheel", type="alternativa.engine3d.core.MouseEvent3D")]
	
	/**
	 * Класс Object3D является базовым классом для всех трёхмерных объектов, которые могут быть отрисованы.
	 * Чтобы упорядочить последовательность отрисовки трёхмерных объектов, нужно использовать <code>Object3DContainer</code> и его наследников.
	 */
	public class Object3D extends Transform3D implements IEventDispatcher {
	
		static private const boundVertexList:Vertex = Vertex.createList(8);
	
		/**
		 * Флаг видимости объекта.
		 */
		public var visible:Boolean = true;
		
		/**
		 * Значение прозрачности объекта.
		 * Допустимые значения находятся в диапазоне от 0 до 1.
		 * Значение по умолчанию 1.
		 */
		public var alpha:Number = 1;
		
		/**
		 * Режим наложения объекта.
		 * Для назначения рекомендуется использовать константы класса <code>flash.display.BlendMode</code>.
		 */
		public var blendMode:String = "normal";
		
		/**
		 * Класс, позволяющий изменять значения цвета объекта.
		 * Преобразование цвета можно применить ко всем четырем каналам: красный, зеленый, синий и альфа.
		 */
		public var colorTransform:ColorTransform = null;
		
		/**
		 * Массив графических фильтров объекта.
		 * Значениями массива должны являться объекты из пакета <code>flash.filters</code>.
		 */
		public var filters:Array = null;
	
		/**
		 * Определяет, получает ли объект сообщения мыши.
		 * Значение по умолчанию — <code>true</code>.
		 * Логика идентична <code>flash.display.InteractiveObject</code>.
		 * Примечание: для обработки событий мыши необходимо установить в <code>true</code> свойство <code>interactive</code> объекта <code>View</code>.
		 */
		public var mouseEnabled:Boolean = true;
		
		/**
		 * Определяет, получает ли объект события <code>doubleClick</code>.
		 * Значение по умолчанию — <code>false</code>.
		 * Примечание: для обработки событий мыши необходимо установить в <code>true</code> свойство <code>interactive</code> объекта <code>View</code>.
		 * Примечание: для обработки события <code>doubleClick</code> необходимо установить в <code>true</code> свойство <code>doubleClickEnabled</code> текущего <code>Stage</code>.
		 */
		public var doubleClickEnabled:Boolean = false;
		
		//public var interactiveAlpha:Number = 0;
		
		//public var useHandCursor:Boolean = false;
	
		/**
		 * Левая граница объекта в его системе координат.
		 */
		public var boundMinX:Number = -1e+22;
		
		/**
		 * Задняя граница объекта в его системе координат.
		 */
		public var boundMinY:Number = -1e+22;
		
		/**
		 * Нижняя граница объекта в его системе координат.
		 */
		public var boundMinZ:Number = -1e+22;
		
		/**
		 * Правая граница объекта в его системе координат.
		 */
		public var boundMaxX:Number = 1e+22;
		
		/**
		 * Передняя граница объекта в его системе координат.
		 */
		public var boundMaxY:Number = 1e+22;
		
		/**
		 * Верхняя граница объекта в его системе координат.
		 */
		public var boundMaxZ:Number = 1e+22;
	
		/**
		 * @private 
		 */
		alternativa3d var _parent:Object3DContainer;
		
		/**
		 * @private 
		 */
		alternativa3d var next:Object3D;
	
		/**
		 * @private 
		 */
		alternativa3d var culling:int = 0;
		
		/**
		 * @private 
		 */
		alternativa3d var transformId:int = 0;
		
		/**
		 * @private 
		 */
		alternativa3d var distance:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var bubbleListeners:Object;
		
		/**
		 * @private 
		 */
		alternativa3d var captureListeners:Object;
		
		/**
		 * Возвращает родительский объект <code>Object3DContainer</code>.
		 */
		public function get parent():Object3DContainer {
			return _parent;
		}
	
		/**
		 * Расчитывает границы объекта в его системе координат.
		 */
		public function calculateBounds():void {
			// Выворачивание баунда
			boundMinX = 1e+22;
			boundMinY = 1e+22;
			boundMinZ = 1e+22;
			boundMaxX = -1e+22;
			boundMaxY = -1e+22;
			boundMaxZ = -1e+22;
			// Заполнение баунда
			updateBounds(this, null);
			// Если баунд вывернут
			if (boundMinX > boundMaxX) {
				boundMinX = -1e+22;
				boundMinY = -1e+22;
				boundMinZ = -1e+22;
				boundMaxX = 1e+22;
				boundMaxY = 1e+22;
				boundMaxZ = 1e+22;
			}
		}

		// Мышиные события
		
		/**
		 * Добавляет обработчик события.
		 * Примечание: для обработки событий мыши необходимо установить в <code>true</code> свойство <code>interactive</code> объекта <code>View</code>.
		 * @param type Тип события.
		 * @param listener Обработчик события.
		 * @param useCapture Определяет, работает ли прослушиватель в фазе захвата или в фазах цели и пузырей.
		 * @param priority Уровень приоритета прослушивателя событий.
		 * @param useWeakReference Определяет сильную или слабую степень ссылки на прослушиватель.
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			if (listener == null) throw new TypeError("Parameter listener must be non-null.");
			var listeners:Object;
			if (useCapture) {
				if (captureListeners == null) captureListeners = new Object();
				listeners = captureListeners;
			} else {
				if (bubbleListeners == null) bubbleListeners = new Object();
				listeners = bubbleListeners;
			}
			var vector:Vector.<Function> = listeners[type];
			if (vector == null) {
				vector = new Vector.<Function>();
				listeners[type] = vector;
			}
			if (vector.indexOf(listener) < 0) {
				vector.push(listener);
			}
		}
	
		/**
		 * Удаляет обработчик события.
		 * @param type Тип события.
		 * @param listener Удаляемый обработчик события.
		 * @param useCapture Указывает, зарегистрирован ли прослушиватель для фазы захвата либо для фаз цели и пузырей.
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			if (listener == null) throw new TypeError("Parameter listener must be non-null.");
			var listeners:Object = useCapture ? captureListeners : bubbleListeners;
			if (listeners != null) {
				var vector:Vector.<Function> = listeners[type];
				if (vector != null) {
					var i:int = vector.indexOf(listener);
					if (i >= 0) {
						var length:int = vector.length;
						for (var j:int = i + 1; j < length; j++, i++) {
							vector[i] = vector[j];
						}
						if (length > 1) {
							vector.length = length - 1;
						} else {
							delete listeners[type];
							var key:*;
							for (key in listeners) break;
							if (!key) {
								if (listeners == captureListeners) {
									captureListeners = null;
								} else {
									bubbleListeners = null;
								}
							}
						}
					}
				}
			}
		}
	
		/**
		 * Проверяет наличие зарегистрированных обработчиков события указанного типа в объекте.
		 * @param type Тип события.
		 * @return <code>true</code> если есть обработчики события указанного типа, иначе <code>false</code>.
		 */
		public function hasEventListener(type:String):Boolean {
			return captureListeners != null && captureListeners[type] || bubbleListeners != null && bubbleListeners[type];
		}
	
		/**
		 * Проверяет наличие зарегистрированных обработчиков события указанного типа в объекте или в любом из его предков.
		 * @param type Тип события.
		 * @return <code>true</code> если есть обработчики события указанного типа, иначе <code>false</code>.
		 */
		public function willTrigger(type:String):Boolean {
			for (var object:Object3D = this; object != null; object = object._parent) {
				if (object.captureListeners != null && object.captureListeners[type] || object.bubbleListeners != null && object.bubbleListeners[type]) return true;
			}
			return false;
		}
	
		/**
		 * Передает событие в поток событий.
		 * @param event Объект Event, отправляемый в поток событий.
		 * @return <code>true</code> если событие было успешно отправлено, иначе <code>false</code>.
		 */
		public function dispatchEvent(event:Event):Boolean {
			if (event == null) throw new TypeError("Parameter event must be non-null.");
			if (event is MouseEvent3D) MouseEvent3D(event)._target = this;
			var branch:Vector.<Object3D> = new Vector.<Object3D>();
			var branchLength:int = 0;
			var object:Object3D;
			for (object = this; object != null; object = object._parent) {
				branch[branchLength] = object;
				branchLength++;
			}
			for (var i:int = 0; i < branchLength; i++) {
				object = branch[i];
				if (event is MouseEvent3D) MouseEvent3D(event)._currentTarget = object;
				if (bubbleListeners != null) {
					var vector:Vector.<Function> = bubbleListeners[event.type];
					if (vector != null) {
						var j:int;
						var length:int = vector.length;
						var functions:Vector.<Function> = new Vector.<Function>();
						for (j = 0; j < length; j++) functions[j] = vector[j];
						for (j = 0; j < length; j++) (functions[j] as Function).call(null, event);
					}
				}
				if (!event.bubbles) break;
			}
			return true;
		}
		
		// Переопределяемые публичные методы
		
		/**
		 * Расчитывает отношение, сколько единиц трёхмерного пространства приходится на пиксел текстуры.
		 * Это полезно для мипмаппинга.
		 * Если в <code>TextureMaterial</code> устанавливать свойство <code>mipMapping</code> в <code>MipMapping.OBJECT_DISTANCE</code> или <code>MipMapping.PER_PIXEL</code>, 
		 * то имеет смысл присвоить свойству текстурного материала <code>resolution</code> результат выполнения этого метода, вызванного у объекта, к которому применяется этот материал.
		 * @param textureWidth Ширина текстуры.
		 * @param textureHeight Высота текстуры.
		 * @param type Метод расчёта: 0 - по первому ребру, 1 - среднее значение, 2 - минимальное значение, 3 - максимальное значение.
		 * @param matrix Матрица трансформации, которая учитывается при расчёте.
		 * @return Отношение, сколько единиц трёхмерного пространства приходится на пиксел текстуры. Если текстура растянута по отношению к геометрии, то значение будет больше 1. Если сжата, то меньше 1.
		 * @see alternativa.engine3d.materials.TextureMaterial
		 * @see alternativa.engine3d.core.MipMapping
		 */
		public function calculateResolution(textureWidth:int, textureHeight:int, type:int = 1, matrix:Matrix3D = null):Number {
			return 1;
		}
		
		/**
		 * Возвращает объект, являющийся точной копией исходного объекта.
		 * @return Клон исходного объекта.
		 */
		public function clone():Object3D {
			var res:Object3D = new Object3D();
			res.cloneBaseProperties(this);
			return res;
		}
	
		/**
		 * Копирует базовые свойства. Метод вызывается внутри <code>clone()</code>.
		 * @param source Объект, с которого копируются базовые свойства.
		 */
		protected function cloneBaseProperties(source:Object3D):void {
			name = source.name;
			visible = source.visible;
			alpha = source.alpha;
			blendMode = source.blendMode;
			mouseEnabled = source.mouseEnabled;
			doubleClickEnabled = source.doubleClickEnabled;
			//interactiveAlpha = source.interactiveAlpha;
			//useHandCursor = source.useHandCursor;
			transformId = source.transformId;
			distance = source.distance;
			if (source.colorTransform != null) {
				colorTransform = new ColorTransform();
				colorTransform.concat(source.colorTransform);
			}
			if (source.filters != null) {
				filters = new Array().concat(source.filters);
			}
			x = source.x;
			y = source.y;
			z = source.z;
			rotationX = source.rotationX;
			rotationY = source.rotationY;
			rotationZ = source.rotationZ;
			scaleX = source.scaleX;
			scaleY = source.scaleY;
			scaleZ = source.scaleZ;
			boundMinX = source.boundMinX;
			boundMinY = source.boundMinY;
			boundMinZ = source.boundMinZ;
			boundMaxX = source.boundMaxX;
			boundMaxY = source.boundMaxY;
			boundMaxZ = source.boundMaxZ;
		}
		
		/**
		 * Возвращает строковое представление заданного объекта.
		 * @return Строковое представление объекта.
		 */
		public function toString():String {
			var className:String = getQualifiedClassName(this);
			return "[" + className.substr(className.indexOf("::") + 2) + " " + name + "]";
		}
		
		// Переопределяемые закрытые методы
		
		/**
		 * @private 
		 */
		alternativa3d function draw(camera:Camera3D, parentCanvas:Canvas):void {
		}
	
		/**
		 * @private 
		 */
		alternativa3d function getVG(camera:Camera3D):VG {
			return null;
		}
	
		/**
		 * @private 
		 */
		alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
		}
	
		/**
		 * @private 
		 */
		alternativa3d function split(a:Vector3D, b:Vector3D, c:Vector3D, threshold:Number):Vector.<Object3D> {
			return new Vector.<Object3D>(2);
		}
		
		/**
		 * @private 
		 */
		alternativa3d function testSplit(a:Vector3D, b:Vector3D, c:Vector3D, threshold:Number):int {
			var plane:Vector3D = calculatePlane(a, b, c);
			if (plane.x >= 0) if (plane.y >= 0) if (plane.z >= 0) {
				if (boundMaxX*plane.x + boundMaxY*plane.y + boundMaxZ*plane.z <= plane.w + threshold) return -1;
				if (boundMinX*plane.x + boundMinY*plane.y + boundMinZ*plane.z >= plane.w - threshold) return 1;
			} else {
				if (boundMaxX*plane.x + boundMaxY*plane.y + boundMinZ*plane.z <= plane.w + threshold) return -1;
				if (boundMinX*plane.x + boundMinY*plane.y + boundMaxZ*plane.z >= plane.w - threshold) return 1;
			} else if (plane.z >= 0) {
				if (boundMaxX*plane.x + boundMinY*plane.y + boundMaxZ*plane.z <= plane.w + threshold) return -1;
				if (boundMinX*plane.x + boundMaxY*plane.y + boundMinZ*plane.z >= plane.w - threshold) return 1;
			} else {
				if (boundMaxX*plane.x + boundMinY*plane.y + boundMinZ*plane.z <= plane.w + threshold) return -1;
				if (boundMinX*plane.x + boundMaxY*plane.y + boundMaxZ*plane.z >= plane.w - threshold) return 1;
			} else if (plane.y >= 0) if (plane.z >= 0) {
				if (boundMinX*plane.x + boundMaxY*plane.y + boundMaxZ*plane.z <= plane.w + threshold) return -1;
				if (boundMaxX*plane.x + boundMinY*plane.y + boundMinZ*plane.z >= plane.w - threshold) return 1;
			} else {
				if (boundMinX*plane.x + boundMaxY*plane.y + boundMinZ*plane.z <= plane.w + threshold) return -1;
				if (boundMaxX*plane.x + boundMinY*plane.y + boundMaxZ*plane.z >= plane.w - threshold) return 1;
			} else if (plane.z >= 0) {
				if (boundMinX*plane.x + boundMinY*plane.y + boundMaxZ*plane.z <= plane.w + threshold) return -1;
				if (boundMaxX*plane.x + boundMaxY*plane.y + boundMinZ*plane.z >= plane.w - threshold) return 1;
			} else {
				if (boundMinX*plane.x + boundMinY*plane.y + boundMinZ*plane.z <= plane.w + threshold) return -1;
				if (boundMaxX*plane.x + boundMaxY*plane.y + boundMaxZ*plane.z >= plane.w - threshold) return 1;
			}
			return 0;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function calculatePlane(a:Vector3D, b:Vector3D, c:Vector3D):Vector3D {
			var res:Vector3D = new Vector3D();
			var abx:Number = b.x - a.x;
			var aby:Number = b.y - a.y;
			var abz:Number = b.z - a.z;
			var acx:Number = c.x - a.x;
			var acy:Number = c.y - a.y;
			var acz:Number = c.z - a.z;
			res.x = acz*aby - acy*abz;
			res.y = acx*abz - acz*abx;
			res.z = acy*abx - acx*aby;
			var len:Number = res.x*res.x + res.y*res.y + res.z*res.z;
			if (len > 0.0001) {
				len = Math.sqrt(len);
				res.x /= len;
				res.y /= len;
				res.z /= len;
			}
			res.w = a.x*res.x + a.y*res.y + a.z*res.z;
			return res;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function cullingInCamera(camera:Camera3D, culling:int):int {
			if (camera.occludedAll) return -1;
			var numOccluders:int = camera.numOccluders;
			var vertex:Vertex;
			// Расчёт точек баунда в координатах камеры
			if (culling > 0 || numOccluders > 0) {
				// Заполнение
				vertex = boundVertexList;
				vertex.x = boundMinX;
				vertex.y = boundMinY;
				vertex.z = boundMinZ;
				vertex = vertex.next;
				vertex.x = boundMaxX;
				vertex.y = boundMinY;
				vertex.z = boundMinZ;
				vertex = vertex.next;
				vertex.x = boundMinX;
				vertex.y = boundMaxY;
				vertex.z = boundMinZ;
				vertex = vertex.next;
				vertex.x = boundMaxX;
				vertex.y = boundMaxY;
				vertex.z = boundMinZ;
				vertex = vertex.next;
				vertex.x = boundMinX;
				vertex.y = boundMinY;
				vertex.z = boundMaxZ;
				vertex = vertex.next;
				vertex.x = boundMaxX;
				vertex.y = boundMinY;
				vertex.z = boundMaxZ;
				vertex = vertex.next;
				vertex.x = boundMinX;
				vertex.y = boundMaxY;
				vertex.z = boundMaxZ;
				vertex = vertex.next;
				vertex.x = boundMaxX;
				vertex.y = boundMaxY;
				vertex.z = boundMaxZ;
				// Трансформация в камеру
				for (vertex = boundVertexList; vertex != null; vertex = vertex.next) {
					var x:Number = vertex.x;
					var y:Number = vertex.y;
					var z:Number = vertex.z;
					vertex.cameraX = ma*x + mb*y + mc*z + md;
					vertex.cameraY = me*x + mf*y + mg*z + mh;
					vertex.cameraZ = mi*x + mj*y + mk*z + ml;
				}
			}
			// Куллинг
			if (culling > 0) {
				var infront:Boolean;
				var behind:Boolean;
				if (culling & 1) {
					var near:Number = camera.nearClipping;
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (vertex.cameraZ > near) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 62;
					}
				}
				if (culling & 2) {
					var far:Number = camera.farClipping;
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (vertex.cameraZ < far) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 61;
					}
				}
				if (culling & 4) {
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (-vertex.cameraX < vertex.cameraZ) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 59;
					}
				}
				if (culling & 8) {
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (vertex.cameraX < vertex.cameraZ) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 55;
					}
				}
				if (culling & 16) {
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (-vertex.cameraY < vertex.cameraZ) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 47;
					}
				}
				if (culling & 32) {
					for (vertex = boundVertexList, infront = false, behind = false; vertex != null; vertex = vertex.next) {
						if (vertex.cameraY < vertex.cameraZ) {
							infront = true;
							if (behind) break;
						} else {
							behind = true;
							if (infront) break;
						}
					}
					if (behind) {
						if (!infront) return -1;
					} else {
						culling &= 31;
					}
				}
			}
			// Окклюдинг
			if (numOccluders > 0) {
				for (var i:int = 0; i < numOccluders; i++) {
					for (var plane:Vertex = camera.occluders[i]; plane != null; plane = plane.next) {
						for (vertex = boundVertexList; vertex != null; vertex = vertex.next) {
							if (plane.cameraX*vertex.cameraX + plane.cameraY*vertex.cameraY + plane.cameraZ*vertex.cameraZ >= 0) break;
						}
						if (vertex != null) break;
					}
					if (plane == null) return -1;
				}
			}
			this.culling = culling;
			return culling;
		}
		
	}
}
