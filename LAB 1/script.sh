#!/bin/bash

bison -d -o 22201358_22299105.tab.c 22201358_22299105.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o 22201358_22299105.tab.c
echo 'Generated the parser object file'
flex 22201358_22299105.l
echo 'Generated the scanner C file'
g++ -fpermissive -w -c -o l.o lex.yy.c
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -o parser.exe
echo 'All ready, running'
./parser.exe 22201358_22299105/input.txt