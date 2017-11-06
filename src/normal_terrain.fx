
#include "vertex_utilities.hlsl"
#include "lighting_utilities.hlsl"
#include "transform_utilities.hlsl"

float4 terrain_constant : register(vs, c[CUSTOM_CONST_MIN]);
float4 texture_coords[8] : register(vs, c[CUSTOM_CONST_MIN + 1]);

struct Vs_input
{
   float4 position : POSITION;
   float4 normal : NORMAL;
   float4 color : COLOR;
};

struct Vs_blendmap_output
{
   float4 position : POSITION;
   float2 texcoord_0 : TEXCOORD0;
   float2 texcoord_1 : TEXCOORD1;
   float2 texcoord_2 : TEXCOORD2;
   float2 texcoord_3 : TEXCOORD3;
   float4 color_0 : COLOR0;
   float4 color_1 : COLOR1;
   float1 fog : FOG;
};

Vs_blendmap_output diffuse_blendmap_vs(Vs_input input)
{
   Vs_blendmap_output output;

   float4 world_position = transform::position(input.position);

   output.position = position_project(world_position);

   output.texcoord_0.x = dot(world_position, texture_coords[0]);
   output.texcoord_0.y = dot(world_position, texture_coords[1]);

   output.texcoord_1.x = dot(world_position, texture_coords[2]);
   output.texcoord_1.y = dot(world_position, texture_coords[3]);

   output.texcoord_2.x = dot(world_position, texture_coords[4]);
   output.texcoord_2.y = dot(world_position, texture_coords[5]);

   output.texcoord_3.x = dot(world_position, texture_coords[6]);
   output.texcoord_3.y = dot(world_position, texture_coords[7]);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   output.color_0.b = input.normal.w;
   output.color_0.g = input.position.w * terrain_constant.w;
   output.color_0.r = constant_0.z;
   output.color_0.a = near_scene.fade * constant_1.y + constant_1.z;

   float3 normals = decompress_normals(input.normal.xyz);
   float4 static_diffuse_color = get_static_diffuse_color(input.color);

   Lighting lighting = light::diffuse::calculate(normals, world_position,
                                                 static_diffuse_color);

   output.color_0.r = lighting.diffuse.w;
   output.color_1.rgb = lighting.diffuse.rgb * terrain_constant.xxx + terrain_constant.yyy;
   output.color_1.a = get_material_color(input.color).a;

   return output;
}

struct Vs_detail_output
{
   float4 position : POSITION;
   float2 detail_texcoord_0 : TEXCOORD0;
   float2 detail_texcoord_1 : TEXCOORD1;
   float4 projection_texcoords : TEXCOORD2;
   float4 shadow_map_texcoords : TEXCOORD3;
   float4 color_0 : COLOR0;
   float3 color_1 : COLOR1;
   float1 fog : FOG;
};

Vs_detail_output detailing_vs(Vs_input input)
{
   Vs_detail_output output;

   float4 world_position = transform::position(input.position);

   output.position = position_project(world_position);

   output.detail_texcoord_0.x = dot(world_position, texture_coords[0]);
   output.detail_texcoord_0.y = dot(world_position, texture_coords[1]);

   output.detail_texcoord_1.x = dot(world_position, texture_coords[2]);
   output.detail_texcoord_1.y = dot(world_position, texture_coords[3]);

   output.projection_texcoords = mul(world_position, light_proj_matrix);

   output.shadow_map_texcoords = transform_shadowmap_coords(world_position); 

   float3 normals = decompress_normals(input.normal.xyz);
   float4 static_diffuse_color = get_static_diffuse_color(input.color);

   Lighting lighting = light::diffuse::calculate(normals,
                                                 world_position,
                                                 static_diffuse_color);

   float4 material_color = get_material_color(input.color);

   output.color_1 = material_color.rgb * lighting.static_diffuse.a;
   output.color_1 *= light_proj_selector.rgb;

   output.color_0.rgb = lighting.diffuse.rgb * terrain_constant.xxx + terrain_constant.yyy;
   output.color_0.w = lighting.diffuse.w;
   output.color_0.rgb = lighting.diffuse.rgb;

   Near_scene near_scene = calculate_near_scene_fade(world_position);

   output.fog = calculate_fog(near_scene, world_position);
   output.color_0.a = near_scene.fade * constant_1.y + constant_1.z;

   return output;
}

struct Ps_blendmap_input
{
   float2 texcoord_0 : TEXCOORD0;
   float2 texcoord_1 : TEXCOORD1;
   float2 texcoord_2 : TEXCOORD2;
   float2 texcoord_3 : TEXCOORD3;
   float4 color_mask : COLOR0;
   float4 light_color : COLOR1;
};

float4 diffuse_blendmap_ps(Ps_blendmap_input input, uniform sampler diffuse_maps[3],
                           uniform sampler blend_or_detail_map) : COLOR
{
   float4 diffuse_color_0 = tex2D(diffuse_maps[0], input.texcoord_0);
   float4 diffuse_color_1 = tex2D(diffuse_maps[1], input.texcoord_1);
   float4 diffuse_color_2 = tex2D(diffuse_maps[2], input.texcoord_2);
   float4 blendmap_color = tex2D(blend_or_detail_map, input.texcoord_3);

   float blend_factor_t2 = dot(input.color_mask.rgb, float3(0, 1, 0));
   blend_factor_t2 = clamp(blend_factor_t2, 0.0, 1.0);

   float4 color;

   color.rgb = diffuse_color_2.rgb * blend_factor_t2;

   float blend_factor_t1 = input.color_mask.b;

   color.rgb += diffuse_color_1.rgb * blend_factor_t1;

   float blend_factor_t0 = (1 - blend_factor_t2) + -blend_factor_t1;

   color.rgb += diffuse_color_0.rgb * blend_factor_t0;

   color.rgb *= input.light_color.rgb;

   color.rgb *= blendmap_color.rgb;
   color.rgb *= 2.0;

   color.a = (input.color_mask.a - 0.5) * 4.0;

   return color;
}

struct Ps_detail_input
{
   float2 detail_texcoord_0 : TEXCOORD0;
   float2 detail_texcoord_1 : TEXCOORD1;
   float4 projection_texcoords : TEXCOORD2;
   float4 shadow_map_texcoords : TEXCOORD3;
   float4 lighting_color : COLOR0;
   float4 proj_lighting : COLOR1;
};

float4 detailing_ps(Ps_detail_input input, uniform sampler detail_maps[2],
                    uniform sampler projection_map, uniform sampler shadow_map) : COLOR
{

   float4 detail_color_0 = tex2D(detail_maps[0], input.detail_texcoord_0);
   float4 detail_color_1 = tex2D(detail_maps[1], input.detail_texcoord_1);
   float4 projection_color = tex2Dproj(projection_map, input.projection_texcoords);
   float4 shadow_map_color = tex2Dproj(shadow_map, input.shadow_map_texcoords);

   float3 color = projection_color.rgb * input.lighting_color.rgb;
   float factor = lerp(0.8, shadow_map_color.a, 0.8);

   color = (color * factor) + input.proj_lighting.rgb;

   float detail_factor = input.lighting_color.a * (1 - shadow_map_color.a);
   detail_factor = clamp(detail_factor, 0.0, 1.0);

   float3 blended_detail = ((1 - detail_factor) * detail_color_0.rgb) * 2.0;
   blended_detail *= detail_color_1.rgb;
   blended_detail *= 2.0;

   color *= blended_detail;

   return float4(color, 1.0);
}