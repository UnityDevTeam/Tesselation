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
		struct fsOutput
	    {
	        float4 col0 : COLOR0;
        	float4 col1 : COLOR1;
	    };
	    
		//float4 FS (vs2gs input) : COLOR
		fsOutput FS (vs2gs input) : COLOR
		{
		
	
						
			
			
			
			
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
			clr = diffuse_light * clr + specular_light*float3(1.0,1.0,1.0)+ clr;

			
			float2 cf = float2(0,0);//EncodeViewNormalStereo (grad);
			float2 cs = EncodeViewNormalStereo (input.nml.xyz);
			//return float4(cf.x,cf.y,cs.x,cs.y);
			
			fsOutput fso;
			fso.col0 = float4(input.posOrig.xyz,input.pos.z/input.pos.w);
			//fso.col1 = float4(cf.x,cf.y,cs.x,cs.y);
			fso.col1 = float4(clr.x,clr.y,clr.y,1.0);
			return fso;
			//return float4(clr.xzy,1);
			//return float4(ao,ao,ao,1);
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
			ZWrite Off ZTest Always Cull Off Fog { Mode Off }

			CGPROGRAM
			
			#include "UnityCG.cginc"
				
			#pragma only_renderers d3d11		
			#pragma target 5.0
			
			#pragma vertex vert
			#pragma fragment frag
		
			#define _dataSize 256.0
			sampler2D _MainTex;
			sampler2D col0;
			sampler2D col1; 
			
					sampler3D _dataFieldTex;
		float3 aoGradParam;
		float3 aoFuncParam;
		int aoSamplesCount;
		float3 aoShadowParam;
		
		float SampleData3( float3 p){
			return tex3Dlod(_dataFieldTex,float4(p.xyz,0)).x;	
		}

		float compute_obscurance(float3 normal, //surface normal
						  				 float dist,	//distance of the sample from the surface point
						  				 float3 gf, 	//gradient at the sample
						  				 float f)		//function value at the sample
		{
//			float _obscurence =  exp(-5.0f*dist);
//			float cosR = 1.0;
//			float cosRD = dot(gf,normal);
//			cosR = 1.0f/(1.0f+exp(aoGradParam.y*cosRD-aoGradParam.z));
//			_obscurence = aoFuncParam.x*(cosR*_obscurence)/(1.0f+exp(-aoFuncParam.y*f-aoFuncParam.z));
			
			float _obscurence =  exp(-10.0f*dist);
			//_obscurence = (_obscurence)/(1.0f+exp(-8.0*f-1.0));
			//_obscurence = aoFuncParam.x*(_obscurence)/(1.0f+exp(-aoFuncParam.y*f-aoFuncParam.z));
			//_obscurence = aoFuncParam.x/(1.0f+exp(-aoFuncParam.y*f-_obscurence-aoFuncParam.z));
			float cosR = 1.0;
			float cosRD = dot(gf,normal);
			cosR = 1.0f/(1.0f+exp(aoGradParam.y*cosRD-aoGradParam.z));
			_obscurence = clamp(cosR*aoFuncParam.x*(aoFuncParam.y*f-_obscurence),0,1);
			return _obscurence;
		}
		
		float compute_obscurance_no_gradient(float dist,	//distance of the sample from the surface point
						  				     float f)		//function value at the sample
		{
			float _obscurence =  exp(-10.0f*dist);
			//_obscurence = (_obscurence)/(1.0f+exp(-8.0*f-1.0));
			//_obscurence = aoFuncParam.x*(_obscurence)/(1.0f+exp(-aoFuncParam.y*f-aoFuncParam.z));
			//_obscurence = aoFuncParam.x/(1.0f+exp(-aoFuncParam.y*f-_obscurence-aoFuncParam.z));
			_obscurence = clamp(aoFuncParam.x*(aoFuncParam.y*f-_obscurence),0,1);
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
				
				
//				for (i=0;i<aoSamplesCount;i++)
//				{
//						int j=10*i;
//						float fi=2.0f*(float)i+1.0f;
//						float fj=2.0f*(float)i+2.0f;
//						x[j+0] = p - fi*t*sdir;
//						x[j+1] = x[j]+fi*axsc*xaxisR;
//						x[j+2] = x[j]-fi*axsc*xaxisR;
//						x[j+3] = x[j]-fi*axsc*yaxisR;
//						x[j+4] = x[j]+fi*axsc*yaxisR;
//						x[j+5] = p - fj*t*sdir;
//						//x[j+5] = p - fi*t*sdir;
//						x[j+6] = x[j+5]+fj*axsc*xaxis;
//						x[j+7] = x[j+5]-fj*axsc*xaxis;
//						x[j+8] = x[j+5]-fj*axsc*yaxis;
//						x[j+9] = x[j+5]+fj*axsc*yaxis;
//						t*=1.5;
//						
//
//				}
				
				for (i=0;i<aoSamplesCount;i++)
				{
						int j=10*i;
						float fi=10.0f*(float)i+1.0f;
						x[j+0] = p - fi*t*sdir;
						x[j+1] = x[j+0] - t*sdir;
						x[j+2] = x[j+1] - t*sdir;
						x[j+3] = x[j+2] - t*sdir;
						x[j+4] = x[j+3] - t*sdir;
						x[j+5] = x[j+4] - t*sdir;
						x[j+6] = x[j+5] - t*sdir;
						x[j+7] = x[j+6] - t*sdir;
						x[j+8] = x[j+7] - t*sdir;
						x[j+9] = x[j+8] - t*sdir;
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
						if (xpl<aoShadowParam.y*t)
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

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.texcoord;
				return o;
			}			

			float4 frag (v2f i) : COLOR0
			{
				//float4 c = tex2D (_MainTex, i.uv);
				float4 a = tex2D (col0, i.uv);
				float4 b = tex2D (col1, i.uv);
				
				if (b.w<1)
					discard;
				//! compute ao
				float dataStepSize = _dataSize;
				float h2 = dataStepSize*2.0;
				float3 dataStep = float3(1.0/dataStepSize,1.0/dataStepSize,1.0/dataStepSize);
				float3 grad = ComputeGradient(a.xyz,dataStep,h2);
				float ao = OcclusionFactor(a.xyz, normalize(grad), dataStep, h2);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz-a.xyz);
				float shadow=0.0;
				//if (dot(lightDir,grad)>0.0)
				shadow = OcclusionFactorOneRay(a.xyz, lightDir, dataStep, h2);
				ao=(1.0-ao);
				ao*=(1.0-aoShadowParam.x*shadow);	
				
				
//				float3 gradVoxel = DecodeViewNormalStereo (float4(b.x,b.y,0,0));
//				float3 nmlVertex = DecodeViewNormalStereo (float4(b.z,b.w,0,0));
//				float3 
//				
//				float3 H = normalize(pos - _WorldSpaceCameraPos);
//				float3 L = normalize(float3(1,1,1));
//				float diffuse_light = max(dot(L,nml),0.0);
//			
//				float3 R = reflect(-L, -nml);
//				float specular_light = pow( max(dot(R, -H), 0.0), 25 );
//				float3 clr = float3(0.5,0.2,0.6);
//				clr = diffuse_light * clr + specular_light*float3(1.0,1.0,1.0)+ clr;
				
				//return float4(clr.x,clr.y,clr.z,1.0);
				return float4(ao,ao,ao,1.0);
			}
			
			ENDCG
		}
		//third pass
		Pass
		{
			ZTest On
			ZWrite On
			
			CGPROGRAM
			
			#pragma vertex vert_img
            #pragma fragment frag
            
			#include "UnityCG.cginc"

			sampler2D _InputTex;
			sampler2D _DepthTex;
			
			sampler2D _MainTex;
			sampler2D col0;
			sampler2D col1;			
			
			static float IaoCap = 0.99f;
			static float IaoMultiplier=100.0f;
			static float IdepthTolerance=0.001;
			static float Iaorange = 1000.0;// units in space the AO effect extends to (this gets divided by the camera far range
			static float IaoScale = 0.5;

			float readDepth( in float2 coord ) 
			{
				//float depthValue = Linear01Depth(tex2D (_InputTex, coord).w);
				//float depthValue = tex2D (_InputTex, coord).w/10.0;
				float depthValue = DECODE_EYEDEPTH(tex2D (col0, coord).w)/1.0;
				return depthValue;
				
//				float n = 0.3; // camera z near
//				float f = 1000.0; // camera z far
//				float z = texture2D( texture0, coord ).x;
//				return (2.0 * n) / (f + n - z * (f - n));	
			}


			float compareDepths( in float depth2, in float depth1 )
			{
			  	float ao=0.0;
				//float diff = sqrt( clamp( 1.0-(depth1-depth2) / (Iaorange/(camerarange.y-camerarange.x) ),0.0,1.0) );
				if (depth2>0.0 && depth1>0.0) 
			  	{
					//float diff = sqrt( clamp( 1.0-(depth1-depth2),0.0,1.0) );
					float diff = sqrt( clamp( (depth1-depth2),0.0,1.0) );
					//if (diff<0.2)
					ao = min(IaoCap,max(0.0,depth1-depth2-IdepthTolerance) * IaoMultiplier) * min(diff,0.1);
					//ao = min(IaoCap, 0.0) * 0.1;
					//ao=0.0;
				}
				return ao;
			}					

			float4 frag (v2f_img i) : COLOR0
			{
				//float depthValue = Linear01Depth(tex2D (_DepthTex, i.uv).r);
				//float depthValue = Linear01Depth(tex2D (_InputTex, i.uv).r);
				
				//return tex2D(_DepthTex, i.uv);
				
				//float4 clr = tex2D (_InputTex, i.uv);
				float4 b = tex2D (col1, i.uv);
				if (b.w<1)
					discard;
				float2 texCoord = i.uv;
				
				//if (clr.w==0.0) return float4(1,1,1,0);
				float depth = readDepth(texCoord);
				
//				return float4(depth,depth,depth,1.0);
//				if (depth==0) discard;
				
				float d;
				float pw = 5.0 / _ScreenParams.x;
				float ph = 5.0 / _ScreenParams.y;

				float aoCap = IaoCap;

				float ao = 0.0;
				
				//float aoMultiplier=10000.0;
				float aoMultiplier= IaoMultiplier;
				float depthTolerance = IdepthTolerance;
				float aoscale= IaoScale;

				d=readDepth( float2(texCoord.x+pw,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x+pw,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;
			    
			    
				d=readDepth( float2(texCoord.x+pw,texCoord.y));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;    
				
				pw*=2.0;
				ph*=2.0;
				aoMultiplier/=2.0;
				aoscale*=1.2;
				
				d=readDepth( float2(texCoord.x+pw,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x+pw,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;
			    
				d=readDepth( float2(texCoord.x+pw,texCoord.y));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;    
			    

				pw*=2.0;
				ph*=2.0;
				aoMultiplier/=2.0;
				aoscale*=1.2;
				
				d=readDepth( float2(texCoord.x+pw,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x+pw,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;
				
			  	d=readDepth( float2(texCoord.x+pw,texCoord.y));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale; 
			    
				pw*=2.0;
				ph*=2.0;
				aoMultiplier/=2.0;
				aoscale*=1.2;
				
				d=readDepth( float2(texCoord.x+pw,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x+pw,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;
			    
			    d=readDepth( float2(texCoord.x+pw,texCoord.y));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x-pw,texCoord.y));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x,texCoord.y+ph));
				ao+=compareDepths(depth,d)/aoscale;
				d=readDepth( float2(texCoord.x,texCoord.y-ph));
				ao+=compareDepths(depth,d)/aoscale;

				// ao/=4.0;
			    ao/=8.0;
			    ao = 1.0-ao;
			    //ao = 1.5*ao;

			    ao = clamp( ao, 0.0, 1.0 );
			    //return ao*float4(1.0,1.0,1.0,1.0);
				return float4(ao,ao,ao,1);
			}
			
			
			ENDCG
		}	

	
}
}
