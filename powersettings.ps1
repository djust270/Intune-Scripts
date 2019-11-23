#simple script to set powersettings for the current user. Run in the users context and adjust values as desired
#As of 11/23/19 OMA-URI power policy CSP settings do no appear to work with intune. 

powercfg.exe -x -monitor-timeout-ac 15
powercfg.exe -x -monitor-timeout-dc 10
powercfg.exe -x -standby-timeout-dc 30
powercfg.exe -x -standby-timeout-ac 0
powercfg.exe -x -disk-timeout-ac 0
powercfg.exe -x -disk-timeout-dc 0
