#!/bin/bash

# color 
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0;0m'

#bm_prg=(pagerank terasort wordcount bayes)
# PR, TS: native set, other: using highbench
bm_prg=(pagerank) 
bm_case=(near far) # add custom

sim_date1=`date +%y%m%d`
sim_date2=`date +%H%M`

exec_path=`pwd`
result_path=`pwd`/results/$sim_date1\.analysis.pf_on
script_path=`pwd`/../scripts
hadoop_path=$exec_path/../benchmarks/hadoop-1.2.1
spark_path=$exec_path/../benchmarks/spark-1.6.0

numa_near=1
numa_far=0
num_iter=3

# pagerank
# PR_input="twitter-2010.txt" # Nodes: 41,652,230, Edges: 1,468,364,884 (41m, 1468m)
# PR_input="facebook_combined.txt" # Nodes: 4,039, Edges: 88,234 (4k, 88k)
# PR_input="com-lj.ungraph.txt" # Nodes: 3,997,962, Edges: 34,681,189 (3m, 34m)
# PR_input="as-skitter.txt" # Nodes: 1,696,415, Edges: 11,095,298 (1.6m, 11m)
PR_input="com-orkut.ungraph.txt" # Nodes: 3,072,441, edges: 117,185,083 (3m, 117m)
PR_input_path=`pwd`/../benchmarks/snap_dataset/$PR_input 
PR_num_iter=10 # perf event -- should disable perf event paranoid 

# terasort
TS_input=10g
TS_input_path=`pwd`/../benchmarks/spark-terasort-master/terasort_input/$TS_input
TS_output_path=`pwd`/../benchmarks/spark-terasort-master/terasort_output/$TS_input

echo -e "${BLUE}result_path    ${NC}" ${GREEN}$result_path
echo -e "${BLUE}script_path    ${NC}" ${GREEN}$script_path
echo -e "${BLUE}execution path ${NC}" ${GREEN}$exec_path
echo -e "${BLUE}HADOOP path    ${NC}" ${GREEN}$hadoop_path
echo -e "${BLUE}SPARK path     ${NC}" ${GREEN}$spark_path${NC}


# jvm common -- should consistent with spark conf (spark_env.sh)
num_gc_thread=32

# spark common -- should constent with spark conf
java_path=/home/arc-knl/jdk1.7.0_79
#java_path=$exec_path/build/linux-amd64/bin
spark_worker_cores=32
spark_worker_memory=12g
spark_worker_instances=1
sed -i "4s@.*@export JAVA_HOME=$java_path@g" $spark_path/conf/spark-env.sh
sed -i "9s/.*/export SPARK_WORKER_CORES=$spark_worker_cores/g" $spark_path/conf/spark-env.sh
sed -i "11s/.*/export SPARK_EXECUTOR_MEMORY=$spark_worker_memory/g" $spark_path/conf/spark-env.sh
sed -i "12s/.*/export SPARK_EXECUTOR_INSTANCES=$spark_worker_instances/g" $spark_path/conf/spark-env.sh

# spark-default.conf
spark_driver_memory=2g
spark_parallelism=64
sed -i "29s/.*/spark.driver.memory $spark_driver_memory/g" $spark_path/conf/spark-defaults.conf
sed -i "30s/.*/spark.default.paralellism  $spark_parallelism/g" $spark_path/conf/spark-defaults.conf

# spark-class -- numa & perf prefix
# echo 0>/proc/sys/kernel/perf_event_paranoid with sudo -s
#perf_event_l2="r204,r404,r4F2E,r412E" # hit/miss (no pf and with pf)
perf_event_l2="r204,r404" # hit/miss (no pf and with pf)
perf_event="instructions,$perf_event_l2,cycles"
perf_prefix="perf stat -a -e $perf_event "
# sed -i "28s/.*/  PERF_PREFIX=\"$perf_prefix\"/g" $spark_path/bin/spark-class

#script options (-d: dump, -m: rdd match, -g: gc dump to csv)
script_opt="-g"
#script_opt="-d -m"

#numastat event
numastat_event="FilePages"

init_instance() {
  # set numa prefix
  # node 0: DDR4 (196484MB), node 1: MCDRAM (16384MB)
  numa_prefix="numactl --cpunodebind=0 --membind=$1 "
  sed -i "29s/.*/  NUMA_PREFIX=\"$numa_prefix\"/g" $spark_path/bin/spark-class

  # invoke master & worker nodes
  pkill java
  sleep 3
  
  echo -e "${BLUE}[HADOOP init START]${NC}"
  cd $hadoop_path/bin/
  ./start-all.sh
  sleep 3
  echo -e "${GREEN}[HADOOP init DONE]${NC}"
  
  echo -e "${BLUE}[SPARK init START]${NC}"
  cd $spark_path/sbin
  ./start-all.sh
  sleep 3
  cd $exec_path
  echo -e "${GREEN}[SPARK init DONE]${NC}"
}

