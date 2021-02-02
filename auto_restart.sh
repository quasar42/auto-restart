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
    echo -e "\t${BOLD}-h${RA}, ${BOLD}--help${RA}\t\t\tPrint this help text and terminates."
    echo -e "\t${BOLD}-c${RA}, ${BOLD}--cpu${RA} ${UND}average-load${RA}\t\tSets threshold for average cpu load. Parameter ${UND}average-load${RA} needs to be\n\t\t\t\t\tformatted as three float numbers separated by comma (e.g., 0.30,0.15,0.05).\n\t\t\t\t\tThe three numbers represent average load for the past 1, 5 and 15 minutes\n\t\t\t\t\tand will be compared to uptime's value. Each given average value has to be\n\t\t\t\t\tlower or equal in order to reboot the computer."
    echo -e "\t${BOLD}-n${RA}, ${BOLD}--network${RA} ${UND}network-usage${RA}\tThreshold for network traffic utilization. Interface with the highest\n\t\t\t\t\ttraffic utilization will be compared to the ${UND}network-usage${RA}.\n\t\t\t\t\tValue ${UND}network-usage${RA} is expected to be in bytes per second."
    echo -e "\t    ${BOLD}--net-interval${RA} ${UND}interval${RA}\tInterval of measurement of network traffic usage defined by ${UND}interval${RA}\n\t\t\t\t\tin seconds. Default value is 30 seconds."
    echo -e "\t${BOLD}-p${RA}, ${BOLD}--proc${RA} ${UND}processes${RA}\t\tList of ${UND}processes${RA} that can't be running when attempting to reboot. The list\n\t\t\t\t\thas to be composed of the names of the processes separated by comma."
    echo -e "\t${BOLD}-i${RA}, ${BOLD}--interval${RA} ${UND}time${RA}\t\tInterval in seconds specified by ${UND}time${RA} between individual tries to reboot.\n\t\t\t\t\tDefault value is 900 seconds."
    echo -e "\t${BOLD}-t${RA}, ${BOLD}--time${RA} ${UND}end-time${RA}\t\tSpecifies until what ${UND}end-time${RA} should the script try to reboot the PC.\n\t\t\t\t\tIt has to be in 24-hour format (e.g., starting the script at 23:00 and\n\t\t\t\t\tsetting -t 04:00 will result in 5 hour time window in which the script\n\t\t\t\t\twill try to reboot the system). Can be combined with ${BOLD}--amount-of-tries${RA}\n\t\t\t\t\tand ${BOLD}--timeout${RA}. Whichever of the set parameter is reached first is used."
    echo -e "\t${BOLD}-u${RA}, ${BOLD}--uptime${RA} ${UND}time${RA}\t\tSets threshold for uptime. If the computer is running longer than ${UND}time${RA}\n\t\t\t\t\tit will try to reboot. Parameter is expected in hours."
    echo -e "\t${BOLD}-a${RA}, ${BOLD}--amount-of-tries${RA} ${UND}amount${RA}\tWill only try to restart ${UND}amount${RA} of times. Can be combined with ${BOLD}--time${RA}\n\t\t\t\t\tand ${BOLD}--timeout${RA}. Whichever of the set parameter is reached first is used.\n\t\t\t\t\tValue ${UND}amount${RA} is unlimited by default."
    echo -e "\t${BOLD}-o${RA}, ${BOLD}--timeout${RA} ${UND}time${RA}\t\tWill only try to restart if total time elapsed from the start of the script\n\t\t\t\t\tis lower than ${UND}time${RA}. Value is expeced in minutes. Can be combined with\n\t\t\t\t\t${BOLD}--time${RA} and ${BOLD}--amount-of-tries${RA}. Whichever of the set parameter is reached\n\t\t\t\t\tfirst is used. Value ${UND}time${RA} is unlimited by default."
    echo -e "\t${BOLD}-e${RA}, ${BOLD}--execute${RA} ${UND}command${RA}\t\tInstead of rebooting, custom ${UND}command${RA} will be executed."
    echo -e "\t${BOLD}-r${RA}, ${BOLD}--human-readable${RA}\t\tPrints network traffic sizes in power of 1000 (e.g., 4.8 M)."
    echo -e "\t${BOLD}-d${RA}, ${BOLD}--dry-run${RA}\t\t\tWon't reboot if the parameters are met, just prints a message."
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

