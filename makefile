
PROG=njm_menu
LIB=../g2_lib
BASE=$(PWD)
TRG=../njm_app_bin

export DBNAME=njm_demo_db
export FJS_GL_DBGLEV=3
export CUSTOM_DB=../custom.json
export FGLIMAGEPATH=$(BASE):$(FGLDIR)/lib/image2font.txt
export FGLRESOURCEPATH=$(BASE)/etc
export FGLLDPATH=$(TRG):$(GREDIR)/lib

all: $(TRG)/$(PROG).42r

$(TRG)/$(PROG).42r: src/*.4gl src/*.per
	gsmake $(PROG).4pw

update:
	git pull

run: $(TRG)/$(PROG).42r
	cd $(TRG) && fglrun $(PROG).42r

clean:
	gsmake -c $(PROG).4pw
