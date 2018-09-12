package Outlineop;

use strict;
use warnings;
no strict 'refs';

sub new {
    my $self = {};
    my $class = shift;
    
    $self->{ks} = shift;
    $self->{ofh} = shift;
    $self->{stack} = ();
    $self->{indent} = 0;
    $self->{prev_len} = 0;
    $self->{cur_len} = 0;
    bless( $self , $class );
    return $self;
}

sub push_hier{
    my $self = shift;
    my $name = shift;
    my @stack = $self->{stack};

    $self->print_with_indent( sprintf("%s<outline text=\"%s\">" , " " x ($#stack + 1) , $name ) );
    push( @stack , $name );
}
sub pop_hier{
    my $self = shift;
    my @stack = $self->{stack};

    $self->print_with_indent( sprintf("%s%s" , " " x ($#stack) , "</outline>" ) );
    pop( @stack );
}
sub flush_hier{
    my $self = shift;
    my $stack = $self->{stack};

    my $level = $self->{prev_len};
    while( ( $#$stack + 1 ) > 0  ){
	$self->pop_hier();
    }
}

sub indent_plus {
    my $self = shift;

    $self->{indent}++;
}

sub indent_minus {
    my $self = shift;

    $self->{indent}--;
}

sub print_with_indent {
    my $self = shift;
    my $str = shift;
    
    $self->println( sprintf("%s%s" , " " x $self->{indent},   $str ) );
}

sub print_tab_and_attr {
    my $self = shift;
    my ($tag, $attr_name, $attr_value) = @_;
    
    $self->print_with_indent( sprintf("<%s %s=\"%s\">",$tag , $attr_name, $attr_value) );
}

sub print_tab_open_and_attr {
    my $self = shift;
    my ($tag, $attr_name, $attr_value) = @_;
    $self->print_with_indent( sprintf("<%s %s=\"%s\">",$tag , $attr_name, $attr_value) );
}
sub print_tab_open {
    my $self = shift;
    my ($tag) = @_;
    $self->indent_plus;
    $self->print_with_indent( sprintf("<%s>",$tag ) );
}
sub print_tab_close {
    my $self = shift;
    my ($tag) = @_;
    $self->print_with_indent( sprintf("</%s>",$tag ) );
    $self->indent_minus;
}
sub print_outline {
    my $self = shift;
    my ($value) = $_;
    $self->print_tab_and_attr( "outline" , "text" , $value );
}
sub print_outline_cloe {
    my $self = shift;
    $self->print_tab_close( "outline" );
}
sub print_one_tab_and_value {
    my $self = shift;
    my ($tag, $value) = @_;

    $self->indent_plus;
    $self->print_tab_open( $tag );
    $self->indent_plus;
    $self->print_with_indent( $value ); 
    $self->indent_minus;
    $self->print_tab_close( $tag );
    $self->indent_minus;
}
sub print_header {
    my $self = shift;
   
    $self->print_tab_open( 'head' ); 
    $self->print_one_tab_and_value( 'title' , '' );
    $self->print_one_tab_and_value( 'ownerEmail' , 'ykominami@gmail.com' );
    $self->print_tab_close( 'head' ); 
}

sub output_outline {
    my $self = shift;
    my $ks = $self->{ks};
    
#    my @ks = ('abc' , 'abc/de' , 'abc/de/fgh' , 'abc/de/lmn' , 'abc/gh');

    my $prev_len=0;
    my @prev_hier = ();
    my $cur_len=0;
    my @cur_hier = ();
    my @hier = ();
    
    $self->print_tab_open( "body" ); 

    $self->indent_plus;
    for my $k ( sort( @$ks ) ){
	#    print $k , "\n";
	@hier = split(/\//, $k);
	$cur_len = $#hier + 1;
	if( $prev_len < $cur_len ){
	    $self->push_hier( pop( @hier ) );
	}
	elsif ( $prev_len == $cur_len ){
	    $self->pop_hier();
	    $self->push_hier( pop( @hier ) );
	}
	else{
	    my $level = $prev_len;
	    while( $level >= $cur_len ){
		$self->pop_hier();
		$level--;
	    }
	    $self->push_hier( pop( @hier ) );
	}
	$prev_len = $cur_len;
    }
    $self->indent_minus;

    $self->flush_hier();

    $self->print_tab_close( "body" ); 
}

sub println {
    my $self = shift;
    my ($str) = @_;
    my $ofh = $self->{ofh};
    
    print $ofh $str, "\n";
#    print $str, "\n";
}


1;
