param(
    [Parameter()]$RootHome,
    [parameter()][switch]$DoFiles,
    [parameter()][switch]$DoFolders
)

if ($DoFiles){
$files = Get-ChildItem $RootHome -Recurse -File
foreach ($f in $files) {
    #Rename-Item -Path $f -NewName {$_.Name -replace $_.Name.ToUpper()}
    #write-host "Renaming $($f.FullName) to uppercase"
    rename-item -path $f.FullName -NewName $f.Name.ToUpper()
}}

if ($DoFolders){
$dirs = Get-ChildItem $RootHome -Recurse -Directory
foreach ($d in $dirs) {
    #Rename-Item -Path $f -NewName {$_.Name -replace $_.Name.ToUpper()}
    #write-host "Renaming $($d.FullName) to uppercase"
    rename-item -path $d.FullName -NewName "$($d.FullName)-temp" -PassThru | rename-item -NewName $d.Name.ToUpper()
}}