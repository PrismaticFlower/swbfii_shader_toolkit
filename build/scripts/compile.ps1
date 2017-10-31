.\build\scripts\compile_helpers.ps1


### Flare Shader ###

compile_pass "flare" "flare_textured_vs" "flare_textured_ps"
compile_pass "flare" "flare_untextured_vs" "flare_untextured_ps"

### Interface Shader ###

compile_pass "interface" "masked_bitmap_vs" "masked_bitmap_ps"
compile_pass "interface" "vector_vs" "vector_ps"
compile_pass "interface" "bitmap_untextured_vs" "bitmap_untextured_ps"
compile_pass "interface" "bitmap_textured_vs" "bitmap_textured_ps"

### Lightbeam Shader ###

compile_pass "lightbeam" "lightbeam_vs" "lightbeam_ps"

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

   process_template $name
}