# Description:

The project aims to send metrics (cpu, mem) of most consuming processes to graphite with a shell script

# Usage:

## Setup a sample project

    git clone https://github.com/clodio/monitoring_shell_most_consuming_processes.git
    cd monitoring_shell_most_consuming_processes
    ./monitoring_shell_most_consuming_processes.sh --json

## Customize the configuration

Open the file monitoring_shell_most_consuming_processes.sh and change if needed

### Change default values
- graphite server adress : 
    graphiteLocation="localhost" 
- preformationg data for graphite
    preformat="10sec.dev." 

# Technology used

## Graphite

- Homepage: <http://graphite.wikidot.com/>
