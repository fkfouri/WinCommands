#habilita o script do PowerShell
set-executionpolicy remotesigned

#Versao do PowerShell
$psversiontable

#importa modulo
Import-Module ServerManager

#verifica em lista
Get-WindowsFeature -Name web* 

#Instala o IIS
Add-WindowsFeature -Name Web-Static-Content,Web-Dir-Browsing,Web-Http-Errors,Web-Http-Redirect,Web-Asp-Net,Web-CGI,Web-Windows-Auth,Web-Filtering,Web-Performance,Web-Mgmt-Tools,Web-Ftp-Service,Web-Dyn-Compression,Web-Scripting-Tools,Web-Mgmt-Service,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing 

#PowerShell ISE, File-Server e Gerenciador de Recursos de Servidor de Arquivos
Add-WindowsFeature -Name PowerShell-ISE, FS-FileServer, RSAT-FSRM-Mgmt -Restart 

#Habilita o Provider do IIS
Set-ExecutionPolicy RemoteSigned –Force
Import-Module WebAdministration
Set-ExecutionPolicy Restricted –Force

#configura o serviÃ§o ASPNET para iniciar automaticamente
Set-Service -Name aspnet_state -StartupType Automatic
Start-Service aspnet_state

#Configure Rule on Firewall Port #8008
#https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule?view=win10-ps
#New-NetFirewallRule -DisplayName "Open Inbound Port 8080" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
netsh advfirewall firewall add rule name="Open Inbound Port 8080" dir=in action=allow remoteip=any protocol=TCP localport=8080

#Desativa o FIPS 140-2 cryptography compliance. Habilita o uso da criptografia Rinjdael
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy" -name Enabled -value 0

#install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#habilitando o useFipsCompliantChecksums
choco feature enable --name="useFipsCompliantChecksums"


#install git
choco install -y git

#install node.js
choco install nodejs.install -y

#install python
#choco install python

#install Java JDK
#choco install jdk8 -y

#install PowerShell core
#choco install powershell-core

#Install Firefox
choco install firefox -y

#Install Notepad++
choco install notepadplusplus.install -y

#Install Nuget
choco install nuget.commandline -y

#SeveZip
choco install 7zip.install 

#Reinicia o Servidor
#Restart-Computer -Force