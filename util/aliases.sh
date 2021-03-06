UTIL=${UTIL:-$(echo ~graehl/u)}
. $UTIL/add_paths.sh
. $UTIL/bashlib.sh
. $UTIL/time.sh
case $(uname) in
    Darwin)
        lwarch=Apple ;;
    Linux)
        lwarch=FC12 ;;
    *)
        lwarch=Windows ;;
esac

testpys() {
    find . -name 'test*.py' -exec python {} \;
}
com() {
    git commit --allow-empty -m "$*"
}
branchnew() {
    branchthis "$@"
    co "$@"
    git commit --allow-empty -m "$*"
}
nbuild() {
    local host=$1
    shift
    ssh ${host:-gitbuild1} -l nbuild -i ~/.ssh/nbuild "$@"
}
nbuild2() {
    nbuild gitbuild2 "$@"
}
nbuild1() {
    nbuild gitbuild1 "$@"
}
externals() {
    local ncmd="cd /jenkins/xmt-externals; git checkout master; git pull"
    for host in localhost c-jgraehl c-skohli c-mdreyer; do
        ssh $host "cd c/xmt-externals; git pull"
    done
    nbuild1 $ncmd
    nbuild2 $ncmd
}
HOST=${HOST:-$(hostname)}
if [[ $HOST = graehl.local ]] ; then
    CXX11=g++-4.7
else
    CXX11=g++
fi
export CCACHE_BASEDIR=$(realpath ~/x)
chost=c-jgraehl
chostfull=$chost.languageweaver.com
phost=pontus.languageweaver.com
if [[ $HOST = $chost ]] ; then
    export USE_BOOST_1_50=1
fi
HOME=${HOME:-$(echo ~)}
DROPBOX=$HOME/dropbox
octo=$HOME/src/octopress
jgpem=$octo/aws/jonathan.graehl.org.pem
jgip=ec2-54-218-0-133.us-west-2.compute.amazonaws.com
emacsd=$HOME/.emacs.d
carmeld=$HOME/g
overflowd=$HOME/music/music-overflow/
composed=$HOME/music/compose.rpp
puzzled=$HOME/puzzle
edud=$HOME/edu
gitroots="$emacsd $octo $carmeld $overflowd $composed"
nospace() {
    catz "$@" | tr -d ' '
}
spacechars() {
    catz "$@" | perl -e 'use open qw(:std :utf8); while(<>) {chomp;@chars = split //, $_; print join(" ", @chars),"\n"; }'
}
supertrims() {
    catz "$@" | perl -pe 'chomp;s/^\s+//;s/\s+$//;s/\s+/ /g;$_+="\n"'
}
trims() {
    catz "$@" | perl -pe 'chomp;s/^\s+//;s/\s+$//;$_+="\n"'
}
rtrims() {
    catz "$@" | perl -pe 'chomp;s/\s+$//;$_+="\n"'
}
translit() {
    lang=$1
    shift
    xmt --config ~/x/RegressionTests/SimpleTransliterator/XMTConfig.yml -p translit-$lang --log-config ~/x/scripts/no.log.xml
}
loch() {
    if [ "x$JAVA_HOME" == "x" ]; then
        export JAVA_HOME=/home/hadoop/jdk1.6.0_24
        export PATH=$JAVA_HOME/bin:$PATH
    fi
    # hadoop variables needed to run utilities at the command line, e.g., pig/hadoop
    export HADOOP_INSTALL=/home/hadoop/hadoop/hadoop-2.0.0-cdh4.2.1
    export PATH=$HADOOP_INSTALL/bin:$PATH
    export HADOOP_CONF_DIR=/home/hadoop/loch2-client-conf
    export HADOOP_HOME=$HADOOP_INSTALL
    export PIG_HADOOP_VERSION=20
    export PIG_CLASSPATH=$HADOOP_CONF_DIR:/home/hadoop/hadoop/hadoop-2.0.0-cdh4.2.1/lib/pig/lib/jython-2.5.0.jar
}
bog() {
    if [ "x$JAVA_HOME" == "x" ]; then
        export JAVA_HOME=/home/hadoop/jdk1.6.0_24
        export PATH=$JAVA_HOME/bin:$PATH
    fi
    # hadoop variables needed to run utilities at the command line, e.g., pig/hadoop
    export HADOOP_INSTALL=/home/hadoop/hadoop/hadoop-2.0.0-cdh4.3.0
    export PATH=$HADOOP_INSTALL/bin:$PATH
    export HADOOP_CONF_DIR=/home/hadoop/loch2-client-conf
    export HADOOP_HOME=$HADOOP_INSTALL
    export PIG_HADOOP_VERSION=20
    export PIG_CLASSPATH=$HADOOP_CONF_DIR:/home/hadoop/hadoop/hadoop-2.0.0-cdh4.3.0/lib/pig/lib/jython-standalone-2.5.2.jar
}
bak() {
    ( set -x
        local bak=${bakdir:-bak}
        mkdir -p $bak
        for f in "$@"; do
            local b=`basename $f`
            local o=$bak/$b
            if [ -r $o ] ; then
                for i in `seq 1 9`; do
                    o=$bak/$b.$i
                    [ -r $o ] || break
                done
                if [ -r $o ] ; then
                    o=$bak/$b.`timestamp`
                fi
                if [ -r $o ] ; then
                    rm -rf $o
                fi
            fi
            echo "$f => $o"
            mv $f $o
        done
    )
}
xpublish() {
    publish=1 pdf=1 save12 ~/tmp/xpublish ~/x/scripts/make-docs.sh "$@"
}
xhtml() {
    open=1 publish= save12 ~/tmp/xhtml ~/x/scripts/make-docs.sh "$@"
}
pmvover() {
    mvover "$@"
    pushover
}

forcecpan() {
    perl -MCPAN -e "CPAN::Shell->force(qw(install $*"
}

#e.g. makedo ce.tab uniqc 'sort $in | uniq -c'
makedo() {
    in=$1
    shift
    suf=.$1
    shift
    cat <<EOF > $in$suf.do
in=\${1%$suf}
redo-ifchange \$in
$*
EOF
    git add $in$suf.do
    echo $in$suf.do
}
do_sort() {
    makedo $1 sort 'sort $in'
}
do_shuf() {
    makedo $1 shuf 'sort -R $in'
}
do_uniqc() {
    do_sort $1 sort
    makedo $1.sort uniqc 'uniq -c $in'
}
do_uniq() {
    do_sort $1 sort
    makedo $1.sort uniq 'uniq $in'
}
editdistance() {
    local ed=${ed:-EditDistance}
    $ed --flag-segment=${chars:-false} --file1 "$1" --file2 "$2" $3
}
lc() {
    catz "$@" | tr A-Z a-z
}
do_lc() {
    makedo $1 lc 'tr A-Z a-z < $in'
}
do_hasuc() {
    makedo $1 hasuc 'grep [A-Z] $in'
}

sum() {
    perl -ne '@f=split " ",$_; $s+=$_ for (@f); END {print $s,"\n"}' "$@"
}

