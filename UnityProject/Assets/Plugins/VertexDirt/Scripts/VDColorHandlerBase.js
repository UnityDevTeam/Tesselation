/* 
	VertexDirt plug-in for Unity
	Copyright 2014, Zoltan Farago, All rights reserved.
*/
#pragma strict

class VDColorHandlerBase extends MonoBehaviour {

	@HideInInspector
	var colors : Color32[];
	//@HideInInspector
	var coloredMesh : Mesh;
	//@HideInInspector
	var originalMesh : Mesh;
	
	function Refresh() {}

}