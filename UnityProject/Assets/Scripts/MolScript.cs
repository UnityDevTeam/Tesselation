using UnityEngine;

using System;
using System.Collections;
using System.Collections.Generic;

public class MolScript : MonoBehaviour
{
	public int molCount = 100;

	private Material molMaterial;

	private ComputeBuffer molBuffer;
	private ComputeBuffer atomBuffer;
	private ComputeBuffer atomBufferOutput;

	private RenderTexture renderTexture;

	private void CreateResources ()
	{
		if (molBuffer == null)
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

		if (atomBuffer == null)
		{
			Vector4[] atomPositions = PdbReader.ReadPdbFileSimple().ToArray();
			
			atomBuffer = new ComputeBuffer (atomPositions.Length, 16); 
			atomBuffer.SetData(atomPositions);
		}

		if (atomBufferOutput == null)
		{
			atomBufferOutput = new ComputeBuffer (1000000, 16, ComputeBufferType.Append);
		}

		if (molMaterial == null)
		{
			molMaterial = Resources.Load<Material> ("MolMaterial");		
			
			molMaterial.SetBuffer ("molPositions", molBuffer);
			molMaterial.SetBuffer ("atomPositions", atomBuffer);
			molMaterial.SetBuffer ("atomBufferOutput", atomBufferOutput);
		}

		if (renderTexture == null)
		{
			renderTexture = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
		}
	}

	private void ReleaseResources ()
	{
		if (molBuffer != null) 
		{
			molBuffer.Release ();
			molBuffer = null;
		}

		if (atomBuffer != null) 
		{
			atomBuffer.Release ();
			atomBuffer = null;
		}
		if(atomBufferOutput != null)
		{
			atomBufferOutput.Release();
			atomBufferOutput = null;
		}
	}
		
	bool flag = false;

	void OnRenderObject() 
	{
//		if (flag)
//			return;
//
//		flag = true;

		CreateResources ();

//		Graphics.SetRenderTarget (renderTexture);

		GL.Clear(true, true, Color.black); 
		molMaterial.SetPass(0);
		Graphics.DrawProcedural(MeshTopology.Points, molCount);

//		RenderTexture.active = null;

//		Graphics.SetRandomWriteTarget (1, atomBufferOutput);
//		Graphics.Blit (renderTexture, molMaterial, 1);
//		Graphics.ClearRandomWriteTargets (); 
//
//		using (var countBuffer = new ComputeBuffer (1, 16, ComputeBufferType.DrawIndirect)) 
//		{			
//			ComputeBuffer.CopyCount (atomPosBuffer, countBuffer, 0);			
//			var count = new int[4];			
//			countBuffer.GetData (count);			
//			Debug.Log ("Atom pos buffer size:" + count[0]);			
//		}	
	}
	
	void OnRenderImage (RenderTexture src, RenderTexture dst)
	{	
		Graphics.SetRandomWriteTarget (1, atomBufferOutput);
		Graphics.Blit (src, dst, molMaterial, 1);
		Graphics.ClearRandomWriteTargets (); 

//		using (var countBuffer = new ComputeBuffer (1, 16, ComputeBufferType.DrawIndirect)) 
//		{			
//			ComputeBuffer.CopyCount (atomBufferOutput, countBuffer, 0);			
//			var count = new int[4];			
//			countBuffer.GetData (count);			
//			Debug.Log ("Atom pos buffer size:" + count[0]);			
//		}	
	} 

	void OnDisable()
	{
		ReleaseResources ();
	}

	void Update () 
	{
		if (Input.GetKey ("escape"))
		{
			Application.Quit();
		}
	}
}
