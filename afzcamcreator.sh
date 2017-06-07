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
    echo "      --versionnumber=x.y.z   afzcam version number (default: 1.0.0)"
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
    --versionnumber=*)
    versionnumber="${i#*=}"
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

arrversionnumber=(${versionnumber//./ })

[ "$inputafzcamfile" = "" ] && error "NO INPUT AFZCAM FILE SPECIFIED"

[ "$rawfile" = "" ] && error "NO RAW FILE SPECIFIED"

[ "$outputafzcamfile" = "" ] && error "NO OUTPUT AFZCAM FILE SPECIFIED"

[ "${arrversionnumber[0]}" = "" ] && error "MISSING VERSION NUMBER"
[ "${arrversionnumber[1]}" = "" ] && error "INCORRECT VERSION NUMBER"
[ "${arrversionnumber[2]}" = "" ] && error "INCORRECT VERSION NUMBER"


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

replaceProperty ${TMPDIR}/${lCameraModel}.afcamera/Info.afpxml "modelName" "${model}"
replaceProperty ${TMPDIR}/${lCameraModel}.afcamera/Info.afpxml "lensMenuModel" "${model}"
replaceProperty ${TMPDIR}/${lCameraModel}.afcamera/Info.afpxml "majorVersion" ${arrversionnumber[0]}
replaceProperty ${TMPDIR}/${lCameraModel}.afcamera/Info.afpxml "minorVersion" ${arrversionnumber[1]}
replaceProperty ${TMPDIR}/${lCameraModel}.afcamera/Info.afpxml "bugfixVersion" ${arrversionnumber[2]}

if [ -n "$noiseninjaname" ]; then
    sed -i -e "s@noiseNinjaName=.*@noiseNinjaName=\"${noiseninjaname}\"@" ${TMPDIR}/${lCameraModel}.afcamera/Info.afpxml
fi

cd ${TMPDIR} && zip -r ${outputafzcamfile} ${lCameraModel}.afcamera && cd ..
cp ${TMPDIR}/${outputafzcamfile} .
