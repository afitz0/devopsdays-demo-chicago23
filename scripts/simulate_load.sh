#!/bin/zsh

SLEEP_INTERVAL_MAX=5
POINTS_MAX=100
INVITE_CHANCE=0.01
MAX_CUSTOMERS_PER_CYCLE=10

DATE_STAMP="date -Iseconds"

export TEMPORAL_ADDRESS="0.0.0.0:7244"

function signalCustomer() {
    workflow=$(temporal workflow list -o json --query "ExecutionStatus = 'Running'" | \
        jq '.[].execution.workflow_id' -r | sort -R | tail -n 1)

    random=$(od -vAn -N2 -tu2 < /dev/urandom | awk '{print $1}')
    points=$(( $random % $POINTS_MAX + 1 ))

    echo -e "[$(eval $DATE_STAMP) $workflow] Signaling to add $points points"
    temporal workflow signal -w $workflow --name addLoyaltyPoints -i $points &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "[$workflow] failed to signal add points"
    fi

    random=$(od -vAn -N2 -tu2 < /dev/urandom | awk '{print $1}')
    if [[ $(( $random % 100 )) < $(( $INVITE_CHANCE * 100 )) ]]; then
        guestId=$random # no need to regenerate random for the ID

        echo -e "[$(eval $DATE_STAMP) $workflow] Signaling to invite guest with ID $guestId"
        signal_cmd="temporal workflow signal -w $workflow --name inviteGuest -i $(echo -n "'\"${guestId}\"'")"
        eval $signal_cmd &> /dev/null
        if [ $? -ne 0 ]; then
            echo -e "[$(eval $DATE_STAMP) $workflow] failed to signal invite guest"
        fi
    fi
}

while true; do
    numCustomers=$(( $RANDOM % $MAX_CUSTOMERS_PER_CYCLE + 1 ))
    for i in `seq 1 $numCustomers`; do
        # May select the same customer multiple times, and that's okay.
        signalCustomer &
    done

    sleepTime=$(( $RANDOM % $SLEEP_INTERVAL_MAX + 1 ))
    wait
    echo -e "[$(eval $DATE_STAMP)] End of cycle; sleeping for ${sleepTime}s"
    sleep $sleepTime
done
