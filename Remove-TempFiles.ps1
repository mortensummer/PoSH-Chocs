<#
.SYNOPSIS
Remove-TempFiles.ps1 - Removes all temporary files from given path.

.DESCRIPTION 
This PowerShell script will remove all known temporary files from a given path.
Primarily these are structural engineering analysis temporary files and\or Autodesk temp working files.

.OUTPUTS
Results are output to a text log file.

.PARAMETER Path
The path on which to find and remove all files. 

.PARAMETER RevitBackups
Specifies that it should also search for Revit Backup files

.PARAMETER LogFile
Specifies the log file for recording it's output.

.PARAMETER RemoveFiles
Should this option be set to True, then the files will be removed.

.EXAMPLE
.\Remove-TempFiles.ps1 -path \\server\jobs -logfile c:\logs\output.log
This will find all temporary files in \\server\jobs, record the actions to c:\logs\output.log, but will not 
remove the files. 

.EXAMPLE
.\Remove-TempFiles.ps1 -path \\server\jobs -logfile c:\logs\output.log -RevitBackups $true
This will find all temporary files, including Revit Backups in \\server\jobs, record the actions to 
c:\logs\output.log, but will not remove the files. 

.EXAMPLE
.\Remove-TempFiles.ps1 -path \\server\jobs -logfile c:\logs\output.log -RemoveFiles $true
This will find all temporary files, record the actions to c:\logs\output.log, and will remove the files. 

.NOTES
Written by: Tom Yates

Change Log
V1.00, 12/11/2018 - Initial version
#>

[CmdletBinding()]
param (
    [Parameter( Mandatory = $true )]
    [string]$Path,

    [Parameter( Mandatory = $false )]
    [bool]$RevitBackups,

    [Parameter( Mandatory = $true )]
    [string]$LogFile,

    [Parameter( Mandatory = $false )]
    [bool]$RemoveFiles = $false    
)

$Extensions = ".tmp",".bak",".sbk",'.$2k',".pcp",".err",".f1",".f3",".fun",".id",".jcj",".jct",".k~0",".k1",".k3",".k4",".l3",".lbl",".lbm",".m1",".m3",".m4",".msh",".mtl",".out",".p3",".p4",".rsi",".sec",".sev",".job",".log",".scp",".xmj",".xyz"
$TempFiles = "thumbs.db","plot.err"
$RevitTempExtension = "\.\d\d\d\d\.rvt"

$timestamp = Get-Date -DisplayHint Time
"$timestamp Process Starting..." | Out-File $LogFile
Function Write-LogFile() {
    param( $logentry )
    $timestamp = Get-Date -DisplayHint Time
    "$timestamp $logentry" | Out-File $LogFile -Append
}

#Make the total size readable in the log file
function Convert-Size{
    param([double]$totalSize)
    switch($totalSize){
        {$_ -ge 1000000000} {$Divider = "1GB"; $Metric = "Gb" }
        {$_ -le 1000000000} {$Divider = "1MB"; $Metric = "Mb"  }
        {$_ -le 1000000} {$Divider = "1KB"; $Metric = "Kb"  }
        {$_ -le 1000} {$Divider = "1B"; $Metric = "b" }
    }
    return -join ([math]::round($totalsize /$Divider,3),"$Metric")
}

If ($RemoveFiles) {Write-LogFile "Remove Files Flag is set to TRUE."}
Write-LogFile "Temp extensions are :$Extensions"
Write-LogFile "Temp files are :$TempFiles"

If ($RevitBackups){
    Write-LogFile "Finding Revit backups - Flag is set to TRUE."
    try {   
        $files = Get-ChildItem -Path $Path -recurse -ErrorAction stop | Where-Object {`
            ($_.Extension -in $Extensions) -or `
            ($_.Name -in $TempFiles) -or `
            ($_.Extension -match $RevitTempExtension)}

        $TotalSize = Convert-Size(($files | Measure-Object -Sum Length).Sum)
        Write-LogFile "Total temporary files to remove :$TotalSize"
    }
    catch{
        $ErrorMessage = $_.Exception.Message
        Write-LogFile "Could not access $Path. Quitting."
        Write-Logfile "Error message was :$ErrorMessage"
    }
}else{
    try{
        $files = Get-ChildItem -Path $Path -recurse -ErrorAction stop | Where-Object {`
            ($_.Extension -in $Extensions) -or `
            ($_.Name -in $TempFiles)}   
            
        $TotalSize = Convert-Size(($files | Measure-Object -Sum Length).Sum)
        Write-LogFile "Total temporary files to remove :$TotalSize"
    }
    catch{
        $ErrorMessage = $_.Exception.Message
        Write-LogFile "Could not access $Path. Quitting."
        Write-Logfile "Error message was :$ErrorMessage"
    }
}

If ($RemoveFiles) {
    ForEach ($file in $files){
        $FullPath = $file.FullName
        Try{
            Remove-Item $file.FullName -ErrorAction Stop
            Write-LogFile "Removing $FullPath"
        }
        Catch{
            $ErrorMessage = $_.Exception.Message
            Write-LogFile "Unable to remove :$FullPath"
            Write-Logfile "Error message was :$ErrorMessage"
        }
    }
}else{
    ForEach ($file in $files){
        $FullPath = $file.FullName
            Write-LogFile "Found, but NOT removing: $FullPath"
    }
}
Write-Logfile "Process Complete."