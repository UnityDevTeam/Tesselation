using UnityEngine;

using System;
using System.Collections;
using System.Collections.Generic;

public class MainScript : MonoBehaviour
{
	public int molCount = 1000;
	private int atomCount = 0;

	private Material molMaterial;

	private ComputeBuffer molBuffer;
	private ComputeBuffer atomBuffer;

	private RenderTexture renderTexture;

	public void createMolBuffer()
	{
		Vector4[] molPositions = new Vector4[molCount];
		
		for (var i=0; i < molCount; i++)
		{
			molPositions[i].Set((UnityEngine.Random.value - 0.5f) * 100.0f, 
			                    (UnityEngine.Random.value - 0.5f) * 100.0f,
			                    (UnityEngine.Random.value - 0.5f) * 100.0f,
			                    1);
		}
		
		molBuffer = new ComputeBuffer (molPositions.Length, 16); 
		molBuffer.SetData(molPositions);
	}

	public void createAtomBuffer()
	{
		Vector4[] atomPositions = PdbReader.ReadPdbFileSimple().ToArray();
		atomCount = atomPositions.Length;

		Debug.Log ("Atom count: " + atomCount);

		atomBuffer = new ComputeBuffer (atomPositions.Length, 16); 
		atomBuffer.SetData(atomPositions);
	}

	public void createMolMaterial()
	{
		molMaterial = Resources.Load<Material> ("MolMaterial");		

		molMaterial.SetBuffer ("molPositions", molBuffer);
		molMaterial.SetBuffer ("atomPositions", atomBuffer);
	}

	void Awake ()
	{
		createMolBuffer ();
		createAtomBuffer ();
		createMolMaterial ();

		renderTexture = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
		renderTexture.Create ();
	}
		
	void OnRenderObject() 
	{
		Graphics.SetRenderTarget (renderTexture);

		GL.Clear(true, true, Color.black); 

		molMaterial.SetPass(1);
		Graphics.DrawProcedural(MeshTopology.Points, molCount);

		RenderTexture.active = null;
	}
	
	void OnRenderImage (RenderTexture src, RenderTexture dst)
	{	
		Graphics.Blit (renderTexture, dst); 
	} 

	void OnDisable()
	{
		if(molBuffer != null)
			molBuffer.Dispose();
		
		if(atomBuffer != null)
			atomBuffer.Dispose();
	}

	void Update () 
	{
		if (Input.GetKey ("escape"))
		{
			Application.Quit();
		}
	}
}