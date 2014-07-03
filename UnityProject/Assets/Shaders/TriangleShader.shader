﻿Shader "Custom/TriangleShader" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader {
	Pass{
		
		Tags { "RenderType"="Opaque" }
		Cull Off Fog { Mode Off }
		LOD 200
		
		CGPROGRAM
		#include "UnityCG.cginc"
			
		#pragma only_renderers d3d11
		#pragma target 5.0				
		
		#pragma vertex VS			
		#pragma fragment FS	
		#pragma geometry GS	
		
		struct GlobalTriangle
		{
			float3 pt[3];
			float3 nml[3];
		};

		
													
		//StructuredBuffer<GlobalTriangle> triangles;
		StructuredBuffer<float3> triangles;
		struct vs2gs
		{
			float4 pos : SV_POSITION;
		};
			
		struct gs2fs
		{
			float4 pos : SV_POSITION;		
			float4 nml	: TEXCOORD0;
		};
			
//		struct fsOutput
//		{
//			float4 color : COLOR0;		
//			float depth	: DEPTH;
//		};

		vs2gs VS(uint id : SV_VertexID)
		{
		    vs2gs output;	
		    output.pos =  float4(id,1.0,1.0,1.0);
		    //output.pos =  float4(triangles[id].pt[0],1.0);
		    return output;
		}
		
		[maxvertexcount(4)]
		void GS(point vs2gs input[1], inout TriangleStream<gs2fs> pointStream)
		{
			gs2fs output;
			//GlobalTriangle gt = triangles[int(input[0].pos.x)];
			int idx = int(input[0].pos.x);
			float3 ptA = triangles[6*idx];
			float3 ptB = triangles[6*idx+1];
			float3 ptC = triangles[6*idx+2];
			float3 nmA = triangles[6*idx+3];
			float3 nmB = triangles[6*idx+4];
			float3 nmC = triangles[6*idx+5];
			
			output.pos = mul(UNITY_MATRIX_MVP, float4(ptA,1.0));							
			output.nml = mul(UNITY_MATRIX_MV, float4(nmA,0.0));							
			pointStream.Append(output);
			
			output.pos = mul(UNITY_MATRIX_MVP, float4(ptB,1.0));							
			output.nml = mul(UNITY_MATRIX_MV, float4(nmB,0.0));							
			pointStream.Append(output);
			
			output.pos = mul(UNITY_MATRIX_MVP, float4(ptC,1.0));							
			output.nml = mul(UNITY_MATRIX_MV, float4(nmC,0.0));
			pointStream.Append(output);
//			output.pos = mul(UNITY_MATRIX_MVP, float4(gt.pt[0],1.0));							
//			output.nml = mul(UNITY_MATRIX_MV, float4(gt.nml[0],0.0));							
//			pointStream.Append(output);
//			
//			output.pos = mul(UNITY_MATRIX_MVP, float4(gt.pt[1],1.0));							
//			output.nml = mul(UNITY_MATRIX_MV, float4(gt.nml[1],0.0));							
//			pointStream.Append(output);
//			
//			output.pos = mul(UNITY_MATRIX_MVP, float4(gt.pt[2],1.0));							
//			output.nml = mul(UNITY_MATRIX_MV, float4(gt.nml[2],0.0));
//			pointStream.Append(output);
			
//			output.pos = mul(UNITY_MATRIX_MVP, input[0].pos);							
//			output.nml = mul(UNITY_MATRIX_MV, float4(gt.nml[0],0.0));							
//			pointStream.Append(output);
//			
//			float4 sx=float4(0.5,0,0,0);
//			float4 sy=float4(0.0,0.5,0,0);
//			output.pos = mul(UNITY_MATRIX_MVP, (input[0].pos+sx));							
//			output.nml = mul(UNITY_MATRIX_MV, float4(gt.nml[1],0.0));							
//			pointStream.Append(output);
//			
//			output.pos = mul(UNITY_MATRIX_MVP, (input[0].pos+sy));							
//			output.nml = mul(UNITY_MATRIX_MV, float4(gt.nml[2],0.0));
//			pointStream.Append(output);							
			
			pointStream.RestartStrip();	
		}
		float4 FS (gs2fs input) : COLOR
		{					
			float pi = 3.14159265;
			float3 dir = normalize(input.pos - float3(0.5,0.5,0.5));
			float u = (atan2(dir.z,dir.x)+pi)/(2.0 * pi); 
			float v = 0.5 + 0.5* dot(float3(0,1,0),dir);

			//float d = abs(dot(normalize(_WorldSpaceLightPos0.xyz),-normal));
			float d = abs(dot(float3(0,0,-1),input.nml.xyz));
			
			//return float4(d,d,d,1);
			return float4(1,1,0,1);
		}
			
		ENDCG				
	} 
	// Second pass
		Pass
		{	
			ZWrite On 	
			CGPROGRAM	

			#include "UnityCG.cginc"			
			
			#pragma vertex VS			
			#pragma fragment FS							
																																									
			struct GlobalTriangle
			{
				float3 pt[3];
				float3 nml[3];
			};

		
													
			StructuredBuffer<GlobalTriangle> triangles;
			
			struct vs2fs
			{
				float4 pos : SV_POSITION;
			};
			

			vs2fs VS(uint id : SV_VertexID)
			{
			    GlobalTriangle triangleInfo = triangles[id];	
			    
			    vs2fs output;	
			    output.pos = mul (UNITY_MATRIX_MVP, float4(triangleInfo.pt[0].xyz, 1));	    
			    //output.pos = mul (UNITY_MATRIX_MVP, float4(0.0,0.0,0.0, 1));	    
			    return output;
			}
			
			float4 FS (vs2fs input) : COLOR
			{					
				return float4(1,1,1,1);
			}
			
			ENDCG					
		}	 
	
}
}
