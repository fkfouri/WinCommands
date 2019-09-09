#Cretate path
$path = "e:\inetpub\Webapp"

If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}

#Set Permition
$Acl = Get-Acl $path

$Ar1 = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Ar2 = New-Object System.Security.AccessControl.FileSystemAccessRule("everyone", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")

$Acl.SetAccessRule($Ar1)
$Acl.SetAccessRule($Ar2)
Set-Acl $path $Acl

#'https://docs.microsoft.com/en-us/powershell/module/smbshare/new-smbshare?view=win10-ps'
#New-SMBShare –Name WebApp –Path $path -FullAccess 'embad\lamorais','embad\fkfouri','embad\nadmonte'



#Exibe os comandos de iis
Get-Command -Module WebAdministration -Noun '*website*' | Format-Table -AutoSize

# Cria um MyAppx
# New-Website –Name MyAppx –PhysicalPath $path

