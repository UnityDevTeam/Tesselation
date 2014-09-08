using UnityEngine;
using System.Runtime.InteropServices;
using System.Collections.Generic;
//using PdbReader;

//[ExecuteInEditMode]
public class MolScript : MonoBehaviour
{
	public int molCount = 1000;
	public Vector3 aoGradParam = new Vector3(3.0f,8.0f,2.0f); //scale of t, scale * distance between levels, not assigned yet
	public Vector3 aoFuncParam = new Vector3(1.0f,8.0f,1.0f); //scale of ao, func 1, func 2
	public Vector3 aoShadowParam = new Vector3 (0.0f, 0.0f, 0.0f); //shadow strength, ...
	public int aoSamplesCount = 1; //number of samples x 10
	//public Shader shader;
	//public Shader shaderMC;
	public Shader shaderTriangles;
	
	//private Material mat;
	private Material matMC = null;
	private Material matTriangles;
	private Texture3D densityTex;	
	private Bounds bbox;
	
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
	//public ComputeShader cs;
	public ComputeShader csMC;
	private Color[]  voxels;
	
	private Vector4[] molPositions;
	private static int triangleCountMax = 1000000;
	private static int gridDim = 128;
	public float SR=1.4f;

	private RenderTexture[] mrtTex;
	private RenderBuffer[] mrtRB; 


	struct GlobalData   // size -> 12
	{
		uint colour;
		uint depth;
		uint previousNode;
	}

	public struct GlobalTriangle
	{
		public Vector3 ptA;
		public Vector3 nmlA;
		public Vector3 ptB;
		public Vector3 nmlB;
		public Vector3 ptC;
		public Vector3 nmlC;
	};

	public struct GlobalVertex
	{
		public Vector3 pt;
		public Vector3 nml;
	};

	private void CreateRenderTextures()
	{

		this.mrtTex  =   new RenderTexture[2];
		this.mrtRB    =   new RenderBuffer[2];
		
		this.mrtTex[0] = new RenderTexture (Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat);
		this.mrtTex[1] = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGBFloat);

		for( int i = 0; i < this.mrtTex.Length; i++ )
			this.mrtRB[i] = this.mrtTex[i].colorBuffer;
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

	private void CreateResources ()
	{

		//GetComponent<Camera>().depthTextureMode = DepthTextureMode.DepthNormals;
		camera.depthTextureMode = DepthTextureMode.DepthNormals;

		if (cbDrawArgs == null)
		{
			cbDrawArgs = new ComputeBuffer (1, 16, ComputeBufferType.DrawIndirect);

			var args = new int[4];
			args[0] = 3;
			args[1] = 0;
			args[2] = 0;
			args[3] = 0;
			cbDrawArgs.SetData (args);

		}

		if (cbMols == null)
		{

			molPositions = new Vector4[molCount];
			
//			for (var i=0; i < molCount; i++)
//			{
//				molPositions[i].Set((UnityEngine.Random.value - 0.5f) * 10.0f, 
//				                    (UnityEngine.Random.value - 0.5f) * 10.0f,
//				                    (UnityEngine.Random.value - 0.5f) * 10.0f,
//				                    0.3f);
//			}

			List<Vector4> molList = PdbReader.ReadPdbFileSimple();
			molPositions = molList.ToArray();
			bbox = new Bounds(Vector3.zero,Vector3.zero);
			//Vector3 minBB = new Vector3(Mathf.Infinity,Mathf.Infinity,Mathf.Infinity);
			//Vector3 maxBB = new Vector3(-Mathf.Infinity,-Mathf.Infinity,-Mathf.Infinity);

			foreach(Vector4 m in molPositions) 
				bbox.Encapsulate(new Vector3(m.x,m.y,m.z));
			bbox.Expand(4.0f);
			//minBB-=new Vector3(1.8f,1.8f,1.8f);
			//maxBB+=new Vector3(1.8f,1.8f,1.8f);
			//bbox = new Bounds(0.5f*(minBB+maxBB),maxBB-minBB);
			cbMols = new ComputeBuffer (molPositions.Length, 16); 
			cbMols.SetData(molPositions);
			Debug.Log("min="+bbox.min+"max="+bbox.max+"extents:"+bbox.size);
			//Debug.Log("min="+minBB+"max="+maxBB);
		}
		/*
		if (globalDataBuffer==null)
			CreateBuffers ();
		*/
		if (triangleOutput == null) 
		{
			//triangleOutput = new ComputeBuffer (100000, Marshal.SizeOf(typeof(GlobalTriangle)), ComputeBufferType.Append); 
			triangleOutput = new ComputeBuffer (triangleCountMax,24*3, ComputeBufferType.Append); 
			GlobalTriangle[] gtlA = new GlobalTriangle[triangleCountMax];
			triangleOutput.SetData(gtlA);
		}

		if (volumeTexture == null)
		{
			volumeTexture = new RenderTexture (gridDim, gridDim, 0, RenderTextureFormat.ARGBFloat);
			volumeTexture.volumeDepth = gridDim;
			volumeTexture.isVolume = true;
			volumeTexture.enableRandomWrite = true;
			volumeTexture.Create();
		}


		
		/*		
		if (matMC == null)
		{
			matMC = new Material(shaderMC);
			//matMC.hideFlags = HideFlags.HideAndDontSave;
		}
		*/
		if (matTriangles == null)
		{
			matTriangles = new Material(shaderTriangles);
			//matMC.hideFlags = HideFlags.HideAndDontSave;
		}

		this.CreateRenderTextures();
	}
//


