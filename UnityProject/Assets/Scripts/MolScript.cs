using UnityEngine;

//[ExecuteInEditMode]
public class MolScript : MonoBehaviour
{
	public int molCount = 100;
	//public Shader shader;
	public Shader shaderMC;
	
	private Material mat;
	private Material matMC;
	private Texture3D densityTex;	
	
	private RenderTexture volumeTexture;
	
	private ComputeBuffer cbDrawArgs;
	private ComputeBuffer cbPoints;
	private ComputeBuffer cbMols;
	private ComputeBuffer cbIndices;
	public ComputeShader cs;
	private Color[]  voxels;
	
	private Vector4[] molPositions;
	
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
			molPositions = new Vector4[molCount];
			
			for (var i=0; i < molCount; i++)
			{
				molPositions[i].Set((UnityEngine.Random.value - 0.5f) * 10.0f, 
				                    (UnityEngine.Random.value - 0.5f) * 10.0f,
				                    (UnityEngine.Random.value - 0.5f) * 10.0f,
				                    0.8f);
			}
			
			cbMols = new ComputeBuffer (molPositions.Length, 16); 
			cbMols.SetData(molPositions);
		}
		
		if (cbPoints == null)
		{
			cbPoints = new ComputeBuffer (Screen.width * Screen.height, 16, ComputeBufferType.Append);
		}

		if (volumeTexture == null)
		{
			volumeTexture = new RenderTexture (64, 64, 0, RenderTextureFormat.ARGBFloat);
			volumeTexture.volumeDepth = 64;
			volumeTexture.isVolume = true;
			volumeTexture.enableRandomWrite = true;
			volumeTexture.Create();
		}

		if (cbIndices == null) 
		{
			//! create the voxelization
			Vector3 min = new Vector3(-7.0f,-7.0f,-7.0f);
			int nx=64;
			int ny=64;
			int nz=64;
			Vector3 dx = new Vector3(14.0f/(float) (nx-1),14.0f/(float) (ny-1),14.0f/(float) (nz-1));
			UpdateDensityTexture(dx,min);
			volumeTexture.filterMode = FilterMode.Trilinear;
			//volumeTexture.anisoLevel = 2;
//			fillVolume(min, dx,nx,ny, nz);
//			densityTex = new Texture3D(nx, ny, nz, TextureFormat.ARGB32, true);
//			densityTex.SetPixels(voxels);
//			densityTex.Apply();
//			densityTex.filterMode = FilterMode.Trilinear;
//			densityTex.wrapMode = TextureWrapMode.Clamp;
//			densityTex.anisoLevel = 2;
			int gridLength = nx*ny*nz;
			Vector3[] indices = new Vector3[gridLength];
			int count = 0;
			Vector3 deltaStep = new Vector3 (1.0f / (float) (nx),1.0f/(float) (ny),1.0f/(float) (nz));
			Debug.Log("delta step"+deltaStep.ToString("F4")+"dx"+dx.ToString("F4"));
			Vector3 pos = new Vector3 (0.0f,0.0f,0.0f);
			for(int x = 0; x < nx; x++)
			{
				for(int y = 0; y < ny; y++)
				{
					for(int z = 0; z < nz; z++)
					{
						Vector3 vol_pos = pos;
						vol_pos.x+=deltaStep.x*(float) x;
						vol_pos.y+=deltaStep.y*(float) y;
						vol_pos.z+=deltaStep.z*(float) z;
						Vector3 _hs = new Vector3(0.5f,0.5f,0.5f);
						indices[count++]=(vol_pos-_hs);
						//Debug.Log(vol_pos);
					}
				}
			}
			cbIndices = new ComputeBuffer (indices.Length, 12); 
			cbIndices.SetData(indices);
		}
		
				
		if (matMC == null)
		{
			matMC = new Material(shaderMC);
			matMC.hideFlags = HideFlags.HideAndDontSave;
		}
	}

	private float eval(Vector3 p)
	{
		float S = 0.0f;
		float SR = 1.3f;
		for (int i=0;i<molPositions.Length;i++)
		{
			Vector3 apt = molPositions[i];
			float radius = molPositions[i].w;
			Vector3 YD = apt - p;
			float r = Vector3.Dot(YD,YD);
			float b = SR*SR;
			float a = -Mathf.Log(0.5f/b)/(radius*radius);
			float gauss_f = b*Mathf.Exp(-(r*a));
			S+=gauss_f;
			//nml = nml + 2.0*b*a*gauss_f*YD;
		}
		return S;
	}

	void fillVolume(Vector3 min, Vector3 dx, int nx, int ny, int nz)
	{
		voxels = new Color[nx*ny*nz];
		int idx = 0;
		Color c = Color.white;
		for(int x = 0; x < nx; x++)
		{
			for(int y = 0; y < ny; y++)
			{
				for(int z = 0; z < nz; z++, ++idx)
				{
					Vector3 vol_pos = new Vector3(x,y,z);
					Vector3 p = min + Vector3.Scale(dx,vol_pos);
					//voxels[idx] = new Vector3(eval(p,atoms)-0.5f,1.0f,1.0f); 
					//c.r = c.g = c.b = c.a = Mathf.Clamp01(eval(p)-0.5f);
					c.r = c.g = c.b = c.a = Mathf.Clamp01(eval(p));
					//if (c.r>0.5) Debug.Log ("TES!!!!!!!!!!!!!!!!!!!!!!!!!!!");
					voxels[idx] = c;
				}
			}
		}
		
	}

	private void UpdateDensityTexture(Vector3 dx,Vector3 min)
	{
		cs.SetVector ("dx", dx);
		cs.SetVector ("minBox", min);
		cs.SetInt("atomCount", molPositions.Length);
		cs.SetBuffer(0,"molPositions", cbMols);
		cs.SetTexture (0, "Result", volumeTexture);
		cs.Dispatch (0, 8,8,8);

	}

	
	private void ReleaseResources ()
	{
		if (cbDrawArgs != null) cbDrawArgs.Release (); cbDrawArgs = null;
		if (cbPoints != null) cbPoints.Release(); cbPoints = null;
		if (cbMols != null) cbMols.Release(); cbMols = null;
		
		if (volumeTexture != null) volumeTexture.Release(); volumeTexture = null;

		if (cbIndices != null) cbIndices.Release(); cbIndices = null;

		Object.DestroyImmediate (matMC);
	}
	
	void OnDisable ()
	{
		ReleaseResources ();
	}
	
	void OnPostRender()
	{
		CreateResources ();
		/*
		Graphics.SetRenderTarget (colorTexture);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));		
		mat.SetBuffer ("molPositions", cbMols);
		mat.SetPass(1);
		Graphics.DrawProcedural(MeshTopology.Points, molCount);

		Graphics.SetRandomWriteTarget (1, cbPoints);
		Graphics.Blit (colorTexture, colorTexture2, mat, 0);
		Graphics.ClearRandomWriteTargets ();		
		ComputeBuffer.CopyCount (cbPoints, cbDrawArgs, 0);
		*/
		/*
		RenderTexture.active = null;
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
		mat.SetBuffer ("atomPositions", cbPoints);
		mat.SetPass(2);
		Graphics.DrawProceduralIndirect(MeshTopology.Points, cbDrawArgs);
		*/
		RenderTexture.active = null;
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
		//matMC.SetBuffer ("atomPositions", cbPoints);
		matMC.SetBuffer ("indices", cbIndices);
		//matMC.SetTexture ("_dataFieldTex", densityTex);
		matMC.SetTexture ("_dataFieldTex", volumeTexture);
		matMC.SetPass(0);
		Graphics.DrawProcedural(MeshTopology.Points, 64*64*64);



	}

	void OnRenderImage (RenderTexture source, RenderTexture destination){
		//! iso-surface creation
		Graphics.Blit (source, destination);
		//Graphics.Blit (this.mrtTex[0], destination);
		/*
		RenderTexture.active = null;
		mat.SetTexture("slab0", this.mrtTex[0]);
		mat.SetTexture("slab1", this.mrtTex[1]);
		mat.SetTexture("slab2", this.mrtTex[2]);
		mat.SetTexture("slab3", this.mrtTex[3]);
		Graphics.Blit (source, destination, mat, 4);
		*/

	}
}