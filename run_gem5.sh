gem5_path=/home/jaewlee/gitroot/JVMonNUMA/gem5
binary_path=$gem5_path/binaries_$1
# disk_img_arm=$binary_path/disks/aarch64-ubuntu-trusty-headless.img
disk_img_arm=$binary_path/disks/aarch32-ubuntu-natty-headless.img
# disk_img_x86=$binary_path/disks/linux-x86-java7.img
disk_img_x86=$binary_path/disks/ubuntu-12.04.img
kernel_x86=$binary_path/binaries/vmlinux-3.2.1.smp
rcs_path=$gem5_path/runscript/rcs
chkt_path=$gem5_path/runscript/chkp
sim_date=`date +%y%m%d`
result_path=$gem5_path/runscript/results/m5out.$sim_date/$1.test
# jdk_path_x86=/jdk7-core/linux-amd64/bin 
jdk_path_x86=/jdk7-headless/usr/lib/jvm/java-7-openjdk-amd64/jre/bin
jdk_path_arm=/usr/lib/jvm/ejre1.7.0_75/bin 
bench_path=/benchmarks  # in gem5 img
bm_prg=(xalan)
min_heap=(9)
multiplier=(1)
num_gc_thread=4
# bm_prg=(avrora batik eclipse h2 jython lusearch pmd sunflow tomcat tradebeans tradesoap xalan)
# min_heap=(12 34 124 400 44 43 12 14 152 108 9)
# multiplier=(1 1.5 2 3 5 10)

set_java_env() {
  prg=$1
  heap=$2
  sys=$3
  opt_comp=" -server" #c2
  opt_gc=" -XX:ParallelGCThreads=$num_gc_thread -XX:+PrintGC -XX:+PrintGCDetails"
  opt_heap=" -Xms${heap}m -Xmx${heap}m "
  opt_gclog="" 
  # opt_gem5=" -XX:+UseGem5Hooks -XX:-UseCompressedOoops"
  opt_gem5="" 
  opt_misc=" -XX:+PrintCommandLineFlags -XX:-UseFastAccessorMethods -XX:-UseAdaptiveSizePolicy -XX:+UseGCOverheadLimit -XX:GCTimeLimit=70"
  if [[ $sys == "arm" ]] 
  then
    java_opt="$opt_comp $opt_gc $opt_heap $opt_misc"
  elif [[ $sys == "x86" ]]
  then
    java_opt="$opt_comp $opt_gc $opt_heap $opt_gem5 $opt_misc"
  fi

  # dacapo option
  bench_niter=1
  bench_nth=4  # the same as num core
  bench_input=large
}

make_rcS() {
  prg=$1
  sys=$2
  if [[ ! -d ./rcs/$sys ]] 
  then
    mkdir -p ./rcs/$sys
  fi

  # making rcS file for each benchmarks 
  echo "#!/bin/bash"         > ./rcs/$sys/$prg.rcS
  echo ""                   >> ./rcs/$sys/$prg.rcS
  echo ""                   >> ./rcs/$sys/$prg.rcS
  echo "cd /benchmarks/"    >> ./rcs/$sys/$prg.rcS
  echo "/sbin/m5 dumpstats" >> ./rcs/$sys/$prg.rcS
  echo "/sbin/m5 resetstat" >> ./rcs/$sys/$prg.rcS
  if [[ $sys == "arm" ]]
  then
    echo "$jdk_path_arm/java $java_opt -jar $bench_path/dacapo-9.12-bach.jar $prg -n $bench_niter -t $bench_nth -s $bench_input" >> ./rcs/$sys/$prg.rcS
  elif [[ $sys == "x86" ]]
  then
    echo "$jdk_path_x86/java $java_opt -jar $bench_path/dacapo-9.12-bach.jar $prg -n $bench_niter -t $bench_nth -s $bench_input" >> ./rcs/$sys/$prg.rcS
  fi

  echo ""                   >> ./rcs/$sys/$prg.rcS
  echo "/sbin/m5 exit"      >> ./rcs/$sys/$prg.rcS
  echo ""                   >> ./rcs/$sys/$prg.rcS
  echo
}

set_gem5_env() {
  sys=$1
  arch_opt=" --num-cpus=4 --cpu-clock=2.8GHz --caches --l2cache --l1d_size=64kB --l1i_size=64kB --l2_size=8192kB --cacheline_size=64 --mem-size=2097152kB "
  bin_opt=opt
  # run gem5
  if [[ $1 == "arm" ]]
  then
    disk_opt=" --disk-image=$disk_img_arm"
  elif [[ $1 == "x86" ]]
  then
    kernel_opt=" --kernel=$kernel_x86"
    # kernel_opt=""
    disk_opt=" --disk-image=$disk_img_x86"
  fi


}

run_gem5() {
  prg=$1
  sys=$2
  core=$3

  if [ ! -d $result_path/out.$prg ]
  then
    mkdir -p $result_path/out.$prg
  fi

  # run gem5
  if [[ $2 == "arm" ]]
  then
    if [ ! -d $result_path/out.$prg ]
    then
      mkdir -p $result_path/out.$prg
    fi
    export M5_PATH=$gem5_path/binaries_$2
    # numactl -C 0 $gem5_path/build/ARM/gem5.$bin_opt --outdir=$result_path/out.$prg $gem5_path/configs/example/fs.py $arch_opt $disk_opt --script=./rcs/$2/$prg.rcS --machine-type=VExpress_EMM > $result_path/out.$prg/gem5.log 2>&1 &
    $gem5_path/build/ARM/gem5.opt --outdir=$result_path/out.${bm_prg[$i]} $gem5_path/configs/example/fs.py --disk-image=$disk_img_arm --machine-type=VExpress_EMM $arch_opt
  elif [[ $2 == "x86" ]]
  then
    export M5_PATH=$gem5_path/binaries_$2
    numactl -C 1 $gem5_path/build/X86/gem5.$bin_opt --outdir=$result_path/out.$prg $gem5_path/configs/example/fs.py $arch_opt $disk_opt $kernel_opt --script=./rcs/$2/$prg.rcS > $result_path/out.$prg/gem5.log 2>&1 &
    sleep 3
    # $gem5_path/build/X86/gem5.opt -d AMD64 --outdir=$result_path/out.$prg $gem5_path/configs/example/fs.py $disk_opt $kernel_opt $arch_opt
  fi
}

# main
set_gem5_env $1
for (( i=0; i < ${#bm_prg[@]}; i++ ))
do
  for (( j=0; j < ${#multiplier[@]}; j++ ))
  do
    tmp_cur_heap=`echo ${min_heap[$i]}*${multiplier[$j]} | bc -l`
    cur_heap=`printf "%.0f" $tmp_cur_heap`

    set_java_env ${bm_prg[$i]} $cur_heap $1
    make_rcS ${bm_prg[$i]} $1
    # [fixme] chkpoint run
    # actual gem5 run
    run_gem5 ${bm_prg[$i]} $1 $i
  done
done
echo "1234" | sudo -S ./free.sh
