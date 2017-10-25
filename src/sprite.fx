
#include "vertex_utilities.hlsl"

struct Vs_input
{
   float4 position : POSITION;
   float4 texcoord : TEXCOORD;
   float4 color : COLOR;
};

struct Vs_output
{
   float4 position : POSITION;
   float2 texcoord : TEXCOORD;
   float4 color : COLOR;
};

struct Ps_input
{
   float2 texcoord : TEXCOORD;
   float4 color : COLOR;
};

sampler diffuse_map_sampler;

Vs_output sprite_vs(Vs_input input)
{
   Vs_output output;

   float4 world_position = pos_to_world(input.position);

   output.position = pos_project(world_position);
   output.texcoord = decompress_texcoords(input.texcoord);

   float4 material_color = get_material_color(input.color);
   Near_scene near_scene = calculate_near_scene_fade(world_position);

   output.color.xyz = material_color.xyz;
   output.color.w = near_scene.fade * material_color.w;

   return output;
}

float4 sprite_ps(Ps_input input) : COLOR
{
   return tex2D(diffuse_map_sampler, input.texcoord) * input.color;
}