foreach ($file in Get-ChildItem -File -Path build\xml\* -Include *.xml)
{
   $outname = $file.Name -replace ".xml", ".shader"

   Write-Host Munging $file.Name

   pc_shadercompiler $file.FullName "build\munged\$outname" -I "build\headers\"
}

levelpack -inputfile "build/core.req" -sourcedir "build/premunged/" "build/munged/"