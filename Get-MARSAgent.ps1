<#
.SYNOPSIS
Get-MARSAgent.ps1 - Downloads latest MARS Agent from Microsoft

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
V2.10, 02/01/2919 - Improved Parameters (for learning), also output to host if not logging
V2.00, 01/12/2018 - Updated to include log output and to make email alert optional.
V1.00, 13/11/2018 - Initial version
#>

[cmdletBinding(DefaultParametersetName='Main')]
    Param(
        [Parameter(ParameterSetName='Email', Mandatory=$false, Position=0)]
        [ValidateNotNullOrEmpty()]
        [switch]$Email,
      
        [Parameter(ParameterSetName='Email', Mandatory = $true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$SMTPServer, 

        [Parameter(ParameterSetName='Email', Mandatory = $true, Position=2)]
        [ValidateNotNullOrEmpty()]
        [string]$sendTo = 'me@example.com',          ### UPDATE THIS EMAIL ADDRESS, or specify in the command line

        [Parameter(ParameterSetName='Email', Mandatory = $true, Position=3)]
        [ValidateNotNullOrEmpty()]
        [string]$sendFrom = 'me@example.com',          ### UPDATE THIS EMAIL ADDRESS, or specify in the command line

        [Parameter(ParameterSetName='Email', Mandatory=$false, Position=4)]
        [Parameter(ParameterSetName='Main', Mandatory=$false, Position=4)]
        [ValidateNotNullOrEmpty()]
        [switch]$Log

    )
    DynamicParam{
        if ($Log){
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary 
            $LogFile = New-Object System.Management.Automation.ParameterAttribute -Property @{
                Mandatory = $true
                Position = 5
                HelpMessage = 'Please enter file and path to write log to.'
            }
            $attributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($LogFile)

            $LogFileParam = New-Object System.Management.Automation.RuntimeDefinedParameter('logfile', [string], $attributeCollection)
            $paramDictionary.Add('logfile', $LogFileParam)

            return $paramDictionary
        }
    }
Process{
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

    Function Write-LogFile() {
        param( $logentry )
        $timestamp = Get-Date -DisplayHint Time
        
        If($Log){ "$timestamp $logentry" | Out-File $LogF -Append }
        else{ Write-Output "$timestamp $logentry" }  
    }
    
    If ($Log){
        $LogF = "$($PSBoundParameters.LogFile)"
        $timestamp = Get-Date -DisplayHint Time
        "$timestamp Process Starting..." | Out-File $LogF
    }
    
    Try{
        Write-LogFile "Getting latest Agent..."
        $MarsAURL = 'http://Aka.Ms/Azurebackup_Agent'
        $WC = New-Object System.Net.WebClient
        $WC.DownloadFile($MarsAURL,$MARSDownloadedFile)
    }
    catch{
        $msg = "Could not download updated package. Quitting.`nError: $($error[0])"
        if ($Log){ Write-LogFile $msg }
        else { Write-Warning $msg }
        Exit
    }

    $VerDownloaded = Get-Version($MARSDownloadedFile)
    Write-LogFile "Downloaded Version is $VerDownloaded"

    If(!(Test-Path $MARSExistingFile)){
        Write-LogFile "Existing file not present. Setting previous version to 0.0 and creating dummy file"
        $VerExisting = "0.0" | Tee-Object -FilePath $MARSExistingFile
    }
    Else{
        $VerExisting = Get-Version($MARSExistingFile)
        Write-LogFile "Existing Version is $VerExisting"
    }

    If([System.Version]$VerDownloaded -gt [System.Version]$VerExisting){
        Write-LogFile "New version available!"

        try{
            Write-LogFile "Creating backup of previous version"
            Copy-Item $MARSExistingFile $BackupFile -Force -ErrorAction Stop

            Write-LogFile "Refreshing existing installation"
            Copy-Item $MARSDownloadedFile $MARSExistingFile -Force -ErrorAction Stop
        }
        catch{
            Write-LogFile "Failed to complete file update. Quitting.`nError: $($error[0])"
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
                $msg = "Failed to send email. Quitting.`nError: $($error[0])"
                if ($Log){ Write-LogFile $msg }
                else { Write-Warning $msg }
                Exit
            }    
        } 
    }
    Else{
        Write-LogFile "Versions identical. No further action needed."
    }
    Write-LogFile "Process Complete."
}