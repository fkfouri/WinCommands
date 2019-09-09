@echo off

::update from tortoise
@tortoiseProc /command:update /path:"D:\FolderConfig\" /closeonend:1

::configure Policy of Forders
PowerShell.exe -ExecutionPolicy Bypass -File "D:\FolderConfig\Config.ps1"
