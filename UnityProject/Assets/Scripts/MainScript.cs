using UnityEngine;
using System;

public class MainScript : MonoBehaviour
{
	public int molCount = 1000;
	//atom buffer
	public ComputeBuffer atomBuffer;

	// Use this for initialization
	void Start ()
	{
//		var vertices = new Vector4[300];
//		for (var i=0; i < 300; i++)
//		{
//			vertices[i] = new Vector3 ( (UnityEngine.Random.value - 0.5f), (UnityEngine.Random.value - 0.5f), (UnityEngine.Random.value - 0.5f));
//		}
		//var buffer = new ComputeBuffer (vertices.Length, 16); 
		//buffer.SetData(vertices);
	}
		
	// Update is called once per frame
	void Update ()
	{
		//Graphics.DrawMesh(mesh, Vector3.zero, Quaternion.identity, material, 0);
	}
//
//	private void ReleaseBuffers() {
//		if (atomBuffer != null) atomBuffer.Release();
//		atomBuffer = null;
//	}
//	
//	void OnDisable() {
//		ReleaseBuffers ();
//	} 
}