	public void updateTextureAndMesh()
	{
		//! create the voxelization
		//Vector3 min = new Vector3(-7.0f,-7.0f,-7.0f);
		Vector3 min = bbox.min;
		int nx=gridDim;
		int ny=gridDim;
		int nz=gridDim;
		//Vector3 dx = new Vector3(14.0f/(float) (nx-1),14.0f/(float) (ny-1),14.0f/(float) (nz-1));
		Vector3 dx = new Vector3(bbox.size.x / (float) (nx-1),bbox.size.y/(float) (ny-1),bbox.size.z/(float) (nz-1));
		UpdateDensityTexture(dx,min);
		volumeTexture.filterMode = FilterMode.Trilinear;
		volumeTexture.wrapMode = TextureWrapMode.Clamp;
		this.ComputeMC(dx,min);
	}
	/*
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
	*/
	private void UpdateDensityTexture(Vector3 dx,Vector3 min)
	{
//		cs.SetVector ("dx", dx);
//		cs.SetVector ("minBox", min);
//		cs.SetInt("atomCount", molPositions.Length);
//		cs.SetBuffer(0,"molPositions", cbMols);
//		cs.SetTexture (0, "Result", volumeTexture);
//		cs.Dispatch (0, 8,8,8);
		csMC.SetVector ("dx", dx);
		//voxelsEval int[]=new int[3]
		csMC.SetFloat ("SR", SR);
		csMC.SetInts("voxelsEval", 2,2,2);
		csMC.SetVector ("minBox", min);
		csMC.SetInt ("_meshSize", gridDim);
		csMC.SetInt("atomCount", molPositions.Length);
		csMC.SetBuffer(1,"molPositions", cbMols);
		csMC.SetTexture (1, "Result", volumeTexture);
		csMC.Dispatch (1, 8,8,8);
		Debug.Log ("SR="+SR+"atomCount="+molPositions.Length);

	}

	private void ComputeMC(Vector3 dx,Vector3 min)
	{
		csMC.SetVector ("_gridRes", new Vector3(gridDim,gridDim,gridDim));
		csMC.SetInt ("_meshSize", gridDim);
		csMC.SetFloat("_isoLevel", 0.5f);
		csMC.SetTexture(0,"_dataFieldTex", this.volumeTexture);
		csMC.SetBuffer (0, "trianglesOut", this.triangleOutput);
		Graphics.SetRandomWriteTarget (1, this.triangleOutput);
		csMC.Dispatch (0, 8,8,8);
		ComputeBuffer.CopyCount (this.triangleOutput, cbDrawArgs, 4); 
		var count = new int[4];
		cbDrawArgs.GetData (count);
		Debug.Log ("[0]"+count[0]);
		Debug.Log ("[1]"+count[1]);
		Debug.Log ("[2]"+count[2]);
		Debug.Log ("[3]"+count[3]);
	}


