#!/bin/bash

#REGEX for number
isNum='^[0-9]+$'

#Text colors constatns
RED='\e[31m'         #Red

#Set text atributes constants
BOLD='\e[1m'         #Bold/Bright
UND='\e[4m'   #Underlined
UND_BLD='\e[4;1m'   #Underlined

#Reset text atributes constants
RA='\e[0m'           #Reset all attributes

function printHelp {
    echo -e "This script will try to reboot the computer if set parameters are met."
    echo -e "${UND_BLD}USAGE:${RA}\t${BOLD}./auto_restart.sh${RA} [${UND_BLD}OPTION${RA}]..."
    echo -e "${UND_BLD}OPTIONS:${RA}"
    echo -e "\t${BOLD}-h${RA},\t\t\t${BOLD}--help${RA}\t\t\tPrint this help text and terminates."
    echo -e "\t${BOLD}-c${RA} ${UND}average-load${RA},\t${BOLD}--cpu${RA} ${UND}average-load${RA}\tSets threshold for average cpu load. Parameter ${UND}average-load${RA} needs to be\n\t\t\t\t\t\t\tformated as three float numbers separated by comma (e.g., 0.30,0.15,0.05).\n\t\t\t\t\t\t\tThe three numbers represent avarege load for the past 1, 5 and 15 minutes\n\t\t\t\t\t\t\tand will be compared to uptime's value. Each given average value has to be\n\t\t\t\t\t\t\tlower or equal in order to reboot the computer."
    echo -e "\t${BOLD}-n${RA} ${UND}network-usage${RA},\t${BOLD}--network${RA} ${UND}network-usage${RA}\tThreshold for network traffic utilization. Interface with highest traffic utilization\n\t\t\t\t\t\t\twill be compared to the ${UND}network-usage${RA}. Value ${UND}network-usage${RA} is expected to be in bytes per second."
    echo -e "\t\t\t\t${BOLD}--net-interval${RA} ${UND}interval${RA}\tInterval of measurement of network traffic usage defined by ${UND}interval${RA} in seconds. Default vaule is 30 seconds"
    echo -e "\t${BOLD}-p${RA} ${UND}processes${RA},\t\t${BOLD}--proc${RA} ${UND}processes${RA}\tList of ${UND}processes${RA} that can't be running when attempting to reboot. The list\n\t\t\t\t\t\t\thas to be composed of the names of the processes separated by comma."
    echo -e "\t${BOLD}-i${RA} ${UND}time${RA},\t\t\t${BOLD}--interval${RA} ${UND}time${RA}\t\tInterval in seconds specified by ${UND}time${RA} between individual tries to reboot. Default value is 900 seconds."
    echo -e "\t${BOLD}-t${RA} ${UND}end-time${RA},\t\t${BOLD}--time${RA} ${UND}end-time${RA}\t\tSpecifies until what ${UND}end-time${RA} should the script try to reboot the PC.\n\t\t\t\t\t\t\tIt has to be in 24-hour format (e.g., starting the script at 23:00\n\t\t\t\t\t\t\tand setting -t 04:00 will result in 5 hour time window in which\n\t\t\t\t\t\t\tthe script will try to reboot the system). Default value is \"5:00\"."
    echo -e "\t${BOLD}-u${RA} ${UND}time${RA},\t\t\t${BOLD}--uptime${RA} ${UND}time${RA}\t\tSets threshold for uptime. If the computer is running longer than ${UND}time${RA}\n\t\t\t\t\t\t\tit will try to reboot. Parameter is expected in hours."
    echo -e "\t${BOLD}-r${RA}\t\t\t${BOLD}--human-readable${RA}\tPrints network traffic sizes in power of 1000 (e.g., 4.8 M)."
    echo -e "\t${BOLD}-d${RA}\t\t\t${BOLD}--dry-run${RA}\t\tWon't reboot if the parameters are met, just prints a message."
    exit 0
}

function echoerr() {
    >&2 echo -e "${RED}$@${RA}"
}

