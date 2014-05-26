Shader "Custom/MolShader" 
{
	Properties 
	{
	    _Color ("Color", Color) = (1,1,1,1)	    
        _SpriteSize("SpriteSize", Float) = 0.1
	}
	SubShader 
	{
	    Pass 
	    {
	    	Tags { "RenderType"="Opaque" }
	    	LOD 200
	    
			CGPROGRAM				
				#include "UnityCG.cginc"
				
				#pragma only_renderers d3d11
				#pragma target 5.0				
				
				#pragma vertex VS
				#pragma hull HS
				#pragma domain DS				
				#pragma geometry GS
				#pragma fragment FS
				
				// **************************************************************
				// IO Data structures												*
				// **************************************************************
								
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
				    float4 color : COLOR;
				    float size : PSIZE;
				}; 

				struct gs2fs
				{
					float4 pos : SV_POSITION;									
					float3 normal : NORMAL;			
					float2 tex0	: TEXCOORD0;
				};
				
				// **************************************************************
				// Global Vars													*
				// **************************************************************				
				
				float4 _Color;
				float _SpriteSize;	
//				int _AtomCount;		
				StructuredBuffer<float4> _AtomBuffer;
				
				// Vertex Program											
				vs2hs VS(appdata_base base)
				{
				    vs2hs output;
				    float4 _newPos = base.vertex; //mul(UNITY_MATRIX_MV,base.vertex);
				    output.pos = _newPos.xyz;
				    
				    return output;
				}
				
				// Hull shader Program
				hsConst HSConst()
				{
					hsConst output;
					
					output.tessFactor[0] = 64.0f;
					output.tessFactor[1] = 64.0f;
					
					return output;
				}

				[domain("isoline")]
				[partitioning("integer")]
				[outputtopology("point")]
				[outputcontrolpoints(1)]				
				[patchconstantfunc("HSConst")]
				hs2ds HS (InputPatch<vs2hs, 1> input, uint id : SV_OutputControlPointID)
				{
				    hs2ds output;
				    
				    output.pos = input[id].pos;
				    
				    return output;
				} 
				
				[domain("isoline")]
				ds2gs DS(hsConst input, const OutputPatch<hs2ds, 1> op, float2 uv : SV_DomainLocation)
				{
					ds2gs output;				
  					
					//output.pos = mul (UNITY_MATRIX_MVP, float4(op[0].pos, 1) + float4(uv.x * 100, uv.y * 100, 0, 0)); //float4(op[0].pos, 1);
					//output.color = float4(1-uv.x, 1-uv.y, 1-(uv.y * uv.x), 1);
					//output.size = 10.0f;
					//
					//return output;
					
					//get molecular position
					float3 pos = op[0].pos;

					// atom position in the texture
					int atomId = uv.x*64*64+uv.y*64;
					atomId = min(atomId,3000);
					float3 atomPos = pos + float4(0.1f*_AtomBuffer[atomId].xyz,1.0);// mul(UNITY_MATRIX_MV, float4(0.1f*_AtomBuffer[atomId].xyz,1.0));
					// Transform position with projection matrix
					output.pos = mul (UNITY_MATRIX_MV, float4(atomPos.xyz,1.0));		
					//output.pos = float4(atomPos.xyz,1.0);		
					return output;			
				}
				
//				float4 FS (ds2gs input) : COLOR
//				{
//					return input.color;
//				}
							
				// Geometry Program
				[maxvertexcount(4)]
				void GS(point ds2gs input[1], inout TriangleStream<gs2fs> pointStream)
				{
					gs2fs output;
					
					output.pos = input[0].pos + float4(  0.5,  0.5, 0, 0) * _SpriteSize;
					output.pos = mul (UNITY_MATRIX_P, output.pos);
					output.normal = float3(0.0f, 0.0f, -1.0f);
					output.tex0 = float2(1.0f, 1.0f);
					pointStream.Append(output);
					
					output.pos = input[0].pos + float4(  0.5, -0.5, 0, 0) * _SpriteSize;
					output.pos = mul (UNITY_MATRIX_P, output.pos);
					output.normal = float3(0.0f, 0.0f, -1.0f);
					output.tex0 = float2(1.0f, 0.0f);
					pointStream.Append(output);					
					
					output.pos = input[0].pos + float4( -0.5,  0.5, 0, 0) * _SpriteSize;
					output.pos = mul (UNITY_MATRIX_P, output.pos);
					output.normal = float3(0.0f, 0.0f, -1.0f);
					output.tex0 = float2(0.0f, 1.0f);
					pointStream.Append(output);
					
					output.pos = input[0].pos + float4( -0.5, -0.5, 0, 0) * _SpriteSize;
					output.pos = mul (UNITY_MATRIX_P, output.pos);
					output.normal = float3(0.0f, 0.0f, -1.0f);
					output.tex0 = float2(0.0f, 0.0f);
					pointStream.Append(output);					
				}
				
				// **************************************************************
				// Fragment Program												*
				// **************************************************************

				float4 FS (gs2fs input) : COLOR
				{
				
					// Center the texture coordinate
				    float3 normal = float3(input.tex0 * 2.0 - float2(1.0, 1.0), 0);

				    // Get the distance from the center
				    float mag = dot(normal, normal);

				    // If the distance is greater than 0 we discard the pixel
				    if (mag > 1) discard;
				
					// Find the z value according to the sphere equation
				    normal.z = sqrt(1.0-mag);
					normal = normalize(normal);
				
					// Lambert shading
					float3 light = float3(0, 0, 1);
					float ndotl = max( 0.0, dot(light, normal));	
				
					return _Color * ndotl;
				}
			
			ENDCG
		 }
	}
	Fallback Off
} 