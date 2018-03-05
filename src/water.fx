
#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"
#include "transform_utilities.hlsl"

float4 texcoords_projection : register(vs, c[CUSTOM_CONST_MIN]);
float4 fade_constant : register(vs, c[CUSTOM_CONST_MIN + 1]);
float4 light_direction : register(vs, c[CUSTOM_CONST_MIN + 2]);
float4 texture_transforms[8] : register(vs, c[CUSTOM_CONST_MIN + 3]);

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

struct Vs_projective_normal_map_output
{
   float4 position : POSITION;
   float fog : FOG;
   float fade : COLOR0;
   float4 projected_texcoords : TEXCOORD0;
   float2 bump_texcoords : TEXCOORD1;
   float3 view_normal : TEXCOORD2;
   float3 half_vector : TEXCOORD3;
};

Vs_projective_normal_map_output projective_normal_map_vs(float4 position : POSITION, 
                                                         float3 normal : NORMAL,
                                                         float4 texcoords : TEXCOORD)
{
   Vs_projective_normal_map_output output;

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

   output.bump_texcoords = decompress_transform_texcoords(texcoords,
                                                          texture_transforms[0],
                                                          texture_transforms[1]);

   output.fade = output.position.z * fade_constant.z + fade_constant.w;
   output.fog = calculate_fog(world_position);

   return output;
}

struct Vs_blended_normal_maps_output
{
   float4 position : POSITION;
   float fog : FOG;
   float fade : COLOR0; // v0.w
   float4 projected_texcoords : TEXCOORD0; // t3
   float2 bump_texcoords[2] : TEXCOORD1; // t0, t1
   float3 view_normal : TEXCOORD3; // v0
   float3 half_vector : TEXCOORD4; // t2
};

Vs_blended_normal_maps_output blended_normal_maps_output_vs(float4 position : POSITION,
                                                            float3 normal : NORMAL,
                                                            float4 texcoords : TEXCOORD)
{
   Vs_blended_normal_maps_output output;

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

   output.bump_texcoords[0] = decompress_transform_texcoords(texcoords,
                                                             texture_transforms[0],
                                                             texture_transforms[1]);
   output.bump_texcoords[1] = decompress_transform_texcoords(texcoords,
                                                             texture_transforms[2],
                                                             texture_transforms[3]);

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

float3 reflection_map_sample(sampler2D reflection_map, float4 texcoords, float2 bump_map)
{
   texcoords.x += -0.011 * bump_map.x + -0.028 * bump_map.y;
   texcoords.y += 0.011 * bump_map.x + -0.011 * bump_map.y;
   
   return tex2Dproj(reflection_map, texcoords).rgb;
}

float4 transmissive_pass_fade_ps(float fade : TEXCOORD0) : COLOR
{
   return float4(refraction_colour.rgb * fade, fade);
}

struct Ps_projective_normal_map_input
{
   float fade : COLOR0;
   float4 projected_texcoords : TEXCOORD0;
   float2 bump_texcoords : TEXCOORD1;
   float3 view_normal : TEXCOORD2;
   float3 half_vector : TEXCOORD3;
};

float4 projective_normal_map_distorted_reflection_ps(Ps_projective_normal_map_input input,
                                                     uniform sampler2D accum_normal_map : register(s0),
                                                     uniform sampler2D signed_bump_map : register(s2),
                                                     uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal = tex2Dproj(accum_normal_map, input.projected_texcoords).xyz * 2.0 - 1.0;
   float2 bump_map = tex2D(signed_bump_map, input.bump_texcoords).xy;
   float3 reflection = 
      reflection_map_sample(reflection_map, input.projected_texcoords, bump_map).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot) * (1.0 - normal_view_dot);
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 color = reflection * reflection_colour.a;

   return float4(color, fresnel_term * input.fade);
}

float4 projective_normal_map_distorted_reflection_specular_ps(Ps_projective_normal_map_input input,
                                                              uniform sampler2D accum_normal_map : register(s0),
                                                              uniform sampler2D signed_bump_map : register(s2),
                                                              uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal = tex2Dproj(accum_normal_map, input.projected_texcoords).xyz * 2.0 - 1.0;
   float2 bump_map = tex2D(signed_bump_map, input.bump_texcoords).xy;
   float3 reflection = 
      reflection_map_sample(reflection_map, input.projected_texcoords, bump_map).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot) * (1.0 - normal_view_dot);
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 half_vector = normalize(input.half_vector);

   float specular_angle = saturate(dot(half_vector, normal));
   float specular = pow(specular_angle, 8);

   float3 color = reflection * reflection_colour.a + specular;

   return float4(color, fresnel_term * input.fade);
}


