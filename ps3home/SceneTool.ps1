param
(# Root folder for your USRDIR path
    [Parameter()][string]$root_folder,
    [Parameter()][switch]$Check_Scene,
    [Parameter()][switch]$Check_SDC,
    [Parameter()][switch]$Crawl_Scene_Assets,
    [Parameter()][switch]$Check_Game_Objects,
    [Parameter()][switch]$Print_Found_Assets
)


#$root_folder = "C:\bin\homeclient\NPIA00010\NPIA00010\USRDIR"
$Scene_Found

[xml]$base_home = get-content C:\Users\iamma\source\repos\PS3\ps3home\LOCALSCENELIST_BASIC.XML

$total = $base_home.SCENELIST.scene.count
$i = 1
[int32]$pctg = 0
$AllMessages = ""
foreach ($base_scene in $base_home.SCENELIST.scene) {
    $ScenePath = "$($root_folder)\$($base_scene.config)"

    $pctg = (($i / $total) * 100)#.ToInt16()
    #write-host "$($pctg) -- $($i) -- $($total)" -ForegroundColor red
    #write-host $i

    Write-Progress -Activity "Checking scenes" -Status "$($base_scene.name)" -PercentComplete $pctg

    $Printed_Error_already = $false
    
    <# The -replace function works recursively, replacing all instances of the SCENE word, instead of just .SCENE
    Some scenes have the worde SCENE as part of the name, besides the extension, so here we just the .replace method instead
    #>

    if ($Check_Scene) {
        if (-not (Test-Path -path $ScenePath)) { 
            $AllMessages += "****** Scene file $($ScenePath) not found" | Out-String
            $Scene_Found = $false
        }
        else {
            if ($Print_Found_Assets) {
                Write-Host "Scene file $($ScenePath) found" -ForegroundColor Blue
            }
            $Scene_Found = $true
        }
    }


    if ($Check_SDC) {
        $SDCPath = $ScenePath.Replace(".scene", ".SDC")
        if (-not(Test-Path -Path $SDCPath)) {
            write-verbose "Testing $($SDCPath)"
            $AllMessages += "****** SDC file $($SDCPath) not found" | Out-String
        }
        else {
            Write-Verbose "SDC File $($SDCPath) found"
        }
    }

    #only crawl the scene if the scene file was found.
    if ($Scene_Found) {
        [xml]$SceneFile = Get-Content $ScenePath 

        if ($Check_Game_Objects) {
            foreach ($s in $SceneFile) {
                $games = $s.game.gameObjectFolder.GameObject
                foreach ($gameObject in $games) {
                    write-host $base_scene.config -ForegroundColor Blue
                    write-host "Game Name: $($gameObject.name) -- Game Object type: $($gameObject.Type) -- Game ID: $($gameObject.game) -- GameName (Internal?): $($gameObject.gameName) -- UUID: $($gameObject.UUID)" -ForegroundColor Green
                }
            }

        }
        if ($Crawl_Scene_Assets) {                                
            foreach ($s in $SceneFile) {
                $Assets = $s.game.assetFolder.asset

                foreach ($asset in $assets) {
                    <#  The source attribute of the asset element indicates the location of the file.
                            There's no consistency on how that's declared -- The following are all valid
                            source="file:///resource_root/Build/environments -- notice the 3 slashes
                            source="file://resource_root/Build/environments -- only 2 slashes
                            source="environments/ -- no file prefix at all

                            Some scenes are stored outside of build/environments (straight on the root), and that's ok! 
                            But we still need to replace the path so we can validate
                            source="file:///resource_root/CasinoMain/

                            In all instances, the environments folder is under USRDIR, which is the true "Root" for the package. 
                            For our path validator, we just need to replace the root references to something windows can understand

                            First I add the root folder to any attributes that don't have it
                            Then I replace 3 slashes to only 2 slashes
                        #>

                    $path = $asset.source
                    $name = $asset.name        
                
                    if ($path -inotlike "file*") {
                        $path = "$($root_folder)/$($path)"
                    }   
                
                
                    if ($path -inotlike "*build/environments*") {
                        $path = $path -replace ("file://resource_root/", "$($root_folder)/")
                    }             

                    $path = $path -replace ("file:///", "file://")
                    $path = $path -Replace ("file://resource_root/build/", "$($root_folder)/") 
                        
                    if (-not(Test-Path -Path $path)) {
                    
                        if ($Printed_Error_already -eq $false) {
                            $AllMessages += "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" | Out-String
                            $AllMessages += " Scene file $($base_scene.name) located at $($base_scene.config)" | Out-String
                            $AllMessages += "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" | Out-String
                            $Printed_Error_already = $true
                        }
                        $AllMessages += "------ Asset name=$($name) not found at: $($path)" | Out-String
                    }
                    else { 
                        if ($Print_Found_Assets) {        
                            write-host "++++++  Asset name=$($name) found at: $($path)" -ForegroundColor Green
                        }
                    }
                }
                    
            }
        }
    }
    $i = $i + 1
}

Write-Host "The following errors were detected:"
write-host $AllMessages

