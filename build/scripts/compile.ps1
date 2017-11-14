.\build\scripts\compile_helpers.ps1

### Decal Shader ###

compile_function "decal" "decal_vs" "vs_2_0"
compile_function "decal" "diffuse_ps" "ps_2_0"
compile_function "decal" "diffuse_bump_ps" "ps_2_0"
compile_function "decal" "bump_ps" "ps_2_0"

### Filtercopy Shader ###

compile_function "filtercopy" "filtercopy_vs" "vs_2_0"
compile_function "filtercopy" "filtercopy_1tex_ps" "ps_2_0"
compile_function "filtercopy" "filtercopy_2tex_ps" "ps_2_0"
compile_function "filtercopy" "filtercopy_3tex_ps" "ps_2_0"
compile_function "filtercopy" "filtercopy_4tex_ps" "ps_2_0"

### Flare Shader ###

compile_function "flare" "flare_textured_vs" "vs_2_0" $false $false "yes"
compile_function "flare" "flare_untextured_vs" "vs_2_0" $false $false "yes"
compile_function "flare" "flare_textured_ps" "ps_2_0"
compile_function "flare" "flare_untextured_ps" "ps_2_0"

### Foliage Shader ###

compile_function "foliage" "opaque_vs" "vs_2_0" $false $false "yes"
compile_function "foliage" "transparent_vs" "vs_2_0" $false $false "yes"
compile_function "foliage" "hardedged_ps" "ps_2_0"
compile_function "foliage" "transparent_hardedged_ps" "ps_2_0"
compile_function "foliage" "shadow_hardedged_ps" "ps_2_0"
compile_function "foliage" "shadow_transparent_hardedged_ps" "ps_2_0"

### HDR Shader ###

compile_function "hdr" "screenspace_vs" "vs_2_0"
compile_function "hdr" "bloomfilter_vs" "vs_2_0"
compile_function "hdr" "glowthreshold_ps" "ps_2_0"
compile_function "hdr" "luminance_ps" "ps_2_0"
compile_function "hdr" "bloomfilter_ps" "ps_2_0"
compile_function "hdr" "screenspace_ps" "ps_2_0"

### Interface Shader ###

compile_pass "interface" "masked_bitmap_vs" "masked_bitmap_ps"
compile_pass "interface" "vector_vs" "vector_ps"
compile_pass "interface" "bitmap_untextured_vs" "bitmap_untextured_ps"
compile_pass "interface" "bitmap_textured_vs" "bitmap_textured_ps"

### Lightbeam Shader ###

compile_function "lightbeam" "lightbeam_vs" "vs_2_0" $false $false "yes"
compile_function "lightbeam" "lightbeam_ps" "ps_2_0"

### Normal Shader ###

compile_function "normal" "unlit_opaque_vs" "vs_2_0" $true $false "yes"
compile_function "normal" "unlit_transparent_vs" "vs_2_0" $true $false "yes"
compile_function "normal" "near_opaque_vs" "vs_2_0" $true $true "yes"
compile_function "normal" "near_opaque_shadow_projectedtex_vs" "vs_2_0" $true $true "yes"
compile_function "normal" "near_transparent_shadow_projectedtex_vs" "vs_2_0" $true $true "yes"
compile_function "normal" "unlit_opaque_ps" "ps_2_0"
compile_function "normal" "unlit_opaque_hardedged_ps" "ps_2_0"
compile_function "normal" "unlit_transparent_ps" "ps_2_0"
compile_function "normal" "unlit_transparent_hardedged_ps" "ps_2_0"
compile_function "normal" "near_opaque_ps" "ps_2_0"
compile_function "normal" "near_opaque_hardedged_ps" "ps_2_0"
compile_function "normal" "near_transparent_ps" "ps_2_0"
compile_function "normal" "near_transparent_hardedged_ps" "ps_2_0"
compile_function "normal" "near_opaque_projectedtex_ps" "ps_2_0"
compile_function "normal" "near_opaque_hardedged_projectedtex_ps" "ps_2_0"
compile_function "normal" "near_transparent_projectedtex_ps" "ps_2_0"
compile_function "normal" "near_transparent_hardedged_projectedtex_ps" "ps_2_0"
compile_function "normal" "near_opaque_shadow_ps" "ps_2_0"
compile_function "normal" "near_opaque_hardedged_shadow_ps" "ps_2_0"
compile_function "normal" "near_opaque_shadow_projectedtex_ps" "ps_2_0"
compile_function "normal" "near_opaque_hardedged_shadow_projectedtex_ps" "ps_2_0"
compile_function "normal" "near_transparent_shadow_ps" "ps_2_0"
compile_function "normal" "near_transparent_hardedged_shadow_ps" "ps_2_0"
compile_function "normal" "near_transparent_shadow_projectedtex_ps" "ps_2_0"
compile_function "normal" "near_transparent_hardedged_shadow_projectedtex_ps" "ps_2_0"

### Normal terrain Shader ###

