export PYTHONPATH=$PYTHONPATH:~/pythonlib/ep-py
export PYTHONPATH=$PYTHONPATH:~/pythonlib/pybrain
export PYTHONPATH=/opt/local/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages/:$PYTHONPATH
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
export svnroot=svn+ssh://jangjae@147.46.219.120/SVN/svnroot
export CUDA_INSTALL_PATH=/usr/local/cuda
export PATH=/usr/local/bin:/usr/bin:/usr:$CUDA_INSTALL_PATH/bin:$PATH
export LD_LIBRARY_PATH=/home/jangjaeyoung/LocalProjects/papi-5.2.0:/home/jangjaeyoung/LocalProjects/papi-5.2.0/src/:$LD_LIBRARY_PATH
export PATH=/usr/local/cuda/include/CL:$PATH
#export PATH=~/svnroot/projects/hetero_pipe/tools/librapl-master:$PATH
export PATH=~/home/jangjaeyoung/svnroot/projects/TC_gem5-2gpgpusim/program/include:$PATH
export LD_LIBRARY_PATH=~/svnroot/projects/hetero_pipe/tools/librapl-master:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=~/custom_gcc/gmp-4.3.2/lib:~/custom_gcc/mpfr-2.4.2/lib:~/custom_gcc/gcc-4.5.3/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=~/usr/local/lib:$LD_LIBRARY_PATH
export PATH=~/custom_gcc/gcc-4.5.3/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
#export PATH=~/hsw/pmu5/tools/perf:$PATH
export PATH=/opt/intel/vtune_amplifier_xe/bin64:$PATH
export PATH=/usr/bin:$PATH
#export PATH=/usr/jvm/java-6-openjdk-amd64/include:$PATH
export SVN_EDITOR=vim

export JAVA_HOME=/usr

#export LANG=C ALT_BOOTDIR=/usr/lib/jvm/java-6-openjdk
export LANG="ko_KR.UTF-8"
export LANGUAGE="ko_KR:ko:en_US:en"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias gos='ssh jangjaeyoung@wonder.skku.edu'
alias phi='ssh -X papl-p20@115.145.211.98'
alias snsd='ssh -X jangjae@snsd.skku.edu'
alias egc='cd ~/svnroot/projects/efficientGC/openjdk/'
alias gsrc='cd ~/svnroot/projects/efficientGC/openjdk/hotspot/src/os/linux/vm/'
alias gprj='cd ~/gitroot/shared/GConNUMA'
alias prj='cd ~/svnroot/projects/efficientGC'
alias prjj='cd ~/svnroot/projects/efficientGC/openjdk_branch'
alias pap='cd ~/svn-numa/ismm15_numaj'
alias spk='cd ~/gitroot/JVMonNUMA/spark-1.6.0-with-log'
alias score='cd ~/gitroot/JVMonNUMA/spark-1.6.0-with-log/core/src/main/scala/org/apache/spark'
alias jcore='cd ~/gitroot/JVMonNUMA/spark-1.6.0-with-log/core/src/main/java/org/apache/spark'
alias pap='cd ~/svnroot/papers/pact17_wasp'
alias jks='cd ~/svnroot/projects/efficientGC/jikesrvm-3.1.3'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
