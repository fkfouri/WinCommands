Import-Module WebAdministration

#---> INTIAL CONFIG 
$Server1 = "BuildWebApp1" #SERVER NAME 1 - Ver no IIS
$Server2 = "BuildWebApp2" #SERVER NAME 2 - Ver no IIS

<#
-------------------------------------------------------------------
identifica se o servidor 'desligado' tem update
-------------------------------------------------------------------
#>
function fn_Check_SVN_update {
    #verifica qual dos servidores eh o corrente
    if ($currentServerRun.name -eq $InfoServer1.name){
        Set-Location -Path $InfoServer2.physicalPath
        Write-Host '- Checking' $InfoServer2.physicalPath '(' $InfoServer2.name ')' -foregroundcolor "Cyan"        
    }
    else{
        Set-Location -Path $InfoServer1.physicalPath
        Write-Host '- Checking' $InfoServer1.physicalPath '(' $InfoServer1.name ')' -foregroundcolor "Cyan"
    }
    
    #funcao interna que obtem a revisao do SVN
    function getRevision($ref){
        return $ref[6].replace('Revision: ','').trim()
    }

    $info1 = svn info
    $rev1 = getRevision($info1)
    Write-Host "- Rev1: $rev1 `t`t`tDate: $(Get-Date -format 'u')" -foregroundcolor "Cyan"  

    $update = svn update
    #Start-Process '@tortoiseProc /command:update /path:"D:\Inetpub\wwwroot\" /closeonend:1'
    $info2 = svn info
    $rev2 = getRevision($info2)
    Write-Host "- Rev2: $rev2  `t`t`tDate: $(Get-Date -format 'u')" -foregroundcolor "Cyan"  

    if($update.Count -gt 2){
        Write-Host "* There are updates" -foregroundcolor "Red" 
        return "Update"
    }    else    {
        Write-Host "* There are any updates" -foregroundcolor "Yellow" 
        return "NA"
    }
}



<#
-------------------------------------------------------------------
executa o teste/build no link fornecido
-------------------------------------------------------------------
#>
function Test_IE($myLink, $testUser){
    $ie = new-object -ComObject "InternetExplorer.Application"
    $ie.silent = $true 
    $ie.visible = $true #$false 

    #Write-Host "- Build:" $currentServerRun.name "`t`tDate: $(Get-Date -format 'u') `t`tLink: $LinkTest" -foregroundcolor "Cyan" 
    Write-Host $myLink "`t`t"  $testUser -foregroundcolor Magenta

    if ($testUser.length -gt 0) {
        $data = ""
        $input = "data="+$data+"\r\n"
        $enc = New-Object System.Text.ASCIIEncoding 
        $pData = $enc.GetBytes($input) 
        $brFlgs = 14 #// no history, no read cache, no write cache
        $header = "X-user:$testUser" 

        $ie.navigate($myLink, $brFlags, 0, $pData, $header)
    }
    else{
        $ie.navigate($myLink)
    }

    while ($ie.Busy) { 
        Start-Sleep -m 1000; 
    } 

    $ie.Quit() #fecha o IE
}



<#
-------------------------------------------------------------------
executa o build e testes de na paginas
-------------------------------------------------------------------
#>
function fn_build_WebApp(){
    #link principal
    $MainLink = 'http://localhost/'  
    #array de outros links de teste
    $OtherLinks = New-Object System.Collections.ArrayList

    #identifica o webSite que se executara a atualizacao
    if ($currentServerRun.name -eq $InfoServer1.name){
        $MainLink = 'http://localhost:82/'}
    else {
        $MainLink = 'http://localhost:81/'}

    #teste o link principal sem usuario
    Test_IE $MainLink;

    #listas de paginas de teste
    $OtherLinks.Add($MainLink + 'pageTest1.aspx')
    $OtherLinks.Add($MainLink + 'pageTest2.aspx')

    foreach ($Link in $OtherLinks){
        #executa o teste fornecendo um usuarios
        Test_IE $Link "fkfouri";
    }

    Write-Host "- Finished `t`t`tDate: $(Get-Date -format 'u')" -foregroundcolor "Cyan" 
}