set_java_env() {
  # opt_comp=" -Xint" # Interp. only
  #opt_comp=" -XComp -XX:-TieredCompilation" # C2
  opt_comp=" -server" # C2
  opt_gc=" -XX:ParallelGCThreads=$num_gc_thread -XX:+PrintGC -XX:+PrintGCDetails"
  opt_alloc=" -XX:+UseAllocProf -XX:+TraceAllocDump -XX:TraceAllocDumpFile=$result_path/${bm_prg[$1]}.alloc.dump -XX:+DumpAllocName -XX:TraceAllocDumpNameFile=$result_path/${bm_prg[$1]}.alloc.name"
  opt_misc=" -XX:+PrintCommandLineFlags -XX:-UseCompressedOops -XX:-UseFastAccessorMethods -XX:-UseAdaptiveSizePolicy"
  opt_gclog=" -Xloggc:$result_path/${bm_prg[$1]}.gclog"

  # add java options to spark conf file
  java_options="$opt_gc $opt_gclog $opt_misc"
  sed -i "31s@.*@spark.executor.extraJavaOptions $java_options@g" $spark_path/conf/spark-defaults.conf
}

run_bench() {
  case $1 in
    pagerank)
    input=$PR_input
    (time $perf_prefix ./bin/spark-submit --class org.apache.spark.examples.graphx.LiveJournalPageRank $spark_path/examples/target/spark-examples_2.10-1.6.0.jar file://$PR_input_path --numIter=$PR_num_iter --numEPart=$spark_worker_cores) > $result_path/$1.jvmlog 2>&1
    ;;

    terasort)
    input=$TS_input
    # generate input
#if [ ! -d $TS_input_path ] 
# then
    ./bin/spark-submit --class com.github.ehiggs.spark.terasort.TeraGen $spark_path/../spark-terasort-master/target/spark-terasort-1.0-SNAPSHOT-jar-with-dependencies.jar $TS_input file://$TS_input_path
# fi

    (time $perf_prefix ./bin/spark-submit --class com.github.ehiggs.spark.terasort.TeraSort $spark_path/../spark-terasort-master/target/spark-terasort-1.0-SNAPSHOT-jar-with-dependencies.jar file://$TS_input_path file://$TS_output_path) > $result_path/$1.jvmlog 2>&1
    ;;
   # no validation
  esac
}

# make result path
if [ ! -d $result_path ] 
then
  mkdir -p $result_path
fi

# main loop
for (( k=0; k< $num_iter; k++ ))
do
  for (( j=0; j < ${#bm_case[@]}; j++ ))
  do
    for (( i=0; i < ${#bm_prg[@]}; i++ ))
    do
      case ${bm_case[$j]} in
      near)
        init_instance $numa_near
        ;;
      far)
        init_instance $numa_far
        ;;
      esac
  
      echo -e "${BLUE}[${bm_prg[$i]} START]${NC}"
  
      # get numastat log -- divide this into separate function
      if [ -f $result_path/${bm_prg[$i]}.filepages.log ]
      then
        rm $result_path/${bm_prg[$i]}.filepages.log
      fi
      nohup watch -t -n 1 "(numastat -m -z | sed -n '/^$numastat_event/p' | awk '{ print $3 }') | tee -a $result_path/${bm_prg[$i]}.$numastat_event.log" &
      pid_log="$!"
  
      # run bench
      cd $spark_path
      set_java_env $i
      run_bench ${bm_prg[$i]}
      kill -9 $pid_log
      cd $exec_path
    
      # parse results
      cp $script_path/gcStatFromLog.py $result_path
      cd $result_path
      ./gcStatFromLog.py $script_opt ${bm_prg[$i]}
      grep -ri rdd ${bm_prg[$i]}.match > ${bm_prg[$i]}.match.rdd
    
      # arranging dir
      if [ ! -d $result_path/${bm_prg[$i]}/$input.$spark_worker_memory.${bm_case[$j]}.$k ]
      then 
        mkdir -p ${bm_prg[$i]}/$input.$spark_worker_memory.${bm_case[$j]}.$k
      fi
  
      mv ${bm_prg[$i]}.* ${bm_prg[$i]}/$input.$spark_worker_memory.${bm_case[$j]}.$k
      rm gcStatFromLog.py
      cd $exec_path
      # clean memchache
      #free && sync && echo 3 > /proc/sys/vm/drop_caches && free
    
      echo -e "${GREEN}[${bm_prg[$i]} is DONE]${NC}"
    done
  done
done

pkill java; sleep 3
echo -e "${GREEN}[Benchmark is DONE]${NC}"
