#Insert the Base64 string of encoded_script.txt file
$encodedScript = @"

"@

#Decode main script
$decodedBytes = [Convert]::FromBase64String($encodedScript)
$decodedScript = [Text.Encoding]::Unicode.GetString($decodedBytes)

#Run main script in memory
$ps = [powershell]::Create()
$ps.AddScript($decodedScript) | Out-Null
$ps.Runspace.ThreadOptions = "ReuseThread"
$ps.Runspace.ApartmentState = "STA"
$ps.Runspace.ThreadOptions = "ReuseThread"
$ps.Runspace.Open()
$ps.Invoke() | Out-Null
$ps.Dispose()