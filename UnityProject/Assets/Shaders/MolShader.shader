Shader "Custom/MolShader" 
{
	Properties
	{
		_MainTex ("", 2D) = "white" {}
	}
	SubShader 
	{
		Pass
		{
			ZWrite Off ZTest Always Cull Off Fog { Mode Off }

			CGPROGRAM
			
			#include "UnityCG.cginc"
				
			#pragma only_renderers d3d11		
			#pragma target 5.0
			
			#pragma vertex vert
			#pragma fragment frag
		
			sampler2D _MainTex;
			
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
				float4 c = tex2D (_MainTex, i.uv);
				
				[branch]
				if (c.w > 0)
				{
					pointBufferOutput.Append (c);
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
				float4 worldPos : FLOAT4;
			};

			vs2fs VS(uint id : SV_VertexID)
			{
			    vs2fs output;		
			    output.worldPos = float4(molPositions[id].xyz, 1);	    			    
			    output.pos = mul(UNITY_MATRIX_MVP, molPositions[id]);				    
			    return output;
			}
			
			float4 FS (vs2fs input) : COLOR
			{					
				return input.worldPos;
			}
			
			ENDCG					
		}
		
		
		
		Pass
		{		
			CGPROGRAM
			#pragma only_renderers d3d11
			#pragma target 5.0		
					
			#include "UnityCG.cginc"		
			
			#pragma vertex VS
			#pragma fragment FS				
			#pragma geometry GS	
									
			float4x4 projectionMatrixInverse;														
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
			    
			    vs2gs output;			    				    			    				    
			    output.pos = mul (UNITY_MATRIX_MV, atomInfo);		    
			    return output;
			}
			
			[maxvertexcount(4)]
			void GS(point vs2gs input[1], inout TriangleStream<gs2fs> pointStream)
			{
				gs2fs output;
				
				float dx = 0.05;
				float dy = 0.05;
								
				output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4( dx, dy, 0, 0));
				output.tex0 = float2(1.0f, 1.0f);
				pointStream.Append(output);
				
				output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4( dx, -dy, 0, 0));
				output.tex0 = float2(1.0f, 0.0f);
				pointStream.Append(output);					
				
				output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4( -dx, dy, 0, 0));
				output.tex0 = float2(0.0f, 1.0f);
				pointStream.Append(output);
				
				output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4( -dx, -dy, 0, 0));
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
		//testing the blending shader
		Pass
		{	
		
			ZWrite Off ZTest Always Cull Off Fog { Mode Off }
			Blend One One
			CGPROGRAM
			#pragma only_renderers d3d11
			#pragma target 5.0		
					
			#include "UnityCG.cginc"		
			
			#pragma vertex VS
			#pragma fragment FS				
			#pragma geometry GS	
									
			float4x4 projectionMatrixInverse;														
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
		        float4 slab0 : COLOR0;
		        float4 slab1 : COLOR1;
		        float4 slab2 : COLOR2;
		        float4 slab3 : COLOR3;
		    };


			vs2gs VS(uint id : SV_VertexID)
			{			    	
			    float4 atomInfo = atomPositions[id];	
			    
			    vs2gs output;			    				    			    				    
			    output.pos = mul (UNITY_MATRIX_MV, atomInfo);		    
			    return output;
			}
			
			[maxvertexcount(4)]
			void GS(point vs2gs input[1], inout TriangleStream<gs2fs> pointStream)
			{
				gs2fs output;
				
				float dx = 0.1;
				float dy = 0.1;
								
				output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4( dx, dy, 0, 0));
				output.tex0 = float2(1.0f, 1.0f);
				pointStream.Append(output);
				
				output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4( dx, -dy, 0, 0));
				output.tex0 = float2(1.0f, 0.0f);
				pointStream.Append(output);					
				
				output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4( -dx, dy, 0, 0));
				output.tex0 = float2(0.0f, 1.0f);
				pointStream.Append(output);
				
				output.pos = mul (UNITY_MATRIX_P, input[0].pos + float4( -dx, -dy, 0, 0));
				output.tex0 = float2(0.0f, 0.0f);
				pointStream.Append(output);					
			}
			
			//fsOutput FS (gs2fs input) : COLOR
			fsOutput FS (gs2fs input) : COLOR
			{	
				
				fsOutput o;
				// Center the texture coordinate
			    float3 normal = float3(input.tex0 * 2.0 - float2(1.0, 1.0), 0);
			    
			    // Get the distance from the center
			    float mag = dot(normal.xy, normal.xy);
			    
			    float slabValues[16];
			    
			    // If the distance is greater than 0 we discard the pixel
			    if (mag > 1) discard;
			    //mag = exp(-mag);
			    
			    float atom_depth = input.pos.z;// / 100.0f;
			    
			    float delta = 0.06666666666667;
			    //float delta = 6.666666666667;
			    float running_depth = 0.0;
			    
			    for (int i=0;i<16;i++,running_depth+=delta)
			    {
			    	float dist2 = (running_depth - atom_depth);
			    	//dist2*=dist2;
			    	dist2 = 100.0*(dist2 + (1.0-mag));
			    	slabValues[i] = mag*exp(-dist2);
			    }
			    
			    o.slab0 = float4(slabValues[0], slabValues[1], slabValues[2], slabValues[3]);
			    o.slab1 = float4(slabValues[4], slabValues[5], slabValues[6], slabValues[7]);
			    o.slab2 = float4(slabValues[8], slabValues[9], slabValues[10],slabValues[11]);
			    o.slab3 = float4(slabValues[12],slabValues[13],slabValues[14],slabValues[15]);
			    
			    
				return o;
			}	
			
			ENDCG					
		}
		
		//iso-surfacing
		Pass
		{
			//ZWrite Off ZTest Always Cull Off Fog { Mode Off }

			CGPROGRAM
			
			#include "UnityCG.cginc"
				
			#pragma only_renderers d3d11		
			#pragma target 5.0
			
			#pragma vertex vert
			#pragma fragment frag
		
			sampler2D slab0;
			sampler2D slab1;
			sampler2D slab2;
			sampler2D slab3;
			

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
			//float4 frag (v2f i,out float depth:DEPTH) : COLOR0
			
			{
				float4 c0 = tex2D (slab0, i.uv);
				float4 c1 = tex2D (slab1, i.uv);
				float4 c2 = tex2D (slab2, i.uv);
				float4 c3 = tex2D (slab3, i.uv);
				float delta = 0.06666666666667;
				float clr=0.2;
				float4 final_clr = float4(0,0,0,1);
				
//				if (c0.x > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				if (c0.y > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				if (c0.z > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				if (c0.w > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				
//				if (c1.x > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				if (c1.y > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				if (c1.z > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				if (c1.w > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				
//				if (c2.x > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				if (c2.y > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				if (c2.z > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				if (c2.w > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
//				clr+=delta;
//				
				if (c3.x > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
				clr+=delta;
				if (c3.y > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
				clr+=delta;
				if (c3.z > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
				clr+=delta;
				if (c3.w > 0.5) { final_clr = float4(clr,clr,clr,1); return final_clr;}
				clr+=delta;
				return final_clr;
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