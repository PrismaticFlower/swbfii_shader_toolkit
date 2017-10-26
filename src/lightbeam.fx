#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"

struct Vs_input
{
   float4 position : POSITION;
   float4 color : COLOR;
};

struct Vs_output
{
   float4 position : POSITION;
   float4 color : COLOR;
   float fog : FOG;
};

Vs_output lightbeam_vs(Vs_input input)
{
   Vs_output output;

   float4 world_position = decompress_pos_to_world(input.position);

   Near_scene near_scene = calculate_near_scene_fade(world_position);

   output.position = pos_project(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   float4 material_color = get_material_color(input.color);

   output.color.xyz = material_color.xyz * hdr_info.zzz;
   output.color.w = material_color.w * near_scene.fade;

   return output;
}

float4 lightbeam_ps(float4 color : COLOR) : COLOR
{
   return color;
}