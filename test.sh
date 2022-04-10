#!/bin/bash

# wget http://phoenix.owl.de/tags/vbcc0_9g.tar.gz
# wget http://phoenix.owl.de/vbcc/2019-10-04/vbcc_target_m68k-amigaos.lha
# wget http://sun.hasenbraten.de/vlink/release/vlink.tar.gz
# wget http://sun.hasenbraten.de/vasm/release/vasm.tar.gz

# we need tar, 7z, patch, gcc, vamos ...

set -e

echo -e "\033[1;33m****** UNPACK ******\033[0m"
tar xvzf vasm.tar.gz
tar xvzf vlink.tar.gz
tar xvzf vbcc.tar.gz

7z x vbcc_target_m68k-amigaos.lha vbcc_target_m68k-amigaos/targets
mv vbcc_target_m68k-amigaos/targets vbcc
rm -r vbcc_target_m68k-amigaos

patch -p 0 << EOF
diff -rupN vbcc/datatypes/dtgen.c vbcc.patch/datatypes/dtgen.c
--- vbcc/datatypes/dtgen.c	2013-04-24 00:45:50 +0200
+++ vbcc.patch/datatypes/dtgen.c	2020-01-01 21:11:42 +0100
@@ -133,8 +133,7 @@ int askyn(char *def)
   do{
     printf("Type y or n [%s]: ",def);
     fflush(stdout);
-    fgets(in,sizeof(in),stdin);
-    if(*in=='\n') strcpy(in,def);
+    strcpy(in,def);
   }while(*in!='y'&&*in!='n');
   return *in=='y';
 }
@@ -144,9 +143,7 @@ char *asktype(char *def)
   char *in=mymalloc(128);
   printf("Enter that type[%s]: ",def);
   fflush(stdout);
-  fgets(in,127,stdin);
-  if(in[strlen(in)-1]=='\n') in[strlen(in)-1]=0;
-  if(!*in) strcpy(in,def);
+  strcpy(in,def);
   return in;
 }
EOF

mkdir -p vbcc/bin
mkdir -p vbcc/config

cat > vbcc/config/vc.config << EOF
-cc=vbccm68k -quiet -hunkdebug %s -o= %s %s -O=%ld -I\$VBCC/targets/m68k-amigaos/include/
-ccv=vbccm68k -hunkdebug %s -o= %s %s -O=%ld -I\$VBCC/targets/m68k-amigaos/include/
-as=vasmm68k_mot -quiet -Fhunk -nowarn=62 %s -o %s
-asv=vasmm68k_mot -Fhunk -nowarn=62 %s -o %s
-rm=rm %s
-rmv=rm %s
-ld=vlink -bamigahunk -x -Bstatic -Cvbcc -nostdlib -mrel \$VBCC/targets/m68k-amigaos/lib/startup.o %s %s -L\$VBCC/targets/m68k-amigaos/lib/ -lvc -lamiga -o %s
-l2=vlink -bamigahunk -x -Bstatic -Cvbcc -nostdlib -mrel %s %s -L\$VBCC/targets/m68k-amigaos/lib/ -o %s
-ldv=vlink -bamigahunk -t -x -Bstatic -Cvbcc -nostdlib -mrel \$VBCC/targets/m68k-amigaos/lib/startup.o %s %s -L\$VBCC/targets/m68k-amigaos/lib/ -lvc -o %s
-l2v=vlink -bamigahunk -t -x -Bstatic -Cvbcc -nostdlib -mrel %s %s -L\$VBCC/targets/m68k-amigaos/lib/ -o %s
-ldnodb=-s -Rshort
-ul=-l%s
-cf=-F%s
-ml=500
EOF

echo -e "\033[1;33m****** VASM ******\033[0m"
cd vasm && make CPU=m68k SYNTAX=mot -j 4 && cd -

echo -e "\033[1;33m****** VLINK ******\033[0m"
cd vlink && make -j 4 && cd -

echo -e "\033[1;33m****** VBCC ******\033[0m"
cd vbcc && make TARGET=m68k -j 4 && cd -

cat > hello.c << EOF
#include <stdio.h>

int main(int argc, const char** argv)
{
	printf("%s, %s\n", argv[0], argc > 1 ? argv[1] : "goodbye");
	return 0;
}
EOF

echo -e "\033[1;33m****** COMPILE ******\033[0m"
VBCC=$PWD/vbcc PATH=$PATH:$PWD/vbcc/bin:$PWD/vasm:$PWD/vlink vc -vv hello.c -o hello

echo -e "\033[1;33m****** RUN ******\033[0m"
vamos hello world

echo -e "\033[1;33m****** CLEANUP ******\033[0m"
rm -rf vasm vlink vbcc vbcc_target_m68k-amigaos hello.c hello

echo -e "\033[1;33m****** DONE ******\033[0m"
