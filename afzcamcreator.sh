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
    echo "  $(basename $0)"
}

error() {
    echo $1
    usage
    exit 1
}

mkdir "$TMPDIR" || error "CANNOT CREATE TEMPORARY FILE DIRECTORY"

echo Test
