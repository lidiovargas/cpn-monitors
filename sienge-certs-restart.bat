@echo off
rem Copy this file to WIN_SERVER:d/TI/batch_scripts/
rem Check if permissions is right to Windows system

rem Check all variables "key=value" from txt file
for /f "delims== tokens=1,2" %%G in (sienge-certs-status.txt) do set %%G=%%H

if %RESTART_SIENGE%==1 ( 
        echo "Restarting Sienge (status = 1)"
        net stop "Firebird Server - SiengeWEB"
        timeout /t 30
        net start "Firebird Server - SiengeWEB"
        echo @ %date% %time% SVC-RESTART "Firebird Server - SiengeWEB" RESTARTED  >> D:\TI\batch_scripts\sienge-certs.log
	timeout /t 15
	
        net stop "JBossSiengeWEB"
        timeout /t 60
        net start "JBossSiengeWEB"
        echo @ %date% %time% SVC-RESTART "JBossSiengeWEB" RESTARTED  >> D:\TI\batch_scripts\sienge-certs.log

        echo RESTART_SIENGE=0 > sienge-certs-status.txt
) 

if %RESTART_SIENGE%==0 (        
        echo "Sienge not restarted (status = 0)"
)
echo Fim do script.
timeout /t 5
