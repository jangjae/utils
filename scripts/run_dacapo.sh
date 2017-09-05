#!/bin/bash

# color 
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0;0m'

# export MALLOC_ARENA_MAX=1
# bm_prg=(avrora batik eclipse fop h2 jython luindex lusearch pmd sunflow tomcat tradebeans tradesoap xalan) 
bm_prg=(jython)
input_size=large
heap_size=(44.0)

sim_date1=`date +%y%m%d`
sim_date2=`date +%H%M`

exec_path=`pwd`
# result_path=`pwd`/results/$sim_date1\.dacapo.minheap.$input_size
dacapo_path=`pwd`/../benchmarks

result_path=`pwd`/results/$sim_date1\.dacapo.minheap.$input_size.each
script_path=`pwd`

echo -e "${BLUE}result_path    ${NC}" ${GREEN}$result_path
echo -e "${BLUE}execution path ${NC}" ${GREEN}$exec_path
echo -e "${BLUE}dacapo path    ${NC}" ${GREEN}$dacapo_path

# jvm common -- should consistent with spark conf (spark_env.sh)
num_mutator_thread=4
num_gc_thread=4
num_iter=1
num_instances=1
script_opt="-g" # gc dump

# spark common -- should constent with spark conf
java_path=/home/arc-p152/jdk1.7.0_79/jre

set_java_env() {
  prg=$1
  heap=$2
  opt_comp=" -server" # C2
  # opt_comp=" -Xmixed -XX:+TieredCompilation -XX:TieredStopAtLevel=3" # c1 only, c1 = 1,2,3, c2 = 4
  opt_gc=" -XX:ParallelGCThreads=$num_gc_thread -XX:+PrintGC -XX:+PrintGCDetails"
  opt_heap=" -Xms${heap}m -Xmx${heap}m "
  opt_gclog=" -Xloggc:$result_path/${bm_prg[$prg]}.`expr $num_instances - 1`.gclog"
  opt_misc=" -XX:+PrintCommandLineFlags -XX:-UseCompressedOops -XX:-UseFastAccessorMethods -XX:-UseAdaptiveSizePolicy -XX:+UseGCOverheadLimit -XX:GCTimeLimit=70"
  java_options="$opt_comp $opt_gc $opt_gclog $opt_heap $opt_misc"
}

# make result path
if [ ! -d $result_path ] 
then
  mkdir -p $result_path
fi

run_bench() {
  bm_prg=$1

  # DaCapo run
  (time $java_path/bin/java $java_options -jar $dacapo_path/dacapo-9.12-bach.jar $bm_prg -t $num_mutator_thread -n $num_iter -s $input_size) > $result_path/$bm_prg.jvmlog 2>&1
}


# main loop
for (( i=0; i < ${#bm_prg[@]}; i++ ))
do
  for (( j=0; j < ${#heap_size[@]}; j++ ))
  do
    echo -e "${BLUE}[${bm_prg[$i]}, ${heap_size[$j]} starts]${NC}"

    # run bench
    set_java_env $i ${heap_size[$j]}
    run_bench ${bm_prg[$i]} ${heap_size[$j]}
  
    # parse results
    cp $script_path/gcStatFromLog.py $result_path
    cd $result_path
    ./gcStatFromLog.py $script_opt ${bm_prg[$i]} $num_instances
  
    # arranging dir
    if [ ! -d $result_path/${bm_prg[$i]}/${heap_size[$j]} ]
    then 
      mkdir -p ${bm_prg[$i]}/${heap_size[$j]}
    fi

    mv ${bm_prg[$i]}.* ${bm_prg[$i]}/${heap_size[$j]}
    rm gcStatFromLog.py
    cd $exec_path

    # clean memchache
    #free && sync && echo 3 > /proc/sys/vm/drop_caches && free
  
    echo -e "${GREEN}[${bm_prg[$i]} is DONE]${NC}"
  done
done

pkill java; sleep 3
echo -e "${GREEN}[Benchmark is DONE]${NC}"
