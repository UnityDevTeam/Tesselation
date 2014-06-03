Shader "Custom/MolShader" 
{
	Properties
	{
		
	}
	SubShader 
	{
		Pass
		{
			ZWrite Off ZTest Always Cull Off Fog { Mode Off }

			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			#include "UnityCG.cginc"
		
			sampler2D _MainTex;
			sampler2D _ColorTex;
			sampler2D _DepthTex;
			
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
				float4 c = tex2D (_ColorTex, i.uv);
				float d = tex2D (_DepthTex, i.uv).x;
				
				[branch]
				if (d < 1)
				{
					pointBufferOutput.Append (float4(i.uv, d, 1));
				}
				
				discard;
				return c;
			}
			
			ENDCG
		}

		Pass
		{	
			CGPROGRAM	
					
			#include "UnityCG.cginc"
			
			#pragma only_renderers d3d11
			#pragma target 5.0				
			
			#pragma vertex VS			
			#pragma fragment FS	
													
			StructuredBuffer<float4> molPositions;
			
			struct vs2fs
			{
				float4 pos : SV_POSITION;
			};

			vs2fs VS(uint id : SV_VertexID)
			{
			    vs2fs output;				    			    
			    output.pos = mul(UNITY_MATRIX_MVP, molPositions[id]);				    
			    return output;
			}
			
			float4 FS (vs2fs input) : COLOR
			{				
				return float4(1,1,1,1);
			}
			
			ENDCG					
		}
		
		Pass
		{		
			CGPROGRAM	
					
			#include "UnityCG.cginc"
			
			#pragma only_renderers d3d11
			#pragma target 5.0				
			
			#pragma vertex VS
			#pragma fragment FS				
			#pragma geometry GS	
													
			StructuredBuffer<float4> atomPositions;
			
			struct vs2gs
			{
				float4 pos : SV_POSITION;
			};
			
			struct gs2fs
			{
				float4 pos : SV_POSITION;		
				float2 tex0	: TEXCOORD0;
			};
			
			struct fsOutput
			{
				float4 color : COLOR0;		
				float depth	: DEPTH;
			};

			vs2gs VS(uint id : SV_VertexID)
			{			    	
			    float4 atomInfo = atomPositions[id];		    
			    float3 screenPos = atomInfo.xyz * 2.0 - 1.0;		
			    
			   	// Need to go back in MV space to find the right point sprite size	    
//			    float4 viewPos = mul (UNITY_MATRIX_P, float4(screenPos, 1.0));			    
			    
			    vs2gs output;			    				    			    				    
			    output.pos = float4(screenPos, 1);			    
			    return output;
			}
			
			[maxvertexcount(4)]
			void GS(point vs2gs input[1], inout TriangleStream<gs2fs> pointStream)
			{
				gs2fs output;
				
				float dx = 0.005;
				float dy = dx * _ScreenParams.x / _ScreenParams.y;
				
				output.pos = input[0].pos + float4( dx, dy, 0, 0);				
				output.tex0 = float2(1.0f, 1.0f);
				pointStream.Append(output);
				
				output.pos = input[0].pos + float4( dx, -dy, 0, 0);
				output.tex0 = float2(1.0f, 0.0f);
				pointStream.Append(output);					
				
				output.pos = input[0].pos + float4( -dx, dy, 0, 0);
				output.tex0 = float2(0.0f, 1.0f);
				pointStream.Append(output);
				
				output.pos = input[0].pos + float4( -dx, -dy, 0, 0);
				output.tex0 = float2(0.0f, 0.0f);
				pointStream.Append(output);					
			}
			
			float4 FS (gs2fs input) : COLOR
			{	
				float4 spriteColor = float4(1,1,1,1);
									
				// Center the texture coordinate
			    float3 normal = float3(input.tex0 * 2.0 - float2(1.0, 1.0), 0);

			    // Get the distance from the center
			    float mag = sqrt(dot(normal, normal));

			    // If the distance is greater than 0 we discard the pixel
			    if ((mag) > 1) discard;
			
				// Find the z value according to the sphere equation
			    normal.z = sqrt(1.0-mag);
				normal = normalize(normal);
			
				// Lambert shading
				float3 light = float3(0, 0, 1);
				float ndotl = max( 0.0, dot(light, normal));	
			
				return spriteColor * ndotl;
			}	
			
			ENDCG					
		}
	}
	Fallback Off
}

	
//		// Tesselation Pass
//	    Pass 
//	    {
//	    	CGPROGRAM			
//	    		
//				#include "UnityCG.cginc"
//				
//				#pragma only_renderers d3d11
//				#pragma target 5.0				
//				
//				#pragma vertex VS				
//				#pragma fragment FS
//				#pragma hull HS
//				#pragma domain DS				
////				#pragma geometry GS
//				
//				float molScale;			
//				float spriteSize;	
//				float4 spriteColor;
//																				
//				StructuredBuffer<float4> molPositions;
//				StructuredBuffer<float4> atomPositions;
//				
//				// vs2hs
//				struct vs2hs
//				{
//		            float3 pos : CPOINT;
//	        	};
//	        	
//	        	// hsConst 
//				struct hsConst
//				{
//				    float tessFactor[2] : SV_TessFactor;
//				};
//
//				// hs2ds
//				struct hs2ds
//				{
//				    float3 pos : CPOINT;
//				};
//				
//				// ds2gs
//				struct ds2gs
//				{
//				    float4 pos : SV_Position;
//				}; 
//							
//				// gs2fs
//				struct gs2fs
//				{
//					float4 pos : SV_POSITION;									
//					float3 normal : NORMAL;			
//					float2 tex0	: TEXCOORD0;
//				};
//					
//				// Vertex Program																					
//				vs2hs VS(uint id : SV_VertexID)
//				{
//				    vs2hs output;
//				    
//				    output.pos = molPositions[id].xyz;
//				    
//				    return output;
//				}										
//				
//				// Hull Constant Function
//				hsConst HSConst(InputPatch<vs2hs, 1> input, uint patchID : SV_PrimitiveID)
//				{
//					hsConst output;					
//					
//					float4 transformPos = mul (UNITY_MATRIX_MVP, float4(input[0].pos, 1.0));
//					transformPos /= transformPos.w;
//					
//					float tessFactor = sqrt(3523) -1;		
//												
//					if( transformPos.x < -1 || transformPos.y < -1 || transformPos.x > 1 || transformPos.y > 1 || transformPos.z > 1 || transformPos.z < -1 ) 
//					{
//						output.tessFactor[0] = 0.0f;
//						output.tessFactor[1] = 0.0f;
//					}		
//					else
//					{
//						output.tessFactor[0] = tessFactor;
//						output.tessFactor[1] = tessFactor;					
//					}		
//					
//					return output;
//				}
//				
//				// Hull Program
//				[domain("isoline")]
//				[partitioning("integer")]
//				[outputtopology("point")]
//				[outputcontrolpoints(1)]				
//				[patchconstantfunc("HSConst")]
//				hs2ds HS (InputPatch<vs2hs, 1> input, uint ID : SV_OutputControlPointID)
//				{
//				    hs2ds output;
//				    
//				    output.pos = input[0].pos;
//				    
//				    return output;
//				} 
//				
//				// Domain Program
//				[domain("isoline")]
//				ds2gs DS(hsConst input, const OutputPatch<hs2ds, 1> op, float2 uv : SV_DomainLocation)
//				{
//					ds2gs output;	
//
//					int id = min(uv.x * input.tessFactor[0] + uv.y * input.tessFactor[0] * input.tessFactor[1], 3523);
//					
//					output.pos = mul(UNITY_MATRIX_MVP, float4(op[0].pos + atomPositions[id].xyz * molScale, 1));
//					
//					// Transform position with projection matrix
////					output.pos = mul (UNITY_MATRIX_MV, float4(atomPos.xyz, 1.0));		
//					
//					return output;			
//				}
//				
//				float4 FS (ds2gs input) : COLOR
//				{				
//					return input.pos;
//				}
//				
////				// Geometry Program
////				[maxvertexcount(4)]
////				void GS(point ds2gs input[1], inout TriangleStream<gs2fs> pointStream)
////				{
////					gs2fs output;
////					
////					output.pos = input[0].pos + float4(  0.5,  0.5, 0, 0) * spriteSize;
////					output.pos = mul (UNITY_MATRIX_P, output.pos);
////					output.normal = float3(0.0f, 0.0f, -1.0f);
////					output.tex0 = float2(1.0f, 1.0f);
////					pointStream.Append(output);
////					
////					output.pos = input[0].pos + float4(  0.5, -0.5, 0, 0) * spriteSize;
////					output.pos = mul (UNITY_MATRIX_P, output.pos);
////					output.normal = float3(0.0f, 0.0f, -1.0f);
////					output.tex0 = float2(1.0f, 0.0f);
////					pointStream.Append(output);					
////					
////					output.pos = input[0].pos + float4( -0.5,  0.5, 0, 0) * spriteSize;
////					output.pos = mul (UNITY_MATRIX_P, output.pos);
////					output.normal = float3(0.0f, 0.0f, -1.0f);
////					output.tex0 = float2(0.0f, 1.0f);
////					pointStream.Append(output);
////					
////					output.pos = input[0].pos + float4( -0.5, -0.5, 0, 0) * spriteSize;
////					output.pos = mul (UNITY_MATRIX_P, output.pos);
////					output.normal = float3(0.0f, 0.0f, -1.0f);
////					output.tex0 = float2(0.0f, 0.0f);
////					pointStream.Append(output);					
////				}
////				
////				// Fragment Program
////				float4 FS (gs2fs input) : COLOR
////				{				
////					// Center the texture coordinate
////				    float3 normal = float3(input.tex0 * 2.0 - float2(1.0, 1.0), 0);
////
////				    // Get the distance from the center
////				    float mag = sqrt(dot(normal, normal));
////
////				    // If the distance is greater than 0 we discard the pixel
////				    if ((mag) > 1) discard;
////				
////					// Find the z value according to the sphere equation
////				    normal.z = sqrt(1.0-mag);
////					normal = normalize(normal);
////				
////					// Lambert shading
////					float3 light = float3(0, 0, 1);
////					float ndotl = max( 0.0, dot(light, normal));	
////				
////					return spriteColor * ndotl;
////				}			
//			ENDCG
//		}		