function numToHumanReadable() {
    if ! [[ $1 =~ $isNum ]];
    then
        echo ""
    elif [[ -z $humanReadable ]];
    then
        echo "$1 "
    else
        if [[ "$1" -gt "900000000000000" ]]
        then
            output=$(echo "$1" | awk '{var = $1 / 1000000000000000} END {printf "%.1f", var}')
            echo "$output P"
        elif [[ "$1" -gt "900000000000" ]]
        then
            output=$(echo "$1" | awk '{var = $1 / 1000000000000} END {printf "%.1f", var}')
            echo "$output T"
        elif [[ "$1" -gt "900000000" ]]
        then
            output=$(echo "$1" | awk '{var = $1 / 1000000000} END {printf "%.1f", var}')
            echo "$output G"
        elif [[ "$1" -gt "900000" ]]
        then
            output=$(echo "$1" | awk '{var = $1 / 1000000} END {printf "%.1f", var}')
            echo "$output M"
        elif [[ "$1" -gt "900" ]]
        then
            output=$(echo "$1" | awk '{var = $1 / 1000} END {printf "%.1f", var}')
            echo "$output k"
        else
            echo "$1 "
        fi
    fi
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -h|--help)
            printHelp
            ;;
        -c|--cpu)
            cpuLoad="$2"
            shift # past argument
            shift # past value
            ;;
        -n|--network)
            network="$2"
            shift # past argument
            shift # past value
            ;;
        --net-interval)
            netInterval="$2"
            shift # past argument
            shift # past value
            ;;
        -p|--proc)
            proc="$2"
            shift # past argument
            shift # past value
            ;;
        -i|--interval)
            interval="$2"
            shift # past argument
            shift # past value
            ;;
        -t|--time)
            endTime="$2"
            shift # past argument
            shift # past value
            ;;
        -u|--uptime)
            uptime="$2"
            shift # past argument
            shift # past value
            ;;
        -r|--human-readable)
            humanReadable=true
            shift # past argument
            ;;
        -d|--dry-run)
            dryRun=true
            shift # past argument
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done

set -- "${POSITIONAL[@]}"

if ! [ -z $1 ];
then
    echoerr "${RED}Error: unknown option \"$1\".${RA}"
    exit 0
fi

errorInArguments=false

if [[ ! -z "$cpuLoad" ]];
then
    if [[ "$cpuLoad" == "1" ]] || [[ $(echo $cpuLoad | sed 's/[0-9]\+.[0-9]\{0,2\},[0-9]\+.[0-9]\{0,2\},[0-9]\+.[0-9]\{0,2\}/1/g') != 1 ]];
    then
        echoerr "Error: CPU load in wrong format. Need \"X,Y,Z\", where X is CPU load for last 1 minute, Y for last 5 minutes and Z for last 15 minutes in float (e.g., 0.30,0.15,0.05), got \"$cpuLoad\""
        errorInArguments=true
    fi
fi

if [[ ! -z "$network" ]];
then
    if [[ "$network" == "1" ]] || [[ $(echo $network | sed 's/[0-9]\+\(\(.[0-9]\+[kMGTP]\)\|[kMGTP]\)\?/1/g') != 1 ]];
    then
        echoerr "Error: network traffic utilization in wrong format. Need \"X[kMGTP]\", where X represents amount of bytes per second and optional character represents multiple of byte. Got \"$network\""
        errorInArguments=true
    fi

    case ${network: -1} in
        k)
            network=$(echo "${network::-1}" | awk '{var = $1 * 1000} END {printf "%.f", var}')
            ;;
        M)
            network=$(echo "${network::-1}" | awk '{var = $1 * 1000000} END {printf "%.f", var}')
            ;;
        G)
            network=$(echo "${network::-1}" | awk '{var = $1 * 1000000000} END {printf "%.f", var}')
            ;;
        T)
            network=$(echo "${network::-1}" | awk '{var = $1 * 1000000000000} END {printf "%.f", var}')
            ;;
        P)
            network=$(echo "${network::-1}" | awk '{var = $1 * 1000000000000000} END {printf "%.f", var}')
            ;;
    esac
    
    if [[ -z "$netInterval" ]];
    then
        netInterval=30
    else
        if ! [[ $netInterval =~ $isNum ]];
        then
            echoerr "Error: network traffic monitoring interval in wrong format. Need \"X\", where X represents inteval in seconds. Got \"$netInterval\""
            errorInArguments=true
        fi
    fi
