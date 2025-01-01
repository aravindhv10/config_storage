#!/bin/sh
gcc -Ofast -mtune=native -march=native -static ./main.c -o main.exe
