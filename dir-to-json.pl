#!/usr/bin/perl
use warnings;
use strict;
use Escape;
use JSON;

my ($dirname, $fqbn) = @ARGV;

if (!defined($dirname)) {
    die("Usage: $0 [dirname]\n");
}

if (!defined($fqbn)) {
    $fqbn = "arduino:avr:uno";
}

opendir(my $dir, $dirname) or die("Couldn't open directory $dirname: $!");

my $config_hash = {
    files => [],
    libraries => {},
    logging => 1,
    format => "hex",
    version => 167,
    vid => 0x2342,
    pid => 0x4321,
    fqbn => $fqbn,
};

while (my $filename = readdir($dir)) {
    # Add .ino files to the output list
    if ($filename eq "." || $filename eq "..") {
        next;
    }
    elsif (($filename =~ /\.ino$/i) || ($filename =~ /\.[cChH]$/)) {

        # Slurp the file in one go
        open(my $ino, '<', $dirname . "/" . $filename) or die;
        local $/ = undef;
        push (@{$config_hash->{"files"}}, {
                filename => $filename,
                content => <$ino>,
            });
        close($ino);
    }
    elsif (-d $dirname . "/" . $filename) {
        my $libname = $filename;
        my $library = [];

        opendir(my $libdir, $dirname . "/" . $filename);

        while (my $libfilename = readdir($libdir)) {
            next if ($libfilename eq "." || $libfilename eq "..");
            next unless (($libfilename =~ /\.[cChH]$/) || ($libfilename =~ /\.cpp$/i));

            open(my $lib, '<', $dirname . "/" . $filename . "/" . $libfilename) or die;
            local $/ = undef;
            push(@$library, {
                "filename" => $libfilename,
                "content" => <$lib>,
            });
            close($lib);
        }
        closedir($libdir);

        $config_hash->{"libraries"}->{$libname} = $library;
    }
}

print to_json($config_hash);
