#!/usr/bin/env python3

# --------------------------------------------------------------------------------------------------

import os

# --------------------------------------------------------------------------------------------------

def main():

    # Directories
    src = os.getcwd()
    dst = os.getenv('HOME')

    print(__file__)

    # Link things in directories
    # --------------------------
    srcdirs = ['bin', 'ssh']
    dstdirs = ['bin', '.ssh']

    for (srcdir, dstdir) in zip(srcdirs, dstdirs):
        print('Linking files for ', dstdir)
        fullsrcdir = os.path.join(src, srcdir)
        fulldstdir = os.path.join(dst, dstdir)
        if not os.path.exists(fulldstdir):
            os.makedirs(fulldstdir)
        for file in next(os.walk(fullsrcdir))[2]:
            srcfile = os.path.join(fullsrcdir, file)
            dstfile = os.path.join(fulldstdir, file)
            if os.path.exists(dstfile) or os.path.islink(dstfile):
                os.remove(dstfile)
            os.symlink(srcfile, dstfile)

    # Link dot files
    # --------------
    for srcfile in next(os.walk(src))[2]:
        if 'DS_Store' not in srcfile and 'link_files.py' not in srcfile:
            dstfile = os.path.join(dst, '.' + srcfile)
            if os.path.exists(dstfile) or os.path.islink(dstfile):
                os.remove(dstfile)
            print(src, os.path.join(src, srcfile), dstfile)
            os.symlink(os.path.join(src, srcfile), dstfile)

    # Link oh-my-zsh
    # --------------
    dstfile = os.path.join(dst, '.oh-my-zsh')
    if os.path.exists(dstfile) or os.path.islink(dstfile):
        os.remove(dstfile)
    os.symlink(os.path.join(src, 'oh-my-zsh'), dstfile)

# --------------------------------------------------------------------------------------------------

if __name__ == "__main__":
    main()

# --------------------------------------------------------------------------------------------------

