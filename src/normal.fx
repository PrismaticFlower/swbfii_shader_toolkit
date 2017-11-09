
#include "constants_list.hlsl"
#include "vertex_utilities.hlsl"
#include "transform_utilities.hlsl"
#include "lighting_utilities.hlsl"

sampler diffuse_map : register(ps, s[0]);
sampler detail_map : register(ps, s[1]);
sampler projected_texture : register(ps, s[2]);
sampler shadow_map : register(ps, s[3]);

float4 lighting_constant : register(vs, c[CUSTOM_CONST_MIN]);
float4 texture_transforms[4] : register(vs, c[CUSTOM_CONST_MIN + 1]);

struct Vs_input
{
   float4 position : POSITION;
   float3 normals : NORMAL;
   uint4 blend_indices : BLENDINDICES;
   float4 weights : BLENDWEIGHT;
   float4 texcoords : TEXCOORD;
   float4 color : COLOR;
};

struct Vs_output
{
   float4 position : POSITION;
   float2 diffuse_texcoords : TEXCOORD0;
   float2 detail_texcoords : TEXCOORD1;
   float4 color : COLOR;
   float1 fog : FOG;
};

Vs_output unlit_opaque_vs(Vs_input input)
{
   Vs_output output;
    
   float4 world_position = transform::position(input.position, input.blend_indices,
                                               input.weights);

   output.position = position_project(world_position);

   output.diffuse_texcoords = decompress_transform_texcoords(input.texcoords,
                                                             texture_transforms[0],
                                                             texture_transforms[1]);
   
   output.detail_texcoords = decompress_transform_texcoords(input.texcoords,
                                                            texture_transforms[2],
                                                            texture_transforms[3]);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   float4 material_color = get_material_color(input.color);

   output.color.rgb = hdr_info.z * lighting_constant.x + lighting_constant.y;
   output.color.rgb *= material_color.rgb;
   output.color.a = near_scene.fade * constant_1.y + constant_1.z;

   return output;
}

Vs_output unlit_transparent_vs(Vs_input input)
{
   Vs_output output;
    
   float4 world_position = transform::position(input.position, input.blend_indices,
                                               input.weights);

   output.position = position_project(world_position);

   output.diffuse_texcoords = decompress_transform_texcoords(input.texcoords,
                                                             texture_transforms[0],
                                                             texture_transforms[1]);

   output.detail_texcoords = decompress_transform_texcoords(input.texcoords,
                                                            texture_transforms[2],
                                                            texture_transforms[3]);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   near_scene = clamp_near_scene_fade(near_scene);
   near_scene.fade *= near_scene.fade;

   float4 material_color = get_material_color(input.color);

   output.color.a = material_color.a * near_scene.fade;

   output.color.rgb = hdr_info.z * lighting_constant.x + lighting_constant.y;
   output.color.rgb *= material_color.rgb;

   return output;
}

Vs_output near_opaque_vs(Vs_input input)
{
   Vs_output output;
    
   float4 world_position = transform::position(input.position, input.blend_indices,
                                               input.weights);

   output.position = position_project(world_position);

   output.diffuse_texcoords = decompress_transform_texcoords(input.texcoords,
                                                             texture_transforms[0],
                                                             texture_transforms[1]);

   output.detail_texcoords = decompress_transform_texcoords(input.texcoords,
                                                            texture_transforms[2],
                                                            texture_transforms[3]);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   float3 normals = transform::normals(input.normals, input.blend_indices,
                                       input.weights);

   Lighting lighting = light::diffuse::calculate(normals, world_position,
                                                 get_static_diffuse_color(input.color));

   float4 material_color = get_material_color(input.color);

   output.color.rgb = lighting.diffuse.rgb * lighting_constant.x + lighting_constant.y;
   output.color.rgb *= material_color.rgb;
   output.color.a = near_scene.fade * constant_1.y + constant_1.z;

   return output;
}

struct Vs_shadow_output
{
   float4 position : POSITION;
   float2 diffuse_texcoords : TEXCOORD0;
   float2 detail_texcoords : TEXCOORD1;
   float4 projection_texcoords : TEXCOORD2;
   float4 shadow_texcoords : TEXCOORD3;
   float4 color : COLOR0;
   float4 projection_color : COLOR1;
   float1 fog : FOG;
};

