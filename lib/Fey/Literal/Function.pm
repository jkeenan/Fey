package Fey::Literal::Function;

use strict;
use warnings;

use Scalar::Util qw( blessed );

use Moose::Policy 'Fey::Policy';
use Moose;
use Moose::Util::TypeConstraints;

extends 'Fey::Literal';

with 'Fey::Role::Comparable', 'Fey::Role::Selectable',
     'Fey::Role::Orderable', 'Fey::Role::Groupable';

has 'function' =>
    ( is       => 'ro',
      isa      => 'Str',
      required => 1,
    );

subtype 'FunctionArg'
    => as 'Fey::Literal | Fey::Column'
    => where { $_->does('Fey::Role::Selectable') };

coerce 'FunctionArg'
    => from 'Undef'
    => via { Fey::Literal::Null->new() }
    => from 'Value'
    => via { Fey::Literal->new_from_scalar($_) };

{
    my $constraint = find_type_constraint('FunctionArg');
    subtype 'FunctionArgs'
        => as 'ArrayRef'
        => where { for my $arg ( @{$_} ) { $constraint->check($arg) || return; } 1; };

    coerce 'FunctionArgs'
        => from 'ArrayRef'
        => via { [ map { $constraint->coerce($_) } @{ $_ } ] };
}

has 'args' =>
    ( is         => 'ro',
      isa        => 'FunctionArgs',
      default    => sub { [] },
      coerce     => 1,
      auto_deref => 1,
    );

has 'alias_name' =>
    ( is      => 'ro',
      isa     => 'Str',
      writer  => '_set_alias_name',
    );

no Moose;
__PACKAGE__->meta()->make_immutable();


sub new
{
    my $class = shift;

    if ( @_ % 2 || $_[0] ne 'function' )
    {
        return $class->new( function => shift,
                            args     => [ @_ ],
                          );
    }
    else
    {
        return $class->SUPER::new(@_);
    }
}

sub sql
{
    my $sql = $_[0]->function();
    $sql .= '(';

    $sql .=
        ( join ', ',
          map { $_->sql( $_[1] ) }
          $_[0]->args()
        );
    $sql .= ')';
}

sub sql_with_alias
{
    $_[0]->_make_alias()
        unless $_[0]->alias_name();

    my $sql = $_[0]->sql( $_[1] );

    $sql .= ' AS ';
    $sql .= $_[1]->quote_identifier( $_[0]->alias_name() );

    return $sql;
}

{
    my $Number = 0;
    sub _make_alias
    {
        my $self = shift;

        $self->_set_alias_name( 'FUNCTION' . $Number++ );
    }
}

sub sql_or_alias
{
    return $_[1]->quote_identifier( $_[0]->alias_name() )
        if $_[0]->alias_name();

    return $_[0]->sql( $_[1] );
}

sub is_groupable { $_[0]->alias_name() ? 1 : 0 }


1;

__END__

=head1 NAME

Fey::Literal::Function - Represents a literal function in a SQL statement

=head1 SYNOPSIS

  my $function = Fey::Literal::Function->new( 'LENGTH', $column );

=head1 DESCRIPTION

This class represents a literal function in a SQL statement, such as
C<NOW()> or C<LENGTH(User.username)>.

=head1 INHERITANCE

This module is a subclass of C<Fey::Literal>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal::Function->new( $function, @args )

This method creates a new C<Fey::Literal::Function> object.

It requires at least one argument, which is the name of the SQL
function that this literal represents. It can accept any number of
additional optional arguments. These arguments must be either scalars,
literals, or columns which belong to a table.

Any scalars passed in as arguments will be passed in turn to C<<
Fey::Literal->new_from_scalar() >>.

=head2 $function->function()

The function's name, as passed to the constructor.

=head2 $function->args()

Returns the function's arguments, as passed to the constructor.

=head2 $function->sql()

=head2 $function->sql_with_alias()

=head2 $function->sql_or_alias()

Returns the appropriate SQL snippet.

Calling C<< $function->sql_with_alias() >> causes a unique alias for
the function to be created.

=head1 ROLES

This class does the C<Fey::Role::Selectable>,
C<Fey::Role::Comparable>, C<Fey::Role::Groupable>, and
C<Fey::Role::Orderable> roles.

This class overrides the C<is_groupable()> and C<is_orderable()>
methods so that they only return true if the C<<
$function->sql_with_alias() >> has been called previously. This
function is called when a function is used in the C<SELECT> clause of
a query. A function must be used in a C<SELECT> in order to be used in
a C<GROUP BY> or C<ORDER BY> clause.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
