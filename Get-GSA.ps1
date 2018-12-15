$CustomerId = '20260417'
$Pass = 'wy2324'

$FrewId ='61839813'
$GSAId = '61814540'
#FREW is an msi
#gsa is exe


#change for LicenseID via Parameter
$LicenseID = $FrewId

$AuthorID='2994476'

$OutFile = "Z:\TEMP\DownloadedVersion.exe"

$URI = "https://www.softwarekey.com/customers/LicenseAgreement.aspx?LicenseID=$LicenseID"

$Body = @{
    LoginType = 'Existing'
    LoginValue = $CustomerId
    Password = $Pass
    AuthorID = $AuthorID
    CMID = '0'
    P = $URI
    Agree = 'True'
}

$output = Invoke-RestMethod -Uri $URI -Method Post -Body $Body -OutFile $Outfile
$output



<#
HTML FROM THE FORM
<form id="login-form" action="Default.aspx" method="post" onsubmit="return ValidateExistingCustomer();">
<input type="hidden" name="LoginType" id="LoginType" value="Existing" />
<input type="hidden" name="P" value="https://www.softwarekey.com/customers/LicenseAgreement.aspx?LicenseID=61814540&amp;Referrer=License.aspx&amp;ReferrerQuerystring=LicenseID=61814540" />
<input type="hidden" name="AuthorID" id="AuthorID" value="0" />
<input type="hidden" name="CMID" id="CMID" value="0" />
<input name="LoginValue" id="LoginValue" class="text-field TextPropertyValid" type="text" size="25" maxlength="60" value="" />
<input name="Password" id="Password" class="text-field TextPropertyValid" type="password" size="15" maxlength="15" />       
#>