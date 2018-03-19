#ifndef LIGHTING_UTILS_INCLUDED
#define LIGHTING_UTILS_INCLUDED

#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"

struct Lighting
{
   float4 diffuse;
   float4 static_diffuse;
};

namespace light
{

float3 ambient(float3 world_normal)
{
   float factor = world_normal.y * -0.5 + 0.5;

   float3 color;

   color.rgb = light_ambient_color_top.rgb * -factor + light_ambient_color_top.rgb;
   color.rgb = light_ambient_color_bottom.rgb * factor + color.rgb;

   return color;
}

namespace diffuse
{

float intensity_directional(float3 world_normal, float4 direction)
{
   float intensity = dot(world_normal.xyz, -direction.xyz);

   return max(intensity, 0.0);
}

float intensity_point(float3 world_normal, float4 world_position, float4 light_position)
{
   float3 light_dir = world_position.xyz + -light_position.xyz;

   const float dir_dot = dot(light_dir, light_dir);

   light_dir *= rsqrt(dir_dot);

   float3 intensity;

   const float inv_range_sq = light_position.w;

   intensity.x = 1.0;
   intensity.z = -dir_dot * inv_range_sq + intensity.x;
   intensity.y = dot(world_normal.xyz, -light_dir);
   intensity = max(intensity, 0.0);

   return intensity.y * intensity.z;
}

float intensity_spot(float3 world_normal, float4 world_position)
{
   const float3 light_dir = normalize(world_position.xyz - light_spot_pos.xyz);

   const float intensity = max(dot(world_normal, -light_dir), 0.0);

   const float inv_range_sq = light_spot_pos.w;
   const float light_dst = distance(world_position.xyz, light_spot_pos.xyz);

   const float attenuation = max(1.0 - (light_dst * light_dst) * inv_range_sq, 0.0);

   const float outer_cone = light_spot_params.x;

   const float theta = max(dot(light_dir, light_spot_dir.xyz), 0.0);
   const float cone_falloff = saturate((theta - outer_cone)  * light_spot_params.z);

   return intensity * attenuation * cone_falloff;
}

Lighting calculate(float3 normals, float4 world_position,
                   float4 static_diffuse_lighting)
{
   float3 world_normal = normals_to_world(normals);

   Lighting lighting;

   lighting.diffuse = 0.0;
   lighting.diffuse.rgb = ambient(world_normal) + static_diffuse_lighting.rgb;

#ifdef LIGHTING_DIRECTIONAL
   float4 intensity = float4(lighting.diffuse.rgb, 1.0);

   intensity.x = intensity_directional(world_normal, light_directional_0_dir);
   lighting.diffuse += intensity.x * light_directional_0_color;

   intensity.w = intensity_directional(world_normal, light_directional_1_dir);
   lighting.diffuse += intensity.w * light_directional_1_color;

#ifdef LIGHTING_POINT_0
   intensity.y = intensity_point(world_normal, world_position, light_point_0_pos);
   lighting.diffuse += intensity.y * light_point_0_color;
#endif

#ifdef LIGHTING_POINT_1
   intensity.w = intensity_point(world_normal, world_position, light_point_1_pos);
   lighting.diffuse += intensity.w * light_point_1_color;
#endif

#ifdef LIGHTING_POINT_23
   intensity.w = intensity_point(world_normal, world_position, light_point_2_pos);
   lighting.diffuse += intensity.w * light_point_2_color;

   intensity.w = intensity_point(world_normal, world_position, light_point_3_pos);
   lighting.diffuse += intensity.w * light_point_3_color;
#elif defined(LIGHTING_SPOT_0)
   intensity.z = intensity_spot(world_normal, world_position);
   lighting.diffuse += intensity.z * light_spot_color;
#endif

   lighting.static_diffuse = static_diffuse_lighting;
   lighting.static_diffuse.w = dot(light_proj_selector, intensity);
   lighting.diffuse.rgb += -light_proj_color.rgb * lighting.static_diffuse.w;

   float scale = max(lighting.diffuse.r, lighting.diffuse.g);
   scale = max(scale, lighting.diffuse.z);
   scale = max(scale, 1.0);
   scale = rcp(scale);
   lighting.diffuse.rgb *= scale;
   lighting.diffuse.rgb *= hdr_info.zzz;
#else // LIGHTING_DIRECTIONAL

   lighting.diffuse = hdr_info.zzzw;
   lighting.static_diffuse = 0.0;
#endif

   return lighting;
}

}
}

#endif