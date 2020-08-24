#  This makefile generates all the output files from the source Asciidoc files.

ifndef $(LANG)
	LANG = en
endif

#  Constants
DIR = _build
DIST = dist
BOOK = book
TAG = `git describe --tags --always`
TITLE = MasteringBitcoin2OE

RUBYDIR = /usr/lib/ruby/gems/2.4.0/gems/
ADOCFONTSDIR = /usr/lib/ruby/gems/*/gems/*/data/fonts/
TTFFONTSDIR = /usr/share/fonts/ttf-*/
ASCIIDOC_IMAGES = /etc/asciidoc/images

KINDLEGEN_PATH = /usr/bin/
KINDLEGEN_OPTS = -c2

#  ---------------------------------
#  Public targets

all: pdf epub kindle
	# Usage
	# make [LANG=xx] {pdf, epub, kindle}

pdf: clean create_pdf dist_pdf

epub: clean create_epub dist_epub

kindle: epub create_kindle dist_kindle

html: clean compress_images create_html

docker-build:
	export PWD=`pwd`
	docker image build ${PWD} -t bookbuilder

docker-run:
	export PWD=`pwd`
	docker run -it -v ${PWD}:/documents/ bookbuilder

tx-pull:
	tx pull -l ${LANG}

#  ---------------------------------
#  Private targets

# Cleanup
clean:
	if [ -d "${DIR}" ]; \
		then rm -r ${DIR}; \
	fi; \


#  If the build directory does not exist, create it
create_folder:
	if [ ! -d "${DIR}" ]; then \
		mkdir ${DIR}; \
	fi; \
	cp -v -u -R -L ${ASCIIDOC_IMAGES} ${DIR}; \
	cp -v -R -u images/ ${DIR}; \
	cp -v -R -u code/ ${DIR}; \
	cp -v -u conf/* ${DIR};
	if [ -d "lang/${LANG}" ]; then \
		for f in lang/${LANG}/*.txt; do \
			name=$$(basename $f .txt); \
			cp -v lang/${LANG}/${name}.txt ${DIR}/${name}.asciidoc; \
		done; \
	fi; \




copy_fonts:
	find ${TTFFONTSDIR} -name *ttf -exec cp -u {} ${DIR} \;
	find ${ADOCFONTSDIR} -name *ttf -exec cp -u {} ${DIR} \;

copy_kindlegen:
	cp -u ${KINDLEGEN_PATH}/kindlegen ${DIR}; \

compress_images: create_folder
	cd ${DIR}; \
	for f in *.png; \
#		do mogrify -verbose -depth 4 -colorspace gray -resize 504 "$$f"; \
		do mogrify -verbose -depth 4 -colorspace gray "$$f"; \
	done; \


#  Generate PDF
create_pdf: create_folder copy_fonts
	cd ${DIR}; \
	asciidoctor-pdf -a pdfbuild -r asciidoctor-mathematical ${BOOK}.asciidoc; \

#  Generate EPUB
create_epub: create_folder copy_fonts
	cd ${DIR}; \
	asciidoctor-epub3 -a ebookbuild -r asciidoctor-mathematical  ${BOOK}.asciidoc; \

#  Create Kindle version (ignoring the error that it outputs)
create_kindle: create_epub
	if [ -d "${KINDLEGEN_PATH}" ]; then \
		${KINDLEGEN_PATH}/kindlegen ${KINDLEGEN_OPTS} ${DIR}/${BOOK}.epub; \
	fi; \

create_dist:
	if [ ! -d "${DIST}" ]; then \
		mkdir ${DIST}; \
	fi; \
	if [ ! -d "${DIST}/${LANG}" ]; then \
		mkdir ${DIST}/${LANG}; \
	fi; \

dist_pdf: create_dist
	if [ -f "${DIR}/${BOOK}.pdf" ]; then \
		cp ${DIR}/${BOOK}.pdf ${DIST}/${LANG}/${TITLE}_${LANG}_${TAG}.pdf; \
	fi; \

dist_epub: create_epub create_dist
	if [ -f "${DIR}/${BOOK}.epub" ]; then \
		cp ${DIR}/${BOOK}.epub ${DIST}/${LANG}/${TITLE}_${LANG}_${TAG}.epub; \
	fi; \

dist_kindle: create_kindle create_dist
	if [ -f "${DIR}/${BOOK}.mobi" ]; then \
		cp ${DIR}/${BOOK}.mobi ${DIST}/${LANG}/${TITLE}_${LANG}_${TAG}.mobi; \
	fi; \
