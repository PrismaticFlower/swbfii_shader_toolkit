
#include "vertex_utilities.hlsl"
#include "transform_utilities.hlsl"

// Deprecated Foliage shader, likely as a layover from the first game.
// This implementation was written before I knew that. It is likely useless
// and pointless.

struct Vs_input
{
   float4 position : POSITION;
   float4 texcoord : TEXCOORD;
   float4 color : COLOR;
};

struct Vs_output
{
   float4 position : POSITION;
   float2 diffuse_coords : TEXCOORD0;
   float4 shadowmap_coords : TEXCOORD1;
   float1 fog : FOG;
   float4 color : COLOR;
};

sampler diffuse_map_sampler;
sampler shadowmap_sampler;

float4 foliage_shadow_consant : register(ps, c[1]);

Vs_output opaque_vs(Vs_input input)
{
   Vs_output output;

   float4 world_position = transform::position(input.position);

   output.position = position_project(world_position);
   output.diffuse_coords = decompress_texcoords(input.texcoord);
   output.shadowmap_coords = transform_shadowmap_coords(world_position);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   float4 material_color = get_material_color(input.color);

   output.color.xyz = material_color.xyz * hdr_info.zzz;
   output.color.w = near_scene.fade * constant_1.y + constant_1.z;

   return output;
}

Vs_output transparent_vs(Vs_input input)
{
   Vs_output output;

   float4 world_position = transform::position(input.position);

   output.position = position_project(world_position);
   output.diffuse_coords = decompress_texcoords(input.texcoord);
   output.shadowmap_coords = transform_shadowmap_coords(world_position);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   near_scene = clamp_near_scene_fade(near_scene);
   near_scene.fade * near_scene.fade;

   float4 material_color = get_material_color(input.color);

   output.color.xyz = material_color.xyz * hdr_info.zzz;
   output.color.w = near_scene.fade * material_color.w;

   return output;
}

struct Ps_hardedged_input
{
   float2 texcoord : TEXCOORD;
   float4 color : COLOR;
};

float4 hardedged_ps(Ps_hardedged_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map_sampler, input.texcoord);

   float4 color;
 
   color.rgb = diffuse_color.rgb * input.color.rgb;
   color.a = (diffuse_color.a - 0.5) + 0.75;

   if (color.a > 0.5) color.a = (input.color.a - 0.5);
   else color.a = 0.75;

   color.a *= 4.0;

   return color;
}

float4 transparent_hardedged_ps(Ps_hardedged_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map_sampler, input.texcoord);

   float alpha_value = diffuse_color.a * input.color.a;

   float4 color;

   color.rgb = diffuse_color.rgb * input.color.rgb;
   color.a = (diffuse_color.a - 0.5) + 0.75;

   if (color.a > 0.5) color.a = alpha_value;
   else color.a = -0.01;

   return color;
}

struct Ps_shadow_input
{
   float2 diffuse_texcoord : TEXCOORD0;
   float4 shadowmap_texcoord : TEXCOORD1;
   float4 color : COLOR;
};

float4 shadow_hardedged_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map_sampler, input.diffuse_texcoord);
   float shadow_value = tex2Dproj(shadowmap_sampler, input.shadowmap_texcoord).a;

   float4 color;

   color.rgb = (1.0 - shadow_value) * foliage_shadow_consant.rgb;
   color.rgb *= input.color.rgb;
   color.rgb *= diffuse_color.rgb;

   color.a = (diffuse_color.a - 0.5) + 0.75;

   if (color.a > 0.5) color.a = (input.color.a - 0.5);
   else color.a = 0.75;

   color.a *= 4.0;

   return color;
}

float4 shadow_transparent_hardedged_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map_sampler, input.diffuse_texcoord);
   float shadow_value = tex2Dproj(shadowmap_sampler, input.shadowmap_texcoord).a;

   float4 color;

   color.rgb = (1.0 - shadow_value) * foliage_shadow_consant.rgb;
   color.rgb *= input.color.rgb;
   color.rgb *= diffuse_color.rgb;
   color.a = (diffuse_color.a - 0.5) + 0.75;

   if (color.a > 0.5) color.a = diffuse_color.a * input.color.a;
   else color.a = -0.01;

   return color;
}