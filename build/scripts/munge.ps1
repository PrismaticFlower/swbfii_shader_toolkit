function global:shader_needs_munging($file)
{

    $checksum_path = "$file.checksum"

    $result = $true
    $hash = (Get-FileHash -Path $file -Algorithm MD5).hash

    if (Test-Path -Path $checksum_path) 
    {
        $result = ((Get-Content -Raw $checksum_path) -ne $hash)
    }

    $hash | Out-File -NoNewline -Encoding utf8 $checksum_path

    $result
}


foreach ($file in Get-ChildItem -File -Path build\xml\* -Include *.xml)
{
    if (-not (shader_needs_munging $file)) { continue }

   $outname = $file.Name -replace ".xml", ".shader"

   Write-Host Munging $file.Name

   pc_shadercompiler $file.FullName "build\munged\$outname" -I "build\headers\"
}

levelpack -inputfile "build/core.req" -sourcedir "build/premunged/" "build/munged/"