<#
-------------------------------------------------------------------
# Executa o Swap para manter o WebApp no Ar
#http://www.tomsitpro.com/articles/powershell-manage-iis-websites,2-994.html
-------------------------------------------------------------------
#>
function fn_swap_IIS(){
    Set-Location -Path IIS:

    if ($currentServerRun.name -eq $InfoServer1.name){
        Remove-WebBinding -name $InfoServer1.name -Port 80 -Protocol http
        New-WebBinding -Name $InfoServer2.name -Port 80 -Protocol http
        WriteMessage $InfoServer2.name "Green"
        #Reinicia o WebSite 1 - Tentativa de zerar o Pool
        #Stop-WebSite $InfoServer1.name
        #Start-WebSite $InfoServer1.name
        
       
    }
    else {
        Remove-WebBinding -name $InfoServer2.name -Port 80 -Protocol http
        New-WebBinding -Name $InfoServer1.name -Port 80 -Protocol http 
        WriteMessage $InfoServer1.name "Green"
        #Reinicia o WebSite 2 - Tentativa de zerar o Pool
        #Stop-WebSite $InfoServer2.name
        #Start-WebSite $InfoServer2.name
        
    }
    
    #Get-Website
    #New-WebBinding -Name "cockpit_build" -Port 80 -Protocol http
}


<#
-------------------------------------------------------------------------
Identifica o Servidor que eventualmente esteja rodando na porta 80
-------------------------------------------------------------------------
#>
function IdentifyServer_RunningOnPort80{
    $out = Get-Website | Where {($_.bindings.collection.protocol –eq 'http') –and ($_.bindings.collection.bindingInformation –eq '*:80:')}

    #Write-Host 'It´s Running ' $out.name  -foregroundcolor "Yellow" 
    return $out
}

<#
-------------------------------------------------------------------------
Escreve a mensagem identificando qual WebSite esta operando
-------------------------------------------------------------------------
#>

function WriteMessage($name, $color){
$message = @"
================================================================================== 
It´s running the webSite $name
==================================================================================
"@
    #Write-Host $message -foregroundcolor $color 

    Write-Host "==================================================================================" -foregroundcolor $color 
    Write-Color "It´s running the webSite ", $name -color $color, Magenta 
    Write-Host "==================================================================================" -foregroundcolor $color 
}

<#
-------------------------------------------------------------------------
Escreve um texto com multiplas cores
https://evotec.xyz/powershell-how-to-format-powershell-write-host-with-multiple-colors/
-------------------------------------------------------------------------
#>
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int] $LinesBefore = 0,[int] $LinesAfter = 0) {
    $DefaultColor = $Color[0]
    if ($LinesBefore -ne 0) {  for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } } # Add empty line before
    if ($StartTab -ne 0) {  for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }  # Add TABS before text
    if ($Color.Count -ge $Text.Count) {
        for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine } 
    } else {
        for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
        for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine }
    }
    Write-Host
    if ($LinesAfter -ne 0) {  for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }  # Add empty line after
}


<#
-------------------------------------------------------------------------
Programa principal
-------------------------------------------------------------------------
#>

#---> SET GLOBAL VARIABLE
$InfoServer1 = Get-Website | Where {($_.name –eq $Server1)}
$InfoServer2 = Get-Website | Where {($_.name –eq $Server2)}

#identifica o servidor que esta funcionando na porta 80
$currentServerRun = IdentifyServer_RunningOnPort80

#se nao houver um servidor funcionando na porta 80
If (!$currentServerRun){
    #coloco o servidor 1 na porta 80
    New-WebBinding -Name $InfoServer1.name -Port 80 -Protocol http
    
    #identifica o servidor que esta funcionando na porta 80
    $currentServerRun = IdentifyServer_RunningOnPort80
}


Write-Host "`n" 
WriteMessage $currentServerRun.name "Yellow"


#Verifica se tem update
$CheckUpdate = fn_Check_SVN_update

#se houver um update dispara a atualizacao
if($CheckUpdate -ne "NA"){
    fn_build_WebApp
    fn_swap_IIS
    $currentServerRun = IdentifyServer_RunningOnPort80
    fn_Check_SVN_update
}
Write-Host "`n" 
Write-Host "`n" 


