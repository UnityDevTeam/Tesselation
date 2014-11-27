/* 
	VertexDirt plug-in for Unity
	Copyright 2014, Zoltan Farago, All rights reserved.
*/
class VDAmbientOcclusionWindow extends EditorWindow {

	@MenuItem ("Tools/VertexDirt/Ambient Occlusion")
	static function ShowWindow () {

		var window : VDAmbientOcclusionWindow = ScriptableObject.CreateInstance.<VDAmbientOcclusionWindow>();
		
		window.position = Rect(100,100, 260,400);
		window.minSize = Vector2 (260,400);
		window.maxSize = Vector2 (260,400);
		window.title = "VD Ambient Occlusion";
		window.ShowUtility();
		VertexDirt.SetPreset (VDPRESET.AMBIENTOCCLUSION);

	}
	
    function OnGUI() {
	
		var h : int = 10;
	
		GUI.Label (Rect(10,h,240,20), "Dirt distance");
		h += 20;
		VertexDirt.samplingDistance = EditorGUI.Slider(Rect(10,h,240,20),VertexDirt.samplingDistance,0.01, 1000.0);
		h += 30;
		
		GUI.Label (Rect(10,h,240,20),"Edge smooth enabled");
		//h += 20;
		VertexDirt.edgeSmooth = GUI.Toggle(Rect(235,h,240,20),VertexDirt.edgeSmooth, "");
		h += 30;
		
		GUI.Label (Rect(10,h,240,20),"Sampling angle");
		h += 20;
		VertexDirt.samplingAngle = EditorGUI.Slider(Rect(10,h,240,20),VertexDirt.samplingAngle,80, 160);
		h += 30;
		//VertexDirt.skyCube = EditorGUILayout.ObjectField(VertexDirt.skyCube, Material, true);

		GUI.Label (Rect(10,h,240,20),"Sky color");
		h += 20;
		VertexDirt.skyColor = EditorGUI.ColorField(Rect(10,h,240,20), VertexDirt.skyColor);
		h += 30;
		
		GUI.Label (Rect(10,h,240,20),"Shadow color");
		h += 20;
		VertexDirt.globalOccluderColor = EditorGUI.ColorField(Rect(10,h,240,20), VertexDirt.globalOccluderColor);
		
		h += 40;
		
//		globalOccluderColor = Color.black;
		
 		if (Selection.gameObjects) {
		
			if (GUI.Button(Rect(10,350,240,40),"Start") ) {

				var tempTime : float = EditorApplication.timeSinceStartup;
				VertexDirt.Dirt();
				Debug.Log ("Dirt time: " + (EditorApplication.timeSinceStartup - tempTime));
		
			}
			
		}
 
    }
	
}