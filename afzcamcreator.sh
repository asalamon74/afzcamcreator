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
    echo "  $(basename $0) [options] input.afzcam rawfile output.afzcam"
    echo "Options:"
    echo "  -h, --help                  display this help"
    echo "      --noiseNinjaName=name   noise ninja name"
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
    --noiseninjaname=*)
    noiseninjaname="${i#*=}"
    shift # past argument=value
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


[ "$inputafzcamfile" = "" ] && error "NO INPUT AFZCAM FILE SPECIFIED"

[ "$rawfile" = "" ] && error "NO RAW FILE SPECIFIED"

[ "$outputafzcamfile" = "" ] && error "NO OUTPUT AFZCAM FILE SPECIFIED"

mkdir "$TMPDIR" || error "CANNOT CREATE TEMPORARY FILE DIRECTORY"

unzip ${inputafzcamfile} -d ${TMPDIR}

cameraModel=$(exiftool -p '${UniqueCameraModel;tr/ /_/;s/__+/_/g}' ${rawfile} 2> /dev/null)
make=$(exiftool -p '${make}' ${rawfile} 2> /dev/null)
model=$(exiftool -p '${model}' ${rawfile} 2> /dev/null)
scaleFactor=$(exiftool -p '${ScaleFactor35efl}' ${rawfile} 2> /dev/null)

lCameraModel=$(echo "$cameraModel" | tr '[:upper:]' '[:lower:]')

echo $cameraModel

mv ${TMPDIR}/*.afcamera ${TMPDIR}/${lCameraModel}.afcamera

echo $make
echo $model

sed -i -e '/<Lens /,/<\/Lens>/d' ${TMPDIR}/${lCameraModel}.afcamera/lens-profile.xml
sed -i -e "s@<Maker>\(.*\)</Maker>@<Maker>${make}</Maker>@" ${TMPDIR}/${lCameraModel}.afcamera/lens-profile.xml
sed -i -e "s@<Model>\(.*\)</Model>@<Model>${model}</Model>@" ${TMPDIR}/${lCameraModel}.afcamera/lens-profile.xml
sed -i -e "s@<CropMultiplier>\(.*\)</CropMultiplier>@<CropMultiplier>${scaleFactor}</CropMultiplier>@" ${TMPDIR}/${lCameraModel}.afcamera/lens-profile.xml

sed -i -e "s@modelName=.*@modelName=\"${model}\"@" ${TMPDIR}/${lCameraModel}.afcamera/Info.afpxml
sed -i -e "s@lensMenuModel=.*@lensMenuModel=\"${model}\"@" ${TMPDIR}/${lCameraModel}.afcamera/Info.afpxml
if [ -n "$noiseninjaname" ]; then
    sed -i -e "s@noiseNinjaName=.*@noiseNinjaName=\"${noiseninjaname}\"@" ${TMPDIR}/${lCameraModel}.afcamera/Info.afpxml
fi

cd ${TMPDIR} && zip -r ${outputafzcamfile} ${lCameraModel}.afcamera && cd ..
cp ${TMPDIR}/${outputafzcamfile} .
