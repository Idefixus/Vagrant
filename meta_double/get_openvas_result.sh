# Continue the openvas script.
# TODO: Stability.

task_id=$1
report_id=$2
target_id=$3
format_id=$4
FORMAT=$5
TARGET=$6
user=tester
password=pw
# Function if not enough parameters are given.
function usage {
    echo "Usage: get_openvas_result.sh <task_id> <report_id> <target_id>"
    echo "Not enough paramters given please check you syntax."
}

# Checks if enough paramters are given
if [ -z "$6" ]; then
    usage
    exit 1
fi

echo "[.] Awaiting for the script to finish. This will take a long while..."
echo "[.] The paramters are: $task_id, Report ID: $report_id, Target ID: $target_id"

aborted=0
while true; do
    RET=$(omp -u $user -w $password -G)
    if [ $? -ne 0 ]; then 
            echo '[!] Querying jobs failed.'; 
            sleep 10
            #end
        fi

    RET=$(echo -n "$RET" | grep -m1 "$task_id" | tr '\n' ' ')
    out=$(echo "$RET" | tr '\n' ' ')
        echo -ne "$out\r"
    if [ `echo "$RET" | grep -m1 -i "fail"` ]; then
            echo '[!] Failed getting running jobs list'
            sleep 10
        fi
    echo "$RET" | grep -m1 -i -E "Stopped"
    if [ $? -ne 1 ]; then
        aborted=1
        break
    fi

    echo "$RET" | grep -m1 -i -E "done"
    if [ $? -ne 1 ]; then
        break
    fi

    sleep 1

done

if [ $aborted -eq 0 ]; then
    echo "[+] Job done, generating report..."

    FILENAME=${TARGET// /_}
    FILENAME="openvas_${FILENAME//[^a-zA-Z0-9_\.\-]/}_$(date +%s)"

	omp -u $user -w $password --get-report $report_id --format $format_id > "$FILENAME.html"
    out=$(omp -u $user -w $password --get-report $report_id --format $format_id > $FILENAME.$FORMAT)

    if [ $? -ne 0 ]; then 
        echo '[!] Failed getting report.'; 
        echo "[!] Output: $out"
        #end
    fi

    echo "[+] Scanning done. The filename of the report is: $FILENAME.$FORMAT"
else
    echo "[?] Scan monitoring has been aborted. You're on your own now."
fi