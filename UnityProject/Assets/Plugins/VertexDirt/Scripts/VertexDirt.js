
/* 
	VertexDirt plug-in for Unity
	Copyright 2014, Zoltan Farago, All rights reserved.
*/
	
#pragma strict
#pragma downcast

/*
	class: VertexDirt

	Main Vertex dirt class. VertexDirt is a vertex colour generator plug-in. Use this to generate Ambient occlusion or other advanced lightings.
*/
static class VertexDirt {

	// private variables for mesh merging and vertex sampling
	private var o : Array = new Array[1];
	private var v : Vector3[];
	private var n : Vector3[];
	private var c : Color32[];
	
	/*
		variable: vertexSample
		
		public variable, but this is used by the baking.
	*/
	var vertexSample : VertexSample = new VertexSample();
	
	/*
		integer: sampleWidth

		Vertical resolution of the sample. The default value of 64 should be fine in all circumstances. 
		Lower values could cause visual artefacts.
	*/
	var sampleWidth : int = 64;

	/*
		integer: sampleHeight

		Horizontal resolution of the sample. The default value of 64 should be fine in all circumstances. 
		Lower values could cause visual artefacts.
	*/	
	var sampleHeight : int = 64;
	
	/*
		float: samplingBias

		The near clip plane of the sampling camera.
	*/
	var samplingBias : float = 0.001;
	
	/*
		float: samplingDistance

		The far clip plane of the sampling camera.
	*/
	var samplingDistance : float = 100;

	/*
		float: samplingAngle

		The FOV of the sampling camera. Please note that this value normally should be between 100-160.
	*/
	var samplingAngle : float = 100;
	
	/*
		boolean: edgeSmooth

		Enable to smoothing out hard edges. Basically just averages the normals of the vertices in the same position.
	*/
	var edgeSmooth : boolean = false;

	/*
		boolean: invertNormals

		Set true if you want to render the inside of the objects. Use this parameter enabled to render thickness.
	*/
	var invertNormals : boolean = false;

	/*
		float: edgeSmoothBias

		The range of edge smoothing. The normals of vertices closer than this value will be averaged.
	*/
	var edgeSmoothBias : float = 0.001;

	/*
		enumeration: skyMode

		Parameter for sampling camera backdrop. 
	*/
	var skyMode : CameraClearFlags = CameraClearFlags.SolidColor;

	/*
		boolean: disableOccluders

		Set true if you only want to bake the background colour/cubeMap to the vertex colours.
		
	*/
	var disableOccluders : boolean = false;

	/*
		variable: skyColor

		The colour of the Sky.
	*/
	var skyColor : Color = Color.white;
	
	/*
		variable: globalOccluderColor

		Colour tint for the occluders. This property is designed for the VDOccluder shader.
	*/
	var globalOccluderColor : Color = Color.black;

	/*
		string: occluderShader

		The shader used on occluders during the bake. The default VD shader is "Hidden/VDOccluder AO"
		If this string is empty or the shader is not exist, then the occluder objects will use their original shaders. 

	*/
	var occluderShader : String = VDSHADER.AMBIENTOCCLUSION;
		
	/*
		variable: skyCube

		The cubeMap of the sampling camera's sky.
	*/
	var skyCube : Material;

	/*
		variable: colorHandlerClass

		The component to store baked vertex color data. The component must derived from VDColorHandlerBase class.
		The default class is VDColorHandler.
	*/
	var colorHandlerClass : String = "VDColorHandler";

	/* 
		function: Dirt
		
		Main function for vertex baking. If you call it without any parameter, then the actual object selection will be used.
	*/
	function Dirt() {
	
		Dirt ( Selection.GetFiltered(Transform, SelectionMode.Deep) );
	
	}

