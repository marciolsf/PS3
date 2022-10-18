The SceneTool.ps1 script crawls through a Playstation Home folder and reports everything that is missing (files, assets, etc).

How to get started:

Simply download this script to your prefered location! Then start a powershell session, and run the script. The following parameters are required:

* Root_folder: The location of your unpacked USRDIR folder
* SceneListFilePath: The location of your LOCALSCENELIST.XML file

For example:

 .\SceneTool.ps1 -root_folder "C:\bin\homeclient\NPIA00010\NPIA00010\USRDIR" -SceneListFilePath "C:\bin\homeclient\NPIA00010\NPIA00010\USRDIR\ENVIRONMENTS\LOCALSCENELIST.XML"

The following parameter is optional:
* Print_Found_Assets -- This reports everything that was found, along with everything that wasn't.

