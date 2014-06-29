#define MAX_24BIT_UINT  ( (1<<24) - 1 )
#define MAX_OVERDRAW 2


struct GlobalData
{
	uint colour;
	uint depth;
	uint previousNode;
};

//RWByteAddressBuffer _GlobalCounter : register(u3);
RWBuffer<uint> _GlobalCounter : register(u3);
RWByteAddressBuffer _HeadBuffer : register(u2);
//RWTexture2D<uint> _HeadBuffer : register(u2);
RWStructuredBuffer<GlobalData> _GlobalData : register(u1);


//--------------------------------------------------------------------------------------
// Helper functions
//--------------------------------------------------------------------------------------
uint PackFloat4IntoUint(float4 vValue)
{
    return ( ((uint)(vValue.x*255)) << 24 ) | ( ((uint)(vValue.y*255)) << 16 ) | ( ((uint)(vValue.z*255)) << 8) | (uint)(vValue.w * 255);
}

float4 UnpackUintIntoFloat4(uint uValue)
{
    return float4( ( (uValue & 0xFF000000)>>24 ) / 255.0, ( (uValue & 0x00FF0000)>>16 ) / 255.0, ( (uValue & 0x0000FF00)>>8 ) / 255.0, ( (uValue & 0x000000FF) ) / 255.0);
}

// Pack depth into 24 MSBs
uint PackDepthIntoUint(float fDepth)
{
    return ((uint)(fDepth * MAX_24BIT_UINT)) << 8;
}

// Pack depth into 24 MSBs and coverage into 8 LSBs
uint PackDepthAndCoverageIntoUint(float fDepth, uint uCoverage)
{
    return (((uint)(fDepth * MAX_24BIT_UINT)) << 8) | uCoverage;
}

uint UnpackDepthIntoUint(uint uDepthAndCoverage)
{
    return (uint)(uDepthAndCoverage >> 8);
}

uint UnpackCoverageIntoUint(uint uDepthAndCoverage)
{
    return (uDepthAndCoverage & 0xff );
}

uint PackNormalIntoUint(float3 n)
{
    uint3 i3 = (uint3) (n * 127.0f + 127.0f);
    return i3.r + (i3.g << 8) + (i3.b << 16);
}

float3 UnpackNormalIntoFloat3(uint n)
{
    float3 n3 = float3(n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff);
    return (n3 - 127.0f) / 127.0f;
}

uint PackNormalAndCoverageIntoUint(float3 n, uint uCoverage)
{
    uint3 i3 = (uint3) (n * 127.0f + 127.0f);
    return i3.r + (i3.g << 8) + (i3.b << 16) + (uCoverage << 24);
}


//--------------------------------------------------------------------------------------
// OIT Methods
//--------------------------------------------------------------------------------------
void WriteOIT(float4 colour, float depth, float2 location)
{
	GlobalData Data;

	uint2 pixelCoordinates = uint2(location * _ScreenParams.xy);

	// This crashes unity.
	//uint previousNode = _GlobalData.IncrementCounter();
	
	uint previousNode;
	//_GlobalCounter.InterlockedAdd(0,1,previousNode);
	InterlockedAdd(_GlobalCounter[0],1,previousNode);
	
    if (previousNode<100000) 
    {
				uint linearAddress = 4 * (pixelCoordinates.y * _ScreenParams.x + pixelCoordinates.x);
				uint prevNode;
				_HeadBuffer.InterlockedExchange(linearAddress, previousNode, prevNode);
				//InterlockedExchange(_HeadBuffer[pixelCoordinates],previousNode, Data.previousNode);

				Data.colour = PackFloat4IntoUint(colour);
				Data.depth = PackDepthIntoUint(depth);
				Data.previousNode = prevNode;
				_GlobalData[previousNode] = Data;
	} 
	
}