#! /usr/bin/python

import sys, os, re
import argparse

class gcStat:
    # total_mut_time = 0
    cur_alloc_size = 0
    total_exec_time = 0.0
    total_sys_time = 0.0
    instructions= 0.0
    l2hits = 0.0
    l2misses= 0.0
    l2hits_pf = 0.0
    l2misses_pf = 0.0
    cycles= 0.0
    mpki = 0.0
    cpi = 0.0
    bandwidth = 0.0

    cur_ygc_time = []
    cur_fgc_time = []
    total_ygc_time = []
    total_fgc_time = []
    total_num_ygc = []
    total_num_fgc = []
    total_alloc_size = []
    allocation_rate = []
    
    total_acnt = 0
    line_cnt = 0
    tmp_acnt = 0 
    acnt_threshold = 0
    
    def parse_line(self, line):
    	line = re.sub('\n', ' ', line)
    	line = re.sub(',', ' ', line)
    	line = re.sub(' ', ' ', line)
    	line = re.sub('->', ' ', line)
    	line = re.sub('K', ' ', line)
    	line = re.sub('m', ' ', line)
    	line = re.sub('s', ' ', line)
    	return re.split('\s*', line)

    def parse_line_report(self, line):
    	line = re.sub('\n', ' ', line)
    	line = re.sub(' ', ' ', line)
    	return re.split('\s*', line)

    def parse_gclog(self, inf, outf, numlog):
        outf.write("# TimeStamp, YGC/FGC, Footprint, Reclaimed, Elapsed Time \n")
        self.total_num_ygc.append(0)
        self.total_num_fgc.append(0)
        self.total_alloc_size.append(0)
        self.total_ygc_time.append(0.0)
        self.total_fgc_time.append(0.0)
        for line in inf:
            t = self.parse_line(line)
            if len(t) > 2:
                if t[1] == "[GC" and len(t) > 10:
                    self.total_num_ygc[numlog] += 1
                    self.total_ygc_time[numlog] += float(t[11])
                    self.total_alloc_size[numlog] += int(t[7], 10) - int(t[8], 10)
                    # fprint tuple (timestamp, y/f, footprint, reclaimed, time) to logfile
                    t[0] = re.sub(':', '', t[0])
                    outf.write(t[0] + ",Y," + t[7] + "," + str(int(t[7], 10) - int(t[8], 10)) + "," + t[11] + "\n")
                elif t[1] == "[Full" and len(t) > 22:
                    self.total_num_fgc[numlog] += 1
                    self.total_fgc_time[numlog] += float(t[23])
                    self.total_alloc_size[numlog] += int(t[13], 10) - int(t[14], 10)
                    # fprint tuple (timestamp, y/f, footprint, reclaimed, time) to logfile
                    t[0] = re.sub(':', ' ', t[0])
                    outf.write(t[0] + ",F," + t[13] + "," + str(int(t[13], 10) - int(t[14], 10)) + "," + t[23] + "\n")
    
    def parse_jvmlog(self, inf):
        for line in inf:
            t = self.parse_line(line)
            if len(t) > 2:
                if t[0] == "real":
                    self.total_exec_time = float(t[1])*60 + float(t[2])
                elif t[0] == "sys":
                    self.total_sys_time = float(t[1])*60 + float(t[2])

                # for stream benchmark
                if (t[0] == "Total") and (t[3] == "bandwidth:"):
                  t = re.sub('MB/', '', t[5])
                  self.bandwidth = int(t, 10)
                
                #t = re.sub(' ', '',  line)
                t = re.sub('\t', ' ', line)
                t = re.split('\s*',   line)
                if (t[1] == "instructions"):
                  self.instructions = float(re.sub(',', '', t[0]))
                elif (t[2] == "instructions"):
                  self.instructions = float(re.sub(',', '', t[1]))
                if t[2] == "r204":
                  self.l2hits = float(re.sub(',', '', t[1]))
                if t[2] == "r404":
                  self.l2misses = float(re.sub(',', '', t[1]))
                if t[2] == "r4F2E":
                  self.l2hits_pf = float(re.sub(',', '', t[1]))
                if t[2] == "r412E":
                  self.l2misses_pf = float(re.sub(',', '', t[1]))
                if (t[1] == "cycles"):
                  self.cycles = float(re.sub(',', '', t[0]))
                elif (t[2] == "cycles"):
                  self.cycles = float(re.sub(',', '', t[1]))

    def parse_report(self, inf):
      for line in inf:
        t = self.parse_line_report(line)
        self.total_exec_time = float(t[4])
    
    def parse_dump(self, inf, hotratio):
        for line in inf:
            t = self.parse_line(line)
            self.total_acnt += int(t[2], 10)
            
        self.acnt_threshold = int(float(self.total_acnt) * hotratio)
        inf.seek(0)
        for line in inf:
            self.line_cnt += 1
            t = self.parse_line(line)
            self.tmp_acnt += int(t[2])
            if self.tmp_acnt > self.acnt_threshold:
                return self.line_cnt

    def parse_match(self, inf, inf_n, outf):
        for line1 in inf:
            t = self.parse_line(line1)
            hashval = int(t[0], 10)
            bci = int(t[1], 10)
            count = int(t[2], 10)
            for line2 in inf_n:
    	        tmp_line = re.sub(' ', ' ', line2)
    	        t = re.split('\s*', tmp_line)
                nhashval = int(t[1], 10)
                if hashval == nhashval:
                    name = t[0]
                    l = [str(hashval), str(bci), str(count), name]
                    outf.write(' '.join(l))
                    outf.write('\n')
                    inf_n.seek(0)
                    break

    def parse_vtune_stat(self, inf, outf):
      while True:
        line = inf.readline()  
        if line == "General Exploration Metrics\n":
          while True:
            line = inf.readline()
            if line == "Collection and Platform Info\n": break 
            print line 
            outf.write(line)
            

        if line == "Summary\n":
          while True:
            line = inf.readline()
            if line == "Event summary\n": break 
            print line
            outf.write(line)
            line = re.sub(' ', ' ', line)
            t = re.split('\s*', line)
            if t[0] == "Elapsed":
              self.total_exec_time = float(t[2])

        if not line: break #EOF
      
    def print_on(self, outf):
        self.mpki = 0 if self.instructions == 0 else \
                    (float(self.l2misses) / float(self.instructions)) * 1000
        self.cpi  = 0 if self.instructions == 0 else \
                    (float(self.cycles) / float(self.instructions))
        self.l2missrate  = 0 if (self.l2hits == 0) or (self.l2misses==0) else \
                    float(self.l2misses) / (float(self.l2hits) + float(self.l2misses))
        self.l2missrate_pf  = 0 if (self.l2hits_pf == 0) or (self.l2misses_pf == 0) else \
                    float(self.l2misses_pf) / (float(self.l2hits_pf) + float(self.l2misses_pf))

        print "Total exec time:      ", self.total_exec_time
        print "MPKI (L2):            ", self.mpki
        print "CPI:                  ", self.cpi
        print "L2 miss rate (ret):   ", self.l2missrate
        print "L2 miss rate (pf):    ", self.l2missrate_pf
        if (self.bandwidth != 0):
          print "Bandwidth (MB/sec):   ", self.bandwidth

        outf.write("Total exec time:     \t " + str(self.total_exec_time) + "\n")
        outf.write("MPKI (L2):           \t " + str(self.mpki) + "\n")
        outf.write("CPI:                 \t " + str(self.cpi) + "\n")
        outf.write("L2 miss rate (ret):  \t " + str(self.l2missrate) + "\n")
        outf.write("L2 miss rate (pf):   \t " + str(self.l2missrate_pf) + "\n")
        if (self.bandwidth != 0):
          outf.write("Bandwidth (MB/sec):    \t" + str(self.bandwidth) + "\n")

    def print_gc(self, outf, numlog):
        for i in range(int(numlog, 10)):
          print "Total Execution Time: ", self.total_exec_time
          print "\n[GC summary " + str(i) + "]"
          print "Total young GC time : ", self.total_ygc_time[i]
          print "Total full GC time:   ", self.total_fgc_time[i]
          print "Total GC time:        ", self.total_ygc_time[i] + self.total_fgc_time[i]
          print "--# of Young GC:      ", self.total_num_ygc[i]
          print "--# of Full GC:       ", self.total_num_fgc[i]
          print "--# of GC:            ", self.total_num_ygc[i] + self.total_num_fgc[i]
          if (self.total_num_ygc[i] + self.total_num_fgc[i]) != 0:
            self.allocation_rate.append(float(self.total_alloc_size[i]) / \
            (float(self.total_exec_time) / float(self.total_num_ygc[i] + self.total_num_fgc[i])))
          # print "Total Mutator time:   ", self.total_mut_time
          print "Total alloc size:     ", self.total_alloc_size[i]
          print "Allocation rate:      ", self.allocation_rate[i]
          
          outf.write("Total Execution Time: " + str(self.total_exec_time) + "\n")
          outf.write("\n[GC summary " + str(i) + "]\n")
          outf.write("Total young GC time: \t " + str(self.total_ygc_time[i]) + "\n")
          outf.write("Total full GC time:  \t " + str(self.total_fgc_time[i]) + "\n")
          outf.write("Total GC time:       \t " + str(self.total_ygc_time[i] + self.total_fgc_time[i]) + "\n")
          outf.write("--# of Young GC:     \t " + str(self.total_num_ygc[i]) + "\n")
          outf.write("--# of Full GC:      \t " + str(self.total_num_fgc[i]) + "\n")
          outf.write("--# of GC:           \t " + str(self.total_num_ygc[i] + self.total_num_fgc[i]) + "\n")
          outf.write("Total alloc size:    \t " + str(self.total_alloc_size[i]) + "\n")
          outf.write("Allocation rate:     \t " + str(self.allocation_rate[i]) + "\n")
          # outf.write("Total Mutator time:  \t " + str(self.total_mut_time) + "\n")

