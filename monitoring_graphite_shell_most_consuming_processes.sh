#/bin/bash

# Monitor most consummming process for a period and output data in graphite or log


usage ()
{
  echo '    -l|--log : log in a file :  default : false' 
  echo '    -g|--graphite : export data to graphite :  default : false'
  echo '    -a|--graphiteLocation  : graphiteLocation : default localhost'
  echo '    -f|--preformat : preformat to graphite (default 10sec.dev)'
  echo '    -n|--nbIteration : nb iteration checking process (default 8640)'
  echo '    -i|--interval : intervall between checks (default 10sec)' 
  exit
}


#default values
graphiteLocation="localhost" #graphite server adress
preformat="10sec.dev." #preformationg data for graphite
nbProcessToMonitor=5 #not dynamic : max process to monitor
minCpuUsageToMonitor=3 #not dynamic : trigger %cpu to monitor
nbIteration=8640 #nb iteration checking process
interval=10 #interval in seconds to ckeck process
log="False"
graphite="False"

while [ "$1" != "" ]; do
case $1 in
        -l|--log )           shift
                       log="True"
                       ;;
        -g|--graphite )           shift
                       graphite="True"
                       ;;
        -a|--graphiteLocation )           shift
                       serveurGraphiteIP=$1
                       ;;
        -p|--process )           shift
                       process=$1
                       ;;
        -f|--preformat )           shift
                       preformat=$1
                       ;;
        -n|--nbIteration )           shift
                       nbIteration=$1
                       ;;
        -i|--interval )           shift
                       interval=$1
                       ;;
        -h|--help )           shift
                       usage
                       ;;
        * )            QUERY=$1
    esac
    shift
done


a=0
currrent_date_file=$(date +'%Y-%m-%d-%H-%M-%S');
if [[ $log == "True" ]]; then echo "Writing in the file /tmp/perf_processes_most_consumming_"$currrent_date_file".log"; fi

echo "date|processname|nbprocess|TotalRSSMemory(kb)|TotalSZMemory(kb)|MemoryPerProcess(kb)|totalCPU"

while [ $a -lt $nbIteration ]
do
	
	processList=$(ps -eo "comm %cpu %mem" --no-headers | awk '{a[$1] = $1; b[$1] += $2; c[$1] += $3; d[$1]+=1;}END{for (i in a)printf "%s %0.1f %0.1f %d\n", a[i], b[i], c[i], d[i]}' | sort -k 2 -r | head -n5 | awk -F' ' '{if ($2>3) {print $1;}}' )
	#nbProcessToMonitor=5 (head -n5)
	#minCpuUsageToMonitor=3 ($2>3)
	
	for process in $(echo $processList | sed 's/|/ /g')
	do

		totalrss=0
		#S+, SS :  filter ps and root process

		metric="rss"
		totalrss=$(ps -A -o pid,$metric,command,stat | grep $process | grep -v "S+" | grep -v "Ss" | awk '{total+=$2}END{printf("%d", total)}')

		totalsz=0
		nbprocess=0
		metric="sz"
		totalsz=$(ps -A -o pid,$metric,command,stat  | grep $process | grep -v grep | grep -v "Ss"  | awk '{total+=$2}END{printf("%d", total)}')
		nbprocess=$(ps -A -o pid,$metric,command,stat  | grep $process | grep -v grep | grep -v "Ss"  | wc -l )

		totalcpu=0
		metric="%cpu"
		totalcpu=$(ps -Ao "comm %cpu" --no-headers | grep $process | awk '{a["cpu"] += $2;}END{printf "%0.1f", a["cpu"]}')
		
		memoryperprocess=$(( ( $totalsz + $totalrss ) ));
		if [[ $nbprocess -ne 0 ]]; then
		      memoryperprocess=$(( $memoryperprocess/$nbprocess ))
		else
			memoryperprocess=0
		fi

		currentdate=$(date +'%Y/%m/%d %H:%M:%S');
	
		
		echo $currentdate"|"$process"|"$nbprocess"|"$totalrss"|"$totalsz"|"$memoryperprocess"|"$totalcpu
		
		#export to log file
		if [[ $log == "True" ]]; then echo $currentdate"|"$process"|"$nbprocess"|"$totalrss"|"$totalsz"|"$memoryperprocess"|"$totalcpu >>"/tmp/perf_processes_"$currrent_date_file".log"; fi

		#export graphite
		if [[ $graphite == "True" ]] ;  then 
			echo $preformat$HOSTNAME'.processes.memory.'$process'.totalsz' $totalsz $(date +%s) | nc  $graphiteLocation 2003;
			echo $preformat$HOSTNAME'.processes.memory.'$process'.totalrss' $totalrss $(date +%s) | nc  $graphiteLocation 2003;
			echo $preformat$HOSTNAME'.processes.nbprocess.'$process $nbprocess $(date +%s) | nc  $graphiteLocation 2003;
			echo $preformat$HOSTNAME'.processes.cpu.'$process'.totalcpu' $totalcpu $(date +%s) | nc  $graphiteLocation 2003;
		fi

	done
	sleep $interval
	a=$(($a+1))
done


