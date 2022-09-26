param
(# Root folder for your USRDIR path
    [Parameter()][string]$root_folder,
    [Parameter()][switch]$Check_Scene,
    [Parameter()][switch]$Check_SDC,
    [Parameter()][switch]$Crawl_Scene_Assets,
    [Parameter()][switch]$Print_Found_Assets
)


#$root_folder = "C:\bin\homeclient\NPIA00010\NPIA00010\USRDIR"
$Scene_Found

[xml]$base_home = get-content C:\Users\iamma\source\repos\PS3\ps3home\LOCALSCENELIST_BASIC.XML

#$Check_Scene = $true
#$Check_SDC = $true
#$Crawl_Scene_Assets = $true

foreach ($c in $base_home.SCENELIST.scene) {
    Write-Host "Checking Scene [$($c.name)] on [$($c.config)]..." -ForegroundColor White

    $ScenePath = "$($root_folder)\$($c.config)"
    
    <#using the -replace function works recursively, replacing all instances of the SCENE word, instead of just .SCENE
    So here we just the .replace method instead
    #>

    if ($Check_Scene) {
        if (-not (Test-Path -path $ScenePath)) { 
            Write-Host "Scene file not found --> $($ScenePath)" -ForegroundColor Red 
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
            write-host "SDC file not found --> $($SDCPath)" -ForegroundColor Red
        }
        else {
            Write-Verbose "SDC File $($SDCPath) found"
        }
    }

    #only crawl the scene if the scene file was found.
    if ($Crawl_Scene_Assets -and $Scene_Found) {
        
        [xml]$SceneFile = Get-Content $ScenePath 
            
        foreach ($a in $SceneFile) {
            $Assets = $a.game.assetFolder.asset

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
                #write-host "**** Original path $($path)" -ForegroundColor White
                
                if ($path -inotlike "file*") {
                    $path = "$($root_folder)/$($path)"
                    #write-host "**** Original path $($path)" -ForegroundColor DarkGray
                    #write-host $path -ForegroundColor blue
                }   
                
                
                if ($path -inotlike "*build/environments*") {
                    $path = $path -replace ("file://resource_root/", "$($root_folder)/")
                    #write-host "****** Replaced path $($path)" -ForegroundColor DarkYellow
                }             

                $path = $path -replace ("file:///", "file://")
                $path = $path -Replace ("file://resource_root/build/", "$($root_folder)/") 
                        
                if (-not(Test-Path -Path $path)) {
                    write-host "------ Asset name=$($name) not found at: $($path)" -ForegroundColor Red
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

