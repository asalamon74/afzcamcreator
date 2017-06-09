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
    echo "  $(basename $0) [options] input.afzcam imagefile output.afzcam"
    echo "Options:"
    echo "  -h, --help                  display this help"
    echo "      --noiseNinjaName=name   noise ninja name"
    echo "      --versionnumber=x.y.z   afzcam version number (default: 1.0.0)"
    echo "      --author=name           author (default: afzcamcreator)"
    echo "      --keepicc               keep the icc specified in input.afzcam"
    echo "      --icc=file              icc (or icm) file to use"
}

error() {
    echo $1
    usage
    exit 1
}

replaceProperty() {
    sed -i -e "s@$2=[^>]*@$2=\"$3\"@" $1
}

versionnumber=1.0.0
author=afzcamcreator

for i in "$@"
do
case $i in
    -h|--help)
    usage
    exit
    ;;
    --noiseninjaname=*)
    noiseninjaname="${i#*=}"
    shift
    ;;
    --versionnumber=*)
    versionnumber="${i#*=}"
    shift
    ;;
    --author=*)
    author="${i#*=}"
    shift
    ;;
    --keepicc)
    keepicc=1
    shift
    ;;
    --icc=*)
    icc="${i#*=}"
    shift
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

if [[ -n $3 ]]; then
outputafzcamfile=$3
fi

arrversionnumber=(${versionnumber//./ })

[ "$inputafzcamfile" = "" ] && error "NO INPUT AFZCAM FILE SPECIFIED"

if [[ $inputafzcamfile != *.afzcam ]]; then
    inputafzcamfile=${inputafzcamfile}.afzcam
fi;

[ ! -f "$inputafzcamfile" ] && error "CANNOT OPEN INPUT AFZCAM FILE ${inputafzcamfile}"

[ "$rawfile" = "" ] && error "NO IMAGE FILE SPECIFIED"

[ ! -f "$rawfile" ] && error "CANNOT OPEN IMAGE FILE"

[ "$outputafzcamfile" = "" ] && error "NO OUTPUT AFZCAM FILE SPECIFIED"

if [[ $outputafzcamfile != *.afzcam ]]; then
    outputafzcamfile=${outputafzcamfile}.afzcam
fi;

baseOutputafzcamfile=$(basename $outputafzcamfile .afzcam)

[ "${arrversionnumber[0]}" = "" ] && error "MISSING VERSION NUMBER"
[ "${arrversionnumber[1]}" = "" ] && error "INCORRECT VERSION NUMBER"
[ "${arrversionnumber[2]}" = "" ] && error "INCORRECT VERSION NUMBER"

[ -n "$icc" -a -n "$keepicc" ] && error "CANNOT USE BOTH --icc AND --keepicc"

[ -n "$icc" -a ! -f "$icc" ] &&  error "CANNOT OPEN ICC FILE: $icc"

baseIcc=$(basename $icc)

if [[ $baseIcc == *.icm ]]; then
    baseIcc=$(basename $baseIcc .icm).icc
fi;

echo $baseIcc

mkdir "$TMPDIR" || error "CANNOT CREATE TEMPORARY FILE DIRECTORY"

unzip ${inputafzcamfile} -d ${TMPDIR}

cameraModel=$(exiftool -p '${UniqueCameraModel;tr/ /_/;s/__+/_/g}' ${rawfile} 2> /dev/null)
make=$(exiftool -p '${make}' ${rawfile} 2> /dev/null)
model=$(exiftool -p '${model}' ${rawfile} 2> /dev/null)
scaleFactor=$(exiftool -p '${ScaleFactor35efl}' ${rawfile} 2> /dev/null)

lCameraModel=$(echo "$cameraModel" | tr '[:upper:]' '[:lower:]')

echo $cameraModel

mv ${TMPDIR}/*.afcamera ${TMPDIR}/${baseOutputafzcamfile}.afcamera

echo $make
echo $model

cameradir=${TMPDIR}/${baseOutputafzcamfile}.afcamera

sed -i -e '/<Lens /,/<\/Lens>/d' ${cameradir}/lens-profile.xml
sed -i -e "s@<Maker>\(.*\)</Maker>@<Maker>${make}</Maker>@" ${cameradir}/lens-profile.xml
sed -i -e "s@<Model>\(.*\)</Model>@<Model>${model}</Model>@" ${cameradir}/lens-profile.xml
sed -i -e "s@<CropMultiplier>\(.*\)</CropMultiplier>@<CropMultiplier>${scaleFactor}</CropMultiplier>@" ${cameradir}/lens-profile.xml

replaceProperty ${cameradir}/Info.afpxml "modelName" "${model}"
replaceProperty ${cameradir}/Info.afpxml "lensMenuModel" "${model}"
replaceProperty ${cameradir}/Info.afpxml "author" "${author}"
replaceProperty ${cameradir}/Info.afpxml "majorVersion" ${arrversionnumber[0]}
replaceProperty ${cameradir}/Info.afpxml "minorVersion" ${arrversionnumber[1]}
replaceProperty ${cameradir}/Info.afpxml "bugfixVersion" ${arrversionnumber[2]}

if [ -z "$keepicc" ]; then
    replaceProperty ${cameradir}/Info.afpxml "cameraProfiles" "100,void.icc"
    rm -rf ${cameradir}/icc/
fi

if [ -n "$icc" ]; then
    replaceProperty ${cameradir}/Info.afpxml "cameraProfiles" "100,$baseIcc"
    rm -rf ${cameradir}/icc/
    mkdir ${cameradir}/icc/
    cp ${icc} ${cameradir}/icc/${baseIcc}
fi

if [ -n "$noiseninjaname" ]; then
    replaceProperty ${cameradir}/Info.afpxml "noiseNinjaName" "${noiseninjaname}"
fi


cd ${TMPDIR} && zip -r ${outputafzcamfile} ${baseOutputafzcamfile}.afcamera && cd ..
cp ${TMPDIR}/${outputafzcamfile} .
