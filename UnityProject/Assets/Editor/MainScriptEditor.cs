using UnityEditor;
using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

public class MyWindow : EditorWindow
{	

	//atom buffer
	public ComputeBuffer atomBuffer;
	//public float SpriteSize;
	// Add menu item named "My Window" to the Window menu
	[MenuItem("CellUnity/Show Window")]
	public static void ShowWindow()
	{
		//Show existing window instance. If one doesn't exist, make one.
		EditorWindow.GetWindow(typeof(MyWindow));
	}
	
	void OnGUI()
	{
		if(GUILayout.Button ("Load MCell Scene")) 
		{
			LoadScene();
		}
	}

	public Texture2D createAtomTexture(Vector4[] vertices)
	{
		int maxTexSize = 1024;
		var positionTexture = new Texture2D(maxTexSize, maxTexSize, TextureFormat.ARGB32, false);
		var pixels = new Color[maxTexSize * maxTexSize];
		for (int j=0; j<vertices.Length; j++)
			pixels [j] = new Color(vertices[j].x,vertices[j].y, vertices[j].z, vertices[j].w);
	
		positionTexture.SetPixels (pixels);
		positionTexture.Apply ();
		return positionTexture;
	}
	
	public ComputeBuffer createAtomBuffer(Vector4[] vertices)
	{
		var buffer = new ComputeBuffer (vertices.Length, 16); 
		//vertices [0].Set (0, 10, 0, 0);
		buffer.SetData(vertices);
		return buffer;
	}
	
	public void LoadScene()
	{
		List<Vector4> molAtomPositions = ReadPdbFileSimple ();
		int molCount = 100; //molAtomPositions.Count;
		Vector3[] vertices = new Vector3[molCount];
		int[] indices = new int[molCount];

		for (var i=0; i < molCount; i++)
		{
			indices[i] = i;
			vertices[i] = new Vector3 ( (UnityEngine.Random.value - 0.5f), (UnityEngine.Random.value - 0.5f), (UnityEngine.Random.value - 0.5f))*200.0f;
			//vertices[i] = new Vector3 ( molAtomPositions[i].x, molAtomPositions[i].y, molAtomPositions[i].z);
		}

		GameObject gameObject = GameObject.Find ("Main Object");

		if (gameObject != null)
			GameObject.DestroyImmediate (gameObject);

		gameObject = new GameObject("Main Object");
		gameObject.AddComponent<MainScript>();		

		
		MeshRenderer meshRenderer = gameObject.AddComponent<MeshRenderer>();
		meshRenderer.material = Resources.Load("MolMaterial") as Material;
		//create and setup texture with atoms
		//Debug.Log (@"Creating atom texture");
		//var tex = createAtomTexture (vertices);
		//meshRenderer.sharedMaterial.SetTexture ("_AtomTexture", tex);
		Debug.Log (@"Creating atom buffer");

		if (atomBuffer==null)
			atomBuffer = createAtomBuffer (molAtomPositions.ToArray());

		meshRenderer.sharedMaterial.SetBuffer ("_AtomBuffer", atomBuffer);
		meshRenderer.sharedMaterial.SetColor ("_Color", Color.red);
		meshRenderer.sharedMaterial.SetFloat ("_SpriteSize", 0.4f);

		
		MeshFilter meshFilter = gameObject.AddComponent<MeshFilter>();	
		meshFilter.sharedMesh = new Mesh();
		meshFilter.sharedMesh.vertices = vertices;
		meshFilter.sharedMesh.SetIndices(indices, MeshTopology.Points, 0);

	}

	public List<Vector4> ReadPdbFileSimple()
	{
		// clear molPositions
		List<Vector4> molAtomPositions = new List<Vector4>();
		
		// radiuses
		Dictionary<string, float> van_der_waals = new Dictionary<string, float>();
		
		van_der_waals["F"]=1.47f;
		van_der_waals["CL"]= 1.89f;
		van_der_waals["H"]=1.100f;
		van_der_waals["C"]=1.548f;
		van_der_waals["N"]=1.400f;
		van_der_waals["O"]=1.348f;
		van_der_waals["P"]=1.880f;
		van_der_waals["S"]=1.808f;
		van_der_waals["CA"]=1.948f;
		van_der_waals["FE"]=1.948f;
		van_der_waals["ZN"]=1.148f;
		van_der_waals["I"]=1.748f;	
		
		string[] lines = System.IO.File.ReadAllLines(@"c:\Users\julius\workspace\mcell\another\UnityPrototype\UnityProject\Assets\Mol\p3.pdb");
		Debug.Log (@"c:\Users\julius\workspace\mcell\another\UnityPrototype\UnityProject\Assets\Mol\p3.pdb");
		foreach (string line in lines) 
		{
			float defaultAtomSize = 1.5f;
			Vector4 atom=new Vector4(0.0f, 0.0f, 0.0f, defaultAtomSize);
			if (line.StartsWith("ATOM") || line.StartsWith("HETATM"))
			{
				string[] split = line.Split(new char[]{' '},  StringSplitOptions.RemoveEmptyEntries);
				List<string> position = new List<string>();
				
				foreach (string s in split)
					if(s.Contains(".")) position.Add(s);
				
				atom.x = float.Parse(position[0]);
				atom.y = float.Parse(position[1]);
				atom.z = float.Parse(position[2]);
				if (van_der_waals.ContainsKey(split[1])) atom.w = van_der_waals[split[1]];
				molAtomPositions.Add(atom);
			}
		}
		
		// Find the bounding box of the molecule and align the molecule with the origin 
		Vector3 bbMin=new Vector3(float.PositiveInfinity, float.PositiveInfinity, float.PositiveInfinity);
		Vector3 bbMax=new Vector3(float.NegativeInfinity, float.NegativeInfinity, float.NegativeInfinity);
		Vector3 bbCenter;	
		
		foreach (Vector4 atom in molAtomPositions)
		{
			bbMin = Vector3.Min(bbMin,new Vector3(atom.x,atom.y,atom.z));
			bbMax = Vector3.Max(bbMax,new Vector3(atom.x,atom.y,atom.z));
		}
		bbCenter = 0.5f*(bbMin+bbMax);
		molAtomPositions.ForEach (delegate(Vector4 atom) {
			atom.x -= bbCenter.x;
			atom.y -= bbCenter.y;
			atom.z -= bbCenter.z;
		});
		
		bbMax -= bbCenter;
		bbMin -= bbCenter;
		// Store values	
		//molAtomCount.Add(molAtomPositions.size());
		//molAtomStart.Add(molAtomPositionsAll.size());
		//molAtomPositionsAll += molAtomPositions;
		//molCount++;
		return molAtomPositions;
	}
}
