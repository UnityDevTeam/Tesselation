Shader "Custom/GSMarchingCubes" 
{
  Properties 
	{
		//_SpriteTex ("Base (RGB)", 2D) = "white" {}
		_dataFieldTex ("Data Field Texture", 3D) = "white"{}
		_dataSize ("Data Field Texture Size", float) = 64 
		_meshSize ("Mesh Cube Size", float) = 32 
		_isoLevel ("isoLevel", Range(0.0, 1.0)) = 0.5
	}

	SubShader 
	{
		Pass
		{
			Cull Off
			Tags { "RenderType"="Opaque" }
			LOD 200
		
			CGPROGRAM
				#pragma target 5.0
				#pragma debug
				#pragma vertex VS_Main
				#pragma fragment FS_Main
				#pragma geometry GS_Main
				#include "UnityCG.cginc"  
				#include "Lighting.cginc"

				#define F3 1.0/3.0 
				#define G3 1.0/6.0 
				

				// **************************************************************
				// Data structures												*
				// **************************************************************
				struct GS_INPUT
				{
					float4	pos		: POSITION;
					//float3	normal	: NORMAL;
					float2  tex0	: TEXCOORD0;
				};

				struct FS_INPUT
				{
					float4	pos		: POSITION;
					float2  tex0	: TEXCOORD0;
					float3  normal  : NORMAL;
					float3  tex3D   : TEXCOORD1;
				};


				// **************************************************************
				// Vars															*
				// **************************************************************

				float _isoLevel;
 				sampler3D _dataFieldTex;
				//float4x4 _VP;
//				Texture2D _SpriteTex;
//				SamplerState sampler_SpriteTex;
				float _dataSize;
				float _meshSize;
				StructuredBuffer<float3> indices;

				// **************************************************************
				// Shader Programs												*
				// **************************************************************

				// Vertex Shader ------------------------------------------------
				
//				GS_INPUT VS_Main(appdata_base v)
//				{
//					GS_INPUT output = (GS_INPUT)0;
//					
//					output.pos =  v.vertex;
//					output.normal = v.normal;
//					output.tex0 = float2(0, 0);
//
//					return output;
//				}
				GS_INPUT VS_Main(uint id : SV_VertexID)
				{			    	
				    float3 atomInfo = indices[id];	
				    
				    GS_INPUT output;			    				    			    				    
				    output.pos = float4(atomInfo,1.0);		    
				    return output;
				}
 				

				float SampleData( float4 pPosition  ){
					//float3 sampleloc = pPosition.xyz - float3(0.5,0.5,0.5);
					//return sqrt(dot(sampleloc,sampleloc));
					return tex3Dlod(_dataFieldTex,float4(pPosition.xyz,0)).x;	
				}

				float SampleData3( float3 p){
					//float3 sampleloc = p - float3(0.5,0.5,0.5);
					//return sqrt(dot(sampleloc,sampleloc));
					return tex3Dlod(_dataFieldTex,float4(p.xyz,0)).x;	
				}

				// Geometry Shader -----------------------------------------------------
				[maxvertexcount(15)]
				void GS_Main(point GS_INPUT p[1], inout TriangleStream<FS_INPUT> triStream)	{
					
//					const float size = 1.0/32.0;
//	 				const float4 cubeVerts[8] = {
//						//front face
//						float4(0, 0, 0, 0) ,		//LB   0
//						float4(0,  size, 0,	0) ,		//LT   1
//						float4( size,  size, 0, 0) ,		//RT   2
//						float4( size, 0, 0, 0) ,		//RB   3
//						//bac0
//						float4(0, 0,  size, 0),		// LB  4
//						float4(0,  size,  size, 0),		// LT  5
//						float4( size,  size,  size, 0),		// RT  6
//						float4( size, 0,  size, 0)		// RB  7
//					};
//					

					const float halfSize = 0.5/_meshSize; 
	 				const float4 cubeVerts[8] = {
						//front face
						float4(-halfSize, -halfSize, -halfSize, 0) ,		//LB   0
						float4(-halfSize,  halfSize, -halfSize,	0) ,		//LT   1
						float4( halfSize,  halfSize, -halfSize, 0) ,		//RT   2
						float4( halfSize, -halfSize, -halfSize, 0) ,		//RB   3
						//bac0
						float4(-halfSize, -halfSize,  halfSize, 0),		// LB  4
						float4(-halfSize,  halfSize,  halfSize, 0),		// LT  5
						float4( halfSize,  halfSize,  halfSize, 0),		// RT  6
						float4( halfSize, -halfSize,  halfSize, 0)		// RB  7
					};

					float4 offset = float4(0.5,0.5,0.5,0.0);//Move cube pos from 0-1 to -0.5-0.5
					//float4 offset = float4(0.0,0.0,0.0,0.0);//Move cube pos from 0-1 to -0.5-0.5
					const float weights[8] = {
						SampleData(p[0].pos + cubeVerts[0] + offset),
						SampleData(p[0].pos + cubeVerts[1] + offset),
						SampleData(p[0].pos + cubeVerts[2] + offset),
						SampleData(p[0].pos + cubeVerts[3] + offset),
						SampleData(p[0].pos + cubeVerts[4] + offset),
						SampleData(p[0].pos + cubeVerts[5] + offset),
						SampleData(p[0].pos + cubeVerts[6] + offset),
						SampleData(p[0].pos + cubeVerts[7] + offset)
					};

					int cubeIndex = 
					(weights[7] < _isoLevel) * 128 + 
					(weights[6] < _isoLevel) * 64 +
					(weights[5] < _isoLevel) * 32 +
					(weights[4] < _isoLevel) * 16 +
					(weights[3] < _isoLevel) * 8 +
					(weights[2] < _isoLevel) * 4 +
					(weights[1] < _isoLevel) * 2 +
					(weights[0] < _isoLevel) * 1;

					const int2 edge_to_verts[12] = {
						int2(0,1), //0
						int2(1,2), //1
						int2(2,3), //2
						int2(3,0), //3
						int2(4,5), //4
						int2(5,6), //5
						int2(6,7), //6
						int2(7,4), //7
						int2(0,4), //8
						int2(1,5), //9
						int2(2,6), //10
						int2(3,7) //11
					};
					/*
					const int case_to_numpolys[256] = {
						0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,2,1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,3,
						1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,3,2,3,3,2,3,4,4,3,3,4,4,3,4,5,5,2,
						1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,3,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,4,
						2,3,3,4,3,4,2,3,3,4,4,5,4,5,3,2,3,4,4,3,4,5,3,2,4,5,5,4,5,2,4,1, 
						1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,3,2,3,3,4,3,4,4,5,3,2,4,3,4,3,5,2, 
						2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,4,3,4,4,3,4,5,5,4,4,3,5,2,5,4,2,1, 
						2,3,3,4,3,4,4,5,3,4,4,5,2,3,3,2,3,4,4,5,4,5,5,2,4,3,5,4,3,2,4,1, 
						3,4,4,5,4,5,3,4,4,5,5,2,3,4,2,1,2,3,3,2,3,4,2,1,3,2,4,1,2,1,1,0
					};
					*/
					
					//   256*5 = 1280 entries
					const int4 edge_connect_list[1280] = { 
						int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  8,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  1,  9, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  8,  3, -1),  int4(9,  8,  1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  2, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  8,  3, -1),  int4(1,  2, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  2, 10, -1),  int4(0,  2,  9, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2,  8,  3, -1),  int4(2, 10,  8, -1), int4(10,  9,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3, 11,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0, 11,  2, -1),  int4(8, 11,  0, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  9,  0, -1),  int4(2,  3, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1, 11,  2, -1),  int4(1,  9, 11, -1),  int4(9,  8, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3, 10,  1, -1), int4(11, 10,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0, 10,  1, -1),  int4(0,  8, 10, -1),  int4(8, 11, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  9,  0, -1),  int4(3, 11,  9, -1), int4(11, 10,  9, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  8, 10, -1), int4(10,  8, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  7,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  3,  0, -1),  int4(7,  3,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  1,  9, -1),  int4(8,  4,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  1,  9, -1),  int4(4,  7,  1, -1),  int4(7,  3,  1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  2, 10, -1),  int4(8,  4,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  4,  7, -1),  int4(3,  0,  4, -1),  int4(1,  2, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  2, 10, -1),  int4(9,  0,  2, -1),  int4(8,  4,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2, 10,  9, -1),  int4(2,  9,  7, -1),  int4(2,  7,  3, -1),  int4(7,  9,  4, -1), int4(-1, -1, -1, -1),
						int4(8,  4,  7, -1),  int4(3, 11,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(11,  4,  7, -1), int4(11,  2,  4, -1),  int4(2,  0,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  0,  1, -1),  int4(8,  4,  7, -1),  int4(2,  3, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  7, 11, -1),  int4(9,  4, 11, -1),  int4(9, 11,  2, -1),  int4(9,  2,  1, -1), int4(-1, -1, -1, -1),
						int4(3, 10,  1, -1),  int4(3, 11, 10, -1),  int4(7,  8,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1, 11, 10, -1),  int4(1,  4, 11, -1),  int4(1,  0,  4, -1),  int4(7, 11,  4, -1), int4(-1, -1, -1, -1),
						int4(4,  7,  8, -1),  int4(9,  0, 11, -1),  int4(9, 11, 10, -1), int4(11,  0,  3, -1), int4(-1, -1, -1, -1),
						int4(4,  7, 11, -1),  int4(4, 11,  9, -1),  int4(9, 11, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  5,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  5,  4, -1),  int4(0,  8,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  5,  4, -1),  int4(1,  5,  0, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(8,  5,  4, -1),  int4(8,  3,  5, -1),  int4(3,  1,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  2, 10, -1),  int4(9,  5,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  0,  8, -1),  int4(1,  2, 10, -1),  int4(4,  9,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(5,  2, 10, -1),  int4(5,  4,  2, -1),  int4(4,  0,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2, 10,  5, -1),  int4(3,  2,  5, -1),  int4(3,  5,  4, -1),  int4(3,  4,  8, -1), int4(-1, -1, -1, -1),
						int4(9,  5,  4, -1),  int4(2,  3, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0, 11,  2, -1),  int4(0,  8, 11, -1),  int4(4,  9,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  5,  4, -1),  int4(0,  1,  5, -1),  int4(2,  3, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2,  1,  5, -1),  int4(2,  5,  8, -1),  int4(2,  8, 11, -1),  int4(4,  8,  5, -1), int4(-1, -1, -1, -1),
						int4(10,  3, 11, -1), int4(10,  1,  3, -1),  int4(9,  5,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  9,  5, -1),  int4(0,  8,  1, -1),  int4(8, 10,  1, -1),  int4(8, 11, 10, -1), int4(-1, -1, -1, -1),
						int4(5,  4,  0, -1),  int4(5,  0, 11, -1),  int4(5, 11, 10, -1), int4(11,  0,  3, -1), int4(-1, -1, -1, -1),
						int4(5,  4,  8, -1),  int4(5,  8, 10, -1), int4(10,  8, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  7,  8, -1),  int4(5,  7,  9, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  3,  0, -1),  int4(9,  5,  3, -1),  int4(5,  7,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  7,  8, -1),  int4(0,  1,  7, -1),  int4(1,  5,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  5,  3, -1),  int4(3,  5,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  7,  8, -1),  int4(9,  5,  7, -1), int4(10,  1,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(10,  1,  2, -1),  int4(9,  5,  0, -1),  int4(5,  3,  0, -1),  int4(5,  7,  3, -1), int4(-1, -1, -1, -1),
						int4(8,  0,  2, -1),  int4(8,  2,  5, -1),  int4(8,  5,  7, -1), int4(10,  5,  2, -1), int4(-1, -1, -1, -1),
						int4(2, 10,  5, -1),  int4(2,  5,  3, -1),  int4(3,  5,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(7,  9,  5, -1),  int4(7,  8,  9, -1),  int4(3, 11,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  5,  7, -1),  int4(9,  7,  2, -1),  int4(9,  2,  0, -1),  int4(2,  7, 11, -1), int4(-1, -1, -1, -1),
						int4(2,  3, 11, -1),  int4(0,  1,  8, -1),  int4(1,  7,  8, -1),  int4(1,  5,  7, -1), int4(-1, -1, -1, -1),
						int4(11,  2,  1, -1), int4(11,  1,  7, -1),  int4(7,  1,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  5,  8, -1),  int4(8,  5,  7, -1), int4(10,  1,  3, -1), int4(10,  3, 11, -1), int4(-1, -1, -1, -1),
						int4(5,  7,  0, -1),  int4(5,  0,  9, -1),  int4(7, 11,  0, -1),  int4(1,  0, 10, -1), int4(11, 10,  0, -1),
						int4(11, 10,  0, -1), int4(11,  0,  3, -1), int4(10,  5,  0, -1),  int4(8,  0,  7, -1),  int4(5,  7,  0, -1),
						int4(11, 10,  5, -1),  int4(7, 11,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(10,  6,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  8,  3, -1),  int4(5, 10,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  0,  1, -1),  int4(5, 10,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  8,  3, -1),  int4(1,  9,  8, -1),  int4(5, 10,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  6,  5, -1),  int4(2,  6,  1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  6,  5, -1),  int4(1,  2,  6, -1),  int4(3,  0,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  6,  5, -1),  int4(9,  0,  6, -1),  int4(0,  2,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(5,  9,  8, -1),  int4(5,  8,  2, -1),  int4(5,  2,  6, -1),  int4(3,  2,  8, -1), int4(-1, -1, -1, -1),
						int4(2,  3, 11, -1), int4(10,  6,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(11,  0,  8, -1), int4(11,  2,  0, -1), int4(10,  6,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  1,  9, -1),  int4(2,  3, 11, -1),  int4(5, 10,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(5, 10,  6, -1),  int4(1,  9,  2, -1),  int4(9, 11,  2, -1),  int4(9,  8, 11, -1), int4(-1, -1, -1, -1),
						int4(6,  3, 11, -1),  int4(6,  5,  3, -1),  int4(5,  1,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  8, 11, -1),  int4(0, 11,  5, -1),  int4(0,  5,  1, -1),  int4(5, 11,  6, -1), int4(-1, -1, -1, -1),
						int4(3, 11,  6, -1),  int4(0,  3,  6, -1),  int4(0,  6,  5, -1),  int4(0,  5,  9, -1), int4(-1, -1, -1, -1),
						int4(6,  5,  9, -1),  int4(6,  9, 11, -1), int4(11,  9,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(5, 10,  6, -1),  int4(4,  7,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  3,  0, -1),  int4(4,  7,  3, -1),  int4(6,  5, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  9,  0, -1),  int4(5, 10,  6, -1),  int4(8,  4,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(10,  6,  5, -1),  int4(1,  9,  7, -1),  int4(1,  7,  3, -1),  int4(7,  9,  4, -1), int4(-1, -1, -1, -1),
						int4(6,  1,  2, -1),  int4(6,  5,  1, -1),  int4(4,  7,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  2,  5, -1),  int4(5,  2,  6, -1),  int4(3,  0,  4, -1),  int4(3,  4,  7, -1), int4(-1, -1, -1, -1),
						int4(8,  4,  7, -1),  int4(9,  0,  5, -1),  int4(0,  6,  5, -1),  int4(0,  2,  6, -1), int4(-1, -1, -1, -1),
						int4(7,  3,  9, -1),  int4(7,  9,  4, -1),  int4(3,  2,  9, -1),  int4(5,  9,  6, -1),  int4(2,  6,  9, -1),
						int4(3, 11,  2, -1),  int4(7,  8,  4, -1), int4(10,  6,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(5, 10,  6, -1),  int4(4,  7,  2, -1),  int4(4,  2,  0, -1),  int4(2,  7, 11, -1), int4(-1, -1, -1, -1),
						int4(0,  1,  9, -1),  int4(4,  7,  8, -1),  int4(2,  3, 11, -1),  int4(5, 10,  6, -1), int4(-1, -1, -1, -1),
						int4(9,  2,  1, -1),  int4(9, 11,  2, -1),  int4(9,  4, 11, -1),  int4(7, 11,  4, -1),  int4(5, 10,  6, -1),
						int4(8,  4,  7, -1),  int4(3, 11,  5, -1),  int4(3,  5,  1, -1),  int4(5, 11,  6, -1), int4(-1, -1, -1, -1),
						int4(5,  1, 11, -1),  int4(5, 11,  6, -1),  int4(1,  0, 11, -1),  int4(7, 11,  4, -1),  int4(0,  4, 11, -1),
						int4(0,  5,  9, -1),  int4(0,  6,  5, -1),  int4(0,  3,  6, -1), int4(11,  6,  3, -1),  int4(8,  4,  7, -1),
						int4(6,  5,  9, -1),  int4(6,  9, 11, -1),  int4(4,  7,  9, -1),  int4(7, 11,  9, -1), int4(-1, -1, -1, -1),
						int4(10,  4,  9, -1),  int4(6,  4, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4, 10,  6, -1),  int4(4,  9, 10, -1),  int4(0,  8,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(10,  0,  1, -1), int4(10,  6,  0, -1),  int4(6,  4,  0, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(8,  3,  1, -1),  int4(8,  1,  6, -1),  int4(8,  6,  4, -1),  int4(6,  1, 10, -1), int4(-1, -1, -1, -1),
						int4(1,  4,  9, -1),  int4(1,  2,  4, -1),  int4(2,  6,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  0,  8, -1),  int4(1,  2,  9, -1),  int4(2,  4,  9, -1),  int4(2,  6,  4, -1), int4(-1, -1, -1, -1),
						int4(0,  2,  4, -1),  int4(4,  2,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(8,  3,  2, -1),  int4(8,  2,  4, -1),  int4(4,  2,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(10,  4,  9, -1), int4(10,  6,  4, -1), int4(11,  2,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  8,  2, -1),  int4(2,  8, 11, -1),  int4(4,  9, 10, -1),  int4(4, 10,  6, -1), int4(-1, -1, -1, -1),
						int4(3, 11,  2, -1),  int4(0,  1,  6, -1),  int4(0,  6,  4, -1),  int4(6,  1, 10, -1), int4(-1, -1, -1, -1),
						int4(6,  4,  1, -1),  int4(6,  1, 10, -1),  int4(4,  8,  1, -1),  int4(2,  1, 11, -1),  int4(8, 11,  1, -1),
						int4(9,  6,  4, -1),  int4(9,  3,  6, -1),  int4(9,  1,  3, -1), int4(11,  6,  3, -1), int4(-1, -1, -1, -1),
						int4(8, 11,  1, -1),  int4(8,  1,  0, -1), int4(11,  6,  1, -1),  int4(9,  1,  4, -1),  int4(6,  4,  1, -1),
						int4(3, 11,  6, -1),  int4(3,  6,  0, -1),  int4(0,  6,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(6,  4,  8, -1), int4(11,  6,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(7, 10,  6, -1),  int4(7,  8, 10, -1),  int4(8,  9, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  7,  3, -1),  int4(0, 10,  7, -1),  int4(0,  9, 10, -1),  int4(6,  7, 10, -1), int4(-1, -1, -1, -1),
						int4(10,  6,  7, -1),  int4(1, 10,  7, -1),  int4(1,  7,  8, -1),  int4(1,  8,  0, -1), int4(-1, -1, -1, -1),
						int4(10,  6,  7, -1), int4(10,  7,  1, -1),  int4(1,  7,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  2,  6, -1),  int4(1,  6,  8, -1),  int4(1,  8,  9, -1),  int4(8,  6,  7, -1), int4(-1, -1, -1, -1),
						int4(2,  6,  9, -1),  int4(2,  9,  1, -1),  int4(6,  7,  9, -1),  int4(0,  9,  3, -1),  int4(7,  3,  9, -1),
						int4(7,  8,  0, -1),  int4(7,  0,  6, -1),  int4(6,  0,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(7,  3,  2, -1),  int4(6,  7,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2,  3, 11, -1), int4(10,  6,  8, -1), int4(10,  8,  9, -1),  int4(8,  6,  7, -1), int4(-1, -1, -1, -1),
						int4(2,  0,  7, -1),  int4(2,  7, 11, -1),  int4(0,  9,  7, -1),  int4(6,  7, 10, -1),  int4(9, 10,  7, -1),
						int4(1,  8,  0, -1),  int4(1,  7,  8, -1),  int4(1, 10,  7, -1),  int4(6,  7, 10, -1),  int4(2,  3, 11, -1),
						int4(11,  2,  1, -1), int4(11,  1,  7, -1), int4(10,  6,  1, -1),  int4(6,  7,  1, -1), int4(-1, -1, -1, -1),
						int4(8,  9,  6, -1),  int4(8,  6,  7, -1),  int4(9,  1,  6, -1), int4(11,  6,  3, -1),  int4(1,  3,  6, -1),
						int4(0,  9,  1, -1), int4(11,  6,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(7,  8,  0, -1),  int4(7,  0,  6, -1),  int4(3, 11,  0, -1), int4(11,  6,  0, -1), int4(-1, -1, -1, -1),
						int4(7, 11,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(7,  6, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  0,  8, -1), int4(11,  7,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  1,  9, -1), int4(11,  7,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(8,  1,  9, -1),  int4(8,  3,  1, -1), int4(11,  7,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(10,  1,  2, -1),  int4(6, 11,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  2, 10, -1),  int4(3,  0,  8, -1),  int4(6, 11,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2,  9,  0, -1),  int4(2, 10,  9, -1),  int4(6, 11,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(6, 11,  7, -1),  int4(2, 10,  3, -1), int4(10,  8,  3, -1), int4(10,  9,  8, -1), int4(-1, -1, -1, -1),
						int4(7,  2,  3, -1),  int4(6,  2,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(7,  0,  8, -1),  int4(7,  6,  0, -1),  int4(6,  2,  0, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2,  7,  6, -1),  int4(2,  3,  7, -1),  int4(0,  1,  9, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  6,  2, -1),  int4(1,  8,  6, -1),  int4(1,  9,  8, -1),  int4(8,  7,  6, -1), int4(-1, -1, -1, -1),
						int4(10,  7,  6, -1), int4(10,  1,  7, -1),  int4(1,  3,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(10,  7,  6, -1),  int4(1,  7, 10, -1),  int4(1,  8,  7, -1),  int4(1,  0,  8, -1), int4(-1, -1, -1, -1),
						int4(0,  3,  7, -1),  int4(0,  7, 10, -1),  int4(0, 10,  9, -1),  int4(6, 10,  7, -1), int4(-1, -1, -1, -1),
						int4(7,  6, 10, -1),  int4(7, 10,  8, -1),  int4(8, 10,  9, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(6,  8,  4, -1), int4(11,  8,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  6, 11, -1),  int4(3,  0,  6, -1),  int4(0,  4,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(8,  6, 11, -1),  int4(8,  4,  6, -1),  int4(9,  0,  1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  4,  6, -1),  int4(9,  6,  3, -1),  int4(9,  3,  1, -1), int4(11,  3,  6, -1), int4(-1, -1, -1, -1),
						int4(6,  8,  4, -1),  int4(6, 11,  8, -1),  int4(2, 10,  1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  2, 10, -1),  int4(3,  0, 11, -1),  int4(0,  6, 11, -1),  int4(0,  4,  6, -1), int4(-1, -1, -1, -1),
						int4(4, 11,  8, -1),  int4(4,  6, 11, -1),  int4(0,  2,  9, -1),  int4(2, 10,  9, -1), int4(-1, -1, -1, -1),
						int4(10,  9,  3, -1), int4(10,  3,  2, -1),  int4(9,  4,  3, -1), int4(11,  3,  6, -1),  int4(4,  6,  3, -1),
						int4(8,  2,  3, -1),  int4(8,  4,  2, -1),  int4(4,  6,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  4,  2, -1),  int4(4,  6,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  9,  0, -1),  int4(2,  3,  4, -1),  int4(2,  4,  6, -1),  int4(4,  3,  8, -1), int4(-1, -1, -1, -1),
						int4(1,  9,  4, -1),  int4(1,  4,  2, -1),  int4(2,  4,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(8,  1,  3, -1),  int4(8,  6,  1, -1),  int4(8,  4,  6, -1),  int4(6, 10,  1, -1), int4(-1, -1, -1, -1),
						int4(10,  1,  0, -1), int4(10,  0,  6, -1),  int4(6,  0,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  6,  3, -1),  int4(4,  3,  8, -1),  int4(6, 10,  3, -1),  int4(0,  3,  9, -1), int4(10,  9,  3, -1),
						int4(10,  9,  4, -1),  int4(6, 10,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  9,  5, -1),  int4(7,  6, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  8,  3, -1),  int4(4,  9,  5, -1), int4(11,  7,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(5,  0,  1, -1),  int4(5,  4,  0, -1),  int4(7,  6, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(11,  7,  6, -1),  int4(8,  3,  4, -1),  int4(3,  5,  4, -1),  int4(3,  1,  5, -1), int4(-1, -1, -1, -1),
						int4(9,  5,  4, -1), int4(10,  1,  2, -1),  int4(7,  6, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(6, 11,  7, -1),  int4(1,  2, 10, -1),  int4(0,  8,  3, -1),  int4(4,  9,  5, -1), int4(-1, -1, -1, -1),
						int4(7,  6, 11, -1),  int4(5,  4, 10, -1),  int4(4,  2, 10, -1),  int4(4,  0,  2, -1), int4(-1, -1, -1, -1),
						int4(3,  4,  8, -1),  int4(3,  5,  4, -1),  int4(3,  2,  5, -1), int4(10,  5,  2, -1), int4(11,  7,  6, -1),
						int4(7,  2,  3, -1),  int4(7,  6,  2, -1),  int4(5,  4,  9, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  5,  4, -1),  int4(0,  8,  6, -1),  int4(0,  6,  2, -1),  int4(6,  8,  7, -1), int4(-1, -1, -1, -1),
						int4(3,  6,  2, -1),  int4(3,  7,  6, -1),  int4(1,  5,  0, -1),  int4(5,  4,  0, -1), int4(-1, -1, -1, -1),
						int4(6,  2,  8, -1),  int4(6,  8,  7, -1),  int4(2,  1,  8, -1),  int4(4,  8,  5, -1),  int4(1,  5,  8, -1),
						int4(9,  5,  4, -1), int4(10,  1,  6, -1),  int4(1,  7,  6, -1),  int4(1,  3,  7, -1), int4(-1, -1, -1, -1),
						int4(1,  6, 10, -1),  int4(1,  7,  6, -1),  int4(1,  0,  7, -1),  int4(8,  7,  0, -1),  int4(9,  5,  4, -1),
						int4(4,  0, 10, -1),  int4(4, 10,  5, -1),  int4(0,  3, 10, -1),  int4(6, 10,  7, -1),  int4(3,  7, 10, -1),
						int4(7,  6, 10, -1),  int4(7, 10,  8, -1),  int4(5,  4, 10, -1),  int4(4,  8, 10, -1), int4(-1, -1, -1, -1),
						int4(6,  9,  5, -1),  int4(6, 11,  9, -1), int4(11,  8,  9, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  6, 11, -1),  int4(0,  6,  3, -1),  int4(0,  5,  6, -1),  int4(0,  9,  5, -1), int4(-1, -1, -1, -1),
						int4(0, 11,  8, -1),  int4(0,  5, 11, -1),  int4(0,  1,  5, -1),  int4(5,  6, 11, -1), int4(-1, -1, -1, -1),
						int4(6, 11,  3, -1),  int4(6,  3,  5, -1),  int4(5,  3,  1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  2, 10, -1),  int4(9,  5, 11, -1),  int4(9, 11,  8, -1), int4(11,  5,  6, -1), int4(-1, -1, -1, -1),
						int4(0, 11,  3, -1),  int4(0,  6, 11, -1),  int4(0,  9,  6, -1),  int4(5,  6,  9, -1),  int4(1,  2, 10, -1),
						int4(11,  8,  5, -1), int4(11,  5,  6, -1),  int4(8,  0,  5, -1), int4(10,  5,  2, -1),  int4(0,  2,  5, -1),
						int4(6, 11,  3, -1),  int4(6,  3,  5, -1),  int4(2, 10,  3, -1), int4(10,  5,  3, -1), int4(-1, -1, -1, -1),
						int4(5,  8,  9, -1),  int4(5,  2,  8, -1),  int4(5,  6,  2, -1),  int4(3,  8,  2, -1), int4(-1, -1, -1, -1),
						int4(9,  5,  6, -1),  int4(9,  6,  0, -1),  int4(0,  6,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  5,  8, -1),  int4(1,  8,  0, -1),  int4(5,  6,  8, -1),  int4(3,  8,  2, -1),  int4(6,  2,  8, -1),
						int4(1,  5,  6, -1),  int4(2,  1,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  3,  6, -1),  int4(1,  6, 10, -1),  int4(3,  8,  6, -1),  int4(5,  6,  9, -1),  int4(8,  9,  6, -1),
						int4(10,  1,  0, -1), int4(10,  0,  6, -1),  int4(9,  5,  0, -1),  int4(5,  6,  0, -1), int4(-1, -1, -1, -1),
						int4(0,  3,  8, -1),  int4(5,  6, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(10,  5,  6, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(11,  5, 10, -1),  int4(7,  5, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(11,  5, 10, -1), int4(11,  7,  5, -1),  int4(8,  3,  0, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(5, 11,  7, -1),  int4(5, 10, 11, -1),  int4(1,  9,  0, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(10,  7,  5, -1), int4(10, 11,  7, -1),  int4(9,  8,  1, -1),  int4(8,  3,  1, -1), int4(-1, -1, -1, -1),
						int4(11,  1,  2, -1), int4(11,  7,  1, -1),  int4(7,  5,  1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  8,  3, -1),  int4(1,  2,  7, -1),  int4(1,  7,  5, -1),  int4(7,  2, 11, -1), int4(-1, -1, -1, -1),
						int4(9,  7,  5, -1),  int4(9,  2,  7, -1),  int4(9,  0,  2, -1),  int4(2, 11,  7, -1), int4(-1, -1, -1, -1),
						int4(7,  5,  2, -1),  int4(7,  2, 11, -1),  int4(5,  9,  2, -1),  int4(3,  2,  8, -1),  int4(9,  8,  2, -1),
						int4(2,  5, 10, -1),  int4(2,  3,  5, -1),  int4(3,  7,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(8,  2,  0, -1),  int4(8,  5,  2, -1),  int4(8,  7,  5, -1), int4(10,  2,  5, -1), int4(-1, -1, -1, -1),
						int4(9,  0,  1, -1),  int4(5, 10,  3, -1),  int4(5,  3,  7, -1),  int4(3, 10,  2, -1), int4(-1, -1, -1, -1),
						int4(9,  8,  2, -1),  int4(9,  2,  1, -1),  int4(8,  7,  2, -1), int4(10,  2,  5, -1),  int4(7,  5,  2, -1),
						int4(1,  3,  5, -1),  int4(3,  7,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  8,  7, -1),  int4(0,  7,  1, -1),  int4(1,  7,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  0,  3, -1),  int4(9,  3,  5, -1),  int4(5,  3,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9,  8,  7, -1),  int4(5,  9,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(5,  8,  4, -1),  int4(5, 10,  8, -1), int4(10, 11,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(5,  0,  4, -1),  int4(5, 11,  0, -1),  int4(5, 10, 11, -1), int4(11,  3,  0, -1), int4(-1, -1, -1, -1),
						int4(0,  1,  9, -1),  int4(8,  4, 10, -1),  int4(8, 10, 11, -1), int4(10,  4,  5, -1), int4(-1, -1, -1, -1),
						int4(10, 11,  4, -1), int4(10,  4,  5, -1), int4(11,  3,  4, -1),  int4(9,  4,  1, -1),  int4(3,  1,  4, -1),
						int4(2,  5,  1, -1),  int4(2,  8,  5, -1),  int4(2, 11,  8, -1),  int4(4,  5,  8, -1), int4(-1, -1, -1, -1),
						int4(0,  4, 11, -1),  int4(0, 11,  3, -1),  int4(4,  5, 11, -1),  int4(2, 11,  1, -1),  int4(5,  1, 11, -1),
						int4(0,  2,  5, -1),  int4(0,  5,  9, -1),  int4(2, 11,  5, -1),  int4(4,  5,  8, -1), int4(11,  8,  5, -1),
						int4(9,  4,  5, -1),  int4(2, 11,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2,  5, 10, -1),  int4(3,  5,  2, -1),  int4(3,  4,  5, -1),  int4(3,  8,  4, -1), int4(-1, -1, -1, -1),
						int4(5, 10,  2, -1),  int4(5,  2,  4, -1),  int4(4,  2,  0, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3, 10,  2, -1),  int4(3,  5, 10, -1),  int4(3,  8,  5, -1),  int4(4,  5,  8, -1),  int4(0,  1,  9, -1),
						int4(5, 10,  2, -1),  int4(5,  2,  4, -1),  int4(1,  9,  2, -1),  int4(9,  4,  2, -1), int4(-1, -1, -1, -1),
						int4(8,  4,  5, -1),  int4(8,  5,  3, -1),  int4(3,  5,  1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  4,  5, -1),  int4(1,  0,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(8,  4,  5, -1),  int4(8,  5,  3, -1),  int4(9,  0,  5, -1),  int4(0,  3,  5, -1), int4(-1, -1, -1, -1),
						int4(9,  4,  5, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4, 11,  7, -1),  int4(4,  9, 11, -1),  int4(9, 10, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  8,  3, -1),  int4(4,  9,  7, -1),  int4(9, 11,  7, -1),  int4(9, 10, 11, -1), int4(-1, -1, -1, -1),
						int4(1, 10, 11, -1),  int4(1, 11,  4, -1),  int4(1,  4,  0, -1),  int4(7,  4, 11, -1), int4(-1, -1, -1, -1),
						int4(3,  1,  4, -1),  int4(3,  4,  8, -1),  int4(1, 10,  4, -1),  int4(7,  4, 11, -1), int4(10, 11,  4, -1),
						int4(4, 11,  7, -1),  int4(9, 11,  4, -1),  int4(9,  2, 11, -1),  int4(9,  1,  2, -1), int4(-1, -1, -1, -1),
						int4(9,  7,  4, -1),  int4(9, 11,  7, -1),  int4(9,  1, 11, -1),  int4(2, 11,  1, -1),  int4(0,  8,  3, -1),
						int4(11,  7,  4, -1), int4(11,  4,  2, -1),  int4(2,  4,  0, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(11,  7,  4, -1), int4(11,  4,  2, -1),  int4(8,  3,  4, -1),  int4(3,  2,  4, -1), int4(-1, -1, -1, -1),
						int4(2,  9, 10, -1),  int4(2,  7,  9, -1),  int4(2,  3,  7, -1),  int4(7,  4,  9, -1), int4(-1, -1, -1, -1),
						int4(9, 10,  7, -1),  int4(9,  7,  4, -1), int4(10,  2,  7, -1),  int4(8,  7,  0, -1),  int4(2,  0,  7, -1),
						int4(3,  7, 10, -1),  int4(3, 10,  2, -1),  int4(7,  4, 10, -1),  int4(1, 10,  0, -1),  int4(4,  0, 10, -1),
						int4(1, 10,  2, -1),  int4(8,  7,  4, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  9,  1, -1),  int4(4,  1,  7, -1),  int4(7,  1,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  9,  1, -1),  int4(4,  1,  7, -1),  int4(0,  8,  1, -1),  int4(8,  7,  1, -1), int4(-1, -1, -1, -1),
						int4(4,  0,  3, -1),  int4(7,  4,  3, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(4,  8,  7, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9, 10,  8, -1), int4(10, 11,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  0,  9, -1),  int4(3,  9, 11, -1), int4(11,  9, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  1, 10, -1),  int4(0, 10,  8, -1),  int4(8, 10, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  1, 10, -1), int4(11,  3, 10, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  2, 11, -1),  int4(1, 11,  9, -1),  int4(9, 11,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  0,  9, -1),  int4(3,  9, 11, -1),  int4(1,  2,  9, -1),  int4(2, 11,  9, -1), int4(-1, -1, -1, -1),
						int4(0,  2, 11, -1),  int4(8,  0, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(3,  2, 11, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2,  3,  8, -1),  int4(2,  8, 10, -1), int4(10,  8,  9, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(9, 10,  2, -1),  int4(0,  9,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(2,  3,  8, -1),  int4(2,  8, 10, -1),  int4(0,  1,  8, -1),  int4(1, 10,  8, -1), int4(-1, -1, -1, -1),
						int4(1, 10,  2, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(1,  3,  8, -1),  int4(9,  1,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  9,  1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(0,  3,  8, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1),
						int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1), int4(-1, -1, -1, -1)
					};
					
					//int numpolys = case_to_numpolys[cubeIndex];
				
					float4x4 vp = UNITY_MATRIX_MVP;//mul(UNITY_MATRIX_MVP, _World2Object);
					FS_INPUT pIn;
					for( int i = 0; i < 5; i++ ){
						int4 vertlistIndices = edge_connect_list[cubeIndex * 5 + i];
						if(vertlistIndices.x != -1) {	
							int va = edge_to_verts[vertlistIndices.x].x;
							int vb = edge_to_verts[vertlistIndices.x].y;
							float amount = (_isoLevel - weights[va]) / (weights[vb] - weights[va]);
							float4 worldPos = lerp( p[0].pos + cubeVerts[va],  p[0].pos + cubeVerts[vb], amount);
							float4 texA = worldPos+offset;
							float4 pA = mul(vp, worldPos);
							
							va = edge_to_verts[vertlistIndices.y].x;
							vb = edge_to_verts[vertlistIndices.y].y;
							amount = (_isoLevel - weights[va]) / (weights[vb] - weights[va]);
							worldPos = lerp( p[0].pos + cubeVerts[va],  p[0].pos + cubeVerts[vb], amount);
							float4 texB = worldPos+offset;
							float4 pB = mul(vp, worldPos);
							
							va = edge_to_verts[vertlistIndices.z].x;
							vb = edge_to_verts[vertlistIndices.z].y;
							amount = (_isoLevel - weights[va]) / (weights[vb] - weights[va]);
							worldPos = lerp( p[0].pos + cubeVerts[va],  p[0].pos + cubeVerts[vb], amount);
							float4 texC = worldPos+offset;
							float4 pC = mul(vp, worldPos);

							float4 r = pA - pC;
							float4 f = pA - pB;
							float3 normal = normalize(cross(f,r));

							pIn.pos = pA;
							pIn.tex3D = texA;
							pIn.tex0 = float2(1.0f, 0.0f);
							pIn.normal = normal;
							triStream.Append(pIn);
							
							pIn.normal = normal;
							pIn.pos = pC;
							pIn.tex3D = texC;
							pIn.tex0 = float2(1.0f, 0.0f);
							triStream.Append(pIn);

							pIn.pos = pB;
							pIn.tex3D = texB;
							pIn.tex0 = float2(1.0f, 0.0f);
							pIn.normal = normal;
							triStream.Append(pIn);
							
							triStream.RestartStrip();
						}else{
							pIn.pos = float4(0,0,0,0);// + p[0].pos;
							pIn.tex0 = float2(1.0f, 0.0f);
							pIn.normal = float3(0,1,0);
							triStream.Append(pIn);
							triStream.Append(pIn);
							triStream.Append(pIn);
							triStream.RestartStrip();
						}
					}
					
				}

				// Fragment Shader -----------------------------------------------
				float4 FS_Main(FS_INPUT input) : COLOR
				{
					float dataStepSize = _dataSize;
					float h2 = dataStepSize*2.0;
					float3 position = input.tex3D;
					float3 dataStep = float3(1.0/dataStepSize,1.0/dataStepSize,1.0/dataStepSize);

					float3 grad = float3(
									(SampleData3(position + float3(dataStep.x, 0, 0)).x - SampleData3(position+float3(-dataStep.x, 0, 0)).x)/h2, 
									(SampleData3(position+float3(0, dataStep.y, 0)).x - SampleData3(position+float3(0, -dataStep.y, 0)).x)/h2, 
									(SampleData3(position+float3(0,0,dataStep.z)).x - SampleData3(position+float3(0,0,-dataStep.z)).x)/h2
									);
					float3 normal = normalize(grad);
					normal = mul(_Object2World,normal);
					normal = normalize(normal);
					
					float pi = 3.14159265;
					float3 dir = normalize(position - float3(0.5,0.5,0.5));
					float u = (atan2(dir.z,dir.x)+pi)/(2.0 * pi); 
					float v = 0.5 + 0.5* dot(float3(0,1,0),dir);

					float d = abs(dot(normalize(_WorldSpaceLightPos0.xyz),-normal));
					//return float4(d,d,d,1);
					return float4(1,1,1,1);
					//return float4(normal,1);
					//return _SpriteTex.Sample(sampler_SpriteTex, float2(u,v))  * saturate(0.5 + normal.y * 0.5) ;
					//return _SpriteTex.Sample(sampler_SpriteTex, float2(u,v))  * d;
				}

			ENDCG
		}
	} 
}