Vs_shadow_output near_opaque_shadow_projectedtex_vs(Vs_input input)
{
   Vs_shadow_output output;
    
   float4 world_position = transform::position(input.position, input.blend_indices,
                                               input.weights);

   output.position = position_project(world_position);

   output.diffuse_texcoords = decompress_transform_texcoords(input.texcoords,
                                                             texture_transforms[0],
                                                             texture_transforms[1]);

   output.detail_texcoords = decompress_transform_texcoords(input.texcoords,
                                                           texture_transforms[2],
                                                           texture_transforms[3]);

   output.projection_texcoords = mul(world_position, light_proj_matrix);

   output.shadow_texcoords = transform_shadowmap_coords(world_position);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   float3 normals = transform::normals(input.normals, input.blend_indices,
                                       input.weights);

   Lighting lighting = light::diffuse::calculate(normals, world_position,
                                                 get_static_diffuse_color(input.color));
   
   float4 material_color = get_material_color(input.color);

   float4 projection_color;
   projection_color.rgb = lighting.static_diffuse.aaa * material_color.rgb;
   projection_color.rgb *= hdr_info.zzz;
   projection_color.rgb *= light_proj_color.rgb;
   projection_color.a = lighting.diffuse.a;

   output.projection_color = projection_color;

   output.color.rgb = lighting.diffuse.rgb * lighting_constant.x + lighting_constant.y;
   output.color.rgb *= material_color.rgb;
   output.color.a = near_scene.fade * constant_1.y + constant_1.z;

   return output;
}

Vs_shadow_output near_transparent_shadow_projectedtex_vs(Vs_input input)
{
   Vs_shadow_output output;
    
   float4 world_position = transform::position(input.position, input.blend_indices,
                                               input.weights);

   output.position = position_project(world_position);

   output.diffuse_texcoords = decompress_transform_texcoords(input.texcoords,
                                                             texture_transforms[0],
                                                             texture_transforms[1]);
   
   output.detail_texcoords = decompress_transform_texcoords(input.texcoords,
                                                            texture_transforms[2],
                                                            texture_transforms[3]);

   output.projection_texcoords = mul(world_position, light_proj_matrix);

   output.shadow_texcoords = transform_shadowmap_coords(world_position);

   Near_scene near_scene = calculate_near_scene_fade(world_position);
   output.fog = calculate_fog(near_scene, world_position);

   near_scene = clamp_near_scene_fade(near_scene);
   near_scene.fade *= near_scene.fade;

   float3 normals = transform::normals(input.normals, input.blend_indices,
                                       input.weights);

   Lighting lighting = light::diffuse::calculate(normals, world_position,
                                                 get_static_diffuse_color(input.color));

   float4 material_color = get_material_color(input.color);

   float4 projection_color;
   projection_color.rgb = lighting.static_diffuse.aaa * material_color.rgb;
   projection_color.rgb *= hdr_info.zzz;
   projection_color.rgb *= light_proj_color.rgb;
   projection_color.a = lighting.diffuse.a;

   output.projection_color = projection_color;

   output.color.rgb = lighting.diffuse.rgb * lighting_constant.xxx + lighting_constant.yyy;
   output.color.rgb *= material_color.rgb;
   output.color.a = near_scene.fade * material_color.a;

   return output;
}

struct Ps_input
{
   float2 diffuse_texcoords : TEXCOORD0;
   float2 detail_texcoords : TEXCOORD1;
   float4 color : COLOR0;
};

float4 blend_constant : register(ps, c[0]);

float4 unlit_opaque_ps(Ps_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);

   float4 color = diffuse_color * input.color;
   color = (color * detail_color) * 2.0;

   float blend_factor = lerp(blend_constant.b, diffuse_color.a, blend_constant.a);

   float4 blended_color = color * blend_factor + color;
   color = blended_color * blend_factor + color;

   color.a = (input.color.a - 0.5) * 4.0;

   return color;
}

float4 unlit_opaque_hardedged_ps(Ps_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);

   float4 color = diffuse_color * input.color;
   color = (color * detail_color) * 2.0;

   float4 blended_color = color * blend_constant.a + color;
   color = blended_color * blend_constant.a + color;

   if (diffuse_color.a > 0.5) color.a = input.color.a - 0.5;
   else color.a = -0.01;

   color.a *= 4.0;

   return color;
}

