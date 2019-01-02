# PoSH-Chocs
Scripts as part of my own Powershell learning that may help others. YMMV.

The scripts here are not perfect in anyway, but they are what I've created as part of tasks in my day job that needed to be automated
or processes that needed to be done. I fully understand that there maybe quicker or more efficent ways to do what I've done in my
scripts! Feel free to reach out and let me know!

## Get-MARSAgent.ps1

Until the Microsoft Azure Recovery Services Agent has an automatic update, I wrote this script to solve the issue for me. It will get the latest MARS Agent, and compare to an existing .exe on the network. If its newer, it will replace it and send me an email. 

I use Lansweeper (http://www.lansweeper.com) and it contains a repository of software installations, in which this .exe is part of. This IT respository is distributed to all geographic locations (including Azure) using Distributed Filing System (DFS). Once the installation file has been updated, its a few seconds to push the update out via Lansweeper Deployments to all servers that require it.

It is suggested that this process is scheduled on a weekly basis.

## Remove-TempFiles.ps1

Removes all temporary files from a specified file path. This was written to deal with the large quantity of temporary files created by SAP2000 Structural Engineering package, and Autodesk's various products such as AutoCAD (+ LT) and Revit.
Thanks to those over at Powershell.org for helping me improve it's efficiency.

## Extract-FreehandData.ps1

This script converts all patient data from an unloaded Freehand Clinic Manger Patient database into CSV format.

By default the patient data is stored in a file called adphsl.dat, which is a COBOL vision data file format.
In order for the script to extract the data correctly, it first must be unloaded into line sequential format.

    This can be achieved using the vutil32.exe command.
    Example: vutil32.exe -unload -t adphsl.dat adphsl.unloaded