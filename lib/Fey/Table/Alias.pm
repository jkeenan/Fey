package Fey::Table::Alias;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_ro_accessors
    ( qw( alias_name table ) );

use Class::Trait ( 'Fey::Trait::Joinable' );

use Fey::Exceptions qw(param_error);
use Fey::Validate
    qw( validate validate_pos
        SCALAR_TYPE
        TABLE_TYPE );

use Fey::Table;

{
    for my $meth ( qw( schema name ) )
    {
        eval <<"EOF";
sub $meth
{
    shift->table()->$meth(\@_);
}
EOF
    }
}

{
    my %Numbers;
    my $spec = { table      => TABLE_TYPE,
                 alias_name => SCALAR_TYPE( optional => 1 ),
               };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        unless ( $p{alias_name} )
        {
            my $name = $p{table}->name();
            $Numbers{$name} ||= 1;

            $p{alias_name} = $name . $Numbers{$name}++;
        }

        return bless \%p, $class;
    }
}

{
    my $spec = (SCALAR_TYPE);
    sub column
    {
        my $self = shift;
        my ($name) = validate_pos( @_, $spec );

        return $self->{columns}{$name}
            if $self->{columns}{$name};

        my $col = $self->table()->column($name)
            or return;

        my $clone = $col->_clone();
        $clone->_set_table($self);

        return $self->{columns}{$name} = $clone;
    }
}

sub columns
{
    my $self = shift;

    my @cols = @_ ? @_ : map { $_->name() } $self->table()->columns();

    return map { $self->column($_) } @cols;
}

sub primary_key { return $_[0]->columns( map { $_->name() } $_[0]->table()->primary_key ) }

sub is_alias { 1 }

sub sql_with_alias
{
    return
        (   $_[1]->quote_identifier( $_[0]->table()->name() )
          . ' AS '
          . $_[1]->quote_identifier( $_[0]->alias_name() )
        );
}

sub id { $_[0]->alias_name() }


1;

__END__

=head1 NAME

Fey::Table - Represents an alias for a table

=head1 SYNOPSIS

  my $alias = $user_table->alias();

  my $alias = $user_table->alias( alias_name => 'User2' );

=head1 DESCRIPTION

This class represents an alias for a table. Table aliases allow you to
join the same table more than once in a query, which makes certain
types of queries simpler to express.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Table::Alias->new()

This method constructs a new C<Fey::Table::Alias> object. It takes the
following parameters:

=over 4

=item * table - required

This is the C<Fey::Table> object which we are aliasing.

=item * alias_name - optional

This should be a valid table name for your DBMS. If not provided, a
unique name is automatically created.

=back

=head2 $alias->table()

Returns the C<Fey::Table> object for which this object is an alias.

=head2 $alias->alias_name()

Returns the name for this alias.

=head2 $alias->name()

=head2 $alias->schema()

These methods work like the corresponding methods in
C<Fey::Table>. The C<name()> method returns the real table name.

=head2 $alias->column($name)

=head2 $alias->columns()

=head2 $alias->columns(@names)

=head2 $alias->primary_key()

These methods work like the corresponding methods in
C<Fey::Table>. However, the columns they return will return the alias
object when C<< $column->table() >> is called.

=head2 $alias->is_alias()

Always returns true.

=head2 $alias->sql_with_alias()

Returns the appropriate SQL snippet for the alias.

=head2 $alias->id()

Returns a unique string identifying the alias.

=head1 TRAITS

This class does the C<Fey::Trait::Joinable> trait.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
