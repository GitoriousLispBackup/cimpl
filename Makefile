## sysdef options ##
TITLE=Adamas-C
VERSION=0.0.0
CREATOR=univ:greyknight3@yahoo.com/2000
IDENT=adamas-c.app
ABSTRACT=A basic Adamas implementation in C.
REQUIRES=-lm
SOURCES=sources/adamas.c
FINAL=binaries/Adamas-C
ENTRYPOINT=main
## end sysdef options ##

OBJECTS:=$(SOURCES:.c=.o)
OBJECTS:=$(shell echo '${OBJECTS}' | sed -e 's/sources/binaries/g')
CC=gcc
CFLAGS=-g -Wall -W
LDFLAGS=
MACROS=-DTITLE='"${TITLE}"' -DVERSION='"${VERSION}"' -DCREATOR='"${CREATOR}"' -DIDENT='"${IDENT}"'

all: $(FINAL)
$(FINAL): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS) $(REQUIRES)

clean:
	-rm binaries/*.o
	-rm $(FINAL)

spotless: clean
	-rm sources/*~

## dependency map ##
sources/adamas.c: sources/adamas.h
## end dependency map ##

.SUFFIXES:

binaries/%.o: sources/%.c
	$(CC) $(CFLAGS) $(MACROS) -c -o $@ $<
