
#include "vertex_utilities.hlsl"

float4 shadowquad_vs(float4 position : POSITION) : POSITION
{
   position = decompress_position(position);
    
   return float4(position.xy, constant_0.yz);

}

float4 shadowquad_ps() : COLOR
{
   return constant_0;
}