package alternativa.engine3d.loaders.collada {
	import flash.utils.Dictionary;
	


	/**
	 * @private
	 */
	public class DaeInstanceController extends DaeElement {
	
		use namespace collada;

		public var node:DaeNode;

		/**
		 * Список верхнеуровневых костей, которые имеют общего предка.
		 * Перед использованием вызвать parse(). 
		 */
		public var topmostJoints:Vector.<DaeNode>;

		public function DaeInstanceController(data:XML, document:DaeDocument, node:DaeNode) {
			super(data, document);
			this.node = node;
		}

		override protected function parseImplementation():Boolean {
			var controller:DaeController = this.controller;
			if (controller != null) {
				topmostJoints = controller.findRootJointNodes(this.skeletons);
				if (topmostJoints != null && topmostJoints.length > 1) {
					replaceNodesByTopmost(topmostJoints);
				}
			}
			return topmostJoints != null;
		}

		/**
		 * Заменяет каждую ноду в списке на ее родителя, у которого родитель является общим для всех остальных нод или является сценой. 
		 * @param nodes не пустой массив нод
		 */
		private function replaceNodesByTopmost(nodes:Vector.<DaeNode>):void {
			var i:int;
			var node:DaeNode, parent:DaeNode;
			var numNodes:int = nodes.length;
			var parents:Dictionary = new Dictionary();
			for (i = 0; i < numNodes; i++) {
				node = nodes[i];
				for (parent = node.parent; parent != null; parent = parent.parent) {
					if (parents[parent]) {
						parents[parent]++;
					} else {
						parents[parent] = 1;
					}
				}
			}
			// Заменяем на родителей нод, которые имеют общего родителя с остальными нодами или не имеют родителя вообще.
			for (i = 0; i < numNodes; i++) {
				node = nodes[i];
				while ((parent = node.parent) != null && (parents[parent] != numNodes)) {
					node = node.parent;
				}
				nodes[i] = node;
			}
		}

		private function get controller():DaeController {
			var controller:DaeController = document.findController(data.@url[0]);
			if (controller == null) {
				document.logger.logNotFoundError(data.@url[0]);
			}
			return controller;
		}

		private function get skeletons():Vector.<DaeNode> {
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

		public function parseSkin(materials:Object):DaeObject {
			var controller:DaeController = this.controller;
			if (controller != null) {
				controller.parse();
				return controller.parseSkin(materials, topmostJoints, this.skeletons);
			}
			return null;
		}

	}
}