compile_function "normal_terrain" "diffuse_blendmap_vs" "vs_2_0" $false $true "always"
compile_function "normal_terrain" "detailing_vs" "vs_2_0" $false $true "always"
compile_function "normal_terrain" "diffuse_blendmap_ps" "ps_2_0"
compile_function "normal_terrain" "detailing_ps" "ps_2_0"

### Normalmapadder Shader ###

compile_function "normalmapadder" "normalmapadder_vs" "vs_2_0" $false $false "no"
compile_function "normalmapadder" "normalmapadder_binormals_vs" "vs_2_0" $false $false "yes"
compile_function "normalmapadder" "normalmapadder_ps" "ps_2_0" 
compile_function "normalmapadder" "normalmapadder_binormals_ps" "ps_2_0" 

### Ocean Shader ###

compile_function "ocean" "far_vs" "vs_2_0" $false $false "yes"
compile_function "ocean" "near_vs" "vs_2_0" $false $false "yes"
compile_function "ocean" "far_ps" "ps_2_0" 
compile_function "ocean" "near_ps" "ps_2_0" 

### Particle Shader ###

compile_function "particle" "normal_vs" "vs_2_0" $false $false "yes"
compile_function "particle" "blur_vs" "vs_2_0" $false $false "yes"
compile_function "particle" "normal_ps" "ps_2_0" 
compile_function "particle" "blur_ps" "ps_2_0" 

### Perpixeldiffuselighting Shader ###

compile_function "perpixeldiffuselighting" "lights_3_vs" "vs_2_0" $true $false "yes"
compile_function "perpixeldiffuselighting" "lights_3_genbinormals_vs" "vs_2_0" $true $false "yes"
compile_function "perpixeldiffuselighting" "lights_3_genbinormals_terrain_vs" "vs_2_0" $true $false "yes"
compile_function "perpixeldiffuselighting" "lights_3_normalmap_ps" "ps_2_0" 
compile_function "perpixeldiffuselighting" "lights_2_normalmap_ps" "ps_2_0" 
compile_function "perpixeldiffuselighting" "lights_1_normalmap_ps" "ps_2_0" 
compile_function "perpixeldiffuselighting" "lights_3_ps" "ps_2_0" 
compile_function "perpixeldiffuselighting" "lights_2_ps" "ps_2_0" 
compile_function "perpixeldiffuselighting" "lights_1_ps" "ps_2_0" 
compile_function "perpixeldiffuselighting" "spotlight_vs" "vs_2_0" $true $false "yes"
compile_function "perpixeldiffuselighting" "spotlight_genbinormals_vs" "vs_2_0" $true $false "yes"
compile_function "perpixeldiffuselighting" "spotlight_genbinormals_terrain_vs" "vs_2_0" $true $false "yes"
compile_function "perpixeldiffuselighting" "spotlight_normalmap_ps" "ps_2_0"
compile_function "perpixeldiffuselighting" "spotlight_ps" "ps_2_0"

### Prereflection Shader ###

compile_function "prereflection" "prereflection_vs" "vs_2_0"
compile_function "prereflection" "prereflection_fake_stencil_vs" "vs_2_0"
compile_function "prereflection" "prereflection_ps" "ps_2_0"

### Rain Shader ###

compile_function "rain" "rain_vs" "vs_2_0" $false $false "yes"
compile_function "rain" "rain_ps" "ps_2_0"

### Refraction Shader ###

compile_function "refraction" "far_vs" "vs_2_0" $true $true "yes"
compile_function "refraction" "nodistortion_vs" "vs_2_0" $true $true "yes"
compile_function "refraction" "distortion_vs" "vs_2_0" $true $true "yes"
compile_function "refraction" "far_ps" "ps_2_0"
compile_function "refraction" "near_diffuse_ps" "ps_2_0"
compile_function "refraction" "near_ps" "ps_2_0"

### Sample Shader ###

compile_pass "sample" "sample_vs" "sample_ps"

### Shadowquad Shader ###

compile_pass "shadowquad" "shadowquad_vs" "shadowquad_ps"

### Shield Shader ###

compile_pass "shield" "shield_vs" "shield_ps"

### Skyfog Shader ###

compile_pass "skyfog" "skyfog_vs" "skyfog_ps"

### Sprite Shader ###

compile_function "sprite" "sprite_vs" "vs_2_0" $false $false "yes"
compile_function "sprite" "sprite_ps" "ps_2_0"

### Z-Prepass Shader ###

compile_function "zprepass" "opaque_vs" "vs_2_0" $true
compile_function "zprepass" "hardedged_vs" "vs_2_0" $true $false "yes"
compile_function "zprepass" "opaque_ps" "ps_2_0"
compile_function "zprepass" "hardedged_ps" "ps_2_0"

foreach ($file in Get-ChildItem -File -Path build\templates\* -Include *.xml.template)
{
   $name = $file.Name -replace ".xml.template", ""

   instantiate_template $name
}