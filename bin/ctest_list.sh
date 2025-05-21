#!/bin/bash

# Check if at least one argument is passed
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 test_number1 [test_number2 ... test_numberN]"
  exit 1
fi

# Loop through each argument and run the ctest command
for test_number in "$@"; do
  echo "Running ctest for test number: $test_number"
  ctest -I "$test_number,$test_number"
done
