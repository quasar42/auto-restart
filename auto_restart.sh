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
    echo -e "\t${BOLD}-c${RA} ${UND}average-load${RA},\t${BOLD}--cpu${RA} ${UND}average-load${RA}\tSets threshold for average cpu load. Parameter ${UND}average-load${RA} needs to be\n\t\t\t\t\t\t\tformated as three float numbers separated by colon (e.g. 0.30,0.15,0.05).\n\t\t\t\t\t\t\tThe three numbers represent avarege load for the past 1, 5 and 15 minutes\n\t\t\t\t\t\t\tand will be compared to uptime's value. Each given average value has to be\n\t\t\t\t\t\t\tlower or equal in order to reboot the computer."
    echo -e "\t${BOLD}-n${RA} ${UND}network-usage${RA},\t${BOLD}--network${RA} ${UND}network-usage${RA}\tThreshold for network traffic utilization. Interface with highest traffic utilization\n\t\t\t\t\t\t\twill be compared to the ${UND}network-usage${RA}. Value ${UND}network-usage${RA} is expected to be in bytes per second."
    echo -e "\t\t\t\t${BOLD}--net-interval${RA} ${UND}interval${RA}\tInterval of measurement of network traffic usage defined by ${UND}interval${RA} in seconds. Default vaule is 30 seconds"
    echo -e "\t${BOLD}-p${RA} ${UND}processes${RA},\t\t${BOLD}--proc${RA} ${UND}processes${RA}\tList of ${UND}processes${RA} that can't be running when attempting to reboot. The list\n\t\t\t\t\t\t\thas to be composed of the names of the processes separated by semicolon."
    echo -e "\t${BOLD}-i${RA} ${UND}time${RA}\t\t\t${BOLD}--interval${RA} ${UND}time${RA}\t\tInterval in seconds specified by ${UND}time${RA} between individual tries to reboot. Default value is 900 seconds."
    echo -e "\t${BOLD}-t${RA} ${UND}end-time${RA}\t\t${BOLD}--time${RA} ${UND}end-time${RA}\t\tSpecifies until what ${UND}end-time${RA} should the script try to reboot the PC.\n\t\t\t\t\t\t\tIt has to be in 24-hour format (e.g. starting the script at 23:00\n\t\t\t\t\t\t\tand setting -t 04:00 will result in 5 hour time window in which\n\t\t\t\t\t\t\tthe script will try to reboot the system). Default value is \"5:00\"."
    echo -e "\t${BOLD}-u${RA} ${UND}time${RA}\t\t\t${BOLD}--uptime${RA} ${UND}time${RA}\t\tSets threshold for uptime. If the computer is running longer than ${UND}time${RA}\n\t\t\t\t\t\t\tit will try to reboot. Parameter is expected in hours."
    exit 2
}

