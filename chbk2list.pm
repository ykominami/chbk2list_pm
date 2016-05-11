package Chbk2list;

use strict;
use warnings;
no strict 'refs';

use utf8;
use HTML::TreeBuilder;
use List::Util;
use List::MoreUtils;
use autodie;
use Data::Dumper;

sub new {
    my $self = {};
    my $class = shift;
    
    $self->{fname} = shift;
    $self->{item_hs} = {};
    $self->{category} = {};
    $self->{category_by_name} = {};
    $self->{tree} = undef;
    bless( $self , $class );
    return $self;
}

sub assign_name_to_ancestor_h1 {
    my $self = shift;
    my $tree = shift;
    
    my $h1s = $tree->find("h1");
    my $x = $h1s;
    my $body_title = $x->as_trimmed_text() ; 
    my $parent = $x->parent();

    my $dl = List::Util::first { $_->tag() eq "dl" } $parent->content_list();
    $self->register_hier_item( $dl );
    $self->register_item( $dl , $body_title , "" , "" );
}

sub register_hier_item {
    my $self = shift;
    my $item = shift;

    my @rev_hier = $item->lineage();
    # /home/bodyの部分を取り除く
    pop(@rev_hier);
    pop(@rev_hier);
    # $itemを最下部として追加する
    unshift(@rev_hier , $item);
    # 階層をトップダウンで表すように配列要素を反転する
    my @hier = reverse(@rev_hier);
    
    List::Util::reduce {
        $self->register_item( $b , undef , $b->{add_date} , $b->{last_modified} );
        push(@$a , $self->{item_hs}->{$b});
        $self->{item_hs}->{$b}->{hier} = $a;
        $a;
    } [] , @hier;
} 

sub register_item {
    my $self = shift;
    my $item = shift;
    my $title = shift;
    my $add_date = shift;
    my $last_modified = shift;

    if( !defined( $self->{item_hs}->{$item} ) ){
        $self->{item_hs}->{$item} = {
            name => $item->tag,
            label => undef ,
            item => $item,
            hier => [],
            call_count => 1,
            call_count_title => 0,
	    add_date => $add_date,
	    last_modified => $last_modified,
        };
    }
    else{
        if( !defined( $self->{item_hs}->{$item}->{name} ) ){
            $self->{item_hs}->{$item}->{name} = $item->tag;
        } 
        if( !defined( $self->{item_hs}->{$item}->{label} ) ){
            $self->{item_hs}->{$item}->{label} = undef;
        } 
        if( !defined( $self->{item_hs}->{$item}->{item} ) ){
            $self->{item_hs}->{$item}->{item} = $item;
        } 
        if( !defined( $self->{item_hs}->{$item}->{hier} ) ){
            $self->{item_hs}->{$item}->{hier} = $item;
        } 
        $self->{item_hs}->{$item}->{call_count} += 1;
	if( !defined( $self->{item_hs}->{$item}->{add_date} ) ){
	    $self->{item_hs}->{$item}->{add_date} = $add_date;
	}
	if( !defined( $self->{item_hs}->{$item}->{last_modified} ) ){
	    $self->{item_hs}->{$item}->{last_modified} = $last_modified;
	}
    }
    if( defined($title) ){
        $self->{item_hs}->{$item}->{title} = $title;
        $self->{item_hs}->{$item}->{call_count_title} += 1;
    }

    if( !defined($self->{item_hs}->{$item}->{title}) ){
#        print "not defined title\n";
    }
}

sub get_dt_text{
    my $self = shift;
    my $item = shift;

    my $hs = $item->tagname_map;
    #    return $hs->{'a'}->as_trimmed_text;
    my $text = "";
    my $add_date = "";
    my $last_modified = "";
    if ( defined($self->{item_hs}->{$item}->{title}) ){
        $text = $self->{item_hs}->{$item}->{title};
        $add_date = $self->{item_hs}->{$item}->{add_date};
        $last_modified = $self->{item_hs}->{$item}->{last_modified};
    }
    else{
        my $a = $hs->{'a'};
        if ( $#$a > 0 ){
            $text = $a->[0]->as_trimmed_text;
	    $add_date = $a->[0]->attr('ADD_DATE');
	    $last_modified = $a->[0]->attr('LAST_MODIFIED');
        }
        else{
            my $h3 = $hs->{'h3'};
            if ( $#$h3 > 0 ){
                $text = $h3->[0]->as_trimmed_text;
		$add_date = $h3->[0]->attr('ADD_DATE');
		$last_modified = $h3->[0]->attr('LAST_MODIFIED');
            }
            else{
                #
            }
        }
    }
    if( !defined $add_date ){
	$add_date = "";
    }
    if( !defined $last_modified ){
	$last_modified = "";
    }
    return ($text , $add_date , $last_modified);
}

