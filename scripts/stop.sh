#!/usr/bin/env bash

edomipid() {
    echo `ps -ef | grep "/usr/local/edomi/main/proc/[p]roc_main.php" | awk '{print $2}'`
}

wait=10
echo -n $"Shutting down Edomi: "
/usr/bin/php /usr/local/edomi/main/control.php quit
rm -f /var/lock/subsys/edomi
sleep 1
PID=$(edomipid)
s=0

if [[ "x$PID" != x ]] ; then
    echo "Allowing Edomi to terminate within $wait seconds"
fi

while [[ "x$PID" != x ]]; do
    s=$((s+1))
    echo -n "."
    if [[ "$s" -ge ${wait} ]]; then
        echo "Edomi did not terminate, hard killing"
        kill -9 ${PID}
        exit 0;
    fi
    sleep 1
    PID=$(edomipid)
done
echo
exit 0;