#!/bin/sh
## Run this in the poplog_base directory created from tar file
## Adds two tar commands to Waldek's build_pop.sh script
## For some reason this works only if 'sourced'.
## 20 Aug 2020: Broken version fixed by Waldek Hebisch
##

## Make it easy to find the pathname, for $usepop
echo 'Create file whose content is the path name of this directory'

echo `pwd` > USEPOP

echo "directory name stored in file USEPOP, for future use."
echo "cat USEPOP"
cat USEPOP

usepop=`pwd`
export usepop

echo "./build_pop0 > rapp1 2>&1"
./build_pop0 > rapp1 2>&1

echo "mv pop/pop/newpop11 pop/pop/corepop"
echo "type 'y' if permission requested"
echo ""
mv pop/pop/newpop11 pop/pop/corepop

echo ""
echo "run second build, to complete construction of basic new poplog"
echo "./build_pop2 > rapp2 2>&1"
./build_pop2 > rapp2 2>&1

echo ""

echo "Basic saved images created in pop/lib/psv:"
echo ""
echo "ls -l pop/lib/psv"
ls -l pop/lib/psv

echo ""
cd pop
echo "Basic pop directory"

ls -l
echo "Installing doc files"
tar xfj ../../docs.tar.bz2

##ls -l
echo ""

echo "Installing packages directory"
tar xfj ../../packages-V16.tar.bz2
ls -l

echo ""
echo "using .../pop/com/poplog.sh to set up environment variables needed to run poplog"

echo ""
echo 'source $usepop/pop/com/poplog.sh'
. $usepop/pop/com/poplog.sh
echo ""

echo "CREATING DOCUMENTATION INDEXES NEEDED BY USERS"

echo ""
## get rid of any previous output file
rm -f /tmp/makeindexes-out.txt

echo '$usepop/pop/com/makeindexes > /tmp/makeindexes-out.txt'

$usepop/pop/com/makeindexes > /tmp/makeindexes-out.txt

echo "DONE"

echo "Output of makeindexes should be in /tmp/makeindexes-out.txt"

echo 'Try setting up $usepop using poplog_base/USEPOP'
echo ''
echo 'Then if using bash or sh, do'
echo ''
echo 'source $usepop/pop/com/poplog.sh'
echo ''
echo 'If using tcsh or csh, do'
echo ''
echo 'source $usepop/pop/com/poplog.csh'
echo ''
