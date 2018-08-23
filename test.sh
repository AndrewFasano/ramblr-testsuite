#!/bin/bash

# Reassembablable disassembly test suite.
# Run workon angr first
# First argument defines csmith random seed, otherwise select at random

#set -x

# Keep the programs fairly simple
flags="--no-argc --no-arrays --no-bitfields --no-comma-operators --no-compound-assignment --concise --no-consts --no-divs --no-embedded-assigns --no-pre-incr-operator --no-post-incr-operator --no-post-decr-operator --no-unary-plus-operator --no-jumps --no-longlong --no-int8 --no-uint8 --no-float --no-math64 --no-inline-function --no-packed-struct --paranoid --no-structs --no-unions --no-volatiles --no-volatile-pointers --no-const-pointers"
flags="$flags --max-expr-complexity 2 --max-funcs 1 --max-pointer-depth 1 --max-struct-fields 1" # Parameterizable options

if [[ $# -eq 1 ]]; then
    seed=$1
else
    seed=$((1 + RANDOM % 1000000000))
fi

if [ ! -d "csmith" ]; then
    echo "You need to build csmith!"
    echo "Start with: git clone https://github.com/csmith-project/csmith.git"
    exit 1
fi

base="data/$seed/"
mkdir -p $base

# Generate a random program
source_file="$base/01_input.c"
csmith $flags -s $seed > $source_file
#echo "Source code at $source_file"

# Compile it
out_file="$base/02_output"
arm-linux-gnueabi-gcc -g -Icsmith/runtime -w $source_file -o $out_file

arm-linux-gnueabi-gcc -g -S -Icsmith/runtime -w $source_file -o $out_file.s

# Get checksum
cksum_orig=`qemu-arm-static -L /usr/arm-linux-gnueabi $out_file`
#echo "Got original: $cksum_orig"

# Ramblr program
ramblr_out="$base/00_ramblr.stdout"
./reassemble.py $out_file armel32 > $ramblr_out 2>&1 
source_file2=$(cat $ramblr_out | tail -n 1)
echo "Ramblr exited with $?"
if [ -z "$source_file2" ]; then
    echo "RAMBLR failed to generate asm";
    echo "Fail $seed"; 
    echo -e "$seed\tFAIL\tramblr fail" >> ./results.txt
    exit 1
fi
if [ -f "$source_file2" ]; then
    cp $source_file2 "$base/03_ramblr.s"
else
    echo "RAMBLR failed to generate asm";
    echo "Fail $seed"; 
    echo -e "$seed\tFAIL\tramblr error" >> ./results.txt
    exit 1
fi;

# Assemble it
out_file2="$base/04_ramblr_out"
out_errs="$base/00_gcc_rew.stdout"
#echo "Assemble $source_file"
#set -x
arm-linux-gnueabi-gcc -gstabs+ -masm-syntax-unified -ffunction-sections -mcpu=cortex-a8 -g $source_file2 -o $out_file2 >$out_errs 2>&1
#set +x
if [ ! -f $out_file2 ]; then
    echo "Failed to assemble RAMBLR asm";
    echo "Fail $seed"; 
    echo -e "$seed\tFAIL\tbad ramblr assembly" >> ./results.txt
    exit 2
fi;

cksum_new=`qemu-arm-static -L /usr/arm-linux-gnueabi $out_file2`
#echo "Seed=$seed"
#echo "Original $cksum_orig"
#echo "---------------------------"
#echo "     New $cksum_new"

if [ "$cksum_orig" = "$cksum_new" ]; then
    echo "Pass $seed";
    echo -e "$seed\tPASS\tchecksum match" >> ./results.txt
    exit 0
else
    echo "Fail $seed";
    echo -e "$seed\tFAIL\tchecksum mismatch" >> ./results.txt
    exit 1
fi

# Get checksum
