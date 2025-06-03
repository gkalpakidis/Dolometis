
# Dolometis

**[UNDER DEVELOPMENT]**

Dolometis is a phishing executable written in Powershell (which targets windows hosts) and Python (which targets linux hosts) and when executed, it (currently) collects useful system information like:
- IP Addresses,
- Network Adapters,
- Installed Apps,
- Important Files,
- Running Processes & Services,
- System Event Logs and
- Hardware Info.

It then sends all that to an email address that the user provides.


![](https://raw.githubusercontent.com/gkalpakidis/Dolometis/refs/heads/main/misc/dolometis-banner-1.png)


## How to use

**Windows**

Before you clone the repository and start the configuration you have to install ***ps2exe***.
```ps
  Install-Module -Name ps2exe -Scope CurrentUser
```
You are likely to be prompted to choose some things.

Install and import NuGet: Y (Yes)

Untrusted repository. Install modules from PSGallery: Y (Yes)

Installation should finish successfully.

Additionally if you have not tinkered with Powershell, you will not be able to execute the scripts and you will have to change the execution policy.

Open Powershell as Administrator and execute:
```ps
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Once again, you will be prompted.

Change execution policy: Y (Yes)

After doing all this, you are ready to configure the scripts.

**Step 1:**
Open encrypt.ps1 and enter your raw email and password. Execute the script to encrypt the raw credentials and generate the necessary keys (Key & IV).

**Step 2:**
Open the main dolometis.ps1 script, change the default values (SMTP Server, Port, Recipient Email Address, etc) and insert the encrypted credentials along with the generated (Base64) Key and IV values to the correct variables. Save the script.

**Step 3:**
Open encode-script.ps1. Enter the path of the main dolometis.ps1 script and the path for the encoded script. Execute the script to get the Base64 encrypted script (encoded_script.txt).

**Step 4:**
Open launcher.ps1 script and insert the Base64 string from the encoded_script.txt file.

**Step 5:**
Open convertor.ps1 script to enter the paths of the launcher.ps1 script and the phishing executable. Execute the script to get the executable.

**Linux**

Dolometis for linux systems is currently just a script which does not get converted to an executable.

It uses a single email sending service ***(MailerSend)*** but I am planning on adding more options in the future.

**Step 1:**
Since the script uses MailerSend to send the email, you will have to create an account and get your SMTP credentials. More specifically you will need the Server, Port, Username and Password and you have to pass these to the script.

When ready just execute the script.

## Authors

- [@gkalpakidis](https://github.com/gkalpakidis)
- [@Fl0w3r1](https://github.com/Fl0w3r1)