float4 projective_normal_map_reflection_ps(Ps_projective_normal_map_input input,
                                                     uniform sampler2D accum_normal_map : register(s0),
                                                     uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal = tex2Dproj(accum_normal_map, input.projected_texcoords).xyz * 2.0 - 1.0;
   float3 reflection = 
      tex2Dproj(reflection_map, input.projected_texcoords).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot) * (1.0 - normal_view_dot);
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 color = reflection * reflection_colour.a;

   return float4(color, fresnel_term * input.fade);
}


float4 projective_normal_map_reflection_specular_ps(Ps_projective_normal_map_input input,
                                                    uniform sampler2D accum_normal_map : register(s0),
                                                    uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal = tex2Dproj(accum_normal_map, input.projected_texcoords).xyz * 2.0 - 1.0;
   float3 reflection =
      tex2Dproj(reflection_map, input.projected_texcoords).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot) * (1.0 - normal_view_dot);
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 half_vector = normalize(input.half_vector);

   float specular_angle = saturate(dot(half_vector, normal));
   float specular = pow(specular_angle, 8);

   float3 color = reflection * reflection_colour.a + specular;

   return float4(color, fresnel_term * input.fade);
}

struct Ps_blended_normal_maps_input
{
   float fade : COLOR0;
   float4 projected_texcoords : TEXCOORD0; 
   float2 bump_texcoords[2] : TEXCOORD1;
   float3 view_normal : TEXCOORD3;
   float3 half_vector : TEXCOORD4;
};

float4 blended_normal_maps_reflection_ps(Ps_blended_normal_maps_input input,
                                         uniform sampler2D normal_maps[2] : register(s0),
                                         uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal_0 = tex2D(normal_maps[0], input.bump_texcoords[0]).xyz;
   float3 normal_1 = tex2D(normal_maps[1], input.bump_texcoords[1]).xyz;
   float3 normal = lerp(normal_1, normal_0, blend_map_constant.a) * 2.0 - 1.0;

   float3 reflection = 
      tex2Dproj(reflection_map, input.projected_texcoords).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot) * (1.0 - normal_view_dot);
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 color = reflection * reflection_colour.a;

   return float4(color, fresnel_term * input.fade);
}

float4 blended_normal_maps_reflection_specular_ps(Ps_blended_normal_maps_input input,
                                                  uniform sampler2D normal_maps[2] : register(s0),
                                                  uniform sampler2D reflection_map : register(s3)) : COLOR
{
   float3 normal_0 = tex2D(normal_maps[0], input.bump_texcoords[0]).xyz;
   float3 normal_1 = tex2D(normal_maps[1], input.bump_texcoords[1]).xyz;
   float3 normal = lerp(normal_1, normal_0, blend_map_constant.a) * 2.0 - 1.0;

   float3 reflection = 
      tex2Dproj(reflection_map, input.projected_texcoords).rgb;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot) * (1.0 - normal_view_dot);
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 half_vector = normalize(input.half_vector);

   float specular_angle = saturate(dot(half_vector, normal));
   float specular = pow(specular_angle, 8);

   float3 color = reflection * reflection_colour.a + specular;

   return float4(color, fresnel_term * input.fade);
}

float4 blended_normal_maps_ps(Ps_blended_normal_maps_input input,
                              uniform sampler2D normal_maps[2] : register(s0)) : COLOR
{
   float3 normal_0 = tex2D(normal_maps[0], input.bump_texcoords[0]).xyz;
   float3 normal_1 = tex2D(normal_maps[1], input.bump_texcoords[1]).xyz;
   float3 normal = lerp(normal_1, normal_0, blend_map_constant.a) * 2.0 - 1.0;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot) * (1.0 - normal_view_dot);
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 color = reflection_colour.rgb;

   return float4(color, fresnel_term * input.fade);
}

float4 blended_normal_maps_specular_ps(Ps_blended_normal_maps_input input,
                                       uniform sampler2D normal_maps[2] : register(s0)) : COLOR
{
   float3 normal_0 = tex2D(normal_maps[0], input.bump_texcoords[0]).xyz;
   float3 normal_1 = tex2D(normal_maps[1], input.bump_texcoords[1]).xyz;
   float3 normal = lerp(normal_1, normal_0, blend_map_constant.a) * 2.0 - 1.0;

   float3 view_normal = normalize(input.view_normal);

   float normal_view_dot = dot(normal, view_normal);

   float fresnel_term = (1.0 - normal_view_dot) * (1.0 - normal_view_dot);
   fresnel_term = lerp(fresnel_min_max.z, fresnel_min_max.w, fresnel_term);

   float3 half_vector = normalize(input.half_vector);

   float specular_angle = saturate(dot(half_vector, normal));
   float specular = pow(specular_angle, 8);

   float3 color = reflection_colour.rgb + specular;

   return float4(color, fresnel_term * input.fade);
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
