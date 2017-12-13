
#include "vertex_utilities.hlsl"
#include "transform_utilities.hlsl"

struct Vs_input
{
   float4 position : POSITION;
   float3 normals : NORMAL;
   float4 texcoords : TEXCOORD0;
};

struct Vs_output
{
   float4 position : POSITION;
   float fog : FOG;

   float4 color : COLOR0;
   float3 specular_color : COLOR1;

   float2 diffuse_coords : TEXCOORD0;
   float4 specular_coords : TEXCOORD1;
};

float4 shield_constants[4] : register(vs, c[CUSTOM_CONST_MIN]);

sampler diffuse_map;
sampler specular_spot;

Vs_output shield_vs(Vs_input input)
{
   Vs_output output;

   float3 world_normal = normals_to_world(decompress_normals(input.normals));
   float4 world_position = transform::position(input.position);

   float4 eye_to_vertex[2];
   eye_to_vertex[1].w = 1.0;

   // calculate the reflected eye-to-vertex vector
   eye_to_vertex[1].xyz = world_position.xyz + -world_view_position.xyz;
   eye_to_vertex[0].w = dot(-eye_to_vertex[1].xyz, world_normal.xyz);
   eye_to_vertex[0].xyz = eye_to_vertex[0].w * world_normal.xyz + eye_to_vertex[1].xyz;
   eye_to_vertex[0].xyz = eye_to_vertex[0].w * world_normal.xyz + eye_to_vertex[0].xyz;

   // calculate the view angle alpha factor
   float value = dot(eye_to_vertex[1], eye_to_vertex[1]);
   value = max(value, shield_constants[3].w);
   
   float angle_alpha_factor = rcp(value);
   value = dot(eye_to_vertex[0], eye_to_vertex[1]);
   angle_alpha_factor *= value;
   angle_alpha_factor = angle_alpha_factor * -0.5 + 0.5;
   angle_alpha_factor *= shield_constants[3].z;
   angle_alpha_factor = -angle_alpha_factor * material_diffuse_color.w + material_diffuse_color.w;

   // calculate specular spot map projected coordinates
   float3 specular_coords;
   specular_coords.x = dot(eye_to_vertex[0].xyz, shield_constants[1].xyz);
   specular_coords.y = dot(eye_to_vertex[0].xyz, shield_constants[2].xyz);
   specular_coords.z = dot(eye_to_vertex[0].xyz, light_directional_0_dir.xyz);

   output.specular_coords = specular_coords.xyzz + specular_coords.zzzz;

   // calculate specular color
   float eye_dot_normal = dot(world_normal.xyz, -light_directional_0_dir.xyz);
   eye_dot_normal = (eye_dot_normal >= 0.0) ? 1.0f : 0.0f;
   eye_dot_normal *= ((eye_to_vertex[0].w >= 0.0) ? 1.0f : 0.0f);

   float3 specular_color = eye_dot_normal * shield_constants[0].xyz;

   output.position = transform::position_project(input.position);

   float2 texcoords = decompress_texcoords(input.texcoords);

   output.diffuse_coords = texcoords + shield_constants[3].xy;

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   near_scene = clamp_near_scene_fade(near_scene);
   near_scene.fade = near_scene.fade * angle_alpha_factor;

   specular_color *= near_scene.fade;
   output.specular_color = specular_color * hdr_info.zzz;

   output.color.rgb = material_diffuse_color.rgb * hdr_info.zzz;
   output.color.a = material_diffuse_color.a * near_scene.fade;

   return output;
}

struct Ps_input
{
   float4 color : COLOR0;
   float3 specular_color : COLOR1;

   float2 diffuse_coords : TEXCOORD0;
   float2 specular_coords : TEXCOORD1;
};

float4 shield_ps(Ps_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_coords);
   float3 specular_color = tex2D(specular_spot, input.specular_coords).rgb;

   specular_color *= input.specular_color;

   float alpha_value = diffuse_color.a + 0.49;

   if (alpha_value <= 0.5) specular_color = float3(0.0, 0.0, 0.0);

   float4 color = diffuse_color * input.color;

   color.rgb = color.rgb * color.a + specular_color;
   color.a = diffuse_color.a;

   return color;
}