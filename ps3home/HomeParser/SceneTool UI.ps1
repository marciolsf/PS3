Add-Type -AssemblyName PresentationFramework
function Get-HomeErrors {
    [cmdletbinding()]
    param
    (
        # Root folder for your USRDIR path    
        [Parameter(Mandatory)][string]$root_folder, 
        # Location of your main LOCALSCENELIST.XML file (or equivalent)
        [Parameter()][string]$SceneListFilePath = '',
        [Parameter()][switch]$Print_Found_Assets
    )

    #Main config parameters
    $Check_Scene = $true #checks all scene files -- mandatory for all other actions besides SDC
    $Check_SDC = $true #chec
    $Crawl_Scene_Assets = $true #crawls each of the asset items in the .SCENE file
    $Check_Game_Objects = $true #crawls for each of the **linked** minigames from the .SCENE file
    $Check_All_Objects = $false #crawls through ALL folders in the OBJECTS folder. Not sure this is really needed, since in theory objects not linked are never used anyway.


    if ($SceneListFilePath -eq '') {
        $SceneListFilePath = "$($root_folder)\ENVIRONMENTS\LocalSceneList.xml"
    }

    if (-not (Test-Path $SceneListFilePath)) {
        Write-Host "`nSceneList.xml file not found at $($root_folder)\ENVIRONMENTS ! Please verify the file is present`n" -ForegroundColor Red
        exit
    }

    #[xml]$base_home = get-content C:\Users\iamma\source\repos\PS3\ps3home\LOCALSCENELIST_BASIC.XML
    #base variables
    [xml]$base_home = get-content $SceneListFilePath
    [xml]$object_catalogentry
    $total = $base_home.SCENELIST.scene.count
    $i = 1
    $y = 1
    [int32]$pctg = 0
    $SceneFileErrors = ""
    $Scene_Found

    <#
    $AllMessages = @(
        [pscustomobject]@{SceneFileErrors=''}
        [pscustomobject]@{MissingAssets=''}
        [pscustomobject]@{ObjectFolderNotFound=''}
        [pscustomobject]@{NotFound=''}
    )
    #>
    [hashtable]$AllMessages = @{}

    foreach ($base_scene in $base_home.SCENELIST.scene) {
        $ScenePath = "$($root_folder)\$($base_scene.config)"

        $pctg = (($i / $total) * 100)

        Write-Progress -id 1 -Activity "Checking scenes" -Status "$($base_scene.name)" -PercentComplete $pctg

        $Printed_Scene_Error_Already = $false
    
        <# The -replace function works recursively, replacing all instances of the SCENE word, instead of just .SCENE
    Some scenes have the worde SCENE as part of the name, besides the extension, so here we just the .replace method instead
    #>

        if ($Check_Scene) {
            if (-not (Test-Path -path $ScenePath)) { 
                $SceneFileErrors += "------ $($ScenePath)" | Out-String
                $Scene_Found = $false
            }
            else {
                if ($Print_Found_Assets) {
                    $foundStuff += "++++++ Scene file $($ScenePath) found" | Out-String
                }
                $Scene_Found = $true
            }
        }


        if ($Check_SDC) {
            $SDCPath = $ScenePath.Replace(".scene", ".SDC")
            if (-not(Test-Path -Path $SDCPath)) {
                $SceneFileErrors += "------ $($SDCPath)" | Out-String
            }
            else {
                if ($Print_Found_Assets) {
                    $foundStuff += "++++++ SDC File $($SDCPath) found" | Out-String
                }
            }
        }

        #only crawl the scene if the scene file was found.
        if ($Scene_Found) {
            [xml]$SceneFile = Get-Content $ScenePath 

            if ($Check_Game_Objects) {
                foreach ($s in $SceneFile) {
                    $children = $s.ChildNodes | Select-Object -ExpandProperty childnodes
                    #write-host $children.name
                    foreach ($c in $children) {
                        $subChild = $c.childnodes | Select-Object -ExpandProperty childnodes
                        foreach ($sc in $subChild) {
                            if ($null -ne $sc.game) {
                        
                                $game_objects_path = "$($root_folder)\objects\$($sc.game)"
                                if (test-path $game_objects_path) {
                                    if ($Print_Found_Assets) {
                                        $foundStuff += "++++++ Scene $($base_scene.name) ($($ScenePath)) contains [$($sc.game)] ($($sc.gameName))" | Out-String
                                    }
                                    #does the resources.xml file exist?
                                    if (Test-Path "$($game_objects_path)\resources.xml") {
                                    
                                        #the resources.xml file describes all the contents of the Game
                                        #Every resource has 4 main components:
            
                                        # * model
                                        # * particle
                                        # * collision
                                        # * lua
                                    
                                        #Each of these has a file="" attribute, and we need to map each attribute to their own collection, 
                                        #in order to parse them

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
                                }
                                else {
                                    $objectFolderNotFound += "------ Scene $($base_scene.name) ($($ScenePath)) missing [$($sc.game)] ($($sc.gameName))" | Out-String
                                }
                            }
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
                
                
                        if ($path -inotlike "*build/*") {
                            $path = $path -replace ("file://resource_root/", "$($root_folder)/")
                        }             

                        $path = $path -replace ("file:///", "file://")
                        Write-Verbose $path 
                        $path = $path -Replace ("file://resource_root/build/", "$($root_folder)/") 
                        write-verbose $path 
                        
                        if (-not(Test-Path -Path $path)) {
                    
                            if ($Printed_Scene_Error_Already -eq $false) {
                                #$SceneFileErrors += "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" | Out-String
                                #$SceneFileErrors += " Scene file $($base_scene.name) located at $($base_scene.config)" | Out-String
                                #$SceneFileErrors += "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" | Out-String
                                $Printed_Scene_Error_Already = $true
                            }
                            $missingAssets += "------ Scene $($base_scene.name) ($($base_scene.config)) missing asset name=$($name) ($($path))" | Out-String
                        }
                        else { 
                            if ($Print_Found_Assets) {        
                                $foundStuff += "++++++ Asset name=$($name) found at: $($path)" | Out-String
                            }
                        }
                    }
                    
                }
            }
        }
        $i = $i + 1
    }

    if ($Check_All_Objects) {
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
<#
    if ($SceneFileErrors.Length -gt 0 -or $notfound.Length -gt 0 -or $objectFolderNotFound.Length -gt 0 ) {
        Write-Host "`n`n`nThe following errors were detected:`n`n`n" -ForegroundColor White
    
        if ($SceneFileErrors.Length -gt 0) {
            write-host "The following scene/SDC files were not found:" -ForegroundColor White
            write-host $SceneFileErrors -ForegroundColor Red
        }
        else {        
            write-host "No Scene errors found" -ForegroundColor Green
        }

        if ($missingAssets.Length -gt 0) {
            write-host "The following asset objects are missing:" -ForegroundColor White
            write-host $missingAssets -ForegroundColor Red
        }
        else {
            write-host "No missing asset objects." -ForegroundColor Green
        }


        if ($objectFolderNotFound.Length -gt 0) {
            write-host "The following Object folders were not found:" -ForegroundColor White
            write-host $objectFolderNotFound -ForegroundColor Red
        }
        else {
            write-host "All game object folders found." -ForegroundColor Green
        }

        if ($notfound.Length -gt 0) {
            write-host "The following mini-game objects are missing:" -ForegroundColor White
            write-host $notfound -ForegroundColor Red
        }
        else {
            write-host "No mini-game object missing." -ForegroundColor Green
        }
    }

    if ($Print_Found_Assets) {
        write-host "`n `n `nThe following objects were found: " -ForegroundColor White
        write-host $foundStuff -ForegroundColor Green
    }

    #>
    #$returnArray = @($SceneFileErrors)

    $AllMessages.SceneFileErrors = $SceneFileErrors
    $AllMessages.MissingAssets = $missingAssets
    $AllMessages.ObjectFolderNotFound = $objectFolderNotFound
    $AllMessages.NotFound = $notfound

    return $AllMessages
}

$xamlFile = ".\HomeParser\MainWindow.xaml"

#create window
$inputXML = Get-Content $xamlFile -Raw
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[XML]$XAML = $inputXML

#Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load( $reader )
} catch {
    Write-Warning $_.Exception
    throw
}

# Create variables based on form control names.
# Variable will be named as 'var_<control name>'

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    #"trying item $($_.Name)"
    try {
        Set-Variable -Name "var_$($_.Name)" -Value $window.FindName($_.Name) -ErrorAction Stop
    } catch {
        throw
    }
}
Get-Variable var_*

$var_btnQuery.Add_Click( {
    #clear the result box
    $var_txtResults.Text = ""
        if ($result = Get-HomeErrors -root_folder $var_txtPath.Text) {
            foreach ($item in $result) {
                $var_txtResults.Text = $var_txtResults.Text + "Scene/SDC errors:`n $($item.SceneFileErrors)"
                $var_txtResults.Text = $var_txtResults.Text + "Missing Assets:`n $($item.MissingAssets)"
                $var_txtResults.Text = $var_txtResults.Text + "Object Folder not found:`n $($item.MissingAssets)"
                $var_txtResults.Text = $var_txtResults.Text + "Mini-game objects not found:`n $($item.MissingAssets)"
                
                #$var_txtResults.Text = $var_txtResults.Text + "VolumeName: $($item.VolumeName)`n"
                #$var_txtResults.Text = $var_txtResults.Text + "FreeSpace: $($item.FreeSpace)`n"
                #$var_txtResults.Text = $var_txtResults.Text + "Size: $($item.Size)`n`n"
            }
            #$var_txtResults.Text = $result
        }       
    })
 
 $var_txtPath.Text = "C:\bin\homeclient\Playstation_Home_v0.97_Demo_002\HOME00097\USRDIR"

$Null = $window.ShowDialog()