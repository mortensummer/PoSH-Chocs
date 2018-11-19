<#
.SYNOPSIS
Get-MARSAgent.ps1 - Downloads latest MARS Agent

.DESCRIPTION 
This PowerShell script will get the latest MARS Agent, and update a specific location if it is newer.

.PARAMETER SMTPServer
SMTP Server for email notification

.PARAMETER SendFrom
Email Address to send notification email from 

.PARAMETER SendTo
Email Address to send notification email from 

.EXAMPLE
.\Get-MARSAgent.ps1 -SMTPServer 127.0.0.1
Will check for latest MARS version, and send email via 127.0.0.1 SMTP Server. 

.NOTES
Written by: Tom Yates

Change Log
V1.00, 13/11/2018 - Initial version
#>
[cmdletbinding()]
    param(
        [Parameter( Mandatory = $true )]
        [string]$SMTPServer, 

        [Parameter(Mandatory = $true)]
        [string]$sendFrom = "alert@example.com",    ### UPDATE THIS EMAIL ADDRESS

        [Parameter(Mandatory = $true)]
        [string]$sendTo = "me@example.com"          ### UPDATE THIS EMAIL ADDRESS

    )

# Set this path to where Lansweeper gets its installation files from. 
# I'm using DFS to replicate my installations to all locations. 

$Domain = (Get-ADDomain).DNSRoot
$DFSDistPath = "\\$Domain\its\SoftwareDeployment\Microsoft\MARSAgent\"

$BackupFile = $DFSDistPath+"MARSAgentInstaller_PreviousVersion.exe"
$MARSExistingFile = $DFSDistPath+"MARSAgentInstaller.exe"
$MARSDownloadedFile = "$ENV:TEMP\MARSAgentInstaller-Downloaded.EXE"

Function Get-Version{
    param([string]$File)
    $FileInfo = Get-ItemProperty $File | Select-Object -Property VersionInfo
    return $FileInfo.VersionInfo.FileVersion
}

Try{
    Write-Verbose "Getting latest Agent..."
    $MarsAURL = 'http://Aka.Ms/Azurebackup_Agent'
    $WC = New-Object System.Net.WebClient
    $WC.DownloadFile($MarsAURL,$MARSDownloadedFile)
}
catch{
    Write-Output "Could not download updated package. Quitting."
    Write-Output "Error message was :$ErrorMessage"
    Exit
}

$VerDownloaded = Get-Version($MARSDownloadedFile)
Write-Verbose "Downloaded Version is $VerDownloaded"

$VerExisting = Get-Version($MARSExistingFile)
Write-Verbose "Existing Version is $VerExisting"

If([System.Version]$VerDownloaded -gt [System.Version]$VerExisting){
    Write-Output "New version available!"
    
    try{
        Write-Verbose "Creating backup of previous version..."
        Copy-Item $MARSExistingFile $BackupFile -Force -ErrorAction Stop
    }
    catch{
        $ErrorMessage = $_.Exception.Message
        Write-Output "Could not create backup. Quitting."
        Write-Output "Error message was :$ErrorMessage"
        Exit
    }

    try{
        Write-Verbose "Refreshing existing installation..."
        Copy-Item $MARSDownloadedFile $MARSExistingFile -Force -ErrorAction Stop
    }
    catch{
        $ErrorMessage = $_.Exception.Message
        Write-Output "Could not refresh source file. Quitting."
        Write-Output "Error message was :$ErrorMessage"
        Exit
    }
    
    try{
        $subject = "Updated Microsoft Azure Recovery Services Agent"
        $body = "New Version: "+ $VerDownloaded +"`n"
        $body+= "Current Version: "+ $VerExisting +"`n`n"
        $body+= "Please deploy the new version accordingly!"
        
        Write-Output "Sending notification email."
        Send-mailmessage -from $sendFrom -to $sendTo -subject $subject -body $body -smtpServer $smtpServer -ErrorAction Stop
    }
    catch{
        Write-Output "Could send email. Quitting."
        Write-Output "Error message was :$ErrorMessage"
        Exit
    }   
}
Else{
        Write-Output "Versions identical. No further action needed."
}