sub get_lineage_by_hier {
    my $self = shift;
    my $item = shift;
    return List::Util::reduce { $a . '/' . $b} reverse $item->lineage_tag_names() ;
}


sub assign_name_to_ancestor_h3{
    my $self = shift;
    my $tree = shift;
    
    foreach my $x ( $tree->find("h3") ){
        my $dl;
        my $text = $x->as_trimmed_text();

	
	my $add_date = $x->attr('ADD_DATE');
	my $last_modified = $x->attr('LAST_MODIFIED');
	if( !defined $add_date ){
	    $add_date = "";
	}
	if( !defined $last_modified ){
	    $last_modified = "";
	}
	    
        # parentはdt
        my $parent = $x->parent;
        $self->register_hier_item( $parent );
        $self->register_item( $parent, $text , $add_date , $last_modified);

        my @a = $parent->content_list();
        if ( defined(@a[ $x->pindex + 1 ]) ){
            $dl = @a[ $x->pindex + 1 ];
            if ($dl->tag ne "dl"){
                die "dl->tag($dl->tag) ne dl\n";
            }
            $self->register_hier_item( $dl );
            $self->register_item( $dl , $text , $add_date, $last_modified);
        }
    }
}

sub assign_name_to_ancestor_a{
    my $self = shift;
    my $tree = shift;

    foreach my $x ( $tree->find("a") ){
        my $text = $x->as_trimmed_text();
	
	my $add_date = $x->attr('ADD_DATE');
	my $last_modified =  $x->attr('LAST_MODIFIED');
	if( !defined $add_date ){
	    $add_date = "";
	}
	$last_modified = $x->attr('LAST_MODIFIED');
	if( !defined $last_modified ){
	    $last_modified = "";
	}
	
        my $parent = $x->parent;
        $self->register_hier_item( $parent );
        $self->register_item( $parent , $text , $add_date , $last_modified );
    }
}

sub listup_no_title_item{
    my $self = shift;

    foreach my $v (values( %{$self->{item_hs}} )){
        if( !defined( $v->{title} ) ){
            print $self->get_lineage_by_hier($v->{item}) , "\n";
            print $v->{name} , "\n";
            print $v->{call_count} , "\n";
            print $v->{call_count_title} , "\n";
            $self->inspect_item( $v->{item} );
        }
    }
}

