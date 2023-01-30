#!/bin/sh
#export LC_CTYPE=en_US.UTF-8
###Changelog::
#   230106 ZQ: creat
#==================================================================== abt. define
VER="pub.sh {v23.1.6} auto mdbook and git upd"
DATE=`date "+%y%m%d"`

MDBOOK="$(which mdbook)"
GIT="$(which git)"
#==================================================================== abt. path
ROOT="/Users/zoomq/Exercism/_sites/rustacean"
SRC="$ROOT/src"
DOC="$ROOT/docs"
CNAME="$SRC/CNAME"

#==================================================================== abt. action
echo "###::$VER build all rustacean for rs.101.so"            #>> $LOGF
echo "###::run@" `date +"%Y/%m/%d %H:%M:%S"` #>> $LOGF

pwd 
$MDBOOK build
cp -fv $CNAME $DOC
ls $DOC

NOW=`date "+%y%m%d %H:%M:%S"`
git upd "re-build by mdbook AT{$NOW}"

echo "###::end@" `date +"%Y/%m/%d %H:%M:%S"` #>> $LOGF
#==================================================================== end shell script
exit  0
