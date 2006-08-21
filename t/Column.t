use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 11;


use_ok( 'Q::Column' );

{
    eval { my $s = Q::Column->new() };
    like( $@, qr/Mandatory parameters .+ missing/,
          'name, generic_type and type are required params' );
}

{
    my $c = Q::Column->new( name         => 'Test',
                            type         => 'foobar',
                            generic_type => 'text',
                          );

    is( $c->name(), 'Test', 'column name is Test' );
    is( $c->type(), 'foobar', 'column type is foobar' );
    is( $c->generic_type(), 'text', 'column generic type is text' );
    ok( ! defined $c->length(), 'column has no length' );
    ok( ! defined $c->precision(), 'column has no precision' );
    ok( ! $c->is_auto_increment(), 'column is not auto increment' );
    ok( ! $c->is_nullable(), 'column defaults to not nullable' );
}

{
    my $c = Q::Column->new( name        => 'Test',
                            type        => 'text',
                            is_nullable => 1,
                          );

    ok( $c->is_nullable(), 'column is nullable' );
}
{
    require Q::Table;

    my $t = Q::Table->new( name => 'Test' );
    my $c1 = Q::Column->new( name         => 'test_id',
                             type         => 'text',
                           );

    $t->add_column($c1);

    undef $t;
    ok( ! $c1->table(), q{column's reference to table is weak} );
}
