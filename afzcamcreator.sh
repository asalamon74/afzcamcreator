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
    echo "  $(basename $0) [options] input.afzcam"
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
inputfile=$1
fi

[ "$inputfile" = "" ] && error "NO INPUT FILE SPECIFIED"

mkdir "$TMPDIR" || error "CANNOT CREATE TEMPORARY FILE DIRECTORY"

unzip ${inputfile} -d ${TMPDIR}

echo Test
