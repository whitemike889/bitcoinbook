#!/bin/bash

# Parse parameters
PARAMS=""

while (( "$#" )); do
  case "$1" in
    -v|--verbose)
      VERBOSE=0
      shift
      ;;
    -l|--lang)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        LANG=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"


# If unset, set language to English (en)
LANG=${LANG:-en}
echo Language: $LANG

#  Constants
DIR=_build
DIST=dist
BOOK=book
TAG=`git describe --tags --always`
TITLE=MasteringBitcoin2OE

RUBYDIR=/usr/lib/ruby/gems/2.4.0/gems/
ADOCFONTSDIR=/usr/lib/ruby/gems/*/gems/*/data/fonts/
TTFFONTSDIR=/usr/share/fonts/ttf-*/
ASCIIDOC_IMAGES=/etc/asciidoc/images
KINDLEGEN_PATH=/usr/bin/
KINDLEGEN_OPTS=-c2


clean () {
	if [ -d "${DIR}" ];
		then rm -r ${DIR};
	fi;
}


create_folder () {
	#  If the build directory does not exist, create it
	if [ ! -d "${DIR}" ]; then
		mkdir -p ${DIR};
		mkdir -p ${DIR}/fonts;
	fi;
	cp -v -R -u images/ ${DIR};
	cp -v images/cover*png ${DIR};
	cp -v -R -u code/ ${DIR};
	cp -v -u conf/* ${DIR};
}

copy_chapters () {
	cp -v -u *.asciidoc ${DIR}
	if [ -d "lang/${LANG}" ]; then
		for f in lang/${LANG}/*.txt; do
			name=$(basename $f .txt);
			cp -v lang/${LANG}/${name}.txt ${DIR}/${name}.asciidoc;
		done;
	fi;
}

copy_fonts () {
	echo Copying fonts
	cp -v -R -u ${TTFFONTSDIR}/*.ttf ${DIR}/fonts/
	cp -v -R -u ${ADOCFONTSDIR}/*.ttf ${DIR}/fonts/
}

compress_images () {
	cd ${DIR}/images;
	for f in *.png; do
		mogrify -verbose -depth 4 -colorspace gray -resize 504 $f;
	done;
}

grayscale_images () {
	cd ${DIR}/images;
	for f in *.png; do
		mogrify -verbose -depth 4 -colorspace gray $f;
	done;
}

create_dist () {
	if [ ! -d "${DIST}" ]; then
		mkdir ${DIST};
	fi;
	if [ ! -d "${DIST}/${LANG}" ]; then
		mkdir ${DIST}/${LANG};
	fi;
}

dist_pdf () {
	if [ -f "${DIR}/${BOOK}.pdf" ]; then
		cp ${DIR}/${BOOK}.pdf ${DIST}/${LANG}/${TITLE}_${LANG}_${TAG}.pdf;
	fi; 
}

case "$1" in
	pdf)
		echo "Building pdf"
		clean
		create_folder
		copy_fonts
		copy_chapters
		cd ${DIR}
		asciidoctor-pdf -a pdfbuild -r asciidoctor-mathematical ${BOOK}.asciidoc
		create_dist
		dist_pdf
		shift
		;;
	epub)
		echo "Building epub"
		shift
		;;
	mobi)
		echo "Building mobi"
		shift
		;;
	*)
		cat << _EOF_


Usage:

./build.sh [ -l | --lang xx ] pdf | epub | mobi

where
	xx is the 2 letter language code
	e.g. en for English, es for Spanish etc.

_EOF_
		exit 1
		;;
esac

exit 0
