.\build\scripts\compile_helpers.ps1

### Filtercopy Shader ###

compile_function "filtercopy" "filtercopy_vs" "vs_2_0"
compile_function "filtercopy" "filtercopy_1tex_ps" "ps_2_0"
compile_function "filtercopy" "filtercopy_2tex_ps" "ps_2_0"
compile_function "filtercopy" "filtercopy_3tex_ps" "ps_2_0"
compile_function "filtercopy" "filtercopy_4tex_ps" "ps_2_0"

### Flare Shader ###

compile_pass "flare" "flare_textured_vs" "flare_textured_ps"
compile_pass "flare" "flare_untextured_vs" "flare_untextured_ps"

### Foliage Shader ###

compile_function "foliage" "opaque_vs" "vs_2_0"
compile_function "foliage" "transparent_vs" "vs_2_0"
compile_function "foliage" "hardedged_ps" "ps_2_0"
compile_function "foliage" "transparent_hardedged_ps" "ps_2_0"
compile_function "foliage" "shadow_hardedged_ps" "ps_2_0"
compile_function "foliage" "shadow_transparent_hardedged_ps" "ps_2_0"

### Interface Shader ###

compile_pass "interface" "masked_bitmap_vs" "masked_bitmap_ps"
compile_pass "interface" "vector_vs" "vector_ps"
compile_pass "interface" "bitmap_untextured_vs" "bitmap_untextured_ps"
compile_pass "interface" "bitmap_textured_vs" "bitmap_textured_ps"

### Lightbeam Shader ###

compile_pass "lightbeam" "lightbeam_vs" "lightbeam_ps"

### Normalmapadder Shader ###

compile_pass "normalmapadder" "normalmapadder_vs" "normalmapadder_ps"
compile_pass "normalmapadder" "normalmapadder_binormals_vs" "normalmapadder_binormals_ps"

### Ocean Shader ###

compile_pass "ocean" "far_vs" "far_ps"
compile_pass "ocean" "near_vs" "near_ps"

### Particle Shader ###

compile_pass "particle" "normal_vs" "normal_ps"
compile_pass "particle" "blur_vs" "blur_ps"

### Prereflection Shader ###

compile_function "prereflection" "prereflection_vs" "vs_2_0"
compile_function "prereflection" "prereflection_fake_stencil_vs" "vs_2_0"
compile_function "prereflection" "prereflection_ps" "ps_2_0"

### Rain Shader ###

compile_pass "rain" "rain_vs" "rain_ps"

### Sample Shader ###

compile_pass "sample" "sample_vs" "sample_ps"

### Shadowquad Shader ###

compile_pass "shadowquad" "shadowquad_vs" "shadowquad_ps"

### Shield Shader ###

compile_pass "shield" "shield_vs" "shield_ps"

### Skyfog Shader ###

compile_pass "skyfog" "skyfog_vs" "skyfog_ps"

### Sprite Shader ###

compile_pass "sprite" "sprite_vs" "sprite_ps"

### Z-Prepass Shader ###

compile_function "zprepass" "opaque_hard_skinned_vs" "vs_2_0"
compile_function "zprepass" "opaque_soft_skinned_vs" "vs_2_0"
compile_function "zprepass" "opaque_unskinned_vs" "vs_2_0"
compile_function "zprepass" "hardedged_hard_skinned_vs" "vs_2_0"
compile_function "zprepass" "hardedged_soft_skinned_vs" "vs_2_0"
compile_function "zprepass" "hardedged_unskinned_vs" "vs_2_0"
compile_function "zprepass" "opaque_ps" "ps_2_0"
compile_function "zprepass" "hardedged_ps" "ps_2_0"

foreach ($file in Get-ChildItem -File -Path build\templates\* -Include *.xml.template)
{
   $name = $file.Name -replace ".xml.template", ""

   instantiate_template $name
}