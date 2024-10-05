package alternativa.engine3d.objects {
	import alternativa.engine3d.core.Vertex;
	
	public class VertexBinding {
	
		public var next:VertexBinding;
	
		public var vertex:Vertex;
		public var weight:Number = 0;
	
	}
}