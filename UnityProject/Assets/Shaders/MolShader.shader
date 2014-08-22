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
			//ZWrite On
			ZWrite Off
						
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
				
//				fragColor = (atomEyeDepth < 10) ? spriteColor * edgeFactor : spriteColor;
				fragColor = spriteColor * edgeFactor;								
				fragDepth = 1 / ((atomEyeDepth + input.size * -normal.z) * _ZBufferParams.z) - _ZBufferParams.w / _ZBufferParams.z;				
			}			
			ENDCG	
		}	
		//fifth pass
		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _CameraDepthTexture;

			struct v2f {
			   float4 pos : SV_POSITION;
			   float4 scrPos:TEXCOORD1;
			};

			//Vertex Shader
			v2f vert (appdata_base v){
			   v2f o;
			   o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			   o.scrPos=ComputeScreenPos(o.pos);
			   //for some reason, the y position of the depth texture comes out inverted
			   o.scrPos.y = 1 - o.scrPos.y;
			   return o;
			}

			//Fragment Shader
			half4 frag (v2f i) : COLOR{
			   float depthValue = Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).r);
			   half4 depth;

			   depth.r = depthValue;
			   depth.g = depthValue;
			   depth.b = depthValue;

			   depth.a = 1;
			   return depth;
			}
			ENDCG
			}			
	}
	Fallback Off
}	