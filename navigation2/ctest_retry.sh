#!/bin/bash

fail=0
total=$1
# Change the file path manually to where you want to log fails
echo "Retrying Ctest up to " $total " times."
for ((i=1;i<=total;i++))
  do
    ctest
    result=$?
    if [ "$result" == "0" ]
    then
      echo "Test succeeded on try " $i
      ((fail++))
    fi
  done
echo "Test failed " $((total-fail)) " times."
echo "Run Ctest : " $total "succeed :" "$fail"
echo "Run Ctest " $total "succeed " "$fail" > Ctest_retry.log
