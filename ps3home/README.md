**SceneTool.ps1**

The SceneTool.ps1 script crawls through a Playstation Home folder and reports everything that is missing (files, assets, etc).

How to get started:

Simply download this script to your prefered location! Then start a powershell session, and run the script. The following parameters are required:

* $Root_folder: The location of your unpacked USRDIR folder
* $SceneListFilePath: The location of your LOCALSCENELIST.XML file

For example:

 .\SceneTool.ps1 -root_folder "C:\bin\homeclient\NPIA00010\NPIA00010\USRDIR" -SceneListFilePath "C:\bin\homeclient\NPIA00010\NPIA00010\USRDIR\ENVIRONMENTS\LOCALSCENELIST.XML"

The following parameter is optional:
* $Print_Found_Assets -- This reports everything that was found, along with everything that wasn't.


**HomeRenamer.ps1**

When building your own Playstation Home package, you have to make sure that all objects/paths/EVERYTHING is upper case. The HomeRenamer.ps1 script does all the renaming for you! The following parameters are required:

* $RootHome -- The location of your USRDIR folder (just like with SceneTool.ps1)
* $DoFiles -- Set this to make changes to FILES only
* $DoFolders -- Rename folders as well

**DockerFile**

This was an experiment on making the pkg file via a docker web container, instead of copying the whole 20GB pkg file in your ps3, and then installing everything (a nearly 2 hour process!). This is usefull if you are having problems sending a large package via FTP or USB. Note it doesn't make installation faster, it just saves the time to copy the package to the PS3 itself.

**1.86 fixes**

Fixes specific to this build