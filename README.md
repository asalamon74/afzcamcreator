[![Build Status](https://travis-ci.org/asalamon74/afzcamcreator.svg?branch=master)](https://travis-ci.org/asalamon74/afzcamcreator)

# afzcamCreator

Corel AfterShot Pro 3 afzcam creator. This tool can create a camera profile for an unsupported camera using information from a similar supported camera profile and an image taken by the new camera.

## Requirements

- exiftool
- Standard Unix tools (zip, sed, ...)

## Usage

```
afzcamcreator.sh [options] input.afzcam imagefile output.afzcam
```

* input.afzcam: This camera profile will be used as a template. You can
 download camera profiles from the [Corel AfterShot Pro
 Downloads](http://learn.corel.com/aftershot-pro-downloads/) page.

* imagefile: A sample file (preferrable RAW) taken using the camera.

* output.afzcam: The output file to be created.

### ICC

There are several option for ICC color profiles:

* By default the tool removes the ICC profiles defined in the input afzcam file. AfterShot Pro works even if ICC is missing from the camera profile (maybe it uses some default profile).
* If `--keepicc` option is specified the ICC profiles in the input afzcam file will be used.
* It is possible to embed a new ICC profile using the `--icc` option.

### Other options

Is is also possible to change a few other fields of the camera profile

```
* --noiseNinjaName=name   noise ninja name
* --versionnumber=x.y.z   afzcam version number (default: 1.0.0)
* --author=name           author (default: afzcamcreator)
```