else
    network=-1
fi

if [[ ! -z "$proc" ]];
then
    if [[ "$proc" == "1" ]] || [[ $(echo $proc | sed 's/^.*,,.*$/1/g') == 1 ]];
    then
        echoerr "Error: list of processes in wrong format. Need \"X,X,X...\", where X represents name of a process. Got \"$proc\""
        errorInArguments=true
    fi
fi

if [[ -z "$interval" ]];
then
    interval=900
else
    if ! [[ $interval =~ $isNum ]];
    then
        echoerr "Error: interval for reboot try in wrong format. Need \"X\", where X represents inteval in seconds. Got \"$interval\""
        errorInArguments=true
    fi 
fi

if [[ -z "$endTime" ]];
then
    endTime="5:00"
else
    if [[ "$endTime" == "1" ]] || [[ $(echo $endTime | sed 's/\(\([0-1]\?[0-9]\)\|\(2[0-3]\)\):[0-5][0-9]/1/g') != 1 ]];
    then
        echoerr "Error: end time in wrong format. Need \"HH:MM\" in 24-hour format (e.g., 05:00, or 5:00). Got \"$endTime\""
        errorInArguments=true
    fi
fi

if [[ -z "$uptime" ]];
then
    uptime=-1
else
    if ! [[ $uptime =~ $isNum ]];
    then
        echoerr "Error: uptime in wrong format. Need \"X\", where X represents uptime in hours. Got \"$uptime\""
        errorInArguments=true
    fi
fi

if [ "$errorInArguments" = true ];
then
    printHelp
fi

echo -e "[START]\t$(date +'%Y-%m-%d %H:%M:%S')\tStarting auto restart script. Set options:"

if [[ ! -z "$cpuLoad" ]];
then
    echo -e "\t\t\t\tCPU load:\t\t\t\t$cpuLoad"
fi

if [[ "$network" -gt "0" ]];
then
    echo -e "\t\t\t\tAverage network traffic:\t\t$(numToHumanReadable $network)B/s"
    echo -e "\t\t\t\tNetwork traffic measurement interval:\t$netInterval s"
fi

if [[ ! -z "$proc" ]];
then
    echo -e "\t\t\t\tProcesses:\t\t\t\t$proc"
fi

if [[ ! -z "$interval" ]];
then
    echo -e "\t\t\t\tRestart try interval:\t\t\t$interval s"
fi

echo -e "\t\t\t\tScript end time:\t\t\t$endTime"

if [[ "$uptime" -gt "0" ]];
then
    echo -e "\t\t\t\tUptime:\t\t\t\t\t$uptime h"
fi

if [[ $(awk -F ':' '{print $1}' <<< $endTime) -le $(date +%H) || $(awk -F ':' '{print $1}' <<< $endTime) == $(date +%H) && $(awk -F ':' '{print $2}' <<< $endTime) -le $(date +%M) ]];
then
    dayEarly=true
    startTime=$(date +%H:%M)
else
    dayEarly=false
fi

