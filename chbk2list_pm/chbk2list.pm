
package Chbk2list;

use strict;
use warnings;
use HTML::TreeBuilder;
use List::Util;
use List::MoreUtils;

sub new {
    my $self = {};
    my $class = shift;
    $self->{fname} = shift;
    print $self->{fname} , "\n";
    $self->{item_hs} = {};
    $self->{tag_list} = [];
    bless( $self , $class );
    return $self;
}

sub trim {
    my $self = shift;
    my $val = shift;
    $val =~ s/\A\s*(.*?)\s*\z/$1/;
    return $val;
}

sub assign_name_to_ancesotr_h1 {
    my $self = shift;
    my $tree = shift;
    my @h1s = $tree->find("h1");
    my $x = $h1s[0];
    my $body_title = $self->trim( $x->as_trimmed_text() ) ; 
    my $parent = $x->parent();

    my $z = List::Util::first { $_->tag() eq "dl" } $parent->content_list();
    $self->{item_hs} = { name => $z->tag(), title => $body_title , label => undef , item => $z };
    
}

sub get_top{
    my $self = shift;
    my $item = shift;
    print "get_top|($item->tag)\n";
    
    if ( $item->tag() ne "body" ){
        print $self->{tag_list} , "\n";
        
        unshift $self->{tag_list} , $item;
        print "get_top 1\n";
        $self->get_top( $item->parent() );
    }
}

sub assign_name_to_ancesotr_h3{
    my $self = shift;
    my $tree = shift;
    foreach my $x ( $tree->find("h3") ){
        print $x , "\n";
        
        my $text = $self->trim( $x->as_trimmed_text() );
        print "text=($text)\n";
        
        # parentはdt
        my $parent = $x->parent();
        print "parent=($parent)\n";
        my @key = keys( %{$parent} );
        foreach my $k  (@key) {
            print "k=($k)\n";
        }
        print "_parent=($parent->{_parent})\n";
        print "get_top 2\n";
        $self->get_top( $parent );
        my $idx = List::Util::first { $_ >= 0 } grep { $self->{tag_list}->[$_]->tag() eq 'dt'} 0 .. $#{$self->{tag_list}};
        # y はdtの１つ上(dl)
        my $dt = $self->{tag_list}->[$idx];
        my $y = $self->{tag_list}->[ $idx - 1 ];
        $self->{tag_list} = [];
        print "get_top 3\n";
        $self->get_top( $y );
        #      @item_hs[y][:tag_list] = @tag_list
        print "=y.path\n";
        print $y->path() , "\n";
        print "=parent.path^n";
        print $parent->path() , "\n";

        print "=y.children\n";
        foreach my $x ( $y->children() ){
            print $x->path() , "\n";
        }
        print "==========";

        my $idz = first { $_ >= 0 } grep { $_ eq $dt } 0 .. $#{$y->children()};
        print "idz=($idz)";
        my $z = $y->children()->[ $idz + 1];
        if ($self->{item_hs}->{$z}){
            if ( !defined( $self->{item_hs}->{$z}->{title} ) ){
                $self->{item_hs}->{$z}->{title} = $text;
            }
        }
        else{
            $self->{item_hs}->{$z} = {
                name => $z->{name},
                title => $text ,
                label => undef ,
                item => $z
            }
        }
        $self->{tag_list} = [];
        print "-------------------\n";
    }
}
sub assign_name_to_ancesotr_a{
    my $self = shift;
    my $tree = shift;
    foreach my $x ( $tree->find("a") ){
        my $text = $self->trim( $x->as_trimmed_text() );
        print "get_top 4\n";
        $self->get_top( $x->parent() );
        my $parent = $x->parent();
        my $parent_ex = $self->{item_hs}->{$parent};
        if ($parent_ex){
            $parent_ex->{title} = $text;
        }
        else{
            $parent = $self->{item_hs}->{parent};
        }
        $self->{item_hs}->{parent}->{tag_list} = $self->{tag_list};
        $self->{tag_list} = [];
    }
}

sub listup_a{
    my $self = shift;
    my $tree = shift;
    foreach my $t ( $tree->find("a") ) {
        my $parent = $t->parent();
        my $list = $self->{item_hs}->{parent}->{hier};
        if (!defined($list) ){
            my $tag_list = $self->{item_hs}->{parent}->{tag_list};
            my $idx = List::Util::first { $_ >= 0 } grep { $tag_list->[$_]->tag() eq "dt" } 0 .. $#{$tag_list};
            $self->{item_hs}->{parent}->{hier} = $self->make_hier( @{$self->{tag_list}}[0 .. $idx]);
        }
        my $hier_str = List::Util::reduce { $a . '/' . $b} List::MoreUtils::apply { $_->{title} } $self->{item_hs}->{parent}->{hier};
        print $hier_str , "\n";
        print "----\n";
    }
}

sub make_hier{
    my $self = shift;
    my $tag_list = shift;
    List::MoreUtils::apply {
        print $_->{name} , "\n";
        if ( $_->{name}  eq "dt" ){
            if ( !defined( $self->{item_hs}->{$_} ) ){
                $self->{item_hs}->{$_} = { name => $_->tag() , title => undef , label => undef , item => $_ };
            }
        }
        elsif ( $_->{name} eq "dl" ){
            if ( !defined( $self->{item_hs}->{$_} ) ){
                $self->{item_hs} = { name => $_->tag() , title => undef , label => undef , item => $_ };
            }
        }
        else{
            print $_->as_trimmed_text();
        }
    }
}

sub get_category_listy {
    my $self = shift;
    
    open my $fh , "<" , $self->{fname} or die "failed to open $!";
    my $tree = HTML::TreeBuilder->new_from_file($fh);
#    $tree->parse();
    $self->assign_name_to_ancesotr_h1($tree);
    $self->assign_name_to_ancesotr_h3($tree);
    $self->assign_name_to_ancesotr_a($tree);
    $self->listup_a($tree);
    close $fh;
}

return 1;
