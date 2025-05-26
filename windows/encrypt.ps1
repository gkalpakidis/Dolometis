function encryptCredentials {
    param (
        [string]$plainText,
        [byte[]]$key,
        [byte[]]$iv
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.IV = $iv
    $encryptor = $aes.CreateEncryptor()
    $bytes = [Text.Encoding]::UTF8.GetBytes($plainText)
    $encrypted = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length)
    return [Convert]::ToBase64String($encrypted)
}

#Generate a random key and IV
$key = New-Object byte[] 32
$iv = New-Object byte[] 16
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($iv)

#Plain Text credentials
$email = ""
$password = ""
$encryptedEmail = encryptCredentials -plainText $email -key $key -iv $iv
$encryptedPass = encryptCredentials -plainText $password -key $key -iv $iv

"Encrypted Email: $encryptedEmail"
"Encrypted Password: $encryptedPass"
"(Base64) Key: $( [Convert]::ToBase64String($key) )"
"(Base64) IV: $( [Convert]::ToBase64String($iv) )"