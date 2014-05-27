Shader "Custom/MolShader" 
{
	Properties 
	{
		molScale("Molecule Scale", Float) = 0.1
		spriteSize("Sprite Size", Float) = 0.25
	    spriteColor ("Sprite Color", Color) = (1,1,1,1)        
	}
	SubShader 
	{
		// Debug Pass		
		Pass
		{	
			CGPROGRAM			
	    		
				#include "UnityCG.cginc"
				
				#pragma only_renderers d3d11
				#pragma target 5.0				
				
				#pragma vertex VS			
				#pragma fragment FS	
					
				float molScale;	
														
				StructuredBuffer<float4> molPositions;
				StructuredBuffer<float4> atomPositions;
				
				struct vs2fs
				{
					float4 pos : SV_POSITION;
				};

				vs2fs VS(uint id : SV_VertexID, uint instance : SV_InstanceID)
				{
				    vs2fs output;				    
				    
				    output.pos = mul(UNITY_MATRIX_MVP, float4(molPositions[instance].xyz + atomPositions[id].xyz * molScale, 1));
				    
				    return output;
				}
				
				float4 FS (vs2fs input) : COLOR
				{				
					return float4(1,1,1,1);
				}
			ENDCG					
		}
	
		// Tesselation Pass
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
//				#pragma geometry GS
				
				float molScale;			
				float spriteSize;	
				float4 spriteColor;
																				
				StructuredBuffer<float4> molPositions;
				StructuredBuffer<float4> atomPositions;
				
				// vs2hs
				struct vs2hs
				{
		            float3 pos : CPOINT;
	        	};
	        	
	        	// hsConst 
				struct hsConst
				{
				    float tessFactor[2] : SV_TessFactor;
				};

				// hs2ds
				struct hs2ds
				{
				    float3 pos : CPOINT;
				};
				
				// ds2gs
				struct ds2gs
				{
				    float4 pos : SV_Position;
				}; 
							
				// gs2fs
				struct gs2fs
				{
					float4 pos : SV_POSITION;									
					float3 normal : NORMAL;			
					float2 tex0	: TEXCOORD0;
				};
					
				// Vertex Program																					
				vs2hs VS(uint id : SV_VertexID)
				{
				    vs2hs output;
				    
				    output.pos = molPositions[id].xyz;
				    
				    return output;
				}										
				
				// Hull Constant Function
				hsConst HSConst(InputPatch<vs2hs, 1> input, uint patchID : SV_PrimitiveID)
				{
					hsConst output;					
					
					float4 transformPos = mul (UNITY_MATRIX_MVP, float4(input[0].pos, 1.0));
					transformPos /= transformPos.w;
					
					float tessFactor = sqrt(3523) -1;		
												
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
				
				// Hull Program
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
				
				// Domain Program
				[domain("isoline")]
				ds2gs DS(hsConst input, const OutputPatch<hs2ds, 1> op, float2 uv : SV_DomainLocation)
				{
					ds2gs output;	

					int id = min(uv.x * input.tessFactor[0] + uv.y * input.tessFactor[0] * input.tessFactor[1], 3523);
					
					output.pos = mul(UNITY_MATRIX_MVP, float4(op[0].pos + atomPositions[id].xyz * molScale, 1));
					
					// Transform position with projection matrix
//					output.pos = mul (UNITY_MATRIX_MV, float4(atomPos.xyz, 1.0));		
					
					return output;			
				}
				
				float4 FS (ds2gs input) : COLOR
				{				
					return float4(1,1,1,1);
				}
				
//				// Geometry Program
//				[maxvertexcount(4)]
//				void GS(point ds2gs input[1], inout TriangleStream<gs2fs> pointStream)
//				{
//					gs2fs output;
//					
//					output.pos = input[0].pos + float4(  0.5,  0.5, 0, 0) * spriteSize;
//					output.pos = mul (UNITY_MATRIX_P, output.pos);
//					output.normal = float3(0.0f, 0.0f, -1.0f);
//					output.tex0 = float2(1.0f, 1.0f);
//					pointStream.Append(output);
//					
//					output.pos = input[0].pos + float4(  0.5, -0.5, 0, 0) * spriteSize;
//					output.pos = mul (UNITY_MATRIX_P, output.pos);
//					output.normal = float3(0.0f, 0.0f, -1.0f);
//					output.tex0 = float2(1.0f, 0.0f);
//					pointStream.Append(output);					
//					
//					output.pos = input[0].pos + float4( -0.5,  0.5, 0, 0) * spriteSize;
//					output.pos = mul (UNITY_MATRIX_P, output.pos);
//					output.normal = float3(0.0f, 0.0f, -1.0f);
//					output.tex0 = float2(0.0f, 1.0f);
//					pointStream.Append(output);
//					
//					output.pos = input[0].pos + float4( -0.5, -0.5, 0, 0) * spriteSize;
//					output.pos = mul (UNITY_MATRIX_P, output.pos);
//					output.normal = float3(0.0f, 0.0f, -1.0f);
//					output.tex0 = float2(0.0f, 0.0f);
//					pointStream.Append(output);					
//				}
//				
//				// Fragment Program
//				float4 FS (gs2fs input) : COLOR
//				{				
//					// Center the texture coordinate
//				    float3 normal = float3(input.tex0 * 2.0 - float2(1.0, 1.0), 0);
//
//				    // Get the distance from the center
//				    float mag = sqrt(dot(normal, normal));
//
//				    // If the distance is greater than 0 we discard the pixel
//				    if ((mag) > 1) discard;
//				
//					// Find the z value according to the sphere equation
//				    normal.z = sqrt(1.0-mag);
//					normal = normalize(normal);
//				
//					// Lambert shading
//					float3 light = float3(0, 0, 1);
//					float ndotl = max( 0.0, dot(light, normal));	
//				
//					return spriteColor * ndotl;
//				}			
			ENDCG
		 }
		 // Debug Pass
		Pass
		{
			CGPROGRAM			
			
				#include "UnityCG.cginc"
				
				#pragma only_renderers d3d11
				#pragma target 5.0				
				
				#pragma vertex VS				
				#pragma geometry GS			
				#pragma fragment FS	
							
				float molScale;			
				float spriteSize;	
				float4 spriteColor;
								
				StructuredBuffer<float4> molPositions;
				StructuredBuffer<float4> atomPositions;
				
				struct vs2gs
				{
					float4 pos : SV_POSITION;
				};
				
				struct gs2fs
				{
					float4 pos : SV_POSITION;									
					float3 normal : NORMAL;			
					float2 tex0	: TEXCOORD0;
				};

				vs2gs VS(uint id : SV_VertexID, uint instance : SV_InstanceID)
				{
				    vs2gs output;
				    
				    output.pos = mul(UNITY_MATRIX_MV, molPositions[instance] + atomPositions[id] * molScale);
				    
				    return output;
				}
				
				// Geometry Program
				[maxvertexcount(4)]
				void GS(point vs2gs input[1], inout TriangleStream<gs2fs> pointStream)
				{
					gs2fs output;
					
					output.pos = input[0].pos + float4(  0.5,  0.5, 0, 0) * spriteSize;
					output.pos = mul (UNITY_MATRIX_P, output.pos);
					output.normal = float3(0.0f, 0.0f, -1.0f);
					output.tex0 = float2(1.0f, 1.0f);
					pointStream.Append(output);
					
					output.pos = input[0].pos + float4(  0.5, -0.5, 0, 0) * spriteSize;
					output.pos = mul (UNITY_MATRIX_P, output.pos);
					output.normal = float3(0.0f, 0.0f, -1.0f);
					output.tex0 = float2(1.0f, 0.0f);
					pointStream.Append(output);					
					
					output.pos = input[0].pos + float4( -0.5,  0.5, 0, 0) * spriteSize;
					output.pos = mul (UNITY_MATRIX_P, output.pos);
					output.normal = float3(0.0f, 0.0f, -1.0f);
					output.tex0 = float2(0.0f, 1.0f);
					pointStream.Append(output);
					
					output.pos = input[0].pos + float4( -0.5, -0.5, 0, 0) * spriteSize;
					output.pos = mul (UNITY_MATRIX_P, output.pos);
					output.normal = float3(0.0f, 0.0f, -1.0f);
					output.tex0 = float2(0.0f, 0.0f);
					pointStream.Append(output);					
				}
				
				// Fragment Program
				float4 FS (gs2fs input) : COLOR
				{				
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