function scriptTerminate() {
    echo -e "[STOP]\t$(date +'%Y-%m-%d %H:%M:%S')\tRequirements not reached, $@, terminating script"
    exit
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
            cpuLoad_F=true
            shift # past argument
            shift # past value
            ;;
        -n|--network)
            network="$2"
            network_F=true
            shift # past argument
            shift # past value
            ;;
        --net-interval)
            netInterval="$2"
            netInterval_F=true
            shift # past argument
            shift # past value
            ;;
        -p|--proc)
            proc="$2"
            proc_F=true
            shift # past argument
            shift # past value
            ;;
        -i|--interval)
            interval="$2"
            interval_F=true
            shift # past argument
            shift # past value
            ;;
        -t|--time)
            endTime="$2"
            endTime_F=true
            shift # past argument
            shift # past value
            ;;
        -u|--uptime)
            uptime="$2"
            uptime_F=true
            shift # past argument
            shift # past value
            ;;
        -a|--amount-of-tries)
            numOfTries="$2"
            numOfTries_F=true
            shift # past argument
            shift # past value
            ;;
        -o|--timeout)
            timeout="$2"
            timeout_F=true
            shift # past argument
            shift # past value
            ;;
        -e|--execute)
            execute="$2"
            execute_F=true
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
    echoerr "Error: unknown option \"$1\"."
    exit 0
fi

errorInArguments=false

if [[ ! -z "$cpuLoad_F" ]];
then
    if [[ "$cpuLoad" == "1" || "$(echo $cpuLoad | sed 's/[0-9]\+.[0-9]\{0,2\},[0-9]\+.[0-9]\{0,2\},[0-9]\+.[0-9]\{0,2\}/1/g')" != "1" ]];
    then
        echoerr "Error: CPU load in wrong format. Need \"X,Y,Z\", where X is CPU load for last 1 minute, Y for last 5 minutes and Z for last 15 minutes in float (e.g., 0.30,0.15,0.05), got \"$cpuLoad\""
        errorInArguments=true
    fi
fi

if [[ -z "$network_F" ]];
then
    network=-1
else
    if [[ "$network" == "1" || "$(echo $network | sed 's/[0-9]\+\(\(.[0-9]\+[kMGTP]\)\|[kMGTP]\)\?/1/g')" != "1" ]];
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
    
    if [[ -z "$netInterval_F" ]];
    then
        netInterval=30
    else
        if ! [[ $netInterval =~ $isNum ]];
        then
            echoerr "Error: network traffic monitoring interval in wrong format. Need \"X\", where X represents inteval in seconds. Got \"$netInterval\""
            errorInArguments=true
        fi
    fi
fi

if [[ ! -z "$proc_F" ]];
then
    if [[ "$proc" == "1" || "$(echo $proc | sed 's/^.*,,.*$/1/g')" == "1" || "$proc" == "" ]];
    then
        echoerr "Error: list of processes in wrong format. Need \"X,X,X...\", where X represents name of a process. Got \"$proc\""
        errorInArguments=true
    fi
fi

if [[ -z "$interval_F" ]];
then
    interval=900
else
    if ! [[ $interval =~ $isNum ]];
    then
        echoerr "Error: interval for reboot try in wrong format. Need \"X\", where X represents inteval in seconds. Got \"$interval\""
        errorInArguments=true
    fi 
fi

if [[ ! -z "$endTime_F" ]];
then
    if [[ "$endTime" == "1" || "$(echo $endTime | sed 's/\(\([0-1]\?[0-9]\)\|\(2[0-3]\)\):[0-5][0-9]/1/g')" != "1" ]];
    then
        echoerr "Error: end time in wrong format. Need \"HH:MM\" in 24-hour format (e.g., 05:00, or 5:00). Got \"$endTime\""
        errorInArguments=true
    else
        endTime_H="$(echo $endTime | awk -F ':' '{print $1}' | sed 's/^0*//')"
        endTime_M="$(echo $endTime | awk -F ':' '{print $2}' | sed 's/^0*//')"
        if [[ "$endTime_H" -lt "$(date +%H | sed 's/^0*//')" || ( "$endTime_H" -eq "$(date +%H | sed 's/^0*//')" && "$endTime_M" -lt "$(date +%M | sed 's/^0*//')" ) ]];
        then
            dayEarly=true
        else
            dayEarly=false
        fi
        echo "day early: $dayEarly"
    fi
