#!/usr/bin/perl

use v5.34;
use strict;
use warnings;
use FindBin qw($Bin);
use Term::ANSIColor;

my $flags = $ARGV[0] if ($ARGV[0]);
my $filechoice = ($ARGV[1] - 1) if ($ARGV[1]);
my $dirpath = $Bin . '/indexes';
my @dirfiles;
my $filecount = 0;
my $chosenindex;

sub checkDir{
    if (opendir (my $dh, $dirpath))
    {
        foreach my $file (readdir $dh)
        {
            next if ($file =~ /\A\./);
            $dirfiles[$filecount] = $file;
            $filecount++;
        }
        closedir $dh;

        if (@dirfiles == 0)
        {
            print colored(['cyan'], "[CLINDEX]: Your Index Directory appears to be empty.\n");
            &createIndex;
        }
    }
    else
    {
        say colored(['cyan'], "[CLINDEX]: couldnt find sub-dir \'/indexes\'");
        print colored(['cyan'], "Create a new dir \'$dirpath\'? [y/n] ");
        chomp(my $yesno = <STDIN>);
        if ($yesno  =~ /\Aye?s?\Z/i)
        {
            mkdir $dirpath, 0755 or die "cannot make new dir: $!";
            print colored(['cyan'], "[CLINDEX]: Successfully created \'$dirpath\'\n");
            &createFile;
        }
        else
        {
            print colored(['cyan'], "[CLINDEX] closing...\n");
            die "\n";
        }
    }
}

sub createFile{
    my $dir = $dirpath;

    say colored(['cyan'], "[CLINDEX] Create a new index");
    print "Enter the name of an index you'd like to create: ";

    chomp(my $index_name = <STDIN>);
    chdir $dir;
    system 'touch', "$index_name.txt";
    say "New index \'$index_name.txt\' sucessfully created!";
    #NEWLY CREATED INDEX, PROMT THE USER IF THEY WANT TO ADD SOMETHING TO IT ???
}

sub removeFile{
    my $dir = $dirpath;

    say colored(['cyan'], "[CLINDEX] REMOVE INDEX");
    &displayIndexes;
    print "Enter the NUMBER of the index you'd like to remove: ";
    chomp(my $index_num = <STDIN>);
    if ($index_num >= 0 && $index_num <= $filecount){
        print "Are you sure you'd like to delete ".colored(['red'], "$dirfiles[$index_num-1]")."? [y/n] ";
        chomp(my $yesno = <STDIN>);
        if ($yesno  =~ /\Aye?s?\Z/i)
        {
            chdir $dir;
            system 'rm', "$dirfiles[$index_num-1]";
            say "Successfully removed $dirfiles[$index_num-1]";
        }
        else
        {
            say colored(['cyan'], "[CLINDEX] Terminating Index removal...")
        }
    }
    else
    {
        say colored(['cyan'], "[CLINDEX] Invalid Index choice \'$index_num\'");
        say colored(['cyan'], "Terminating Index removal...")
    }


}

