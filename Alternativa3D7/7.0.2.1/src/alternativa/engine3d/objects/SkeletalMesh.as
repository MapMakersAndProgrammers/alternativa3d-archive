package alternativa.engine3d.objects {
	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.alternativa3d;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace alternativa3d;
	
	public class SkeletalMesh extends Mesh {
	
		alternativa3d var _numBones:uint = 0;
		alternativa3d var bones:Vector.<Bone> = new Vector.<Bone>();
		private var weights:Vector.<Vector.<Number>>;
		private var originalVertices:Vector.<Number>;
		private var originalBonesMatrices:Vector.<Matrix3D>;
		private var boneVertices:Vector.<Number>;
		
		public function initBones():void {
			// Инициализируем массив весов и сохраняем оригинальные матрицы костей
			originalBonesMatrices = new Vector.<Matrix3D>(_numBones, true);
			weights = new Vector.<Vector.<Number>>(_numBones, true);
			for (var j:int = 0; j < _numBones; j++) {
				originalBonesMatrices[j] = new Matrix3D();
				originalBonesMatrices[j].prepend(bones[j].matrix);
				originalBonesMatrices[j].invert();
				weights[j] = new Vector.<Number>(numVertices, true);
			}
			// Формируем вспомогательные массивы для вершин  
			originalVertices = new Vector.<Number>(numVertices*3, true);
			boneVertices = new Vector.<Number>(numVertices*3, true);
			
			// Обрабатываем вершины
			var v:Vector3D = new Vector3D();
			for (var i:int = 0; i < numVertices; i++) {
				var k:int = i*3;
				// Сохраняем оригинальные координаты вершин
				originalVertices[k] = vertices[k];
				originalVertices[k + 1] = vertices[k + 1];
				originalVertices[k + 2] = vertices[k + 2];
				
				// Находим веса для каждой кости
				var sumWeight:Number = 0;
				for (j = 0; j < _numBones; j++) {
					// Находим расстояние от вершины до кости
					var b1:Vector3D = bones[j].matrix.transformVector(new Vector3D());
					var b2:Vector3D = bones[j].matrix.transformVector(new Vector3D(0, 0, bones[j].length));
					v.x = originalVertices[k];
					v.y = originalVertices[k + 1];
					v.z = originalVertices[k + 2];
					var w:Number = 1 - distanceToBone(b1, b2, v)/bones[j].distance;
					//trace(w);
					w = (w > 0) ? w : 0;
					weights[j][i] = w;
					sumWeight += w;
				}
				  
				// Нормализуем веса
				if (sumWeight > 0) {
					for (j = 0; j < _numBones; j++) {
						weights[j][i] /= sumWeight;
					}
				} else {
					// Если вершина не относится ни к какой кости, помечаем
					for (j = 0; j < _numBones; j++) { 
						weights[j][i] = -1;
					}
				}
				
			}
		}
		
		private function distanceToBone(b1:Vector3D, b2:Vector3D, p:Vector3D):Number {
		    var v:Vector3D = b2.subtract(b1);
		    var w:Vector3D = p.subtract(b1);
		
		    var c1:Number = w.dotProduct(v);
		    if ( c1 <= 0 )
		        return Vector3D.distance(p, b1);
		
		    var c2:Number = v.dotProduct(v);
		    if ( c2 <= c1 )
		        return Vector3D.distance(p, b2);
		
		    v.scaleBy(c1 / c2);
		    var Pb:Vector3D = b1.add(v);
		    return Vector3D.distance(p, Pb);
			
			
		}
		
		private var m:Matrix3D = new Matrix3D();
		public function calculateBones():void {
			// Обнуление координат
			for (var i:int = 0; i < numVertices*3; i++) {
				vertices[i] = 0;
			}
			// Добавление трансформации через кости
			for (var j:int = 0; j < _numBones; j++) {
				m.identity();
				m.prepend(bones[j].matrix);
				m.prepend(originalBonesMatrices[j]);
				m.transformVectors(originalVertices, boneVertices);
				var boneWeights:Vector.<Number> = weights[j];
				for (i = 0; i < numVertices; i++) {
					var weight:Number = boneWeights[i];
					var k1:int = i*3;
					var k2:int = k1 + 1;
					var k3:int = k1 + 2;
					if (weight >= 0) {
						vertices[k1] += boneVertices[k1]*weight;
						vertices[k2] += boneVertices[k2]*weight;
						vertices[k3] += boneVertices[k3]*weight;
					} else {
						vertices[k1] = originalVertices[k1];
						vertices[k2] = originalVertices[k2];
						vertices[k3] = originalVertices[k3];
					}
				}
			}
		}

		public function addBone(bone:Bone):void {
			bones[_numBones++] = bone;
		}
/*
		public function removeChild(bone:Bone):void {
			var i:int = bones.indexOf(bone);
			if (i < 0) throw new ArgumentError();
			children.splice(i, 1);
			_numBones--;
			var len:uint = drawChildren.length;
			for (i = 0; i < len; i++) {
				if (drawChildren[i] == bone) {
					drawChildren.splice(i, 1);
					break;
				}
			}
			bone._parent = null;
			bone.setStage(null);
		}
*/	



	}
}