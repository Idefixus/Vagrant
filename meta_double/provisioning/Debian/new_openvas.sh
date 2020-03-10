#!/usr/bin/env bash
#
# OpenVAS automation script.
# Mariusz B. / mgeeky, '17
#	v0.2
#

trap ctrl_c INT

# Install pcregrep for pattern matching in grep if it doesn't exist on the machine already.

pcregrep 2> /dev/null
if [ $? -ne 2 ]; then
    echo "[!] pcregrep is not installed and will now be downloaded."
	echo
    apt install pcregrep -y
fi

# --- CONFIGURATION ---

USER=tester
PASS=pw
HOST=127.0.0.1
PORT=9390

# Must be one of the below defined targets
SCAN_PROFILE="Full and fast"
#SCAN_PROFILE="Full and fast ultimate"

FORMAT="XML"

# A valid "alive_test" parameter
# Defines how it is determined if the targets are alive
# Currently, valid values are the following:
#     Scan Config Default
#     ICMP, TCP-ACK Service & ARP Ping
#     TCP-ACK Service & ARP Ping
#     ICMP & ARP Ping
#     ICMP & TCP-ACK Service Ping
#     ARP Ping
#     TCP-ACK Service Ping
#     TCP-SYN Service Ping
#     ICMP Ping
#     Consider Alive
ALIVE_TEST='ICMP, TCP-ACK Service &amp; ARP Ping'

# --- END OF CONFIGURATION ---

targets=(
    "Discovery"
    "Full and fast"
    "Full and fast ultimate"
    "Full and very deep"
    "Full and very deep ultimate"
    "Host Discovery"
    "System Discovery"
)

formats=(
    "ARF"
    "CPE"
    "HTML"
    "ITG"
    "NBE"
    "PDF"
    "TXT"
    "XML"
)

able_to_clean=1

function usage {
    echo
    echo -ne "Usage: openvas-automate.sh <host>"
    echo
    echo -ne "\n  host\t- IP address or domain name of the host target."
    echo
    echo
}

function omp_cmd {
    cmd="omp -u $USER -w \"$PASS\" -h $HOST -p $PORT $@"
    #>&2 echo "DBG: OMP cmd: \"$cmd\""
    eval $cmd 2>&1
}

function omp_cmd_xml {
    omp_cmd "--xml='$@'"
}

function end {
    echo "[>] Performing cleanup"	

    if [ $able_to_clean -eq 1 ]; then
        omp_cmd -D $task_id
        omp_cmd -X '<delete_target target_id="'$target_id'"/>'
    fi
    exit 1
}

function ctrl_c() {
    echo "[?] CTRL-C trapped."
    exit 1
    end
}

echo
echo " :: OpenVAS automation script."
echo "    Idefixus, 0.3 (based on mgeeky, 0.2b)"
echo

out=$(omp_cmd -g | grep -i "discovery")
if [ -z "$out" ]; then
    echo "Exiting due to OpenVAS authentication failure."
    exit 1
fi

echo "[+] OpenVAS authenticated."

found=0

# Check if the chosen scan profile is legitimate
for i in "${targets[@]}"
do
    if [ "$i" == "$SCAN_PROFILE" ]; then
        found=1
        break
    fi
done

# Get the scan profile id from omp
scan_profile_id=$(omp_cmd -g | grep "$SCAN_PROFILE" | cut -d' ' -f1)
if [ $found -eq 0 ] || [ -z "$scan_profile_id" ]; then
    echo "[!] You've selected unknown SCAN_PROFILE. Please change it in script's settings."
    exit 1
fi

found=0

# Check if format is legitimate
for i in "${formats[@]}"
do
    if [ "$i" == "$FORMAT" ]; then
        found=1
        break
    fi
done

# Get the format id from omp
format_id=$(omp_cmd -F | grep "$FORMAT" | cut -d' ' -f1)

if [ $found -eq 0 ] || [ -z "$format_id" ]; then
    echo "[!] You've selected unknown FORMAT. Please change it in script's settings."
    exit 1
fi

# Checks if enough paramters are given
if [ -z "$1" ]; then
    usage
    exit 1
fi

TARGET="$1"

# When the IP of the target is not up return error message
ping -c 1 -W 1 "$TARGET" 2>&1 > /dev/null

if [ $? -ne 0 ]; then
    echo "[!] Specified target host seems to be unavailable!"
    read -p "Are you sure you want to continue [Y/n]? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo > /dev/null
    else
        exit 1
    fi
fi

echo "[+] Tasked: '$SCAN_PROFILE' scan against '$TARGET' "

# If target already exists reuse it otherwise create a new target. 
# NOTE: pcregrep has to be installed
target_id=$(omp_cmd -T | grep "$TARGET" | cut -d' ' -f1)

out=""
if [ -z "$target_id" ]; then

    echo "[>] Creating a target..."
    out=$(omp -u $USER -w "$PASS" -h $HOST -p $PORT --xml=\
"<create_target>\
<name>${TARGET}</name><hosts>$TARGET</hosts>\
<alive_tests>$ALIVE_TEST</alive_tests>\
</create_target>")
    target_id=$(echo "$out" | pcregrep -o1 'id="([^"]+)"')

else
    echo "[>] Reusing target..."
fi

if [ -z "$target_id" ]; then
    echo "[!] Something went wrong, couldn't acquire target's ID! Output:"
    echo $out
    exit 1
else 
    echo "[+] Target's id: $target_id"
fi

echo "[>] Creating a task..."
task_id=$(omp_cmd -C -n "$TARGET" --target=$target_id --config=$scan_profile_id)
    
if [ $? -ne 0 ]; then
    echo "[!] Could not create a task."
    end
fi

echo "[+] Task created successfully, id: '$task_id'"

echo "[>] Starting the task..."
report_id=$(omp_cmd -S $task_id)
    
if [ $? -ne 0 ]; then
    echo "[!] Could not start a task."
    end
fi

able_to_clean=0

echo "[+] Task started. Report id: $report_id"
echo "[.] Awaiting for it to finish. This will take a long while..."
echo

aborted=0
while true; do
    RET=$(omp_cmd -G)
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

    out=$(omp_cmd --get-report $report_id --format $format_id > $FILENAME.$FORMAT )

    if [ $? -ne 0 ]; then 
        echo '[!] Failed getting report.'; 
        echo "[!] Output: $out"
        #end
    fi

    echo "[+] Scanning done."
else
    echo "[?] Scan monitoring has been aborted. You're on your own now."
fi