	public void BuildMC()
	{
		//CreateResources ();
		updateTextureAndMesh ();
		Debug.Log ("TEST!@!!!");
	}

	public void Start()
	{
		CreateResources ();
		Debug.Log ("Creating resources");
	}

	
	private void ReleaseResources ()
	{
		if (cbDrawArgs != null) cbDrawArgs.Release (); cbDrawArgs = null;
		//a-buffers
		if (globalDataBuffer != null) globalDataBuffer.Release(); globalDataBuffer = null;
		if (headBuffer != null) headBuffer.Release(); headBuffer = null;
		//if (headBuffer != null) headBuffer.Release(); headBuffer = null;
		if (globalCounter != null) globalCounter.Release(); globalCounter = null;
		//a-buffers

		if (cbMols != null) cbMols.Release(); cbMols = null;
		
		if (volumeTexture != null) volumeTexture.Release(); volumeTexture = null;

		if (cbIndices != null) cbIndices.Release(); cbIndices = null;

		if (triangleOutput != null) triangleOutput.Release(); triangleOutput = null;

		//if (colorTexture != null) colorTexture.Release (); colorTexture = null;
		for( int i = 0; i < this.mrtTex.Length; i++ ) {
			if (mrtTex[i] != null) {mrtTex[i].Release(); mrtTex[i]=null;}
			//if (mrtRB[i] != null) {mrtRB[i].Release(); mrtRB[i]=null;}
		} 

		Debug.Log("Cleaning resources");
		Object.DestroyImmediate (matMC);
		Object.DestroyImmediate (matTriangles);
		//Object.DestroyImmediate (csMC,true);

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


	void RenderToFragmentList()
	{
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
		Graphics.DrawProcedural(MeshTopology.Points, gridDim*gridDim*gridDim);
		Graphics.ClearRandomWriteTargets ();
		uint[] _counter=new uint[4];
		globalCounter.GetData (_counter);
		Debug.Log ("count[0]"+_counter[0]);
		Debug.Log ("count[1]"+_counter[1]);
		Debug.Log ("count[2]"+_counter[2]);
		Debug.Log ("count[2]"+_counter[3]);
	}
	
	void OnPostRender()
	{
		//CreateResources ();
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
		*/
		//RenderTexture.active = colorTexture;
		if (matTriangles!=null)
		{
			//camera.SetReplacementShader(matTriangles,null);
			Graphics.SetRenderTarget (mrtTex[1]);
			GL.Clear (true, true, new Color (1.0f, 1.0f, 1.0f, 0.0f));
			Graphics.SetRenderTarget(mrtRB, mrtTex[1].depthBuffer);
			matTriangles.SetBuffer ("triangles", this.triangleOutput);
			matTriangles.SetPass(0);
			Graphics.DrawProceduralIndirect(MeshTopology.Triangles, cbDrawArgs);
			//Graphics.DrawProcedural(MeshTopology.Triangles, 3, 207000);
			Graphics.ClearRandomWriteTargets ();
		}
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
		matTriangles.SetTexture ("col0", this.mrtTex [0]);
		matTriangles.SetTexture ("col1", this.mrtTex [1]);
		matTriangles.SetTexture("_dataFieldTex", this.volumeTexture);
		matTriangles.SetVector("aoGradParam",aoGradParam);
		matTriangles.SetVector("aoFuncParam",aoFuncParam);
		matTriangles.SetVector("aoShadowParam",aoShadowParam);
		matTriangles.SetInt("aoSamplesCount",aoSamplesCount);
		Graphics.Blit (source, destination, matTriangles, 1);
//		matMC.SetBuffer ("r_HeadBuffer", headBuffer);
//		matMC.SetBuffer ("r_GlobalData", globalDataBuffer);
//		Graphics.Blit (source, destination, matMC, 1);
//		Graphics.ClearRandomWriteTargets ();
		//Graphics.Blit (this.mrtTex[0], destination);
	}
}