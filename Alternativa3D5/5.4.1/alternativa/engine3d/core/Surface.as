package alternativa.engine3d.core {
	import alternativa.engine3d.*;
	import alternativa.engine3d.errors.FaceExistsError;
	import alternativa.engine3d.errors.FaceNotFoundError;
	import alternativa.engine3d.errors.InvalidIDError;
	import alternativa.engine3d.materials.SurfaceMaterial;
	import alternativa.types.Set;
	
	use namespace alternativa3d;
	
	/**
	 * Поверхность &mdash; набор граней, объединённых в группу. Поверхности используются для установки материалов,
	 * визуализирующих грани объекта.
	 */
	public class Surface {
		// Операции
		/**
		 * @private
		 * Изменение набора граней
		 */		
		alternativa3d var changeFacesOperation:Operation = new Operation("changeFaces", this);
		/**
		 * @private
		 * Изменение материала
		 */		
		alternativa3d var changeMaterialOperation:Operation = new Operation("changeMaterial", this);

		/**
		 * @private
		 * Меш
		 */
		alternativa3d var _mesh:Mesh;
		/**
		 * @private
		 * Материал
		 */
		alternativa3d var _material:SurfaceMaterial;
		/**
		 * @private
		 * Грани
		 */
		alternativa3d var _faces:Set = new Set();
		
		/**
		 * Создание экземпляра поверхности.
		 */		
		public function Surface() {}
		
		/**
		 * Добавление грани в поверхность.
		 *  
		 * @param face экземпляр класса <code>alternativa.engine3d.core.Face</code> или идентификатор грани полигонального объекта
		 * 
		 * @throws alternativa.engine3d.errors.FaceNotFoundError грань не найдена в полигональном объекте содержащем поверхность
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 * @throws alternativa.engine3d.errors.FaceExistsError поверхность уже содержит указанную грань
		 * 
		 * @see Face 
		 */
		public function addFace(face:Object):void {
			var byLink:Boolean = face is Face;
			
			// Проверяем на нахождение поверхности в меше
			if (_mesh == null) {
				throw new FaceNotFoundError(face, this);
			}
			
			// Проверяем на null
			if (face == null) {
				throw new FaceNotFoundError(null, this);
			}
			
			// Проверяем наличие грани в меше
			if (byLink) {
				// Если удаляем по ссылке
				if (Face(face)._mesh != _mesh) {
					// Если грань не в меше
					throw new FaceNotFoundError(face, this);
				}
			} else {
				// Если удаляем по ID
				if (_mesh._faces[face] == undefined) {
					// Если нет грани с таким ID
					throw new FaceNotFoundError(face, this);
				} else { 
					if (!(_mesh._faces[face] is Face)) {
						throw new InvalidIDError(face, this);
					}
				}
			}
			
			// Находим грань
			var f:Face = byLink ? Face(face) : _mesh._faces[face];
			
			// Проверяем наличие грани в поверхности
			if (_faces.has(f)) {
				// Если грань уже в поверхности
				throw new FaceExistsError(f, this);
			}
			
			// Проверяем грань на нахождение в другой поверхности
			if (f._surface != null) {
				// Удаляем её из той поверхности
				f._surface._faces.remove(f);
				f.removeFromSurface(f._surface);
			}
			
			// Добавляем грань в поверхность
			_faces.add(f);
			f.addToSurface(this);
			
			// Отправляем операцию изменения набора граней
			_mesh.addOperationToScene(changeFacesOperation);
		}

		/**
		 * Удаление грани из поверхности.
		 *  
		 * @param face экземпляр класса <code>alternativa.engine3d.core.Face</code> или идентификатор грани полигонального объекта
		 * 
		 * @throws alternativa.engine3d.errors.FaceNotFoundError поверхность не содержит указанную грань
		 * @throws alternativa.engine3d.errors.InvalidIDError указано недопустимое значение идентификатора
		 * 
		 * @see Face
		 */
		public function removeFace(face:Object):void {
			var byLink:Boolean = face is Face;
			
			// Проверяем на нахождение поверхности в меше
			if (_mesh == null) {
				throw new FaceNotFoundError(face, this);
			}
			
			// Проверяем на null
			if (face == null) {
				throw new FaceNotFoundError(null, this);
			}
			
			// Проверяем наличие грани в меше
			if (byLink) {
				// Если удаляем по ссылке
				if (Face(face)._mesh != _mesh) {
					// Если грань не в меше
					throw new FaceNotFoundError(face, this);
				}
			} else {
				// Если удаляем по ID
				if (_mesh._faces[face] == undefined) {
					// Если нет грани с таким ID
					throw new FaceNotFoundError(face, this);
				} else {
					if (!(_mesh._faces[face] is Face)) {
						throw new InvalidIDError(face, this);
					}
				}
				
			}
			
			// Находим грань
			var f:Face = byLink ? Face(face) : _mesh._faces[face];
			
			// Проверяем наличие грани в поверхности
			if (!_faces.has(f)) {
				// Если грань не в поверхности
				throw new FaceNotFoundError(f, this);
			}
			
			// Удаляем грань из поверхности
			_faces.remove(f);
			f.removeFromSurface(this);
			
			// Отправляем операцию изменения набора граней
			_mesh.addOperationToScene(changeFacesOperation);
		}
		
		/**
		 * Материал поверхности. При установке нового значения, устанавливаемый материал будет удалён из старой поверхности.
		 */
		public function get material():SurfaceMaterial {
			return _material;
		}

		/**
		 * @private
		 */
		public function set material(value:SurfaceMaterial):void {
			if (_material != value) {
				// Если был материал
				if (_material != null) {
					// Удалить материал из поверхности
					_material.removeFromSurface(this);
					// Удалить материал из меша
					if (_mesh != null) {
						_material.removeFromMesh(_mesh);
						// Удалить материал из сцены
						if (_mesh._scene != null) {
							_material.removeFromScene(_mesh._scene);
						}
					}
				}
				// Если новый материал
				if (value != null) {
					// Если материал был в другой поверхности
					if (value._surface != null) {
						// Удалить его оттуда
						value._surface.material = null;
					}
					// Добавить материал в поверхность
					value.addToSurface(this);
					// Добавить материал в меш
					if (_mesh != null) {
						value.addToMesh(_mesh);
						// Добавить материал в сцену
						if (_mesh._scene != null) {
							value.addToScene(_mesh._scene);
						}
					}
				}
				// Сохраняем материал
				_material = value;
				// Отправляем операцию изменения материала
				addMaterialChangedOperationToScene();
			}
		}
		
		/**
		 * Набор граней поверхности.
		 */
		public function get faces():Set {
			return _faces.clone();
		}
		
		/**
		 * Полигональный объект, которому принадлежит поверхность.
		 */		
		public function get mesh():Mesh {
			return _mesh;
		}
		
		/**
		 * Идентификатор поверхности в полигональном объекте. Если поверхность не принадлежит ни одному объекту,
		 * значение идентификатора равно <code>null</code>.
		 */
		public function get id():Object {
			return (_mesh != null) ? _mesh.getSurfaceId(this) : null;
		}
		
		/**
		 * @private
		 * Добавление в сцену.
		 * 
		 * @param scene
		 */
		alternativa3d function addToScene(scene:Scene3D):void {
			// Добавляем на сцену материал
			if (_material != null) {
				_material.addToScene(scene);
			}
		}
		
		/**
		 * @private
		 * Удаление из сцены.
		 * 
		 * @param scene
		 */
		alternativa3d function removeFromScene(scene:Scene3D):void {
			// Удаляем все операции из очереди
			scene.removeOperation(changeFacesOperation);
			scene.removeOperation(changeMaterialOperation);
			// Удаляем из сцены материал
			if (_material != null) {
				_material.removeFromScene(scene);
			}
		}
		
		/**
		 * @private
		 * Добавление к мешу
		 * @param mesh
		 */		
		alternativa3d function addToMesh(mesh:Mesh):void {
			// Подписка на операции меша
			
			// Добавляем в меш материал
			if (_material != null) {
				_material.addToMesh(mesh);
			}
			// Сохранить меш
			_mesh = mesh;
		}
		
		/**
		 * @private
		 * Удаление из меша
		 * 
		 * @param mesh
		 */
		alternativa3d function removeFromMesh(mesh:Mesh):void {
			// Отписка от операций меша
			
			// Удаляем из меша материал
			if (_material != null) {
				_material.removeFromMesh(mesh);
			}
			// Удалить ссылку на меш
			_mesh = null;
		}
		
		/**
		 * @private
		 * Удаление граней
		 */
		alternativa3d function removeFaces():void {
			for (var key:* in _faces) {
				var face:Face = key;
				_faces.remove(face);
				face.removeFromSurface(this);
			}
		}

		/**
		 * @private
		 * Изменение материала
		 */
		alternativa3d function addMaterialChangedOperationToScene():void {
			if (_mesh != null) {
				_mesh.addOperationToScene(changeMaterialOperation);
			}
		}

		/**
		 * Строковое представление объекта.
		 * 
		 * @return строковое представление объекта
		 */
		public function toString():String {
			var length:uint = _faces.length;
			var res:String = "[Surface ID:" + id + ((length > 0) ? " faces:" : "");
			var i:uint = 0;
			for (var key:* in _faces) {
				var face:Face = key;
				res += face.id + ((i < length - 1) ? ", " : "");
				i++;
			}
			res += "]";
			return res;
		}		
	}
}