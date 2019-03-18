<#
.SYNOPSIS
Get-IP.ps1. Notify if the external IP has changed. 

.DESCRIPTION 
This PowerShell script will notify if the external IP address has changed via email. 
It selects at random a web service to provide this information. 

.PARAMETER SMTPServer
SMTP Server for sending the email notification

.PARAMETER SendFrom
Email Address to send notification email from 

.PARAMETER SendTo
Email Address to send notification email to 

.EXAMPLE
.\Get-IP.ps1 -SendTo me@example.com -SendFrom mypc@example.com -SMTPServer 127.0.0.1

.NOTES
Conversion of a PHP script I had. Works in PS6 Core.
Written by: Tom Yates

Change Log
V1.00, 18/03/2019 - Initial version
#>

[CmdletBinding()]
param (
    [Parameter( Mandatory = $true )]
    [ValidateNotNullOrEmpty()]
    [string]$SendFrom,

    [Parameter( Mandatory = $true )]
    [ValidateNotNullOrEmpty()]
    [string]$SendTo,

    [Parameter( Mandatory = $true )]
    [ValidateNotNullOrEmpty()]
    [string]$SMTPServer   
)

[array]$apis = 
    'https://v4.ident.me/',
    'https://ifconfig.co/ip',
    'https://api.ipify.org',
    'https://wtfismyip.com/text',
    'https://ip.seeip.org'

$ProgressPreference = "SilentlyContinue"

$DateFormat = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
$History = "history.csv"

$HistoryCSV = Import-CSV($History)

$URI = Get-Random -InputObject $apis -Count 1
Try{    
    If ($CurrentIP = Invoke-RestMethod $URI){
        $CurrentIP = $CurrentIP -replace "`t|`n|`r","" #remove whitespace and carriage returns
    }
}Catch {
    Write-host "could not call web service"
    Break
}

$LastIP = ($HistoryCSV | Sort-Object -Property DateTime -Descending | Select-Object -first 1).IP

If ($CurrentIP -ne $LastIP){
    Add-Content -Path $History -Value "$DateFormat,$CurrentIP,$URI"
    $HistoryCSV | Select-Object -First 10 | Sort-object DateTime -Descending

    $subject = "IP Address Change"
    $Body = "Awooga!`n"
    $Body = "IP has changed from $LastIP to $CurrentIP`n`n"
    $Body += "History`n=======`n`n"
    $Body += $HistoryCSV | Out-String
    Write-Host $Body
    send-mailmessage -from $sendFrom  -to $sendTo -subject $subject -body $body -smtpServer $SMTPServer -BodyAsHtml
}