float4 unlit_transparent_ps(Ps_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);

   float4 color = diffuse_color * input.color;
   color.rgb = (color * detail_color).rgb * 2.0;

   float4 blended_color = color * blend_constant.a + color;
   color.rgb = (blended_color * blend_constant.a + color).rgb;

   return color;
}

float4 unlit_transparent_hardedged_ps(Ps_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);

   float4 color;

   float alpha = diffuse_color.a * input.color.a;

   if (diffuse_color.a > 0.5) color.a = alpha;
   else color.a = 0.0;

   color.rgb = (diffuse_color * input.color).rgb;
   color.rgb = (color * detail_color).rgb * 2.0;

   float3 blended_color;

   blended_color = color.rgb * blend_constant.a + color.rgb;
   color.rgb = blended_color * blend_constant.a + color.rgb;

   return color;
}

float4 near_opaque_ps(Ps_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);

   float4 color = diffuse_color * input.color;
   color.a = (input.color.a - 0.5) * 4.0;
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   return color;
}

float4 near_opaque_hardedged_ps(Ps_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);

   float4 color = diffuse_color * input.color;
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   if (diffuse_color.a > 0.5) color.a = input.color.a - 0.5;
   else color.a = -0.01;
   
   color.a *= 4.0;

   return color;
}

float4 near_transparent_ps(Ps_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);

   float4 color = diffuse_color * input.color;
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   color.a = lerp(1.0, diffuse_color.a, blend_constant.b);
   color.a *= input.color.a;

   return color;
}

float4 near_transparent_hardedged_ps(Ps_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);

   float4 color = diffuse_color * input.color;
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   float alpha = diffuse_color.a * input.color.a;

   if (diffuse_color.a > 0.5) color.a = alpha;
   else color.a = 0.0;

   return color;
}

struct Ps_shadow_input
{
   float2 diffuse_texcoords : TEXCOORD0;
   float2 detail_texcoords : TEXCOORD1;
   float4 projection_texcoords : TEXCOORD2;
   float4 shadow_texcoords : TEXCOORD3;
   float4 color : COLOR0;
   float4 projection_color : COLOR1;
};

float4 near_opaque_projectedtex_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 projected_color = tex2Dproj(projected_texture, input.projection_texcoords);

   float4 color = projected_color * input.projection_color + input.color;
   color.rgb *= diffuse_color.rgb;
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   color.a = (color.a - 0.5) * 4.0;

   return color;
}

float4 near_opaque_hardedged_projectedtex_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 projected_color = tex2Dproj(projected_texture, input.projection_texcoords);

   float4 color = projected_color * input.projection_color + input.color;
   color.rgb *= diffuse_color.rgb;
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   if (diffuse_color.a > 0.5) color.a = (input.color.a - 0.5);
   else color.a = -0.01;

   color.a *= 4.0;

   return color;
}

float4 near_transparent_projectedtex_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 projected_color = tex2Dproj(projected_texture, input.projection_texcoords);

   float4 color = projected_color * input.projection_color + input.color;
   color.rgb *= diffuse_color.rgb;
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   color.a = lerp(1.0, diffuse_color.a, blend_constant.b);
   color.a *= input.color.a;

   return color;
}

float4 near_transparent_hardedged_projectedtex_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 projected_color = tex2Dproj(projected_texture, input.projection_texcoords);

   float4 color = projected_color * input.projection_color + input.color;
   color.rgb *= diffuse_color.rgb;
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   float alpha = diffuse_color.a * input.color.a;

   if (diffuse_color.a > 0.5) color.a = alpha;
   else color.a = 0.0;

   return color;
}

float4 near_opaque_shadow_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 shadow_color = tex2Dproj(shadow_map, input.shadow_texcoords);
   
   float shadow_value = input.projection_color.a * (1 - shadow_color.a);

   float4 color = diffuse_color * input.color;
   color *= (1 - shadow_value);
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   color.a = (input.color.a - 0.5) * 4.0;

   return color;
}

float4 near_opaque_hardedged_shadow_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 shadow_color = tex2Dproj(shadow_map, input.shadow_texcoords);

   float shadow_value = input.projection_color.a * (1 - shadow_color.a);

   float4 color = diffuse_color * input.color;
   color *= (1 - shadow_value);
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   if (diffuse_color.a > 0.5) color.a = (input.color.a - 0.5);
   else color.a = -0.01;

   color.a *= 4.0;

   return color;
}

