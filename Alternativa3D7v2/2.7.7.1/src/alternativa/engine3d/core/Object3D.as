package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

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
	public class Object3D implements IEventDispatcher {
	
		static private const boundVertexList:Vertex = Vertex.createList(8);
		
		/**
		 * Координата X.
		 */
		public var x:Number = 0;
		
		/**
		 * Координата Y.
		 */
		public var y:Number = 0;
		
		/**
		 * Координата Z.
		 */
		public var z:Number = 0;
		
		/**
		 * Угол поворота вокруг оси X.
		 * Указывается в радианах.
		 */
		public var rotationX:Number = 0;
		
		/**
		 * Угол поворота вокруг оси Y.
		 * Указывается в радианах.
		 */
		public var rotationY:Number = 0;
		
		/**
		 * Угол поворота вокруг оси Z.
		 * Указывается в радианах.
		 */
		public var rotationZ:Number = 0;
		
		/**
		 * Коэффициент масштабирования по оси X.
		 */
		public var scaleX:Number = 1;
		
		/**
		 * Коэффициент масштабирования по оси Y.
		 */
		public var scaleY:Number = 1;
		
		/**
		 * Коэффициент масштабирования по оси Z.
		 */
		public var scaleZ:Number = 1;
		
		/**
		 * Имя объекта.
		 */
		public var name:String;
		
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
		
		// Матрица
		
		/**
		 * @private 
		 */
		alternativa3d var ma:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mb:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mc:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var md:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var me:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mf:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mg:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mh:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mi:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mj:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var mk:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var ml:Number;
	
		// Инверсная матрица
		
		/**
		 * @private 
		 */
		alternativa3d var ima:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imb:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imc:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imd:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var ime:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imf:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var img:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imh:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imi:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imj:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var imk:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var iml:Number;
		
		/**
		 * @private 
		 */
		alternativa3d var weightsSum:Vector.<Number>;
		
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
		 * Объект <code>Matrix3D</code>, содержащий значения, влияющие на масштабирование, поворот и перемещение объекта.
		 */
		public function get matrix():Matrix3D {
			var m:Matrix3D = new Matrix3D();
			var t:Vector3D = new Vector3D(x, y, z);
			var r:Vector3D = new Vector3D(rotationX, rotationY, rotationZ);
			var s:Vector3D = new Vector3D(scaleX, scaleY, scaleZ);
			var v:Vector.<Vector3D> = new Vector.<Vector3D>();
			v[0] = t;
			v[1] = r;
			v[2] = s;
			m.recompose(v);
			return m;
		}
	
		/**
		 * @private
		 */
		public function set matrix(value:Matrix3D):void {
			var v:Vector.<Vector3D> = value.decompose();
			var t:Vector3D = v[0];
			var r:Vector3D = v[1];
			var s:Vector3D = v[2];
			x = t.x;
			y = t.y;
			z = t.z;
			rotationX = r.x;
			rotationY = r.y;
			rotationZ = r.z;
			scaleX = s.x;
			scaleY = s.y;
			scaleZ = s.z;
		}
		
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
		 * Преобразует точку из локальных координат в глобальные.
		 * @param point Точка в локальных координатах объекта.
		 * @return Точка в глобальном пространстве.
		 */
		public function localToGlobal(point:Vector3D):Vector3D {
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				appendMatrix(root);
			}
			var res:Vector3D = new Vector3D();
			res.x = ma*point.x + mb*point.y + mc*point.z + md;
			res.y = me*point.x + mf*point.y + mg*point.z + mh;
			res.z = mi*point.x + mj*point.y + mk*point.z + ml;
			return res;
		}
		
		/**
		 * Преобразует точку из глобальной системы координат в локальные координаты объекта.
		 * @param point Точка в глобальном пространстве.
		 * @return Точка в локальных координатах объекта.
		 */
		public function globalToLocal(point:Vector3D):Vector3D {
			composeMatrix();
			var root:Object3D = this;
			while (root._parent != null) {
				root = root._parent;
				root.composeMatrix();
				appendMatrix(root);
			}
			invertMatrix();
			var res:Vector3D = new Vector3D();
			res.x = ma*point.x + mb*point.y + mc*point.z + md;
			res.y = me*point.x + mf*point.y + mg*point.z + mh;
			res.z = mi*point.x + mj*point.y + mk*point.z + ml;
			return res;
		}
		
		/**
		 * Осуществляет поиск пересечение луча с объектом.
		 * @param origin Начало луча.
		 * @param direction Направление луча.
		 * @param exludedObjects Ассоциативный массив, ключами которого являются экземпляры <code>Object3D</code> и его наследников. Объекты, содержащиеся в этом массиве будут исключены из проверки.
		 * @param camera Камера для правильного поиска пересечения луча с объектами <code>Sprite3D</code>. Эти объекты всегда повёрнуты к камере. Если камера не указана, результат пересечения луча со спрайтом будет <code>null</code>.
		 * @return Результат поиска пересечения — объект <code>RayIntersectionData</code>. Если пересечения нет, будет возвращён <code>null</code>.
		 * @see RayIntersectionData
		 * @see alternativa.engine3d.objects.Sprite3D
		 */
		public function intersectRay(origin:Vector3D, direction:Vector3D, exludedObjects:Dictionary = null, camera:Camera3D = null):RayIntersectionData {
			return null;
		}
		
		/**
		 * Возвращает объект, являющийся точной копией исходного объекта.
		 * @return Клон исходного объекта.
		 */
		public function clone():Object3D {
			var res:Object3D = new Object3D();
			res.clonePropertiesFrom(this);
			return res;
		}
	
		/**
		 * Копирует базовые свойства. Метод вызывается внутри <code>clone()</code>.
		 * @param source Объект, с которого копируются базовые свойства.
		 */
		protected function clonePropertiesFrom(source:Object3D):void {
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
		alternativa3d function boundIntersectRay(origin:Vector3D, direction:Vector3D, boundMinX:Number, boundMinY:Number, boundMinZ:Number, boundMaxX:Number, boundMaxY:Number, boundMaxZ:Number):Boolean {
			if (origin.x >= boundMinX && origin.x <= boundMaxX && origin.y >= boundMinY && origin.y <= boundMaxY && origin.z >= boundMinZ && origin.z <= boundMaxZ) return true;
			if (origin.x < boundMinX && direction.x <= 0) return false;
			if (origin.x > boundMaxX && direction.x >= 0) return false;
			if (origin.y < boundMinY && direction.y <= 0) return false;
			if (origin.y > boundMaxY && direction.y >= 0) return false;
			if (origin.z < boundMinZ && direction.z <= 0) return false;
			if (origin.z > boundMaxZ && direction.z >= 0) return false;
			var a:Number;
			var b:Number;
			var c:Number;
			var d:Number;
			var threshold:Number = 0.000001;
			// Пересечение проекций X и Y
			if (direction.x > threshold) {
				a = (boundMinX - origin.x)/direction.x;
				b = (boundMaxX - origin.x)/direction.x;
			} else if (direction.x < -threshold) {
				a = (boundMaxX - origin.x)/direction.x;
				b = (boundMinX - origin.x)/direction.x;
			} else {
				a = -1e+22;
				b = 1e+22;
			}
			if (direction.y > threshold) {
				c = (boundMinY - origin.y)/direction.y;
				d = (boundMaxY - origin.y)/direction.y;
			} else if (direction.y < -threshold) {
				c = (boundMaxY - origin.y)/direction.y;
				d = (boundMinY - origin.y)/direction.y;
			} else {
				c = -1e+22;
				d = 1e+22;
			}
			if (c >= b || d <= a) return false;
			if (c < a) {
				if (d < b) b = d;
			} else {
				a = c;
				if (d < b) b = d;
			}
			// Пересечение проекций XY и Z 
			if (direction.z > threshold) {
				c = (boundMinZ - origin.z)/direction.z;
				d = (boundMaxZ - origin.z)/direction.z;
			} else if (direction.z < -threshold) {
				c = (boundMaxZ - origin.z)/direction.z;
				d = (boundMinZ - origin.z)/direction.z;
			} else {
				c = -1e+22;
				d = 1e+22;
			}
			if (c >= b || d <= a) return false;
			return true;
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
		alternativa3d function composeMatrix():void {
			var cosX:Number = Math.cos(rotationX);
			var sinX:Number = Math.sin(rotationX);
			var cosY:Number = Math.cos(rotationY);
			var sinY:Number = Math.sin(rotationY);
			var cosZ:Number = Math.cos(rotationZ);
			var sinZ:Number = Math.sin(rotationZ);
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			var cosYscaleX:Number = cosY*scaleX;
			var sinXscaleY:Number = sinX*scaleY;
			var cosXscaleY:Number = cosX*scaleY;
			var cosXscaleZ:Number = cosX*scaleZ;
			var sinXscaleZ:Number = sinX*scaleZ;
			ma = cosZ*cosYscaleX;
			mb = cosZsinY*sinXscaleY - sinZ*cosXscaleY;
			mc = cosZsinY*cosXscaleZ + sinZ*sinXscaleZ;
			md = x;
			me = sinZ*cosYscaleX;
			mf = sinZsinY*sinXscaleY + cosZ*cosXscaleY;
			mg = sinZsinY*cosXscaleZ - cosZ*sinXscaleZ;
			mh = y;
			mi = -sinY*scaleX;
			mj = cosY*sinXscaleY;
			mk = cosY*cosXscaleZ;
			ml = z;
		}
	
		/**
		 * @private 
		 */
		alternativa3d function appendMatrix(transform:Object3D):void {
			var a:Number = ma;
			var b:Number = mb;
			var c:Number = mc;
			var d:Number = md;
			var e:Number = me;
			var f:Number = mf;
			var g:Number = mg;
			var h:Number = mh;
			var i:Number = mi;
			var j:Number = mj;
			var k:Number = mk;
			var l:Number = ml;
			ma = transform.ma*a + transform.mb*e + transform.mc*i;
			mb = transform.ma*b + transform.mb*f + transform.mc*j;
			mc = transform.ma*c + transform.mb*g + transform.mc*k;
			md = transform.ma*d + transform.mb*h + transform.mc*l + transform.md;
			me = transform.me*a + transform.mf*e + transform.mg*i;
			mf = transform.me*b + transform.mf*f + transform.mg*j;
			mg = transform.me*c + transform.mf*g + transform.mg*k;
			mh = transform.me*d + transform.mf*h + transform.mg*l + transform.mh;
			mi = transform.mi*a + transform.mj*e + transform.mk*i;
			mj = transform.mi*b + transform.mj*f + transform.mk*j;
			mk = transform.mi*c + transform.mj*g + transform.mk*k;
			ml = transform.mi*d + transform.mj*h + transform.mk*l + transform.ml;
		}
	
		/**
		 * @private 
		 */
		alternativa3d function composeAndAppend(transform:Object3D):void {
			var cosX:Number = Math.cos(rotationX);
			var sinX:Number = Math.sin(rotationX);
			var cosY:Number = Math.cos(rotationY);
			var sinY:Number = Math.sin(rotationY);
			var cosZ:Number = Math.cos(rotationZ);
			var sinZ:Number = Math.sin(rotationZ);
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			var cosYscaleX:Number = cosY*scaleX;
			var sinXscaleY:Number = sinX*scaleY;
			var cosXscaleY:Number = cosX*scaleY;
			var cosXscaleZ:Number = cosX*scaleZ;
			var sinXscaleZ:Number = sinX*scaleZ;
			var a:Number = cosZ*cosYscaleX;
			var b:Number = cosZsinY*sinXscaleY - sinZ*cosXscaleY;
			var c:Number = cosZsinY*cosXscaleZ + sinZ*sinXscaleZ;
			var d:Number = x;
			var e:Number = sinZ*cosYscaleX;
			var f:Number = sinZsinY*sinXscaleY + cosZ*cosXscaleY;
			var g:Number = sinZsinY*cosXscaleZ - cosZ*sinXscaleZ;
			var h:Number = y;
			var i:Number = -sinY*scaleX;
			var j:Number = cosY*sinXscaleY;
			var k:Number = cosY*cosXscaleZ;
			var l:Number = z;
			ma = transform.ma*a + transform.mb*e + transform.mc*i;
			mb = transform.ma*b + transform.mb*f + transform.mc*j;
			mc = transform.ma*c + transform.mb*g + transform.mc*k;
			md = transform.ma*d + transform.mb*h + transform.mc*l + transform.md;
			me = transform.me*a + transform.mf*e + transform.mg*i;
			mf = transform.me*b + transform.mf*f + transform.mg*j;
			mg = transform.me*c + transform.mf*g + transform.mg*k;
			mh = transform.me*d + transform.mf*h + transform.mg*l + transform.mh;
			mi = transform.mi*a + transform.mj*e + transform.mk*i;
			mj = transform.mi*b + transform.mj*f + transform.mk*j;
			mk = transform.mi*c + transform.mj*g + transform.mk*k;
			ml = transform.mi*d + transform.mj*h + transform.mk*l + transform.ml;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function invertMatrix():void {
			var a:Number = ma;
			var b:Number = mb;
			var c:Number = mc;
			var d:Number = md;
			var e:Number = me;
			var f:Number = mf;
			var g:Number = mg;
			var h:Number = mh;
			var i:Number = mi;
			var j:Number = mj;
			var k:Number = mk;
			var l:Number = ml;
			var det:Number = 1/(-c*f*i + b*g*i + c*e*j - a*g*j - b*e*k + a*f*k);
			ma = (-g*j + f*k)*det;
			mb = (c*j - b*k)*det;
			mc = (-c*f + b*g)*det;
			md = (d*g*j - c*h*j - d*f*k + b*h*k + c*f*l - b*g*l)*det;
			me = (g*i - e*k)*det;
			mf = (-c*i + a*k)*det;
			mg = (c*e - a*g)*det;
			mh = (c*h*i - d*g*i + d*e*k - a*h*k - c*e*l + a*g*l)*det;
			mi = (-f*i + e*j)*det;
			mj = (b*i - a*j)*det;
			mk = (-b*e + a*f)*det;
			ml = (d*f*i - b*h*i - d*e*j + a*h*j + b*e*l - a*f*l)*det;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function calculateInverseMatrix():void {
			var det:Number = 1/(-mc*mf*mi + mb*mg*mi + mc*me*mj - ma*mg*mj - mb*me*mk + ma*mf*mk);
			ima = (-mg*mj + mf*mk)*det;
			imb = (mc*mj - mb*mk)*det;
			imc = (-mc*mf + mb*mg)*det;
			imd = (md*mg*mj - mc*mh*mj - md*mf*mk + mb*mh*mk + mc*mf*ml - mb*mg*ml)*det;
			ime = (mg*mi - me*mk)*det;
			imf = (-mc*mi + ma*mk)*det;
			img = (mc*me - ma*mg)*det;
			imh = (mc*mh*mi - md*mg*mi + md*me*mk - ma*mh*mk - mc*me*ml + ma*mg*ml)*det;
			imi = (-mf*mi + me*mj)*det;
			imj = (mb*mi - ma*mj)*det;
			imk = (-mb*me + ma*mf)*det;
			iml = (md*mf*mi - mb*mh*mi - md*me*mj + ma*mh*mj + mb*me*ml - ma*mf*ml)*det;
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
		
		/**
		 * @private 
		 */
		alternativa3d function removeFromParent():void {
			if (_parent != null) {
				_parent.removeChild(this);
			}
		}
		
	}
}
