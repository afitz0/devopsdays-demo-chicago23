#!/bin/zsh

SLEEP_INTERVAL_MAX=5
POINTS_MAX=100
INVITE_CHANCE=0.01

while true; do
    workflow=$(temporal workflow list -o json --query "ExecutionStatus = 'Running'" | \
        jq '.[].execution.workflow_id' -r | sort -R | tail -n 1)
    echo "Chose customer workflow ID: $workflow"
    
    points=$(( $RANDOM % $POINTS_MAX + 1))
    echo -e "\t--> Signaling to add $points points"
    echo -n -e "\t--> "
    temporal workflow signal -w $workflow --name addLoyaltyPoints -i $points

    if [[ $(( $RANDOM % 100 )) < $(( $INVITE_CHANCE * 100 )) ]]; then
        guestId=$RANDOM
        echo -e "\t--> Signaling to invite guest with ID $guestId"
        echo -n -e "\t--> "
        signal_cmd="temporal workflow signal -w $workflow --name inviteGuest -i $(echo -n "'\"${guestId}\"'")"
        eval $signal_cmd
    fi

    echo -e "\t--> End of cycle; sleeping"
    sleep $(( $RANDOM % $SLEEP_INTERVAL_MAX + 1 ))
done
