#!/usr/bin/env python3

# --------------------------------------------------------------------------------------------------

import os

# --------------------------------------------------------------------------------------------------

def directory_loop(total_count):

    directories = next(os.walk('./'))[1]

    for directory in directories:

        os.chdir(directory)
        number_of_files = next(os.walk('./'))[2]
        if number_of_files:
            print(str(len(number_of_files)).ljust(5), ' files in ', os.getcwd())
            total_count = total_count + len(number_of_files)
        total_count = directory_loop(total_count)

    os.chdir('..')
    return total_count


# --------------------------------------------------------------------------------------------------

def main():

    # Count files in starting directory
    total_count = len(next(os.walk('./'))[2])

    # Iterate through sub directories to count files
    total_count = directory_loop(total_count)

    # Print total
    print('\nTotal number of files: ', total_count, '\n')

# --------------------------------------------------------------------------------------------------

if __name__ == "__main__":
    main()

# --------------------------------------------------------------------------------------------------

