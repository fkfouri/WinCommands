:: @echo off
robocopy C:\inetpub\Repositorios\Cockpit\ \\server\directory1\Build1 *.* /MIR /SEC /xd ".svn" "App_Temp" "Config" /xf "web.config"
robocopy C:\inetpub\Repositorios\Cockpit\Config\Bubble\. \\server\directory1\Build1\ /E

::   
::   ...files in current dir: for %f in (.\*) do @echo %f
::   ...subdirs in current dir: for /D %s in (.\*) do @echo %s
::   ...files in current and all subdirs: for /R %f in (.\*) do @echo %f
::   ...subdirs in current and all subdirs: for /R /D %s in (.\*) do @echo %s
::   

:: 
:: set back=%cd%
:: for /d %%i in (C:\inetpub\Repositorios\Cockpit\*) do (
:: 	cd "%%i"
:: 	echo current directory:
:: 	cd
:: )
:: cd %back%
:: 
