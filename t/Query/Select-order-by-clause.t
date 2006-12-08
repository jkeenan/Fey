use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 10;

use Q::Literal;
use Q::Query;


my $s = Q::Test->mock_test_schema_with_fks();

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    eval { $q->order_by() };
    like( $@, qr/0 parameters/,
          'at least one parameter is required for order_by()' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->order_by( $s->table('User')->column('user_id') );
    is( $q->_order_by_clause(), q{ORDER BY "User"."user_id"},
        'order_by() one column' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->order_by( $s->table('User')->column('user_id'), 'ASC' );
    is( $q->_order_by_clause(), q{ORDER BY "User"."user_id" ASC},
        'order_by() one column' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->order_by( $s->table('User')->column('user_id'), 'DESC' );
    is( $q->_order_by_clause(), q{ORDER BY "User"."user_id" DESC},
        'order_by() one column' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->order_by( $s->table('User')->column('user_id'),
                  $s->table('User')->column('username'), 'ASC'
                );
    is( $q->_order_by_clause(), q{ORDER BY "User"."user_id", "User"."username" ASC},
        'order_by() two columns' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->order_by( $s->table('User')->column('user_id'), 'DESC',
                  $s->table('User')->column('username'), 'ASC'
                );
    is( $q->_order_by_clause(), q{ORDER BY "User"."user_id" DESC, "User"."username" ASC},
        'order_by() two columns' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    $q->order_by( $s->table('User')->column('user_id')
                  ->alias( alias_name => 'alias_test' ) );

    is( $q->_order_by_clause(), q{ORDER BY "alias_test"},
        'order_by() column alias' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $now = Q::Literal->function( 'NOW' );
    $now->_make_alias();

    $q->order_by($now);

    like( $q->_order_by_clause(), qr/ORDER BY "FUNCTION\d+"/,
        'order_by() function' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $now = Q::Literal->function( 'NOW' );

    eval { $q->order_by($now) };
    like( $@, qr/is orderable/,
          'cannot order by function with no alias' );
}

{
    my $q = Q::Query->new( dbh => $s->dbh() )->select();

    my $term = Q::Literal->term( q{"Foo"::text} );
    $q->order_by($term);

    is( $q->_order_by_clause(), q{ORDER BY "Foo"::text},
        'order_by() term' );
}
