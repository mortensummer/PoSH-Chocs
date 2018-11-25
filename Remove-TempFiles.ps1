<#
.SYNOPSIS
Remove-TempFiles.ps1 - Removes Temporary files from file path

.DESCRIPTION 
This PowerShell script will recursively remove all structural analysis temporary files from a folder path. It has options to remove
Revit temporary files also. 

.PARAMETER Path
Path to run script against. Can be UNC or local

.PARAMETER IncludeRevitBackups
Switch to look for Revit backup files

.PARAMETER LogFile
 Where to record the results to

.PARAMETER Commit
Setting this parameter to True will remove all temporary files found. By default, temporary files will only be logged. 

.EXAMPLE
.\Remove-TempFiles.ps1 -path C:\Work -logfile C:\scripts\logoutput.log
Will search for all temporary files within C:\Work, and will record that they exist in the log file, but will not remove them. 

.EXAMPLE
.\Remove-TempFiles.ps1 -path C:\Work -logfile C:\scripts\logoutput.log -Commit
Will search for all temporary files within C:\Work, and will record that they exist in the log file and WILL remove them.

.EXAMPLE
.\Remove-TempFiles.ps1 -path C:\Work -IncludeRevitBackups -logfile C:\scripts\logoutput.log -Commit
Will search for all temporary files and Revit Backup Files within C:\Work, and will record that they exist in the log file and WILL remove them.

.NOTES
Written by: Tom Yates

Change Log
V1.10, 24/11/2018 - Updated to use System32.IO.FileInfo Delete method and single output of removed files. 
V1.00, 01/11/2018 - Initial version
#>

[CmdletBinding()]
param (
    [Parameter( Mandatory = $true )]
    [string]$Path,

    [Parameter( Mandatory = $false )]
    [switch]$IncludeRevitBackups,

    [Parameter( Mandatory = $true )]
    [string]$LogFile,

    [Parameter( Mandatory = $false )]
    [switch]$Commit = $false    
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

If ($Commit) {Write-LogFile "Commit Flag is set to TRUE. Files will be removed"}
Write-LogFile "Temp extensions are :$Extensions"
Write-LogFile "Temp files are :$TempFiles"

If ($IncludeRevitBackups){
    Write-LogFile "Include Revit Backups flag is set to TRUE. These files will be found (and removed if commit flag is TRUE)."
    try {   
        $files = (Get-ChildItem -Path $Path -recurse -ErrorAction stop).where{
            ($_.Extension -in $Extensions) -or
            ($_.Name -in $TempFiles) -or
            ($_.Extension -match $RevitTempExtension)
            }

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
        $files = (Get-ChildItem -Path $Path -recurse -ErrorAction stop).Where{
            ($_.Extension -in $Extensions) -or `
            ($_.Name -in $TempFiles)
            }   
            
        $TotalSize = Convert-Size(($files | Measure-Object -Sum Length).Sum)
        Write-LogFile "Total temporary files to remove :$TotalSize"
    }
    catch{
        $ErrorMessage = $_.Exception.Message
        Write-LogFile "Could not access $Path. Quitting."
        Write-Logfile "Error message was :$ErrorMessage"
    }
}

If ($Commit) {
    ForEach ($file in $files){
        $FullPath = $file.FullName
        Try{
            [System.IO.File]::Delete($file.FullName)
            #Remove-Item $file.FullName -ErrorAction Stop
            Write-LogFile "Removing $FullPath"
        }
        Catch{
            $ErrorMessage = $_.Exception.Message
            Write-LogFile "Unable to remove :$FullPath"
            Write-Logfile "Error message was :$ErrorMessage"
        }
    }
}else{
    Write-LogFile "Found, but NOT removing following files: $FullPath"
    $files.FullName | Out-File -FilePath $LogFile -Append
}
Write-Logfile "Process Complete."