sub displayFiles{
        say colored(['cyan'], "Your Available Indexes:");
        foreach my $i (0..$#dirfiles)
        {
            say $i+1 . ". $dirfiles[$i]";
        }
}

sub hashFile{
    my $file = $_[0] . $_[1];
    open FILE, $file;
    chomp (my @arr = <FILE>);
    close FILE;

    return @arr;
}

sub indexChooser{
    if ($filechoice >= 0 && $filechoice < $filecount)
    {
        return "/$dirfiles[$filechoice]"
    }
    else
    {
        say colored(['cyan'], "[CLINDEX] Invalid Index choice \'$ARGV[1]\'");
        &displayFiles;
        die "\n";
    }
}

sub usageDisplay{
    say colored(['cyan'], " - [CLINDEX] - \nUSAGE:") . "\$ clindex <desired behavior> <number of desired index>";
    say colored(['cyan'], "BEHAVIOR FLAGS:\n-i: Create new index*\n-r: Remove Index*\n-p: Print Index\n-s: Search Index\n-a: Add to Index\n-d: Delete from Index\n");
    &displayFiles;
    say colored(['blue'], "\n*index-number optional");
}

sub printIndex{
    say colored(['cyan'], "[CLINDEX] Reading $chosenindex");
    my %index = &hashFile($dirpath, $chosenindex);
    my @terms = sort(keys(%index));
    if (@terms)
    {
        foreach my $i (0..$#terms)
        {
            say $i+1 . ". $terms[$i] - $index{$terms[$i]}\n";
        }
    }
    else
    {
        say "$chosenindex appears to be empty. Use -a to add a term";
    }
}

sub searchIndex{
    say colored(['cyan'], "[CLINDEX] Searching $chosenindex") if (!$_[0]);
    my %index = &hashFile($dirpath, $chosenindex);
    my @terms = sort(keys(%index));
    my $searchchecker = -1;

    print "Search for terms: " if (!$_[0]);
    chomp(my $searchterm = <STDIN>);
    for my $i (0..$#terms)
    {
        if (!$_[0])
        {
            if ($terms[$i] =~ /\A$searchterm/i){
                say "$terms[$i] - $index{$terms[$i]}";
            }
            else
            {
                $searchchecker++;
            }
        }
        else
        {
            if ($terms[$i] eq $searchterm) 
            {
                return $terms[$i]
            }
            else
            {
                $searchchecker++;
            }
        }
    }

    if ($searchchecker == $#terms){
        say colored(['cyan'], "[CLINDEX] Couldnt find \'$searchterm\' in $chosenindex");
        if ($_[0])
        {
            say colored(['red'], "Canceling deletion.");
            return "notfound";
        }
    } 
}

sub addToIndex{
    open FILE, ">> $dirpath" . "$chosenindex";
    say colored(['cyan'], "[CLINDEX] Adding to $chosenindex");
    print "New term: ";
    chomp(my $newterm = <STDIN>);
    print FILE "$newterm\n";
    print $newterm . " description: ";
    my $newdesc = <STDIN>;
    print FILE $newdesc;
    close FILE;
    say colored(['cyan'], "$chosenindex updated!");
}

sub deleteFromIndex{
    say colored(['cyan'], "[CLINDEX] Deleting from $chosenindex");
    print "Enter the EXACT TERM you wish to remove: ";
    my $term_to_delete = &searchIndex(1);
    if ($term_to_delete ne 'notfound')
    {
        print "Are you sure you'd like to delete ".colored(['red'], $term_to_delete)."? [y/n] ";
        chomp(my $yesno = <STDIN>);
            if ($yesno  =~ /\Aye?s?\Z/i)
            {
                my %index = &hashFile($dirpath, $chosenindex);
                my @terms = sort(keys(%index));
                open FILE, "> $dirpath"."$chosenindex";
                foreach my $i (0..$#terms)
                {
                    next if ($terms[$i] eq $term_to_delete);
                    say FILE "$terms[$i]\n$index{$terms[$i]}";
                }
                close FILE;
                say colored(['cyan'], "[CLINDEX] ").colored(['green'], "Deletion successful!.");
            }
            else
            {
                say colored(['cyan'], "[CLINDEX] ")."Canceling deletion.";
            }
        }
}

#--MAIN FUNCTION-----(how ya like that?)--------------------------------------{

&checkDir;
$chosenindex = &indexChooser if ($ARGV[1]);

if((!$ARGV[0]) || ($ARGV[0] !~ /\-/))
{
   &usageDisplay 
}
else
{
    if ($ARGV[0] eq '-i'){
        &createFile;
    }
    if ($ARGV[0] eq '-p'){
        (!$ARGV[1])? &usageDisplay : &printIndex;
    }
    if ($ARGV[0] eq '-r'){
        &removeFile
    }
    if ($ARGV[0] eq '-s'){
        (!$ARGV[1])? &usageDisplay : &searchIndex;
    }
    if ($ARGV[0] eq '-a'){
        (!$ARGV[1])? &usageDisplay : &addToIndex;
    }
    if ($ARGV[0] eq '-d'){
        (!$ARGV[1])? &usageDisplay : &deleteFromIndex;
    }
}

#&editIndex
#   -add or delete a term

#&searchIndex
#   -general serach and exact search (for term removal)
#-----------------------------------------------------------------------------}
