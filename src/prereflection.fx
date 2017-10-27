
#include "vertex_utilities.hlsl"

float4 prereflection_vs(float4 position : POSITION) : POSITION
{
   return decompress_pos_to_world_project(position);
}

float4 prereflection_fake_stencil_vs(float4 position : POSITION) : POSITION
{
   position = decompress_pos_to_world_project(position);

   return position.xyww;
}

float4 prereflection_ps() : COLOR
{
   return float4(0.0, 0.0, 0.0, 0.0);
}