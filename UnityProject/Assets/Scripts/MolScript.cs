using UnityEngine;

//[ExecuteInEditMode]
public class MolScript : MonoBehaviour
{
	public int molCount = 100000;
	public Shader shader;

	private Material mat;
	private RenderTexture renderTexture;
		
	private ComputeBuffer cbDrawArgs;
	private ComputeBuffer cbPoints;
	private ComputeBuffer cbMols;
	
	private void CreateResources ()
	{
		if (cbDrawArgs == null)
		{
			cbDrawArgs = new ComputeBuffer (1, 16, ComputeBufferType.DrawIndirect);
			var args = new int[4];
			args[0] = 0;
			args[1] = 1;
			args[2] = 0;
			args[3] = 0;
			cbDrawArgs.SetData (args);
		}
		
		if (cbMols == null)
		{
			Vector4[] molPositions = new Vector4[molCount];
			
			for (var i=0; i < molCount; i++)
			{
				molPositions[i].Set((UnityEngine.Random.value - 0.5f) * 10.0f, 
				                    (UnityEngine.Random.value - 0.5f) * 10.0f,
				                    (UnityEngine.Random.value - 0.5f) * 10.0f,
				                    1);
			}
			
			cbMols = new ComputeBuffer (molPositions.Length, 16); 
			cbMols.SetData(molPositions);
		}
		
		if (cbPoints == null)
		{
			cbPoints = new ComputeBuffer (Screen.width * Screen.height, 16, ComputeBufferType.Append);
		}

		if (renderTexture == null)
		{
			renderTexture = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
			renderTexture.Create();
		}
		
		if (mat == null)
		{
			mat = new Material(shader);
			mat.hideFlags = HideFlags.HideAndDontSave;
		}
	}
	
	private void ReleaseResources ()
	{
		if (cbDrawArgs != null) cbDrawArgs.Release (); cbDrawArgs = null;
		if (cbPoints != null) cbPoints.Release(); cbPoints = null;
		if (cbMols != null) cbMols.Release(); cbMols = null;
		Object.DestroyImmediate (mat);
	}
	
	void OnDisable ()
	{
		ReleaseResources ();
	}
	
	void OnPostRender()
	{
		print(SystemInfo.supportedRenderTargetCount);

		CreateResources ();

		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));		
		mat.SetBuffer ("molPositions", cbMols);
		mat.SetPass(1);
		Graphics.DrawProcedural(MeshTopology.Points, molCount);
	}

	void OnRenderImage (RenderTexture src, RenderTexture dst)
	{
		if (!shader)
		{
			Debug.LogWarning ("No Shader set");
			return;			
		}
		
		if (!SystemInfo.supportsComputeShaders)
		{
			Debug.LogWarning ("Compute shaders not supported (not using DX11?)");
			return;			
		}
	
		Graphics.SetRandomWriteTarget (1, cbPoints);
		Graphics.Blit (src, dst, mat, 0);
		Graphics.ClearRandomWriteTargets ();

		ComputeBuffer.CopyCount (cbPoints, cbDrawArgs, 0);
//		var count = new int[4];			
//		cbDrawArgs.GetData (count);			
//		Debug.Log ("Atom pos buffer size:" + count[0]);	

		Graphics.SetRenderTarget (dst);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
		mat.SetBuffer ("atomPositions", cbPoints);
		mat.SetPass(2);
		Graphics.DrawProceduralIndirect(MeshTopology.Points, cbDrawArgs);
	}
}