# main -----------------

# argument set / parsing
arg_parser = argparse.ArgumentParser()
arg_parser.add_argument("infile", help = "type in input file name")
arg_parser.add_argument("ninstance", help = "number of executor instances")
arg_parser.add_argument("-d", "--dump", help = "cat & dump file", action="store_true")
arg_parser.add_argument("-m", "--match", help = "make name match file", action="store_true")
arg_parser.add_argument("-g", "--gcdump", help = "gcdump for graph", action="store_true")
arg_parser.add_argument("-v", "--vtune", help = "allow vtune analysis", action="store_true")
arg_parser.add_argument("-s", "--spark", help = "with spark", action="store_true")
args = arg_parser.parse_args()

infilename_jvmlog = args.infile + ".jvmlog"
infile_jvmlog = open(infilename_jvmlog, 'r')

if args.spark:
    infilename_report= args.infile + ".report"
    infile_report = open(infilename_report, 'r')

outfilename_summary = ""
outfilename_summary = args.infile+ ".summary"
outfile_summary = open(outfilename_summary, 'w')
print "output file (summary) name: ", outfilename_summary

if args.dump:
    outfilename_hotsites = ""
    outfilename_hotsites = args.infile + ".hotsites"
    print "output file (hotsites) name: ", outfilename_hotsites
    infilename_dump = args.infile + ".alloc" + ".dump"
    infile_dump= open(infilename_dump, 'r')

