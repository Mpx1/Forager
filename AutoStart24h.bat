@echo off

cd /d %~dp0

set Mode=Automatic24h
set Pools=NiceHash,Zpool,ZergPool,WhatToMine

set Command="& .\Core.ps1 -MiningMode %Mode% -PoolsName %Pools%"

where pwsh >nul 2>nul || goto powershell
pwsh -executionpolicy bypass -command %Command%
goto end

:powershell
powershell -version 5.0 -executionpolicy bypass -command %Command%

:end
pause
