#Logging location
$LogFile = "$ENV:LocalAppData\ProtonVPN\Script.log"

#Get the last line written to the ProtonVPN log
$Log = Get-Content $(Get-ChildItem "$ENV:LocalAppData\ProtonVPN\Logs\" | Sort LastWriteTime | Select -Last 1).FullName -Tail 1

#Extract the port numbers based on the 5digits->5digits text comparison or if the last log update didn't specify port numbers just exit
#Chose this method to ensure it didnt pick an error or date if something was unusual.
If ([Regex]::Matches($Log, '\d{5}->\d{5}'))
{
  #Select just the last port value as local port
  $Port = $($([Regex]::Matches($Log, '\d{5}->\d{5}')).Value).Split("->")[-1]
  #Update log
  Add-Content $LogFile -value "Port number: $Port"
} Else { Add-Content $LogFile -value "No port found so exiting"; Add-Content $LogFile -value "Errors: $Error `r`n`r`n"; Exit 0 }  

#Find the currently set port
$OldPort = ConvertFrom-Json (Invoke-WebRequest -Uri 'http://localhost:8083/api/v2/app/preferences').Content | Select -Expand  "listen_port"
#Update log
Add-Content $LogFile -value "Existing port number: $OldPort"

#Had issues with the port value not being correct - suspect due to file lock conflicts, so check we have a 5 digit port value otherwise just skip
#If the ports are different, push the change
If ($Port -match '\d{5}' -And $OldPort -ne $Port)
{
  #Generate json variable to be passed to api
  $Body = [PSCustomObject]@{ "listen_port" = $Port} | ConvertTo-Json -Compress

  #Use native powershell to push the chage to the api
  Invoke-WebRequest -Method Post -Body "json=$Body" -Uri "http://localhost:8083/api/v2/app/setPreferences"
  
  #Update log
  Add-Content $LogFile -value "Updated port due to detected change"
  Add-Content $LogFile -value "Errors: $Error `r`n`r`n";
} Else {  Add-Content $LogFile -value "Port is unchanged, or issue getting a port number so exiting"; Add-Content $LogFile -value "Errors: $Error `r`n`r`n" }
