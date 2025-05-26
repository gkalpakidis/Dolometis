
# Dolometis

**[UNDER DEVELOPMENT]**
Dolometis is a phishing executable written in Powershell (targets windows hosts) and when executed, it (currently) collects useful system information like:
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

1. Use the encrypt.ps1 script to encrypt your credentials so they are not in plain text.
2. Insert the encrypted credentials along with the generated key and iv values to the main dolometis.ps1 script.
3. The script must then turn into an executable that the target will execute.

## Authors

- [@gkalpakidis](https://github.com/gkalpakidis)
- [@Fl0w3r1](https://github.com/Fl0w3r1)
