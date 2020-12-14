SCHTASKS /CREATE /SC DAILY /TN "Sienge Restart after certs updated" /TR "D:\TI\batch_scripts\sienge-certs-schedule.bat" /ST 05:15


rem Run this script as admin
rem Copy this file to WIN_SERVER:d/TI/batch_scripts/
rem Check if permissions is right to Windows system

rem Related scripts:
rem Collection of related scripts, and shedulling:
rem 1. WIN_SERVER:.../letsencrypt-sienge-autorenew.bat (daily at 05:02am)
rem 2. LINUX/sienge-certs.sh (daily at 05:10 am)
rem 3. WIN_SERVER:.../sienge-certs-restart.bat (daily at 05:15am)

rem Collection of other related files
rem 4. WIN_SERVER:.../sienge-certs-schedule.bat
rem      Schedule "script 3" into task of Windows - Run as admin
rem 5. WIN_SERVER:.../sienge-certs-status.txt
rem      Store variable RESTART_SIENGE=0 (or 1), checked by "script 3"
rem      to manage when restart is needed.

