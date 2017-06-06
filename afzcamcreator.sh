#!/bin/bash

TMPROOTDIR="."
TMPDIR="${TMPROOTDIR}/AFZCAMCREATOR.$$"

cleanup() {
  rv=$?
  rm -rf $TMPDIR
  exit $rv
}

trap cleanup INT TERM EXIT

usage() {
    echo "Usage:"
    echo "  $(basename $0) [options] input.afzcam rawfile"
    echo "Options:"
    echo "  -h, --help                display this help"
}

error() {
    echo $1
    usage
    exit 1
}

for i in "$@"
do
case $i in
    -h|--help)
    usage
    exit
    ;;
    -*)
    echo "Unknown option $1"
    usage
    exit 1
    ;;
esac
done

if [[ -n $1 ]]; then
inputafzcamfile=$1
fi

if [[ -n $2 ]]; then
rawfile=$2
fi

[ "$inputafzcamfile" = "" ] && error "NO INPUT AFZCAM FILE SPECIFIED"

[ "$rawfile" = "" ] && error "NO RAW FILE SPECIFIED"

mkdir "$TMPDIR" || error "CANNOT CREATE TEMPORARY FILE DIRECTORY"

unzip ${inputafzcamfile} -d ${TMPDIR}

echo Test
