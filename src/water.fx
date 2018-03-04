
#include "constants_list.hlsl"
#include "ext_constants_list.hlsl"
#include "vertex_utilities.hlsl"
#include "transform_utilities.hlsl"

float4 texcoords_projection : register(vs, c[CUSTOM_CONST_MIN]);
float4 fade_constant : register(vs, c[CUSTOM_CONST_MIN + 1]);
float4 light_direction : register(vs, c[CUSTOM_CONST_MIN + 2]);
float4 texture_transforms[8] : register(vs, c[CUSTOM_CONST_MIN + 3]);

const static float wave_length = 0.1;
const static float wave_height = 0.1;
const static float2 water_direction = {0.5, 1.0};
const static float time_scale = 0.003333;

struct Vs_fade_output
{
   float4 position : POSITION;
   float fog : FOG;
   float fade : TEXCOORD0;
};

Vs_fade_output transmissive_pass_fade_vs(float4 position : POSITION)
{
   Vs_fade_output output;

   float4 world_position = transform::position(position);

   output.position = position_project(world_position);
   output.fade = output.position.z * fade_constant.z + fade_constant.w;
   output.fog = calculate_fog(world_position);

   return output;
}

struct Vs_lowquality_output
{
   float4 position : POSITION;
   float fog : FOG;
   float2 diffuse_texcoords[2] : TEXCOORD0;
   float2 spec_texcoords[2] : TEXCOORD2;
   float2 hdr_scale_fade : COLOR0;
   float specular : COLOR1;
};

Vs_lowquality_output lowquality_vs(float4 position : POSITION, float3 normal : NORMAL,
                                   float4 texcoords : TEXCOORD)
{
   Vs_lowquality_output output;

   float4 world_position = transform::position(position);
   float3 world_normal = normals_to_world(decompress_normals(normal));

   float3 view_normal = normalize(world_view_position - world_position).xyz;

   float3 half_vector = normalize(light_direction.xyz + view_normal);
   float specular_angle = max(dot(half_vector, normal), 0.0);
   output.specular = pow(specular_angle, light_direction.w);

   output.diffuse_texcoords[0] = decompress_transform_texcoords(texcoords,
                                                                texture_transforms[0],
                                                                texture_transforms[1]);
   output.diffuse_texcoords[1] = decompress_transform_texcoords(texcoords,
                                                                texture_transforms[2],
                                                                texture_transforms[3]);

   output.spec_texcoords[0] = decompress_transform_texcoords(texcoords,
                                                             texture_transforms[4],
                                                             texture_transforms[5]);
   output.spec_texcoords[1] = decompress_transform_texcoords(texcoords,
                                                             texture_transforms[6],
                                                             texture_transforms[7]);

   output.position = position_project(world_position);
   output.hdr_scale_fade.x = hdr_info.z;
   output.hdr_scale_fade.y = output.position.z * fade_constant.z + fade_constant.w;
   output.fog = calculate_fog(world_position);

   return output;
}

struct Vs_normal_map_output
{
   float4 position : POSITION;
   float fog : FOG;
   float fade : COLOR0;
   float4 projected_texcoords : TEXCOORD0;
   float3 view_normal : TEXCOORD1;
   float3 half_vector : TEXCOORD2;
   float2 texcoords : TEXCOORD3;
};

Vs_normal_map_output normal_map_vs(float4 position : POSITION, float3 normal : NORMAL)
{
   Vs_normal_map_output output;

   float4 world_position = transform::position(position);
   float3 world_normal = normals_to_world(decompress_normals(normal));
   float3 view_normal = normalize(world_view_position - world_position).xyz;

   output.position = position_project(world_position);
   output.half_vector = light_direction.xyz + view_normal;
   output.view_normal = view_normal * 0.25 + 0.25;

   output.projected_texcoords.x = dot(output.position.xyw, texcoords_projection.yxy);
   output.projected_texcoords.y = dot(output.position.xyw, texcoords_projection.xzy);
   output.projected_texcoords.z = 0.0;
   output.projected_texcoords.w = output.position.w;

   float2 texcoords = world_position.xz * 0.125;

   texcoords.x = dot(float4(texcoords, 0, 1), texture_transforms[0]);
   texcoords.y = dot(float4(texcoords, 0, 1), texture_transforms[1]);

   output.texcoords = texcoords * wave_length + time_scale * time * water_direction;

   output.fade = output.position.z * fade_constant.z + fade_constant.w;
   output.fog = calculate_fog(world_position);

   return output;
}

// Pixel Shaders //

float4 refraction_colour : register(ps, c[0]);
float4 reflection_colour : register(ps, c[1]);
float4 fresnel_min_max : register(ps, c[2]);
float4 blend_map_constant : register(ps, c[3]);
float4 blend_specular_constant : register(ps, c[4]);
float3 offset_scales : register(ps, c[5]);

float3 reflection_map_sample(sampler2D reflection_map, float4 texcoords, float3 normal)
{
   texcoords.x += -0.011 * normal.x + -0.028 * normal.y;
   texcoords.y += 0.011 * normal.x + -0.011 * normal.y;
   
   return tex2Dproj(reflection_map, texcoords).rgb;
}

