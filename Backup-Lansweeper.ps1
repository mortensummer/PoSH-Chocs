[CmdletBinding(DefaultParameterSetName='Main')]
    Param(
        [Parameter(ParameterSetName='Main', Mandatory=$true)]
        [Switch]$SQL,

        [Parameter(ParameterSetName='Main', Mandatory=$true)]
        [String]$Destination,

        [Parameter(ParameterSetName='Main', Mandatory=$false)]
        [int]$BackupsToKeep
    )      


$WebsiteFolders = @(
    'website\actions',
    'website\assetpictures',
    'website\docs', 
    'website\images',
    'website\userpictures',
    'website\widgetscustom',
    'website\app_data',
    'website\customdata',
    'website\lang',
    'website\widgetscustom'
)

$rootFolders =@(
    'actions',
    'key',
    'packageshare',
    'iisexpress',
    'sqldata'
)

$helpdeskfolders =(
    'website\helpdesk\files',
    'website\helpdesk\icons'
)

$knowledgebaseFolders= @(
    'website\knowledgebase\kbfiles'
)
$ServiceFolders =@(
    'service\export'  
)

### System Variables ###
$LSRoot = "C:\Program Files (x86)\Lansweeper"           # Lansweeper Installation Folder
$LSDBServer = "localhost"                               # Lansweeper Database Server (If not using SQL Compact)
$LSDBName = "lansweeperdb"                              # Lansweeper Database Name (If not using SQL Compact)

#Which services need to start/stop as part of this backup process?
$DependantServices = "W3SVC","IISExpressSVC","LansweeperService"

$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays(-$BackupsToKeep)
$CurrentDate.A
$Date = Get-Date -Format 'ddMMyy-HHmmss'

$FilePrefix = "Lansweeper_Backup_"
$Name = "$FilePrefix$Date"

#Set up a working folder for creating the ZIP file
$WorkingFolder = Join-Path -path $env:temp -childpath $([System.IO.Path]::GetRandomFileName())
New-item -Path $WorkingFolder -ItemType Directory

$TempPath = Join-Path -Path $WorkingFolder -ChildPath $Name
$ZipBackup = Join-Path $WorkingFolder "$Name.zip"

#SQL Query to backup the database (if not using SQL Compact)
$LSDBBackup = "$TempPath\$LSDBName$Date.bak"            # Name of Database Backup
$SQLQuery = "BACKUP DATABASE $LSDBName TO DISK = N'$LSDBBackup' WITH NOFORMAT, INIT, NAME = N'Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

function Copy-Folders([string]$Dest, [psobject]$SourceFolders){
    foreach($folder in $SourceFolders){
        Copy-Item "$LSRoot\$Folder\" $Dest -Recurse -Force
    }
}
function Switch-Services([string]$action, $services){
        Foreach ($service in $services){
         Switch ($action){
            "stop"{
                If (Get-Service $service -ErrorAction SilentlyContinue) {
                    If ((Get-Service $service).Status -eq 'Running') {Stop-Service $service}
                }
                else{Write-Verbose "$Service :Not Found" }
            }
            "start" {
                If (Get-Service $service -ErrorAction SilentlyContinue) {
                    If ((Get-Service $service).Status -eq 'Stopped') {
                        If((Get-Service $service).StartType -eq 'Disabled'){
                            Write-Verbose "$Service :Set to Disabled"
                        }
                        Else{
                            Write-Verbose "Starting Service $service"
                            Start-Service $service  
                        }
                    }
                }
            }
        } 
    }
}
#Stop Services
Switch-Services "stop" $DependantServices

#Website
$WebsiteFolderBackup = New-Item -Path $TempPath -ItemType Directory -Name "website"
Copy-Folders $WebsiteFolderBackup $WebsiteFolders

#helpdesk
$HelpdeskFolderBackup = New-Item -Path $WebsiteFolderBackup -ItemType Directory -Name "helpdesk"
Copy-Folders $HelpdeskFolderBackup $helpdeskfolders

#knowledgebase
$KBFolderBackup = New-Item -Path $WebsiteFolderBackup -ItemType Directory -Name "knowledgebase"
Copy-Folders $KBFolderBackup $knowledgebaseFolders

#service
$ServiceFolderBackup = New-Item -Path $TempPath -ItemType Directory -Name "service"
Copy-Folders $ServiceFolderBackup $ServiceFolders

#Root
Copy-Folders $TempPath $rootFolders

#Backup Database if SQL parameter is set.
If ($SQL){SQLCMD.EXE -S $LSDBServer -E -Q $SQLQuery}

#Start Services
Switch-Services "start" $DependantServices

#Zip it up
$Finish = Get-ChildItem $TempPath
Compress-Archive -Path $Finish.FullName -DestinationPath $ZipBackup

#Calculate Hash
$OriginalHash = Get-FileHash -Path $ZipBackup -Algorithm MD5

#Copy file to destination
try{
    $FileBackup = Copy-Item -Path $ZipBackup -Destination $Destination -PassThru
}catch{

}

#Calculate Hash afer copying
$CopiedHash = Get-FileHash -Path $FileBackup.FullName -Algorithm MD5

#Compare hashes
If ($OriginalHash.hash -ne $CopiedHash.hash){
    Write-Warning "Hash Mismatch when copying. Not cleaning up."
    Write-Warning "Please check folder $WorkingFolder"

}else{
    Write-Verbose "Removing $WorkingFolder as the file hash matched"
    remove-Item $WorkingFolder -Force -Recurse

    If($BackupsToKeep){
        Write-Verbose "Removing files older than $Backupstokeep days"
        Get-ChildItem $Destination -Filter "$FilePrefix*.zip" | Where-Object {$_.LastWriteTime -lt $DatetoDelete} | Remove-Item 
    }
}