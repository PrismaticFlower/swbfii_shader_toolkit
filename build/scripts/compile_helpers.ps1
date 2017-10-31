function global:compile_function($shader, $func_name, $profile)
{
    Write-Host "Compiling build\asm\${shader}_${func_name}.asm"

    $function = fxc /nologo /T $profile /E $func_name /Cc /Zi /O3 src/$shader.fx

    # Clean string so it is safe to pass through the munger.
    $function = $function -replace $profile, ""
    $function = $function -replace "#line", "// line"
    $function = $function -replace "<", "("
    $function = $function -replace ">", ")"

    $function | Out-File -Encoding utf8 "build\asm\${shader}_${func_name}.asm"
}

function global:compile_pass($shader, $vs_func, $ps_func)
{
    compile_function $shader $vs_func "vs_2_0"
    compile_function $shader $ps_func "ps_2_0"
}

function global:instantiate_template($name)
{
    Write-Host "Instantiating ${name}.xml.template"

    $template = Get-Content -Raw "build\templates\${name}.xml.template"

    $tokens = Select-String "~.+?~" -input $template -AllMatches

    ForEach ($token in $tokens.matches)
    {
       $func = $token -replace "~", ""
    
       $asm = Get-Content -Raw "build\asm\${name}_${func}.asm"
       $template = $template -replace $token, $asm
    }

    $template | Out-File -Encoding utf8 ".\build\xml\$name.xml"
}