Shader "Custom/MolShader" 
{
	Properties
	{
		
	}
	
	SubShader 
	{
		// First pass
	    Pass 
	    {
	    	CGPROGRAM			
	    		
			#include "UnityCG.cginc"
			
			#pragma only_renderers d3d11
			#pragma target 5.0				
			
			#pragma vertex VS				
			#pragma fragment FS
			#pragma hull HS
			#pragma domain DS	
			
			float molScale;		
																			
			StructuredBuffer<float4> molPositions;
			StructuredBuffer<float4> atomPositions;
			
			struct vs2hs
			{
	            float3 pos : CPOINT;
        	};
        	
        	struct hsConst
			{
			    float tessFactor[2] : SV_TessFactor;
			};

			struct hs2ds
			{
			    float3 pos : CPOINT;
			};
			
			struct ds2gs
			{
			    float4 pos : SV_Position;
			    float4 atomInfo : FLOAT4;
			}; 
						
			struct gs2fs
			{
				float4 pos : SV_POSITION;									
				float3 normal : NORMAL;			
				float2 tex0	: TEXCOORD0;
			};
				
			vs2hs VS(uint id : SV_VertexID)
			{
			    vs2hs output;
			    
			    output.pos = molPositions[id].xyz;
			    
			    return output;
			}										
			
			hsConst HSConst(InputPatch<vs2hs, 1> input, uint patchID : SV_PrimitiveID)
			{
				hsConst output;					
				
				float4 transformPos = mul (UNITY_MATRIX_MVP, float4(input[0].pos, 1.0));
				transformPos /= transformPos.w;
				
				float tessFactor = sqrt(3523);		
											
				if( transformPos.x < -1 || transformPos.y < -1 || transformPos.x > 1 || transformPos.y > 1 || transformPos.z > 1 || transformPos.z < -1 ) 
				{
					output.tessFactor[0] = 0.0f;
					output.tessFactor[1] = 0.0f;
				}		
				else
				{
					output.tessFactor[0] = tessFactor;
					output.tessFactor[1] = tessFactor;					
				}		
				
				return output;
			}
			
			[domain("isoline")]
			[partitioning("integer")]
			[outputtopology("point")]
			[outputcontrolpoints(1)]				
			[patchconstantfunc("HSConst")]
			hs2ds HS (InputPatch<vs2hs, 1> input, uint ID : SV_OutputControlPointID)
			{
			    hs2ds output;
			    
			    output.pos = input[0].pos;
			    
			    return output;
			} 
			
			[domain("isoline")]
			ds2gs DS(hsConst input, const OutputPatch<hs2ds, 1> op, float2 uv : SV_DomainLocation)
			{
				ds2gs output;	

				int id = min(uv.x * input.tessFactor[0] + uv.y * input.tessFactor[0] * input.tessFactor[1], 3523);				
				output.atomInfo = float4(op[0].pos + atomPositions[id].xyz * molScale, atomPositions[id].w);
				output.pos = mul(UNITY_MATRIX_MVP, float4(output.atomInfo.xyz, 1));					
				return output;			
			}
			
			float4 FS (ds2gs input) : COLOR
			{				
				return input.atomInfo;
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
		
			sampler2D _InputTex;
			
			AppendStructuredBuffer<float4> pointBufferOutput : register(u1);

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
				float4 c = tex2D (_InputTex, i.uv);
				
				[branch]
				if (any(c > 0))
				{
					pointBufferOutput.Append (c);
				}
				
				discard;
				return c;
			}
			
			ENDCG
		}	
		
		// Third pass
		Pass
		{	
			CGPROGRAM	
					
			#include "UnityCG.cginc"			
			
			#pragma vertex VS			
			#pragma fragment FS							
			#pragma geometry GS	
													
			float molScale;	
			float4 spriteColor;																														
			StructuredBuffer<float4> atomPositions;
			
			struct vs2gs
			{
				float4 pos : SV_POSITION;
				float4 size : FLOAT;
			};
			
			struct gs2fs
			{
				float4 pos : SV_POSITION;	
			};

			vs2gs VS(uint id : SV_VertexID)
			{
			    float4 atomInfo = atomPositions[id];	
			    
			    vs2gs output;	
			    output.pos = mul (UNITY_MATRIX_MV, float4(atomInfo.xyz, 1));
			    output.size = atomInfo.w; 			    
			    return output;
			}
			
			[maxvertexcount(1)]
			void GS(point vs2gs input[1], inout PointStream<gs2fs> pointStream)
			{
				float spriteSize = molScale * input[0].size;
			
				float4 temp = mul (UNITY_MATRIX_P, float4(spriteSize, 0, input[0].pos.z, 1));  
			    float discardSize = (temp.x / temp.w) * _ScreenParams.x;
			
//				if(discardSize <= 1)	
				if(true)			
				{				 
				  	gs2fs output;				
					output.pos = mul (UNITY_MATRIX_P, input[0].pos);
					pointStream.Append(output);			
				}				
			}
			
			float4 FS (gs2fs input) : COLOR
			{					
				return spriteColor;
			}
			
			ENDCG					
		}	
		
		// Fourth pass
		Pass
		{		
			ZWrite On
			ZTest On
			//Blend Off
			//ZWrite Off
						
			CGPROGRAM	
					
			#include "UnityCG.cginc"
									
			#pragma vertex VS
			#pragma fragment FS				
			#pragma geometry GS	
									
			float molScale;	
			float4 spriteColor;																													
			StructuredBuffer<float4> atomPositions;
						
			struct vs2gs
			{
				float4 pos : SV_POSITION;
				float4 size : FLOAT;
			};
			
			struct gs2fs
			{
				float4 pos : SV_POSITION;		
				float2 mapping	: FLOAT2;
				float size : FLOAT;
			};
			
			struct fsOut
			{
				float4 color : COLOR;		
				float depth	: SV_DEPTH;
			};

			vs2gs VS(uint id : SV_VertexID)
			{			    	
			    float4 atomInfo = atomPositions[id];	
			    
			    vs2gs output;	
			    output.pos = mul (UNITY_MATRIX_MV, float4(atomInfo.xyz, 1));
			    output.size = atomInfo.w; 			    
			    return output;
			}
			
			[maxvertexcount(4)]
			void GS(point vs2gs input[1], inout TriangleStream<gs2fs> pointStream)
			{
				float spriteSize = molScale * input[0].size;
				
				float4 temp = mul (UNITY_MATRIX_P, float4(spriteSize, 0, input[0].pos.z, 1));  
			    float discardSize = (temp.x / temp.w) * _ScreenParams.x;
			
				if(discardSize > 1)	
//				if(true)
				{				 
				  	gs2fs output;				
					output.size = spriteSize;
				
					output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4(spriteSize, spriteSize, 0, 0));
					output.mapping = float2(1.0f, 1.0f);
					pointStream.Append(output);

					output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4(spriteSize, -spriteSize, 0, 0));
					output.mapping = float2(1.0f, -1.0f);
					pointStream.Append(output);					

					output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4(-spriteSize, spriteSize, 0, 0));
					output.mapping = float2(-1.0f, 1.0f);
					pointStream.Append(output);

					output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4(-spriteSize, -spriteSize, 0, 0));
					output.mapping = float2(-1.0f, -1.0f);
					pointStream.Append(output);				
				}				
			}
			
			void FS (gs2fs input, out float4 fragColor : COLOR, out float fragDepth : DEPTH) 
			{	
				float lensqr = dot(input.mapping, input.mapping);
    			
    			if(lensqr > 1.0)
        			discard;

			    float3 normal = float3(input.mapping, sqrt(1.0 - lensqr));				
				float3 light = float3(0, 0, 1);							
									
				float ndotl = max( 0.0, dot(light, normal));	
				float atom01Depth = LinearEyeDepth(input.pos.z);				
				float atomEyeDepth = LinearEyeDepth(input.pos.z);				
				float edgeFactor = clamp((ndotl- 0.4) * 50, 0, 1);
				
				fragColor = (atomEyeDepth < 10) ? spriteColor * edgeFactor : spriteColor;
				//fragColor = spriteColor * edgeFactor;								
				fragDepth = 1 / ((atomEyeDepth + input.size * -normal.z) * _ZBufferParams.z) - _ZBufferParams.w / _ZBufferParams.z;				
				fragColor.x=fragDepth;
			}			
			ENDCG	
		}	
		//fifth pass
		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _DepthTex;
			sampler2D _InputTex;
			
			
			const float IaoCap = 0.99;
			const float IaoMultiplier=10.0;
			const float IdepthTolerance=0.001;
			const float Iaorange = 1000.0;// units in space the AO effect extends to (this gets divided by the camera far range
			const float IaoScale = 0.5;

			float readDepth( in float2 coord ) {
				float depthValue = 0.5*(Linear01Depth(tex2D (_InputTex, coord).x)+1.0);
				return depthValue;
				
//				float n = 0.3; // camera z near
//				float f = 1000.0; // camera z far
//				float z = texture2D( texture0, coord ).x;
//				return (2.0 * n) / (f + n - z * (f - n));	
			}


			float compareDepths( in float depth1, in float depth2 ) {
			  float ao=0.0;
				//float diff = sqrt( clamp( 1.0-(depth1-depth2) / (Iaorange/(camerarange.y-camerarange.x) ),0.0,1.0) );
				if (depth2>0.0 && depth1>0.0) 
			  	{
					//float diff = sqrt( clamp( 1.0-(depth1-depth2),0.0,1.0) );
					float diff = sqrt( clamp( (depth1-depth2),0.0,1.0) );
					ao = min(IaoCap,max(0.0,depth1-depth2-IdepthTolerance) * IaoMultiplier) * min(diff,0.1);
				}
				return ao;
			}

