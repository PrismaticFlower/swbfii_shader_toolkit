#ifndef CONSTANTS_LIST_INCLUDED
#define CONSTANTS_LIST_INCLUDED

// This file is a listing of SWBFII's shader constants/uniforms as in 
// pcredvertexshaderconstants.h. Along with the comments on the contents
// of the constants.

// (0.0, 0.5, 1.0, -1.0) 
float4 constant_0 : register(vs, c[0]);

// (2.0, 0.25, 0.5, index_decompress = 765.001) 
float4 constant_1 : register(vs, c[1]);

// world space to projection space matrix
float4x4 projection_matrix : register(vs, c[2]);

// presumably holds the position of the view for some shaders?
float4 world_view_position : register(vs, c[6]);

// (camera fog scale, camera fog offset, world fog scale, world fog offset)
float4 fog_info : register(vs, c[7]);

// (nearfade scale, nearfade offset, lighting scale, 1.0)
float4 near_scene_fade : register(vs, c[8]);

// uses the same register as near_scene_fade, so may be no different or
// it might be. The original authors of the shaders made the distinction
// so this does as well.
#define hdr_info near_scene_fade

// shadow map transform
float4 shadow_map_transform[3] : register(vs, c[9]);

// (normal decompress = 2 or 1, -1 or 0, texture decompress = 1 / 0x0800 or 1, 1)
float4 normaltex_decompress : register(vs, c[12]);

// min_pos = ((bbox (max - min) * 0.5 / 0x7FFF) or (1, 1, 1), 0)
float4 position_decompress_min : register(vs, c[13]);
// max_pos = ((bbox (max + min) * 0.5 / 0x7FFF) or (0, 0, 0), 1)
float4 position_decompress_max : register(vs, c[14]);

// Pandemic: whether vertex colors are lighting or material colors
// (1, 0, 0, 0)
float4 color_state : register(vs, c[15]);

// object space to world space matrix
float4x3 world_matrix : register(vs, c[16]);

// Pandemic: ambient color interpolated with ambient color1 using world 
// normal y component - applied in the transform fragment (i.e. lighting 
// fragment not needed)
float4 light_ambient_color_top : register(vs, c[19]);

// Pandemic: ambient color interpolated with ambient color0 using world 
// normal y component - applied in the transform fragment (i.e. lighting 
// fragment not needed)
float4 light_ambient_color_bottom : register(vs, c[20]);

// directional light 0 color
float4 light_directional_0_color : register(vs, c[21]);

// directional light 0 normalized world space direction
float4 light_directional_0_dir : register(vs, c[22]);

// directional light 1 color
float4 light_directional_1_color : register(vs, c[23]);

// directional light 1 normalized world space direction
float4 light_directional_1_dir : register(vs, c[24]);

// point light 0 color, intensity in alpha value
float4 light_point_0_color : register(vs, c[25]);

// point light 0 world space position
float4 light_point_0_pos : register(vs, c[26]);

// point light 1 color, intensity in alpha value
float4 light_point_1_color : register(vs, c[27]);

// point light 1 world space position
float4 light_point_1_pos : register(vs, c[28]);

// point light 2 color, intensity in alpha value 
// (shares register with light_spot_color)
float4 light_point_2_color : register(vs, c[29]);

// point light 2 world space position
// (shares register with light_spot_pos)
float4 light_point_2_pos : register(vs, c[30]);

// point light 3 color, intensity in alpha value
// (shares register with light_spot_dir)
float4 light_point_3_color : register(vs, c[31]);

// point light 3 world space position
// (shares register with light_spot_params)
float4 light_point_3_pos : register(vs, c[32]);

// spot light color, intensity in alpha value
float4 light_spot_color : register(vs, c[29]);

// spot light position, w = 1 / r^2
float4 light_spot_pos : register(vs, c[30]);

// spot light direction
float4 light_spot_dir : register(vs, c[31]);

// spot light params
// (x = half outer cone angle, y = half inner cone angle, 
//  z = 1 / (cos(y) - cos(x)), w = falloff)
float4 light_spot_params : register(vs, c[32]);

// projected light color
float4 light_proj_color : register(vs, c[33]);

// Pandemic: selects which light use for the projection texture
float4 light_proj_selector : register(vs, c[34]);

// projected light matrix
float4x4 light_proj_matrix : register(vs, c[35]);

// Pandemic: material diffuse color (x tweak color)
float4 material_diffuse_color : register(vs, c[39]);

// registers 40 to 50 are set aside as "custom constants"
#define CUSTOM_CONST_MIN 40
#define CUSTOM_CONST_MAX 50

// bone matrices
float4 bone_matrices[48] : register(vs, c[51]);


#endif