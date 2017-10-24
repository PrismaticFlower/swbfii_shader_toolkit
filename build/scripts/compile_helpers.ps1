function global:compile_pass($shader, $vs_func, $ps_func)
{
    fxc /nologo /T vs_2_0 /E $vs_func /Fc "build/asm/${shader}_${vs_func}.asm" /O3 src/$shader.fx
    fxc /nologo /T ps_2_0 /E $ps_func /Fc "build/asm/${shader}_${ps_func}.asm" /O3 src/$shader.fx
}

function global:load_asm_shader ($path, $type)
{
    $body = Get-Content -Raw $path

    $body -replace $type, ""
}

function global:start_xml_shader ($rendertype, $skinned)
{
    '<?xml version="1.0" encoding="utf-8" ?><shader rendertype="' + $rendertype + '" skinned="' + $skinned + '" debuginfo="no"><pipeline id="2">' 
}

function global:end_xml_shader 
{
    '</pipeline></shader>'
}

function global:start_shader_state ([int] $index)
{
    '<state id="' + $index + '">' 
}

function global:end_shader_state 
{
    '</state>'
}

function global:add_state_pass ($shader, $vs_func, $ps_func)
{
    $pass_body = '<pass transform="none" lighting="none"><vertexshader target="vs_2_0">!VS_BODY!</vertexshader><pixelshader target="ps_2_0">!PS_BODY!</pixelshader></pass>';

    $vs_body = load_asm_shader "build/asm/${shader}_${vs_func}.asm" "vs_2_0"
    $ps_body = load_asm_shader "build/asm/${shader}_${ps_func}.asm" "ps_2_0"

    $pass_body =  $pass_body -replace "!VS_BODY!", $vs_body
    $pass_body -replace "!PS_BODY!", $ps_body
}