package alternativa.engine3d.loaders {

	import __AS3__.vec.Vector;
	
	import alternativa.engine3d.materials.CommonMaterial;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.TextureMaterial;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	
	public class CommonMaterialsLoader extends EventDispatcher {

		public var materials:Dictionary;
		private var originals:Vector.<Material>;
		private var currentMaterialIndex:int;
		private var currentComponentIndex:int;

		private var loader:Loader;
		private var context:LoaderContext;

		public function CommonMaterialsLoader() {
		}

		public function load(materials:Vector.<Material>, context:LoaderContext = null):void {
			this.originals = materials;
			this.materials = new Dictionary(false);
			this.context = context;
			currentMaterialIndex = 0;
			currentComponentIndex = 0;
			loadTexture();
		}

		private function loadTexture():void {
			var material:Material = originals[currentMaterialIndex];
			while (material != null) {
				var url:String = null;
				if (currentComponentIndex == 0) {
					if (material is TextureMaterial) url = TextureMaterial(material).diffuseMapURL;
				}
				if (currentComponentIndex <= 1 && url == null) {
					if (material is TextureMaterial) url = TextureMaterial(material).opacityMapURL;
					currentComponentIndex = 1;
				}
				if (currentComponentIndex <= 2 && url == null) {
					url = material.normalMapURL;
					currentComponentIndex = 2;
				}
				if (currentComponentIndex <= 3 && url == null) {
					url = material.specularMapURL;
					currentComponentIndex = 3;
				}
				if (currentComponentIndex <= 4 && url == null) {
					url = material.emissionMapURL;
					currentComponentIndex = 4;
				}
				if (url != null) {
					loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onTextureLoad);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
					loader.load(new URLRequest(url));
					return;
				}
				currentComponentIndex = 0;
				currentMaterialIndex++;
				material = (currentMaterialIndex < originals.length) ? originals[currentMaterialIndex] : null;
			}
			originals = null;
			loader = null;
			context = null;
			dispatchEvent(new Event(Event.COMPLETE));
		}

		private function onTextureLoad(e:Event):void {
			var original:Material = originals[currentMaterialIndex];
			var material:CommonMaterial = materials[original];
			if (material == null) {
				material = new CommonMaterial();
				material.name = original.name;
				materials[original] = material;
			}
			var bmd:BitmapData = Bitmap(loader.content).bitmapData;
			switch (currentComponentIndex) {
				case 0: // diffuse
					material.diffuse = bmd;
					break;
				case 1: // opacity
					material.opacity = bmd;
					break;
				case 2: // normals
					material.normals = bmd;
					break;
				case 3: // specular
					material.specular = bmd;
					break;
				case 4: // emission
					material.emission = bmd;
					break;
			}
			currentComponentIndex++;
			loadTexture();
		}

		private function onError(e:Event):void {
			currentComponentIndex++;
			loadTexture();
		}

	}
}