float4 transmissive_pass_fade_ps(float fade : TEXCOORD0) : COLOR
{
   return float4(refraction_colour.rgb * fade, fade);
}

struct Ps_normal_map_input
{
   float fade : COLOR0;
   float4 projected_texcoords : TEXCOORD0;
   float3 view_normal : TEXCOORD1;
   float3 half_vector : TEXCOORD2;
   float2 texcoords : TEXCOORD3;
};

float4 normal_map_distorted_reflection_ps(Ps_normal_map_input input,
                                          uniform sampler2D normal_map : register(s8),
                                          uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal = tex2D(normal_map, input.texcoords).xyz  * 2.0 - 1.0;

   float2 reflection_coords = input.projected_texcoords.xy / input.projected_texcoords.w;
   reflection_coords += (normal.xy * wave_height);

   float3 reflection = tex2D(reflection_map, reflection_coords).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot);
   fresnel_term *= fresnel_term;
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 color = reflection * reflection_colour.a;

   return float4(color, fresnel_term * input.fade);

}

float4 normal_map_distorted_reflection_specular_ps(Ps_normal_map_input input,
                                                   uniform sampler2D normal_map : register(s8),
                                                   uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal = tex2D(normal_map, input.texcoords).xyz  * 2.0 - 1.0;

   float2 reflection_coords = input.projected_texcoords.xy / input.projected_texcoords.w;
   reflection_coords += (normal.xy * wave_height);

   float3 reflection = tex2D(reflection_map, reflection_coords).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot);
   fresnel_term *= fresnel_term;
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 half_vector = normalize(input.half_vector);

   float specular_angle = saturate(dot(half_vector, normal));
   float specular = pow(specular_angle, 64);

   float3 color = reflection * reflection_colour.a + specular;

   return float4(color, fresnel_term * input.fade);
}

float4 normal_map_reflection_ps(Ps_normal_map_input input,
                                           uniform sampler2D normal_map : register(s8),
                                           uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal = tex2D(normal_map, input.texcoords).xyz  * 2.0 - 1.0;

   float3 reflection = tex2Dproj(reflection_map, input.projected_texcoords).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot);
   fresnel_term *= fresnel_term;
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 color = reflection * reflection_colour.a;

   return float4(color, fresnel_term * input.fade);
}

float4 normal_map_reflection_specular_ps(Ps_normal_map_input input,
                                         uniform sampler2D normal_map : register(s8), 
                                         uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal = tex2D(normal_map, input.texcoords).xyz  * 2.0 - 1.0;

   float3 reflection = tex2Dproj(reflection_map, input.projected_texcoords).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot);
   fresnel_term *= fresnel_term;
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 half_vector = normalize(input.half_vector);

   float specular_angle = saturate(dot(half_vector, normal));
   float specular = pow(specular_angle, 64);

   float3 color = reflection * reflection_colour.a + specular;

   return float4(color, fresnel_term * input.fade);
}

float4 normal_map_ps(Ps_normal_map_input input,
                     uniform sampler2D normal_map : register(s8)) : COLOR
{
   float3 normal = tex2D(normal_map, input.texcoords).xyz  * 2.0 - 1.0;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot);
   fresnel_term *= fresnel_term;
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   return float4(reflection_colour.rgb, fresnel_term * input.fade);
}

float4 normal_map_specular_ps(Ps_normal_map_input input,
                              uniform sampler2D normal_map : register(s8)) : COLOR
{
   float3 normal = tex2D(normal_map, input.texcoords).xyz  * 2.0 - 1.0;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot);
   fresnel_term *= fresnel_term;
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 half_vector = normalize(input.half_vector);

   float specular_angle = saturate(dot(half_vector, normal));
   float specular = pow(specular_angle, 64);

   return float4(reflection_colour.rgb + specular, fresnel_term * input.fade);
}

struct Ps_lowquality_input
{
   float2 diffuse_texcoords[2] : TEXCOORD0;
   float2 spec_texcoords[2] : TEXCOORD2;
   float2 hdr_scale_fade : COLOR0;
   float specular : COLOR1;
};

float4 lowquality_ps(Ps_lowquality_input input,
                     uniform sampler2D diffuse_map : register(s1)) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords[1]);

   float4 color = refraction_colour * diffuse_color;
   color.rgb *= input.hdr_scale_fade.x;
   color.a *= input.hdr_scale_fade.y;

   return color;
}

float4 lowquality_specular_ps(Ps_lowquality_input input,
                              uniform sampler2D diffuse_map : register(s1),
                              uniform sampler2D specular_map[2] : register(s2)) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords[1]);

   float3 spec_mask_0 = tex2D(specular_map[0], input.spec_texcoords[0]).rgb;
   float3 spec_mask_1 = tex2D(specular_map[1], input.spec_texcoords[1]).rgb;
   float3 spec_mask = lerp(spec_mask_0, spec_mask_1, blend_specular_constant.rgb);

   float4 color = refraction_colour * diffuse_color;

   color.rgb += (spec_mask * input.specular);
   color.rgb *= input.hdr_scale_fade.x;
   color.a *= input.hdr_scale_fade.y;

   return color;
}