	/* 
		function: Dirt
		
		Main function for vertex baking. The the Object[] array will be used.
	*/
    function Dirt(sels : Object[]) {
	
 		if (sels.Length > 0) {
			
			//vertex camera
			var camGO : GameObject = new GameObject("VDSamplerCamera"); 
			var cam : Camera = camGO.AddComponent(Camera);
			camGO.AddComponent("VDSampler");
			RenderTexture.active = null;
			cam.pixelRect = Rect(0,0,sampleWidth, sampleHeight);
			cam.aspect = 1.0;	
			cam.nearClipPlane = samplingBias;
			cam.farClipPlane = samplingDistance;
			cam.fieldOfView = Mathf.Clamp ( samplingAngle, 5, 160 );
			cam.clearFlags = skyMode;
			cam.backgroundColor = skyColor;
			var tempSkybox : Material = RenderSettings.skybox;
			if (skyMode == CameraClearFlags.Skybox) { RenderSettings.skybox = skyCube; }
			Shader.SetGlobalColor("_VDOccluderColor", globalOccluderColor);
			cam.SetReplacementShader(Shader.Find(occluderShader), disableOccluders ? "ibl-only" : "");
			CombineVertices(sels);
			ResetColors();
			SmoothVertices();
			CalcColors(camGO, cam);
			ApplyColors();
			RenderSettings.skybox = tempSkybox;
			GameObject.DestroyImmediate(camGO);
		
			var handlers : VDColorHandlerBase[] = UnityEngine.Object.FindObjectsOfType(VDColorHandlerBase);

			for (var handler : VDColorHandlerBase in handlers) {
			
				if (handler.originalMesh && !handler.coloredMesh) {
				
					handler.coloredMesh = UnityEngine.Object.Instantiate(handler.originalMesh);
					handler.gameObject.GetComponent(MeshFilter).mesh = handler.coloredMesh;
					
				}
			
			}
			
		}
 
    }

	/* 
		function: SetPreset
		
		Set preset for VertexDirt. Presets are for batch change common VertexDirt parameters.
	*/
	function SetPreset (v : VDPRESET) {
	
		switch (v) {
		
			case VDPRESET.AMBIENTOCCLUSION :
			
				invertNormals = false;
				skyMode = CameraClearFlags.SolidColor;
				disableOccluders = false;
				skyColor = Color.white;
				globalOccluderColor = Color.black;
				occluderShader = VDSHADER.AMBIENTOCCLUSION;
			
			break;

			case VDPRESET.INDIRECTLIGHTING :
			
				invertNormals = false;
				skyMode = CameraClearFlags.SolidColor;
				skyColor = Color.white;
				disableOccluders = false;
				occluderShader = VDSHADER.INDIRECTLIGHTING;
			
			break;

			case VDPRESET.AMBIENTCUBE :
			
				invertNormals = false;
				skyMode = CameraClearFlags.Skybox;
				occluderShader = VDSHADER.AMBIENTCUBE;
			
			break;

			case VDPRESET.THICKNESS :
			
				invertNormals = false;
				edgeSmooth = true;
				skyMode = CameraClearFlags.SolidColor;
				disableOccluders = false;
				skyColor = Color.white;
				globalOccluderColor = Color.black;
				occluderShader = VDSHADER.THICKNESS;
			
			break;
			
		}
	
	}

	/* 
		function: ResetSettings
		
		Reset every VertexDirt parameters to defaults.
	*/
	function ResetSettings () {
			
		sampleWidth  = 64;
		sampleHeight = 64;
		samplingBias = 0.001;
		samplingDistance = 100;
		samplingAngle = 100;
		edgeSmooth = false;
		invertNormals = false;
		edgeSmoothBias = 0.001;
		skyMode = CameraClearFlags.SolidColor;
		disableOccluders = false;
		skyColor = Color.white;
		globalOccluderColor = Color.black;
		occluderShader = "Hidden/VDOccluder AO";
		skyCube = null;

	}
	
