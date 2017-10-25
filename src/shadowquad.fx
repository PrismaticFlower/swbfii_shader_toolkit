
#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"

struct Vs_output
{
   float4 position : POSITION;
};

struct Ps_output
{
   float4 color : COLOR;
};

Vs_output shadowquad_vs(float4 position : POSITION)
{
   position = decompress_position(position, position_decompress);
   Vs_output output;
    
   output.position = float4(position.xy, constant_0.yz);

   return output;
}

Ps_output shadowquad_ps()
{
   Ps_output output;
   output.color = constant_0;

   return output;    
}