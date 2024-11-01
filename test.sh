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
tar xvzf vbcc_unix_config.tar.gz -C vbcc

7z x vbcc_target_m68k-amigaos.lha vbcc_target_m68k-amigaos/targets
mv vbcc_target_m68k-amigaos/targets vbcc
rm -r vbcc_target_m68k-amigaos

7z x vbcc_target_m68k-kick13.lha vbcc_target_m68k-kick13/targets
mv vbcc_target_m68k-kick13/targets/m68k-kick13 vbcc/targets/m68k-kick13
rm -r vbcc_target_m68k-kick13

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

echo -e "\033[1;33m****** VASM ******\033[0m"
cd vasm && make CPU=m68k SYNTAX=mot -j 4 && cd -

echo -e "\033[1;33m****** VLINK ******\033[0m"
cd vlink && make -j 4 && cd -

echo -e "\033[1;33m****** VBCC ******\033[0m"
[[ "$OSTYPE" == "msys"* ]] && numcpu="1" || numcpu="4"
cd vbcc && make TARGET=m68k -j ${numcpu} && cd -

echo -e "\033[1;33m****** CREATE OUTPUT ******\033[0m"
[[ "$OSTYPE" == "darwin"* ]] && executable="+111" || executable="/111"
find vasm  -type f -perm ${executable} -exec cp {} vbcc/bin \;
find vlink -type f -perm ${executable} -exec cp {} vbcc/bin \;
mkdir -p build/vbcc
cp -r vbcc/bin     build/vbcc
cp -r vbcc/config  build/vbcc
cp -r vbcc/targets build/vbcc

if [[ "$OSTYPE" == "msys"* ]]; then
    sed -ie 's/$VBCC/%VBCC%/g' build/vbcc/config/*
fi

cat > hello.c << EOF
#include <stdio.h>

int main(int argc, const char** argv)
{
	printf("%s, %s\n", argv[0], argc > 1 ? argv[1] : "goodbye");
	return 0;
}
EOF

echo -e "\033[1;33m****** COMPILE ******\033[0m"
VBCC=$PWD/build/vbcc PATH=$VBCC/bin:$PATH vc +aos68k -vv hello.c -o hello

echo -e "\033[1;33m****** RUN ******\033[0m"
file hello
type vamos > /dev/null && vamos hello world

echo -e "\033[1;33m****** COMPILE (1.3) ******\033[0m"
VBCC=$PWD/build/vbcc PATH=$VBCC/bin:$PATH vc +kick13 -vv hello.c -o hello

echo -e "\033[1;33m****** RUN (1.3) ******\033[0m"
file hello
type vamos > /dev/null && vamos hello world

echo -e "\033[1;33m****** CLEANUP ******\033[0m"
rm -rf vasm vlink vbcc vbcc_target_m68k-amigaos hello.c hello

echo -e "\033[1;33m****** DONE ******\033[0m"
