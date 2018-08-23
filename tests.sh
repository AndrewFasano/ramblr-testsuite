#!/bin/bash

tests=0
fail=0
for i in {1..100}; do
    ./test.sh $i 
    res=$?
    tests=$(($tests + 1))
    fail=$(($fail +$res))
    echo "$fail failures of $tests total tests"
done
