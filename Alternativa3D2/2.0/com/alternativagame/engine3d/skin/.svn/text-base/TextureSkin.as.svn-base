package com.alternativagame.engine3d.skin {
	import com.alternativagame.engine3d.object.mesh.polygon.TexturePolygon3D;
	import com.alternativagame.engine3d.material.TextureMaterial;
	import com.alternativagame.type.RGB;
	import com.alternativagame.engine3d.engine3d;
	
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;

	use namespace engine3d;
	
	public class TextureSkin extends FillSkin {

		use namespace engine3d;

		private var textureMatrix:Matrix;
		private var texture:BitmapData = null;
		private var aUV:Point;
		private var bUV:Point;
		private var cUV:Point;

		public function TextureSkin(polygon:TexturePolygon3D) {
			super(polygon);
		}

		override protected function drawPolygon(bx:int, by:int, cx:int, cy:int):void {
			var poly:TexturePolygon3D = TexturePolygon3D(polygon);
			var material:TextureMaterial = TextureMaterial(poly.material);
			var textureEnabled:Boolean = (material.texture != null) && (poly.aUV != null) && (poly.bUV != null) && (poly.cUV != null);
			
			if (textureEnabled) {
				// Если изменилась текстура или UV-координаты, пересчитываем матрицу текстуры
				if ((texture != material.texture) || (aUV != poly.aUV) || (bUV != poly.bUV) || (cUV != poly.cUV)) {

					// Сохраняем ссылки на текстуру и UV-координаты
					texture = material.texture;
					aUV = poly.aUV;
					bUV = poly.bUV;
					cUV = poly.cUV;
	
					// Преобразование текстуры под UV координаты
					textureMatrix = new Matrix();
					textureMatrix.tx = aUV.x * texture.width;
					textureMatrix.ty = -aUV.y * texture.height;
					textureMatrix.a = (bUV.x - aUV.x) * texture.width;
					textureMatrix.b = (aUV.y - bUV.y) * texture.height;
					textureMatrix.c = (cUV.x - aUV.x) * texture.width;
					textureMatrix.d = (aUV.y - cUV.y) * texture.height;
					textureMatrix.invert();
				}
			
				var drawMatrix:Matrix = textureMatrix.clone();
				drawMatrix.concat(new Matrix(bx, by, cx, cy));
				with (graphics) {
					clear();
					beginBitmapFill(texture, drawMatrix, true, material.smoothing);
					lineTo(bx, by);
					lineTo(cx, cy);
				}
			} else {
				super.drawPolygon(bx, by, cx, cy);
			}
		}
		
	}
}