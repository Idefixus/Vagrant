echo "Doing a openvas basic scan"
#$env:IP_VULNERABLE=192.168.178.24
#./openvas_scan_automation_start.sh $env:IP_VULNERABLE
./openvas_scan_automation_start.sh 192.168.178.24
# --- CONFIGURATION ---

# omp config
#omp_config="omp -u tester -w pw"

# Get the pdf id
#FORMAT="HTML"
#format_id=$($omp_config -F | grep "$FORMAT" | cut -d' ' -f1)

# Get the last running task

#task=$($omp_config --get-tasks | grep "$env:IP_VULNERABLE" | cut -d' ' -f1)

# Get the report_id of the task
# Fehleranfällig :P SEHR weis grad nix besseres
#$omp_config --get-tasks --details | grep 2020 | cut -d " " -f3

# Get the reports
#$omp_config --get-report $task --format $format_id > "report.$FORMAT"