Shader "Custom/TriangleShader" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader {
	Pass{
		
		Tags { "RenderType"="Opaque" }
		Cull Off Fog { Mode Off }
		LOD 200
		ZWrite On
		
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
		float3 aoGradParam;
		float3 aoFuncParam;
		int aoSamplesCount;
		
		float SampleData3( float3 p){
			return tex3Dlod(_dataFieldTex,float4(p.xyz,0)).x;	
		}

		float compute_obscurance(float3 normal, //surface normal
						  				 float dist,	//distance of the sample from the surface point
						  				 float3 gf, 	//gradient at the sample
						  				 float f)		//function value at the sample
		{
			float _obscurence =  exp(-5.0f*dist);
			//float _obscurence =  exp(-10.5f*dist);
			//float _obscurence =  1.0;
			float cosR = 1.0;
			float cosRD = dot(gf,normal);
			//cosR = 1.0f/(1.0f+exp(8.0f*cosRD-2.0f));
			cosR = 1.0f/(1.0f+exp(aoGradParam.y*cosRD-aoGradParam.z));
			//cosR=1.0;
			//_obscurence = (cosR*_obscurence)/(1.0f+exp(-8.0f*f-4.0));
			//_obscurence = (cosR*_obscurence)/(1.0f+exp(-8.0*f-1.0));
			_obscurence = aoFuncParam.x*(cosR*_obscurence)/(1.0f+exp(-aoFuncParam.y*f-aoFuncParam.z));
			return _obscurence;
			//return 1.0f;
		}
		
		float compute_obscurance_no_gradient(float dist,	//distance of the sample from the surface point
						  				     float f)		//function value at the sample
		{
			float _obscurence =  exp(-5.0f*dist);
			//_obscurence = (_obscurence)/(1.0f+exp(-8.0*f-1.0));
			_obscurence = aoFuncParam.x*(_obscurence)/(1.0f+exp(-aoFuncParam.y*f-aoFuncParam.z));
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


		void BuildSamples(float level)
		{
			
		}
		
//		void generate_samples_ao(float3 p, float3 normal, float3 dataStep,inout float3 x[50])
//		{
//			float t=aoGradParam.x*dataStep.x;
//			int i;
//			float3 xaxis = get_orthogonal_vec(normal);
//			float3 yaxis = normalize(cross(normal,xaxis));
//			float3 xaxisR = normalize(xaxis+yaxis);
//			float3 yaxisR = normalize(xaxis-yaxis);
//			float axsc = t/0.47;
//			float3 sdir=normal;	
//			for (i=0;i<aoSamplesCount;i++)
//			{
//					int j=10*i;
//					float fi=2.0f*(float)i+1.0f;
//					float fj=2.0f*(float)i+2.0f;
//					x[j+0] = p - fi*t*sdir;
//					x[j+1] = x[j]+fi*axsc*xaxisR;
//					x[j+2] = x[j]-fi*axsc*xaxisR;
//					x[j+3] = x[j]-fi*axsc*yaxisR;
//					x[j+4] = x[j]+fi*axsc*yaxisR;
//					x[j+5] = p - fj*t*sdir;
//					//x[j+5] = p - fi*t*sdir;
//					x[j+6] = x[j+5]+fj*axsc*xaxis;
//					x[j+7] = x[j+5]-fj*axsc*xaxis;
//					x[j+8] = x[j+5]-fj*axsc*yaxis;
//					x[j+9] = x[j+5]+fj*axsc*yaxis;
//
//			}
//		}
		
		float OcclusionFactor(float3 p, float3 normal, float3 dataStep, float h2)
		{
				float fmin=-0.5;
				//float t=4.0*dataStep.x;
				float t=aoGradParam.x*dataStep.x;
				float3 x[50];
				int i;
				//generate_samples_ao(p,normal,dataStep,x);
				float ao=0.0;
				int samplesCount=0;
				
				float3 xaxis = get_orthogonal_vec(normal);
				float3 yaxis = normalize(cross(normal,xaxis));
				float3 xaxisR = normalize(xaxis+yaxis);
				float3 yaxisR = normalize(xaxis-yaxis);
				float axsc = t/0.47;
				float3 sdir=normal;
				
				
				for (i=0;i<aoSamplesCount;i++)
				{
						int j=10*i;
						float fi=2.0f*(float)i+1.0f;
						float fj=2.0f*(float)i+2.0f;
						x[j+0] = p - fi*t*sdir;
						x[j+1] = x[j]+fi*axsc*xaxisR;
						x[j+2] = x[j]-fi*axsc*xaxisR;
						x[j+3] = x[j]-fi*axsc*yaxisR;
						x[j+4] = x[j]+fi*axsc*yaxisR;
						x[j+5] = p - fj*t*sdir;
						//x[j+5] = p - fi*t*sdir;
						x[j+6] = x[j+5]+fj*axsc*xaxis;
						x[j+7] = x[j+5]-fj*axsc*xaxis;
						x[j+8] = x[j+5]-fj*axsc*yaxis;
						x[j+9] = x[j+5]+fj*axsc*yaxis;

				}
				
				for (i=0;i<10*aoSamplesCount;i++)
				{
					//float3 x = p - t*normal;
					float xpl = length(x[i]-p);
					float f = SampleData3(x[i]).x-0.5;
					//if (f>fmin)
					{
						//float3 xpv = normalize(p-x[i]);
						float3 grad;
						float aonow;
						if (xpl<4.0*t)
						{
							grad = ComputeGradient(x[i],dataStep,h2);
							float gradl = length(grad);
							grad = grad/gradl;
							aonow=compute_obscurance(normal,xpl,grad,f);
						} else
						{
							aonow=compute_obscurance_no_gradient(xpl,f);
						}
						ao+=aonow;
						samplesCount++;
					}
					 
				}
				if (samplesCount>0) return clamp(ao/float(samplesCount),0,1);
				return 0;
		}
		
		float OcclusionFactorOneRay(float3 p, float3 normal, float3 dataStep, float h2)
		{
				float fmin=-0.5;
				//float t=4.0*dataStep.x;
				float t=aoGradParam.x*dataStep.x;
				float3 x[50];
				int i;
				//generate_samples_ao(p,normal,dataStep,x);
				float ao=0.0;
				int samplesCount=0;
				
				for (i=0;i<5*aoSamplesCount;i++)
				{
						x[i] = p - (float)i*t*normal;
				}
				
				for (i=0;i<5*aoSamplesCount;i++)
				{
					//float3 x = p - t*normal;
					float xpl = length(x[i]-p);
					float f = SampleData3(x[i]).x-0.5;
					//if (f>fmin)
					{
						//float3 xpv = normalize(p-x[i]);
						float3 grad;
						float aonow;
						if (xpl<10.0*t)
						{
							grad = ComputeGradient(x[i],dataStep,h2);
							float gradl = length(grad);
							grad = grad/gradl;
							aonow=compute_obscurance(normal,xpl,grad,f);
						} else
						{
							aonow=compute_obscurance_no_gradient(xpl,f);
						}
						ao+=aonow;
						samplesCount++;
					}
					 
				}
				if (samplesCount>0) return clamp(ao/float(samplesCount),0,1);
				//if (samplesCount>0) return clamp(ao,0,1);
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
		
		//[earlydepthstencil]
		//
		struct fs2out 
		{
		float4 oColor : COLOR;
   		float oDepth : DEPTH;
		};
		//fs2out FS (vs2gs input)
		float4 FS (vs2gs input) : COLOR
		{
		
			//! compute ao
			float dataStepSize = _dataSize;
			float h2 = dataStepSize*2.0;
			float3 dataStep = float3(1.0/dataStepSize,1.0/dataStepSize,1.0/dataStepSize);
			float3 grad = ComputeGradient(input.posOrig,dataStep,h2);
			float ao = OcclusionFactor(input.posOrig, normalize(grad), dataStep, h2);
			float3 lightDir = normalize(_WorldSpaceLightPos0.xyz-input.posOrig);
			float shadow=0.0;
			//if (dot(lightDir,grad)>0.0)
			shadow = OcclusionFactorOneRay(input.posOrig, lightDir, dataStep, h2);
			ao=(1.0-ao)*(1.0-shadow);		
						
			
			
			
			
			//float3 dir = normalize(input.pos - float3(0.5,0.5,0.5));
			//float pi = 3.14159265;
			//float u = (atan2(dir.z,dir.x)+pi)/(2.0 * pi); 
			//float v = 0.5 + 0.5* dot(float3(0,1,0),dir);

			//float d = abs(dot(normalize(_WorldSpaceLightPos0.xyz),-normal));
			float3 H = normalize(input.pos - _WorldSpaceCameraPos);
			float3 L = normalize(float3(1,1,1));
			float diffuse_light = max(dot(L,input.nml.xyz),0.0);
			
			float3 R = reflect(-L, -input.nml.xyz);
			float specular_light = pow( max(dot(R, -H), 0.0), 25 );
			float3 clr = float3(0.5,0.2,0.6);
			clr = diffuse_light * clr + ao*specular_light*float3(1.0,1.0,1.0)+ ao*clr;

			
			
			
			
			//return float4(clr.xzy,1);
			return float4(ao,ao,ao,1);
			//fs2out fout;
			//fout.oColor = float4(1.0,1.0,1.0,1);
			//fout.oDepth = input.pos.z/input.pos.w;
			
			//return float4(1.0,1.0,1.0,1);
			//return fout;
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
