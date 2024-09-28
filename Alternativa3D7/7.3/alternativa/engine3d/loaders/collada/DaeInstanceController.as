package alternativa.engine3d.loaders.collada {


	/**
	 * @private
	 */
	public class DaeInstanceController extends DaeElement {
	
		use namespace collada;
	
		public var node:DaeNode;
	
		public var skin:DaeAnimatedObject;
	
		public function DaeInstanceController(data:XML, document:DaeDocument, node:DaeNode) {
			super(data, document);
			this.node = node;
		}
		
		public function get controller():DaeController {
			var controller:DaeController = document.findController(data.@url[0]);
			if (controller == null) {
				document.logger.logNotFoundError(data.@url[0]);
			}
			return controller;
		}
	
		public function get skeletons():Vector.<DaeNode> {
			var list:XMLList = data.skeleton;
			if (list.length() > 0) {
				var skeletons:Vector.<DaeNode> = new Vector.<DaeNode>();
				for (var i:int = 0, count:int = list.length(); i < count; i++) {
					var skeletonXML:XML = list[i];
					var skel:DaeNode = document.findNode(skeletonXML.text()[0]);
					if (skel != null) {
						skeletons.push(skel);
					} else {
						document.logger.logNotFoundError(skeletonXML);
					}
				}
				return skeletons;
			}
			return null;
		}
	
		public function findRootJointNodes():Vector.<DaeNode> {
			var controller:DaeController = this.controller;
			if (controller != null) {
				return controller.findRootJointNodes(this.skeletons);
			}
			return null;
		}
	
	}
}
