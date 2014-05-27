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
	private ComputeBuffer atomPosBuffer;

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

	public void createAtomPosBuffer()
	{	
		atomPosBuffer = new ComputeBuffer (1000000, 16, ComputeBufferType.Append); 
	}

	public void createMolMaterial()
	{
		molMaterial = Resources.Load<Material> ("MolMaterial");		

		molMaterial.SetBuffer ("molPositions", molBuffer);
		molMaterial.SetBuffer ("atomPositions", atomBuffer);
		molMaterial.SetBuffer ("atomBufferOutput", atomPosBuffer);
	}

	void Awake ()
	{
		createMolBuffer ();
		createAtomBuffer ();
		createAtomPosBuffer ();

		createMolMaterial ();

		renderTexture = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
		renderTexture.Create ();
	}
		
	void OnRenderObject() 
	{
		if (renderTexture.width != Screen.width || renderTexture.height != Screen.height) 
		{
			renderTexture = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
			//atomPosBuffer.Dispose();
			//atomPosBuffer = new ComputeBuffer (100000, 16, ComputeBufferType.Append); 
		}


		Graphics.SetRenderTarget (renderTexture);

		GL.Clear(true, true, Color.black); 

		//molMaterial.SetPass(1);
		//Graphics.DrawProcedural(MeshTopology.Points, molCount);

		RenderTexture.active = null;
		Graphics.SetRandomWriteTarget (1, atomPosBuffer);
		Graphics.Blit (renderTexture, molMaterial, 2);
		Graphics.ClearRandomWriteTargets (); 
		/*
		using (var countBuffer = new ComputeBuffer (1, 16, ComputeBufferType.DrawIndirect)) {
			
			ComputeBuffer.CopyCount (atomPosBuffer, countBuffer, 0);
			
			var count = new int[4];
			
			countBuffer.GetData (count);
			
			Debug.Log ("Atom pos buffer size:" + count[0]);
			
		}
		*/

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

		if(atomPosBuffer != null)
			atomPosBuffer.Dispose();
	}

	void Update () 
	{
		if (Input.GetKey ("escape"))
		{
			Application.Quit();
		}
	}
}