function echoerr() {
    >&2 echo -e "${RED}$@${RA}"
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
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done

set -- "${POSITIONAL[@]}"

if ! [ -z $1 ];
then
    echo -e "${RED}Error: unknown option \"$1\".${RA}"
    printHelp
fi

errorInArguments=false

if [[ ! -z "$cpuLoad" ]];
then
    if [[ "$cpuLoad" == "1" ]] || [[ $(echo $cpuLoad | sed 's/[0-9]\+.[0-9]\{0,2\},[0-9]\+.[0-9]\{0,2\},[0-9]\+.[0-9]\{0,2\}/1/g') != 1 ]];
    then
        echoerr "Error: CPU load in wrong format. Need \"X,Y,Z\", where X is CPU load for last 1 minute, Y for last 5 minutes and Z for last 15 minutes in float (e.g. 0.30,0.15,0.05), got \"$cpuLoad\""
        errorInArguments=true
    fi
fi

if [[ ! -z "$network" ]];
then
    if [[ "$network" == "1" ]] || [[ $(echo $network | sed 's/[0-9]\+\(\(.[0-9]\+[kMGTP]\)\|[kMGTP]\)\?/1/g') != 1 ]];
    then
        echoerr "Error: network trafic utilization in wrong format. Need \"X[kMGTP]\", where X represents amount of bytes per second and optional character represents multiple of byte. Got \"$network\""
        errorInArguments=true
    fi
    
    if [[ -z "$netInterval" ]];
    then
        netInterval=30
    else
        if ! [[ $netInterval =~ $isNum ]];
        then
            echoerr "Error: network trafic monitoring interval in wrong format. Need \"X\", where X represents inteval in seconds. Got \"$netInterval\""
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
        echoerr "Error: end time in wrong format. Need \"HH:MM\" in 24-hour format (e.g. 05:00, or 5:00). Got \"$endTime\""
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
    echo -e "\t\t\t\tAverage network traffic:\t\t$network B/s"
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
        if [ -z "$cpuLoad" -o \( \( "$(echo $(awk -F ',' '{print $1}' <<< $currentCPULoad) \<\= $(awk -F ',' '{print $1}' <<< $cpuLoad) | bc -l)" = "1" \) -a \( "$(echo $(awk -F ',' '{print $2}' <<< $currentCPULoad) \<\= $(awk -F ',' '{print $2}' <<< $cpuLoad) | bc -l)" = "1" \) -a \( "$(echo $(awk -F ',' '{print $3}' <<< $currentCPULoad) \<\= $(awk -F ',' '{print $3}' <<< $cpuLoad) | bc -l)" = "1" \) \) ];
        then
            processFound=0

            if [[ ! -z "$proc" ]];
            then
                IFS=',' read -ra processes <<< $proc
                for process in "${processes[@]}";
                do
                    if [[ "$(pgrep $process | wc -l)" > "0" ]];
                    then
                        processFound=$process
                        break
                    fi
                done
            fi

            if [ "$processFound" == "0" ];
            then
                if [[ "$network" -gt "0" ]];
                then
                    oldRxTx=$(cat /proc/net/dev | grep -e '.*:.*' | awk '{sum += $2 + $10} END {printf "%.f", sum}')
                    sleep $netInterval
                    deltaRxTx=$(expr $(cat /proc/net/dev | grep -e '.*:.*' | awk '{sum += $2 + $10} END {print "%.f", sum}') - $oldRxTx)
                    averageRxTx=$(echo "$deltaRxTx / $netInterval" | bc -l | awk '{print int($1+0.5)}')
                    case ${network: -1} in
                        k)
                            network=$(echo "${network::-1} * 1000" | bc -l | cut -d '.' -f 1)
                            ;;
                        M)
                            network=$(echo "${network::-1} * 1000000" | bc -l | cut -d '.' -f 1)
                            ;;
                        G)
                            network=$(echo "${network::-1} * 1000000000" | bc -l | cut -d '.' -f 1)
                            ;;
                        T)
                            network=$(echo "${network::-1} * 1000000000000" | bc -l | cut -d '.' -f 1)
                            ;;
                        P)
                            network=$(echo "${network::-1} * 1000000000000000" | bc -l | cut -d '.' -f 1)
                            ;;
                    esac
                else
                    averageRxTx=-2
                fi
                
                if [ "$averageRxTx" -lt "$network" ];
                then
                    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tThe computer will now be restarted."
                    echo -e "\t\t\t\tUptime:\t\t\t$(cat /proc/uptime | awk '{print int($1/3600)}') h\n\t\t\t\tCPU load:\t\t$currentCPULoad\n\t\t\t\tAverage net traffic:\t$averageRxTx B/s"
                    echo -e "[STOP]\t$(date +'%Y-%m-%d %H:%M:%S')\tTerminating script."
                    reboot
                else
                    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tWon't restart, because $deltaRxTx (network trafic in bytes) > $network (network traffic threshold)"
                fi
            else
                echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tWon't restart, becasue one of this process is still running: $processFound"
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
