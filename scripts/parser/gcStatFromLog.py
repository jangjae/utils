#! /usr/bin/python

import sys, os, re
import argparse

class gcStat:
    cur_alloc_size = 0
    cur_ygc_time = 0
    cur_fgc_time = 0
    total_ygc_time = 0
    total_fgc_time = 0
    total_num_ygc = 0
    total_num_fgc = 0
    total_num_gc = 0
    total_gc_time = 0
    total_mut_time = 0
    total_exec_time = 0.0
    total_sys_time = 0.0
    total_alloc_size = 0
    allocation_rate = 0
    
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

    def parse_gclog(self, inf):
        for line in inf:
            t = self.parse_line(line)
            if len(t) > 2:
                if t[1] == "[GC":
                    self.total_num_ygc += 1
                    self.cur_alloc_size = int(t[7], 10) - int(t[8], 10)
                    self.cur_ygc_time = float(t[11])
                    self.total_alloc_size += self.cur_alloc_size
                    self.total_ygc_time += self.cur_ygc_time
                elif t[1] == "[Full":
                    self.total_num_fgc += 1
                    self.cur_alloc_size = int(t[13], 10) - int(t[14], 10)
                    self.total_fgc_time += float(t[23])
                    self.total_alloc_size += self.cur_alloc_size
    
    def parse_jvmlog(self, inf):
        for line in inf:
            t = self.parse_line(line)
            if len(t) > 2:
                if t[0] == "real":
                    self.total_exec_time = float(t[1])*60 + float(t[2])
                elif t[0] == "sys":
                    self.total_sys_time = float(t[1])*60 + float(t[2])
    
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

    def print_on(self, outf):
        self.total_gc_time =  self.total_ygc_time  + self.total_fgc_time
        self.total_num_gc =   self.total_num_ygc   + self.total_num_fgc
        self.total_gc_time =  self.total_ygc_time  + self.total_fgc_time
        self.total_mut_time = self.total_exec_time - (self.total_ygc_time + self.total_fgc_time)
        self.allocation_rate = float(self.total_alloc_size) / \
        (float(self.total_exec_time) / float(self.total_num_gc))
        print "Total exec time: ",      self.total_exec_time
        print "Total young GC time : ", self.total_ygc_time
        print "Total full GC time: ",   self.total_fgc_time
        print "Total GC time: ",        self.total_gc_time
        print "--# of Young GC: ",      self.total_num_ygc
        print "--# of Full GC: ",       self.total_num_fgc
        print "--# of GC: ",            self.total_num_gc
        print "--Total GC time: ",      self.total_gc_time
        print "Tatal Mutator time: ",   self.total_mut_time
        print "Total alloc size: ",     self.total_alloc_size
        print "Allocation rate: ",      self.allocation_rate
        
        outf.write("Total exec time: \t " +     str(self.total_exec_time) + "\n")
        outf.write("Total young GC time: \t " + str(self.total_ygc_time) + "\n")
        outf.write("Total full GC time: \t " +  str(self.total_fgc_time) + "\n")
        outf.write("Total GC time: \t " +       str(self.total_gc_time) + "\n")
        outf.write("--# of Young GC: \t " +     str(self.total_num_ygc) + "\n")
        outf.write("--# of Full GC: \t "+       str(self.total_num_fgc) + "\n")
        outf.write("--# of GC: \t "+            str(self.total_num_gc) + "\n")
        outf.write("Total Mutator time: \t " +  str(self.total_mut_time) + "\n")
        outf.write("Total alloc size: \t " +    str(self.total_alloc_size) + "\n")
        outf.write("Allocation rate: \t " +     str(self.allocation_rate) + "\n")

# main -----------------

# argument set / parsing
arg_parser = argparse.ArgumentParser()
arg_parser.add_argument("infile", help = "type in input file name")
arg_parser.add_argument("-d", "--dump", help = "cat & dump file", action="store_true")
arg_parser.add_argument("-m", "--match", help = "make name match file", action="store_true")
args = arg_parser.parse_args()

infilename_jvmlog = args.infile + ".jvmlog"
infile_jvmlog = open(infilename_jvmlog, 'r')

infilename_gclog = args.infile + ".gclog"
infile_gclog = open(infilename_gclog, 'r')

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

summary = gcStat()
summary.parse_gclog(infile_gclog)
summary.parse_jvmlog(infile_jvmlog)
summary.print_on(outfile_summary)

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

