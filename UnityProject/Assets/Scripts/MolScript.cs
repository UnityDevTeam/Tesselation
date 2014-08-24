using UnityEngine;

//[ExecuteInEditMode]
public class MolScript : MonoBehaviour
{
	[RangeAttribute(0.01f,0.5f)]
	public float molScale = 0.01f;
	public int molCount = 100000;
	public Vector3 domainSize = new Vector3(25.0f,25.0f,25.0f);

	public Shader shader;	
	private Material mat;
	
	private RenderTexture colorTexture;
	private RenderTexture colorTexture2;	
	private RenderBuffer depthBuffer;
	private RenderTexture depthTexture;

	
	private ComputeBuffer cbDrawArgs;
	private ComputeBuffer cbPoints;
	private ComputeBuffer cbAtoms;
	private ComputeBuffer cbMols;

	public ComputeBuffer GetCbMols()
	{
		return cbMols;
	}

	void Start () {
		camera.depthTextureMode = DepthTextureMode.Depth;
	}

	private void CreateResources ()
	{
		if (cbDrawArgs == null) {
			cbDrawArgs = new ComputeBuffer (1, 16, ComputeBufferType.DrawIndirect);
			var args = new int[4];
			args [0] = 0;
			args [1] = 1;
			args [2] = 0;
			args [3] = 0;
			cbDrawArgs.SetData (args);
		}

		if (cbAtoms == null) {
			var atoms = PdbReader.ReadPdbFileSimple ();

			cbAtoms = new ComputeBuffer (atoms.Count, 16);
			cbAtoms.SetData (atoms.ToArray ());
		}
		
		if (cbMols == null) {
			Vector4[] molPositions = new Vector4[molCount];
			
			for (var i=0; i < molCount; i++) {
				molPositions [i].Set ((UnityEngine.Random.value - 0.5f) * domainSize.x, 
				                    (UnityEngine.Random.value - 0.5f) * domainSize.y,
				                    (UnityEngine.Random.value - 0.5f) * domainSize.z,
				                    1);
			}
			
			cbMols = new ComputeBuffer (molPositions.Length, 16); 
			cbMols.SetData (molPositions);
		}
		
		if (cbPoints == null) {
			cbPoints = new ComputeBuffer (Screen.width * Screen.height, 16, ComputeBufferType.Append);
		}
		
		if (colorTexture == null) {
			colorTexture = new RenderTexture (Screen.width, Screen.height, 32, RenderTextureFormat.ARGBFloat);
			colorTexture.filterMode = FilterMode.Point;
			colorTexture.depth =
			colorTexture.anisoLevel = 1;
			colorTexture.antiAliasing = 1;
			colorTexture.Create ();
		}

		if (depthTexture == null) 
		{
			depthBuffer = new RenderBuffer();
			depthTexture = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.Depth); 
			depthBuffer = depthTexture.depthBuffer;
		}

		if(mat == null)
		{
			mat = new Material(shader);
			mat.hideFlags = HideFlags.HideAndDontSave;
		}


	}
	
	private void ReleaseResources ()
	{
		if (cbDrawArgs != null) cbDrawArgs.Release (); cbDrawArgs = null;
		if (cbPoints != null) cbPoints.Release(); cbPoints = null;
		if (cbAtoms != null) cbAtoms.Release(); cbAtoms = null;
		if (cbMols != null) cbMols.Release(); cbMols = null;
		
		if (colorTexture != null) colorTexture.Release(); colorTexture = null;
		if (depthTexture != null) depthTexture.Release(); depthTexture = null;

		DestroyImmediate (mat);
		mat = null;
	}

	void OnRenderImage(RenderTexture src, RenderTexture dst)
	{
		CreateResources ();

		Graphics.SetRenderTarget (colorTexture);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));		
		mat.SetFloat ("molScale", molScale);
		mat.SetBuffer ("molPositions", cbMols);
		mat.SetBuffer ("atomPositions", cbAtoms);
		mat.SetPass(0);
		Graphics.DrawProcedural(MeshTopology.Points, molCount);

		mat.SetTexture ("_InputTex", colorTexture);
		Graphics.SetRandomWriteTarget (1, cbPoints);
		Graphics.Blit (src, dst, mat, 1);
		Graphics.ClearRandomWriteTargets ();		
		ComputeBuffer.CopyCount (cbPoints, cbDrawArgs, 0);
	
		//Graphics.SetRenderTarget (src.colorBuffer,depthTexture.depthBuffer);
		//Graphics.SetRenderTarget (src);
		Graphics.SetRenderTarget (colorTexture);
		GL.Clear (true, true, new Color (1.0f, 1.0f, 1.0f, 0.0f));
		mat.SetFloat ("spriteSize", molScale * 1.0f);
		mat.SetColor ("spriteColor", Color.white);
		mat.SetBuffer ("atomPositions", cbPoints);

//		mat.SetPass(2);
//		Graphics.DrawProceduralIndirect(MeshTopology.Points, cbDrawArgs);
		//Graphics.SetRenderTarget (src.colorBuffer,depthTexture.depthBuffer);
		//Graphics.SetRenderTarget (src.colorBuffer,depthBuffer);
		mat.SetPass(3);
		Graphics.DrawProceduralIndirect(MeshTopology.Points, cbDrawArgs);

		//Graphics.Blit (src, dst);
		//mat.SetTexture ("_DepthTex", depthTexture);
		//mat.SetTexture ("_InputTex", src);
		mat.SetTexture ("_InputTex", colorTexture);
		Graphics.Blit (src, dst, mat, 4);
	}

	void OnDisable ()
	{
		ReleaseResources ();
	}
}