	private function CombineVertices(sel : Object[]) {
	
		var vertexCount : int;
		o.Clear();
		v = new Vector3[0];
		n = new Vector3[0];
		c = new Color32[0];
		
		for (var go : Transform in sel) {
		
			if (go.gameObject.GetComponent(MeshFilter)) {
			
				if (!go.gameObject.GetComponent(VDColorHandlerBase)) {
				
					go.gameObject.AddComponent(colorHandlerClass);
			
				}
				
				var v0 = go.gameObject.GetComponent(MeshFilter).sharedMesh.vertices;
				var n0 = go.gameObject.GetComponent(MeshFilter).sharedMesh.normals;
				
				for (var t : int = 0; t < v0.Length; t++) {
				
					v0[t] = go.TransformPoint(v0[t]);
					n0[t] = Vector3.Normalize(go.TransformDirection(n0[t]));
				
				}
				
				vertexCount += v0.Length;
				o.Add(go.gameObject.GetComponent(MeshFilter));
				v = MergeVector3 (v, v0);
				n = MergeVector3 (n, n0);
								
			}
			
		}
	
	}
	
	function ResetColors() {
		
		c = new Color32[v.length];		
		
	}

	function ResetColors(Color32) {
		
		c = new Color32[v.length];		
		
	}

	private function SmoothVertices() {
	
		if (edgeSmooth) {
			
			for (var a = 0; a < v.length; a++) {
		
				for (var d = a; d < v.length; d++) {

					if (Vector3.Distance(v[a],v[d]) < edgeSmoothBias) {
				
						n[a] = Vector3.Normalize(n[a] + n[d]);
						n[d] = n[a];
										
					}

				}
			
			}

			for (var k : int = 0; k <c.length; k++) {
			
				c[k] = Color32 (255,255,255,255);
			
			}
			
		}

	}
	
	private function CalcColors(camGO : GameObject, cam : Camera) {
		
		for (var vv : int = 0; vv<v.Length; vv++) {
	
			camGO.transform.position = v[vv];

			if (invertNormals) {
			
				camGO.transform.LookAt(v[vv] - n[vv]);
				
			}
			else {
			
				camGO.transform.LookAt(v[vv] + n[vv]);
				
			}
			
			vertexSample.index = vv;
			vertexSample.isCalulated = false;
			cam.Render();
			var timeout : int = 0;
			
			while (!vertexSample.isCalulated || timeout < 1000) {
						
				++timeout;
			
			}
			c[vv] = vertexSample.color; // * Color(lum,lum,lum,1);

		}
		
	}
	
	function SetColorSample(c : Color32) {
	
		vertexSample.color = c;
		vertexSample.isCalulated = true;
	
	}

 	private function ApplyColors() {
	
		var count : int = 0;
	
		for (var m : MeshFilter in o) {
			
			var tc : Color32[] = new Color32[m.gameObject.GetComponent(VDColorHandlerBase).originalMesh.vertices.Length];
			
			for (var c0 : int = 0; c0 <m.gameObject.GetComponent(VDColorHandlerBase).originalMesh.vertices.Length; c0++) {
			
				tc[c0] = c[count];
				count++;
				
			}
			
			//m.mesh.colors32 = tc;
			m.gameObject.GetComponent(VDColorHandlerBase).colors = tc;
			m.gameObject.GetComponent(VDColorHandlerBase).Refresh();
		}	
	
	}
	
 
	private function MergeVector3 (v1 : Vector3[], v2 : Vector3[]) : Vector3[] {
	
		var v3 = new Vector3[v1.length + v2.length];
		System.Array.Copy (v1, v3, v1.length);
		System.Array.Copy (v2, 0, v3, v1.length, v2.length);
		return v3;
		
	}
	
}

//	Class for passing samples from sampler camera to the VertexDirt class. For internal use only

class VertexSample {

	var color : Color32 = Color.white;
	var index : int = 0;
	var isCalulated : boolean = false;

}