sub listup{
    my $self = shift;
    my $tree = $self->{tree};
    my @ary = ();

    foreach my $t ( $self->{tree}->find("a") ) {
        my $str = "";
        my $parent = $t->parent();

        my $list = $self->{item_hs}->{$parent}->{hier};
        if ( !defined($list) or  $#$list <= 0 ){
            $self->register_hier_item($parent);
            $list = $self->{item_hs}->{$parent}->{hier};
        }
	my $add_date = $self->{item_hs}->{$parent}->{add_date};
	my $last_modified = $self->{item_hs}->{$parent}->{last_modified};

	my $category = $self->{category}->{$parent};
	if( !defined($category) ){
	    $self->{category}->{$parent} = {};
	    $self->{category}->{$parent}->{add_date} = $add_date;
	    $self->{category}->{$parent}->{last_modified} = $last_modified;
	    $category = $self->{category}->{$parent};
	}
        my $num = @$list;
        if( $num > 0 ){
	    my @lx = grep { $_->{name} eq "dl" } @{$list};
	    
            my @ax  = List::MoreUtils::apply {
                $_ = $_->{title};
            } @lx;

            $str = "";
            if ($#ax > 0 ){
                my $last_item = List::Util::reduce {
		    my $label;

		    if( !defined($b->{title}) ){
			$b->{title} = "";
		    }
		    
		    if( defined($a) ){
			if( defined($a->{label}) ){
			    $label = $a->{label} . '/' . $b->{title};
			}
			else{
			    $label = $b->{title};
			}
		    }
		    else{
			$label = $b->{title};
		    }
		    $b->{label} = $label;
		    if( !defined( $self->{category}->{$label} ) ){
			$self->{category_by_name}->{$label} = {};
			$self->{category_by_name}->{$label}->{add_date} = $b->{add_date};
			$self->{category_by_name}->{$label}->{last_modified} = $b->{last_modified};
		    }
		    $b;
		} undef, @lx;
		#                $str = List::Util::reduce { $a . '/' . $b} @ax;
		$str = $last_item->{label};

            }
	    push @ary , ["$str" , $t->as_trimmed_text , $t->attr('href'), $t->attr('ADD_DATE'), $t->attr('LAST_MODIFIED') ];
        }
        else{
            #                            print "hier size 0\n";
        }
    }

    return @ary;
}

sub parse_html {
    my $self = shift;

    open my $fh , "<" , $self->{fname} or die "failed to open $!";
    my $tree = HTML::TreeBuilder->new_from_file($fh);
    $self->{tree} = $tree;

    $self->assign_name_to_ancestor_h1($tree);
    $self->assign_name_to_ancestor_h3($tree);
    $self->assign_name_to_ancestor_a($tree);
    close $fh;

    return $tree;
}

sub get_bookmark_list {
    my $self = shift;
    my $tree = shift;
    
    if( !defined( $tree ) ){
	$tree = $self->{tree};
    }

    if( !defined( $tree ) ){
	$tree = $self->parse_html;
    }

    return $self->listup( $tree );
}


sub get_category_list {
    my $self = shift;
    my $tree = shift;
    
    if( !defined( $tree ) ){
	$tree = $self->{tree};
    }

    if( !defined( $tree ) ){
	$tree = $self->page_html;
    }

    return $self->{category_by_name};
}

sub print_category_list {
    my $self = shift;
    my $tree = shift;
    
    foreach my $v ($self->get_category_list($tree) ) {
	print join( "\t" , @$v ) , "\n";
   }
}

sub inspect_item {
    my $self = shift;
    my $item = shift;

    print "----inspect_item" , "\n";
    print $item->tag , "\n";
    print $self->get_lineage_by_hier($item) , "\n";
    print $item->address , "\n";
    print "\n";
    my $address = $item->address();
    print $item->address($address) , "\n";
    print "# item->content_list\n";
    foreach my $x ( $item->content_list) {
        my $text = "";
	my $add_date = "";
	my $last_modified = "";
        print $x , "\n";
        try {
            my $tagname = $x->tag();
            if ($tagname eq "dt"){
                ($text , $add_date, $last_modified) = $self->get_dt_text($x);
            }
            print $x , " | ", $x->tag , " | " , $text , "\n";
            #            print $self->get_lineage_by_hier($x) , "\n";
            print $x->address , "\n";
            print $x->pindex , "\n";
        } catch {
            print "ERROR: $_";
        }
    }
    print "-- parent" , "\n";
    my $parent = $item->parent;
    print $parent->tag , "\n";
    print $self->get_lineage_by_hier($parent) , "\n";
    $address = $parent->address();
    print $parent->address , "\n";
    print $parent->address($address) , "\n";
    print $parent->pindex , "\n";
    
    print "-- parent->content_list" , "\n";
    foreach my $x ( $parent->content_list) {
        my $text = "";
	my $add_date = "";
	my $last_modified = "";
        if ($x->tag eq "dt"){
            ($text , $add_date, $last_modified) = $self->get_dt_text($x);
        }
        print $x , " | ", $x->tag , " | " , $text , " | " , $add_date , " | " , $last_modified , "\n";
#        print $self->get_lineage_by_hier($x) , "\n";
        print $x->address , "\n";
        print $x->pindex , "\n";
    }
}

return 1;
