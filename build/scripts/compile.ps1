.\build\scripts\compile_helpers.ps1


### Rain Shader ###

compile_pass "rain" "rain_vs" "rain_ps"

$shader = start_xml_shader "rain" "no"   

$shader += start_shader_state 0

$shader += add_state_pass "rain" "rain_vs" "rain_ps"

$shader += end_shader_state

$shader += end_xml_shader

$shader | Out-File -Encoding utf8 ".\build\xml\rain.xml"