# parse log
summary = gcStat()

if args.spark:
    os.system("tail -1 " + infilename_report + " | tee " + infilename_report)
    summary.parse_report(infile_report)

if not args.vtune:
  summary.parse_jvmlog(infile_jvmlog)
  summary.print_on(outfile_summary)


if args.vtune:
  print "v on"
  summary.parse_vtune_stat(infile_jvmlog, outfile_summary)

if args.gcdump:
  infilename_gclog=[]
  for i in range(int(args.ninstance, 10)):
    print i
    infilename_gclog.append(args.infile + "."+ str(i) + ".gclog")
    infile_gclog = open(infilename_gclog[i], 'r')
    outfile_gclog = open(infilename_gclog[i] + ".csv", 'w')
    summary.parse_gclog(infile_gclog, outfile_gclog, i)
  summary.print_gc(outfile_summary, args.ninstance)

if args.dump:
    hotratio = 0.1
    print "input dump file: " + infilename_dump
    os.system("cat " + infilename_dump + " | sort -g -k 3 -t \" \" -r > " + infilename_dump + ".sorted");
    threshold = summary.parse_dump(infile_dump, hotratio)
    os.system("head -" + str(threshold) + " " + infilename_dump + ".sorted > " + outfilename_hotsites);

if args.match:
    outfilename_match= ""
    outfilename_match= args.infile + ".match"
    print "output file (matching name) name: ", outfilename_match
    infilename_match= args.infile + ".alloc.dump.sorted"
    infilename_name= args.infile + ".alloc.name"
    infilename_name2= args.infile + ".alloc.name.sorted"
    os.system("cat " + infilename_name + " | sort -g -k 2 -t \" \" -u > " + infilename_name2 );
    os.system("mv " + infilename_name2 + " " + infilename_name);
    infile_match= open(infilename_match, 'r')
    infile_name= open(infilename_name, 'r')
    outfile_match= open(outfilename_match, 'w')
    summary.parse_match(infile_match, infile_name, outfile_match)

infile_gclog.close()
infile_jvmlog.close()
if args.dump:
    infile_dump.close()
if args.match:
    infile_match.close()
    infile_name.close()
    outfile_match.close()
outfile_summary.close()

