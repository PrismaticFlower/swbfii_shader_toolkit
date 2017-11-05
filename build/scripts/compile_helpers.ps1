function global:function_needs_compiling($file_path, $test_aginst)
{
    $last_write = (Get-Item $file_path).LastWriteTime

    (Test-Path -Path $test_aginst -OlderThan $last_write) -or (-not (Test-Path -Path $test_aginst)) -or ((Get-Item $test_aginst).Length -eq 0)
}

function global:compile_function($shader, $func_name, $profile, 
                                 $skinned = $false, $lighting = $false)
{
    $transform_pass_defines = @('')
    $transform_pass_names = @('')

    if ($skinned -eq $true)
    {
        $tu = 'TRANSFORM_UNSKINNED'
        $tss = 'TRANSFORM_SOFT_SKINNED'
        $ths = 'TRANSFORM_HARD_SKINNED'

        $transform_pass_defines = "/D$tu", "/D$tss", "/D$ths"
        $transform_pass_names = '_unskinned', '_soft_skinned', '_hard_skinned'
    }
    
    $lighting_pass_defines = @('')
    $lighting_pass_names = @('')

    if ($lighting -eq $true)
    {
        $ld = 'LIGHTING_DIRECTIONAL'
        $lp_0 = 'LIGHTING_POINT_0'
        $lp_1 = 'LIGHTING_POINT_1'
        $lp_23 = 'LIGHTING_POINT_23'
        $ls = 'LIGHTING_SPOT_0'
        $ln = 'LIGHTING_NONE'

        $lighting_pass_defines = @("/D${ld}"),
        @("/D${ld}", "/D${lp_0}"),
        @("/D${ld}", "/D${lp_0}", "/D${lp_1}"),
        @("/D${ld}", "/D${lp_0}", "/D${lp_1}", "/D${lp_23}"), 
        @("/D${ld}", "/D${ls}"),
        @("/D${ld}", "/D${ls}", "/D${lp_0}"),
        @("/D${ld}", "/D${ls}", "/D${lp_0}", "/D${lp_1}"),
        @("/D${ln}")
                                 
        $lighting_pass_names = "_2d", "_2d1p", "_2d2p", "_2d4p", "_2d1s", "_2d1p1s", "_2d2p1s", ""
    }

    for ($i = 0; $i -lt $transform_pass_names.length; ++$i)
    {
        $transform_define = $transform_pass_defines[$i]
        $transform_name = $transform_pass_names[$i]

        for ($j = 0; $j -lt $lighting_pass_defines.length; ++$j)
        {
            $lighting_defines = $lighting_pass_defines[$j]
            $lighting_name = $lighting_pass_names[$j]

            $asm_path = "build\asm\${shader}_${func_name}${transform_name}${lighting_name}.asm"

            # skip compiling the function if it's been recently compiled.
            if (-not (function_needs_compiling "src/$shader.fx" $asm_path)) { continue };
            
            Write-Host "Compiling $asm_path"

            $function = fxc /nologo $lighting_defines $transform_define /T $profile /E $func_name /Cc /Zi /O3 src/$shader.fx

            if ($LASTEXITCODE -ne 0) 
            {
                throw "compilation failure!", "fxc /nologo $lighting_defines $transform_define /T $profile /E $func_name /Cc /Zi /O3 src/$shader.fx"
            }

            # Clean string so it is safe to pass through the munger.
            $function = $function -replace $profile, ""
            $function = $function -replace "#line", "// line"
            $function = $function -replace "<", "("
            $function = $function -replace ">", ")"

            $function | Out-File -Encoding utf8 "${asm_path}"
        }
    }
}

function global:compile_pass($shader, $vs_func, $ps_func, 
                             $skinned = $false, $lighting = $false)
{
    compile_function $shader $vs_func "vs_2_0" $skinned $lighting
    compile_function $shader $ps_func "ps_2_0" $skinned $lighting
}

function global:instantiate_transform($name)
{
@"          
#ifdef TRANSFORM_UNSKINNED
    ~${name}_unskinned~
#elif defined(TRANSFORM_SOFT_SKINNED)
    ~${name}_soft_skinned~
#elif defined(TRANSFORM_HARD_SKINNED)
    ~${name}_hard_skinned~
#endif
"@
}

function global:instantiate_lighting($name)
{
@"          
#ifdef LIGHTING_2D
    ~${name}_2d~
#elif defined(LIGHTING_2D1P)
    ~${name}_2d1p~
#elif defined(LIGHTING_2D2P)
    ~${name}_2d2p~
#elif defined(LIGHTING_2D4P)
    ~${name}_2d4p~
#elif defined(LIGHTING_2D1P1S)
    ~${name}_2d1p1s~
#elif defined(LIGHTING_2D2P1S)
    ~${name}_2d2p1s~
#elif defined(LIGHTING_2D1S)
    ~${name}_2d2p1s~
#else
    ~${name}~
#endif
"@
}

function global:instantiate_skinned_lighting($name)
{
$unskinned_lighting = instantiate_lighting ${name}_unskinned
$soft_skinned_lighting = instantiate_lighting ${name}_soft_skinned
$hard_skinned_lighting = instantiate_lighting ${name}_hard_skinned

@"
#ifdef TRANSFORM_UNSKINNED
${unskinned_lighting}
#elif defined(TRANSFORM_SOFT_SKINNED)
${soft_skinned_lighting}
#elif defined(TRANSFORM_HARD_SKINNED)
${hard_skinned_lighting}
#endif
"@
}

function global:instantiate_template($name)
{
    Write-Host "Instantiating ${name}.xml.template"

    $template = Get-Content -Raw "build\templates\${name}.xml.template"

    # instantiate transform definitions
    $tokens = Select-String "#.+?#" -input $template -AllMatches

    foreach ($token in $tokens.matches)
    {
       $func = $token -replace "#", ""
    
       $template = $template -replace $token, (instantiate_transform $func)
    }
    
    # instantiate lighting definitions
    $tokens = Select-String "@.+?@" -input $template -AllMatches

    foreach ($token in $tokens.matches)
    {
       $func = $token -replace "@", ""
    
       $template = $template -replace $token, (instantiate_lighting $func)
    }
    
    # instantiate transform lighting definitions
    $tokens = Select-String "%.+?%" -input $template -AllMatches

    foreach ($token in $tokens.matches)
    {
       $func = $token -replace "%", ""
    
       $template = $template -replace $token, (instantiate_skinned_lighting $func)
    }

    # instantiate functions
    $tokens = Select-String "~.+?~" -input $template -AllMatches

    foreach ($token in $tokens.matches)
    {
       $func = $token -replace "~", ""
    
       $asm = Get-Content -Raw "build\asm\${name}_${func}.asm"
       $template = $template -replace $token, $asm
    }

    $template | Out-File -Encoding utf8 ".\build\xml\$name.xml"
}