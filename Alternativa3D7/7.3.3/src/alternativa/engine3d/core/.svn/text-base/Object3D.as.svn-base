package alternativa.engine3d.core {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.ColorTransform;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
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
	 * Базовый трёхмерный объект
	 */
	public class Object3D {
	
		static private const boundVertexList:Vertex = Vertex.createList(8);
	
		public var name:String;
	
		public var x:Number = 0;
		public var y:Number = 0;
		public var z:Number = 0;
		public var rotationX:Number = 0;
		public var rotationY:Number = 0;
		public var rotationZ:Number = 0;
		public var scaleX:Number = 1;
		public var scaleY:Number = 1;
		public var scaleZ:Number = 1;
	
		public var visible:Boolean = true;
	
		public var alpha:Number = 1;
		public var blendMode:String = "normal";
		public var colorTransform:ColorTransform = null;
		public var filters:Array = null;
	
		public var interactiveAlpha:Number = 0;
		public var mouseEnabled:Boolean = true;
		public var mouseChildren:Boolean = true;
		public var doubleClickEnabled:Boolean = false;
		public var useHandCursor:Boolean = false;
	
		public var boundMinX:Number = -1e+22;
		public var boundMinY:Number = -1e+22;
		public var boundMinZ:Number = -1e+22;
		public var boundMaxX:Number = 1e+22;
		public var boundMaxY:Number = 1e+22;
		public var boundMaxZ:Number = 1e+22;
	
		alternativa3d var _parent:Object3DContainer;
	
		alternativa3d var culling:int = 0;
	
		// Матрица
		alternativa3d var ma:Number;
		alternativa3d var mb:Number;
		alternativa3d var mc:Number;
		alternativa3d var md:Number;
		alternativa3d var me:Number;
		alternativa3d var mf:Number;
		alternativa3d var mg:Number;
		alternativa3d var mh:Number;
		alternativa3d var mi:Number;
		alternativa3d var mj:Number;
		alternativa3d var mk:Number;
		alternativa3d var ml:Number;
	
		// Инверсная матрица
		alternativa3d var ima:Number;
		alternativa3d var imb:Number;
		alternativa3d var imc:Number;
		alternativa3d var imd:Number;
		alternativa3d var ime:Number;
		alternativa3d var imf:Number;
		alternativa3d var img:Number;
		alternativa3d var imh:Number;
		alternativa3d var imi:Number;
		alternativa3d var imj:Number;
		alternativa3d var imk:Number;
		alternativa3d var iml:Number;
	
		alternativa3d var listeners:Object;
		
		alternativa3d var weightsSum:Vector.<Number>;
	
		public function get parent():Object3DContainer {
			return _parent;
		}
	
		public function getMatrix():Matrix3D {
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
	
		public function setMatrix(value:Matrix3D):void {
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
	
		public function get position():Vector3D {
			return new Vector3D(x, y, z);
		}
	
		public function set position(value:Vector3D):void {
			x = value.x;
			y = value.y;
			z = value.z;
		}

		public function setPositionXYZ(x:Number, y:Number, z:Number):void {
			this.x = x;
			this.y = y;
			this.z = z;
		}
		
		public function setRotationXYZ(rx:Number, ry:Number, rz:Number):void {
			rotationX = rx;
			rotationY = ry;
			rotationZ = rz;
		}
	
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

		public function removeFromParent():void {
			if (_parent != null)
				_parent.removeChild(this);
		}
	
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
	
		alternativa3d function appendMatrix(object:Object3D):void {
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
			ma = object.ma*a + object.mb*e + object.mc*i;
			mb = object.ma*b + object.mb*f + object.mc*j;
			mc = object.ma*c + object.mb*g + object.mc*k;
			md = object.ma*d + object.mb*h + object.mc*l + object.md;
			me = object.me*a + object.mf*e + object.mg*i;
			mf = object.me*b + object.mf*f + object.mg*j;
			mg = object.me*c + object.mf*g + object.mg*k;
			mh = object.me*d + object.mf*h + object.mg*l + object.mh;
			mi = object.mi*a + object.mj*e + object.mk*i;
			mj = object.mi*b + object.mj*f + object.mk*j;
			mk = object.mi*c + object.mj*g + object.mk*k;
			ml = object.mi*d + object.mj*h + object.mk*l + object.ml;
		}
	
		alternativa3d function composeAndAppend(object:Object3D):void {
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
			ma = object.ma*a + object.mb*e + object.mc*i;
			mb = object.ma*b + object.mb*f + object.mc*j;
			mc = object.ma*c + object.mb*g + object.mc*k;
			md = object.ma*d + object.mb*h + object.mc*l + object.md;
			me = object.me*a + object.mf*e + object.mg*i;
			mf = object.me*b + object.mf*f + object.mg*j;
			mg = object.me*c + object.mf*g + object.mg*k;
			mh = object.me*d + object.mf*h + object.mg*l + object.mh;
			mi = object.mi*a + object.mj*e + object.mk*i;
			mj = object.mi*b + object.mj*f + object.mk*j;
			mk = object.mi*c + object.mj*g + object.mk*k;
			ml = object.mi*d + object.mj*h + object.mk*l + object.ml;
		}
	
		alternativa3d function calculateInverseMatrix(object:Object3D):void {
			var a:Number = object.ma;
			var b:Number = object.mb;
			var c:Number = object.mc;
			var d:Number = object.md;
			var e:Number = object.me;
			var f:Number = object.mf;
			var g:Number = object.mg;
			var h:Number = object.mh;
			var i:Number = object.mi;
			var j:Number = object.mj;
			var k:Number = object.mk;
			var l:Number = object.ml;
			var det:Number = 1/(-c*f*i + b*g*i + c*e*j - a*g*j - b*e*k + a*f*k);
			ima = (-g*j + f*k)*det;
			imb = (c*j - b*k)*det;
			imc = (-c*f + b*g)*det;
			imd = (d*g*j - c*h*j - d*f*k + b*h*k + c*f*l - b*g*l)*det;
			ime = (g*i - e*k)*det;
			imf = (-c*i + a*k)*det;
			img = (c*e - a*g)*det;
			imh = (c*h*i - d*g*i + d*e*k - a*h*k - c*e*l + a*g*l)*det;
			imi = (-f*i + e*j)*det;
			imj = (b*i - a*j)*det;
			imk = (-b*e + a*f)*det;
			iml = (d*f*i - b*h*i - d*e*j + a*h*j + b*e*l - a*f*l)*det;
		}
	
		alternativa3d function draw(camera:Camera3D, object:Object3D, parentCanvas:Canvas):void {
		}
	
		alternativa3d function getGeometry(camera:Camera3D, object:Object3D):Geometry {
			return null;
		}
	
		alternativa3d function updateBounds(bounds:Object3D, transformation:Object3D = null):void {
		}
	
		alternativa3d function split(normalX:Number, normalY:Number, normalZ:Number, offset:Number, threshold:Number):Vector.<Object3D> {
			return new Vector.<Object3D>(2);
		}
	
		alternativa3d function cullingInCamera(camera:Camera3D, object:Object3D, culling:int):int {
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
					vertex.cameraX = object.ma*x + object.mb*y + object.mc*z + object.md;
					vertex.cameraY = object.me*x + object.mf*y + object.mg*z + object.mh;
					vertex.cameraZ = object.mi*x + object.mj*y + object.mk*z + object.ml;
				}
			}
			// Куллинг
			if (culling > 0) {
				var infront:Boolean;
				var behind:Boolean;
				if (culling & 1) {
					var near:Number = camera.nearClipping;
					for (vertex = boundVertexList,infront = false,behind = false; vertex != null; vertex = vertex.next) {
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
					for (vertex = boundVertexList,infront = false,behind = false; vertex != null; vertex = vertex.next) {
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
					for (vertex = boundVertexList,infront = false,behind = false; vertex != null; vertex = vertex.next) {
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
					for (vertex = boundVertexList,infront = false,behind = false; vertex != null; vertex = vertex.next) {
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
					for (vertex = boundVertexList,infront = false,behind = false; vertex != null; vertex = vertex.next) {
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
					for (vertex = boundVertexList,infront = false,behind = false; vertex != null; vertex = vertex.next) {
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
			object.culling = culling;
			return culling;
		}
	
		public function clone():Object3D {
			var res:Object3D = new Object3D();
			res.cloneBaseProperties(this);
			return res;
		}
	
		protected function cloneBaseProperties(source:Object3D):void {
			name = source.name;
			visible = source.visible;
			alpha = source.alpha;
			blendMode = source.blendMode;
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
		 * Добавляет обработчик события.
		 * @param type тип события
		 * @param listener обработчик события
		 */
		public function addEventListener(type:String, listener:Function):void {
			if (listeners == null) listeners = new Object();
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
		 * @param type тип события
		 * @param listener обработчик события
		 */
		public function removeEventListener(type:String, listener:Function):void {
			if (listeners != null) {
				var vector:Vector.<Function> = listeners[type];
				if (vector != null) {
					var i:int = vector.indexOf(listener);
					if (i >= 0) {
						var length:int = vector.length;
						for (var j:int = i + 1; j < length; j++,i++) {
							vector[i] = vector[j];
						}
						if (length > 1) {
							vector.length = length - 1;
						} else {
							delete listeners[type];
							var key:*;
							for (key in listeners) break;
							if (!key) listeners = null;
						}
					}
				}
			}
		}
	
		/**
		 * Проверяет наличие зарегистрированных обработчиков события указанного типа.
		 * @param type тип события
		 * @return <code>true</code> если есть обработчики события указанного типа, иначе <code>false</code>
		 */
		public function hasEventListener(type:String):Boolean {
			return listeners != null && listeners[type];
		}
	
		public function toString():String {
			var className:String = getQualifiedClassName(this);
			return "[" + className.substr(className.indexOf("::") + 2) + " " + name + "]";
		}
	
	}
}
