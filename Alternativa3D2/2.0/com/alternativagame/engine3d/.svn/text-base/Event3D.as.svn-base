package com.alternativagame.engine3d {
	import flash.events.Event;
	import com.alternativagame.engine3d.material.Material;
	import com.alternativagame.type.Vector;
	import com.alternativagame.engine3d.object.Object3D;
	import com.alternativagame.engine3d.object.mesh.polygon.Polygon3D;

	public class Event3D extends Event {
		
		static public const DOWN:String = "3DDown";
		static public const UP:String = "3DUp";
		static public const CLICK:String = "3DClick";
		
		public var ctrlKey:Boolean;
		public var altKey:Boolean;
		public var shiftKey:Boolean;

		public var object:Object3D;
		public var polygon:Polygon3D;
		public var material:Material;
		public var canvasCoords:Vector;
		public var objectCoords:Vector;
		public var currentObjectCoords:Vector;
		
		public function Event3D(type:String, ctrlKey:Boolean = false, altKey:Boolean = false, shiftKey:Boolean = false, object:Object3D = null, polygon:Polygon3D = null, material:Material = null, canvasCoords:Vector = null, objectCoords:Vector = null, currentObjectCoords:Vector = null) {
			super(type);
			
			this.ctrlKey = ctrlKey;
			this.altKey = altKey;
			this.shiftKey = shiftKey;

			this.object = object;
			this.polygon = polygon;
			this.material = material;
			this.canvasCoords = canvasCoords;
			this.objectCoords = objectCoords;
			this.currentObjectCoords = currentObjectCoords;
			
		}
		
	}
}