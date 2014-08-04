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
		#define _dataSize 256.0
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
		
		
		sampler3D _dataFieldTex;
		
		float SampleData3( float3 p){
			return tex3Dlod(_dataFieldTex,float4(p.xyz,0)).x;	
		}

		float compute_obscurance(float3 normal, //surface normal
						  				 float dist,	//distance of the sample from the surface point
						  				 float3 gf, 	//gradient at the sample
						  				 float f)		//function value at the sample
		{
			//float _obscurence =  exp(-pow_param.y*dist);
			float _obscurence =  exp(-5.0f*dist);
			float cosR = 1.0;
			float cosRD = dot(gf,normal);
			cosR = 1.0f/(1.0f+exp(8.0f*cosRD-1.0f));
			//cosR=1.0;
			_obscurence = (cosR*_obscurence)/(1.0f+exp(-8.0f*f-4.0));
			return _obscurence;
		}
		
		float3 ComputeGradient(float3 position, float3 dataStep, float h2)
		{
			float3 grad = float3(
							(SampleData3(position + float3(dataStep.x, 0, 0)).x - SampleData3(position+float3(-dataStep.x, 0, 0)).x)/h2, 
							(SampleData3(position+float3(0, dataStep.y, 0)).x - SampleData3(position+float3(0, -dataStep.y, 0)).x)/h2, 
							(SampleData3(position+float3(0,0,dataStep.z)).x - SampleData3(position+float3(0,0,-dataStep.z)).x)/h2
							);
			return grad;
		}
		
		float3 get_orthogonal_vec(float3 v)
		{
			float3 g=float3(1,0,0);
			float3 h = cross(v,g);
			return h;
		}

		
		float OcclusionFactor(float3 p, int steps, float3 normal, float3 dataStep, float h2)
		{
				float fmin=-0.5;
				float t=0.5*dataStep.x;
				float ao=0.0;
				int samplesCount=0;
				float3 xaxis = get_orthogonal_vec(normal);
				float3 yaxis = normalize(cross(normal,xaxis));
				float3 x[20];
				float axsc = t/0.47;
				float3 sdir=normal;
				x[0] = p - t*sdir;
				x[1] = x[0]+axsc*xaxis; x[1]=x[0]+t*normalize(x[1]-x[0]);
				x[2] = x[0]-axsc*xaxis; x[2]=x[0]+t*normalize(x[2]-x[0]);
				x[3] = x[0]-axsc*yaxis; x[3]=x[0]+t*normalize(x[3]-x[0]);
				x[4] = x[0]+axsc*yaxis; x[4]=x[0]+t*normalize(x[4]-x[0]);
				t*=1.5;
				axsc = t/0.47;
				float scale=0.5;
				x[5] = x[0] - scale*t*sdir;
				x[6] = x[5]+axsc*xaxis; x[6]=x[5]+t*normalize(x[6]-x[5]);
				x[7] = x[5]-axsc*xaxis; x[7]=x[5]+t*normalize(x[7]-x[5]);
				x[8] = x[5]-axsc*yaxis; x[8]=x[5]+t*normalize(x[8]-x[5]);
				x[9] = x[5]+axsc*yaxis; x[9]=x[5]+t*normalize(x[9]-x[5]);
				t*=1.5;
				axsc = t/0.47;
				x[10] = x[5] - scale*t*sdir;
				x[11] = x[10]+axsc*xaxis; x[11]=x[10]+t*normalize(x[11]-x[10]);
				x[12] = x[10]-axsc*xaxis; x[12]=x[10]+t*normalize(x[12]-x[10]);
				x[13] = x[10]-axsc*yaxis; x[13]=x[10]+t*normalize(x[13]-x[10]);
				x[14] = x[10]+axsc*yaxis; x[14]=x[10]+t*normalize(x[14]-x[10]);
				t*=1.5;
				axsc = t/0.47;
				x[15] = x[10] - scale*t*sdir;
				x[16] = x[15]+axsc*xaxis; x[16]=x[15]+t*normalize(x[16]-x[15]);
				x[17] = x[15]-axsc*xaxis; x[17]=x[15]+t*normalize(x[17]-x[15]);
				x[18] = x[15]-axsc*yaxis; x[18]=x[15]+t*normalize(x[18]-x[15]);
				x[19] = x[15]+axsc*yaxis; x[19]=x[15]+t*normalize(x[19]-x[15]);
				
				for (int i=0;i<steps;i++,t+=dataStep)
				{
					//float3 x = p - t*normal;
					float xpl = length(x[i]-p);
					float3 xpv = normalize(p-x[i]);
					float3 grad = ComputeGradient(x[i],dataStep,h2);
					float f = SampleData3(x[i]).x;
					if (f>fmin)
					{
						float gradl = length(grad);
						grad = grad/gradl;
						float aonow=sin(1.5*dot(xpv,normal))*compute_obscurance(xpv,xpl,grad,f);
						ao+=aonow;
						samplesCount++;
					} 
				}
				if (samplesCount>0)
					return clamp(ao/float(samplesCount),0,1);
				return 0;
		}
													
		StructuredBuffer<GlobalTriangle> triangles;
		//StructuredBuffer<GlobalVertex> triangles;
		//StructuredBuffer<float3> triangles;
		struct vs2gs
		{
			float4 pos : SV_POSITION;
			float4 nml	: FLOAT;
			float4 clr : COLOR;
			float3 posOrig : FLOAT1;
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
			float3 offset=float3(0.5,0.5,0.5);
			if (id==0) 
			{ 
				output.pos =  mul(UNITY_MATRIX_MVP,float4(gt.ptA,1.0));
				output.posOrig = gt.ptA+offset;
		    	output.nml =  mul(UNITY_MATRIX_MV,float4(gt.nmlA,0.0));
		    } else
		    if (id==1) 
			{ 
				output.pos =  mul(UNITY_MATRIX_MVP,float4(gt.ptB,1.0));
				output.posOrig = gt.ptB+offset;
		    	output.nml =  mul(UNITY_MATRIX_MV,float4(gt.nmlB,0.0));
		    } else
			{ 
				output.pos =  mul(UNITY_MATRIX_MVP,float4(gt.ptC,1.0));
				output.posOrig = gt.ptC+offset;
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
			float dataStepSize = _dataSize;
			float h2 = dataStepSize*2.0;
			float3 dataStep = float3(1.0/dataStepSize,1.0/dataStepSize,1.0/dataStepSize);
			float3 grad = ComputeGradient(input.posOrig,dataStep,h2);
			float ao = OcclusionFactor(input.posOrig, 20, normalize(grad), dataStep, h2);
			ao=1.0-ao;
			
			//return float4(d,d,d,1);
			return float4(ao,ao,ao,1);
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
