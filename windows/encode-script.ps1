$scriptContent = Get-Content -Path "C:\Downloads\Dolometis\dolometis.ps1" -Raw #Enter the path of dolometis.ps1 script
$bytes = [Text.Encoding]::Unicode.GetBytes($scriptContent)
$encodedScript = [Convert]::ToBase64String($bytes)
Set-Content -Path "C:\Downloads\Dolometis\encoded_script.txt" -Value $encodedScript #Enter the path for the encoded script (where you want to save it)