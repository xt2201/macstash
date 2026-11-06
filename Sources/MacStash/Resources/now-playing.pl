#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
use DynaLoader;

die "Usage: $0 <library> <get|watch|watch_all>\n" unless @ARGV >= 2;
my ($library, $mode) = @ARGV;
$library = abs_path($library) // $library;

my $libref = DynaLoader::dl_load_file($library, 0)
    or die "dl_load_file failed: " . DynaLoader::dl_error() . "\n";

my $symbol_name;
if ($mode eq 'watch') {
    $symbol_name = 'macstash_now_playing_watch';
} elsif ($mode eq 'watch_all') {
    $symbol_name = 'macstash_now_playing_watch_all';
} else {
    $symbol_name = 'macstash_now_playing_get';
}

my $symref = DynaLoader::dl_find_symbol($libref, $symbol_name)
    or die "dl_find_symbol failed: " . DynaLoader::dl_error() . "\n";

my $entry = DynaLoader::dl_install_xsub("main::$symbol_name", $symref, $library);
my $code = $entry->();
exit($code // 0);
