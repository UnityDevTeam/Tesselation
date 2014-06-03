using UnityEngine;

//[ExecuteInEditMode]
public class MolScript : MonoBehaviour
{
	public int molCount = 100000;
	public Shader shader;

	private Material mat;

	private RenderTexture colorTexture;
	private RenderTexture depthTexture;
		
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

		if (colorTexture == null)
		{
			colorTexture = new RenderTexture (Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
			colorTexture.Create();
		}
		
		if (depthTexture == null)
		{
			depthTexture = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.Depth);
			depthTexture.Create();
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

		if (colorTexture != null) colorTexture.Release(); colorTexture = null;		
		if (depthTexture != null) depthTexture.Release(); depthTexture = null;

		Object.DestroyImmediate (mat);
	}
	
	void OnDisable ()
	{
		ReleaseResources ();
	}
	
	void OnPostRender()
	{
		CreateResources ();

		Graphics.SetRenderTarget (colorTexture.colorBuffer, depthTexture.depthBuffer);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));		
		mat.SetBuffer ("molPositions", cbMols);
		mat.SetPass(1);
		Graphics.DrawProcedural(MeshTopology.Points, molCount);
	}

	void OnRenderImage (RenderTexture src, RenderTexture dst)
	{
		mat.SetTexture ("_ColorTex", colorTexture);
		mat.SetTexture ("_DepthTex", depthTexture);

		Graphics.SetRandomWriteTarget (1, cbPoints);
		Graphics.Blit (src, dst, mat, 0);
		Graphics.ClearRandomWriteTargets ();

		ComputeBuffer.CopyCount (cbPoints, cbDrawArgs, 0);

		// Read the amount of atoms to draw // Time consuming !! Use carefully
//		var count = new int[4];			
//		cbDrawArgs.GetData (count);			
//		Debug.Log ("Atom pos buffer size:" + count[0]);	

		var projectionMatrixInverse = camera.projectionMatrix.inverse;

		Graphics.SetRenderTarget (dst);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));

		mat.SetBuffer ("atomPositions", cbPoints);
		mat.SetMatrix ("projectionMatrixInverse", projectionMatrixInverse);
		mat.SetPass(2);

		Graphics.DrawProceduralIndirect(MeshTopology.Points, cbDrawArgs);
	}
}