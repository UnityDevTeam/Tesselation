Shader "Custom/TriangleShader" {
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
		//#pragma geometry GS	
		
struct GlobalTriangle
{
	float3 ptA;
	float3 nmlA;
	float3 ptB;
	float3 nmlB;
	float3 ptC;
	float3 nmlC;
};
		
		struct GlobalVertex
		{
			float3 pt;
			float3 nml;
		};

		
													
		StructuredBuffer<GlobalTriangle> triangles;
		//StructuredBuffer<GlobalVertex> triangles;
		//StructuredBuffer<float3> triangles;
		struct vs2gs
		{
			float4 pos : SV_POSITION;
			float4 nml	: FLOAT;
			float4 clr : COLOR;
		};
			
		struct gs2fs
		{
			float4 pos : SV_POSITION;		
			float4 nml	: FLOAT;
		};
			
//		struct fsOutput
//		{
//			float4 color : COLOR0;		
//			float depth	: DEPTH;
//		};

		vs2gs VS(uint id : SV_VertexID, uint inst : SV_InstanceID)
		{
		    vs2gs output;	
		    //output.pos = float4(triangles[inst].pt[id],1.0);
		    //output.nml = float4(triangles[inst].nml[id],0.0);
		    
		    //output.pos =  float4(id,1.0,1.0,1.0);
//		    output.pos =  mul(UNITY_MATRIX_MVP,float4(triangles[inst*3+id].pt,1.0));
//		    output.nml =  mul(UNITY_MATRIX_MV,float4(triangles[inst*3+id].nml,0.0));
			GlobalTriangle gt = triangles[inst];
			if (id==0) 
			{ 
				output.pos =  mul(UNITY_MATRIX_MVP,float4(gt.ptA,1.0));
		    	output.nml =  mul(UNITY_MATRIX_MV,float4(gt.nmlA,0.0));
		    } else
		    if (id==1) 
			{ 
				output.pos =  mul(UNITY_MATRIX_MVP,float4(gt.ptB,1.0));
		    	output.nml =  mul(UNITY_MATRIX_MV,float4(gt.nmlB,0.0));
		    } else
			{ 
				output.pos =  mul(UNITY_MATRIX_MVP,float4(gt.ptC,1.0));
		    	output.nml =  mul(UNITY_MATRIX_MV,float4(gt.nmlC,0.0));
		    } 
		    output.clr = float4(1,0,0,1);
		    //if (inst>0) output.clr = float4(1,1,0,1);
		    return output;
		}
		
//		[maxvertexcount(3)]
//		void GS(triangle vs2gs input[3], inout TriangleStream<gs2fs> pointStream)
//		{
//			gs2fs output;
//			float3 ptA = input[0].pos;
//			float3 ptB = input[1].pos;
//			float3 ptC = input[2].pos;
//			float3 nmA = input[0].nml;
//			float3 nmB = input[1].nml;
//			float3 nmC = input[2].nml;
//
//			
//			output.pos = mul(UNITY_MATRIX_MVP, float4(ptA,1.0));							
//			output.nml = mul(UNITY_MATRIX_MV, float4(nmA,0.0));							
//			pointStream.Append(output);
//			
//			output.pos = mul(UNITY_MATRIX_MVP, float4(ptB,1.0));							
//			output.nml = mul(UNITY_MATRIX_MV, float4(nmB,0.0));							
//			pointStream.Append(output);
//			
//			output.pos = mul(UNITY_MATRIX_MVP, float4(ptC,1.0));							
//			output.nml = mul(UNITY_MATRIX_MV, float4(nmC,0.0));
//			pointStream.Append(output);
//
//			pointStream.RestartStrip();	
//		}
		
		//float4 FS (gs2fs input) : COLOR
		float4 FS (vs2gs input) : COLOR
		{					
			float pi = 3.14159265;
			float3 dir = normalize(input.pos - float3(0.5,0.5,0.5));
			float u = (atan2(dir.z,dir.x)+pi)/(2.0 * pi); 
			float v = 0.5 + 0.5* dot(float3(0,1,0),dir);

			//float d = abs(dot(normalize(_WorldSpaceLightPos0.xyz),-normal));
			float d = abs(dot(normalize(float3(1,1,1)),-input.nml.xyz));
			
			return float4(d,d,d,1);
			//return input.clr;
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
