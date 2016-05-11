use strict;
use warnings;
#no strict 'refs';

use utf8;
use Encode qw/encode decode/;

use Data::Dumper;
#use HTTP::Tiny;
use JSON qw/encode_json decode_json/;
use Encode qw/encode_utf8 decode_utf8/;
#use File::Basename 'basename', 'dirname';
use File::Basename;
use File::Spec;

require 'chbk2list.pm';

my $bkfname = $ARGV[0];
my $ofname = $ARGV[1];
my ($basename, $dirname, $ext) = fileparse($ofname , qr/\..*$/);
my $category_ofname = File::Spec->catfile( $dirname , $basename . "_category" . $ext);

my $delimitor = "\t";
#my $delimitor = '|';
#my $delimitor = ',';



my $chbk = Chbk2list->new( $bkfname );
my $max_id=0;
my $added_count = 0;

open my $ofh , ">" , $ofname or die "failed to open $!";
open my $category_ofh , ">" , $category_ofname or die "failed to open $!";

my $url = 'http://localhost:4567';


my $lines = 0;

foreach my $v ($chbk->get_bookmark_list) {
    my ($category , $title, $href, $add_date, $last_modified) = map { $_ } @$v;
    if (!defined $add_date){
	$add_date = "";
    }
    if (!defined $last_modified){
	$last_modified = "";
    }
    if ( $lines == 0 ){
	print $ofh join($delimitor , ('category' , 'title' , 'href' , 'add_date', 'last_modified') ) , "\n";
    }
    print $ofh join($delimitor , ($category , $title , $href , $add_date, $last_modified) ) , "\n";
    $lines++;
}

close $ofh;

my $hs = $chbk->get_category_list;
my $string = "";
for my $k ( sort (keys %{$hs}) ){
    $string = join($delimitor , ($k , $hs->{$k}->{add_date}, $hs->{$k}->{last_modified} ));
 
    print $category_ofh  $string, "\n";
}
close $category_ofh;