statbytes() {
    if [[ $# = 0 ]] ; then
        echo 0
    else
        if [[ $lwarch = Apple ]] ; then
            stat -f %z "$@"
        else
            stat -c %s "$@"
        fi
    fi
}
totalbytes() {
    statbytes "$@" | sum
}
justfiles() {
    for f in "$@"; do
        [[ -f $f ]] && echo $f
    done
}
filestatbytes() {
    statbytes `justfiles "$@"`
}
totalfilebytes() {
    totalbytes `justfiles "$@"`
}
maybeshortlines() {
    if [[ $linelen ]] ; then
        shortlines $linelen "$@"
    else
        cat "$@"
    fi
}
shortlines() {
    local linelen=${1:-80}
    shift
    local continuation=${continuation:-...}
    perl -ne 'BEGIN{$linelen=shift;$continuation=shift;$clen=$linelen-length($continuation);}
chomp;$c=length($_); print $c<=$linelen ? $_ : substr($_,0,$clen).$continuation, "\n"
' "$linelen" "$continuation" "$@"
}
#args must be files, not stdin (this is not a streaming algorithm)
sample() {
    local nlines=${1:-20}
    shift
    local linelen=${linelen:-132}
    local name=${name:-0}
    local sz=$(totalfilebytes "$@")
    #TODO: use linelen as hint or to print first whatever chars
    perl -ne 'BEGIN{$sz=shift;$nlines=shift;$name=shift;} use bytes;
if ($nlines) { $lines++; $cpre=$c||0; $c+=length($_); $left=$sz-$c; $avglen=$c/$lines || 1e100; $lineleft=$left/$avglen; if (!$lineleft || rand() < $nlines/$lineleft) { --$nlines; print "$ARGV: " if $name; print; } }
' "$sz" "$nlines" "$name" "$@" | shortlines $linelen
}
psample() {
    perl -ne 'BEGIN{$p=shift}print if rand() < $p' "$@"
}
pevery() {
    perl -ne 'BEGIN{$p=1./shift}print if rand() < $p' "$@"
}
ctestlast() {
    (
        cd ~/x/${BUILD:-Debug}
        echo 'CTEST_CUSTOM_POST_TEST("cat Testing/Temporary/LastTest.log")' > CTestCustom.test
        make test
    )
}
xmtfails() {
    d=~/tmp
    cut -d' ' -f1 $d/fails > $d/fails.all
    cd ~/x/RegressionTests/; grep -l xmt/xmt `cat $d/fails.all` > $d/fails.xmt
    cd ~/x/RegressionTests/; grep -L xmt/xmt `cat $d/fails.all` > $d/fails.nonxmt
    tailn=20 preview $d/fails.xmt $d/fails.nonxmt
}
uncache() {
    sudo bash -c "sync; echo 3 > /proc/sys/vm/drop_caches"
}
fixgerrit() {
    ssh git02 "/local/gerrit/bin/gerrit.sh restart || /local/gerrit/bin/gerrit.sh start"
}
upext() {
    (set -e
        cd ~/c/xmt-externals
        git fetch origin
        git pull --rebase
    )
}
gitshow() {
    sh -c "git show $*"
}
gitdiff() {
    sh -c "git diff $*"
}
pytimeit() {
    echo "$@"
    for py in pypy python ; do
        echo -n "$py: "
        $py -mtimeit -s"$@"
    done
}
gitunrm1() {
    if [[ -f "$1" ]] ; then
        warn "$1" already exists. remove it and try again?
    else
        git checkout $(git rev-list -n 1 HEAD -- "$1")^ -- "$1"
    fi
}
macxhosts() {
    sudo vi /etc/X0.hosts
}
boostmerge1() {
    (set -e;
        set -x
        cd ~/src/boost
        git fetch upstream
        git co "$1"
        git merge remotes/upstream/master
        git push
    )
}
boostmaster() {
    (set -e;
        set -x
        cd ~/src/boost
        git fetch upstream
        git co master
        git rebase remotes/upstream/master
        git push
    )
}
boostmerge() {

    boostmerge1 object_pool-constant-time-free
    boostmerge1 dynamic_bitset
}
reveal() {
    open -R "$@"
}
compush() {
    (set -e
        git commit -a -m "$*"
        git pull --rebase
        git push
    )
}
mvover() {
    (set -e
        mv "$@" $overflowd/
        cd $overflowd
        git add *
    )
}
pushover() {
    (set -e
        cd $overflowd/
        git add *
        git commit -a -m more
        git pull --rebase
        git push
    )
}
mean() {
    sudo nice -n-20 ionice -c1 -n0 sudo -u $USER "$@"
}

brewhead() {
    brew unlink "$@"
    brew install "$@" --HEAD
}
#puzzled edud
# doesn't include ~/x on purpose (often in weird branch/rebase state)
nolog12() {
    save12 "$@" --log-config ~/x/scripts/no.log.xml
}
overflow() {
    echo mv "$@" ~/music/music-overflow/
    mv "$@" ~/music/music-overflow/
}
forcepull() {
    git pull --rebase || (git stash; git pull --rebase; git stash pop || true)
}
pulls() {
    (set -e
        for f in $gitroots; do
            (cd $f; forcepull)
        done
        empull
    )
}
forcepush() {
    echo pushing `pwd` message = "$*"
    git commit -a -m "$*"
    forcepull
    git push
}
#modified including untracked. also includes ?? line noise output
gitmod() {
    git status --porcelain -- "*$1"
    #    git ls-files -mo
}
gitmodbase() {
    local ext=${1:?.extension}
    for f in `gitmod $ext`; do
        if [[ $f != '??' ]] && [[ $f != A ]] && [[ $f != M ]] ; then
            basename "$f" "$ext"
        fi
    done
}
octopush() {
    (
        cd $octo
        set -e
        git add source/_posts/*.markdown || true
        forcepush `gitmodbase .markdown`
    )
}
pushes() {
    (set -e
        for f in $gitroots; do
            (cd $f; forcepush push)
        done
    )
    octopush
}
sshjg() {
    ssh -i $jgpem ec2-user@$jgip "$@"
}
gitlsuntracked() {
    git ls-files --others --exclude-standard "$@"
}
gitexecuntracked() {
    gitlsuntracked -z |  xargs -0 --replace={} "$@"
}
gitsync() {
    (set -e
        git pull --rebase
        git push
    )
}
web() {
    browse "$@"
}
uservm() {
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
}
rakedeploy() {
    (
        uservm
        cd ~/src/octopress
        set -e
        set -x
        rake generate
        rake deploy
        git add -v -N source/_posts/*.markdown
        git commit -a -m 'deploy'
        git push origin
    )
}
chrometab() {
    open -a 'Google Chrome Canary' "$@"
}
browse() {
    open -a 'Google Chrome Canary' "$@"
}
rakegen() {
    (
        uservm
        cd ~/src/octopress
        rake generate[unpublished]
        web public/index.html
    )
}
rakepreview() {
    (
        uservm
        cd ~/src/octopress
        set -e
        rake generate[unpublished] &
        rake preview
        chrometab 'http://localhost:4000'
    )
}
rakedraft() {
    (
        uservm
        cd ~/src/octopress
        set -e
        rake draft["$*"]
    )
    rakepreview
}
newpost() {
    rakepost "$@"
}
rakepost() {
    (
        uservm
        cd ~/src/octopress
        set -e
        rake new_post["$*"]
        rakepreview
    )
}
splitflac() {
    #git clone git://github.com/ftrvxmtrx/split2flac.git
    split2flac "$@"
}
flacgain() {
    echo2 flac replay gain "$@"
    metaflac --no-utf8-convert --dont-use-padding --preserve-modtime --with-filename --add-replay-gain "$@"
}
mp3m4again() {
    echo2 mp3 or m4a replay gain "$@"
    aacgain -r -k -p "$@"
}
gains() {
    for f in "$@"; do
        if [[ ${f%.flac} = $f ]] ; then
            mp3m4again "$f"
        else
            flacgain "$f"
        fi
    done
}
gitrmsub() {
    local sub=${1:?submodule path}
    git status || return
    git config -f .git/config --remove-section submodule.$1
    git config -f .gitmodules --remove-section submodule.$1
    rm -rf $1
    git rm --cached -f $1
    git commit -a -m 'rm submodule $1'
    rm -rf $1 .git/modules/$1 .git/modules/path/to/$1
}

alias edbg="open /Applications/Emacs.app --args --debug-init"
alias cedbg="/Applications/Emacs.app/Contents/MacOS/Emacs -nw --debug-init"
overflow() {
    local overflow=`echo ~/music/music-overflow`
    require_dir "$overflow"
    mv "$@" "$overflow"
}

xsnap() {
    (set -e;
        cd $xmtx
        git stash && git stash apply
    )
}

gitsnap() {
    git stash && git stash apply
}

commg() {
    ( set -e
        cd ~/g
        gcom "$@"
    )
}

cto() {
    local dst=.
    if [[ $2 ]] ; then
        dst=$1
        shift
    fi
    (
        require_dir $dst
        for f in "$@"; do
            scp $chost:"$f" $dst
        done
    )
}
ccp() {
    #uses: $chost for scp
    local n=$#
    local dst=${@:$n:$n}
    (set -e
        require_dir `dirname "$dst"`
        if [[ $(( -- n )) -gt 0 ]] ; then
            if [[ $n -gt 1 ]] ; then
                require_dir "$dst"
            fi
            for f in "${@:1:$n}"; do
                echo scp $chost:"$f" "$dst"
                scp $chost:"$f" "$dst"
            done
        fi
    )
}
ccat() {
    cjg cat "$*"
}
csave() {
    save12 ~/tmp/cjg.`filename_from $1 $2` cjg "$@"
}
creg() {
    save12 ~/tmp/creg.`filename_from "$@"` cwith yreg "$@"
}
cregr() {
    save12 ~/tmp/cregr.`filename_from "$@"` cwith yregr "$@"
}
treg() {
    save12 /tmp/reg yreg "$@"
}
tregr() {
    save12 /tmp/reg yregr "$@"
}
cp2cbin() {
    scp "$@" c-jgraehl:/c01_data/graehl/bin/
}

valgrind=`which valgrind`
[[ -x $valgrind ]] || valgrind=

findx() {
    find . "$@" -type f -perm -u+x
}

find_tests() {
    findx -name Test\*
}


memcheck() {
    local test=`basename $1`
    if [[ $valgrind ]] ; then
        local memlog=`mktemp /tmp/memcheck.$test.err.XXXXXX`
        local memout=`mktemp /tmp/memcheck.$test.out.XXXXXX`
        #TODO: could use --log-fd=3 >/dev/null 2>/dev/null 3>&2
        # need to test order of redirections, though
        local supp=$xmtx/jenkins/valgrind.fc12.debug.supp
        local valgrindargs="-q --tool=memcheck --leak-check=no --track-origins=yes --suppressions=$supp"
        save12timeram $memout valgrind $valgrindargs --log-file=$memlog "$@"
        local rc=$?
        if [[ $rc -ne 0 ]] || [[ -s $memlog ]] ; then
            echo $hr
            echo "memcheck $test [FAIL]"
            echo $hr
            echo "cd `pwd` && valgrind $valgrindargs $1"
            ls -l $memout $memlog
            head -40 $memlog
            echo ...
            echo $memlog
            memcheckrc=88
            memcheckfailed+=" $test"
            echo $hr
        else
            cat $memlog 1>&2
            rm $memout
            rm $memlog
        fi
    fi
}


skiptest() {
    echo "skipping memcheck of $basetest (MEMCHECKALL=1 to include it)"
    echo $hr
    return 1
}

memchecktest() {
    ### TODO@JG: put these shell fns in a shell script and use GNU parallel (an
    ### awesome 150kb perl script) to do #threads - then we can run some of hte
    ### slower ones for validation. postponed due to decisions about accumulating
    ### failed tests' outputs (can't use shell vars)

    basetest=`basename $1`
    if [[ $MEMCHECKALL = 0 ]] ; then
        case ${basetest#Test} in
            #recommendation: exclude tests only if there are currently no errors and execution time is >10s
            LWUtil) # for some reason this one takes several minutes; the rest are 20-30 sec affairs
                skiptest ;;
            FeatureBot)
                skiptest ;;
            Vocabulary)
                skiptest ;;
            WordAligner)
                skiptest ;;
            SpellChecker)
                skiptest ;;
            LexicalRewrite)
                skiptest ;;
            RegexTokenizer)
                skiptest ;;
            Optimization)
                skiptest ;;
            Hypergraph)
                skiptest ;;
            Copy)
                skiptest ;;
            Concat)
                skiptest ;;
            BlockWeight)
                skiptest ;;
            OCRC)
                skiptest ;;
            *)
                ;;
        esac
    fi
}

memchecktests() {
    if [[ $valgrind ]] ; then
        local tests=`find_tests`
        echo "Running memcheck on unit tests:"
        echo $tests
        echo
        memcheckrc=0
        memcheckfailed=''
        for test in $tests; do
            if memchecktest $test ; then
                echo memcheck $test ...
                memcheck $test
                echo $hr
            fi
        done
        if [[ $memcheckrc -ne 0 ]] ; then
            #FINALRC=$memcheckrc
            #TODO: enable only once failures are fixed in master
            echo "memcheck failed for:$memcheckfailed"
        fi
    else
        echo "WARNING: valgrind not found. skipping MEMCHECKUNITTEST"
    fi
}

####

gdbargs() {
    local prog=$1
    shift
    gdb --fullname -ex "set args $*; r" $prog
}
rebaseadds() {
    local adds=`git rebase --continue 2>&1 | perl -ne 'if (/^(.*): needs update/) { print $1," " }'`
    echo adds=$adds
    if [[ $adds ]] ; then
        git add -- $adds
    fi
    git rebase --continue
}
rebasenext() {
    cd ~/x
    rebasece `git rebase --continue 2>&1 | perl -ne 'if (!$done && /^(.*): needs merge/) { print $1; $done=1; }'`
    rebaseadds
}
agsrc() {
    ag -G '\.(h|c|hh|cc|hpp|cpp|scala|py|pl|perl)$' "$@"
}
agsrce() {
    ag --nogroup --nocolor -G '\.(h|c|hh|cc|hpp|cpp|scala|py|pl|perl)$' "$@"
}

pepall() {
    pep `find . -name '*.py'`
}

flakeall() {
    flake `find . -name '*.py'`
}

pycheckall() {
    pychecker `find . -name '*.py'`
}

fork() {
    if [[ $ARCH = cygwin ]] ; then
        "$@" &
    else
        (setsid "$@" &)
    fi
}

launder() {
    xattr -d com.apple.quarantine "$@"
    xattr -d com.apple.metadata:kMDItemWhereFroms "$@"
}
interactive() {
    if [[ $- == *i* ]] ; then
        true
    else
        false
    fi
}
githistory() {
    gitstat "$@"
}
gitstat() {
    local file=$1
    shift
    git log --stat "$@" -- "$file"
}
pytest() {
    local TERM=$TERM
    if [[ $INSIDE_EMACS ]] ; then
        TERM=dumb
    fi
    TERM=$TERM py.test --assert=reinterp "$@"
}
yreg() {
    if [[ $xmtShell ]] ; then
        makeh xmtShell
    fi
    local args="$yargs"
    # -t 2
    (set -e;
        local logfile=/tmp/yreg.`filename_from "$@" $BUILD`
        cd $xmtx/RegressionTests
        THREADS=`ncpus`
        MINTHREADS=${MINTHREADS:-2} # unreliable with 1
        MAXTHREADS=6
        if [[ $THREADS -gt $MAXTHREADS ]] ; then
            THREADS=$MAXTHREADS
        fi
        if [[ $THREADS -lt $MINTHREADS ]] ; then
            THREADS=$MINTHREADS
        fi
        #        set -x
        local STDERR_REGTEST
        if [[ $verbose ]] ; then
            STDERR_REGTEST="--dump-stderr"
        fi
        local memcheckparam
        if [[ $memcheck ]] || [[ $MEMCHECKREGTEST -eq 1 ]] ; then
            memcheckparam=--memcheck
        fi
        local REGTESTPARAMS="$REGTESTPARAMS $memcheckparam -b $racer/${BUILD:-Debug} -t $THREADS -x regtest_tmp_$USER_$BUILD $GLOBAL_REGTEST_YAML_ARGS $STDERR_REGTEST"
        if [[ $1 ]] ; then
            if [[ -d $1 ]] ; then
                save12 $logfile ./runYaml.py $args $REGTESTPARAMS "$@"
            elif [[ -f $1 ]] ; then
                save12 $logfile ./runYaml.py $args $REGTESTPARAMS -y "$(basename $1)"
            else
                save12 $logfile ./runYaml.py $args $REGTESTPARAMS -y \*$1\*ml
            fi
        else
            save12 $logfile ./runYaml.py $args $REGTESTPARAMS
        fi
        set +x
        echo saved log:
        echo
        echo $logfile
    )
}

#TODO: screws up line editing
bashcmdprompt() {
    unset PROMPT_COMMAND
    case $HOST in
        graehl.local)
            DISPLAYHOST=mac ;;
        c-skohli*)
            DISPLAYHOST=kohli ;;
        c-jgraehl*)
            DISPLAYHOST=g ;;
        *)
            DISPLAYHOST=$HOST
    esac

    export PS1="\e]0;[$DISPLAYHOST] \w\007[$DISPLAYHOST] \w\$ "
    #set -T
    trap 'printf "\\e]0;[$DISPLAYHOST] %b\\007" $BASH_COMMAND' DEBUG
}
to5star() {
    mv "$@" ~/music/local/[5star]/
}
toscraps() {
    mv "$@" ~/dropbox/music-scraps/
}
stt() {
    StatisticalTokenizerTrain "$@"
}
sk() {
    chost=c-skohli sc
}
sd() {
    chost=c-mdreyer sc
}
kwith() {
    (
        chost=c-skohli linwith "$@"
    )
}
dwith() {
    (
        chost=c-mdreyer linwith "$@"
    )
}
kjen() {
    chost=c-skohli linjen "$@"
}
djen() {
    chost=c-mdreyer linjen "$@"
}
cjen() {
    chost=c-jgraehl linjen "$@"
}
cwith() {
    chost=c-jgraehl linwith "$@"
}
gjen() {
    (set -e
        macget ${1:?mac-branch [jen args]}
        shift
        jen "$@"
    )
}
hgtrie() {
    StatisticalTokenizerTrain --whitespace-tokens --start-greedy-ascii-weight '' \
        --unigram-addk=0 --addk=0 --unk-weight '' --xmt-block 0 --loop 0 "$@"
}
hgbest() {
    xmt --input-type FHG --pipeline Best "$@"
}
macflex() {
    LDFLAGS+=" -L/usr/local/opt/flex/lib"
    CPPFLAGS+=" -I/usr/local/opt/flex/include"
    CFLAGS+=" -I/usr/local/opt/flex/include"
    export LDFLAGS CPPFLAGS CFLAGS
}
racm() {
    (
        set -e
        racb ${1:-Debug}
        shift || true
        cd $racerbuild
        local prog=$1
        local maketar=
        if [ "$prog" ] ; then
            shift
            #rm -f {Autorule,Hypergraph,FsTokenize,LmCapitalize}/CMakeFiles/$prog.dir/{src,test}/$prog.cpp.o
            if [[ ${prog#Test} = $prog ]] ; then
                test=
                tests=
            else
                maketar=$prog
                prog=
            fi
        fi
        if [[ $test ]] ; then
            make check
        elif [[ $prog ]] && [[ "$*" ]]; then
            make -j$MAKEPROC $prog && $prog "$@"
        else
            make -j$MAKEPROC $maketar VERBOSE=1
        fi
        set +x
        for t in $tests; do
            ( set -e;
                echo $t
                td=$(dirname $t)
                tn=$(basename $t)
                testexe=$td/Test$tn
                [[ -x $testexe ]] || testexe=$t/Test$t
                $testgdb $testexe ${testarg:---catch_system_errors=no} 2>&1 | tee $td/$tn.log
            )
        done
    )
}
racc() {
    racb ${1:-Debug}
    shift || true
    cd $racerbuild
    if [[ $HOST = $chost ]] ; then
        export USE_BOOST_1_50=1
    fi
    ccmake ../xmt $cmarg "$@"
}
raccm() {
    racc ${1:-Debug}
    racm "$@"
}
ccmake() {
    local d=${1:-..}
    shift
    (
        rm -f CMakeCache.txt $d/CMakeCache.txt
        if [[ $llvm ]] ; then
            usellvm
        fi
        usegcc
        local cxxf=$cxxflags
        if [[ $clang ]] || [[ ${build%Clang} != $build ]] ; then
            useclang
            cxxf=-fmacro-backtrace-limit=100
        fi
        CFLAGS= CXXFLAGS=$cxxf CPPFLAGS= LDFLAGS=-v cmake $d "$@"
    )
}
savecppch() {
    local code_path=${1:-.}
    local OUT=${2:-$HOME/tmp/cppcheck-$(basename `realpath $code_path`)}
    save12 $OUT cppch "$code_path"
    echo2 $cppcheck_cmd
}
cppch() {
    # Suppressions are comments of the form "// cppcheck-suppress ErrorType" on the line preceeding the error
    # see https://www.icts.uiowa.edu/confluence/pages/viewpage.action?pageId=63471714
    local code_path=${1:-.}
    local extra_include_paths=${extra_include_paths:-$code_path}
    if [[ $cppcheck_externals ]] ; then
        extra_include_paths+=" $(echo $XMT_EXTERNALS_PATH/libraries/*/include)"
    fi
    local extrachecks=${extrachecks:-performance}
    if [[ $extrachecks = none ]] ; then
        extrachecks=
    fi
    local ignoreargs
    local ignorefiles="" # list of (basename) filenames to skip
    if [[ $ignorefiles ]] ; then
        for f in $ignores ; do
            ignoreargs+=" -i $f"
        done
    fi
    local includeargs
    if [[ $extra_include_paths ]] ; then
        for f in $extra_include_paths ; do
            includeargs+=" -I $f"
        done
    fi
    local extraargs
    if [[ $extrachecks ]] ; then
        for f in $extracheck ; do
            extraargs+=" --enable=$f"
        done
    fi
    cppcheck_cmd="cppcheck -j 3 --inconclusive --quiet --force --inline-suppr \
        --template '{file}:{line}: {severity},{id},{message}' \
        $includeargs $ignoreargs "$code_path" --error-exitcode=2"
    cppcheck -j 3 --inconclusive --quiet --force --inline-suppr \
        --template '{file}:{line}: {severity},{id},{message}' \
        $includeargs $ignoreargs "$code_path" --error-exitcode=2
}
coma() {
    git commit -a -m "$*"
}
assume() {
    git update-index --assume-unchanged "$@"
}
unassume() {
    git update-index --no-assume-unchanged "$@"
}
assumed() {
    git ls-files -v | grep ^h | cut -c 3-
}
snapshot() {
    git stash save "snapshot: $(date)" && git stash apply "stash@{0}"
}

pepignores=E501
#,E401
flake() {
    flake8 --ignore=$pepignores "$@"
}
pep() {
    pep8 --ignore=$pepignores "$@"
}
bakdocs() {
    (
        cd ~/x/docs
        scp *.r *.rmd *.md *.txt $chost:projects/docs
    )
}
metaflacs() {
    for f in *.flac; do
        metaflac --with-filename --preserve-modtime --dont-use-padding "$@" "$f"
    done
}
cuesplit() {
    local cue=${1:?args file.cue [file.flac]}
    local flac=${2:-${cue%.cue}.flac}
    showvars_required cue flac
    require_files "$cue" "$flac"
    mkdir -p split
    shntool split -f "$cue" -o 'flac flac --output-name=%f -' -t '%n-%p-%t' "$flac"
    for f in *.flac; do
        if [[ "$f" != "$flac" ]] ; then
            flacgain "$f"
            mv "$f" split
        fi
    done
    #    shntool split -f "$cue" -o 'flac flacandgain %f' "$flac"
}
stripx() {
    strip "$@"
    upx "$@"
}
cpstripx() {
    local from=$1
    local to=${2:?from to}
    (set -e
        require_file $from
        cp $from $to
        chmod +x $to
        stripx $to
    )
}
topps() {
    local pid=${1?args PID N secperN}
    save12 ${out:-top.$pid} top -b -n ${2:-1000} -d ${3:-10} -p $pid
}
toppsq() {
    topps "$@" 2>/dev/null >/dev/null
}
lnccache() {
    local f
    local ccache=$(echo ~/bin/ccache)
    for f in "$@" ; do
        local g=$ccache-`basename $f`
        cat > $g <<EOF
#!/bin/bash
exec $ccache $f "\$@"
EOF
        chmod +x $g
        echo $g
    done
}
findsize1() {
    tailn=100 preview `find . -name '*pp' -size 1` > ~/tmp/size1
}
expsh() {
    perl -ne 'chomp;print qq{echo "$_"; pwd; hostname; date; $_; echo "No errors from $_" 1>&2\n}'
}
condorexp() {
    local f=$1/jobs.condor
    require_file $f
    condor_submit $f
    echo ls log/$f/
}
exp() {
    local f=${1%.sh}
    (set -e
        require_file $f.sh
        create-dir.pl $f
        condorexp $f
    )
}
redodo() {
    for f in "$@"; do
        redo-ifchange ${f%.do}
    done
}
reallr() {
    redodo `find ${*:-.} -name '*.do'`
}
cleanall() {
    noredo=1 clean=1 reall "$@"
}
reall() {
    local redos
    for d in ${*:-.}; do
        for f in $d/*.do; do
            redos+=" ${f%.do}"
        done
    done
    if [[ $clean ]] ; then
        rm -fv $redos
        for f in $redos; do
            rm -fv $f.redo?.tmp
        done
    fi
    if ! [[ $noredo ]] ; then
        (
            redo-ifchange $redos
        )
    fi
}
re() {
    redo-ifchange "$@"
}
dedup() {
    local f="$(filename_from $*)"
    catz "$@" | sort | uniq > $f.uniq
    (wc $* ; wc $f.uniq) | tee $f.uniq.wc
}
savedo() {
    local dir=${1:?arg1: dir to save .do outputs to}
    mkdir -p $dir
    local cmd=cp
    local cmdargs=-a
    if [[ $mv ]] ; then
        cmd=mv
        cmdargs=
    fi
    for f in `find . -name '*.do'`; do
        local o=${f%.do}
        if [[ -f $o ]] ; then
            cp -a $f $dir/$f
            $cmd $cmdargs $o $dir/$o
            ls -l $dir/$f $dir/$o
        fi
    done
}
sherp() {
    local CT=${CT:-~/c/ct/main}
    cd `dirname $1`
    local apex=`basename $1`
    if [[ -f $apex.apex ]] ; then
        apex=$apex.apex
    fi
    local dir=${apex%.apex}
    if [[ $cleancondor ]] && [[ -d $dir ]] ; then
        echo rm -rf $dir
        rm -rf $dir
    fi
    $CT/sherpa/App/sherpa --apex=$apex "$@"
}
resherp() {
    cleancondor=1 sherp "$@"
}
clonect() {
    git clone http://git02.languageweaver.com:29418/coretraining ct
}
macboost() {
    BOOST_VERSION=1_50_0
    BOOST_SUFFIX=
    if true ; then
        BOOST_SUFFIX=-xgcc42-mt-d-1_49
        BOOST_VERSION=1_49_0
    fi
    if [[ -d $XMT_EXTERNALS_PATH ]] ; then
        BOOST_INCLUDE=$XMT_EXTERNALS_PATH/libraries/boost_$BOOST_VERSION/include
        BOOST_LIB=$XMT_EXTERNALS_PATH/libraries/boost_$BOOST_VERSION/lib
        add_ldpath $BOOST_LIB
    fi
}
tokeng() {
    ${xmt:-$xmtx/Release/xmt/xmt} -c $xmtx/RegressionTests/RegexTokenizer/xmt.eng.yml -p eng-tokenize --log-config $xmtx/scripts/no.log.xml "$@"
}

rstudiopandoc() {
    Rscript -e '
options(rstudio.markdownToHTML =
  function(inputFile, outputFile) {
    system(paste("pandoc", shQuote(inputFile), "--webtex", "--latex-engine=xelatex", "--self-contained", "-o", shQuote(outputFile)))
  }
)
'
}
panpdf() {
    local in=${1?in}
    local inbase=${in%.md}
    local out=${2:-$inbase.pdf}
    (
        texpath
        if [[ ! -f $in ]] ; then
            in=$inbase.md
        fi
        set -e
        require_file $in
        local geom="-V geometry=${paper:-letter}paper -V geometry=margin=${margin:-0.5cm} -V geometry=${orientation:-portrait} -V geometry=footskip=${footskip:-20pt}"
        pandoc --webtex --latex-engine=xelatex --self-contained -r markdown+implicit_figures -t latex -w latex -o $out --template ~/u/xetex.template --listings -V mainfont="${mainfont:-Constantia}" -V sansfont="${sansfont:-Corbel}" -V monofont="${monofont:-Consolas}"  -V fontsize=${fontsize:-10pt} -V documentclass=${documentclass:-article}  $in
        if [[ $open ]] ; then
            open $out
        fi
    )
}
rmd() {
    RMDFILE=${1?missing RMDFILE.rmd}
    RMDFILE=${RMDFILE%.rmd}
    (
        set -e
        cd `dirname $RMDFILE`
        RMDFILE=`basename $RMDFILE`
        Rscript -e "require(knitr); require(markdown); require(ggplot2); require(reshape); knit('$RMDFILE.rmd', '$RMDFILE.md');"
        #markdownToHTML('$RMDFILE.md', '$RMDFILE.html', options=c('use_xhml'))
        pandoc --webtex --latex-engine=xelatex --self-contained -t html5 -o $RMDFILE.html -c ~/u/pandoc.css $RMDFILE.md
        if [[ $pdf ]] ; then
            panpdf $RMDFILE.md
        elif [[ $open ]] ; then
            open $RMDFILE.html
        fi
    )
}
gitgrep() {
    local expr=$1
    shift
    echo2 $expr
    git rev-list --all -- "$@"
    git rev-list --all -- "$@" | (
        while read revision; do
            git grep -e "$expr" $revision -- "$@"
        done
    )
    # git rev-list --all -- "$@" | xargs -I {} git grep -e "$expr" {} -- "$@"
}
subsync() {
    git submodule sync "$@"
}
mp3split() {
    mp3splt "$@"
}
ontunnel=
if [[ $HOST = graehl.local ]] ; then
    ontunnel=1
    /sbin/ifconfig > /tmp/ifcfg
    if grep -q 10.110 /tmp/ifcfg; then
        ontunnel=
    fi
fi
cjg() {
    local fwdenv="gccfilter=$gccfilter"
    if [[ $ontunnel ]] ; then
        sshvia $chost ". ~/.e;$fwdenv $*"
    else
        ssh $chost ". ~/.e;$fwdenv $*"
    fi
}
printyaml() {
    ruby -ryaml -e 'y '"$*"
}
GRAEHLSRC=${GRAEHLSRC:-`echo ~/g`}
GLOBAL_REGTEST_YAML_ARGS="-c -n -v --dump-on-error"
maco=10.110.5.15
macl=192.168.1.7
tunrdp() {
    ssh -L33391:$1:3389 -p 4640 graehl@pontus.languageweaver.com
}
tsp() {
    tunrdp tsp-xp1
}
lagra() {
    #tunrdp lagraeh02
    tunrdp 10.110.5.5
}
sox() {
    connect -S 127.0.0.1:12345 "$@"
}
gitp() {
    GIT_PROXY_COMMAND=c:/msys/bin/sox.bat git "$@"
}
gitpf() {
    gitp fetch http://localhost:29418/xmt "$@"
}

giteol() {
    if ! [[ -f .gitattributes ]] ; then
        echo '* text=auto' > .gitattributes
        git add .gitattributes
        git commit -m 'auto line-end'
    fi
    git rm --cached -r .
    # Remove everything from the index.

    git reset --hard
    # Write both the index and working directory from git's database.

    git add .
    # Prepare to make a commit by staging all the files that will get normalized.

    # This is your chance to inspect which files were never normalized. You should
    # get lots of messages like: "warning: CRLF will be replaced by LF in file."

    git commit -m "Normalize line endings"
    # Commit
}
spd() {
    ~/x/scripts/speedtest-stat-tok.sh "$@"
}
gpush() {
    (set -e
        pushd ~/g
        gcom "$@"
        git pull
        git push
    )
}
mendre() {
    (set -e
        cd ~/x
        mend
        bakre "$@"
    )
}
bakx() {
    (set -e
        cd ~/x
        bakthis "$@"
    )
}
bakre() {
    bakthis ${1:-prebase}
    upre
}
tryre() {
    local branch=$(git_branch)
    (set -e
        local to=$branch.re
        git branch -D $to || true
        git checkout -b $to
        up
        git rebase master || git rebase --abort
        co $branch
        git branch -D $to
    )
}

upre() {
    (set -e
        git fetch origin
        git rebase origin/master
    ) || git rebase --continue
}
showbest() {
    for f in "$@" ; do
        echo $f 1>&2
        HgBest -n 1 $f -y 1 -Y 1 2>/dev/null
        echo
    done
}
tunhost="pontus.languageweaver.com"
tunport=4640
randomport() {
    perl -e 'print int(12000+rand(10000))'
}
ssht() {
    ssh -p $tunport $tunhost "$@"
}
sshvia() {
    local lport=`randomport`
    local rhost=$1
    shift
    echo via $lport to $rhost 1>&2
    local permit="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "
    ssh -f -L $lport:$rhost:22 -p $tunport $tunhost "sleep 6" && ssh $permit -p $lport localhost "$@"
}
clonex() {
    (
        set -e
        git clone ssh://localhost:29418/xmt x
        cd x
        machost=192.168.1.7
        git remote add macw ssh://$machost:22/users/graehl/c/xmt
        scp $machost:/users/graehl/c/xmt/.git/config/commit-msg .git/config/commit-msg
    )
}
tunsocks() {
    # ssh -f -N -D 1080 -p $tunport $tunhost "$@"
    #ssh -D 1082 -f -C -q -N -p $tunport $tunhost
    ssh -f -C -q -N -D 12345 -p $tunport $tunhost
}
tunport() {
    local port=${1:?usage: port [host] via tunhost:tunport $tunhost:$tunport}
    local host=${2:-git02.languageweaver.com}
    local lport=${3:-$port}
    ssh -N -L $port:$host:$lport -p $tunport $tunhost "$@"
}
ssht() {
    ssh -p $tunport $tunhost "$@"
}
tunmac() {
    tunport 22 $maco &
}
sshtun() {
    ssh -f -N tun
}
sshmaster() {
    fork ssh -MNn $chost
}
tungerrit() {
    #tunport 29418 git02.languageweaver.com
    ssh -L 29418:git02.languageweaver.com:29418 -L 3391:172.20.1.122:3389 -p $tunport $tunhost -N &
}
conf64() {
    ./configure --prefix=/msys --host=x86_64-w64-mingw32 "$@"
}
zillaq() {
    perl -n -e 'print $1,"\n" if m#<LocalFile>(.*)/[^/]*</LocalFile>#' "$@" | sort | uniq -c
}
cpfrom() {
    cp "$2" "$1"
}
conflicts() {
    perl -ne 'print "$1 " if /^CONFLICT.* in (.*)$/; print "$1 " if /^(.*): needs merge$/' "$@"
}
gitcontinue() {
    git mergetool && git rebase --continue
}
gitrebase() {
    (set -e
        local last=${1:?usage: from-branch [HEAD]}
        git rebase "$@" || gitcontinue
    )
}
filtergcc() {
    "$@" 2>&1 | filter-gcc-errors
}
gitstashun() {
    echo stashing unadded changes only so you can commit part
    git stash --keep-index
}
gitreplace() {
    local branch=$(git_branch)
    local to=${1:?arg1: destination branch e.g. master. replace by current branch}
    (
        set -e
        showvars_required branch to
        git merge --strategy=ours --no-commit $to
        git commit -m "replace $to by $branch by merging"
        git checkout $to
        git merge $branch
    )
}
gitrecycle() {
    git log --diff-filter=D --summary | grep delete
}
useclang() {
    local ccache=${ccache:-$(echo ~/bin/ccache)}
    export CC="$ccache-cc$GCC_SUFFIX"
    export CXX="$ccache-c++$GCC_SUFFIX"
}
gcc48=
gcc47=1
#TestWeight release optimizer problem
usegcc() {
    if false && [[ $HOST = graehl.local ]] ; then
        usegccnocache
        #don't have right gdb for gcc 4.7 on my mac
    else
        if [[ $gcc48 ]] && [[ -x `which gcc-4.8 2>/dev/null` ]] ; then
            GCC_SUFFIX=-4.8
        elif [[ $gcc47 ]] && [[ -x `which gcc-4.7 2>/dev/null` ]] ; then
            GCC_SUFFIX=-4.7
        fi
        local ccache=${ccache:-$(echo ~/bin/ccache)}
        export CC="$ccache-gcc$GCC_SUFFIX"
        export CXX="$ccache-g++$GCC_SUFFIX"
    fi
    echo2 CC=$CC CXX=$CXX
}
usegccnocache() {
    export CC="gcc"
    export CXX="g++"
}
usellvm() {
    local ccache=${ccache:-$(echo ~/bin/ccache)}
    local gcc=$GCC_PREFIX
    local llvm=/usr/local/llvm
    export PATH=$llvm/bin:$llvm/sbin:$PATH
    local gccm=$gcc/lib/gcc/x86_64-apple-darwin11.4.0
    export LIBRARY_PATH=$llvm/lib:$gccarch/4.7.1:$gcc/lib/gcc:$gcc/lib
    export CC="$ccache $llvm/bin/clang"
    export CXX="$ccache $llvm/bin/clang++"
}
withcc() {
    local source=$1
    require_file $source
    shift
    (local sdir=`dirname $source`
        cd $sdir
        local exe=$(basename $source .cc)
        exe=${exe%.cpp}
        exe=${exe%.c}
        local bexe=${bindir:-$sdir}/$exe
        local cxx=${CXX:-/usr/local/gcc-4.7.1/bin/g++}
        [[ -x $cxx ]] || cxx=/mingw/bin/g++
        [[ -x $cxx ]] || cxx=g++
        set -e
        $cxx -O3 --std=c++${cxxstd:-11} $source -o $bexe
        if [ "$run $*" ] ; then
            $bexe "$@"
        fi
    )
}
xmtx=/.auto/home/graehl/x
xmtr=$xmtx/RegressionTests
if [[ $HOST = $chost ]] || [[ $HOST = graehl.local ]] || [[ $HOST = graehl ]] ; then
    xmtx=/Users/graehl/x
fi
if [[ $HOST = c-skohli ]] ; then
    xmtx=/.auto/home/graehl/x
fi
dumbmake() {
    if [[ $DUMB ]] ; then
        /usr/bin/make VERBOSE=1 "$@" 2>&1
        #| sed -e 's%^.*: error: .*$%\x1b[37;41m&\x1b[m%' -e 's%^.*: warning: .*$%\x1b[30;43m&\x1b[m%'
    else
        /usr/bin/make "$@"
    fi
}
substxmt() {
    (
        cd $xmtx/xmt
        substi "$@" $(ack --ignore-dir=LWUtil --ignore-dir=graehl --cpp -f)
    )
}
linwith() {
    (set -e;
        cd ~/x;mend;
        local branch=$(git_branch)
        cjg macget $branch
        cjg "$@"
    )
}
linregr() {
    cjg yregr "$@"
}
linjen() {
    cd $xmtx
    local branch=$(git_branch)
    mend
    (set -e;
        cjg macget $branch
        cjg threads=$threads VERBOSE=${VERBOSE:-0} jen "$@" 2>&1) | tee ~/tmp/linjen.$branch | filter-gcc-errors
}
jen() {
    cd $xmtx
    local build=${1:-${BUILD:-Release}}
    shift
    local log=$HOME/tmp/jen.log.`timestamp`
    . xmtpath.sh
    usegcc
    if [[ $HOST = $chost ]] ; then
        export USE_BOOST_1_50=1
    fi
    if [[ $memcheck ]] ; then
        MEMCHECKUNITTEST=1
    else
        MEMCHECKUNITTEST=0
    fi
    if [[ $memcheckall ]] ; then
        MEMCHECKALL=1
    else
        MEMCHECKALL=0
    fi
    MEMCHECKUNITTEST=$MEMCHECKUNITTEST MEMCHECKALL=$MEMCHECKALL jenkins/jenkins_buildscript --threads ${threads:-`ncpus`} --no-cleanup --regverbose $build "$@" 2>&1 | tee $log
    echo
    echo $log
    fgrep '... FAIL' $log | grep -v postagger | sort > $log.fails
    nfails=`cut -d' ' -f1 $log.fails | uniq -c | wc -l`
    cp $log.fails /tmp/last-fails
    echo
    cat /tmp/last-fails
    echo
    echo $log.fails
    echo "#fails = $nfails"
    echo "#fails = $nfails" >> $log.fails
}
rmautosave() {
    find . -name '\#*' -exec rm {} \;
}
gitdiffsub() {
    PAGER= git diff "$@"
    PAGER= git diff --submodule "$@"
}
gitdiff() {
    git difftool --tool=opendiff "$@"
}
ret() {
    #cpshared
    commt "$@"
}
shortstamp() {
    date +%m.%d_%H.%M
}
raccmsave() {
    local BUILD=${1:-Release}
    cd $xmtx
    local gbranch=$(git_branch)
    if [[ $gbranch = "(no branch)" ]] ; then
        gbranch=${branch:-headless}
    fi
    local binf=~/bin/xmt.$gbranch.`shortstamp`
    BUILD=$BUILD makeh xmt && cp $xmtx/$BUILD/xmt/xmt $binf && ls -al $binf && [[ $clean ]] && rm ~/bin/xmt.$gbranch.* && cp $xmtx/$BUILD/xmt/xmt $binf
    echo $binf
    newxmt=$binf
}
pkill() {
    local prefile=`mktemp /tmp/pgrep.pre.XXXXXX`
    pgrep "$@" > $prefile
    cat $prefile
    kill `cat $prefile | cut -c1-5`
    # | xargs kill
    echo before:
    cat $prefile
    sleep 1
    echo now:
    pgrep "$@"
    rm $prefile
}
gccopt3() {
    local f=$1
    shift
    local ofile=~/tmp/gopt3.E.`basename $f`
    ${CXX:-g++} -fdump-tree-all -O${optimize:-3} -c "$f" "$@" -E -o $ofile
    echo $ofile

}
gccasm3() {
    local f=$1
    shift
    local ofile=~/tmp/gasm3.`basename $f`.s
    local lfile=~/tmp/gasm3.`basename $f`.lst
    ${CXX:-g++} -S -fverbose-asm -O${optimize:-3} -c "$f" "$@" -o $ofile
    if [[ $lwarch = Apple ]] ; then
        cp $ofile $lfile
    else
        as -alhnd $ofile > $lfile
    fi
    echo $lfile
}
sortk3() {
    local f=$1
    if [[ -f $f ]] && ! [[ $2 ]] ; then
        local sf=$f.sorted
        sort -k3 -n "$f" > $sf
        if ! diff -q $sf $f ; then
            echo sorted
            mv $sf $f
        else
            echo was already sorted
            rm $sf
        fi
    fi
}
xmtinstall() {
    (set -e
        cd $xmtx
        local gitbranch=${gitbranch:-${2:-master}}
        stamp=$gitbranch.`shortstamp`
        raccm Release
        cp $xmtx/Release/xmt/xmt ~/bin/xmt.$stamp
        installed=$xmtx/Release.$stamp
        cp -a $xmtx/Release $installed
        find $installed -name CMakeFiles -exec rm -rf {} \; || true
        find $installed -name Makefile -exec rm {} \;
        find $installed -name \*.cmake -exec rm {} \;
        ls -lr $xmtx/Release.$stamp
    )
}
mv1() {
    local to=$1
    shift
    if [[ $2 ]] ; then
        echo2 'mv1 expects 1 or 2 args (last is source file, first is dest)'
    else
        if [[ $1 ]] ; then
            mv "$1" $to
        else
            mv "$1" .
        fi
    fi
}
forpaste() {
    local f
    while read f; do
        "$@" $f
    done
}
yregr() {
    BUILD=Release yreg "$@"
}
rexmt() {
    (set -e
        cd $xmtx
        git pull --rebase
        racm "$@"
    )
}
rexmtr() {
    BUILD=Release rexmt
}
rexmty() {
    (set -e
        rexmt
        yreg "$@"
    )
}
rexmtry() {
    BUILD=Release rexmty
}
echo2() {
    echo "$@" 1>&2
}
save12() {
    local out="$1"
    [[ -f $out ]] && mv "$out" "$out~"
    shift
    echo2 saving output $out
    ( if ! [[ $quiet ]] ; then
        echo "$@";echo
        fi
        "$@" 2>&1) | tee $out | ${page:=cat}
    echo2 saved output:
    echo2 $out
}
save2() {
    local out="$1"
    [[ -f $out ]] && mv "$out" "$out~"
    shift
    echo2 saving output $out
    ( if ! [[ $quiet ]] ; then
        echo2 "$@";echo2
        fi
        "$@" ) 2>&1 2>$out.stdout | tee $out | ${page:=cat}
    echo
    tail $out $out.stdout
    echo2 saved output:
    echo2 $out $out.stdout
}
atime() {
    local proga=$1
    shift
    outa=`mktemp /tmp/$(basename $proga).out.XXXXXX`
    $proga "$@" >$outa 2>&1
    echo2 $proga "$@" "> $outa"
    echo2 ::::::::: nrep=$nrep
    time (for i in `seq 1 ${nrep:-1}`; do $proga "$@" >/dev/null 2>/dev/null; done ) 2>&1
    echo2 "$proga done (exit=$?)"
    echo2 =========
}
reptime() {
    width=$1
    shift
    height=${1}
    shift
    input=$1
    shift
    proga=${1:?usage: reptime [repeat-width] [repeat-height] [input-file] [program] [args] ...}
    shift
    repn $width $input | replinen $height | atime $proga "$@"
}
abtime() {
    proga=$1
    progb=$2
    shift
    shift
    atime $proga "$@"
    atime $progb "$@"
}
replinen() {
    perl -e '
$n=shift;
$m=$n;
($m,$n)=($1,$2) if $n=~/(\d+)-(\d+)/;
print STDERR "$m-$n vertical repeats of each line...\n";
while(<>) {
 for $i (1..$n) {
  print;
 }
}' "$@"
}
repn() {
    perl -e '
$n=shift;
$m=$n;
($m,$n)=($1,$2) if $n=~/(\d+)-(\d+)/;
print STDERR "$m-$n horizontal repeats of each line...\n";
while(<>) {
 chomp;
 $one=$_;
 for $i (1..$n) {
  print "$_\n" if $i>=$m;
  $_="$_ $one";
 }
}
' "$@"
}
expn() {
    perl -e '
$n=shift;
$m=$n;
($m,$n)=($1,$2) if $n=~/(\d+)-(\d+)/;
print STDERR "$m...$n doublings of each line...\n";
while(<>) {
 chomp;
 for $i (1..$n) {
  print "$_\n" if $i>=$m;
  $_="$_ $_";
 }
}
' "$@"
}
vocab() {
    perl -ne 'chomp;for (split) {
push @w,$_ unless ($v{$_}++);
}
END { print "$v{$_} $_\n" for (@w) }
' "$@"
}
xmtspeed() {
    logf=${logf:-~/tmp/xmtspeed.`shortstamp`}
    save12 $logf xmt -c /c07_data/mhopkins/trainings/eng-chi-xmt/EC.mrx.pbmt.noisy.sep10.DeTok/XMTConfig.yml -p final-decode-no-cap-detok -i /home/akariuki/CA/Tests/CA-7xxx/xline.in.txt -o xline.out.txt 2>&1
}
linbuild() {
    cd $xmtx
    local branch=$(git_branch)
    mend
    cjg build=$build branch=$branch regs=$regs test=$test all=$all reg=$reg macbuild $branch "$@" 2>&1 | tee ~/tmp/linbuild.$branch.`shortstamp` | filter-gcc-errors
}
splitape() {
    local file=${1%.ape}
    file=${file%.}
    (
        set -e
        cuebreakpoints "$file.cue" > "$file.offsets.txt"
        shntool split -f "$file.offsets.txt" -o ape -n "$file" "$file.ape"
    )
}
unhyphenate() {
    perl -pe 's/(?<=\w\w)- (?=\w+)//' "$@"
}
cpshared() {
    for f in $xmtx/xmt/graehl/shared/*; do
        cp $f ~/g/shared
    done
}
commshared() {
    cpshared
    commt "$@"
}
pgrep() {
    local flags=ax
    ps $flags | fgrep "$@" | grep -v grep
}
pgrepn() {
    pgrep "$@" | cut -f1 -d' '
}
pgrepkill() {
    pkill "$@"
}
overwrite() {
    if [[ $3 ]] ; then
        echo error: should be overwrite target src = cp src target
    fi
    cp "${2}" "${1%,}"
}
dryreg() {
    local args=${dryargs:--d}
    (set -e;
        cd $xmtx/RegressionTests
        if [[ -d $1 ]] ; then
            ./runYaml.py $args -b $racer/${BUILD:-Debug} -n -v "$@"
        elif [[ -f $1 ]] ; then
            ./runYaml.py $args -b $racer/${BUILD:-Debug} -n -v -y "$(basename $1)"
        elif [[ $1 ]] ; then
            ./runYaml.py $args -b $racer/${BUILD:-Debug} -n -v -y \*$1\*
        else
            ./runYaml.py $args -b $racer/${BUILD:-Debug} -n -v
        fi
    )
}

bakthis() {
    local branch=$(git_branch)
    if [[ $1 ]] ; then
        local suf=
        if [[ $1 ]] ; then
            suf=".$1"
        fi
        local to=$branch.b$suf
        killbranch $to
        git checkout -b "$to"
        git checkout $branch
    fi
}

savethis() {
    local branch=$(git_branch)
    if [[ $1 ]] ; then
        git checkout -b "$1"
        git checkout $branch
    fi
}
killbranch() {
    forall killbranch1 "$@"
}
killbranch1() {
    git branch -D "$1"
}
racer=$(echo $xmtx)
export WORKSPACE=$racer
racerextbase=$(echo ~/c/xmt-externals)
racerext=$racerextbase/$lwarch
racerlib=$racerext/libraries
racerlibshared=$racerextbase/Shared/cpp/libraries
export WORKSPACE=$racer
export XMT_EXTERNALS_PATH=$racerext
GRAEHL_INCLUDE=$racer/xmt

ffmpegaudio1() {
    local input=$1
    ffmpeg -i "$input" -acodec copy "${input%.mp4}.aac"
}
ffmpegaudio() {
    forall ffmpegaudio1 "$@"
}

jenkinsb() {
    local b=${BUILD:-Debug}
    local c=${2:---no-cleanup}
    local a=${3:---no-archive}
    CXX=${CXX:-g++} $WORKSPACE/jenkins/jenkins_buildscript $b $c $a
}
souph=98.158.26.222
macget() {
    local branch=${1:?args: branch]}
(
    set -e
    cd $xmtx
    echo branch $branch tar $tar
    git fetch mac
    if [[ $force ]] ; then
        git branch -D $branch || true
        git checkout -b $branch remotes/mac/$branch
    fi
    git checkout remotes/mac/$branch
)
}
macbuild() {
    local branch=${1:?args branch [target] [Debug|Release]}
    local tar=$2
    local build=${3:-${build:-Debug}}
    (
        set -e
        macget $branch
        if [[ $test ]] ; then
            test=1 raccm $build
        fi
        BUILD=$build makeh $tar
        if [[ $all ]] ; then
            raccm $build
        fi
        if [[ $reg ]] ; then
            BUILD=$build yreg $regs
        fi
    )
}
linevery() {
    test=1 all=1 reg=1 linbuild
}
mactest() {
    test=1 macbuild "$@"
}
macall() {
    all=1 mactest "$@"
}
macreg() {
    local branch=${1:-?args branch [regr-pat] [target] [Debug|Release|RelWithDebuInfo]}
    shift
    local regs=$1
    shift
    reg=1 regs=$regs macbuild $branch "$@"
}
soup() {
    ssh $souph "$@"
}
rebases() {
    perl -ne 'print "$1 " if /^(.*): needs merge/g'
    echo
}
rebasece() {
    (
        cd $xmtx
        for f in "$@"; do
            edit $f
        done
        rebasec "$@"
    )
}
unadd() {
    if [[ $* ]] ; then
        git reset HEAD "$@"
    fi
}
g1po() {
    (
        cd $xmtx/xmt
        export GRAEHL_INCLUDE=`pwd`
        cd $xmtx/xmt/graehl/shared
        ARGS='--a.xs 1 2 --b.xs 2 --death-year=2011 --a.str 2 --b.str abc' cleanup=1 g1 configure_program_options.hpp -DGRAEHL_CONFIGURE_SAMPLE_MAIN=1
    )
}
overt() {
    pushd $racer/xmt/graehl/shared
    gsh=~/g/shared
    for f in *.?pp; do
        rm -f $gsh/$f
        cp $f $gsh/$f
    done
    pushd ~/g
}
commt()
{
    (set -e
        overt
        compush "$@"
        popd
        popd
    )
}
branchthis() {
    [[ $1 ]] && git checkout -b "$1"
}
linuxfonts() {
    (set -e
        sudo=sudo
        fontdir=/usr/local/share/fonts
        local t=`mktemp /tmp/fc-list.XXXXXX`
        local u=`mktemp /tmp/fc-list.XXXXXX`
        fc-list > $t
        $sudo mkdir -p $fontdir
        $sudo cp "$@" $fontdir
        $sudo fc-cache $fontdir
        fc-list > $u
        echo change in fc-list
        diff -u $t $u
    )
}
gstat() {
    git status
}
rebasec() {
    git add "$@"
    git rebase --continue
}

mend() {
    (
        git commit --allow-empty -a -C HEAD --amend
    )
}

xmend() {
    (
        pushd $xmtx
        git commit -a --amend
        popd
    )
}


fastreg() {
    (set -e;
        cd $xmtx/RegressionTests
        for f in *; do
            [ -d $f ] && [ $f != BasicShell ] && [ $f != xmt ] && [ -x $f/run.pl ] && regressp $f
        done
    )
}
rencd() {
    local pre="$*"
    showvars_required pre
    local prein=
    local postin=" Audio Track.wav"
    local postout=".wav"
    local out=renamed
    mkdir -p $out
    echo "rencd $pre" > $out/rencd.sh
    local pfile=$out/rencd.prompt
    rm -f $pfile
    for i in `seq -f '%02g' 1 ${ntracks:-20}`; do
        local t="$pre - [$i] "
        read -e -p "$t"
        echo $REPLY >> $pfile
        cp "$prein$i$postin" "$out/$t$REPLY$postout"
    done
}
gitgc() {
    git gc --aggressive
}
branchmv() {
    git branch -m "$@"
}
gitrecase() {
    local to=${2:-$1}
    git mv $1 $1.tmp && git mv $1.tmp $to
    git commit -a -m "fix case => $to"
}
install_ccache() {
    for f in gcc g++ cc c++ ; do ln -s ccache /usr/local/bin/$f; done
}
gitclean() {
    local dry="-n"
    if [[ $1 ]] ; then
        dry="-f"
    fi
    git clean -d -x $dry
}
git_dirty() {
    if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] ; then
        echo -n "*"
    fi
}
git_untracked() {
    n=$(expr `git status --porcelain 2>/dev/null| grep "^??" | wc -l`)
    if [[ $n -gt 0 ]] ; then
        echo -n "($n)"
    fi
}
clonefreshxmt() {
    git clone ssh://graehl@git02.languageweaver.com:29418/xmt "$@"
    scp -p -P 29418 git02.languageweaver.com:hooks/commit-msg xmt/.git/hooks
}
forcebranch() {
    local branch=$(git_branch)
    local forceb=$1
    if [[ $forceb ]] ; then
        git branch -D $forceb || echo new branch $forceb of $branch
        echo from $branch to $forceb
        git checkout -b $forceb
    fi
}

upfrom() {
    local pullfrom=${1?args: [branch pull/rebase against] [backup#]}
    shift
    bakthis $1
    (set -e
        up $pullfrom
        git rebase $pullfrom
    )
}
breview() {
    local branch=$(git_branch)
    local rev=$branch-review
    git commit -a --amend # in case you forgot something
    (set -e
        if [[ $force ]] ; then
            forcebranch $rev
        else
            git checkout -b $rev
        fi
        up
        #git fetch origin
        #git rebase -i origin/master
        git rebase master
        git push origin HEAD:refs/for/master
        echo "git branch -D $rev # do this after gerrit merges it only"
    )
    echo ""
    git checkout $branch
    echo "git checkout $branch ; git fetch origin; git rebase origin/master # and this after gerrit merge"
}

drypull() {
    git fetch
    git diff ...origin
}
git_branch() {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}
rebase() {
    local branch=$(git_branch)
    git stash
    (set -e
        remaster
        co $branch
        git rebase master
    )
    git stash pop
    set +x
}
gd2() {
    echo branch \($1\) has these commits and \($2\) does not
    git log $2..$1 --no-merges --format='%h | Author:%an | Date:%ad | %s' --date=local
}
grin() {
    git fetch origin master
    gd2 FETCH_HEAD $(git_branch)
}
grout() {
    git fetch origin master
    gd2 $(git_branch) FETCH_HEAD
}
gitlog() {
    if [ $# -gt 0 ]; then
        git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short --branches -p -$1
    else
        git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short --branches -n ${ncommits:-30}
        echo
    fi
}
gitreview() {
    git review "$@"
}
gerritorigin="ssh://graehl@git02.languageweaver.com:29418/xmt"
gerritxmt() {
    echo git push $gerritorigin HEAD:refs/for/master
    git push $gerritorigin HEAD:refs/for/master
}
gerrit() {
    local gerritorigin=origin
    echo git push $gerritorigin HEAD:refs/for/master
    git push $gerritorigin HEAD:refs/for/master
}
gerritfor() {
    local gerritorigin=origin
    local rbranch=${1:-remote-branch}
    echo git push $gerritorigin HEAD:refs/for/$rbranch
    git push $gerritorigin HEAD:refs/for/$rbranch
}

review() {
    git commit -a
    gerrit
}

push2() {
    local l=$1
    if [[ $2 ]] ; then
        l+=":$2"
    fi
    git push origin $l
}
status() {
    git status
    git branch -a
}
#branch.<branch>.remote and branch.<branch>.merge
#git config branch.master.remote yourGitHubRepo.git
config() {
    git config "$@"
}
remotes() {
    git remote -v
    git remote show origin
}
tracking() {
    git config --get-regexp ^br.*
}
gitkall() {
    gitk --all
}
co() {
    if [[ "$*" ]] ; then
        git checkout "$@"
    else
        git branch -a
    fi
}
up() {
    local branch=`git_branch`
    local upbranch=${1:-master}
    (set -e;
        git fetch origin
        co $upbranch
        git pull --stat
        git rebase
    )
    co $branch
}
remaster() {
    (set -e
        co master
        git fetch origin
        git pull --stat
        git rebase
        [[ $1 ]] && git checkout $1
    )
}
squash() {
    local branch=$(git_branch)
    (set -e
        remaster $branch
        git rebase -i master
    )
}
squashmaster() {
    git reset --soft $(git merge-base master HEAD)
}
branch() {
    if [[ "$*" ]] ; then
        co master
        git checkout -b "$@"
    else
        git branch -a
    fi
}
gamend() {
    if [[ "$*" ]] ; then
        local marg=
        local arg=--no-edit
        # since git 1.7.9 only.
        if [[ "$*" ]] ; then
            marg="-m"
            arg="$*"
        fi
        git commit -a --amend $marg "$arg"
    else
        git commit -C HEAD --amend
    fi
}
amend() {
    git commit -a --amend "$@"
}
xmtclone() {
    git clone ssh://graehl@git02.languageweaver.com:29418/xmt "$@"
}
findc() {
    find . -name '*.hpp' -o -name '*.cpp' -o -name '*.ipp' -o -name '*.cc' -o -name '*.hh' -o -name '*.c' -o -name '*.h'
}

tea() {
    local time=${1:-200}
    shift
    local msg="$*"
    [[ $msg ]] || msg="TEA TIME!"
    (date;sleep $time;growlnotify -m "$msg ($time sec)";date) &
}

linxreg() {
    ssh $chost ". ~/a; BUILD=${BUILD:-Debug} fregress $*"
}

export PYTHONIOENCODING=utf_8
if [[ $HOST = graehl.local ]] ; then
    GCC_PREFIX=/usr/local/gcc-4.8.1
    GCC_BIN=$GCC_PREFIX/bin
fi
gcc48() {
    if [[ $HOST = graehl.local ]] ; then
        GCC_SUFFIX=-4.8
        export CC=ccache-gcc$GCC_SUFFIX
        export CXX=ccache-g++$GCC_SUFFIX
        prepend_path $GCC_PREFIX
        add_ldpath $GCC_PREFIX/lib
    fi
}
maketest() {
    (
        cd $xmtx/${BUILD:-Debug}
        if [[ $3 ]] ; then
            targ="-t $2/$3"
        elif [[ $2 ]] ; then
            targ="-t $2"
        fi
        local valgrindpre=
        if [[ $vg ]] && [[ $valgrind ]] ; then
            valgrindpre="$valgrind --db-attach=yes --tool=memcheck"
        fi
        local test=`find . -name Test$1`
        make VERBOSE=1 Test$1 && $valgrindpre $test $targ
    )
}
makerun() {
    local exe=$1
    if [[ $exe = test ]] ; then
        exe=check
    fi
    shift
    cd $xmtx/${BUILD:-Debug}
    local cpus=$(ncpus)
    echo2 "$cpus cpus ... -j$cpus"
    (set -e
        dumbmake $exe VERBOSE=1 -j$cpus || exit $?
        if [[ $exe != test ]] ; then
            set +x
            local f=$(echo */$exe)
            if [[ -x $f ]] ; then
                if ! [[ $pathrun ]] ; then
                    if ! [[ $norun ]] ; then
                        $f "$@"
                    fi
                else
                    $exe "$@"
                fi
            fi
        fi
    )
}
makex() {
    norun=1 makerun "$@"
}
makejust() {
    norun=1 makerun "$@"
}
makeh() {
    if [[ $1 ]] ; then
        makerun $1 --help
    else
        makerun
    fi
}
hncomment() {
    fold -w 77 -s | sed "s/^/   /" | pbcopy
}
forcet() {
    for f in "$@"; do
        cp $xmtx/xmt/graehl/shared/$f ~/t/graehl/shared
        lnshared1 $f
    done
}
no2() {
    echo cat $TEMP/no2.txt
    "$@" 2>$TEMP/no2.txt
}
fregress() {
    racer=$(echo ~/c/fresh/xmt) BUILD=${BUILD:-Debug} regress1 "$@"
}
regressdirs() {
    (
        cd $1
        for f in RegressionTests/*/run.pl ;do
            if [[ -f $f ]] ; then
                f=${f%/run.pl}
                f=${f#RegressionTests/}
                echo $f
            fi
        done
    )
}
regress1p() {
    local dir
    (
        cd ${racer:-$xmtx/}
        set -e
        for dir in "$@"; do
            local run=./RegressionTests/$dir/run.pl
            if [[ -x $run ]] ; then
                BUILD=${BUILD:-Debug} $run --verbose --no-cleanup
                set +x
            fi
        done
    )
}
regressp() {
    r="$*"
    [[ $* ]] || r=$(regressdirs ~/c/fresh/xmt)
    echo racer=$(echo ~/c/fresh/xmt) BUILD=${BUILD:-Debug} regress1p $r
    regress1p $r
}

fregressp() {
    racer=$(echo ~/c/fresh/xmt) regressp "$@"
}

regress1() {
    local dir
    for dir in "$@"; do
        (
            cd ${racer:-$xmtx}/RegressionTests/$dir
            if [[ -x ./run.pl ]] ; then
                BUILD=${BUILD:-Debug} ./run.pl --verbose --no-cleanup
            fi
        )
    done
}
regress2() {
    regress1 Hypergraph2
}
lwlmcat() {
    out=${2:-${1%.lwlm}.arpa}
    [[ -f $out ]] || LangModel -sa2text -lm-in $1 -lm-out "$out" -tmp ${TMPDIR:-/tmp}
    cat $out
}
pyprof() {
    #easy_install -U memory_profiler
    python -m memory_profiler -l -v "$@"
}
macpageoff() {
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist
}
macpageon() {
    sudo launchctl load -wF /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist
}

#file arg comes first! then cmd, then args
javaperf="-XX:+UseNUMA -XX:+TieredCompilation -server -XX:+DoEscapeAnalysis"
rrpath() {
    (set -e
        f=$(whichreal "$1")
        r=${2:-'$ORIGIN'}
        echo adding rpath "$r" to $f
        [ -f "$f" ]
        addrpathb "$f" "$r" "$f".rpath && mv "$f"{,.rpath.orig} && mv "$f"{.rpath,}
    )
}
svnchmodx() {
    chmod +x "$@"
    svn propset svn:executable '' "$@"
    svn propset eol-style native "$@"
}
lc() {
    catz "$@" | tr A-Z a-z
}
lnxmtlib() {
    d=${1?arg1: dest dir}
    mkdir -p $d
    for f in `find $racerext/libraries -name libd -prune -o -name '*.so'`; do
        echo $f
        force=1 lnreal $f $d/
    done
}
countvocab() {
    catz "$@" | tr -s ' \t' '\n' | sort | uniq -c
}
nsincludes() {
    perl -ne '
$ns=1 if /namespace/;
if (/^\s*#\s*include/ && $ns) {
print;
print $ARGV,"\n";
exit;
}
' "$1"
}
nsinclude() {
    for f in "$@"; do
        nsincludes "$f"
    done
}
gitpullsub() {
    #-q
    git submodule foreach git pull -q origin master
}
espullsub() {
    #-q
    cd ~/.emacs.d
    git submodule foreach git pull -q origin master
}
sitelisp() {
    cd ~/.emacs.d
    git submodule add git://github.com/${2:-emacsmirror}/$1.git site-lisp/$1
}
emcom() {
    cd ~/.emacs.d
    git add -v *.el defuns/*.el site-lisp/*.el
    git add -v snippets/*/*.yasnippet
    gcom "$@"
}
ecomsub() {
    cd ~/.emacs.d
    git pull
    cd site-lisp
    gitpushsub *
}
empull() {
    (
        cd ~/.emacs.d
        git pull
        cd site-lisp
        gitpullsub *
    )
}
uext() {
    cd $racerext
    svn update
}
comdocs() {
    cd $xmtx/docs
    svn change=md *.md
    change=md commit=1 revx "$@"
    makedocs
    svn commit *.pdf -m 'docs: pandoc to pdf'
}
makedocs() {
    cd $xmtx/docs
    . make.sh
}
roundshared() {
    cp $xmtx/xmt/graehl/shared/* ~/t/graehl/shared/; relnshared
}
tagtracks() {
    for i in `seq -w 1 99`; do echo $i; id3tag --album='Top 100 Best Techno Vol.1' --track=$i $i-*.mp3 ; done
}
tagalbum() {
    for f in *.mp3; do echo $i; id3tag --album="$*" "$f" ; done
}
svnmime() {
    local type=$1
    shift
    svn propset svn:mime-type $type "$@"
}
svnpdf() {
    svnmime application/pdf *.pdf
}
xhostc() {
    xhost +192.168.131.135
}
showdefines() {
    ${CC:-g++} -dM -E "${1:--}" < /dev/null
}
showcpp() {
    (
        local outdir=${outcpp:-~/tmp}
        local os=
        for f in "$@"; do
            local o=$outdir/$(basename $f).pp.cpp
            os+=" $o"
            rm -f $o
            f=$(realpath $f)
            pushd /Users/graehl/x/Debug/Hypergraph && /usr/bin/g++ -DGRAEHL_G1_MAIN -DHAVE_CXX_STDHEADERS -DBOOST_ALL_NO_LIB -DTIXML_USE_TICPP -DBOOST_TEST_DYN_LINK -DHAVE_SRILM -DHAVE_KENLM -DHAVE_OPENFST -O0 -g -Wall -Wno-unused-variable -Wno-parentheses -Wno-sign-compare -Wno-reorder -Wreturn-type -Wno-strict-aliasing -g -I/Users/graehl/x/xmt -I$racerlib/utf8 -I$racerlib/boost_1_49_0/include -I$racerlib/lexertl-2012-07-26 -I$racerlib/log4cxx-0.10.0/include -I$racerlib/icu-4.8/include -I/Users/graehl/x/xmt/.. -I$racerlib/BerkeleyDB.4.3/include -I/usr/local/include -I$racerlib/openfst-1.2.10/src -I$racerlib/openfst-1.2.10/src/include -I/users/graehl/t/ \
                -I $racerlib/db-5.3.15 \
                -I $racerlib/yaml-cpp-0.3.0-newapi/include \
                -I$racerlibshared/utf8 -I$racerlibshared/openfst-1.2.10/src -I$racerlibshared/tinyxmlcpp-2.5.4/include \
                -E -x c++ -o $o -c "$f" && emacs $o
            popd
        done
        echo
        echo $os
        preview $os
    )
}
pdfsettings() {
    # MS fonts - distributed with the free Powerpoint 2007 Viewer or the Microsoft Office Compatibility Pack
    #    mainfont=Cambria

    #no effect?
    margin=2cm
    hmargin=2cm
    vmargin=2cm

    #effect:
    paper=letter
    fontsize=11pt
    mainfont=${mainfont:-Constantia}
    sansfont=Corbel
    monofont=Consolas
    documentclass=scrartcl
    paper=letter

}
panda() {
    margin=1cm
    hmargin=1cm
    vmargin=1cm

    #    mainfont=Cambria
    mainfont=Constantia
    sansfont=Corbel
    monofont=Consolas
    fontsize=11pt
    documentclass=article
    #documentclass=scrartcl
    paper=letter


    if [[ $toc = 1 ]]; then
        tocparams="--toc"
    fi


    (
        for docmd in "$@"
        do
            set -e
            doc=${docmd%.md}
            doc=${doc%.}
            parentPage=XMT
            if [[ ${doc%-userdoc} != $doc ]] ; then
                parentPage=$userdocParent
            fi
            title=$doc
            tex=xelatex
            tf="$doc.tex"
            sources="$doc.md"
            params="--webtex --latex-engine=$tex --self-contained"
            html="$doc.html"
            echo generating $html for browser
            pandoc $params $tocparams -t html5 -o "$html" "$sources"
            if [[ $epub = 1 ]] ; then
                local coverarg
                local cover=${cover:-cover.png}
                if [[ -f $cover ]] ; then
                    coverarg=--epub-cover-image=$cover
                fi
                pandoc -S $coverarg -o "$doc.epub" "$sources"
            fi
            if [[ $pdf = 1 ]] ; then
                fpdf="$doc.pdf"
                rm -f "$fpdf"
                echo generating $tf
                latextemplate=${latextemplate:-$(echo ~/.pandoc/template/xetex.template)}
                local ltarg
                if [[ -f $latextemplate ]] ; then
                    ltarg="--template=$latextemplate"
                fi
                pandoc $params $tocparams -t latex -w latex -o "$tf" $ltarg --listings -V mainfont="${mainfont:-Constantia}" -V sansfont="${sansfont:-Corbel}" -V monofont="${monofont:-Consolas}"  -V fontsize=${fontsize:-11pt} -V documentclass=${documentclass:-article} -V geometry=${paper:-letter}paper -V geometry=margin=${margin:-2cm} -V geometry=${orientation:-portrait} -V geometry=footskip=${footskip:-20pt} "$sources"
                (
                    echo generating $fpdf
                    #TODO: fix all latex errors. xelatex is crashing on RegexTokenizer-userdoc
                    xelatex -interaction=nonstopmode "$tf"
                    if [[ $toc = 1 ]] ; then
                        xelatex -interaction=nonstopmode "$tf"
                    fi
                ) || echo latex exit code $?
            fi
            # I tried all of these in an attempt to adjust the pdf margins more aggressively, but neither did anything beyond just setting margin:

            # -V geometry=margin=$margin -V margin=$margin -V hmargin=$hmargin -V vmargin=$vmargin -V geometry=margin=$margin -V geometry=vmargin=$vmargin -V geometry=hmargin=$hmargin -V geometry=bmargin=$vmargin -V geometry=tmargin=$vmargin -V geometry=lmargin=$hmargin -V geometry=rmargin=$hmargin
            if [[ $open = 1 ]] ; then
                open $doc.pdf
            fi
        done
    ) || echo panda exit code $?
}
pandcrap() {
    local os=$1
    [[ $os = html ]] && os=html5
    local pdfargs=
    if [[ $os = pdf ]] ; then
        t=latex
        pdfsettings
    fi
    local f
    for f in "$@"; do
        local g=${f%.txt}
        g=${g%.md}
        g=${g%.}
        local o=$g.$os
        (
            texpath
            set -e
            # --read=markdown
            if [[ $os = pdf ]] ; then
                latextemplate=${latextemplate:-$(echo ~/.pandoc/template/xetex.template)}
                pandoc --webtex $f -o $o --latex-engine=xelatex --self-contained --template=$latextemplate --listings -V mainfont="${mainfont:-Constantia}" -V sansfont="${sansfont:-Corbel}" -V monofont="${monofont:-Consolas}"  -V fontsize=${fontsize:-11pt} -V documentclass=${documentclass:-article} -V geometry=${paper:-letter}paper -V geometry=margin=${margin:-2cm} -V geometry=${orientation:-portrait} -V geometry=footskip=${footskip:-20pt}
            else
                pandoc $f -o $o --latex-engine=xelatex --self-contained
                #--webtex
            fi
            if [[ "$open" ]] ; then open $o; fi
        )
        echo $o
    done
}
pandall() {
    pdf=1 epub=1 panda "$@"
}
pandcrapall()
{
    local o=`pandcrap html "$@"`
    pandcrap latex "$@"
    #pand epub "$@"
    #pand mediawiki "$@"
    pandcrap pdf "$@"
    local f
    for f in $o; do
        open $f
    done
}
texpath() {
    export PATH=/usr/local/texlive/2012/bin/x86_64-darwin/:/usr/local/texlive/2012/bin/universal-darwin/:$PATH
}
sshut() {
    local dnsarg=
    if [ "$dns "] ; then
        dnsarg="--dns"
    fi
    ~/sshuttle/sshuttle $dnsarg -vvr graehl@ceto.languageweaver.com 0/0
}
dotshow() {
    local f=${1:-o}
    dot $f -Tpng -o $f.png && open $f.png
}
fsmshow() {
    local f=$1
    require_file $f
    local g=$f.dot
    HgFsmDraw "$f" > $g
    dotshow $g
}
sceto() {
    ssh -p 4640 ceto.languageweaver.com "$@"
}
bsceto() {
    homer Hypergraph
    bceto
}
bceto() {
    sceto ". a;linx Debug"
}
homer() {
    for p in "$@"; do
        scp -P 4640 -r ~/c/xmt/$p/*pp graehl@ceto.languageweaver.com:c/xmt/xmt/$p
    done
}
homers() {
    homer Hypergraph
    homer LWUtil
}
#racer=$racer/xmt
#racer=$racer
#racers=$racer/xmt
view() {
    if [[ $lwarch = Apple ]] ; then
        open "$@"
    else
        xzgv "$@"
    fi
}
realgit=`which git`
substigrep() {
    local repl=$1
    (set -e
        require_file "$repl"
        shift
        substi $repl $(ag -l "$@")
    )
}
substi() {
    (set -e
        local tr=$1
        shift
        if ! [[ $nodryrun ]] ; then
            subst.pl "$@" --dryrun --inplace --tr "$tr"
            echo
        fi
        cat $tr
        echo
        echo ctrl-c to abort
        sleep 3
        subst.pl "$@" --inplace --tr "$tr"
    )
}
substigrepq() {
    substi $1 `ag -l $(basename $1)`
}
substrac() {
    (
        pushd $racer/xmt
        substi "$@" $(ack --cpp -f)
    )
}
substcpp() {
    (
        substi "$@" $(find . -name '*.?pp')
    )
}
substyml() {
    (
        substi "$@" $(ag -g '\.ya?ml$')
    )
}
substcmake() {
    (
        substi "$@" $(ack --cmake -f)
    )
}
git() {
    if [[ $INSIDE_EMACS ]] ; then
        $realgit --no-pager "$@" | head -80
    else
        $realgit "$@"
    fi
}
gitchange() {
    git --no-pager log --format="%ai %aN %n%n%x09* %s%d%n"
}
mflist() {
    perl -e 'while(<>) { if (/<td align="left">([^<]+)</td>/) { $n=$1; $l=1; } else { $l=0; } }'
}
showlib() {
    (
        export DYLD_PRINT_LIBRARIES=1
        "$@"
    )
}
otoollibs() {
    perl -e '
$f=shift;
$_=`otool -L $f`;
while (m|^\s*(\S+) |gm) {
print "$1 " unless $1 =~ m|^/usr/lib/|;
}
print "\n";
' $1
}
libmn() {
    local m=${1:-48}
    local n=${2:-1}
    local s=$m.$n.dylib
    for f in *.$s; do local g=${f%.$s};
        local ss="$g.dylib $g.$m.dylib"
        svn rm $ss
        ln -sf $f $g.dylib
        ln -sf $f $g.$m.dylib
        svn add $ss
    done
}

hgrep() {
    history | grep "$@"
}
brewgdb() {
    brew install https://github.com/adamv/homebrew-alt/raw/master/duplicates/gdb.rb
}
gdbtool () {
    emacsc --eval "(gud-gdb \"gdb --annotate=3; --args $*\")"
}
svnrespecial() {
    for f in "$@"; do
        rm $f
        svn update $f
    done
}
fontsmooth() {
    defaults -currentHost write -globalDomain AppleFontSmoothing -int "${1:-2}"
}
locp=${locp:9922}
tun1() {
    #eg tun1 revboard 80 9921
    local p=${3:-$port}
    if ! [[ $p ]] ; then
        p=$locp
        locp=$((locp+1))
    fi
    # ssh -L9922:svn.languageweaver.com:443 -N -t -x pontus.languageweaver.com -p 4640 &
    ssh -L$p:${1:-$chost.languageweaver.com}:${2:-22} -N -t -x ${4:-ceto}.languageweaver.com -p 4640
    set +x
    lp=localhost:$p
    echo lp
    echo $lp
}
tunsvn() {
    tun1 svn 80 $rxsvnp
}
lwsvnhost=svn.languageweaver.com
localsvnhost=localhost:$rxsvnp
rxsvn="http://svn.languageweaver.com/svn/repos2"
rxlocal="http://localhost:$rxsvnp/svn/repos2"
cmerepo="http://svn.languageweaver.com/svn/repos2"
cmelocal="http://localhost:$rxsvnp/svn/repos2"
rblocal="http://localhost:$revboardp/"
rblw="http://revboard/"

revboardrc() {
    local rb=$rblw
    if [[ $local ]] ; then
        rb=$rblocal
    fi
    (echo "REPOSITORY = \"$cmerepo\""; echo "REVIEWBOARD_URL = \"$rb\"") > .reviewboardrc
}
svnroot() {
    svn info | grep ^Repository\ Root | cut -f 3 -d ' '
}
svnswitchurl() {
    svnroot | sed "s/$1/$2/"
}
svnswitchhost() {
    local r=$(svnroot)
    local u=$(svnswitchurl "$@")
    echo "$r => $u"
    if [[ $svnpass ]] ; then
        local sparg="--password $svnpass"
    fi
    if [[ $svnuser ]] ; then
        local suarg="--username graehl"
    fi
    svn relocate $suarg $sparg "$r" "$u"
}
svnswitchlocal() {
    if [[ $local ]] ; then
        svnswitchhost $lwsvnhost $localsvnhost
    else
        svnswitchhost $localsvnhost $lwsvnhost
    fi
}
rxtun() {
    (
        cd $racer
        svn relocate $rxsvn $rxlocal
        revboardrc
    )
}
#switch --relocate
rxlw() {
    (
        cd $racer
        svn relocate $rxlocal $rxsvn
        revboardrc
    )
}
tokdot() {
    local t=${1:-2}
    shift
    local s=${1:-9}
    shift
    pushd $xmtx/xmt/FsTokenizer
    stopw=$s tokw=$t draw=1 ./test.sh tiny.{vcb,untok}
    hgdot ~/r/FsTokenizer/work/s=$s,t=$t/tiny.vcb.trie.gz
    popd
}
tokt() {
    pushd $xmtx/xmt/FsTokenizer
    ./test.sh "$@"
}
revx() {
    local dr=
    #p
    local sum=$1
    shift
    if [[ $dryrun ]] ; then
        dr="n"
    fi
    pushd $racer
    local dry=1
    local carg=
    if [[ $change ]] ; then carg="--svn-changelist=$change"; fi
    if [[ $commit ]] ; then dry=; fi
    if [ "$sum" ] ; then
        post-review -do$dr $carg --summary="$sum" --description="$*" --username=graehl --password=cheese --target-groups=ScienceCoreModels
        dryrun=$dry crac "$sum: $*"
        echo "crac '$sum: $*'" > $xmtx/commit.sh
        chmod +x $xmtx/commit.sh
    fi
    set +x
    popd
}
rerevx() {
    revxcmd -r "$@"
}
revxcmd() {
    pushd $racer
    if [[ $change ]] ; then carg="--svn-changelist=$change"; fi
    post-review "$@" $carg --username=graehl --password=cheese
    set +x
    popd
}
withdbg() {
    local d=$1
    shift
    local gdbc=
    if [ "$gdb" ] ; then
        gdbc="gdb --args"
    fi
    # TUHG_DBG=$d
    TUHG_DBG=$d HYPERGRAPH_DBG=$d LAZYF_DBG=$d HGBEST_DBG=$d $gdbc "$@"
}
rmstashx() {
    rm -rf ~/c/stash.*
}
stashx() {
    cd ~/c
    local s=~/c/stash.`shortstamp`
    mkdir -p $s
    cp -pr ~/c/xmt/{3rdParty/graehl,racerx/Hypergraph} $s
}
rcompile() {
    local s=$1
    shift
    local flags="-I$BOOST_INCLUDE -I$HOME/x/3rdparty -I$HOME/x -O0 -ggdb"
    g++ $flags -x c++ -DGRAEHL__SINGLE_MAIN -DHYPERGRAPH_MAIN "$s" "$@"
}
brewrehead() {
    brew remove "$@"
    safebrew install -d --force -v --use-gcc --HEAD "$@"
}
brewhead() {
    safebrew install -d --force -v --use-gcc --HEAD "$@"
}
nonbrew() {
    find "$1" \! -type l \! -type d -depth 1 | grep -v brew
}
rebrew() {
    brew remove "$@"
    safebrew install "$@"
}
safebrew() {
    local log=/tmp/safebrew.log
    (
        saves=$(echo /usr/local/{bin,lib,lib/pkgconfig})
        set +e
        for f in $saves; do
            echo mkdir -p $f/unbrew
            mkdir -p $f/unbrew
            set +x
            mv `nonbrew $f` $f/unbrew/
        done
        mv /usr/local/bin/auto* $savebin
        export LDFLAGS+=" -L/usr/local/Cellar/libffi/3.0.9/lib"
        export CPPFLAGS+="-I/usr/local/Cellar/libffi/3.0.9/include"
        export PATH=/usr/local/bin:$PATH
        export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
        #by default it looks there already. just in case!
        unset DYLD_LIBRARY_PATH
        brew -v "$@" || brew doctor
        set +x
        savedirs=
        for f in $saves; do
            savedirs+=" $f/unbrew"
            mv -n $f/unbrew/* $f/
        done
        echo $savedirs should be empty:
        ls -l $savedirs
        echo empty, i hoope
    ) 2>&1 | tee $log
    echo cat $log
}
awksub() {
    local s=$1
    shift
    local r=$1
    shift
    awk '{gsub(/'"$s"'/,"'"$r"'")};1' "$@"
}
awki() {
    local f=$1
    shift
    cmdi "$f" awk "$@"
}
cmdi() {
    local f=$1
    shift
    local cmd=$1
    shift
    ( mv $f $f~ && $cmd "$@" > $f) < $f
    diff -b -B -- $f~ $f
}

gitsubuntracked() {
    awki .gitmodules ' {print}; /^.submodule / { print "\tignore = untracked" }'
}

gitpush1sub() {
    local p=$1
    shift
    local msg="$*"
    local sub=$(basename $p)
    echo git submodule push $p ...
    if ! [[ -d $p ]] ; then
        echo gitsubpush skipping non-directory $p ...
    else
        sub=${sub%/}
        (set -e
            pushd $p
            gcom "$msg"
            cd ..
            git commit $sub -m "$msg"
            git push $sub -m "$msg"
        )
    fi
}
gitpushsub() {
    forall gitpushsub1 "$@"
}
gitpullsub1() {
    local p=$1
    shift
    local msg="$*"
    echo git submodule push-pull $p ...
    if ! [[ -d $p ]] ; then
        echo gitpullsub skipping non-directory $p ...
    else
        (
            set -e
            pushd $p
            local sub=$(basename $p)
            sub=${sub%/}
            local gitbranch=${gitbranch:-${2:-master}}
            banner pulling submodule $p ....
            showvars_required sub gitbranch
            ! grep graehl .git/config || gcom "$msg"
            git checkout $gitbranch
            git pull
            cd ..
            git add `basename $p`
            git commit $sub -m "pulled $p - $msg"
            [[ $nopush ]] || git push
            banner DONE pulling submodule $p.
        )
    fi
}
gitpullsub() {
    forall gitpullsub1 "$@"
}
dbgemacs() {
    ${emacs:-appemacs} --debug-init
}
freshemacs() {
    git clone --recursive git@github.com:graehl/.emacs.d.git
}
urlup() {
    #destroys hostname if you go to far
    perl -e '$_=shift;s|/[^/]+/?$||;print "$_";' "$*"
}
svnurl() {
    svn info | awk '/^URL: / {print $2}'
}
svngetrev() {
    svn ls -v "$@" | awk '{print $1}'
}
svnprev() {
    #co named revision of file in current dir
    local f=${1?-arg1: file in cdir}
    local r=$2
    [[ $r ]] || r=PREV
    local svnu=`svnurl`
    #local svnp=`urlup $svnu`
    local svnp="$svnu"
    local d=`basename $svnu`
    local dco="co-$d-r$r"
    set -e
    showvars_required svnp dco f r
    require_file $f
    local rev=`svngetrev -r "$r" $f`
    echo ""$f at revision $rev - latest as of requested $r:""
    ! [[ -d $dco ]] || rm -rf $dco/
    svn checkout -r "$rev" $svnp $dco --depth empty || error "svn checkout -r '$rev' '$svnp' $dco --depth empty" || return
    pushd $dco
    svn update -r "$rev" $f || error "svn update $f" || return
    popd
    local dest="$f@$r"
    ln -sf $dco/$f $dest
    diff -s -u "$dest" "$f"
    echo diff -s -u "$dest" "$f"
    echo
    echo $dest
}
svnprevs() {
    local rev=$1
    shift
    for f in "$@"; do
        (svnprev $f $rev)
    done
}
pids() {
    grep=${grep:-/usr/bin/grep}
    ps -ax | awk '/'$1'/ && !/awk/ {print $1}'
}
gituntrack() {
    git update-index --assume-unchanged "$@"
}
svntaglog() {
    local proj=${1:-carmel}
    local spath=${2:-"https://nlg0.isi.edu/svn/sbmt/tags/$proj"}
    showvars_required proj spath
    svn log -v -q --stop-on-copy $spath
}

svntagr() {
    svntaglog "$@" | grep " A"
}

gitsub() {
    git pull
    git submodule update --init --recursive "$@"
    git pull
}
gitco() {
    git clone --recursive "$@"
}
gitchanged() {
    git status -uno
}
gcom() {
    gitchanged
    git commit -a -m "$*"
    git push -v || true
}
scom() {
    svn commit -m "$*"
}
gscom() {
    gcom "$@"
    scom "$@"
}
acksed() {
    echo going to replace $1 by $2 - ctrl-c fast!
    (set -e
        ack -l $1
        sleep 3
        ack -l --print0 --text $1 | xargs -0 -n 1 sed -i -e "s/$1/$2/g"
        ack $1l

    )
}
retok() {
    cd $xmtx/xmt/Tokenizer
    ./test.sh "$@"
}
hgdot() {
    local m=${3:-${1%.gz}}
    HgDraw $1 > $m.dot
    doto $m.dot $2
}
doto() {
    local t=${2:-pdf}
    local o=${3:-${1%.dot}}
    dot -Tpdf -o$o.$t $1 && open $o.$t
}

dbgemacs() {
    cd ~/bin/Emacs.contents
    MacOS/Emacs --debug-init "$@"
}
lnshared() {
    forall lnshared1 "$@"
}
lnshared1() {
    local s=~/t/graehl/shared
    local f=$s/$1
    local d=$racer/xmt/graehl/shared
    local g=$d/$1

    if ! [ -r $f ] ; then
        cp $g $f
    fi
    if [ -r $f ] ; then
        if ! [ -r $g ] ; then
            ln $f $g
        fi
        if diff -u $g $f || [[ $force ]] ; then
            rm -f $g
            ln $f $g
        fi
    fi

    (cd $s; svn add "$1")
    #(cd $d; svn add "$1")
}
racershared1() {
    local s=~/t/graehl/shared
    local f=$s/$1
    local d=$racer/xmt/graehl/shared
    local g=$d/$1
    if [ -f $g ] ; then
        if [ "$force" ] ; then
            diff -u -w $f $g
            rm -f $f
        fi
        ln $g $f
    fi
}
usedshared() {
    (cd $racer/xmt/graehl/shared/;ls *.?pp)
}
diffshared1() {
    local s=~/t/graehl/shared/
    local f=$s/"$1"
    local d=$racer/xmt/graehl/shared/
    diff -u -w $f $d/$1
}
diffshared() {
    forall diffshared1 $(usedshared)
}
relnshared() {
    lnshared $(usedshared)
}
lnhg1() {
    local d=$1
    shift
    local pre=$1
    shift
    rpathsh=$racerlib/rpath.sh
    echo "$d" > ~/bin/racerbuild.dirname
    for f in $d/$pre*; do
        $rpathsh $f 1
        if [[ ${f%.log} = $f ]] ; then
            basename $f
            local b=`basename $f`
            for t in $b egdb$b gdb$b vg$b; do
                echo $t
                ln -sf $racer/run.sh ~/bin/$t
            done
        fi
    done
}
rpathhg() {
    rpathsh=$racer/3rdParty/Apple/rpath.sh
    local b=${1:-Debug}
    find $racer/$b -type f -exec $rpathsh {} \;
}
lnhg() {
    local b=${1:-Debug}
    lnhg1 $racer/$b ProcessYAML/ProcessYAML
    lnhg1 $racer/$b ProcessYAML/ProcessYAML
    lnhg1 $racer/$b ProcessYAML/Test
    lnhg1 $racer/$b RuleDumper/RuleDumper
    lnhg1 $racer/$b SyntaxBased/Test
    lnhg1 $racer/$b LanguageModel/LMQuery/LMQuery
    lnhg1 $racer/$b LWUtil/Test
    lnhg1 $racer/$b Grammar/Test
    lnhg1 $racer/$b FeatureBot/Test
    lnhg1 $racer/$b Utf8Normalize/Utf8Normalize
    lnhg1 $racer/$b BasicShell/xmt
    lnhg1 $racer/$b OCRC/OCRC
    lnhg1 $racer/$b AutoRule/Test
    lnhg1 $racer/$b RuleSerializer/Test
    lnhg1 $racer/$b Hypergraph/Test
    lnhg1 $racer/$b Config/Test
    lnhg1 $racer/$b Hypergraph/Hg
    lnhg1 $racer/$b StatisticalTokenizer/StatisticalTokenizer
    lnhg1 $racer/$b LmCapitalize/LmCapitalize
    lnhg1 $racer/$b ValidateConfig/ValidateConfig
}
rebuildc() {
    (set -e
        s2c
        ssh $chost ". ~/a;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose} tests=${tests:-Hypergraph/Empty} racm Debug"
    )
}
ackc() {
    ack --ignore-dir=3rdParty --pager="less -R" --cpp "$@"
}
freshx() {
    (set -e; set -x; racer=~/c/fresh/xmt; cd $racer ; [ "$noup" ] || svn update; raccm ${1:-Debug}; cd $racer; RegressionTests/run.pl)
}
linx() {
    ssh $chost ". ~/.e;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose}_LEVEL test=$test tests=$tests freshx $*"
}
linxx() {
    (cd;sync2 $chost x/xmt x/RegressionTests x/docs)
    ssh $chost ". ~/.e;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose}_LEVEL test=$test tests=$tests raccm $*"
}

cmehost=cme01.languageweaver.com
cmex() {
    ssh $cmehost ". ~/a;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose}_LEVEL test=$test tests=$tests freshx $*"
}
cmexx() {
    (cd;sync2 $cmehost x/xmt x/RegressionTests x/docs)
    ssh $cmehost ". ~/a;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose}_LEVEL test=$test tests=$tests raccm $*"
}

horse=~/c/horse
horsem() {
    (
        export LW64=1
        export LWB_JOBS=5
        cd $horse
        perl GenerateSolution.pl
        make
    )
}
sa2c() {
    s2c
    (cd
        for d in x/xmt/ ; do
            sync2 $chost $d
        done
    )
}
s2c() {

    #elisp x/3rdParty
    (cd
        set -e
        toc x/run.sh
        toc x/xmtpath.sh
        for d in u g script bugs .gitconfig ; do
            sync2 $chost $d
        done
    )
}
syncc() {
    sync2 $chost "$@"
}
svndry() {
    svn merge --dry-run -r BASE:HEAD ${1:-.}
}
cregress() {
    find $xmtx/RegressionTests -name '*.log' -exec rm {} \;
}
sconsd() {
    scons -Q --debug=presub "$@"
}
#sudo gem install git_remote_branch --include-dependencies - gives the nice 'grb' git remote branch cmd
#see aliases in .gitconfig #git what st ci co br df dc lg lol lola ls info ign


ncpus() {
    if [[ $lwarch = Apple ]] || ! [[ -f /proc/cpuinfo ]] ; then
        if [[ $usecpus ]] ; then
            echo $usecpus
        else
            echo 1
        fi
    else
        local actual=`countcpus`
        local r=$((actual+3))
        echo $r
        #echo2 "using -j$r, actual cpus=$actual"
    fi
}
countcpus() {
    grep ^processor /proc/cpuinfo | wc -l
}
MAKEPROC=${MAKEPROC:-$(ncpus)}

lsld() {
    echo $DYLD_LIBRARY_PATH
}
addld() {
    if [[ $lwarch = Apple ]] ; then
        if ! fgrep -q "$1" <<< "$DYLD_LIBRARY_PATH" ; then
            export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$1
        else
            true || echo "$1 already in DYLD_LIBRARY_PATH"
        fi
    else
        if ! fgrep -q "$1" <<< "$LD_LIBRARY_PATH" ; then
            export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$1
        else
            true || echo "$1 already in LD_LIBRARY_PATH"
        fi
    fi
}
dylds() {

    for f in $racerlib/*; do
        if [ -d $f/lib ] ; then #[[ ${f%log4cxx-10.0.0} == $f ]] &&
            #echo $f
            addld $f/lib
        fi
    done
}
dylds

failed() {
    racb
    testlogs $(find . -type d -maxdepth 2)
}
testlogs() {
    for f in "$@"; do
        local g=$f/Testing/Temporary/LastTestsFailed.log
        if [ -f $g ] ; then
            tailn=30 preview $g
        fi
    done
}
corac() {
    svn co http://svn.languageweaver.com/svn/repos2/cme/trunk/xmt
    cd racerx
}
#sets cmarg
racb() {
    build=${build:-Release}
    build=${1:-$build}
    shift || true
    if [[ $debug = 1 ]] ; then
        build=Debug
    fi
    racerbuild=$racer/$build
    racer3=$racer/3rdParty
    export XMT_EXTERNALS_PATH=$racerext
    mkdir -p $racerbuild
    cd $racerbuild
    local buildtyped=$build
    if [[ ${build#Debug} != $build ]] ; then
        buildtyped=Debug
    fi
    local allarg=
    local allhg=
    if [[ $allhg ]] ; then
        allarg="-DAllHgBins=1"
    fi
    if [[ $nohg ]] ; then
        allarg=
    fi
    cmarg="-DCMAKE_BUILD_TYPE=${buildtype:-$buildtyped} $allarg $*"
    if [[ $HOST = graehl.local ]] || [[ $OS = Darwin ]] ; then
        cmarg+=" -DLOG4CXX_ROOT=/usr/local"
    fi
    CMAKEARGS=${CMAKEARGS:- -DCMAKE_COLOR_MAKEFILE=OFF -DCMAKE_VERBOSE_MAKEFILE=OFF}
    cmarg+=" $CMAKEARGS"
}
racd() {
    cd $racer
    svn diff -b
}
urac() {
    (
        cd $racer
        if ! [ "$noup" ] ; then svn update ; fi
    )
}
crac() {
    pushd $racer
    local dryc=
    if [[ $dryrun ]] ; then
        dryc=echo
    fi
    local carg=
    if [[ $change ]] ; then carg="--changelist $change"; fi
    $dryc svn commit $carg -m "$*"
    popd
}
commx() {
    crac "$@"
}
svndifflines()
{
    diffcontext=0
    echo changed wc -l:
    svndiff | wc -l
}
svndiff()
{
    local diffcontext=${diffcontext:-8}
    svn diff --diff-cmd diff --extensions "-U $diffcontext -b"
}
svndifflog() {
    local lastlog=${1:-5}
    shift
    svn log -l $lastlog --incremental "$@"
    svndiff
}
drac() {
    cd $racer/3rdparty
    banner 3rdparty svn
    svndifflog 2 "$@"
    echo;echo
    banner racerx svn
    cd $racer
    svndifflog 5 "$@"
}
runc() {
    ssh $chost "$*"
}
enutf8=en_US.UTF-8
sc() {
    if [[ $term != xterm-256color ]] ; then
        ssh $chost "$@"
    else
        LANG=$enutf8 mosh --server="LANG=$enutf8 mosh-server" $chost "$@"
    fi
}
tocabs() {
    tohost $chost "$@"
}
toc() {
    tohostp $chost "$@"
}
topon() {
    thostp $phost "$@"
}
fromc() {
    fromhost $chost "$@"
}
clocal() {
    (
        set -e
        if [ "$1" ] ; then cd $1* ; fi
        ./configure --prefix=/usr/local "$@" && make -j && sudo make install
    )
}
msudo() {
    make -j 4 && sudo make install
}
cgnu() {
    for f in "$@"; do
        g=$f-${ver:-latest}.tar.${bzip:-bz2}
        (set -e
            curl -O http://ftp.gnu.org/gnu/$f/$g
            tarxzf $g
        )
    done
}
emacsapp=/Applications/Emacs.app/Contents/MacOS/
emacssrv=$emacsapp/Emacs
emacsc() {
    if [ "$*" ] ; then
        if [[ -x ~/bin/eclient.sh ]] ; then
            ~/bin/eclient.sh "$@"
        else
            $emacsapp/bin/emacsclient -a $emacssrv "$@"
        fi
    else
        $emacssrv &
    fi
}

svnln() {
    forall svnln1 "$@"
}
svnln1() {
    ln -s $1 .
    svn add $(basename $1)
}


hemacs() {
    nohup ssh -X hpc-login2.usc.edu 'bash --login -c emacs' &
}
to3() {
    #-f ws_comma
    2to3 -f all -f idioms -f set_literal "$@"
}
to2() {
    #-f set_literal #python 2.7
    2to3 -f idioms -f apply -f except -f ne -f paren -f raise -f sys_exc -f tuple_params -f xreadlines -f types "$@"
}

ehpc() {
    local cdir=`pwd`
    local lodir=`relhome $cdir`
    ssh $HPCHOST -l graehl ". .bashrc;. t/graehl/util/bashlib.sh . t/graehl/util/aliases.sh;cd $lodir && $*"
}
reltohpc() {
    local cdir=`pwd`
    local lodir=`relhome $cdir`
    ssh $HPCHOST -l graehl "mkdir -p $lodir"
    scp "$@" graehl@$HPCHOST:$lodir
}

splitcomma() {
    clines "$@"
}

getwt()
{
    local f="$1"
    shift
    clines "$@" | fgrep -- "$f"
}
imira() {
    local hm=$HOME/hiero-mira
    local m=$HOME/mira
    rm -rf $hm
    mkdir -p $hm
    local b=/home/nlg-03/mt-apps/hiero-mira/20110804
    cp -pR $b/* $hm/
    qmira
}
qmira()
{
    local hm=$HOME/hiero-mira
    local m=$HOME/mira
    for f in $m/{genhyps,log,trainer,sbmt_decoder}.py; do
        cp -p $f $hm/
    done
    (
        cd
        cd $hm
        pycheckers {genhyps,log,trainer,sbmt_decoder}.py
    )

}
vgnorm() {
    perl -i~ -pe 's|^==\d+== ?||;s|\b0x[0-9A-F]+||g' "$@"
}

pycheckers() {
    (
        pycheckerarg=${pycheckerarg:- --stdlib --limit=1000}
        [ -f setup.sh ] && . setup.sh
        for f in "$@" ; do
            pychecker $pycheckerarg $f 2>&1 | grep -v 'Warnings...' | grep -v 'Processing module ' | tee $f.check
        done
    )
}
#simpler than pychecker
pycheck() {
    python -c "import ${1%.py}"
}

cmpy() {
    python setup.py ${target:-install} --home $FIRST_PREFIX
}
cmpyh() {
    python setup.py ${target:-install} --home ~
}
backupsbmt() {
    mkdir -p $1
    #--exclude Makefile\* --exclude auto\* --exclude config\*
    #--size-only
    rsync --modify-window=1 --verbose --max-size=500K --cvs-exclude --exclude '*~' --exclude libtool --exclude .deps --exclude \*.Po --exclude \*.la --exclude hpc\* --exclude tmp --exclude .libs --exclude aclocal.m4 -a $SBMT_TRUNK ${1:-$dev/sbmt.bak}
    #-lprt
    # cp -a $SBMT_TRUNK $dev/sbmt.bak
}
build_sbmt_variant()
{
    #target=check
    variant=debug boostsbmt "$@"
}

boostsbmt()
{
    (
        set -e
        local h=${host:-$HOST}
        nproc_default=5
        if [[ "$h" = cage ]] ; then
            nproc_default=7
        fi
        nproc=${nproc:-$nproc_default}
        variant=${variant:-$releasevariant}
        local linking="link=static"
        linking=
        branch=${branch:-trunk}
        trunkdir=${trunkdir:-$SBMT_BASE/$branch}
        [ -d $trunkdir ] || trunkdir=$HOME/t
        showvars_required branch trunkdir
        pushd $trunkdir
        mkdir -p $h
        local prefix=${prefix:-$FIRST_PREFIX}
        [ "$utility" ] && target="utilities//$utility"
        target=${target:-install-pipeline}
        #
        #--boost-location=$BOOST_SRCDIR
        #-d 4
        local barg boostdir
        local builddir=${build:-$h}
        if [[ $boost ]] ; then
            boostdir=$HOME/src/boost_$boost
            builddir="${builddir}_boost_$boost"
        fi
        if [[ $boostdir ]] ; then
            [[ -d $boostdir ]] || boostdir=/usr/local
            barg="--boost=$boostdir"
        fi
        execpre=${execpre:-$FIRST_PREFIX}
        if [[ $variant = debug ]] ; then
            execpre+=/debug
        fi
        if [[ $variant = release ]] ; then
            execpre+=/valgrind
        fi
        bjam cflags=-Wno-parentheses cflags=-Wno-deprecated cflags=-Wno-strict-aliasing -j $nproc $target variant=$variant toolset=gcc --build-dir=$builddir --prefix=$prefix --exec-prefix=$execpre $linking $barg "$@" -d+${verbose:-2}
        set +x
        popd
    )
}
tmpsbmt() {
    local tmpdir=/tmp/trunk.graehl.$HOST
    backupsbmt $tmpdir
    trunkdir=$tmpdir/trunk boost=${boost:-1_35_0} boostsbmt "$@"
}
vgsbmt() {
    variant=release tmpsbmt
}
dusort() {
    perl -e 'require "$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl";while(<>){$n=()=m#/#g;push @{$a[$n]},$_;} for(reverse(@a)) {print sort_by_num(\&first_mega,$_); }' "$@"
}
realwhich() {
    whichreal "$@"
}
check1best() {
    echo 'grep decoder-*.1best :'
    perl1p 'while(<>) { if (/sent=(\d+)/) { $consec=($1==$last)?"(consecutive)":""; $last=$1; log_numbers("sent=$1"); if ($n{$1}++) { count_info_gen("dup consecutive $ARGV [sent=$1 line=$.]");log_numbers("dup $ARGV $consec: $1") } } } END { all_summary() }' decoder-*.1best
    grep -i "bad_alloc" logs/*/decoder.log
    grep -i "succesful parse" logs/*/decoder.log | summarize_num.pl
    grep -i "pushing grammar" logs/*/decoder.log | summarize_num.pl
    # perl1p 'while(<>) { if (/sent=(\d+)/) { next if ($1==$last); $last=$1; log_numbers($1); log_numbers("dup: $1") if $n{$1}++; } } END { all_summary() }' decoder-*.1best
}

blib=$d/bloblib.sh
[ -r $blib ] && . $blib
em() {
    nohup emacs ~/t/sbmt_decoder/include/sbmt/io/logging_macros.hpp ~/t/sblm/sblm_info.hpp &
}
libzpre=/nfs/topaz/graehl/isd/cage/lib
HPF="$USER@$HPCHOST"
browser=${browser:-chrome}
ltd() {
    lt -d "$@"
}
comjam() {
    (
        set +e
        cd ~/t
        mv Jamroot Jamroot.works2; cp Jamroot.svn Jamroot; svn commit -m "$*"; cp Jamroot.works2 Jamroot
    )
}
upjam() {
    (
        set +e
        cd ~/t
        mv Jamroot Jamroot.works2; cp Jamroot.svn Jamroot; svn update; cp Jamroot.works2 Jamroot
    )
}
ld() {
    l -d "$@"
}
flv2aac() {
    local f=${1%.flv}
    set -o pipefail
    local t=`mktemp /tmp/flvatype.XXXXXX`
    local ext
    local codec=copy
    ffmpeg -i "$1" 2>$t || true
    if fgrep -q 'Audio: aac' $t; then
        ext=m4a
    elif fgrep -q 'Audio: mp3' $t; then
        ext=mp3
    else
        ext=wav
        codec=pcm_s16le
    fi
    local mapa
    if [[ $stream ]] ; then
        mapa="-map 0:$stream"
    fi
    if [[ $start ]] ;then
        mapa+=" -ss $start"
    fi
    if [[ $time ]] ; then
        mapa+= " -t $time"
    fi
    local f="$1"
    shift
    ffmpeg -i "$f" -vn $mapa -ac 2 -acodec $codec "$f.$ext" "$@"
}
tohpc() {
    cp2 $HPCHOST "$@"
}
cp2hpc() {
    cp2 $HPCHOST "$@"
}
buildpypy() {
    (set -e
        #http://codespeak.net/pypy/dist/pypy/doc/getting-started-python.html
        opt=jit
        [[ $jit ]] || opt=2
        # mar 2010 opt=2 is default (jit is 32-bit only)
        cd pypy/translator/goal
        CFLAGS="$CFLAGS -m32" ${python:-python2.7} translate.py --opt=$opt -O$opt --cc=gcc targetpypystandalone.py
        ./pypy-c --help
    )
}
safepath() {
    if [[ $ONCYGWIN ]] ; then
        cygpath -m -a "$@"
    else
        abspath "$@"
    fi
}
upa() {
    (pushd ~/t/graehl/util;
        svn update *.sh
    )
    sa
}
comg() {
    (pushd ~/t/graehl/
        svn commit -m "$*"
    )
}
comt() {
    (pushd ~/t/
        svn commit -m "$*"
    )
}
upd() {
    for f; do
        blob_update $f
    done
}
new() {
    for f; do
        blob_new_latest $f
    done
}
ffox() {
    pkill firefox
    find ~/.mozilla \( -name '*lock' -o -name 'places.sqlite*' \) -exec rm {} \;
        firefox "$@"
}
rpdf() {
    cd /tmp
    scp hpc.usc.edu:$1 . && acrord32 `basename $1`
}
alias rot13="tr '[A-Za-z]' '[N-ZA-Mn-za-m]'"
cpdir() {
    local dest
    for dest in "$@"; do true; done
    set -x
    [ -f "$dest" ] && echo file $dest exists && return 1
    mkdir -p "$dest"
    # [ -d "$dest" ] || mkdir "$dest"
    cp "$@"
    set +x
}
jobseq() {
    seq -f %7.0f "$@"
}
lcext() {
    perl -e 'for (@ARGV) { $o=$_; s/(\.[^. ]+)$/lc($1)/e; if ($o ne $_) { print "mv $o $_\n";rename $o,$_ unless $ENV{DEBUG};} }' -- "$@"
}

mkstamps() {
    (
        set -e
        local stamp=${stamp:-`mktemp /tmp/stamp.XXXXXX.tex`}
        stamp=${stamp%.tex}.tex
        mkdir -p "`dirname '$stamp'`"
        local title=${title:-""}
        local papertype=${papertype:-letter}
        local npages=${npages:-5}
        local headpg=${headpg:-R}
        local footpg=${footpg:-L}
        local botmargin=${botmargin:-1.3cm}
        local topmargin=${topmargin:-2cm}
        local leftmargin=${leftmargin:-0.4cm}
        local rightmargin=${rightmargin:-$leftmargin}
        showvars_required papertype npages stamp
        cat > "$stamp" <<EOF
        \documentclass[${papertype}paper,english]{article}
        %,9pt
        \usepackage[T1]{fontenc}
        \usepackage{pslatex} % needed for fonts
        \usepackage[latin1]{inputenc}
        \usepackage{babel}
        \usepackage{fancyhdr}
        %\usepackage{color}
        %\usepackage{transparent}
        \usepackage[left=$leftmargin,top=$botmargin,right=$leftmargin,bottom=$botmargin,${papertype}paper]{geometry}
        \title{$title}
        %\pagestyle{plain}
        \fancyhead{}
        \fancyhead[$headpg]{\thepage}
        \fancyfoot{}
        \fancyfoot[$footpg]{\thepage}
        \renewcommand{\headrulewidth}{0pt}
        \renewcommand{\footrulewidth}{0pt}
        \pagestyle{fancy}
        \begin{document}
        %\maketitle
        %\thispagestyle{empty}
        \begin{center}
        \footnotesize
        %\copyright 2008 Some Institute. Add your copyright message here.
        \end{center}
EOF

for i in `seq 1 $npages`; do
    # echo '\newpage' >> $stamp
    echo '\mbox{} \newpage' \
        >> $stamp
done

echo '\end{document}' >> $stamp

local sbase=${stamp%.tex}
lat2pdf $sbase
echo $sbase.pdf
    ) | tail -n 1
}
pdfnpages() {
    pdftk "$1" dump_data output - | perl -ne 'print "$1\n" if /^NumberOfPages: (.*)/'
}
pdfstamp() {
    if [ -f "$1" ] ; then
        if [ -f "$2" ] ; then
            pdftk "$1" stamp "$2" output "$3"
        else
            cp "$1" "$3"
        fi
    else
        cp "$2" "$3"
    fi
}
pdfoverlay() {
    # pdftk bot stamp top (1 page at a time)
    (set -e
        local bot=$1
        # bot=`abspath $bot`
        shift
        local top=$1
        # top=`abspath $top`
        shift
        local out=${1:--}
        shift

        local npages=`pdfnpages "$top"`

        botpre=`tmpnam`.bot
        toppre=`tmpnam`.top
        allpre=`tmpnam`.all

        showvars_required npages botpre toppre allpre

        pdftk "$bot" burst output "$botpre.%04d.pdf"
        pdftk "$top" burst output "$toppre.%04d.pdf"

        local pages=
        for i in $(seq -f '%04g' 1 $npages); do
            pdfstamp $botpre.$i.pdf $toppre.$i.pdf $allpre.$i.pdf
            pages+=" $allpre.$i.pdf"
        done
        pdftk $pages cat output "$out"
        ls -l "$out"
        pdfnpages "$out"
    )
}
pdfnumber1() {
    (
        set -e
        local in=$1
        local inNOPDF=${in%.PDF}
        if [ "$in" != "$inNOPDF" ] ; then
            lcext "$in"
            in=$inNOPDF.pdf
        fi
        local inpre=${1%.pdf}
        shift
        in=`abspath "$in"`
        require_file "$in"
        local stamp=${stamp:-`tmpnam`}
        local stampf=$(stamp=$stamp npages=$(pdfnpages "$in") mkstamps)
        local out=${out:-$inpre.N.pdf}
        pdfoverlay "$in" "$stampf" "$out"
        rm "$stamp"*
        echo "$out"
    )
}
pdfnumber() {
    forall pdfnumber1 "$@"
}
exists_1() {
    [ -f "$1" ] || [ -d "$1" ]
}
based_paths_r() {
    local p=$1
    shift
    local d
    local r
    while true; do
        d=`dirname $p`
        r=`based_paths $d "$@"`
        [ -L $p ] || break
        exists_1 && break
    done
    echo "$r"
}
based_paths() {
    local base=$1
    [ "$base" ] || $base+=/
    shift
    local f
    local r=
    for f in "$@"; do
        r+=" $base$f"
    done
}

to8() {
    for f in "$@"; do
        iconv -c --verbose -f ${encfrom:-UTF16} -t ${encto:-UTF8} "$f" -o "$f"
    done
}

getcert() {
    local REMHOST=$1
    local REMPORT=${2:-443}
    echo | openssl s_client -connect ${REMHOST}:${REMPORT} 2>&1 |sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
}

pmake() {
    perl Makefile.PL PREFIX=$FIRST_PREFIX
    make && make install
}
unlibz() {
    mv $libzpre/libz.a $libzpre/unlibz.a
}

relibz() {
    mv $libzpre/unlibz.a $libzpre/libz.a
}

export PLOTICUS_PREFABS=$HOME/isd/lib/ploticus/prefabs
HPCHOST=hpc-login2.usc.edu
HPC32=hpc-login1.usc.edu
HPC64=hpc-login2.usc.edu
WFHOME=/lfs/bauhaus/graehl/workflow
WFHPC='~/workflow'


gensym() {
    perl -e '$"=" ";$_="gensym @ARGV";s/\W+/_/g;print;' "$@" `nanotime`
}

currydef() {
    local curryfn=$1
    shift
    eval function $curryfn { "$@" '$*'\; }
}

curry() {
    #fixme: global output variable curryout, since can't print curryout and capture in `` because def would be lost.
    curryout=`gensym $*`
    eval currydef $curryout "$@"
}

pdfcat() {
    gs -sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH -sOutputFile=- "$@"
}

pdfrange() {
    local first=${1:-1}
    local last=${2:-99999999}
    shift
    shift
    verbose2 +++ pdfrange first=$first last=$last "$@"
    gs -sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH -dFirstPage=$((first)) -dLastPage=$last -sOutputFile=- "$@"
}

pdf1() {
    pdfhead -1 "$@"
}

pdfcat1() {
    mapreduce_files pdf1 pdfcat "$@"
}

pdftail() {
    local from=${from:--10}
    if [ "$from" -lt 0 ] ; then
        from=$((`nlines "$@"`-$from))
    fi
    pdfrange $from 99999999 "$@"
}

#range: 1-based double-closed interval e.g. (1,2) is first 2 lines
range() {
    local from=${1:-0}
    local to=${2:-99999999}
    shift
    shift
    perl -e 'require "$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl";$"=" ";' \
        -e '$F=shift;$T=shift;&argvz;$n=0;while(<>) { ++$n;;print if $n>=$F && $n<=$T }' \
        $from $to "$@"
    if false ; then
        if [ "$from" -lt 0 ] ; then
            tail $from "$@" | head -$to
        else
            head -$to "$@" | tail +$from
        fi
    fi
}

lastpr() {
    perl -ne 'while (/(P=\S+ R=\S+)/g) { $first=$1 unless $first;$last=$1};END{print "[corpus ",($first eq $last?$last:"$last (i=0: $first)"),"]\n"}' "$@"
}

nthpr() {
    perl -ne '$n=shift;while (/(P=\S+ R=\S+)/g) { $first=$1 unless $first;$last=$1;last if --$n==0;};END{print "[corpus ",($first eq $last?$last:"$last (i=0: $first)"),"]\n"}' "$@"
}
bigclm() {
    perl -i~ -pe ' s/lw/big/g if /clm-lr/' *.sh
}
scts() {
    local l=${1:-ara}
    grep BLEU detok $l-*/$l-decode-iter-*/ibmbleu.out | bleulr
}
mvpre() {
    local pre=$1
    shift
    for f in "$@"; do
        mv $f `dirname $f`/$pre.`basename $f`
    done
}
ofcom() {
    pushd ~/t/graehl/gextract/optfunc
    gcom "$@"
}
obut0() {
    rm -rf 1btn0000;. master.sh; rm -rf *0001;casub 1btn0000
}
but0() {
    for f in *1btn0000; do
        echo $f
        sleep 3
        casub $f
    done
}
chimira0() {
    local l=chi
    local g=$1
    echo genre=$g
    if [ "$g" ] ; then
        local m=$l-mira0000
        exh rm -rf $m
        . mira.sh $g-tune
        casub $m
    fi
}

pwdh() {
    local d=`pwd`
    local e=${d#$HOME/}
    if [ $d != $e ] ; then
        echo '~/'$e
    else
        e=${d#$WFHOME/}
        if [ $d != $e ] ; then
            echo "$WFHPC/$e"
        else
            echo $d
        fi
    fi
}
lnh() {
    ssh $HPCHOST "cd `pwdh` && ln -s $*" && ln -s "$@"
}
rmh() {
    ssh $HPCHOST "cd `pwdh` && rm $*" && rm "$@"
}
exh() {
    ssh $HPCHOST "cd `pwdh` && $*" && $*
}
double1() {
    catz "$@" "$@" > 2x."$1"
}
doublemany() {
    for f in "$@"; do
        double1 $f
    done
}

doubleinplace() {
    local nano=`nanotime`
    local suffix="$$$nano"
    for f in "$@"; do
        mv $f $f.$suffix
        cat $f.$suffix $f.$suffix > $f && rm $f.$suffix
    done
}

split() {
    cat "$@" | tr ' ' '\n'
}


cdr()
{
    cd $(realpath "$@")
}
cdw()
{
    cd $WFHOME/workflow/tune
}
mirasums() {
    for d in ${*:-.}; do
        find $d -name '*mira0*' -print -exec mira-summary.sh {} \;
    done
}
miras() {
    local a=""
    for d in ${*:-.}; do
        a="$a $d/*mira*"
    done
    miradirs $a
}
miradirs() {
    for d in ${*:-*mira000}; do
        if [ -d $d ] ; then
            echo -n $d
            if grep -q /home/nlg-02/data07/eng/agile-p4/lm $d/record.txt; then
                echo -n " AGILE LM"
            fi
            echo
            mira-summary.sh $d

            echo
        fi
    done
}
ln0() {
    mkdir -p $2
    pushd $2
    for f in ../$1/*-*0000; do ln -s $f .; done
    [ "$3" ] && rm *-$3*0000
    ls
    popd
}

cpsh() {
    mkdir -p $2
    cp $1/*.sh $2
    ssh $HPCHOST "cd `pwdh` && mkdir -p $2"
}
cprules() {
    cpsh $1 $2
    pushd $2
    ln -s ../$1/*{xrsdb0000,rules0000} .
    popd
}
srescue() {
    find "$@" -name '*.dag.rescue'
}
drescue() {
    for f in `srescue "$@"`; do
        diff $f $f.rescue
    done
}
rmrescue() {
    find "$@" -name '*.dag.rescue.*' -exec rm {} \;
}
rescue() {
    for f in `srescue "$@"`; do
        pushd `dirname $f`
        vds-submit-dag `basename $f`
        popd
    done
}
csub() {
    pushd `dirname $1`
    vds-submit-dag `basename $1`
    popd
}
casubr() {
    casub `ls -dtr *00* | tail -1` "$@"
}
kajobs() {
    for d in $1/*0000; do
        echo killing: $d
        kjobs $d
    done
}
kalljobs() {
    for d in "$@"; do
        kajobs $d
    done
}
progress() {
    [ "$3" ] && pushd $3
    local jd=*decode-iter-$2-${1}0000
    rm -rf $jd
    . progress.sh $1 $2
    casub $jd
    [ "$3" ] && popd
    true
}
cprogress() {
    [ "$3" ] && pushd $3
    local jd=chi-decode-$2-${1}0000
    exh rm -rf $jd
    . progress.sh $1 $2
    casub $jd
    [ "$3" ] && popd
    true
}

[ "$ONHPC" ] && alias qme="qstat -u graehl"
alias gpi="grid-proxy-init -valid 99999:00"
alias 1but="cd 1btn0000 && vds-submit-dag 1button.dag; cd .."
alias rm0="rm -rf *000?"
alias lsd="ls -al | egrep '^d'"
releasevariant="release debug-symbols=on --allocator=tbb"
variant=$releasevariant
qsi2() {
    local n=${1:-1}
    shift
    qsinodes=$n qsippn=2 qsubi -X "$@"
}
#variant=""
#
DTOOLS=$HOME/isd/decode-tools-trunk/
sbmtargs="$variant toolset=gcc -j4 --prefix=$DTOOLS"
alias pjam="bjam --prefix=$FIRST_PREFIX -j4"
alias sjam="bjam $sbmtargs"
buildpipe() {
    mkdir -p $DTOOLS
    pushd ~/t;svn update;bjam $sbmtargs install-pipeline ;popd
    pushd $DTOOLS
    ln -sf . x86_64;ln -sf . tbb
    cp $FIRST_PREFIX/lib/libtbb{,malloc}.* lib
    popd
}
buildxrs() {
    pushd ~/t;svn update;bjam $sbmtargs utilities//install ;popd
}
alias grepc="$(which grep) --color -n"
buildgraehl() {
    local d=$1
    local v=$2
    (set -e
        pushd $GRAEHLSRC/$1
        #export GRAEHL=$GRAEHLSRC
        #export TRUNK=$GRAEHLSRC
        #export SHARED=$TRUNK/shared
        export BOOST=$BOOST_INCLUDE
        [ "$clean" ] && make clean
        [ "$noclean" ] || make clean
        set -x
        #LDFLAGS+="-ldl -pthread -lpthread -L$FIRST_PREFIX/lib"
        #LDFLAGS+="-ldl -pthread -lpthread -L$FIRST_PREFIX/lib"
        make CMDCXXFLAGS+="-I$FIRST_PREFIX/include" BOOST_SUFFIX=mt -j$MAKEPROC
        make CMDCXXFLAGS+="-I$FIRST_PREFIX/include" BOOST_SUFFIX=mt install
        set +x
        popd
        if [ "$v" ] ; then
            pushd $FIRST_PREFIX/bin
            cp carmel carmel.$v
            cp carmel.static carmel.$v
            popd
        fi
    )
}
buildcar() {
    buildgraehl carmel "$@"
    # pushd ~/t/graehl/carmel
    # [ "$noclean" ] || make clean
    # set -x
    # make CMDCXXFLAGS+="-I$FIRST_PREFIX/include" LDFLAGS+="-ldl -pthread -lpthread -L$FIRST_PREFIX/lib" BOOST_SUFFIX= -j$MAKEPROC
    # make CMDCXXFLAGS+="-I$FIRST_PREFIX/include" LDFLAGS+="-ldl -pthread -lpthread -L$FIRST_PREFIX/lib" BOOST_SUFFIX= install
    # set +x
    # popd
    # if [ "$1" ] ; then
    # pushd $FIRST_PREFIX/bin
    # cp carmel carmel.$1
    # cp carmel.static carmel.$1
    # popd
    # fi
}
buildfem() {
    buildgraehl forest-em
}
buildboost() {(
        set -e
        local withouts
        [ "$without" ] && withouts="--without-mpi --without-python --without-wave"
        [ "$noboot" ] || ./bootstrap.sh --prefix=$FIRST_PREFIX
        ./bjam --build-type=complete --layout=tagged --prefix=$FIRST_PREFIX $withouts --runtime-debugging=on -j$MAKEPROC install
        # ./bjam --threading=multi --runtime-link=static,shared --runtime-debugging=on --variant=debug --layout=tagged --prefix=$FIRST_PREFIX $withouts install -j4
        # ./bjam --layout=system --threading=multi --runtime-link=static,shared --prefix=$FIRST_PREFIX $withouts install -j4
        )}

PUZZLEBASE=~/puzzle
#PUZZLETO='graehl@isi.edu'
MYEMAIL='graehl@gmail.com'
export EMAIL=$MYEMAIL
PUZZLETO='1051962371@facebook.com'
#PUZZLETO=$MYEMAIL
function testp()
{
    pw=`pwd`
    ~/puzzle/test.pl ./`basename $pw` test.expect
}

function ocb()
{
    OCAMLLIB=/usr/lib/ocaml /usr/bin/ocamlbrowser &
}
function puzzle()
{
    (
        set -e
        require_dir $PUZZLEBASE
        puzzle=$1
        puzzledir=$PUZZLEBASE/$puzzle
        pushd $puzzledir
        if make || [ ! -f Makefile ] ; then
            local tar=$puzzle.tar.gz
            tar czf $tar `ls Makefile $puzzle $puzzle.{ml,py,cc,cpp,c} 2>/dev/null`
            tar tzf $tar
            set -x
            [ "$dryrun" ] || EMAIL=$MYEMAIL mutt -s $puzzle -a `realpath $tar` $PUZZLETO -b $MYEMAIL < /dev/null
            set +x
        fi
        popd
    )
}

#SCALA=c:/Users/graehl/.netbeans/6.7rc2/scala/scala-2.7.3.final/lib
SCALABASE=~/puzzle/scala
#SCALABASE=c:/Users/graehl/Documents/NetBeansProjects
function spuzzle()
{
    (
        set -e
        set -x
        puz=$1
        dist=$SCALABASE/$1
        # require_dir $dist
        cd $dist
        slib=scala-library.jar
        plib=$puz.jar
        src=$puz.scala
        bin=$puz
        tar=$puz.tar.gz
        extra=
        if [ $puz = breathalyzer ] ; then
            extra=words
            maybe_cp $SCALA_PROJECTS/$puz/twl06.txt $extra || true
        fi
        chmod +x $bin
        all="$bin $slib $src $extra"
        if [ "$nomanifest" ] ; then
            all="$all `ls *.class`"
        else
            all="$all $plib"
        fi
        # [ "$SCALA_HOME" ] && scala-jar.sh $1
        pwd
        require_files $all
        tar czf $tar $all
        tar tzf $tar
        set -x
        [ "$dryrun" ] || EMAIL=$MYEMAIL mutt -s $puz -a `realpath $tar` $PUZZLETO -b $MYEMAIL < /dev/null
        set +x
    )
}
rgrep()
{
    local a=$1
    shift
    if [ "$*" ] ; then
        find "$@" -exec egrep "$a" {} \; -print
    else
        find . -exec egrep "$a" {} \; -print
    fi
}

function frgrep()
{
    local a=$1
    shift
    find . -exec fgrep "$@" "$a" {} \; -print
}

function findpie ()
{
    local pattern=$1
    shift
    if [ "$2" ] ; then
        local name="-name $2"
        shift
    fi
    echo "find . $name $* -exec perl -p -i -e $pattern {} \;"
}


other() {
    local f=${1:?'returns $otherdir/`basename $1`'}
    showvars_required otherdir
    echo $otherdir/`basename $f`
}

diffother() {
    local f=$1
    shift
    local o=`other $f`
    require_files $f $o
    diff -u "$@" $f $o
}

other1() {
    local f=${1:?'returns $other1dir/$1 with $other1dir in place of the first part of $1'}
    showvars_required other1dir
    other1=$other1 perl -e 'for(@ARGV) { s|^/?[^/]+/|$ENV{other1}/|; print "$_\n"}' "$@"
}

diffother1() {
    local f=$1
    shift
    local o=`other1 $f`
    require_files $f $o
    diff -u "$@" $f $o
}

lastlog() {
    "$@" 2>&1 | tee ~/tmp/lastlog
}

msum() {
    local wh=$1
    shift
    mkdir -p sum
    local out=$wh
    [ "$*" ] && out=$wh.`filename_from "$@"`
    showvars wh out
    echo ~/t/utilities/summarize_multipass.pl -l $wh.log data/$wh.nbest -csv sum/$out.csv "$@"
    ~/t/utilities/summarize_multipass.pl -l $wh.log data/$wh.nbest -csv sum/$out.csv "$@" 2>&1 | tee sum/$out.sum
}

function build_carmel
{
    cd $SBMT_TRUNK/graehl/carmel

    nproc_default=3
    [ "$h" = cage ] && nproc_default=7
    nproc=${nproc:-$nproc_default}
    local archf
    local args
    args=""
    [ "$install" ] && $args="install"
    local install=${install:-$FIRST_PREFIX}
    [ -d "$install" ] || install=$HOME/isd/$install
    buildsub=${buildsub:-$ARCH}
    [ "$linux32" -o "$buildsub" = linux ] && archf="-m32 -march=i686"
    BUILDSUB=$buildsub INSTALL_PREFIX=$install ARCH_FLAGS=$archf make -j $nproc $args "$@"
}


function sbmt_test
{
    gdb --args $SBMT_TEST
}

function hoard()
{
    export LD_PRELOAD="$FIRST_PREFIX/lib/libhoard.so"
}

function nohoard()
{
    export LD_PRELOAD=
}


perlf() {
    perldoc -f "$@" | cat
}

alias gc=gnuclientw

function callgrind() {
    local exe=${1:?callgrind program args. env cache=1 branch=1 cgf=outfilename}
    #dumpbefore dumpafter zerobefore = fn-name, or dumpevery=1000000
    local base=`basename $1`
    shift
    local cgf=${cgf:-/tmp/callgrind.$base.`shortstamp`}
    echo $cgf
    local cachearg
    local brancharg
    if [[ $cache ]] ; then
        cachearg=--cache-sim=yes
    fi
    if [[ $branch ]] ; then
        brancharg=--branch-sim=yes
    fi
    valgrind --tool=callgrind $cachearg $brancharg --callgrind-out-file=$cgf --dump-instr=yes -- $exe "$@"
    #&& /Applications/qcachegrind.app $cgf
    echo $cgf
    tail -2 $cgf
}
VGARGS="--num-callers=16 --leak-resolution=high --suppressions=$HOME/u/valgrind.supp"
function vg() {
    local darg=
    local varg=
    local suparg=
    if [[ $gdb ]] ; then
        gdb --args "$@"
        return
    fi
    [ "$debug" ] && darg="--db-attach=yes"
    [ "$vgdb" ] && varg="--vgdb=full"
    [ "$sup" ] && suparg="--gen-suppressions=yes"
    local lc=
    if [ "$noleak" ] ; then
        lc=no
    else
        lc=yes
    fi
    if [ "$reach" ] ; then
        lc=full
        reacharg="--show-reachable=yes"
    fi
    GLIBCXX_FORCE_NEW=1 valgrind $darg $varg $suparg --leak-check=$lc $reacharg --tool=memcheck $VGARGS "$@"
}
vgf() {
    vg "$@"
    # | head --bytes=${maxvgf:-9999}
}
#--show-reachable=yes
#alias vgfast="GLIBCXX_FORCE_NEW=1 valgrind --db-attach=yes --leak-check=yes --tool=addrcheck $VGARGS"
alias vgfast=vg
alias massif="valgrind --tool=massif --depth=5"

gpp() {
    g++ -x c++ -E "$@"
}
alias jane="ssh 3jane.dyndns.org -l jonathan"
alias shpc="ssh $HPCHOST -l graehl -X"
alias sh2="ssh $HPC64 -l graehl -X"
alias snlg="ssh nlg0.isi.edu -l graehl"

alias rs="rsync --size-only -Lptave ssh"

function hscp
{
    if [ $# = 1 ] ; then
        from=$1
        to=.
    else
        COUNTER=1
        from=''
        while [ $COUNTER -lt $# ]; do
            echo $from
            echo ${!COUNTER}

            from="$from ${!COUNTER}"
            let COUNTER=COUNTER+1
        done
        to=${!#}
    fi
    echo scp \"$from\" $shpchost:$to
    scp -r $from $shpchost:$to
}

function hrscp
{
    if [ $# = 1 ] ; then
        from=$1
        to=.
    else
        COUNTER=1
        from=''
        while [ $COUNTER -lt $# ]; do
            echo $from
            echo ${!COUNTER}

            from="$from ${!COUNTER}"
            let COUNTER=COUNTER+1
        done
        to=${!#}
    fi
    echo scp \"$shpchost:$from\" $to
    scp -r $shpchost:$from $to
}

function hrs
{
    if [ $# = 1 ] ; then
        from=$1
        to=.
    else
        COUNTER=1
        from=''
        while [ $COUNTER -lt $# ]; do
            echo $from
            echo ${!COUNTER}

            from="$from ${!COUNTER}"
            let COUNTER=COUNTER+1
        done
        to=${!#}
    fi
    echo rs \"$from\" $shpchost:$to
    rs $from $shpchost:$to
}


JOBTIME=${JOBTIME:-23:50:00}
qg() {
    qstat -au graehl
}
qsd() {
    qsub -q default -I -l walltime=$JOBTIME,pmem=4000mb "$@"
}


function xe
{
    xemacs "$@" &
    disown
}

function xt
{
    xterm -sb -ls -fn fixed "$@" &
    disown
}
HOST=${HOST:-`hostname`}
if [ "$HOST" = twiki ] ; then
    alias sudo=/local/bin/sudo
fi

function rebin
{
    pdq ~/bin
    for f in ../dev/tt/scripts/* ; do ln -s $f . ; done
    popd
}
alias pd=pdq
getattr() {
    attr=$1
    shift
    perl -ne '/\Q'"$attr"'\E=\{\{\{([^}]+)\}\}\}/ or next;print "$ARGV:" if ($ARGV ne '-'); print $.,": ",$1,"\n";close ARGV if eof' "$@"
}
#,qsh.pl,checkjobs.pl
alias commh="pdq ~/isd/hints;cvs update && comml;popd"
alias sb=". ~/.bashrc"
alias sa=". ~/u/aliases.sh"
alias sbl=". ~/u/bashlib.sh"
alias sl=". ~/local.sh"
export PBSQUEUE=isi

cp_sbmt() {
    local to=$1
    local sub=$2
    [ "$sub" ] && sub="/$sub"
    if [ "$to" ] ; then
        echo2 copying trunk to $to
        svn cp -m "trunk->$to" $SBMT_SVNREPO/trunk$sub $SBMT_SVNREPO/$to
    fi
}

tag_module() {
    local ver=$1
    local module=${2:-mini_decoder}
    showvars_required ver module
    if [ "$ver" ] ; then
        local to=tags/$module/version-$ver
        if [ "$force" ] ; then
            svn rm -m "redo $to" $SBMT_SVNREPO/$to
        fi
        cp_sbmt $to $3
    fi
}

tag_fem() {
    local ver=$1
    tag_module $ver forest-em graehl
}

tag_carmel() {
    local ver=$1
    tag_module $ver carmel graehl
}

tag_mini() {
    tag_module "$@"
}

set -b
shopt -s checkwinsize
shopt -s cdspell

hpcquota() {
    ssh almaak.usc.edu /opt/SUNWsamfs/bin/squota -U graehl
}


export LESS='-d-e-F-X-R'


function lastbool
{
    echo $?
}


greph() {
    fgrep "$@" $HISTORYOLD
}

export IGNOREEOF=10

#alias hrssd="hrs ~/dev/syntax-decoder/src dev/syntax-decoder"
rgrep()
{
    a=$1
    shift
    find . \( -type d -and -name .svn -and -prune \) -o -exec egrep -n -H "$@" "$a" {} \; -print
}
frgrep()
{
    a=$1
    shift
    find . \( -type d -and -name .svn -and -prune \) -o -exec fgrep -n -H "$@" "$a" {} \; -print
}
dos2unix()
{
    perl -p -i~ -e 'y/\r//d' "$@"
}
isdos()
{
    perl -e 'while(<>) { if (y/\r/\r/) { print $ARGV,"\n"; last; } }' "$@"
}
psgn1()
{
    psgn $1 | head -1
}
psgn()
{
    psg $1 | awk '{print $2}'
}
openssl=/usr/local/ssl/bin/openssl
certauth=/web/conf/ssl.crt/ca.crt
function sslverify()
{
    $openssl verify -CAfile $certauth "$@"
}
function sslx509()
{
    $openssl x509 -text -noout -in "$@"
}
function ssltelnet()
{
    $openssl s_client -connect "$@"
}

function m()
{
    clear
    make "$@" 2>&1 | more
}
function ll ()
{
    /bin/ls -lA "$@"
}
function lt ()
{
    /bin/ls -lrtA "$@"
}
function l ()
{
    /bin/ls -ls -A "$@"
}
function c ()
{
    cd "$@"
}
function s ()
{
    su - "$@"
}
function f ()
{
    find / -fstype local -name "$@"
}
function e ()
{
    emacs "$@"
}
function wgetr ()
{
    wget -r -np -nH "$@"
}
function cleanr ()
{
    find . -name '*~' -exec rm {} \;
}
#function perl1 {
# local libgraehl=~/isd/hints/libgraehl.pl
# perl -e 'require "'$libgraehl'";' "$@" -e ';print "\n";'
#}
alias perl1="perl -e 'require \"\$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl\";\$\"=\" \";' -e "
alias perl1p="perl -e 'require \"\$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl\";\$\"=\" \";END{println();}' -e "
alias perl1c="perl -ne 'require \"\$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl\";\$\"=\" \";END{while((\$k,\$v)=each \%c) { print qq{\$k: \$v };println();}' -e "
alias clean="rm *~"
alias nitro="ssh -1 -l graehl nitro.isi.edu"
alias hpc="ssh -1 -l graehl $HPCHOST"
alias nlg0="ssh -1 -l graehl nlg0.isi.edu"
alias more=less
alias h="history 25"
alias jo="jobs -l"

alias cpup="cp -vRdpu"
# alias hem="pdq ~/dev/tt; hscp addfield.pl forest-em-button.sh dev/tt; popd"

# alias ls="/bin/ls"
RCFILES=~/isd/hints/{.bashrc,aliases.sh,bloblib.sh,bashlib.sh,add_paths.sh,inpy,dir_patt.py,.emacs}
alias hb="scp $RCFILES graehl@$HPCHOST:isd/hints"
alias fb="scp $RCFILES graehl@false.isi.edu:isd/hints"
alias dp=`/usr/bin/which d 2>/dev/null`
alias d="d -c-"
sd="~/dev/syntax-decoder/src"
sds=$sd/../scripts
alias hsds="coml $sds;hup $sds"
e() {
    local host=$1
    shift
    ssh -t $host -l graehl <<EOF
"$@"
EOF
}
ehost() {
    local p=`homepwd`
    local host=$1
    shift
    ssh -t $host -l graehl <<EOF
cd $p
"$@"
EOF
    #"/bin/bash"' --login -c "'"$*"'"'
}

enlg() {
    ehost enlg "$@"
}
function homepwd
{
    perl -e '$_=`pwd`;s|^/cygdrive/z|~|;print'
}
eerdos() {
    local p=`homepwd`
    ssh -t erdos.isi.edu -l graehl <<EOF
cd $p
"$@"
EOF
}
estrontium() {
    local p=`homepwd`
    ssh -t strontium.isi.edu -l graehl <<EOF
cd $p
"$@"
EOF
}
ercage() {
    local p=`homepwd`
    # ssh -t cage.isi.edu -l graehl <<EOF
    rsh -l graehl cage bash <<EOF
cd $p
"$@"
EOF
}
egrieg() {
    local p=`homepwd`
    ssh -t grieg.isi.edu -l graehl <<EOF
cd $p
"$@"
EOF
}
ecage() {
    local p=`homepwd`
    ssh -t cage.isi.edu -l graehl <<EOF
cd $p
$*
EOF
}
epro() {
    local p=`homepwd`
    ssh -t prokofiev.isi.edu -l graehl <<EOF
cd $p
$*
EOF
}
pro() {
    ssh prokofiev.isi.edu -l graehl
}
dhelp() {
    decoder --help 2>&1 | grep "$@"
}

grepnpb() {
    catz "$@" | egrep '^NPB\(x0:NN\) -> x0 \#'
}
perfnbest() {
    perfs "$@" | grep 'best derivations in '
}
tarxzf() {
    catz "$@" | tar xvf -
}
wxzf() {
    local b=`basename "$@"`
    wget "$@"
    tarxzf $b
}


pdq() {
    local err=`mktemp /tmp/pdq.XXXXXX`
    pushd "$@" 2>$err || cat $err 1>&2
    rm -f $err
}
pawd() {
    perl1p "print &abspath_from qw(. . 1)"
}
comsd() {
    com ~/dev/syntax-decoder/"$@"
}
comtt() {
    coml ~/dev/shared
    coml ~/dev/tt
    coml ~/dev/xrsmodels
}
comh() {
    coml ~/isd/hints
}
comxrs() {
    coml ~/dev/xrsmodels
    coml ~/isd/hints
    coml ~/dev/shared
}
comdec() {
    comh
    comsd
    comsd
    comxrs
}
comall() {
    comh
    comsd
    comtt
}
redodecb() {
    redo decoder/decoder-bin
}
redodec() {
    redo bashlib
    redo libgraehl
    redo decoder
}
rdec() {
    comdec
    ehpc redodec
}
rdecs() {
    coml ~/dev/syntax-decoder/scripts
    ehpc redo decoder
}
rdecb() {
    coml ~/dev/syntax-decoder/src
    ehpc redo decoder/decoder-bin
}
rtt() {
    enlg comtt
    ehpc redo forest-em
}
alias sl=". ~/isd/hints/bashlib.sh"
alias hh="comh;huh"
if [ $HOST = TRUE ] ; then
    alias startxwin="/usr/X11R6/bin/startxwin.sh"
    alias rr="ssh nlg0 rdec"
    alias rdb="ssh nlg0 rdecb"
    alias rrs="ssh nlg0 rdecs"
fi

cb() {
    pushd $BLOBS/$1/unstable
}

allscripts="bashlib libgraehl qsh decoder"
allblobs="bashlib libgraehl qsh decoder/decoder-bin decoder rule-prep/identity-ascii-xrs rule-prep/add-xrs-models"
refresh_all() {
    (
        set -e
        for f in $allblobs; do redo $f latest ; done
    )
}
refresh_scripts() {
    (
        set -e
        for f in $allscripts; do redo $f latest ; done
    )
}
new_all() {
    (
        set -e
        for f in $allblobs; do blob_new_latest $f ; done
    )
}

xscripts() {
    find $1 -name '*.pl*' -exec chmod +x {} \;
    find $1 -name '*.sh*' -exec chmod +x {} \;
}

if [ "$ONCYGWIN" ] ; then
    sshwrap() {
        local which=$1
        shift
        /usr/bin/$which -i c:/cache/.ssh/id_dsa "$@"
    }

    wssh() {
        sshwrap ssh "$@"
    }

    wscp() {
        sshwrap scp "$@"
    }

    cscp() {
        scp -2 $1 graehl@cage.isi.edu:/users/graehl/$2
    }
fi


function dvi2ps
{
    papertype=${papertype:-letter}
    local b=${1%.dvi}
    local d=`dirname $1`
    local b=`basename $1`
    pushd $d
    b=${b%.dvi}
    dvips -t $papertype -o $b.ps $b.dvi
    popd
}

function latrm
{
    rm -f *-qtree.aux $1.aux $1.dvi $1.bbl $1.blg $1.log
}
cplatex=~/texmf/pst-qtree.tex
[ -f $cplatex ] || cplatex=
function latp
{
    local d=`dirname $1`
    local b=`basename $1`
    pushd $d

    [ "$cplatex" ] && cp $cplatex .
    latrm $b
    local i
    for i in `seq 1 ${latn:=1}`; do
        if [ "$batchmode" ] ; then
            latex "\batchmode\input $b.tex"
        else
            latex $b.tex
        fi
    done
    [ "$cplatex" -a -f "$cplatex" ] && rm $cplatex
    popd
}
function latq
{
    local f=${1%.tex}
    latp $f && dvi2pdf $f
    latrm $f
}
function dvi2pdf
{
    local d=`dirname $1`
    local b=`basename $1`
    pushd $d
    b=${b%.dvi}
    dvi2ps $b
    ps2pdf $b.ps $b.pdf || true
    popd
}
function lat2pdf
{
    latq "$@"
}
function lat2pdf_landscape
{
    papertype=landscape lat2pdf $1
}

function vizalign
{
    echo2 vizalign "$@"
    local f=$1
    shift
    local n=`nlines "$f.a"`
    if [ "$n" = 0 ] ; then
        warn "no lines to vizalign in $f.a"
    fi
    local lang=${lang:-chi}
    # if [ -f $f.info ] ; then
    # viz-tree-string-pair.pl -t -l $lang -i $f -a $f.info
    # else
    quietly viz-tree-string-pair.pl -c "$f" -t -l $lang -i "$f" "$@"
    # fi
    quietly lat2pdf_landscape $f
}
function lat
{
    papertype=${papertype:-letter}
    latp $1 && bibtex $1 && latex $1.tex && ((latex $1.tex && dvips -t $papertype -o $1.ps $1.dvi) 2>&1 | tee log.lat.$1)
    ps2pdf $1.ps $1.pdf
}

g1() {
    local ccmd="g++"
    local linkcmd="g++"
    local archarg=
    if [[ $OS = Darwin ]] ; then
        ccmd="g++"
        linkcmd="g++"
        archarg="-arch x86_64"
        macboost
    fi
    local program_options_lib="-lboost_program_options$BOOST_SUFFIX -lboost_system$BOOST_SUFFIX"
    local source=$1
    shift
    [ -f "$source" ] || cd $GRAEHL_INCLUDE/graehl/shared
    pwd
    ls $source
    local out=${OUT:-$source.`filename_from $HOST "$*"`}
    (
        set -e
        local flags="$CXXFLAGS $MOREFLAGS -I$GRAEHL_INCLUDE -I$BOOST_INCLUDE -DGRAEHL_G1_MAIN"
        showvars_optional ARGS MOREFLAGS flags
        if ! [ "$OPT" ] ; then
            flags="$flags -O0"
        fi
        #$ccmd $archarg $MOREFLAGS -ggdb -fno-inline-functions -x c++ -DDEBUG -DGRAEHL__SINGLE_MAIN $flags "$@" $source -c -o $out.o
        #$linkcmd $archarg $LDFLAGS $out.o -o $out $program_options_lib 2>/tmp/g1.ld.log
        $ccmd $program_options_lib -L$BOOST_LIB $MOREFLAGS $archarg -g -fno-inline-functions -x c++ -DDEBUG -DGRAEHL__SINGLE_MAIN $flags "$@" $source -o $out
        #$archarg
        LD_RUN_PATH=$BOOST_LIB $gdb ./$out $ARGS
        if [[ $cleanup = 1 ]] ; then
            rm -f $out.o $out
        fi
        set +e
    )
}
euler() {
    source=${source:-euler$1.cpp}
    local flags="$CXXFLAGS $MOREFLAGS -I$BOOST_INCLUDE -DGRAEHL__SINGLE_MAIN"
    local out=${source%.cpp}
    g++ -O euler$1.cpp $flags -o $out && echo running $out ... && ./$out
}
gtest() {
    MOREFLAGS="$GCPPFLAGS" OUT=$1.test ARGS="--catch_system_errors=no" g1 "$@" -DGRAEHL_TEST -DINCLUDED_TEST -ffast-math -lboost_unit_test_framework${BOOST_SUFFIX:-mt} -lboost_random${BOOST_SUFFIX:-mt}
}
gsample() {
    local s=$1
    shift
    OUT=$s.sample ARGS=""$@"" g1 $s -DGRAEHL_SAMPLE
}


function conf
{
    ./configure $CONFIG "$@"
}

function myconfig
{
    local C=$CONFIGBOOST
    [ "$noboost" ] && C=$CONFIG
    showvars_required C BUILDDIR LD_LIBRARY_PATH
    [ -x configure ] || ./bootstrap
    [ "$distclean" ] && [ "$BUILDDIR" ] && [ -d $BUILDDIR ] && rm -rf $BUILDDIR
    mkdir -p $BUILDDIR
    pushd $BUILDDIR
    [ "$reconfig" ] && rm -f Makefile
    echo ../configure $C $myconfigargs "$@"
    [ -f Makefile ] || ../configure $C $myconfigargs "$@"
    popd
}

function doconfig
{
    noboost=1 myconfig
}

function dobuild
{
    if doconfig "$@" ; then
        pushd $BUILDIR && make && make install
        popd
    fi
}

makesrilm_c() {
    make OPTION=_c World
}

set_i686() {
    set_build i686
}
set_i686_debug() {
    set_build i686 -O0
}

upt()
{
    pushd ~/t
    svn update
    popd
}

mlm=~/t/utilities/make.lm.sh
[ -f $mlm ] && . $mlm

cwhich() {
    l `which "$@"`
    cat `which "$@"`
}

vgx() {
    (
        #lennonbin
        local outarg smlarg out vgprog dbarg leakcheck
        [ "$out" ] && outarg="--log-file-exactly=$out"
        [ "$xml" ] && xmlarg="--xml=yes"
        [ "$xml" ] && out=${out:-valgrind.xml}
        vgprog=valgrind
        [ "$valk" ] && vgprog=valkyrie
        [ "$valk" ] || leakcheck="--leak-check=yes --tool=memcheck"
        [ "$debug" ] && dbarg="--db-attach=yes"
        GLIBCXX_FORCE_NEW=1 $vgprog $xmlarg $leakcheck $dbarg $VGARGS $outarg "$@"
        [ "$xml" ] && valkyrie --view-log $out
    )
    #--show-reachable=yes
}

unshuffle() {
    perl -e 'while(<>){print;$_=<>;die unless $_;print STDERR $_}' "$@"
}

ngr() {
    local lm=$1
    shift
    ngram -ppl - -debug 1 -lm $lm "$@"
}


compare_length() {
    extract-field.pl -print -f text-length,foreign-length "$@" | summarize_num.pl
}

ogetbleu() {
    local log=${log:-bleu.`filename_from $1`}
    local nbest=${2:-1.NBEST.err}
    opt-nbest.out -maxiter 0 -init $1 -nos 0 -inputfile $nbest -keepInitsZero 2>&1 | tee $log
}


hypfromdata() {
    perl -e '$whole=$ENV{whole};$ns=$ENV{nsents};$ns=999999999 unless defined $ns;while(<>) { if (/^(\d+) -1 \# \# (.*) \# \#/) { if ($l ne $1) { print ($whole ? $_ : "$2\n");last unless $n++ < $ns; $l=$1; } } } ' "$@"
}

stripbracespace() {
    perl -pe 's/^\s+([{}])/$1/' "$@"
}

# input is blank-line separated paragraphs. print first nlines of first nsents paragraphs. blank=1 -> print separating newline
firstlines() {
    perl -e '$blank=$ENV{blank};$ns=$ENV{nsents};$ns=999999999 unless defined $ns;$max=1;$max=$ENV{nlines} if exists $ENV{nlines};$nl=0;while(<>) { print if $nl++<$max; if (/^$/) {$nl=0;print "\n" if $blank;last unless $n++ < $ns;} }' "$@"
}

stripunknown() {
    perl -pe 's/\([A-Z]+ \@UNKNOWN\@\) //g' "$@"
}

fixochbraces() {
    # perl -ne '
    # s/^\s+\{/ \{\n/ if ($lastcond);
    # s/\s+$//;
    # print;
    # $lastcond=/^\s+(if|for|do)/;
    # print "\n" unless $lastcond;
    # END {
    # print "\n" if $lastcond;
    # }
    # ' "$@"
    perl -e '$/=undef;$_=<>;print $_
$ws=q{[ \t]};
$kw=q{(?:if|for|while|else)};
$notcomment=q{(?:[^/\n]|/(?=[^/\n]))};
s#(\b$kw\b$notcomment+)$ws*(?:(//[^\n]*\n)|\n)$ws*\{$ws*#$1 { $2#gs;
s/}\s*else/} else/gs;
print;
# @lines=split "\n";
# for (@lines) {
# s#(\b$kw\b$notcomment*)(//.*?)\s*\{\s*$#$1 { $2#;
# print "$_\n";
# }
' "$@"
    #s|(\b$kw\b$notcomment*)(//[^\n]*)(\{$ws*)\n|$1$3\n$2\n|gs;

}


tviz() {
    (
        set -e
        captarg=
        work=${work:-tviz}
        if [ "$caption" ] ; then
            captionfile=`mktemp /tmp/caption.XXXXXXXX`
            echo "$caption" > $captionfile
            captarg="-c $captionfile"
        fi
        escapetree | treeviz -s -p 'graph [fontsize=12,labelfontsize=10,center=0]; node [fontsize=10,height=.06,margin=".04,.02",nodesep=.02,shape=none] ;'"$*" $captarg > $work.dot
        require_files $work.dot
        out=$work
        dot -Tpng < $work.dot > $out.png
        require_files $out.png
        rm -f $captionfile
        ls $work.{dot,png}
        if ! [[ $noview ]] ; then
            firefox $work.png
        fi
    )
}
treevizn() {
    (
        set -e
        local graehlbin=`echo ~graehl/bin`
        export PATH=$BLOBS/forest-em/latest:$graehlbin:$PATH
        local n=$1
        shift
        local f=$1
        shift
        showvars_required n f
        require_files $f
        local dir=`dirname -- $f`
        local file=`basename -- $f`
        local outdir=$dir/treeviz.$file
        local workdir=$outdir/work
        mkdir -p $outdir
        mkdir -p $workdir
        local work=$workdir/line$n
        local out=$outdir/line$n
        local captionfile=`mktemp /tmp/caption.XXXXXXXX`
        showvars_required out captionfile
        get $n $f > $work.1best
        require_files $work.1best
        extract-field.pl -f hyp -pass $work.1best > $work.hyp
        require_files $work.hyp
        orig_pos=`extract-field.pl -f unreranked-n-best-pos $work.1best`
        (echo -n "line $n of $f (orig #$orig_pos): "; cat $work.hyp; ) > $captionfile
        require_files $captionfile
        cat $work.1best | extract-field.pl -f tree -pass | escapetree > $work.treeviz.tree
        if [ "$*" ] ; then
            cat $work.treeviz.tree | treeviz -s -p 'graph [fontsize=12,labelfontsize=10,center=0]; node [fontsize=10,height=.06,margin=".04,.02",nodesep=.02,shape=none] ;'"$*" -c $captionfile > $work.dot
        else
            cat $work.treeviz.tree | treeviz -s -p 'graph [fontsize=12,labelfontsize=10,center=0]; node [fontsize=10,height=.06,margin=".04,.02",nodesep=.02,shape=none] ;' -c $captionfile > $work.dot
        fi
        require_files $work.dot
        dot -Tpng < $work.dot > $out.png
        require_files $out.png
        rm -f $captionfile
    )
}

wtake() {
    wget -r -l1 -H -t1 -nd -N -np -A.mp3 -erobots=off "$@"
}
alias slo='ssh login.clsp.jhu.edu -l jgraehl'
cplo1() {
    local dest=`relpath ~ $1`
    local dd=`dirname $dest`
    [ "$dd" == "." ] || elo mkdir -p "$dd"
    [ -d "$1" ] && dest=$dd
    echo scp -r "$1" jgraehl@login.clsp.jhu.edu:"$dest"
    scp -r "$1" jgraehl@login.clsp.jhu.edu:"$dest"
}
rfromlo1() {
    local dest=`relpath ~ $1`
    mkdir -p `dirname $dest`
    echo scp -r jgraehl@login.clsp.jhu.edu:"$dest" "$1"
    scp -r jgraehl@login.clsp.jhu.edu:"$dest" "$1"
}
flo() {
    local f
    for f in "$@"; do
        echo scp -r jgraehl@login.clsp.jhu.edu:"$f" .
        scp -r jgraehl@login.clsp.jhu.edu:"$f" .
    done
}

elo() {
    local cdir=`pwd`
    local lodir=`relpath ~ $cdir`
    ssh login.clsp.jhu.edu -l jgraehl ". .bashrc;. isd/hints/aliases.sh;cd $lodir && $*"
    # "$@"
}
eboth() {
    echo "$@"
    "$@" && echo && echo HPC: && echo && ehpc "$@"
}
DefaultBaseAddress=0x70000000
DefaultOffset=0x10000

cygbase() {
    local BaseAddress=${base:-$DefaultBaseAddress}
    local Offset=${off:-$DefaultOffset}
    local f=$1
    shift
    [ -f "$f" ] || f=c:/cygwin/bin/$f
    rebase -v -d -b $BaseAddress -o $Offset $f "$@"
}

export SVNAUTHORS=~/isd/hints/svn.authorsfile
clonecar() {
    local CR=https://nlg0.isi.edu/svn/sbmt/
    git config svn.authorsfile $SVNAUTHORS && git svn --authors-file=$SVNAUTHORS clone --username=graehl --ignore-paths='^(NOTES.*|scraps|syscom|tt|xrsmodels|Jamfile|dagtt)' ---trunk=$CR/trunk/graehl "$@"
    #--tags=$CR/tags --branches=$CR/branches
    #-r 3502 at
    # https://nlg0.isi.edu/svn/sbmt/trunk/graehl@3502
    #e4bd1e594dd7051a9e50561d19bdc31139ba1159

    #--no-metadata
}


testws() {
    cd $WSMT
    makews && ./tests/run-system-tests.pl
}

svncom() {
    (
        proj=${project:-$WSMT}
        cd $proj
        echo $project $proj
        set -e
        (
            if [ $# = 1 ] ; then
                git commit -a -m "$1"
            else
                git commit -a "$@"
            fi
        )
        git svn rebase
        git svn dcommit
        # git push
    )
}
alias wscom="project=$WSMT svncom"

alias c10="pushd $WSMT"

toy() {
    local h=$1
    shift
    $cdec -c ${TOYG:-~/toy-grammar}/cdec-$h.ini "$@"
}

feo() {
    local tt=${1:-hiero}
    shift
    echo 'eso perro feo .' | toy $tt "$@"
}

par() {
    local npar=${npar:-20}
    local parargs=${parargs:-"-p 9g -j $npar"}
    local logdir=${logdir:-`filename_from log "$@"`}
    logdir="`abspath $logdir`"
    mkdir -p "$logdir"
    showvars_required npar parargs logdir
    logarg="-e $logdir"
    $WSMT/vest/parallelize.pl $parextra $parargs $logarg -- "$@"
}

qjhu() {
    SGE_ROOT=/usr/local/share/SGE /usr/local/share/SGE/bin/lx24-x86/qlogin -l mem_free=9g
}
qelo() {
    elo qjhu
}
mkdest() {
    if [ "$2" ] ; then
        dest=$2
    else
        dest=`dirname "$1"`
        mkdir -p "$dest"
    fi
}

fromhost1() {
    (
        cd
        mkdest "$@"
        user=${user:-`userfor $host`}
        echo scp -r "$user@$host:$1" "$dest"
        scp -r $user@$host:"$1" "$dest"
    )
}
fromhost() {
    local host=$1
    shift
    host=$host forall fromhost1 "$@"
}
relhomeby() {
    ${relpath:-$UTIL/relpath} ~ "$@"
}

shost1() {(set -e
        local portarg=
        if [[ $port ]] ; then
            portarg=-P$port
        fi
        )}
tohost1() {
    (
        set -e
        f=$(relhomeby $1)
        cd
        local u
        user=${user:-`userfor $host`}
        [ "$user" ] && u="$user@"
        echo scp -r "$f" "$u$host:`dirname $f`"
        local portarg=
        if [[ $port ]] ; then
            portarg=-P$port
        fi
        if [ "$dryrun" ] ; then
            showvars_optional relpath
        else
            scp $portarg -r "$f" "$u$host:`dirname $f`"
        fi
    )
}
tohostp1() {
    relpath=$UTIL/relpathp tohost1 "$@"
}
tohost() {
    local host=$1
    shift
    host=$host forall tohost1 "$@"
}
tohostp() {
    local host=$1
    shift
    host=$host forall tohostp1 "$@"
}

fromhpc() {
    fromhost $HPCHOST "$@"
}
fromhpc1() {
    host=$HPCHOST fromhost1 "$@"
}
tcmi() {
    local d=$1
    local f=$1
    d=${d%.tar.bz2}
    d=${d%.tar.gz}
    d=${d%.tgz}
    d=${d%.tar.xz}
    shift
    tarxzf "$f" && cd "$d" && cmi "$@"
}
wtx() {
    wget "$1" && tarxzf $(basename $1)
}
wcmi() {
    wget "$1" && tcmi "$(basename $1)"
}
cmi() {
    if ./configure $CONFIG "$@"; then
        make -j 4
        make && make install
    fi
}

cpanforce() {
    perl -MCPAN -e '*CPAN::_flock = sub { 1 }; install( "Test::Output" );' "$@"
}

bleulog() {
    perl -ne 'BEGIN{$x=shift};print "$x\t$1\n" if /BLEU(?: score)? = ([\d.]+)/' -- "$@"
}

firstnum() {
    # 1: string to find number in: .*prefix.*(\d[\d.e-+]*)
    # 2: optional match - first number after match gets printed.
    perl -e '$_=shift; $p=shift; $_=$1 if /\Q$p\E(.*)/;if (/((?:[-+\d]|(?<=\.)\.)[-\d.e+]*)/) { $_=$1;s/\.$//;print "$_\n"}' "$@"
}

shortsh1() {
    perl -i~ -pe 's/^\s*function\s+(\w+)\s*\{/\1() {/' -- "$@"
}
shortsh() {
    shortsh1 *.sh "$@"
}
conff=`echo `
allconff="$conff elisp"
rsync_exclude="--exclude=.git/ --cvs-exclude"

sync2() {
    (
        cd
        local h=$1
        shift
        local u
        user=${user:-$(userfor $h)}
        [ "$user" ] && u="$user@"
        local f
        local darg
        [ "$dryrun" ] && darg="-n"
        echo sync2 user=$user host=$h "$@"
        set -x
        (for f in "$@"; do if [ -d "$f" ] ; then echo $f/; else echo $f; fi; done) | rsync $darg -avruz -e ssh --files-from=- $rsyncargs $rsync_exclude . $u$h:${dest:=.}
    )
}
syncto() {
    sync2 "$@"
}
userfor() {
    case $1 in
        login*) echo -n jgraehl ;;
        *) echo -n graehl ;;
    esac
}
syncfrom() {
    (
        cd
        local h=$1
        shift
        local u
        user=${user:-`userfor $h`}
        [ "$user" ] && u="$user@"
        local f
        local darg
        [ "$dryrun" ] && darg="-n"
        echo syncFROM user=$user host=$h "$@"
        sleep 2
        set -x
        (for f in "$@"; do echo $f; done) | rsync $darg $rsync_exclude -avruz -e ssh --files-from=- $u$h:. .
    )
}
conf2() {
    sync2 $1 isd/hints/
    sync2 $1 .inputrc .screenrc .bashrc .emacs
    sync2 $1 elisp/
}
conffrom() {
    fromhost $1 isd/hints/
    fromhost $1 .inputrc .screenrc .bashrc .emacs
    # syncfrom $1 elisp/
}
conf2l() {
    conf2 login.clsp.jhu.edu
}
alias lob="(cd;cplo isd/hints/{aliases.sh,bashlib.sh};cplo .inputrc .bashrc .emacs )"
alias loa="(cd;cplo1 isd/hints/aliases.sh)"
alias froma="(cd;fromlo1 isd/hints/aliases.sh)"
alias loe="(cd;cplo .emacs elisp)"
alias qs="qstat -f -j"
qdelrange() {
    for i in `seq -f "%.0f" "$@"`; do
        qdel $i
    done
}
cdech() {
    $cdec --help 2>&1 | more
}
gitundo() {
    git stash save --keep-index
}
gitundorm() {
    git stash drop
}
alias comlo=ws10com
gitcom() {
    git commit -a -m "$*"
}
rwpaths() {
    perl -i -pe 's#/home/jgraehl/#/home/graehl/#g;s#/export/ws10smt/#/home/graehl/e/#g' "$@"
}
s0() {
    ssh -l jgraehl a0${1:-3}
}
alias ec='emacsclient -n '
gitsvnbranch() {
    git config --get-all svn-remote.$1.branches
}
gdcommit() {
    (cd $WSMT
        git svn dcommit --commit-url https://graehl:ts7sr8dG9nj2@ws10smt.googlecode.com/svn/trunk
    )
}
refargs() {
    local f
    local r
    local refarg=${refarg:--R}
    for f in "$@"; do
        r="$r $refarg $f"
    done
    echo $r
}
makesrilm() {
    (set -e;
        if [ -f "$1" ] ;then
            mkdir -p srilm
            cd srilm
            tarxzf ../$1
            local d=`realpath .`
            perl -i -pe 's{# SRILM = .*}{SRILM = '$d'}' Makefile
            shift
        fi
        head Makefile
        [ "$noclean" ] || make cleanest OPTION=_c
        local a64
        [ "$force64" ] && a64="MACHINE_TYPE=i686-m64"
        MACHINE_TYPE=`sbin/machine-type`
        for d in bin lib; do
            ln -sf $d/${MACHINE_TYPE}_c $d/${MACHINE_TYPE}
        done
        make $a64 World OPTION=_c "$@"
    )
}
allhosts="login.clsp.jhu.edu hpc.usc.edu"
conf2all() {
    local h
    for h in $allhosts; do
        conf2 $h
    done
}
cp2() {
    tohost "$@"
}
cp2all() {
    local h
    for h in $allhosts; do
        cp2 $h "$@"
    done
}
c2() {
    sync2 "$@"
}
vgd() {
    debug=1 vg "$@"
}
page() {
    "$@" 2>&1 | more
}
page2() {
    page=more save12 "$@"
}
scr() {
    screen -UaARRD
}
scrls() {
    screen -list
}

#for cygwin:
altinstall() {
    local b=$1
    local ver=$2
    local exe=$3
    local f=/usr/bin/$b-$ver$exe
    showvars_required b ver f
    require_file $f && /usr/sbin/update-alternatives --install /usr/bin/$b$exe $b $f 30
}

altgcc4() {
    /usr/sbin/update-alternatives \
        --install "/usr/bin/gcc.exe" "gcc" "/usr/bin/gcc-4.exe" 30 \
        --slave "/usr/bin/ccc.exe" "ccc" "/usr/bin/ccc-4.exe" \
        --slave "/usr/bin/i686-pc-cygwin-ccc.exe" "i686-pc-cygwin-ccc" \
        "/usr/bin/i686-pc-cygwin-ccc-4.exe" \
        --slave "/usr/bin/i686-pc-cygwin-gcc.exe" "i686-pc-cygwin-gcc" \
        "/usr/bin/i686-pc-cygwin-gcc-4.exe"

    /usr/sbin/update-alternatives \
        --install "/usr/bin/g++.exe" "g++" "/usr/bin/g++-4.exe" 30 \
        --slave "/usr/bin/c++.exe" "c++" "/usr/bin/c++-4.exe" \
        --slave "/usr/bin/i686-pc-cygwin-c++.exe" "i686-pc-cygwin-c++" \
        "/usr/bin/i686-pc-cygwin-c++-4.exe" \
        --slave "/usr/bin/i686-pc-cygwin-g++.exe" "i686-pc-cygwin-g++" \
        "/usr/bin/i686-pc-cygwin-g++-4.exe"
}

plboth() {
    local o=$1
    local oarg="-landscape"
    [ "$portrait" ] && oarg=
    shift
    pl -png -o $o.png "$@"
    pl -ps -o $o.ps $oarg "$@"
    ps2pdf $o.ps $o.pdf
}

graph() {
    local xaxis=${xaxis:-1}
    local yaxis=${yaxis:-2}
    local zaxis=${zaxis:-3}
    local xlbl="$1"
    local ylbl="$2"
    shift
    shift
    [ "$zlbl" ] && zarg="y2=$zaxis ylbl2=$zlbl"
    [ "$zlbl" ] && zword=".and.$zlbl"
    local ylbldistance=${ydistance:-'0.7"'}
    local scale=${scale:-1.4}
    [ "$topub" ] && pubb=~/pub/
    local name=${name:-`filename_from $in.$ylbl$zword.vs.$xlbl$zword`}
    local obase=${obase:-$pubb$name}
    mkdir -p `dirname $obase`
    local title=${title:-$obase}
    local darg
    if [ "$data" ] ; then
        darg="data=$data"
        if [ "$pubb" ] ; then
            banner cp "$data" $pubb/
            cp "$data" $pubb/
        fi
    fi
    set -x
    pubb=$pubb plboth $obase -prefab lines $darg x=$xaxis xlbl="$xlbl" y=$yaxis ylbl="$ylbl" ylbldistance=$ylbldistance title="$title" ystubfmt '%6g' ystubdet="size=6" -scale $scale $zarg "$@"
    set +x
    local of=$obase.png
    ls -l $obase.* 1>&2
    echo $of
}


graph3() {
    local y=$1
    local ylbl="$2"
    local y2=$3
    local ylbl2="$4"
    local y3=$5
    local ylbl3="$6"
    local ylbldistance=${7:-'0.7"'}
    local name=${name:-$data}
    local obase=${obase:-$opre$name.x_`filename_from $xlbl`.$y.`filename_from $ylbl`.$y2.`filename_from $ylbl2`.$y3.`filename_from $ylbl3`}
    local of=$obase.png
    local ops=$obase.ps
    #yrange=0
    local yrange_arg
    [ "$ymin" ] && yrange_arg="yrange=$ymin $ymax"
    #pointsym=none pointsym2=none
    title=${title:-"$ylbl $ylbl2 $ylbl3 vs. $xlbl"}
    xlbl=${xlbl:=x}
    showvars_required obase xlbl ylbl ylbl2 ylbl3
    showvars_optional yrange yrange_arg title
    require_files $data
    plboth $obase -prefab lines data=$data x=1 "$yrange_arg" y=$y name="$ylbl" y2=$y2 name2="$ylbl2" y3=$y3 name3="$ylbl3" ylbldistance=$ylbldistance xlbl="$xlbl" title="$title" ystubfmt '%4g' ystubdet="size=6" linedet2="style=1" linedet3="style=3" -scale ${scale:-1.4}
    echo $of
}

cppdb() {
    local f=$1
    shift
    g++ -x c++ -dD -E -I. -I.. -I../.. -I$FIRST_PREFIX/include "$@" "$f" > "$f.ii"
    preview "$f.ii"
}

clear_gcc() {
    unset C_INCLUDE_PATH
    unset CPPFLAGS
    unset LD_LIBRARY_PATH
    unset LIBRARY_PATH
    unset LDFLAGS
    unset CXXFLAGS
    unset CFLAGS
    unset CPPFLAGS
}

first_gcc() {
    clear_gcc
    export LD_LIBRARY_PATH=$FIRST_PREFIX/lib:$FIRST_PREFIX/lib64
    #    export C_INCLUDE_PATH=$FIRST_PREFIX/include
    export CXXFLAGS="-I$FIRST_PREFIX/include"
    export LDFLAGS="-L$FIRST_PREFIX/lib -L$FIRST_PREFIX/lib64"
}

config_gcc_bare() {
    first_gcc
    local nomp=--disable-libgomp
    #--disable-shared
    local skip="--disable-libssp --disable-libmudflap --disable-nls --disable-decimal-float"
    # --disable-bootstrap
    # gomp: open mp. ssp: stack corruption mitigation. mudflap: buffer overflow instrumentation (optional). nls: non-english text
    local basegcc=${basegcc:--enable-language=c,c++ --enable-__cxa_atexit --enable-clocale=gnu --enable-threads=posix --disable-multilib $skip}
    #--with-gmp-include=`realpath gmp` --with-gmp-lib=`realpath gmp`/.libs
    # local basegcc=${basegcc:--enable-language=c,c++ --enable-clocale=gnu --enable-shared --enable-threads=posix --disable-multilib}

    src=${src:-.}

    echo $src/configure --prefix=$FIRST_PREFIX $basegcc "$@" > my.config.sh
    . my.config.sh
    #--with-mpfr=$FIRST_PREFIX --with-mpc=$FIRST_PREFIX --with-gmp=$FIRST_PREFIX
}

config_gcc() {
    ( set -e
        config_gcc_bare "$@"
    )
}


make_gcc() {
    ( set -e
        first_gcc
        make -j 4 "$@"
    )
}

install_gcc() {
    (
        first_gcc
        make install
    )
}

build_gcc() {
    (
        set -e
        config_gcc_bare "$@"
        make_gcc
        install_gcc
    )
}

dmakews() {
    g++ --version
    debug=1 MAKEPROC=4 cmakews "CXXFLAGS+=-fdiagnostics-show-option" "$@"
}

checkws() {
    debug=1 MAKEPROC=4 cmakews check
}

uninstgcc() {
    (
        set -e
        cd $FIRST_PREFIX
        cd bin
        mkdir uninstgcc
        mv *gcc* *g++* cpp gcov uninstgcc/
    )
}

confws() {
    (
        cd $WSMT
        ./configure --with-srilm=`realpath ~/src/srilm` --prefix=$FIRST_PREFIX "$@"
    )
}

bootstrap() {
    ( set -e
        aclocal
        automake --add-missing
        autoconf
        libtoolize -i --recursive
    )
}

fastflags() {
    CFLAGS+=-Ofast
    CXXFLAGS+=-Ofast
    export CFLAGS CXXFLAGS
    # turns on fast-math, and maybe some unsafe opts beyond -O3
}

slowflags() {
    CFLAGS+=-O0
    CXXFLAGS+=-O0
    export CFLAGS CXXFLAGS
}
makecdec() {
    make cdec CXXFLAGS+="-Wno-sign-compare -Wno-unused-parameter -loolm -ldstruct -lmisc -lz -lboost_program_options -lpthread -lboost_regex -lboost_thread -O0 -ggdb"
}
carmelv() {
    grep VERSION ~/t/graehl/carmel/src/carmel.cc
}
pdf2() {
    batchmode=1 latn=2 lat2pdf_landscape "$@"
}
alias ..="cd .."
alias c=cd
if [[ $OS = Darwin ]] ; then
    alias l="ls -alFG"
    alias lo="ls -alHLFCG"
    export CLICOLOR=1
else
    alias l="ls -alF --color=auto"
    alias lo="ls -alHLFC --color=auto"
fi
alias k=colormake
alias g=git
alias s=svn
getcert() {
    local REMHOST=$1
    local REMPORT=${2:-443}
    echo |\
openssl s_client -connect ${REMHOST}:${REMPORT} 2>&1 |\
sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
}
showprompt()
{
    echo $PS1 | less -E
    echo $PROMPT_COMMAND | less -E
}
ming() {
    local src=$1
    shift
    local exe=$src
    exe=${exe%.cc}
    exe=${exe%.cpp}
    exe=${exe%.c}
    /mingw/bin/g++ --std=c++11 $src -o $exe "$@" && ./$exe
}

gjam() {
    GJAMROUND=$DROPBOX/jam/1c
    GJAMDIR=$GJAMROUND/a
    local in=$1
    local basein=`basename $in`
    if [[ $basein = A-* ]] ; then
        GJAMDIR=$GJAMROUND/a
    elif [[ $basein = B-* ]] ; then
        GJAMDIR=$GJAMROUND/b
    elif [[ $basein = C-* ]] ; then
        GJAMDIR=$GJAMROUND/c
    fi

    shift
    local cc=$1
    if ! [[ -f $cc ]] ; then
        cc=solve.cc
    fi
    if ! [[ -s $cc ]] ; then
        cd $GJAMDIR
        shift
    fi
    if [[ $in ]] ; then
        cp $in in
    fi
    require_file in
    set -e
    set -x
    if [[ $no11 ]] ; then
        g++ -O -g $cc -o solve
    else
        $CXX11 -O3 --std=c++11 $cc -o solve
    fi
    time ./solve
    set +x
    out=out
    expect=$in.expect
    [ -f $expect ] || expect=
    if [[ $in ]] ; then
        basein=$(basename $in)
        out=${basein%.in}.out
        cp out $out
    else
        in=in
    fi
    wrong=${out%.out}.wrong
    tailn=20 preview $out $expect
    wc -l $in $out
    if [[ -f $wrong ]] ; then
        set -x
        diff -u $out $wrong
        set +x
    fi
}


addpythonpath() {
    if ! [[ $PYTHONPATH ]] || ! [[ $PYTHONPATH = *$1* ]] ; then
        if [[ $PYTHONPATH ]] ; then
            export PYTHONPATH=$1:$PYTHONPATH
        else
            export PYTHONPATH=$1
        fi
    fi
}

addpythonpath $xmtx/python $racerextbase/Shared/python

export MARKPATH=$HOME/.marks
function jump {
    cd -P $MARKPATH/$1 2> /dev/null || echo "No such mark: $1"
}
function mark {
    mkdir -p $MARKPATH; ln -s $(pwd) $MARKPATH/$1
}
function unmark {
    rm -f $MARKPATH/$1
}
function marks {
    \ls -l $MARKPATH | tail -n +2 | sed 's/  / /g' | cut -d' ' -f9- | awk -F ' -> ' '{printf "%-10s -> %s\n", $1, $2}'
}
function _jump {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local marks=$(find $MARKPATH -type l | awk -F '/' '{print $NF}')
    COMPREPLY=($(compgen -W '${marks[@]}' -- "$cur"))
    return 0
}
complete -o default -o nospace -F _jump jump

# maintains a jump-list of the directories you actually use
#
# INSTALL:
#     * put something like this in your .bashrc/.zshrc:
#         . /path/to/z.sh
#     * cd around for a while to build up the db
#     * PROFIT!!
#     * optionally:
#         set $_Z_CMD in .bashrc/.zshrc to change the command (default z).
#         set $_Z_DATA in .bashrc/.zshrc to change the datafile (default ~/.z).
#         set $_Z_NO_RESOLVE_SYMLINKS to prevent symlink resolution.
#         set $_Z_NO_PROMPT_COMMAND if you're handling PROMPT_COMMAND yourself.
#         set $_Z_EXCLUDE_DIRS to an array of directories to exclude.
#
# USE:
#     * z foo # cd to most frecent dir matching foo
#     * z foo bar # cd to most frecent dir matching foo and bar
#     * z -r foo # cd to highest ranked dir matching foo
#     * z -t foo # cd to most recently accessed dir matching foo
#     * z -l foo # list matches instead of cd
#     * z -c foo # restrict matches to subdirs of $PWD

[ -d "${_Z_DATA:-$HOME/.z}" ] && {
    echo "ERROR: z.sh's datafile (${_Z_DATA:-$HOME/.z}) is a directory."
}

_z() {

    local datafile="${_Z_DATA:-$HOME/.z}"

    # bail if we don't own ~/.z (we're another user but our ENV is still set)
    [ -f "$datafile" -a ! -O "$datafile" ] && return

    # add entries
    if [ "$1" = "--add" ]; then
        shift

        # $HOME isn't worth matching
        [ "$*" = "$HOME" ] && return

        # don't track excluded dirs
        local exclude
        for exclude in "${_Z_EXCLUDE_DIRS[@]}"; do
            [ "$*" = "$exclude" ] && return
        done

        # maintain the data file
        local tempfile="$datafile.$RANDOM"
        while read line; do
            # only count directories
            [ -d "${line%%\|*}" ] && echo $line
        done < "$datafile" | awk -v path="$*" -v now="$(date +%s)" -F"|" '
            BEGIN {
                rank[path] = 1
                time[path] = now
            }
            $2 >= 1 {
                # drop ranks below 1
                if( $1 == path ) {
                    rank[$1] = $2 + 1
                    time[$1] = now
                } else {
                    rank[$1] = $2
                    time[$1] = $3
                }
                count += $2
            }
            END {
                if( count > 6000 ) {
                    # aging
                    for( x in rank ) print x "|" 0.99*rank[x] "|" time[x]
                } else for( x in rank ) print x "|" rank[x] "|" time[x]
            }
        ' 2>/dev/null >| "$tempfile"
        # do our best to avoid clobbering the datafile in a race condition
        if [ $? -ne 0 -a -f "$datafile" ]; then
            env rm -f "$tempfile"
        else
            env mv -f "$tempfile" "$datafile" || env rm -f "$tmpfile"
        fi

    # tab completion
    elif [ "$1" = "--complete" ]; then
        while read line; do
            [ -d "${line%%\|*}" ] && echo $line
        done < "$datafile" | awk -v q="$2" -F"|" '
            BEGIN {
                if( q == tolower(q) ) imatch = 1
                split(substr(q, 3), fnd, " ")
            }
            {
                if( imatch ) {
                    for( x in fnd ) tolower($1) !~ tolower(fnd[x]) && $1 = ""
                } else {
                    for( x in fnd ) $1 !~ fnd[x] && $1 = ""
                }
                if( $1 ) print $1
            }
        ' 2>/dev/null

    else
        # list/go
        while [ "$1" ]; do case "$1" in
                --) while [ "$1" ]; do shift; local fnd="$fnd $1";done;;
                -*) local opt=${1:1}; while [ "$opt" ]; do case ${opt:0:1} in
                            c) local fnd="^$PWD $fnd";;
                            h) echo "${_Z_CMD:-z} [-chlrtx] args" >&2; return;;
                            x) sed -i "\:^${PWD}|.*:d" "$datafile";;
                            l) local list=1;;
                            r) local typ="rank";;
                            t) local typ="recent";;
                        esac; opt=${opt:1}; done;;
                *) local fnd="$fnd $1";;
            esac; local last=$1; shift; done
            [ "$fnd" -a "$fnd" != "^$PWD " ] || local list=1

        # if we hit enter on a completion just go there
            case "$last" in
            # completions will always start with /
                /*) [ -z "$list" -a -d "$last" ] && cd "$last" && return;;
            esac

        # no file yet
            [ -f "$datafile" ] || return

            local cd
            cd="$(while read line; do
            [ -d "${line%%\|*}" ] && echo $line
        done < "$datafile" | awk -v t="$(date +%s)" -v list="$list" -v typ="$typ" -v q="$fnd" -F"|" '
            function frecent(rank, time) {
                # relate frequency and time
                dx = t - time
                if( dx < 3600 ) return rank * 4
                if( dx < 86400 ) return rank * 2
                if( dx < 604800 ) return rank / 2
                return rank / 4
            }
            function output(files, out, common) {
                # list or return the desired directory
                if( list ) {
                    cmd = "sort -n >&2"
                    for( x in files ) {
                        if( files[x] ) printf "%-10s %s\n", files[x], x | cmd
                    }
                    if( common ) {
                        printf "%-10s %s\n", "common:", common > "/dev/stderr"
                    }
                } else {
                    if( common ) out = common
                    print out
                }
            }
            function common(matches) {
                # find the common root of a list of matches, if it exists
                for( x in matches ) {
                    if( matches[x] && (!short || length(x) < length(short)) ) {
                        short = x
                    }
                }
                if( short == "/" ) return
                # use a copy to escape special characters, as we want to return
                # the original. yeah, this escaping is awful.
                clean_short = short
                gsub(/[\(\)\[\]\|]/, "\\\\&", clean_short)
                for( x in matches ) if( matches[x] && x !~ clean_short ) return
                return short
            }
            BEGIN { split(q, words, " "); hi_rank = ihi_rank = -9999999999 }
            {
                if( typ == "rank" ) {
                    rank = $2
                } else if( typ == "recent" ) {
                    rank = $3 - t
                } else rank = frecent($2, $3)
                matches[$1] = imatches[$1] = rank
                for( x in words ) {
                    if( $1 !~ words[x] ) delete matches[$1]
                    if( tolower($1) !~ tolower(words[x]) ) delete imatches[$1]
                }
                if( matches[$1] && matches[$1] > hi_rank ) {
                    best_match = $1
                    hi_rank = matches[$1]
                } else if( imatches[$1] && imatches[$1] > ihi_rank ) {
                    ibest_match = $1
                    ihi_rank = imatches[$1]
                }
            }
            END {
                # prefer case sensitive
                if( best_match ) {
                    output(matches, best_match, common(matches))
                } else if( ibest_match ) {
                    output(imatches, ibest_match, common(imatches))
                }
            }
        ')"
            [ $? -gt 0 ] && return
            [ "$cd" ] && cd "$cd"
    fi
}

alias ${_Z_CMD:-z}='_z 2>&1'

[ "$_Z_NO_RESOLVE_SYMLINKS" ] || _Z_RESOLVE_SYMLINKS="-P"

    # bash
    # tab completion
complete -o filenames -C '_z --complete "$COMP_LINE"' ${_Z_CMD:-z}
[ "$_Z_NO_PROMPT_COMMAND" ] || {
        # populate directory list. avoid clobbering other PROMPT_COMMANDs.
    grep "_z --add" <<< "$PROMPT_COMMAND" >/dev/null || {
        PROMPT_COMMAND="$PROMPT_COMMAND"$'\n''_z --add "$(pwd '$_Z_RESOLVE_SYMLINKS' 2>/dev/null)" 2>/dev/null;'
    }
}

jpgclean() {
    exiftool -all= ${*:-*.jpg}
}

bd() {
    local OLDPWD=`pwd`
    local NEWPWD=
    local index=
    if [ "$1" = "-s" ] ; then
        NEWPWD=`echo $OLDPWD | sed 's|\(.*/'$2'[^/]*/\).*|\1|'`
        index=`echo $NEWPWD | awk '{ print index($1,"/'$2'"); }'`
    else
        NEWPWD=`echo $OLDPWD | sed 's|\(.*/'$1'/\).*|\1|'`
        index=`echo $NEWPWD | awk '{ print index($1,"/'$1'/"); }'`
    fi

    if [ $index -eq 0 ] ; then
        echo "No such occurrence."
    fi

    echo $NEWPWD
    cd "$NEWPWD"
}
