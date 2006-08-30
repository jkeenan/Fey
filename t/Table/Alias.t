use strict;
use warnings;

use lib 't/lib';

use Q::Test;
use Test::More tests => 20;


use_ok( 'Q::Table::Alias' );


my $t = Q::Table->new( name => 'Test' );
my $c1 = Q::Column->new( name => 'test_id',
                         type => 'text',
                       );

my $c2 = Q::Column->new( name => 'size',
                         type => 'integer',
                       );

$t->add_column($_) for $c1, $c2;

{
    my $alias = $t->alias();
    isa_ok( $alias, 'Q::Table::Alias' );
    isa_ok( $alias, 'Q::Table' );

    is( $alias->name(), 'Test', 'name is Test' );
    is( $alias->alias_name(), 'Test1', 'alias_name is Test1' );
    is( $alias->id(), 'Test1', 'id is Test1' );

    ok( $alias->is_alias(), 'is_alias is true' );

    my $col = $alias->column('test_id');
    is( $col->table(), $alias,
        'table for column from alias is the alias table' );
    is( $col, $alias->column('test_id'),
        'column() method for alias just clones a column once' );

    my @cols = sort { $a->name() cmp $b->name() } $alias->columns();
    is( scalar @cols, 2, 'columns() returns 2 columns' );
    is( $cols[0]->name(), 'size', 'first col is size' );
    is( $cols[0]->table(), $alias, 'table for first col is alias' );
    is( $cols[1]->name(), 'test_id', 'second col is test_id' );
    is( $cols[1]->table(), $alias, 'table for second col is alias' );

    ok( ! $alias->column('no-such-thing'),
        'column() returns false for nonexistent column' );
}

{
    my $alias = $t->alias();
    is( $alias->alias_name, 'Test2', 'alias_name is Test2 - second alias' );
}

{
    my $alias = $t->alias( alias_name => 'Foo' );
    is( $alias->alias_name(), 'Foo', 'explicitly set alias name to foo' );
}

{
    my $s = Q::Test->mock_test_schema();

    my $alias = $s->table('User')->alias();
    is( $alias->schema(), $s, 'schema method returns correct schema' );

    my @pk = $alias->primary_key();
    is( scalar @pk, 1, 'one column in primary key' );
    is( $pk[0], $s->table('User')->column('user_id'),
        'primary_key() returns same columns as non-alias' );
}
