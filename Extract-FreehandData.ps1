<#
.SYNOPSIS
    This script converts all patient data from an unloaded Freehand Clinic Manger Patient database into CSV format. 

.DESCRIPTION
    This script generates a CSV file based on an unloaded Freehand Clinic Manager Patient database. 
    Freehand Clinic Manager is written in AcuCOBOL, and the data is stored in a COBOL vision data file. 

.EXAMPLE
    ./Freehand-Extract-ToCSV.ps1 -InputFile <string> -CSVOutputFile <string>

.PARAMETER -InputFile
        Specifies the path to the COBOL line sequential file.
.PARAMETER -CSVOutputFile
        Specifies the name and path for the CSV-based output file.

.NOTES
    By default the patient data is stored in a file called adphsl.dat, which is a COBOL vision data file format. 
    In order for the script to extract the data correctly, it first must be unloaded into line sequential format. 

    This can be achieved using the vutil32.exe command. 
    Example: vutil32.exe -unload -t adphsl.dat adphsl.unloaded

    This script uses the StreamReader class from Microsoft .Net to read the file line by line, as opposed to the Get-Content method. 
    Therefore dependant on the quantity of records in the file, it may take a long time to fully generate the CSV file. 

    There is very little error checking in this script, so it will just dump data out to CSV.
    Therefore, if a value has a comma in it, e.g "10, some drive", that will get split into "10" and "some drive"
    It is far easiest to use Excel to find these erroneous lines rather than try and find them within the raw data. 

    The first 10-20 lines are the usernames to access Freehand. These can be ignored. 
    The final 100 lines also appears to be internal record information. These can also be ignored. 
#>

Param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    [Parameter(Mandatory=$true)]
    [string]$CSVOutputFile
    )

#General Environment Variables
$nl = [Environment]::NewLine
$lineCount = 0
$startTime = Get-Date

#If you know the CSV Format, put it in here... below is a start. 
$csvout = ''
#$csvout = 'PatientID, Full Name, Address1, Address2, Address3, Address4, Postcode, Name, Number1, Number2, Number3, DoB, Occupation, MedCode1, MedCode2, MedCode3, Something, Something, Referral, Something, GP, Something, Something'

#Set up the Stream Reader object. 
$reader = New-Object System.IO.StreamReader -ArgumentList $InputFile

#Regex Patterns
$pattern = '(.{9})(.{35})(.{35})(.{35})(.{35})(.{35})(.{8})(.{20})(.{22})(.{22})(.{22})(.{6})(.{25})(.{25})(.{5})(.{20})(.{25})(.{6})(.{25})(.{6})(.{25})(.{1})(.{6})(.{1})(.{6})(.{6})(.{2})(.{6})(.{2})(.{6})(.{1})(.{6})(.{20})(.{6})(.{6})(.{6})(.{6})(.{6})(.{7})(.{80})(.{4})(.{208})(.{202})(.{6})(.{6})(.{6})(.{6})(.{6})(.{6})(.{16})'
$PatientPattern ='^([A-Z])([A-Z])([A-Z])([A-Z])([A-Z])([0-9])([0-9])([0-9])([0-9])'
$DeletedPatient = '^([A-Z])([A-Z])([A-Z])([A-Z])([A-Z])([0-9])([0-9])([0-9])([0-9])\W(DEL)'

#How Many Lines are there? 
$x = Get-Content $InputFile
$length = $x.count
Remove-Variable -name x

#Read the file line by line
while($null -ne ($line = $reader.ReadLine())) {
    $lineCount++     
    $newarray = ([Regex]::Matches($line, $pattern).Groups).Value
     
     #Process only if it matches the correct Regex pattern
     If($line -match $PatientPattern){ 

        #And dont bother if it is a deleted patient. 
        If($line -notmatch $DeletedPatient) {
        for ($i=1; $i -lt $newarray.length; $i++) {
                $csvout = $csvout + $newarray[$i].trim() + ","
         }
            #Give the user some feedback
            Write-Progress -Activity "Processing File" -status "Line number $linecount" -PercentComplete ($lineCount/$length*100)
            $csvout = $csvout + $nl
        }
      }
}
#How long did that take? 
$nts = New-Timespan -Start $startTime

#Write to file
$csvout | Out-File $CSVOutputFile

#End Summary
Write-Host "============================================================================"
Write-Host "Complete. Created $CSVOutputFile"
Write-Host "Processed $($LineCount) lines in $($Nts.Hours.ToString("00"))h:$($Nts.Minutes.ToString("00"))m:$($Nts.Seconds.ToString("00"))s"
Write-Host "============================================================================"