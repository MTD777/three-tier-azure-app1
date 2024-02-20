# .NET 8 


# Github CLI commands

gh auth login
gh auth status
gh auth logout
gh repo create MTD777/new-project --private
gh repo clone MTD777/new-project 

# Git commands

git add .
git rm --cached <file>
git commit -m "Commit changes"
git push -u origin main
git pull
git fetch
git clone <https://URL>
git checkout -b branchName # creates and switch to new branch
git clone -b <branchname> <https://URL>


# Configuration documentation - I am basing this project in the MS learn doc below

https://learn.microsoft.com/en-us/training/modules/n-tier-architecture/3-deploy-n-tier-architecture

az login
az group create --name three-tier-rg --location northcentralus

# Deploying using JSON ARM template - This is using the original project/deployment file

az deployment group create --resource-group three-tier-rg --template-uri  https://raw.githubusercontent.com/MicrosoftDocs/mslearn-n-tier-architecture/master/Deployment/azuredeploy.json --parameters password="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"


# check deployment

az deployment group show --output table --resource-group three-tier-rg --name azuredeploy --query properties.outputs.webSiteUrl


# Query resources

az resource list --tag tier=presentation --output table
az resource list --tag tier=application --output table
az resource list --tag tier=data --output table


################################
# Add SSH config to backend for E2E encryption
################################

# Ref - https://www.arubacloud.com/tutorial/how-to-enable-https-protocol-with-apache-2-on-ubuntu-20-04.aspx

sudo nano /etc/apache2/conf-available/ssl-params.conf

# Paste

SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH

    SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1

    SSLHonorCipherOrder On


    Header always set X-Frame-Options DENY

    Header always set X-Content-Type-Options nosniff

    # Requires Apache >= 2.4

    SSLCompression off

    SSLUseStapling on

    SSLStaplingCache "shmcb:logs/stapling-cache(150000)"


    # Requires Apache >= 2.4.11

    SSLSessionTickets Off


# Then modify apache2 file to include the following config

sudo nano /etc/apache2/sites-available/votingweb.conf

# HTTPS configuration
<VirtualHost *:443>
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:5000/
    ProxyPassReverse / http://127.0.0.1:5000/
    ErrorLog ${APACHE_LOG_DIR}/votingweb-error.log
    CustomLog ${APACHE_LOG_DIR}/votingweb-access.log common

    SSLEngine on
    SSLCertificateFile "/var/www/votingweb/ssl-certs/certificate.crt"
    SSLCertificateKeyFile "/var/www/votingweb/ssl-certs/privatekey.key"

    # If you have a chain certificate, use the following line
    # This the the full cert chain - 3 cerfificates chained
    # SSLCertificateChainFile "/var/www/votingweb/ssl-certs/certchain.crt"
</VirtualHost>

# Create ssl-certs folder and copy the certs, you will need to convert them from PFX to CRT and KEY

sudo mkdir /var/www/votingweb/ssl-certs

openssl pkcs12 -in mfk-labs-wild-0924-pass.pfx -nocerts -out privatekey.key -nodes
openssl pkcs12 -in mfk-labs-wild-0924-pass.pfx -clcerts -nokeys -out certificate.crt

sudo cp privatekey.key /var/www/votingweb/ssl-certs
sudo cp certificate.crt /var/www/votingweb/ssl-certs


# Check service is running

sudo a2enmod ssl
sudo systemctl restart apache
sudo systemctl status apache2.service


################################
# Troubleshooting commands
################################

# Keep in mind all the files named *web are located in the frontend VM and the *data on the backend VM

# Debbuging .NET and SQL 

sudo netstat -tuna # Check the current active connections - Established and Listen is ideally what you like to see here :)
sudo lsof -i :5001 # Check you app is running
curl -v localhost:5001 # Check if you can access your app using localhost locally
curl -v 10.24.2.4:5001 # Check if the app is accessible using IP address 

# Checking Frontend to Backend connection

cat /var/www/votingweb/appsettings.json # check your frontend app config


# Checking backend to DB Connection

cat /var/www/votingdata/appsettings.json # check your backend app config

nc -vz sql-just-man.database.windows.net 1443 # from your frontend, check if you can access the Azure SQL DB

# Looking for config files or any files - "Find" is a great command to get familiarized with

sudo find / -name *voting*

# Restart Services

sudo systemctl restart apache2
sudo systemctl restart votingweb.service # Restart frontend 
sudo systemctl restart votingdata.service # Restart backend

# .NET logs ~ troubleshoot 

journalctl -f # View systemd logs - Ref https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs
journalctl -f | grep exception # Filter for exceptions
sudo journalctl -u votingweb.service # Frontend
sudo systemctl status votingweb.service # Frontend service logs
sudo systemctl status votingdata.service # Backend service logs

/usr/bin/dotnet /var/www/votingdata/VotingData.dll # Start app manually, it will fail if app is already running, you can stop it with systemctl stop votingdata.service

nano /etc/systemd/system/votingdata.service # Edit backend service - Here you can change what setting your app listens to, use 0.0.0.0/0 to listen on all addresses or other as required
systemctl daemon-reload # if you made changes to service, daemon will need a reload

# Apache logs and config file

# Frontend

cat /etc/apache2/sites-available/votingweb.conf # check log location 
less /var/log/apache2/votingweb-access.log # access log
less /var/log/apache2/votingweb-error.log # error logs


# Backend 

cat /etc/apache2/sites-available/votingdata.conf # check log location 
less /var/log/apache2/votingdata-access.log # access log
less /var/log/apache2/votingdata-error.log # error logs


## Other Reference / Troubleshoot docs

https://andrewlock.net/5-ways-to-set-the-urls-for-an-aspnetcore-app/ # Allow frontend to backend in desired URLs/IPs
https://learn.microsoft.com/en-us/aspnet/core/fundamentals/host/web-host?view=aspnetcore-3.1#server-urls # Server URLs doc
https://learn.microsoft.com/en-us/aspnet/core/security/enforcing-ssl?view=aspnetcore-8.0&viewFallbackFrom=aspnetcore-2.2&tabs=netcore-cli%2Clinux-ubuntu # HTTPS and .NET options
https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel?view=aspnetcore-3.1#endpoint-configuration # Kestrel and .NET
https://andrewlock.net/why-isnt-my-aspnetcore-app-in-docker-working/ # Troubleshoot .NET
https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.app/container-app-acr/main.bicep # Azure Quickstart templates, great for quickly deploying proof of conecepts / demo apps and architectures
https://github.com/github/gitignore/blob/main/VisualStudio.gitignore # This is a project to check for common git ignore configs
https://learn.microsoft.com/en-us/azure/azure-sql/database/single-database-create-terraform-quickstart?view=azuresql&tabs=azure-cli # Deploy Azure SQL with unique name
https://raw.githubusercontent.com/MTD777/three-tier-azure-app1/main/setup-files/votingdata/votingdata.service # Raw Github content format



