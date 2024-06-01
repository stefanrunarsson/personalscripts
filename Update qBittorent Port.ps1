#Get the last line written to the ProtonVPN log
$Log = Get-Content $(Get-ChildItem "$ENV:LocalAppData\ProtonVPN\Logs\" | Sort LastWriteTime | Select -Last 1).FullName -Tail 1

#Extract the port numbers based on the 5digits->5digits text comparison
#Chose this method to ensure it didnt pick an error or date if something was unusual.
#Then select just the last port value as local port
$Port = $($([Regex]::Matches($Log, '\d{5}->\d{5}')).Value).Split("->")[-1]

#Find the currently set port
$OldPort = ConvertFrom-Json (Invoke-WebRequest -Uri 'http://localhost:8083/api/v2/app/preferences').Content | Select -Expand  "listen_port"

#If the ports are different, push the change
If ($OldPort -ne $Port)
{
  #Generate json variable to be passed to api
  $Body = [PSCustomObject]@{ "listen_port" = $Port} | ConvertTo-Json -Compress

  #Use native powershell to push the chage to the api
  Invoke-WebRequest -Method Post -Body "json=$Body" -Uri "http://localhost:8083/api/v2/app/setPreferences"
} 
