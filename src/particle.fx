
#include "vertex_utilities.hlsl"

float4 particle_constants[6] : register(vs, c[CUSTOM_CONST_MIN]);

sampler diffuse_map;
sampler refraction_buffer;

struct Vs_normal_input
{
   float4 position : POSITION;
   float4 color : COLOR;
   float4 texcoords : TEXCOORD0;
};

struct Vs_normal_output
{
   float4 position : POSITION;
   float4 color : COLOR;
   float fog : FOG;
   float2 texcoords : TEXCOORD;
};

Vs_normal_output normal_vs(Vs_normal_input input)
{
   Vs_normal_output output;

   float4 position = transform_unskinned_project(input.position);

   output.position = position;

   float fade_factor;

   fade_factor = position.w * particle_constants[0].x + particle_constants[0].y;
   fade_factor = max(fade_factor, constant_0.x);
   fade_factor = max(fade_factor, constant_0.z);

   float4 world_position = pos_to_world(input.position);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   near_scene = clamp_near_scene_fade(near_scene);
   near_scene.fade = near_scene.fade * near_scene.fade;

   output.color.rgb = get_material_color(input.color).rgb * hdr_info.zzz;

   fade_factor *= near_scene.fade;

   output.color.a = fade_factor * get_material_color(input.color).a;

   float2 texcoords = decompress_texcoords(input.texcoords);
   output.texcoords = texcoords * particle_constants[1].xy + particle_constants[1].zw;

   return output;
}

struct Vs_blur_input
{
   float4 position : POSITION;
   float4 color : COLOR;
   float4 texcoords : TEXCOORD0;
   float3 normal : NORMAL;
};

struct Vs_blur_output
{
   float4 position : POSITION;
   float4 color : COLOR;
   float  fog : FOG;
   float2 alphamap_texcoords : TEXCOORD0;
   float4 refract_texcoords : TEXCOORD1;
};

Vs_blur_output blur_vs(Vs_blur_input input)
{
   Vs_blur_output output;

   float4 position = transform_unskinned_project(input.position);

   output.position = position;

   float fade_factor;

   fade_factor = position.w * particle_constants[0].x + particle_constants[0].y;
   fade_factor = max(fade_factor, constant_0.x);
   fade_factor = max(fade_factor, constant_0.z);

   float4 world_position = pos_to_world(input.position);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   near_scene = clamp_near_scene_fade(near_scene);

   output.color.rgb = get_material_color(input.color).rgb;

   fade_factor *= near_scene.fade;

   output.color.a = fade_factor * get_material_color(input.color).a;

   float2 texcoords = decompress_texcoords(input.texcoords);
   output.alphamap_texcoords = texcoords * particle_constants[1].xy + particle_constants[1].zw;

   float3 normal = decompress_normals(input.normal);

   float4 coords = normal.xyzz * constant_0.zzzx + constant_0.xxxz;
   
   output.refract_texcoords.x = dot(coords, particle_constants[2]);
   output.refract_texcoords.y = dot(coords, particle_constants[3]);
   output.refract_texcoords.z = dot(coords, particle_constants[4]);
   output.refract_texcoords.w = dot(coords, particle_constants[5]);

   return output;
}

struct Ps_normal_input
{
   float4 color : COLOR;
   float2 texcoords : TEXCOORD;
};

float4 normal_ps(Ps_normal_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.texcoords);

   return diffuse_color * input.color;
}

struct Ps_blur_input
{
   float4 color : COLOR;
   float2 alphamap_texcoords : TEXCOORD0;
   float4 refract_texcoords : TEXCOORD1;
};

float4 blur_ps(Ps_blur_input input) : COLOR
{
   float alpha = tex2D(diffuse_map, input.alphamap_texcoords).a;
   float4 refraction_color = tex2Dproj(refraction_buffer, input.refract_texcoords);
   
   float4 color;

   color.rgb = refraction_color.rgb * input.color.rgb;
   color.a = alpha * input.color.a;

   return color;
}