.\build\scripts\compile_helpers.ps1


### Rain Shader ###

compile_pass "rain" "rain_vs" "rain_ps"

$shader = start_xml_shader "rain"   

$shader += start_shader_state 0
$shader += add_state_pass "rain" "rain_vs" "rain_ps"
$shader += end_shader_state

$shader += end_xml_shader

$shader | Out-File -Encoding utf8 ".\build\xml\rain.xml"


### Shadowquad Shader ###

compile_pass "shadowquad" "shadowquad_vs" "shadowquad_ps"

$shader = start_xml_shader "shadowquad"  

$shader += start_shader_state 0
$shader += add_state_pass "shadowquad" "shadowquad_vs" "shadowquad_ps"
$shader += end_shader_state

$shader += end_xml_shader

$shader | Out-File -Encoding utf8 ".\build\xml\shadowquad.xml"

### Interface Shader ###

compile_pass "interface" "masked_bitmap_vs" "masked_bitmap_ps"
compile_pass "interface" "vector_vs" "vector_ps"
compile_pass "interface" "bitmap_untextured_vs" "bitmap_untextured_ps"
compile_pass "interface" "bitmap_textured_vs" "bitmap_textured_ps"

$shader = start_xml_shader "interface"

$shader += start_shader_state 0
$shader += add_state_pass "interface" "masked_bitmap_vs" "masked_bitmap_ps"
$shader += end_shader_state

$shader += start_shader_state 1
$shader += add_state_pass "interface" "vector_vs" "vector_ps"
$shader += end_shader_state

$shader += start_shader_state 2
$shader += add_state_pass "interface" "bitmap_untextured_vs" "bitmap_untextured_ps"
$shader += end_shader_state

$shader += start_shader_state 3
$shader += add_state_pass "interface" "bitmap_textured_vs" "bitmap_textured_ps"
$shader += end_shader_state

$shader += end_xml_shader

$shader | Out-File -Encoding utf8 ".\build\xml\interface.xml"