float4 near_opaque_shadow_projectedtex_ps(Ps_shadow_input input,
                                          uniform float4 shadow_blend : register(ps, c[1])) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 projected_color = tex2Dproj(projected_texture, input.projection_texcoords);
   float4 shadow_color = tex2Dproj(shadow_map, input.shadow_texcoords);

   float projection_shadow_value = lerp(1.0, shadow_color.a, shadow_blend.a);
   float shadow_value = saturate(input.projection_color.a * (1 - shadow_color.a));

   float4 color = projected_color * input.projection_color;
   color = color * projection_shadow_value + input.color;
   color *= diffuse_color;
   color *= (1 - shadow_value);
   color = (color * detail_color) * 2.0;

   color.a = (input.color.a - 0.5) * 4.0;

   return color;
}

float4 near_opaque_hardedged_shadow_projectedtex_ps(Ps_shadow_input input,
                                                    uniform float4 shadow_blend : register(ps, c[1])) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 projected_color = tex2Dproj(projected_texture, input.projection_texcoords);
   float4 shadow_color = tex2Dproj(shadow_map, input.shadow_texcoords);

   float projection_shadow_value = lerp(1.0, shadow_color.a, shadow_blend.a);
   float shadow_value = saturate(input.projection_color.a * (1 - shadow_color.a));

   float4 color = projected_color * input.projection_color;
   color = color * projection_shadow_value + input.color;
   color *= diffuse_color;
   color *= (1 - shadow_value);
   color = (color * detail_color) * 2.0;

   if (diffuse_color.a > 0.5) color.a = (input.color.a - 0.5);
   else color.a = -0.01;

   color.a *= 4.0;

   return color;
}

float4 near_transparent_shadow_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 shadow_color = tex2Dproj(shadow_map, input.shadow_texcoords);

   float shadow_value = input.projection_color.a * (1 - shadow_color.a);

   float4 color = diffuse_color * input.color;
   color *= (1 - shadow_value);
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   color.a = lerp(1.0, diffuse_color.a, blend_constant.a) * input.color.a;

   return color;
}

float4 near_transparent_hardedged_shadow_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 shadow_color = tex2Dproj(shadow_map, input.shadow_texcoords);

   float shadow_value = input.projection_color.a * (1 - shadow_color.a);

   float4 color = diffuse_color * input.color;
   color *= (1 - shadow_value);
   color.rgb = (color.rgb * detail_color.rgb) * 2.0;

   float alpha = diffuse_color.a * input.color.a;

   if (diffuse_color.a > 0.5) color.a = alpha;
   else color.a = 0.0;

   return color;
}

float4 near_transparent_shadow_projectedtex_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 projected_color = tex2Dproj(projected_texture, input.projection_texcoords);
   float4 shadow_color = tex2Dproj(shadow_map, input.shadow_texcoords);

   float shadow_value = input.projection_color.a * (1 - shadow_color.a);

   float4 color = projected_color * input.projection_color + input.color;
   color *= diffuse_color;
   diffuse_color *= (1 - shadow_value);
   color = (color * detail_color) * 2.0;

   color.a = lerp(1.0, diffuse_color.a, blend_constant.b) * input.color.a;

   return color;
}

float4 near_transparent_hardedged_shadow_projectedtex_ps(Ps_shadow_input input) : COLOR
{
   float4 diffuse_color = tex2D(diffuse_map, input.diffuse_texcoords);
   float4 detail_color = tex2D(detail_map, input.detail_texcoords);
   float4 projected_color = tex2Dproj(projected_texture, input.projection_texcoords);
   float4 shadow_color = tex2Dproj(shadow_map, input.shadow_texcoords);

   float shadow_value = input.projection_color.a * (1 - shadow_color.a);

   float4 color = projected_color * input.projection_color + input.color;
   color *= diffuse_color;
   diffuse_color *= (1 - shadow_value);
   color = (color * detail_color) * 2.0;

   float alpha = diffuse_color.a * input.color.a;

   if (diffuse_color.a > 0.5) color.a = alpha;
   else color.a = 0.0;

   return color;
}