fi

if [[ -z "$uptime_F" ]];
then
    uptime=-1
else
    if ! [[ $uptime =~ $isNum ]];
    then
        echoerr "Error: uptime in wrong format. Need \"X\", where X represents uptime in hours. Got \"$uptime\""
        errorInArguments=true
    fi
fi

if [[ -z "$numOfTries_F" ]];
then
    numOfTries=-1
else
    if ! [[ $numOfTries =~ $isNum ]];
    then
        echoerr "Error: amount of reboot tries in wrong format. Need \"X\", where X represents number of tries to reboot. Got \"$numOfTries\""
        errorInArguments=true
    else
        triesCounter=1
    fi
fi

if [[ -z "$timeout_F" ]];
then
    timeout=-1
else
    if ! [[ $timeout =~ $isNum ]];
    then
        echoerr "Error: timeout in wrong format. Need \"X\", where X represents timeout for reboot tries and is expected to be in minutes. Got \"$timeout\""
        errorInArguments=true
    else
        timeoutStart="$(date +%s)"
    fi 
fi

if [[ ! -z "$execute_F" ]];
then
    if ! command -v $(echo "$execute" | awk -F ' ' '{print $1}') >/dev/null;
    then
        echoerr "Error: command to execute is not recognized by this system. Got \"$execute\""
        errorInArguments=true
    fi
fi

if [ "$errorInArguments" = true ];
then
    printHelp
fi

echo -e "[START]\t$(date +'%Y-%m-%d %H:%M:%S')\tStarting auto restart script. Set options:"

if [[ ! -z "$cpuLoad_F" ]];
then
    echo -e "\t\t\t\tCPU load:\t\t\t\t$cpuLoad"
fi

if [[ ! -z "$network_F" ]];
then
    echo -e "\t\t\t\tAverage network traffic:\t\t$(numToHumanReadable $network)B/s"
    echo -e "\t\t\t\tNetwork traffic measurement interval:\t$netInterval s"
fi

if [[ ! -z "$proc_F" ]];
then
    echo -e "\t\t\t\tProcesses:\t\t\t\t$proc"
fi

if [[ ! -z "$interval_F" ]];
then
    echo -e "\t\t\t\tRestart try interval:\t\t\t$interval s"
fi

if [[ ! -z "$endTime_F" ]];
then
    echo -e "\t\t\t\tScript end time:\t\t\t$endTime"
fi

if [[ ! -z "$uptime_F" ]];
then
    echo -e "\t\t\t\tUptime:\t\t\t\t\t$uptime h"
fi

if [[ ! -z "$numOfTries_F" ]];
then
    echo -e "\t\t\t\tNumber of tries:\t\t\t$numOfTries"
fi

if [[ ! -z "$timeout_F" ]];
then
    echo -e "\t\t\t\tTimeout:\t\t\t\t$timeout min"
fi

if [[ ! -z "$execute_F" ]];
then
    echo -e "\t\t\t\tExecute command:\t\t\t$execute"
fi

