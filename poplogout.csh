#!/bin/tcsh
### This must be run using "source poplogout.csh", from tcsh or csh
### $poplocal/local/com/poplogout
#
# J. Meyer, Nov 1990
# A. Sloman, various modifications and extensions 30 Jun 2002
# poplogout - remove Poplog environment variables from environment
#
# usage: source poplogout

if ( ! ($?usepop || $?popsys )) exit 0 # no poplog to logout from

# print a brief message
echo "poplogout":  poplog, usepop = $usepop


# BASIC UNSETS: remove variables listed in $usepop/pop/com/popenv
# And others added by A.Sloman

foreach i ( \
        popcom \
        popsrc \
        popsys \
        popexternlib \
        popautolib \
        popdatalib \
        popliblib \
        poppwmlib \
        popsunlib \
        popvedlib \
        poplocalauto \
        poplocalbin \
        popsavelib \
        popcomppath \
        popsavepath \
        popexlinkbase \
        pop_ved      \
        pop_help     \
        pop_ref      \
        pop_teach    \
        pop_doc      \
        pop_im       \
        pop_eliza    \
        pop_prolog   \
        pop_clisp    \
        pop_pml      \
        pop_xved     \
        pop_xvedpro  \
        pop_xvedlisp \
        popcontrib   \
        pop_pop11    \
        pop_popc     \
        poplib       \
        pop_poplink  \
        popobjlib    \
        local        \
        pop_poplibr  \
    )
    unsetenv $i
end

# UNSET PATH: remove $usepop and $poplocal from path
set npath=
foreach i ( $path )
if (("$i" !~ "$usepop"*) && ("$i" !~ "$poplocal"*) ) set npath=($npath $i)
end
set path=($npath)
unset npath

# TESTED UNSETS: unset conditionally set variables
# UNSET USEPOP
unsetenv usepop
unsetenv poplocal

# DONE