while [ \( "$dayEarly" = "true" -a $(date +%H) -le "23" -a $(date +%M) -le "59" \) -o \( $(awk -F ':' '{print $1}' <<< $endTime) -ge $(date +%H) -a $(awk -F ':' '{print $2}' <<< $endTime) -gt $(date +%M) \) ]
do
    if [ "$uptime" -le "$(cat /proc/uptime | awk '{print int($1/3600)}')" ]
    then
        currentCPULoad=$(uptime | sed 's/.*\([0-9]\+,[0-9]\+, [0-9]\+,[0-9]\+, [0-9]\+,[0-9]\+\).*/\1/' | sed 's/\([0-9]\+\),\([0-9]\+\)/\1.\2/g' | sed 's/, /,/g')
        if [[ -z "$cpuLoad" || $(echo "$currentCPULoad,$cpuLoad" | awk -F ',' '{if ($1 <= $4 && $2 <= $5 && $3 <= $6) print "1"; else print "0";}') == "1" ]];
        then
            processFound=0

            if [[ ! -z "$proc" ]];
            then
                IFS=',' read -ra processes <<< $proc
                for process in "${processes[@]}";
                do
                    if [[ "$(pgrep $process | wc -l)" > "0" ]];
                    then
                        if [ "$processFound" == "0" ];
                        then
                            processFound=$process
                        else
                            processFound="$processFound $process"
                        fi
                    fi
                done
            fi

            if [ "$processFound" == "0" ];
            then
                if [[ "$network" -gt "0" ]];
                then
                    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tStarting network traffic monitorig for $netInterval s"
                    oldRxTx=$(cat /proc/net/dev | grep -e '.*:.*' | awk '{sum += $2 + $10} END {printf "%.f", sum}')
                    sleep $netInterval
                    deltaRxTx=$(expr $(cat /proc/net/dev | grep -e '.*:.*' | awk '{sum += $2 + $10} END {printf "%.f", sum}') - $oldRxTx)
                    averageRxTx=$(echo "$deltaRxTx $netInterval" | awk '{var = $1 / $2} END {printf "%.f", var}')
                else
                    averageRxTx=-2
                fi
                
                if [ "$averageRxTx" -lt "$network" ];
                then
                    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tThe computer will be restarted now."
                    echo -en "\t\t\t\tCPU load:\t\t$currentCPULoad"
                    if [[ -z "$cpuLoad" ]];
                    then
                        echo ""
                    else
                        echo -e "\tThreshold: $cpuLoad"
                    fi

                    if [[ "$network" -gt "0" ]];
                    then
                        echo -e "\t\t\t\tAverage net traffic:\t$(numToHumanReadable $averageRxTx)B/s\tThreshold: $(numToHumanReadable $network)B/s"
                    fi

                    echo -en "\t\t\t\tUptime:\t\t\t$(cat /proc/uptime | awk '{print int($1/3600)}') h"
                    if [[ "$uptime" -gt "0" ]];
                    then
                        echo -e "\t\tThreshold: $uptime h"
                    else
                        echo ""
                    fi

                    echo -e "[STOP]\t$(date +'%Y-%m-%d %H:%M:%S')\tTerminating script."

                    if [[ -z "$dryRun" ]];
                    then
                        #reboot
                        echo "hehe"
                    else
                        echo -e "\t\t\t\t###################################"
                        echo -e "\t\t\t\t##                               ##"
                        echo -e "\t\t\t\t##  DRY RUN - WOULD RESTART NOW  ##"
                        echo -e "\t\t\t\t##                               ##"
                        echo -e "\t\t\t\t###################################"
                        exit 0
                    fi
                else
                    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tWon't restart, because $(numToHumanReadable $averageRxTx)B/s (average network traffic in last $netInterval s) > $(numToHumanReadable $network)B/s (network traffic threshold)"
                fi
            else
                if [ "$(echo $processFound | wc -w)" == "1" ];
                then
                    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tWon't restart, becasue this process is still running: $processFound"
                else
                    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tWon't restart, becasue these processes are still running: $processFound"
                fi
            fi
        else
            echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tWon't restart, because $currentCPULoad (current CPU load) > $cpuLoad (CPU load threshold)"
        fi
    else
        echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tWon't restart, because $(cat /proc/uptime | awk '{print int($1/3600)}') (current uptime) < $uptime (threshold for uptime)"
    fi
    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tWill sleep for $interval seconds"
    sleep $interval
    if [ "$dayEarly" = true ] && [ $(awk -F ':' '{print $1}' <<< $startTime) -ge $(date +%H) ] && [ $(awk -F ':' '{print $2}' <<< $startTime) -gt $(date +%M) ];
    then
        dayEarly=false
    fi
done

echo -e "[STOP]\t$(date +'%Y-%m-%d %H:%M:%S')\tRequirements for restarting were not met, terminating script"
