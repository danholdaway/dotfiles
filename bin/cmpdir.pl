#!/usr/bin/env perl
#=======================================================================
# name - cmpdir
# purpose - this utility allows users to quickly and easily see
#           differences between files in two experiment directories.
#
# Note:
# 1. See usage subroutine for usage information
# 2. This script uses the xxdiff utility
#
# !Revision History
# 29Mar2010  Stassi  Initial version.
#=======================================================================
use strict;
use warnings;

# global variables
#-----------------
my ($debug, $ext, $fileID, $list, $listx, @p1, @p2);
my ($quiet, $recurse, $subdir, $verbose, @exclude);
my (%diffsTXT, %diffsBIN, %different, $bwiFLG, $diffFLGs);
my (%found, @notfound1, @notfound2, %identical);
my ($dirA, $dirB, $dir1, $dir2, $dirL1, $dirL2);
my (@files, @files1, @files2, $first);
my (@subdirs, %dir_display);

# main program
#-------------
{
    init();
    while (1) {
        cmp_files();
        show_results();
    }
}

#=======================================================================
# name - init
# purpose  - get input parameters and initialize global variables
#=======================================================================
sub init {
    use File::Basename;
    use Getopt::Long;
    my ($bwiFLG, $help, %patterns, $rsflg, $runflg, $subdirname);

    # get runtime flags
    #------------------
    GetOptions("bwi"      => \$bwiFLG,
               "db|debug" => \$debug,
               "ext=s"    => \$ext,
               "id=s"     => \$fileID,
               "h|help"   => \$help,
               "list"     => \$list,
               "listx"    => \$listx,
               "p=s"      => \%patterns,
               "p1=s"     => \@p1,
               "p2=s"     => \@p2,
               "q"        => \$quiet,
               "rs"       => \$rsflg,
               "r"        => \$recurse,
               "run"      => \$runflg,
               "subdir=s" => \$subdir,
               "v"        => \$verbose,
               "X=s"      => \@exclude );
    usage() if $help;
    $list = 1 if $listx;

    # shortcuts for checking run or rs directory 
    #-------------------------------------------
    if ($runflg) { $subdir = "run"; $recurse = 1 }
    if ($rsflg)  { $subdir = "rs"; $ext = "bin" unless $ext }

    # runtime parameters
    #-------------------
    $dirA  = shift @ARGV;
    $dirB  = shift @ARGV;

    # check inputs
    #-------------
    usage() unless $dirA and $dirB;
    die ">> Error << Cannot find directory $dirA" unless -d $dirA;
    die ">> Error << Cannot find directory $dirB" unless -d $dirB;

    # remove final slash from directory name
    #---------------------------------------
    $dirA = cleanDirName($dirA, 1);
    $dirB = cleanDirName($dirB, 1);

    # add user inputted patterns to pattern arrays
    #---------------------------------------------
    foreach (keys %patterns) {
        push @p1, $_;
        push @p2, $patterns{$_};
    }

    # add directory basenames to pattern arrays
    #------------------------------------------
    push @p1, basename $dirA;
    push @p2, basename $dirB;

    # check for @p1/@p2 correspondence
    #---------------------------------
    die ">> Error << unequal number of patterns (-p1/-p2)"
        unless scalar(@p1) == scalar(@p2);

    # find common subdirectories
    #---------------------------
    foreach (<$dirA/*>) {
        next unless -d $_;
        $subdirname = basename $_;
        push @subdirs, $subdirname if -d "$dirB/$subdirname";
        next;
    }

    # check for requested subdirectory
    #---------------------------------
    if ($subdir) {
        die "not found: $dirA/$subdir\n" unless -d "$dirA/$subdir";
        die "not found: $dirB/$subdir\n" unless -d "$dirB/$subdir";
    }

    # initialize other variables
    #---------------------------
    $first = 1;
    if ($bwiFLG) { $diffFLGs = "-bwi" }
    else         { $diffFLGs = ""     }
}

#=======================================================================
# name - cmp_files
# purpose - get list of files from both directories and compare files
#           to find those which are the same in both directories, those
#           which are not, and those which are in only one directory or
#           the other.
#=======================================================================
sub cmp_files {
    use File::Basename ("basename", "dirname");
    use File::Find ("find");

    my ($file1, $file2, $base1, $base2, $dirname1, $dirname2, $middir);
    my ($maxK, $maxV, $fmt1, $fmt2);
    my ($status, $indexB, $indexT);

    # get directories
    #----------------
    $dir1 = $dirA;
    $dir2 = $dirB;
    $dirL1 = basename $dir1;
    $dirL2 = basename $dir2;

    if ($subdir) {
        $dir1  .= "/$subdir";
        $dir2  .= "/$subdir";
        $dirL1 .= "/$subdir";
        $dirL2 .= "/$subdir";
    }

    # comparing list of files in directories only
    #--------------------------------------------
    if ($list) { cmp_lists($dir1, $dir2); return }

    # get file lists
    #---------------
    if ($ext) {
        chomp( @files1 = (`find $dir1 -name \\*\.$ext`) );
        chomp( @files2 = (`find $dir2 -name \\*\.$ext`) );
    }
    elsif ($fileID) {
        $fileID =~ s/\./\\\./;
        chomp( @files1 = (`find $dir1 -name \\*$fileID\\*`) );
        chomp( @files2 = (`find $dir2 -name \\*$fileID\\*`) );
    }
    else {
        if ($recurse) {
            chomp( @files1 = (`find $dir1 -name \\*`) );
            chomp( @files2 = (`find $dir2 -name \\*`) );
        }
        else {
            @files1 = ( <$dir1/*> );
            @files2 = ( <$dir2/*> );
        }
    }

    # remove directories from file list
    #----------------------------------
    for (0..$#files1) {
        $file1 = shift @files1;
        push @files1, $file1 unless -d $file1;
    }
    for (0..$#files2) {
        $file2 = shift @files2;
        push @files2, $file2 unless -d $file2;
    }
    show_file_counts(1);
    find_common_label(\@files1, \@files2);
    if ($debug) {
        foreach (0..$#p1) { print "p1/p2 = $p1[$_]/$p2[$_]\n" };
        print "<cr> to continue ... "; my $dummy = <STDIN>;
    }

    # zero-out lists
    #---------------
    %diffsBIN = ();
    %diffsTXT = ();
    %different = ();
    %identical = ();
    @notfound1 = ();
    @notfound2 = ();
    %found = ();

    # which files are in both expdir1 and expdir2?
    #---------------------------------------------
    foreach $file1 (@files1) {

        $base1 = basename $file1;
        next if Xcluded($base1);

        $dirname1 = dirname $file1;
        $middir = "";
        $middir = $1 if ($dirname1 =~ m[^$dir1/(\S+)]);
        print "(1) checking $file1\n" if $verbose;

        if ($middir) { $file2 = namechange("$dir2/$middir/$base1", "1") }
        else         { $file2 = namechange("$dir2/$base1", "1")         }
        print "(2) checking $file2\n\n" if $verbose;

        if (-e $file2) { $found{$file1} = display($file2,2) }
        else           { push @notfound2, display($file1,1) }
    }

    # send job to dmget files (just in case)
    #---------------------------------------
    dmget(1, keys %found);
    dmget(2, values %found);

    # compare files found in both directories
    #----------------------------------------
    $maxK = 0; $maxV = 0;
    foreach (keys   %found) { $maxK = baselen($_) if baselen($_) > $maxK }
    foreach (values %found) { $maxV = baselen($_) if baselen($_) > $maxV }
    $fmt1 = "checking %s\n";
    $fmt2 = "checking %-${maxK}s <=> %-${maxV}s\n";

    foreach $file1 (sort keys %found) {
        $file2 = $found{$file1};
        $base1 = basename $file1;
        $base2 = basename $file2;
        unless ($quiet) {
            if ($base1 eq $base2) { printf $fmt1, $base1         }
            else                  { printf $fmt2, $base1, $base2 }
        }

        ($status = system "diff $diffFLGs $file1 $file2 >& /dev/null") /= 256;
        unless ($status) {
            $identical{$file1} = $file2;
            next;
        }

        # files are different
        #--------------------
        $different{$file1} = $file2;
        if ( binary($file1, $file2) ) { $diffsBIN{++$indexB} = $file1 }
        else                          { $diffsTXT{++$indexT} = $file1 }
    }

    # compare dir2 files to dir1
    #---------------------------
    foreach $file2 (@files2) {

        # check corresponding file in dir1
        #---------------------------------
        $base2 = basename $file2;
        next if Xcluded($base2);

        $dirname2 = dirname $file2;
        $middir = "";
        $middir = $1 if ($dirname2 =~ m[^$dir2/(\S+)]);
        print "(2) checking $file2\n" if $verbose;

        $file1 = namechange("$dir1/$middir/$base2", "2");
        $base1 = basename $file1;
        print "(1) checking $file1\n\n" if $verbose;
        unless (-e $file1) { push @notfound1, display($file2,2); next }
    }
}

#=======================================================================
# name - cmp_lists
# purpose - compare lists of files in $dir1 and $dir2
#=======================================================================
sub cmp_lists {
    my ($HOME, $list1, $list2);
    my (@filearr1, @filearr2, $cnt, $name);
    my ($expid1, $expid2);

    # make list of files in $dir1
    #----------------------------
    print "\n(1) making list of files in $dir1\n";
    @files = ();
    find(\&wanted, $dir1);
    @filearr1 = sort @files;
    $expid1 = getexpid(@filearr1);

    # make list of files in $dir2
    #----------------------------
    print "(2) making list of files in $dir2\n";
    @files = ();
    find(\&wanted, $dir2);
    @filearr2 = sort @files;
    $expid2 = getexpid(@filearr2);

    # ignore $dir1/dir2 name differences
    #-----------------------------------
    if ($listx) {
        if ($dir1 =~ /$dir2/) {
            $cnt = scalar(@filearr2);
            for (1..$cnt) {
                $name = shift @filearr2;
                $name =~ s/$dir2/$dir1/;
                $name =~ s/\b$expid2\b/$expid1/g if $expid1 and $expid2;
                push @filearr2, $name;
            }
        }
        else {
            $cnt = scalar(@filearr1);
            for (1..$cnt) {
                $name = shift @filearr1;
                $name =~ s/$dir1/$dir2/;
                $name =~ s/\b$expid1\b/$expid2/g if $expid1 and $expid2;
                push @filearr1, $name;
            }
        }
    }
            
    # dump lists to files
    #--------------------
    $HOME = $ENV{"HOME"};
    $list1 = "$HOME/cmpdir_list1_" .basename($dir1);
    $list2 = "$HOME/cmpdir_list2_" .basename($dir2);

    listdump(\@filearr1, $list1, dirname($dir1)."/");
    print "\n(1) list written: $list1\n";

    listdump(\@filearr2, $list2, dirname($dir2)."/");
    print "(2) list written: $list2\n\n";
        
    # set up global arrays and hashes to show differences in list files
    #------------------------------------------------------------------
    @files1 = ( $list1 );
    @files2 = ( $list2 );
    $found{$list1} = $list2;
    $different{$list1} = $list2;
    $diffsTXT{"1"} = $list1;
    $diffFLGs = "-bwi";

    return;
}

#=======================================================================
# name - find_common_label
# purpose - check the file names to see if the files have a common label.
#           if so, then add labels to pattern arrays, if not already present.
#
# input parameters
# => $arr1ADDR: address of 1st array of filenames
# => $arr1ADDR: address of 2nd array of filenames
#=======================================================================
sub find_common_label {
    my ($arr1ADDR, $arr2ADDR, @arr1, @arr2);
    my ($base, @parts, %L1, %L2);
    my ($max, $labelone, $labeltwo);

    $arr1ADDR = shift @_;
    $arr2ADDR = shift @_;
    @arr1 = @$arr1ADDR;
    @arr2 = @$arr2ADDR;

    # get labels from files in each array
    #------------------------------------
    foreach (@arr1) {
        $base = basename $_;
        @parts = split /[.]/, $base;
        ++$L1{$parts[0]} if scalar(@parts) > 1;
    }
    foreach (@arr2) {
        $base = basename $_;
        @parts = split /[.]/, $base;
        ++$L2{$parts[0]} if scalar(@parts) > 1;
    }
    
    # find most common label in each array
    #-------------------------------------
    $max = 0; $labelone = "";
    foreach (keys %L1) {
        if ($L1{$_} > $max) { $labelone = $_; $max = $L1{$_} }
    }
    return unless $max*2 > @arr1;

    $max = 0; $labeltwo = "";
    foreach (keys %L2) {
        if ($L2{$_} > $max) { $labeltwo = $_; $max = $L2{$_} }
    }
    return unless $max*2 > @arr2;

    # add labels to pattern arrays if appropriate
    #--------------------------------------------
    if ($labelone ne $labeltwo) {
        return if in($labelone, @p1);
        return if in($labeltwo, @p2);
        push @p1, $labelone;
        push @p2, $labeltwo;
    }
    return;
}

#=======================================================================
# name - show_results
# purpose - give menu option for user to view results of comparison
#           between two directories
#=======================================================================
sub show_results {
    my ($opt, $dflt);

    $opt  = "";
    $dflt = 1;
    unless (@files1 and @files2) {
        if ($ext) { print "No .$ext files found.\n\n"; exit }
        else      { $dflt = 6 }
    }
    unless (%found) {
        if ($ext)  { print "No common .$ext files were found.\n\n" }
        else       { print "No common files were found.\n\n" }
        exit;
    }
    if ($list) {
        display_text_diffs(1);
        foreach (keys %different) {
            unlink $_;
            unlink $different{$_};
            print "unlink $_\n";
            print "unlink $different{$_}\n";
        }
        exit;
    }

    while (1) {
        unless ($first and $dflt == 6) {
            underline("Make Selection",2);
            print " 1. differences\n"
                . " 2. identical\n"
                . " 3. not found\n\n"
                . " 4. file counts\n"
                . " 5. file lists\n";
            print " 6. choose (other) subdirectory\n" unless $ext;
            print "\n"
                . " 0. quit\n\n"
                . "choose option: [$dflt] ";

            chomp($opt = <STDIN>);
        }
        $opt = $dflt if $opt =~ /^\s*$/;
        exit unless $opt;

        $first = 0;
        if ($opt > 2) { $dflt = 0 }
        else          { $dflt = $opt + 1 }

        if ($opt eq "1") { show_differences(); next }
        if ($opt eq "2") { show_identical();   next }
        if ($opt eq "3") { show_notfound();    next }
        if ($opt eq "4") { show_file_counts(); next }
        if ($opt eq "5") { list_files();       next }
        unless ($ext) {
            if ($opt eq "6") { choose_subdir();  return }
        }
        print "\n$opt: Invalid option; Try again.\n\n";
    }
}

#=======================================================================
# name - show differences
# purpose - print summary list of files which differ; give user option
#           to view differences in specific files using xxdiff utility
#=======================================================================
sub show_differences {
    use File::Basename;

    unless (%diffsBIN or %diffsTXT) {
        print "\nNo differences found.\n";
        pause();
        return;
    }
    show_binary_diffs() if %diffsBIN;
    show_text_diffs()   if %diffsTXT;
}

#=======================================================================
# name - show_binary_diffs
# purpose - 
#=======================================================================
sub show_binary_diffs {
    use File::Basename;
    my ($maxB, $fmt1, $fmtB, $num, $show_menu);
    my ($file1, $base1, $base2, $dflt, $sel);

    $maxB = 0;
    foreach (values %diffsBIN) { $maxB = baselen($_) if baselen($_) > $maxB }

    $fmt1 = "%3s. %s\n";
    $fmtB = "%3s. %-${maxB}s <=> %-s\n";

    $num = 1;
    $show_menu = 1;
    while (1) {

        if ($show_menu) {

            # select file to do h5diff
            #-------------------------
            $num--;
            underline("These binary files differ") if %diffsBIN;
            foreach (sort numeric keys %diffsBIN) {
                $file1 = $diffsBIN{$_};
                $base1 = mybase($file1, "1");
                $base2 = mybase($different{$file1}, "2");

                if ($base1 eq $base2) { printf $fmt1, $_, $base1 }
                else                  { printf $fmtB, $_, $base1, $base2 }
            }
        }
        print "\n";
        printf $fmt1, "0", "previous menu";
        printf $fmt1, "-1", "refresh menu\n";

        $show_menu = 0;
        $dflt = ++$num;
        while ($dflt) {
            unless ( $diffsBIN{$dflt} ) { $dflt = 0; last }
            last if $diffsBIN{$dflt} =~ /\.nc4$/;
            $dflt++;
        }

        print "Show h5diff: [$dflt] ";
        chomp( $sel = <STDIN> ); $sel = $dflt unless $sel =~ /\S+/;

        if ($sel ==  0) { return }
        if ($sel == -1) { $show_menu = 1; next }
            
        # show selected h5diff
        #---------------------
        $num = $sel;
        unless ($diffsBIN{$num}) {
            print "Selection not found: $num\n"
                . "Try again.\n";
            $num = --$dflt;
            next;
        }
        show_h5diff($num);
    }
}

#=======================================================================
# name - show_h5diff
# purpose - show h5diff comparison of two text files
#
# input parameters
# => $num: index number of difference to display (starting at 1)
#=======================================================================
sub show_h5diff {
    use File::Basename ("basename");
    my ($num, $file1, $file2, $base1, $base2, $status);
    $num = shift @_;

    $file1 = $diffsBIN{$num};
    $file2 = $different{$file1};
    $base1 = mybase($file1, "1");
    $base2 = mybase($file2, "2");

    if ($base1 eq $base2) {
        printf "checking h5diff (%d) %s\n", $num, $base1;
    } else {
        printf "checking h5diff (%d) %s <=> %s\n", $num, $base1, $base2;
    }
    $status = system "h5diff $file1 $file2";
    if ($status ) { print "FILES DIFFER\n" }
    else          { print "FILES MATCH\n"  }
}

#=======================================================================
# name - show_text_diffs
# purpose - show text differences
#=======================================================================
sub show_text_diffs {
    use File::Basename;
    my ($maxT, $fmt0, $fmt1, $fmtT, $num);
    my ($file1, $base1, $base2, $dflt, $sel);

    $maxT = 0;
    foreach (values %diffsTXT) { $maxT = baselen($_) if baselen($_) > $maxT }

    $fmt0 = "%3s. %s";
    $fmt1 = "%3s. %s\n";
    $fmtT = "%3s. %-${maxT}s <=> %-s\n";

    return unless %diffsTXT;
    $num = 0;
    while (1) {
        
        # select which file to show differences
        #--------------------------------------
        underline("These text files differ");
        foreach (sort numeric keys %diffsTXT) {
            $file1 = $diffsTXT{$_};
            $base1 = basename $file1;
            $base2 = basename $different{$file1};

            if ($base1 eq $base2) { printf $fmt1, $_, $base1 }
            else                  { printf $fmtT, $_, $base1, $base2 }
        }
        $dflt = ++$num;
        $dflt = 0 unless $diffsTXT{$dflt};

        print "\n";
        printf $fmt1, "0", "previous menu";
        if (keys %diffsTXT > 1) {
            printf $fmt0, "a", "cycle thru all";
            if ($dflt) { print " (starting from $dflt)\n" } else { print "\n" }
            if ($diffFLGs) { printf $fmt1, "b", "toggle -bwi flag OFF\n" }
            else           { printf $fmt1, "b", "toggle -bwi flag ON\n"  }
        }
        print "Make Selection: [$dflt] ";
        chomp( $sel = <STDIN> ); $sel = $dflt unless $sel =~ /\S+/;

        return if $sel eq "0";

        # show differences for all remaining files starting with current index
        #---------------------------------------------------------------------
        if ($sel eq "a") {
            $num = 1 unless $diffsTXT{$num};
            while ($diffsTXT{$num}) {
                display_text_diffs($num);
                $num++;
            }
            $num = -1; next;
        }

        # toggle -bwi flag
        #-----------------
        if ($sel eq "b") {
            $bwiFLG = ! $bwiFLG;
            if ($diffFLGs) { $diffFLGs = ""     }
            else           { $diffFLGs = "-bwi" }
            $num -= 2; $num = 0 if $num < 0; next;
        }

        # show selected difference
        #-------------------------
        $num = $sel;
        unless ($diffsTXT{$num}) {
            print "Selection not found: $num\n"
                . "Try again.\n";
            $num = --$dflt;
            next;
        }
        display_text_diffs($num);
    }
}

#=======================================================================
# name - display_text_diffs
# purpose - display the xxdiff of two text files
#
# input parameters
# => $num: index number of difference to display (starting at 1)
#=======================================================================
sub display_text_diffs {
    use File::Basename ("basename");
    my ($num, $file1, $file2, $base1, $base2);
    $num = shift @_;

    $file1 = $diffsTXT{$num};
    $file2 = $different{$file1};
    $base1 = basename $file1;
    $base2 = basename $file2;

    if ($base1 eq $base2) {
        printf "showing diffs for (%d) %s\n", $num, $base1;
    } else {
        printf "showing diffs for (%d) %s <=> %s\n", $num, $base1, $base2;
    }
    system "xxdiff $diffFLGs $file1 $file2";
}

#=======================================================================
# name - show_identical
# purpose - print summary list of files which are identical in both
#           directories
#=======================================================================
sub show_identical {
    use File::Basename;
    my ($max, $num, $fmt1, $fmt2);
    my ($file1, $file2, $base1, $base2);

    $max = 0;
    foreach (keys %identical) {
        $max = length(mybase($_, "1")) if length(mybase($_, "1")) > $max;
    }
    $fmt1 = "%2d. %s\n";
    $fmt2 = "%2d. %-${max}s <=> %-s\n";

    if (%identical) {
        $num = 0;
        underline("These files are identical in the two directories");
        foreach (sort keys %identical) {
            $file1 = $_;
            $file2 = $identical{$file1};
            $base1 = mybase($file1, "1");
            $base2 = mybase($file2, "2");
            if ($base1 eq $base2) { printf $fmt1, ++$num, $base1         }
            else                  { printf $fmt2, ++$num, $base1, $base2 }
        }
    } else {
        print "\nNo identical files were found in the two directories.\n";
    }
    pause();
}

#=======================================================================
# name - show_notfound
# purpose - print summary lists of files which exist in one directory
#           but not in the other
#=======================================================================
sub show_notfound {
    my ($num, $ddir1, $ddir2, $ddirL1, $ddirL2);

    $ddir1  = display($dir1,1);
    $ddir2  = display($dir2,2);
    $ddirL1 = display($dirL1,1);
    $ddirL2 = display($dirL2,2);

    # list files found in dir1 but not in dir2
    #-----------------------------------------
    if (@notfound2) {
        $num = 0;
        underline("FOUND in (1) $ddirL1 but NOT FOUND in (2) $ddirL2");
        foreach ( sort @notfound2 ) { printf "%2d. %s\n", ++$num, $_ }
    } else {
        if (@files1) { print "\nAll files in $ddir1 are also in $ddir2\n"   }
        else         { print "\nNo files found in directory (1): $ddir1\n" }
    }
    pause();

    # list files found in dir2 but not in dir1
    #-----------------------------------------
    if (@notfound1) {
        $num = 0;
        underline("FOUND in (2) $ddirL2 but NOT FOUND in (1) $ddirL1");
        foreach ( sort @notfound1 ) { printf "%2d. %s\n", ++$num, $_ }
    } else {
        if (@files2) { print "\nAll files in $ddir2 are also in $ddir1\n"   }
        else         { print "\nNo files found in directory (2): $ddir1\n" }
    }
    pause();
}

#=======================================================================
# name - show_file_counts
# purpose - show number of files in each of the two directories being compared
#
# input parameter
# => $flag: flag indicating whether to pause afterwards (=0 for pause)
#=======================================================================
sub show_file_counts {
    my ($flag, $len1, $len2, $max, $fmt);

    $flag = shift @_;

    $len1 = length($dir1);
    $len2 = length($dir2);

    if ($len1 > $len2) { $max = $len1 }
    else               { $max = $len2 }
    $fmt = "%-${max}s (%d files)\n";

    underline("Directory file counts");
    printf $fmt, $dir1, scalar(@files1);
    printf $fmt, $dir2, scalar(@files2);
    print "\n";

    pause() unless $flag;
}

#=======================================================================
# name - list_files
# purpose - display list of files in the two directories being compared
#=======================================================================
sub list_files {
    my ($fmt, $num, $base);

    $fmt = "%2d. %s\n";

    # print filenames in dir1
    #------------------------
    if (@files1) {
        underline($dir1);
        $num = 0;
        foreach (sort @files1) {
            printf $fmt, ++$num, mybase($_, "1");
        }
    } else {
        print "\nNo files in directory (1): $dir1\n";
    }
    pause();

    # print filenames in dir2
    #------------------------
    if (@files2) {
        underline($dir2);
        $num = 0;
        foreach (sort @files2) {
            printf $fmt, ++$num, mybase($_, "2");
        }
    } else {
        print "\nNo files in directory (2): $dir2\n";
    }
    pause();
}

#=======================================================================
# name - mybase
# purpose - return filename with specified directory name removed
#
# note: This is not the same as taking the basename, since the basename
#       function will remove all the directories preceding the last name,
#       where this function will only remove the directory which is being
#       compared.
#
# input parameters
# => $name: full name of file, including path
# => $flag: flag indicating which directory path to remove from $name
#           Note: if $flag eq "1", then remove $dir1
#                 if $flag eq "2", then remove $dir2
#=======================================================================
sub mybase {
    my ($name, $flag, $ddir, $base);

    $name = shift @_;
    $flag = shift @_;

    if ($flag eq "1") {
        $ddir = display($dir1,1);
        $name =~ s/$dir1\///;
        $name =~ s/$ddir\///;
    }
    elsif ($flag eq "2") {
        $ddir = display($dir2,2);
        $name =~ s/$dir2\///;
        $name =~ s/$ddir\///;
    }
    return $name;
}

#=======================================================================
# name - choose_subdir
# purpose - choose which subdirectory to compare
#=======================================================================
sub choose_subdir {
    my ($opt, $cnt, $dflt);

    # short-circuit if no common subdirectories
    #------------------------------------------
    unless (@subdirs) {
        print "\nNo common subdirectories found.\n";
        pause();
        return;
    }

    # choose subdirectory to compare
    #-------------------------------
    $dflt = 1;
    while (1) {
        underline("Directories");
        print "$dir1\n"
            . "$dir2\n";

        $cnt = 0;
        underline("Which subdirectory do you want to compare?",2);
        foreach (@subdirs) {
            printf "%2d. %s\n", ++$cnt, $_;
            $dflt = $cnt if $_ eq "run";
        }
        print "\n";
        print " 0. previous menu\n";
        print "\n";
        print "choose: [$dflt] ";

        chomp($opt = <STDIN>); 
        $opt = $dflt unless $opt =~ /\S+/;
        return if $opt eq "0";

        unless ($subdirs[$opt-1]) {
            print "\n$opt: Invalid option; Try again.\n\n";
            next;
        }
        $subdir = $subdirs[$opt-1];
        last;
    }
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                         UTILITY subroutines
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#=======================================================================
# name - baselen
# purpose - get length of basename of a variable
#
# input parameters
# => $name: pathname of variable
#=======================================================================
sub baselen {
    use File::Basename;
    my $name = shift @_;
    return length(basename $name);
}    

#=======================================================================
# name - binary
# purpose - determine whether both files are binary (i.e. non-viewable)
#
# input parameters
# => $file1: 1st file
# => $file2: 2nd file
#=======================================================================
sub binary {
    my ($file1, $file2, $type1, $type2, $binflag);
    $file1 = shift @_;
    $file2 = shift @_;

    $binflag = 1;
    $type1 = `file $file1`;
    $type2 = `file $file2`;

    $binflag = 0 if ($type1=~/ASCII/ or $type1=~/text/ or $type1=~/source/)
        and         ($type2=~/ASCII/ or $type2=~/text/ or $type2=~/source/);
    return $binflag;
}

#=======================================================================
# name - cleanDirName
# purpose - remove the final slash from a directory name and find
#           the absolute path
#
# input parameters
# => $dir:  name of directory
# => $flag: return abbreviated name if ==1
#=======================================================================
sub cleanDirName {
    use Cwd ("abs_path");
    my ($dir, $flag, $abspath);

    $dir  = shift @_;
    $flag = shift @_;
    while ($dir =~ m[^(.*[^/])/+$]) { $dir = $1 };
    
    $abspath = abs_path($dir);
    $dir_display{$abspath} = $dir if $flag;
    return $abspath;
}

#=======================================================================
# name - display
# purpose - display path as given rather as absolute path
#
# input parameters
# => $name: filename to display
# => $flag: flag indicating whether files come from $dir1 or $dir2
#=======================================================================
sub display {
    my $name = shift @_;
    my $flag = shift @_;

    if    ($flag == 1) { $name =~ s|$dirA|$dir_display{$dirA}| }
    elsif ($flag == 2) { $name =~ s|$dirB|$dir_display{$dirB}| }

    return $name;
}

#=======================================================================
# name - dmget
# purpose - send job to dmget files prior to comparing them
#
# input parameters
# => $flag: flag indicating whether files come from $dir1 or $dir2
# => @arr: array of files to dmget
#=======================================================================
sub dmget {
    use Cwd ("abs_path");
    use File::Basename;
    my ($flag, @arr, $str, $name, $cnt, $max);
    my ($dmgetcmd, $pid);

    $flag = shift @_;
    @arr  = @_;
    
    $cnt = 0;
    $max = 150;

    # look for dmget command
    #-----------------------
    $dmgetcmd = "/x/x/x/";
    chomp($dmgetcmd = `which dmget`);
    return unless -x $dmgetcmd;

    # get list of files in archive directory
    #---------------------------------------
    $str = "";
    while (@arr) {
        $name = shift @arr;
        if (abs_path(dirname($name)) =~ /archive/) {
            $str .= " " .display($name, $flag);
            $cnt++;
        }

        # fork job to dmget files
        #------------------------
        if ($cnt > $max or (! @arr and $cnt)) {
            print "$dmgetcmd $str\n" if $verbose;
            defined($pid = fork) or die ">> Error << while forking: $!";
            unless ($pid) {
                exec "$dmgetcmd $str";
                die ">> Error << $dmgetcmd command not executed: $!";
            }
            $str = "";
            $cnt = 0;
        }
    }
}

#=======================================================================
# name - getexpid
# purpose - extract a guess at the expid from list of file names
#
# input parameter
# => @arr: list of file names
#=======================================================================
sub getexpid {
    use File::Basename;
    my (@arr, $expid, $max);
    my ($fullname, $name, @dummy, %count);

    @arr = @_;
    $expid = "";
    $max = -99;
    $expid = "";

    foreach $fullname (@arr) {
        ($name, @dummy) = split /[.]/, basename $fullname;
        $count{$name}++;
    }
    foreach $name (sort keys %count) {
        if ($count{$name} == $max) {
            $expid = "";
            next;
        }
        if ($count{$name} > $max) {
            $expid = $name;
            $max = $count{$name};
        }
    }
    return $expid;
}

#=======================================================================
# name - listdump
# purpose - dump sorted contents of array to file
#
# input parameters
# => $arrAddr: address of array to dump
# => $fname:   name of file where the contents get written
# => $exclude: string to exclude from the display
#=======================================================================
sub listdump {
    my ($arrAddr, @arr, $fname, $name, $exclude);
    $arrAddr = shift @_;
    $fname = shift @_;
    $exclude = shift @_;
    @arr = @$arrAddr;

    open OUTFL, "> $fname" or die "Error opening file, $fname;";
    foreach $name (sort @arr) {
        $name =~ s/$exclude//;
        print OUTFL "$name\n";
    }
    close OUTFL;
}

#=======================================================================
# name - in
# purpose - determine whether value is in an array
#
# input parameters
# => $value: value to search for in an array
# => @array: array to search
#=======================================================================
sub in {
    my ($value, @array, $flag);

    $value = shift @_;
    @array = @_;

    $flag = 0;
    foreach (@array) {
        if ($_ eq $value) { $flag = 1; last }
    }
    return $flag;
}

#=======================================================================
# name - namechange
# purpose - substitute patterns into name
#
# input parameters
# => $name: name of file before name change
# => $flag: =1 (default) replace @p1 values with @p2 values
#           =2           replace @p2 values with @p1 values
#=======================================================================
sub namechange {
    use File::Basename;
    my ($name, $flag);
    my ($dir, $base);

    $name = shift @_;
    $flag = shift @_;
    $flag = 1 unless $flag;

    foreach (0..$#p1) {
        last if -e $name;
        $dir = dirname $name;
        $base = basename $name;
        if ($flag eq "1") { $base =~ s/\b$p1[$_]\b/$p2[$_]/g }
        else              { $base =~ s/\b$p2[$_]\b/$p1[$_]/g }
        $name = "$dir/$base";
    }

    return $name;
}

#=======================================================================
# name - numeric
# purpose - used with perl sort command to do a numeric sort
#=======================================================================
sub numeric {
    return  1 if $a > $b;
    return -1 if $a < $b;
}

#=======================================================================
# name - pause
# purpose - pause processing until user input is detected
#=======================================================================
sub pause {
    my $dummy;
    print "\nHit <CR> to continue ... ";
    $dummy = <STDIN>;
}

#=======================================================================
# name - queryYN
# purpose - get and return response to y/n question
#
# input parameters
# => $prompt: string to prompt for user response
# => $addr: address for variable $YN which contains a default response
#           either "y" or "n"; will be set to "n" unless it equals "y"
#
# output
# => sent back through address, $addr
#=======================================================================
sub queryYN {
    my ($prompt, $addr, $YN, $ans);

    while (1) {

        # input parameters
        #-----------------
        $prompt = shift @_;
        $addr   = shift @_; $YN = $$addr;

        # default response is "n" unless user specified "y"
        #-------------------------------------------------
        $YN = "n" unless $YN;

        # concatenate y/n choices and default to prompt
        #----------------------------------------------
        $prompt .= " (y/n) [$YN]? ";

        # print prompt and get response
        #------------------------------
        print $prompt;
        chomp($ans = lc <STDIN>); $ans = $YN unless $ans;
        $ans = "n" if $ans eq "no";
        $ans = "y" if $ans eq "yes";

        last if $ans eq "y" or $ans eq "n";
        print "Unrecognizable input.  Try again\n";
    }
    $$addr = $ans;
}

#=======================================================================
# name - underline
# purpose - prints a string to stdout and underlines it
#
# input parameters
# => string: the string to underline
# => flag: (optional); defaults to =1
#           =1: underline only with '-'
#           =2: underline and overline with '='
#=======================================================================
sub underline {
    my ($string, $flag);
    my (%pattern, $cnt);

    $string = shift @_;
    $flag = shift @_;

    $pattern{1} = "-";
    $pattern{2} = "=";

    $flag = 1 unless $flag;
    $flag = 1 unless $flag == 2;

    $cnt = length($string);
    print "\n";
    print $pattern{$flag}x$cnt."\n" if $flag == 2;
    print $string."\n";
    print $pattern{$flag}x$cnt."\n";
}

#=======================================================================
# name - wanted
# purpose - collect file names in find function from File::Find
#=======================================================================
sub wanted {
    push @files, $File::Find::name;
}

#=======================================================================
# name - Xcluded
# purpose - identify files that are to be excluded
#=======================================================================
sub Xcluded {
    my ($name, $Xclude);

    $name = shift @_;

    $Xclude = 0;
    foreach (@exclude) {
        if ($name =~ /$_/) { $Xclude = 1; last }
    }
    return $Xclude;
}

#=======================================================================
# name - usage
# purpose - print script usage information
#=======================================================================
sub usage {    
    use File::Basename;
    my $script = basename $0;
    print << "EOF";
Usage: $script dir1 dir2 [options]
where
  dir1 = first directory being compared
  dir2 = second directory being compared

options
  -bwi               ignore blanks, white space, and case when doing file diffs
  -ext extension     compare all files with this extension (recursive)
  -id fileID         compare all files with \"fileID\" as part of its filename
  -h(elp)            print usage information
  -list              compare list of files in dir1 and dir2
  -listx             same as -list, except ignore dir and expid name differences
  -q                 quiet mode
  -r                 recursively compare any subdirectories found
  -rs                shortcut for "-subdir rs -ext bin"
  -run               shortcut for "-subdir run -r"
  -subdir name       start comparison in specified subdirectory
  -v                 verbose mode
  -X  string         filenames which include this string will be excluded
                     from the comparison
pattern options
  -p1 pattern1       ignore these pattern differences in dir1/dir2 filenames
  -p2 pattern2

or
  -p pattern1=pattern2

EOF
exit;
}
