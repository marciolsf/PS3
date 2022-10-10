[cmdletbinding()]
param
(# Root folder for your USRDIR path
    [Parameter(Mandatory)][string]$root_folder,
    [Parameter()][switch]$Check_Scene,
    [Parameter()][switch]$Check_SDC,
    [Parameter()][switch]$Crawl_Scene_Assets,
    [Parameter()][switch]$Check_Game_Objects,
    [Parameter()][switch]$Check_Objects,
    [Parameter()][switch]$Print_Found_Assets
)


#$root_folder = "C:\bin\homeclient\NPIA00010\NPIA00010\USRDIR"
$Scene_Found

[xml]$base_home = get-content C:\Users\iamma\source\repos\PS3\ps3home\LOCALSCENELIST_BASIC.XML
[xml]$object_catalogentry
#$object_root = "$($root_folder)\objects"

$total = $base_home.SCENELIST.scene.count
$i = 1
$y = 1
[int32]$pctg = 0
$AllMessages = ""
#$clothing = ""
#$entitlements = ""
#$mini_games = ""
#$Printed_Game_Error_Already = $false


foreach ($base_scene in $base_home.SCENELIST.scene) {
    $ScenePath = "$($root_folder)\$($base_scene.config)"

    $pctg = (($i / $total) * 100)#.ToInt16()
    #write-host "$($pctg) -- $($i) -- $($total)" -ForegroundColor red
    #write-host $i

    Write-Progress -id 1 -Activity "Checking scenes" -Status "$($base_scene.name)" -PercentComplete $pctg

    $Printed_Scene_Error_Already = $false
    
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
                $games = $s.game.gameObjectFolder.GameObject#.folder.gameObject
                $Printed_Game_Error_Already = $false
                foreach ($gameObject in $games) {
                    #the gameID attribute maps to a folder under the usrdir\objects folder
                    $GameID = $gameObject.game
                    $game_objects_path = "$($root_folder)\objects\$($GameID)"
                    #does the resources.xml file exist?
                    if (Test-Path "$($game_objects_path)\resources.xml") {
                        
                        #the resources.xml file describes all the contents of the Game
                        <#Every resource has 4 main components:

                        * model
                        * particle
                        * collision
                        * lua
                        
                        Each of these has a file="" attribute, and we need to map each of them to their own collection 
                        in order to parse them

                        #>
                        
                        [xml]$game_resources = get-content "$($game_objects_path)\resources.xml"
                        foreach ($resource in $game_resources) {
                            $models = $resource.resources.local.model
                            $particles = $resource.resources.local.particle
                            $collisions = $resource.resources.local.collision
                            $lua = $resource.resources.local.lua
                            foreach ($m in $models) {                            
                                if (-not(Test-Path -Path "$($root_folder)\$($m.file)" )) { 
                                    $notfound += "$($m.name) -- $($m.file)" | Out-String
                                }
                            }
                            foreach ($p in $particles) {
                                if (-not(Test-Path -Path "$($root_folder)\$($p.file)" )) { 
                                    $notfound += "$($p.name) -- $($p.file)" | Out-String
                                }                                
                            }
                            foreach ($c in $collisions) {
                                if (-not(Test-Path -Path "$($root_folder)\$($c.file)" )) { 
                                    $notfound += "$($c.name) -- $($c.file)" | Out-String
                                }                                                                
                            }
                            foreach ($l in $lua) {
                                if (-not(Test-Path -Path "$($root_folder)\$($l.file)" )) {  
                                    $notfound += "$($l.name) -- $($l.file)" | Out-String
                                }                                
                            }
                        }
                    }
                    elseif ($null -eq $GameID) { #The scene did not have a game attribute, or the attribute was null
                        #if ($null -eq $GameID ) {Write-Host "GameID is Null" -ForegroundColor Red}
                        #write-host "Objects folder $($game_objects_path) for $($base_scene.config) not found" -ForegroundColor Red
                        #if ($Printed_Game_Error_Already = $false) {
                            $objectFolderNotFound += "The $($base_scene.name) did not have a game UUID" | Out-String
                            #$Printed_Game_Error_Already = $true
                        #} #else {Write-Host "derp"}
                    }
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
                    
                        if ($Printed_Scene_Error_Already -eq $false) {
                            $AllMessages += "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" | Out-String
                            $AllMessages += " Scene file $($base_scene.name) located at $($base_scene.config)" | Out-String
                            $AllMessages += "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" | Out-String
                            $Printed_Scene_Error_Already = $true
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

if ($Check_Objects) {
    $object_folders = Get-ChildItem "$($root_folder)\objects" -Directory
    $total_folders = $object_folders.count
    foreach ($o_folder in $object_folders) {
        #write-host $o_folder.FullName -ForegroundColor Green
        $pctg2 = (($y / $total_folders) * 100)
        Write-Progress -id 2 -Activity "Checking Objects" -Status "$($o_folder.name)" -PercentComplete $pctg2
        $o_path = Get-ChildItem $o_folder.FullName
        foreach ($file in $o_path) {
            
            if ($file.Name -eq "CATALOGUEENTRY.XML") {
                #write-host $file.Name
                [xml]$object_catalogentry = Get-Content $file.FullName
                foreach ($o in $object_catalogentry) {
                    <#
                    $clothing += $o.object.clothing | Out-String
                    $entitlements += $o.object.entitlement_id | Out-String
                    $mini_games += $o.object.mini_game  | Out-String
                    #>
                }
            }
        }

        $y = $y + 1
    }
}

if ($AllMessages.Length -gt 0 -or $notfound.Length -gt 0 -or $objectFolderNotFound.Length -gt 0) {
    Write-Host "The following errors were detected:"
    
    if ($AllMessages.Length -gt 0) {
        write-host $AllMessages
    }
    else {
        
        write-host "No Scene errors found" -ForegroundColor Green
    }
    if ($notfound.Length -gt 0) {
        write-host $notfound 
    }
    else {
        write-host "No game object errors found." -ForegroundColor Green
    }

    if ($objectFolderNotFound.Length -gt 0) {
        write-host $objectFolderNotFound
    }
    else {
        write-host "All game object folders found." -ForegroundColor Green
    }

}


<#
write-host "clothing $($clothing.count)"
write-host "entitlements $($entitlements.count)"
write-host "mini_games $($mini_games.count)"
#>