 #Entra na pasta
#Set-Location -Path  D:\ForderToManage

#---> INTIAL CONFIG 
# Identificado que quando roda como administrador sendo ativido via mouse, aponta para a pastar System32.
$currentDir = (Get-Item -Path ".\" -Verbose).FullName                    # Identifica o endereco atual
$currentDir = "D:\FolderConfig\"               # Fixa o endereco da pasta onde contem o Excel.
$ExcelFileAddress =Join-Path $currentDir config.xlsx     # tipo path.combine, identifica o endereco do XLS
$myAD = "myLDAP"

Write-Host "===================================="
Write-Host $ExcelFileAddress
Write-Host "===================================="


<#
-------------------------------------------------------------------
responsavel por limpar todas as definicoes de usuario da pasta
-------------------------------------------------------------------
#>
function removeAllUserFromPath($path){
    #obtem os acessos das pasta
    $folder = Get-Acl $path 

    foreach ($user in $folder.Access | Where {($_.IdentityReference -like 'myAD\*') -or ($_.IdentityReference -like 'AD\*')}){
        $folder.RemoveAccessRule($user)
    }
   
    #aplica as modificacoes de folder
    Set-Acl $path $folder
}

<#
-------------------------------------------------------------------
responsavel por substituir todas as permissoes de pasta de arquivos
filhos. Identificado que havia um bug... pois o usuario ao copiar arquivos para a pasta, poderiam carregavam
politicas de acessos.
https://www.itdroplets.com/powershell-replace-all-child-object-permission-entries-with-inheritable-permission-entries-from-this-object/
-------------------------------------------------------------------
#>
function replaceAllChildPermition($Path){
    <#
    #https://community.spiceworks.com/topic/415037-replace-all-child-object-permissions-powershell
	 #obtem os acessos das pasta
    $folder = Get-Acl $Path
    
    $folder.SetAccessRuleProtection($false, $true)
    #>


	Try {
        #Start the job that will reset permissions for each file, don't even start if there are no direct sub-files
        $SubFiles = Get-ChildItem $Path -File
        If ($SubFiles)  {
            $Job = Start-Job -ScriptBlock {$args[0] | %{icacls $_.FullName /Reset /C}} -ArgumentList $SubFiles
        }

        #Now go through each $Path's direct folder (if there's any) and start a process to reset the permissions, for each folder.
        $Processes = @()
        $SubFolders = Get-ChildItem $Path -Directory
        If ($SubFolders)  {
            Foreach ($SubFolder in $SubFolders)  {
            #Start a process rather than a job, icacls should take way less memory than Powershell+icacls
            $Processes += Start-Process icacls -WindowStyle Hidden -ArgumentList """$($SubFolder.FullName)"" /Reset /T /C" -PassThru
            }
        }	

        #Now that all processes/jobs have been started, let's wait for them (first check if there was any subfile/subfolder)
        #Wait for $Job
        If ($SubFiles)  {
            Wait-Job $Job -ErrorAction SilentlyContinue | Out-Null
            Remove-Job $Job
        }
        #Wait for all the processes to end, if there's any still active
        If ($SubFolders)  {
            Wait-Process -Id $Processes.Id -ErrorAction SilentlyContinue
        }
        
        Write-Host "The script has completed resseting permissions."
        Write-Host ""
    }
    Catch  {
        $ErrorMessage = $_.Exception.Message
        Throw "There was an error during the script: $($ErrorMessage)"
    }

}



<#
-------------------------------------------------------------------
responsavel por cadastrar uma permisssao de usuario na pasta
-------------------------------------------------------------------
#>
function AddUserToPath ($userName, $path){
    #obtem os acessos das pasta
    $folder = Get-Acl $path  

    #limpa a string de userName
    $userName = [string]$userName.Trim() 
    if ($userName -notlike '*\*'){

        #considera-se como padrao usuarios do Embad
        $userName = 'myAD\' + $userName
    }

    #[System.Windows.Forms.MessageBox]::Show($userName) 

    #Cria usuario com politica de acesso
    $newUser = New-Object System.Security.AccessControl.FileSystemAccessRule($userName,"Modify","ContainerInherit, ObjectInherit", "None", "Allow")
    
    #inclui usuario na pasta
    $folder.SetAccessRule($newUser)

    #aplica as modificacoes de folder
    Set-Acl $path $folder
}



<#
-------------------------------------------------------------------
responsavel por listar os usuarios com permissao de acesso na pasta
-------------------------------------------------------------------
#>
function listUsersFromPath($path){
    #obtem os acessos das pasta
    $folder = Get-Acl $path  

    #obtem a lista de usuarios com acesso na pasta
    $folder.Access | Where {($_.IdentityReference -like 'myAD\*') -or ($_.IdentityReference -like 'AD\*')} 
}



<#
-------------------------------------------------------------------
responsavel por  ler o arquivo de configuracao da pasta ForderToManage
-------------------------------------------------------------------
#>
function ReadExcel{
    $strFileName = $ExcelFileAddress
    $strSheetName = 'Plan1$'
    $strProvider = "Provider=Microsoft.ACE.OLEDB.12.0"
    $strDataSource = "Data Source = $strFileName"
    $strExtend = "Extended Properties='Excel 8.0;HDR=Yes;IMEX=1';"
    $strQuery = "Select * from [$strSheetName]"

    $objConn = New-Object System.Data.OleDb.OleDbConnection("$strProvider;$strDataSource;$strExtend")
    $sqlCommand = New-Object System.Data.OleDb.OleDbCommand($strQuery)
    $sqlCommand.Connection = $objConn
    $objConn.open()

    $da = New-Object system.Data.OleDb.OleDbDataAdapter($sqlCommand)
    $dt = New-Object system.Data.datatable
    [void]$da.fill($dt)
      
    $objConn.close()
    return $dt
}


<#
-------------------------------------------------------------------
responsavel por  ler o arquivo de configuracao da pasta ForderToManage
-------------------------------------------------------------------
#>
function configPath(){
    #Data Table do Excel
    $dtExcel = ReadExcel

    #para cada linha dataTable
    foreach ($line in $dtExcel | Where {($_.Ativo -eq 'Sim')}){
        #obtem o valor do diretorio
        $dir = $line.Diretorio

        #Exibe o diretorio
        Write-Host ""
        Write-Host "Defining permitions under $($dir)."

        #verifica se o diretorio existe
        if([System.IO.Directory]::Exists($dir)){

            #[System.Windows.Forms.MessageBox]::Show($dir) 

            #remove todos os usuarios do diretorio
            removeAllUserFromPath $dir

            #para cada login da linha de logins
            foreach ($login in $line.Login -split ";"){
                $login = $login.Trim()

                #se houver conteudo de login
                if($login.Length -gt 0){
                    #cadastra a permissao de login no diretorio
                    try{

                        AddUserToPath $login $dir
                        }
                    Catch {
                       #[System.Windows.Forms.MessageBox]::Show($login)
                    }
                }
            }

            #listUsersFromPath $dir

            #substitui a politica de permissao dos filhos "QUASE FUNCIONA na pasta PAI"
            replaceAllChildPermition $dir
        }

    }
}




<#
-------------------------------------------------------------------------
Programa principal
-------------------------------------------------------------------------
#>
configPath


#replaceAllChildPermition "D:\ForderToManage\TESTE"

#listUsersFromPath "D:\ForderToManage\Pasta1"

#listUsersFromPath "D:\ForderToManage\eJets"

#removeAllUserFromPath "D:\ForderToManage\Pasta1"

#AddUserToPath "fkfouri" "D:\ForderToManage\Pasta1"







