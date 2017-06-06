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
    echo "  $(basename $0) [options]"
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

mkdir "$TMPDIR" || error "CANNOT CREATE TEMPORARY FILE DIRECTORY"

echo Test
