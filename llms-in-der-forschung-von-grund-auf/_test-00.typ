// Testdatei: kompiliert nur ein Kapitel im Buchlayout.
// typst compile --font-path fonts _test-00.typ /pfad/zum/scratch/test-00.pdf
#import "layout.typ": *
#show: layout
#include "kap00-vorwort.typ"
#include "literatur.typ"
