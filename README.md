# Auto restart
This script will try to reboot the computer if set parameters are met. Suitable for Linux based computers.

## Requirements
* bash
* awk

## Usage
`./auto_restart.sh [OPTION]...`

## Options
* `-h, --help` Print help text and terminates.
* `-c <average-load>, --cpu <average-load>` Sets threshold for average cpu load. Parameter `<average-load>` needs to be formated as three float numbers separated by comma (e.g., 0.30,0.15,0.05). The three numbers represent avarege load for the past 1, 5 and 15 minutes and will be compared to uptime's value. Each given average value has to be lower or equal in order to reboot the computer.
* `-n <network-usage>, --network <network-usage>` Threshold for network traffic utilization. Interface with highest traffic utilization will be compared to the `<network-usage>`. Value `<network-usage>` is expected to be in bytes per second.
* `--net-interval <interval>` Interval of measurement of network traffic usage defined by `<interval>` in seconds. Default vaule is 30 seconds
* `-p <processes>, --proc <processes>` List of `<processes>` that can't be running when attempting to reboot. The list has to be composed of the names of the processes separated by comma.
* `-i <time>, --interval <time>` Interval in seconds specified by `<time>` between individual tries to reboot. Default value is 900 seconds.
* `-t <end-time>, --time <end-time>` Specifies until what `<end-time>` should the script try to reboot the PC. It has to be in 24-hour format (e.g., starting the script at 23:00 and setting -t 04:00 will result in 5 hour time window in which the script will try to reboot the system). Default value is "5:00".
* `-u <time>, --uptime <time>` Sets threshold for uptime. If the computer is running longer than `<time>` it will try to reboot. Parameter is expected in hours.
