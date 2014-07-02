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
	//! a buffers
	private ComputeBuffer globalDataBuffer;
	private ComputeBuffer headBuffer;
	//private RenderTexture headBuffer;
	private ComputeBuffer globalCounter;
	private const int MAX_OVERDRAW = 10;
	private readonly int resolutionArea = Screen.width * Screen.height;
	private uint[] initialHeadArray;
	private uint[] zero_val;
	private ComputeBuffer triangleOutput;
	//! a buffers

	private ComputeBuffer cbMols;
	private ComputeBuffer cbIndices;
	public ComputeShader cs;
	public ComputeShader csMC;
	private Color[]  voxels;
	
	private Vector4[] molPositions;

	struct GlobalData   // size -> 12
	{
		uint colour;
		uint depth;
		uint previousNode;
	}


	private void CreateBuffers()
	{
		//globalDataBuffer = new ComputeBuffer(MAX_OVERDRAW * resolutionArea, 12, ComputeBufferType.Counter);
		globalDataBuffer = new ComputeBuffer(MAX_OVERDRAW * resolutionArea, 12, ComputeBufferType.Raw);
		GlobalData[] initialDataArray = new GlobalData[MAX_OVERDRAW * resolutionArea];
		for (int i = 0; i < MAX_OVERDRAW * resolutionArea; i++)
		{
			initialDataArray[i] = new GlobalData();
		}
		globalDataBuffer.SetData(initialDataArray);
		
		// Initialize head pointer buffer to magic value : 0

		initialHeadArray = new uint[resolutionArea];
		for (int i = 0; i < resolutionArea; i++)
		{
			initialHeadArray[i] =  0xFFFFFFFF;
		}
		
		headBuffer = new ComputeBuffer(resolutionArea, 4, ComputeBufferType.Raw);
		headBuffer.SetData(initialHeadArray);

		//this.headBuffer = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RInt);
		//this.headBuffer.enableRandomWrite = true;
		//this.headBuffer.Create(); 
		globalCounter = new ComputeBuffer(4, 4, ComputeBufferType.Raw);
		zero_val = new uint[4];
		zero_val[0] = 4;
		zero_val[1] = 10;
		zero_val[2] = 13;
		zero_val[3] = 15;
		globalCounter.SetData(zero_val);
		Debug.Log ("resolutionArea" + resolutionArea);
	}

	private void CreateTriangleBuffer()
	{

	}
	

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
				                    0.3f);
			}
			
			cbMols = new ComputeBuffer (molPositions.Length, 16); 
			cbMols.SetData(molPositions);
		}
		/*
		if (globalDataBuffer==null)
			CreateBuffers ();
		*/
		if (triangleOutput==null)
			triangleOutput = new ComputeBuffer (100000, 24, ComputeBufferType.Append); 

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
			//matMC.hideFlags = HideFlags.HideAndDontSave;
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

	private void ComputeMC(Vector3 dx,Vector3 min)
	{
		cs.SetVector ("dx", dx);
		cs.SetVector ("_gridRes", new Vector3(64,64,64));
		cs.SetFloat("_isoLevel", 0.5f);
		cs.SetTexture(0,"_dataFieldTex", volumeTexture);
		cs.SetBuffer (0, "trianglesOut", this.triangleOutput);
		cs.Dispatch (0, 8,8,8);
	}

	
	private void ReleaseResources ()
	{
		if (cbDrawArgs != null) cbDrawArgs.Dispose (); cbDrawArgs = null;
		//a-buffers
		if (globalDataBuffer != null) globalDataBuffer.Dispose(); globalDataBuffer = null;
		if (headBuffer != null) headBuffer.Dispose(); headBuffer = null;
		//if (headBuffer != null) headBuffer.Release(); headBuffer = null;
		if (globalCounter != null) globalCounter.Dispose(); globalCounter = null;
		//a-buffers

		if (cbMols != null) cbMols.Dispose(); cbMols = null;
		
		if (volumeTexture != null) volumeTexture.Release(); volumeTexture = null;

		if (cbIndices != null) cbIndices.Dispose(); cbIndices = null;

		if (triangleOutput != null) triangleOutput.Dispose(); triangleOutput = null;


		Object.DestroyImmediate (matMC);
	}
	
	void OnDisable ()
	{
		ReleaseResources ();
	}

//	private void OnPreCull()
//	{
//		if (headBuffer != null)
//		{
//			headBuffer.SetData(initialHeadArray);
//			globalCounter.SetData(zero_val);
//		}
//		else
//		{
//			Debug.LogWarning("Head buffer is empty.");
//		}
//	}

	
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

		if (headBuffer != null)
		{
			headBuffer.SetData(initialHeadArray);
//			Graphics.SetRenderTarget (headBuffer);
//			GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
			globalCounter.SetData(zero_val);
		} else
		{
			Debug.LogWarning("Head buffer is empty.");
		}

		//matMC.SetBuffer ("atomPositions", cbPoints);
		RenderTexture.active = null;
		//GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
		matMC.SetBuffer ("indices", cbIndices);
		//matMC.SetBuffer ("triangleOutput", this.triangleOutput);
		//matMC.SetTexture ("_dataFieldTex", densityTex);
		matMC.SetTexture ("_dataFieldTex", volumeTexture);
		Shader.SetGlobalBuffer("_GlobalData", globalDataBuffer);
		Shader.SetGlobalBuffer("_HeadBuffer", headBuffer);
		//Shader.SetGlobalTexture("_HeadBuffer", headBuffer);
		//Shader.SetGlobalBuffer("_GlobalCounter", globalCounter);
//		matMC.SetBuffer("_GlobalData", globalDataBuffer);
//		matMC.SetBuffer("_HeadBuffer", headBuffer);
		matMC.SetBuffer("_GlobalCounter", globalCounter);
		Graphics.ClearRandomWriteTargets ();
		Graphics.SetRandomWriteTarget (1, globalDataBuffer);
		Graphics.SetRandomWriteTarget (2, headBuffer);
		Graphics.SetRandomWriteTarget (3, globalCounter);
		//Graphics.SetRandomWriteTarget (5, triangleOutput); 
		matMC.SetPass(0);
		Graphics.DrawProcedural(MeshTopology.Points, 64*64*64);
		Graphics.ClearRandomWriteTargets ();
		uint[] _counter=new uint[4];
		globalCounter.GetData (_counter);
		Debug.Log ("count[0]"+_counter[0]);
		Debug.Log ("count[1]"+_counter[1]);
		Debug.Log ("count[2]"+_counter[2]);
		Debug.Log ("count[2]"+_counter[3]);
		//Graphics.ClearRandomWriteTargets ();
//		ComputeBuffer.CopyCount (triangleOutput, cbDrawArgs, 0); 
//		int[] da =new int[4];
//		cbDrawArgs.GetData (da);
//		Debug.Log ("da[0]"+da[0]);
//		Debug.Log ("da[1]"+da[1]);
//		Debug.Log ("da[2]"+da[2]);
//		Debug.Log ("da[3]"+da[2]);


	}

	void OnRenderImage (RenderTexture source, RenderTexture destination){
		//! iso-surface creation
		Graphics.Blit (source, destination);
//		matMC.SetBuffer ("r_HeadBuffer", headBuffer);
//		matMC.SetBuffer ("r_GlobalData", globalDataBuffer);
//		Graphics.Blit (source, destination, matMC, 1);
//		Graphics.ClearRandomWriteTargets ();
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