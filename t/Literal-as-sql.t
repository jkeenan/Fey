use strict;
use warnings;

use lib 't/lib';

use Fey::Test;
use Test::More tests => 29;

use Fey::Literal;
use Fey::Quoter;


{
    my $f = Fey::Quoter->new( dbh => Fey::Test->mock_dbh() );

    my $num = Fey::Literal::Number->new(1237);
    is( $num->sql_with_alias($f), '1237', 'number sql_with_alias is 1237' );
    is( $num->sql_or_alias($f), '1237', 'number sql_or_alias is 1237' );
    is( $num->sql($f), '1237',
        'number sql is 1237' );

    my $term = Fey::Literal::Term->new('1237.0');
    is( $term->sql_with_alias($f), '1237.0', 'term sql_with_alias is 1237.0' );
    is( $term->sql_or_alias($f), '1237.0',
        'term sql_or_alias is 1237.0' );
    is( $term->sql($f), '1237.0',
        'term sql is 1237.0' );

    $term = Fey::Literal::Term->new( q{"Foo"::text} );
    is( $term->sql_or_alias($f),
        q{"Foo"::text}, 'term sql_with_alias is "Foo"::text' );
    is( $term->sql_or_alias($f),
        q{"Foo"::text}, 'term sql_or_alias is "Foo"::text' );
    is( $term->sql($f),
        q{"Foo"::text}, 'term sql is "Foo"::text' );

    my $string = Fey::Literal::String->new('Foo');
    is( $string->sql_with_alias($f), q{'Foo'}, "string sql_with_alias is 'Foo'" );
    is( $string->sql_or_alias($f), q{'Foo'}, "string sql_or_alias is 'Foo'" );
    is( $string->sql($f), q{'Foo'}, "string sql is 'Foo'" );

    $string = Fey::Literal::String->new("Weren't");
    is( $string->sql_or_alias($f),
        q{'Weren''t'}, "string formatted is 'Weren''t'" );

    my $null = Fey::Literal::Null->new();
    is( $null->sql_with_alias($f), 'NULL', 'null sql_with_alias' );
    is( $null->sql_or_alias($f), 'NULL', 'null sql_or_alias' );
    is( $null->sql($f), 'NULL', 'null sql' );
}

{
    my $s = Fey::Test->mock_test_schema();
    my $dbh = Fey::Test->mock_dbh();

    my $f = Fey::Quoter->new( dbh => $dbh );

    my $now = Fey::Literal::Function->new( 'NOW' );
    is( $now->sql_with_alias($f), q{NOW() AS FUNCTION0},
        'NOW function sql_with_alias' );
    is( $now->sql_with_alias($f), q{NOW() AS FUNCTION0},
        'NOW function sql_with_alias - second time' );
    is( $now->sql_or_alias($f), q{"FUNCTION0"},
        'NOW function sql_or_alias - with alias' );
    is( $now->sql($f), 'NOW()',
        'NOW function sql - with alias' );

    my $now2 = Fey::Literal::Function->new( 'NOW' );
    is( $now2->sql_or_alias($f), q{NOW()},
        'NOW function sql_or_alias - no alias' );
    is( $now2->sql($f), q{NOW()},
        'NOW function sql - no alias' );

    my $avg =
        Fey::Literal::Function->new( 'AVG',
                                     $s->table('User')->column('user_id') );

    is( $avg->sql_or_alias($f), q{AVG("User"."user_id")},
        'AVG function formatted' );

    my $substr =
        Fey::Literal::Function->new( 'SUBSTR',
                                     $s->table('User')->column('user_id'),
                                     5, 2 );
    is( $substr->sql_or_alias($f), q{SUBSTR("User"."user_id", 5, 2)},
        'SUBSTR function formatted' );

    my $ifnull =
        Fey::Literal::Function->new( 'IFNULL',
                                     $s->table('User')->column('user_id'),
                                     $s->table('User')->column('username'),
                                   );
    is( $ifnull->sql_or_alias($f), q{IFNULL("User"."user_id", "User"."username")},
        'IFNULL function formatted' );

    my $concat =
        Fey::Literal::Function->new( 'CONCAT',
                                     $s->table('User')->column('user_id'),
                                     Fey::Literal::String->new(' '),
                                     $s->table('User')->column('username'),
                                   );
    is( $concat->sql_or_alias($f),
        q{CONCAT("User"."user_id", ' ', "User"."username")},
        'CONCAT function formatted' );

    my $ifnull2 =
        Fey::Literal::Function->new( 'IFNULL',
                                     $s->table('User')->column('user_id'),
                                     $concat,
                                   );
    is( $ifnull2->sql_or_alias($f),
        q{IFNULL("User"."user_id", CONCAT("User"."user_id", ' ', "User"."username"))},
        'IFNULL(..., CONCAT) function formatted' );

    my $avg2 =
        Fey::Literal::Function->new
            ( 'AVG',
              $s->table('User')->column('user_id')->alias( alias_name => 'uid' ) );
    is( $avg2->sql_or_alias($f), q{AVG("uid")},
        'AVG() with column alias as argument' );
}

{
    my $f = Fey::Quoter->new( dbh => Fey::Test->mock_dbh() );

    my $now = Fey::Literal::Function->new( 'NOW' );
    $now->_make_alias();

    like( $now->sql_or_alias($f), qr/FUNCTION\d+/,
        'NOW function formatted for compare when it has an alias returns alias' );
}

