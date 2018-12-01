<#
.SYNOPSIS
Get-MARSAgent.ps1 - Downloads latest MARS Agent

.DESCRIPTION 
This PowerShell script will get the latest MARS Agent, and update a specific location if it is newer.

.PARAMETER Email
Switch for sending email. SMTPServer, SendFrom and SendTo parameters are mandatory if this is True.

.PARAMETER SMTPServer
SMTP Server for email notification

.PARAMETER SendFrom
Email Address to send notification email from 

.PARAMETER SendTo
Email Address to send notification email to 

.PARAMETER Log
Switch for logging to file. LogFile is mandatory if this parameter is True.

.PARAMETER LogFile
Log file for recording output.

.EXAMPLE
.\Get-MARSAgent.ps1 -Email -SMTPServer 127.0.0.1
Will check for latest MARS version, and send email via 127.0.0.1 SMTP Server. 

.EXAMPLE
.\Get-MARSAgent.ps1 -Log -LogFile C:\Temp\MARSAgent-Update.log
Will check for latest MARS version, and record the process in C:\Temp\MARSAgent-Update.log

.NOTES
Written by: Tom Yates

Change Log
V2.00, 01/12/2018 - Updated to include log output and to make email alert optional.
V1.00, 13/11/2018 - Initial version
#>

[cmdletBinding(DefaultParametersetName='None')]
    Param(
        [Parameter(ParameterSetName='Email', Mandatory=$false)]
        [switch]$Email,

        [Parameter(ParameterSetName='Email', Mandatory = $true )]
        [string]$SMTPServer, 

        [Parameter(ParameterSetName='Email', Mandatory = $true)]
        [string]$sendFrom = "alert@example.com",    ### UPDATE THIS EMAIL ADDRESS, or specify in the command line

        [Parameter(ParameterSetName='Email', Mandatory = $true)]
        [string]$sendTo = "me@example.com",          ### UPDATE THIS EMAIL ADDRESS, or specify in the command line

        [Parameter(ParameterSetName='Log', Mandatory=$false)]
        [switch]$Log,

        [Parameter(ParameterSetName='Log', Mandatory = $true )]
        [string]$LogFile
    )

# Set this path to where Lansweeper gets its installation files from. 
# I'm using DFS to replicate my installations to all locations. 

#$Domain = (Get-ADDomain).DNSRoot
#$DFSDistPath = "\\$Domain\its\SoftwareDeployment\Microsoft\MARSAgent\"

$DFSDistPath = "Z:\Temp\Mars\"

$BackupFile = $DFSDistPath+"MARSAgentInstaller_PreviousVersion.exe"
$MARSExistingFile = $DFSDistPath+"MARSAgentInstaller.exe"
$MARSDownloadedFile = "$ENV:TEMP\MARSAgentInstaller-Downloaded.EXE"

Function Get-Version{
    param([string]$File)
    $FileInfo = Get-ItemProperty $File | Select-Object -Property VersionInfo
    return $FileInfo.VersionInfo.FileVersion
}

If ($Log){
    $timestamp = Get-Date -DisplayHint Time
    "$timestamp Process Starting..." | Out-File $LogFile

    Function Write-LogFile() {
        param( $logentry )
        $timestamp = Get-Date -DisplayHint Time
        "$timestamp $logentry" | Out-File $LogFile -Append
    }
}

Try{
    If($Log){Write-LogFile "Getting latest Agent..."}
    $MarsAURL = 'http://Aka.Ms/Azurebackup_Agent'
    $WC = New-Object System.Net.WebClient
    $WC.DownloadFile($MarsAURL,$MARSDownloadedFile)
}
catch{
    If($Log){Write-LogFile "Could not download updated package. Quitting.`nError: $ErrorMessage"}
    Exit
}

$VerDownloaded = Get-Version($MARSDownloadedFile)
If($Log){Write-LogFile "Downloaded Version is $VerDownloaded"}

If(!(Test-Path $MARSExistingFile)){
    If($Log){Write-LogFile "Existing file not present. Setting previous version to 0.0 and creating dummy file"}
    $VerExisting = "0.0" | Tee-Object -FilePath $MARSExistingFile
}
Else{
    $VerExisting = Get-Version($MARSExistingFile)
    If($Log){Write-LogFile "Existing Version is $VerExisting"}
}

If([System.Version]$VerDownloaded -gt [System.Version]$VerExisting){
    If($Log){Write-LogFile "New version available!"}

    try{
        If($Log){Write-LogFile "Creating backup of previous version"}
        Copy-Item $MARSExistingFile $BackupFile -Force -ErrorAction Stop

        If($Log){Write-LogFile "Refreshing existing installation"}
        Copy-Item $MARSDownloadedFile $MARSExistingFile -Force -ErrorAction Stop
    }
    catch{
        $ErrorMessage = $_.Exception.Message
        If($Log){Write-LogFile "Failed to complete file update. Quitting.`nError: $ErrorMessage"}
        Exit
    }
    If ($Email) {
        try{
            $subject = "Updated Microsoft Azure Recovery Services Agent"
            $body = "New Version: "+ $VerDownloaded +"`n"
            $body+= "Current Version: "+ $VerExisting +"`n`n"
            $body+= "Please deploy the new version accordingly!"
            
            Send-mailmessage -from $sendFrom -to $sendTo -subject $subject -body $body -smtpServer $smtpServer -ErrorAction Stop
        }
        catch{
            If($Log){Write-LogFile "Failed to send email. Quitting.`nError: $ErrorMessage"}
            Exit
        }    
    } 
}
Else{
    If($Log){Write-LogFile "Versions identical. No further action needed."}
}
If($Log){Write-LogFile "Process Complete."}