//			//Fragment Shader
//			half4 frag (v2f i) : COLOR{
//			   //float depthValue = Linear01Depth (tex2Dproj(_DepthTex, UNITY_PROJ_COORD(i.scrPos)).r);
//			   float depthValue = Linear01Depth (tex2Dproj(_DepthTex, UNITY_PROJ_COORD(i.scrPos)).r);
//			   //float Linear01Depth (tex2Dproj(_DepthTex, UNITY_PROJ_COORD(i.scrPos)).r);
//			   half4 depth;
//
//			   depth.r = depthValue;
//			   depth.g = depthValue;
//			   depth.b = depthValue;
//
//			   depth.a = 1;
//			   return depth;
//			}
			
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
				//float depthValue = Linear01Depth(tex2D (_DepthTex, i.uv).r);
				//float depthValue = Linear01Depth(tex2D (_InputTex, i.uv).r);
				float4 clr = tex2D (_InputTex, i.uv);
				float2 texCoord = i.uv;
				if (clr.x==0) discard;
				float depth = readDepth(texCoord);
				return float4(depth,depth,depth,1.0);
				//if (depth==0) discard;
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
			    clr = float4(ao,ao,ao,1.0);
				return clr;
				//return float4(ao,ao,ao,1);
			}
			
			
			ENDCG
			}			
	}
	Fallback Off
}	