FC = gfortran
FFLAGS = -m64 -O3 -I/usr/local/include
TARGET_ARCH =
LDFLAGS = -m64 -L/usr/local/lib
BLIBS = -lfortrangis -lfortranc -lgdal

EXE = loadraster

.SUFFIXES:

.SUFFIXES:.o.f90.plt

SRC = \
       main.f90 \

OBJECTS:=

OBJ = ${SRC:.f90=.o}

$(EXE): $(OBJ)
	$(FC) $(LDFLAGS) $(OBJ) $(BLIBS) -o $(EXE)

%.o : %.f90
	$(FC) $(FFLAGS) -c $<

clean:
	rm -f *.mod *~ core
	rm -f *.o
