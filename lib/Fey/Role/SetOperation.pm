package Fey::Role::SetOperation;

use strict;
use warnings;

use MooseX::Role::Parameterized;
use MooseX::Params::Validate qw( pos_validated_list );

parameter keyword =>
(
    isa => 'Str',
    required => 1,
);

with 'Fey::Role::SQL::HasOrderByClause',
     'Fey::Role::SQL::HasLimitClause';

has 'is_all' =>
    ( is      => 'rw',
      isa     => 'Bool',
      default => 0,
      writer  => '_set_is_all',
    );

has '_set_element' =>
    ( metaclass => 'Collection::Array',
      is        => 'ro',
      isa       => 'ArrayRef',
      default   => sub { [] },
      provides  => { push     => '_add_set_elements',
                     elements => '_set_elements',
                     count    => '_set_element_count',
                   },
      init_arg  => undef,
    );

sub all
{
    $_[0]->_set_is_all(1);
    return $_[0];
};

sub bind_params
{
    my $self = shift;
    return 
        ( map { $_->bind_params } $self->_set_elements
        );
};

role {
    my $p = shift;

    my $name = lc($p->keyword);

    my $clause_method = $name . '_clause';

    method 'keyword_clause' => sub
    {
        my $self = shift;

        my $sql = uc($name);
        $sql .= ' ALL' if $self->is_all;
        return $sql;
    };

    method 'sql' => sub
    {
        my $self = shift;
        my $dbh  = shift;

        return
            ( join ' ',
              $self->$clause_method($dbh),
              $self->order_by_clause($dbh),
              $self->limit_clause($dbh),
            );
    };


    method $name => sub
    {
        my $self = shift;

        my $count = @_;
        $count = 2 if $count < 2 and $self->_set_element_count < 2;

        my (@set) = 
            pos_validated_list( \@_,
                                ( ( { isa => 'Fey::SQL::Select' } ) x $count ),
                                MX_PARAMS_VALIDATE_NO_CACHE => 1,
                              );

        $self->_add_set_elements(@set);

        return $self;
    };

    method $clause_method => sub
    {
        my $self = shift;
        my $dbh  = shift;

        return
            ( join ' ' . $self->keyword_clause($dbh) . ' ',
              map { '(' . $_->sql($dbh) . ')' }
              $self->_set_elements
            );
    };
};

no MooseX::Role::Parameterized;

1;

__END__

=head1 NAME

Fey::Role::SetOperation - A role for things that are like a set operation

=head1 SYNOPSIS

  use Moose;

  with 'Fey::Role::SetOperation' => { keyword => $keyword };

=head1 DESCRIPTION

Classes which do this role represent a query which can include multiple
C<SELECT> queries.

=head1 PARAMETERS

=head2 keyword

The SQL keyword for this set operation (i.e. C<UNION>, C<INTERSECT>,
C<EXCEPT>).

=head1 METHODS

This role provides the following methods, where C<$keyword> is the C<keyword>
parameter, above:

=head2 $query->$keyword()

  $union->union($select1, $select2, $select3);

Adds to the C<SELECT> queries that this set operation includes.

A set operation must include at least two queries, so the first time this is
called, at least two selects must be provided; subsequent calls do not suffer
this constraint.

=head2 $query->all()

Sets whether or not C<ALL> is included in the SQL for this set operation (e.g.
C<UNION ALL>).

=head2 $query->is_all()

Returns true if C<< $query->all() >> has previously been called.

=head2 $query->keyword_clause()

Returns the SQL keyword and possible C<ALL> for this set operation.

=head2 $query->${keyword}_clause()

  print $query->union_clause();

Returns each of the selects for this set operation, joined by the
C<keyword_clause>.

=head1 ROLES

This class includes C<Fey::Role::SQL::HasOrderByClause> and
C<Fey::Role::SQL::HasLimitClause>.

=head1 AUTHOR

Hans Dieter Pearcey <hdp.cpan.fey@weftsoar.net>

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut