#!/bin/sh

VERSION=`perl -n -e '/Version (.*)/ && print $1' ../Ack.pm`

INPUT_FILE=ack-package.pmdoc
OUTPUT_FILE=ack-${VERSION}.pkg

/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker \
  --doc ${INPUT_FILE} --out ${OUTPUT_FILE}
