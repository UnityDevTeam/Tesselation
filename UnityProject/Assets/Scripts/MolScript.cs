using UnityEngine;

//[ExecuteInEditMode]
public class MolScript : MonoBehaviour
{
	public int molCount = 100000;
	public Shader shader;
	
	private Material mat;
	
	private RenderTexture colorTexture;
	private RenderTexture colorTexture2;	
	
	private ComputeBuffer cbDrawArgs;
	private ComputeBuffer cbPoints;
	private ComputeBuffer cbMols;
	private ComputeBuffer cbIndices;
	private float[,,] voxels;

	private RenderTexture[] mrtTex;
	private RenderBuffer[] mrtRB;
	
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
		Vector4[] molPositions = null;
		if (cbMols == null)
		{
			molPositions = new Vector4[molCount];
			
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

		if (cbIndices == null) 
		{
			//! create the voxelization
			Vector3 min = new Vector3(-12.0f,-12.0f,-12.0f);
			Vector3 dx = new Vector3(0.3f,0.3f,0.3f);
			int nx=64;
			int ny=64;
			int nz=64;
			fillVolume(min, dx,nx,ny, nz, molPositions);
			int gridLength = nx*ny*nz;
			Vector3[] indices = new Vector3[gridLength];
			int count = 0;
			Vector3 deltaStep = new Vector3 (1.0f / (float) nx, 1.0f / (float) ny, 1.0f / (float) nz);
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
						indices[count++]=vol_pos;
					}
				}
			}
			cbIndices = new ComputeBuffer (indices.Length, 12); 
			cbIndices.SetData(indices);
		}
		
		if (colorTexture == null)
		{
			colorTexture = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGBFloat);
			colorTexture.Create();
		}
		
		if (colorTexture2 == null)
		{
			colorTexture2 = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGBFloat);
			colorTexture2.Create();
		}

		if (this.mrtTex == null)
		{
			this.mrtTex  =   new RenderTexture[4];
			this.mrtRB    =   new RenderBuffer[4];

			this.mrtTex[0] = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGBFloat);
			this.mrtTex[1] = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGBFloat);
			this.mrtTex[2] = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGBFloat);
			this.mrtTex[3] = new RenderTexture (Screen.width, Screen.height, 24, RenderTextureFormat.ARGBFloat);

			for( int i = 0; i < this.mrtTex.Length; i++ )
				this.mrtRB[i] = this.mrtTex[i].colorBuffer;

		}
		
		if (mat == null)
		{
			mat = new Material(shader);
			mat.hideFlags = HideFlags.HideAndDontSave;
		}
	}

	private float eval(Vector3 p, Vector4[] atoms)
	{
		float S = 0;
		float SR = 1.3;
		for (int i=0;i<atoms.Length;i++)
		{
			Vector3 apt = atoms[i];
			float radius = atoms[i].w;
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

	void fillVolume(Vector3 min, Vector3 dx, int nx, int ny, int nz, Vector4[] atoms)
	{
		voxels = new float[nx, ny, nz];
		
		for(int x = 0; x < nx; x++)
		{
			for(int y = 0; y < ny; y++)
			{
				for(int z = 0; z < nz; z++)
				{
					Vector3 vol_pos = new Vector3(x,y,z);
					Vector3 p = min + Vector3.Scale(dx,vol_pos);
					voxels[x,y,z] = eval(p,atoms)-0.5f; 
				}
			}
		}
		
	}

	
	private void ReleaseResources ()
	{
		if (cbDrawArgs != null) cbDrawArgs.Release (); cbDrawArgs = null;
		if (cbPoints != null) cbPoints.Release(); cbPoints = null;
		if (cbMols != null) cbMols.Release(); cbMols = null;
		
		if (colorTexture != null) colorTexture.Release(); colorTexture = null;
		if (colorTexture2 != null) colorTexture2.Release(); colorTexture2 = null;	
		for( int i = 0; i < this.mrtTex.Length; i++ ) {
			if (mrtTex[i] != null) {mrtTex[i].Release(); mrtTex[i]=null;}
		}
		if (cbIndices != null) cbIndices.Release(); cbIndices = null;
		Object.DestroyImmediate (mat);
	}
	
	void OnDisable ()
	{
		ReleaseResources ();
	}
	
	void OnPostRender()
	{
		CreateResources ();
		
		Graphics.SetRenderTarget (colorTexture);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));		
		mat.SetBuffer ("molPositions", cbMols);
		mat.SetPass(1);
		Graphics.DrawProcedural(MeshTopology.Points, molCount);

		Graphics.SetRandomWriteTarget (1, cbPoints);
		Graphics.Blit (colorTexture, colorTexture2, mat, 0);
		Graphics.ClearRandomWriteTargets ();		
		ComputeBuffer.CopyCount (cbPoints, cbDrawArgs, 0);
		/*
		RenderTexture.active = null;
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
		mat.SetBuffer ("atomPositions", cbPoints);
		mat.SetPass(2);
		Graphics.DrawProceduralIndirect(MeshTopology.Points, cbDrawArgs);
		*/


		Graphics.SetRenderTarget (this.mrtTex[0]);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
		Graphics.SetRenderTarget (this.mrtTex[1]);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
		Graphics.SetRenderTarget (this.mrtTex[2]);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
		Graphics.SetRenderTarget (this.mrtTex[3]);
		GL.Clear (true, true, new Color (0.0f, 0.0f, 0.0f, 0.0f));
		Graphics.SetRenderTarget (this.mrtRB,this.mrtTex[0].depthBuffer);
		mat.SetBuffer ("atomPositions", cbPoints);
		mat.SetPass(3);
		Graphics.DrawProceduralIndirect(MeshTopology.Points, cbDrawArgs);

	}

	void OnRenderImage (RenderTexture source, RenderTexture destination){
		//! iso-surface creation
		Graphics.Blit (this.mrtTex[0], destination);
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