while true;
do
    if [[ "$uptime" -le "$(cat /proc/uptime | awk '{print int($1/3600)}')" ]]
    then
        currentCPULoad="$(LC_ALL=en_GB.utf8 uptime | sed 's/, /,/g' | awk -F ' ' '{print $NF}')"
        if [[ -z "$cpuLoad" || "$(echo "$currentCPULoad,$cpuLoad" | awk -F ',' '{if ($1 <= $4 && $2 <= $5 && $3 <= $6) print "1"; else print "0";}')" == "1" ]];
        then
            processFound=0

            if [[ ! -z "$proc_F" ]];
            then
                IFS=',' read -ra processes <<<$proc
                for process in "${processes[@]}";
                do
                    if [[ "$(pgrep $process | wc -l)" -gt "0" ]];
                    then
                        if [[ "$processFound" == "0" ]];
                        then
                            processFound=$process
                        else
                            processFound="$processFound $process"
                        fi
                    fi
                done
            fi

            if [[ "$processFound" == "0" ]];
            then
                if [[ ! -z "$network_F" ]];
                then
                    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tStarting network traffic monitorig for $netInterval s"
                    oldRxTx="$(cat /proc/net/dev | grep -e '.*:.*' | awk '{sum += $2 + $10} END {printf "%.f", sum}')"
                    sleep $netInterval
                    deltaRxTx="$(expr $(cat /proc/net/dev | grep -e '.*:.*' | awk '{sum += $2 + $10} END {printf "%.f", sum}') - $oldRxTx)"
                    averageRxTx="$(echo "$deltaRxTx $netInterval" | awk '{var = $1 / $2} END {printf "%.f", var}')"
                else
                    averageRxTx=-2
                fi
                
                if [ "$averageRxTx" -lt "$network" ];
                then
                    echo -e "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tThe computer will be restarted now."
                    echo -en "\t\t\t\tCPU load:\t\t$currentCPULoad"
                    if [[ -z "$cpuLoad_F" ]];
                    then
                        echo ""
                    else
                        echo -e "\tThreshold: $cpuLoad"
                    fi

                    if [[ ! -z "$network_F" ]];
                    then
                        echo -e "\t\t\t\tAverage net traffic:\t$(numToHumanReadable $averageRxTx)B/s\tThreshold: $(numToHumanReadable $network)B/s"
                    fi

                    echo -en "\t\t\t\tUptime:\t\t\t$(cat /proc/uptime | awk '{print int($1/3600)}') h ($(uptime -p))"
                    if [[ ! -z "$uptime_F" ]];
                    then
                        echo -e "\t\tThreshold: $uptime h"
                    else
                        echo ""
                    fi

                    echo -e "[STOP]\t$(date +'%Y-%m-%d %H:%M:%S')\tTerminating script"

                    if [[ -z "$dryRun" ]];
                    then
                        if [[ -z "$execute_F" ]];
                        then
                            shutdown -r
                        else
                            bash -c "$execute"
                        fi
                    else
                        echo -e "\t\t\t\t###################################"
                        echo -e "\t\t\t\t##                               ##"
                        echo -e "\t\t\t\t##  DRY RUN - WOULD RESTART NOW  ##"
                        echo -e "\t\t\t\t##                               ##"
                        echo -e "\t\t\t\t###################################"
                    fi
                    exit 0
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

    echo -en "[INFO]\t$(date +'%Y-%m-%d %H:%M:%S')\tWill sleep for $interval seconds"
    
    if [[ ! -z $numOfTries_F ]];
    then
        echo -n ", this was try number $triesCounter"
    fi
    
    if [[ ! -z $timeout_F ]];
    then
        runningTime="$(echo "$timeoutStart $(date +%s)" | awk '{print int(($2 - $1) / 60)}')"
        echo -n ", script is running for $runningTime minute"
        if [[ "$runningTime" -ne "1" ]];
        then
            echo -n "s"
        fi
    fi
    echo ""
    
    sleep $interval

    if [[ ! -z $endTime_F ]];
    then
        if [[ "$dayEarly" == "true" && "$endTime_H" -ge "$(date +%H | sed 's/^0*//')" && "$endTime_M" -gt "$(date +%M | sed 's/^0*//')" ]];
        then
            dayEarly=false
        fi
        
        if [[ "$dayEarly" == "false" && "$endTime_H" -le "$(date +%H | sed 's/^0*//')" && "$endTime_M" -lt "$(date +%M | sed 's/^0*//')" ]];
        then
            scriptTerminate "real time exceeded set end time ($endTime)"
        fi
    fi
    
    if [[ ! -z $numOfTries_F ]];
    then
        if [[ "$triesCounter" -lt "$numOfTries" ]];
        then
            ((triesCounter++))
        else
            scriptTerminate "number of tries exceeded set amount of tries ($numOfTries)"
        fi
    fi
    
    if [[ ! -z $timeout_F ]];
    then
        if [[ "$(echo "$timeoutStart $(date +%s)" | awk '{print int(($2 - $1) / 60)}')" -ge "$timeout" ]];
        then
            scriptTerminate "script was running longer than the set timeout ($timeout)"
        fi
    fi
done
