/* 
	VertexDirt plug-in for Unity
	Copyright 2014, Zoltan Farago, All rights reserved.
*/
#pragma strict
@ExecuteInEditMode()

class VDColorHandler extends VDColorHandlerBase {

	function Refresh() {

		var meshFilter : MeshFilter = gameObject.GetComponent(MeshFilter);
		DestroyImmediate(coloredMesh);
		coloredMesh = Instantiate(originalMesh);
		meshFilter.mesh = coloredMesh;
		coloredMesh.colors32 = colors;
		gameObject.GetComponent(MeshFilter).mesh = coloredMesh;			

	}
	
	function OnDisable() {
	
		gameObject.GetComponent(MeshFilter).mesh = originalMesh;
	
	}

	function OnEnable() {
	
		var meshFilter : MeshFilter = gameObject.GetComponent(MeshFilter);

		if (!originalMesh) {
		
			originalMesh = meshFilter.sharedMesh;
		
		}
		
		if (coloredMesh) {
		
			meshFilter.mesh = coloredMesh;
		
		}
			
	}
	
}