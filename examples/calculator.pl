# This is a Pegex precedence parser for arithmetic expressions that properly
# parses and evaluates expressions containing the following symbols:
#
#   Int -Int + - * / ^ ( )
#
# It demonstrates:
#
# * 3 levels of precedence.
# * Multiple operators at same precedence level
# * Operators of both left and right associativity

use Pegex;

my $grammar = <<'...';
expr: add_sub
add_sub: mul_div (/~([<PLUS><DASH>])~/ mul_div)*
mul_div: exp (/~([<STAR><SLASH>])~/ exp)*
exp: token (/~<CARET>~/ token)*
token: /~<LPAREN>~/ expr /~<RPAREN>~/ | number
number: /~(<DASH>?<DIGIT>+)~/
...

package Calculator;
use base 'Pegex::Receiver';

sub got_add_sub {
    my @list = flatten(pop);
    while (@list > 1) {
        my ($a, $op, $b) = splice(@list, 0, 3);
        unshift @list, ($op eq '+') ? ($a + $b) : ($a - $b);
    }
    $list[0];
}

sub got_mul_div {
    my @list = flatten(pop);
    while (@list > 1) {
        my ($a, $op, $b) = splice(@list, 0, 3);
        unshift @list, ($op eq '*') ? ($a * $b) : ($a / $b);
    }
    $list[0];
}

sub got_exp {
    my @list = flatten(pop);
    while (@list > 1) {
        my ($a, $b) = splice(@list, -2, 2);
        push @list, $a ** $b;
    }
    $list[0];
}

sub flatten {
    ref($_[0]) ? map flatten($_), @{$_[0]} : $_[0];
}

package main;

while (1) {
    print "\nEnter an equation: ";
    my $input = <>;
    chomp $input;
    last unless length $input;
    calc($input);
}

sub calc {
    my $expr = shift;
    my $calculator = pegex($grammar, receiver => 'Calculator');
    my $result = eval { $calculator->parse($expr) };
    print $@ || "$expr = $result\n";
}

# calc '2';
# calc '2 * 4';
# calc '2 * 4 + 6';
# calc '2 + 4 * 6 + 1';
# calc '2 + (4 + 6) * 8';
# calc '(((2 + (((4 + (6))) * (8)))))';
# calc '2 ^ 3 ^ 2';
# calc '2 ^ (3 ^ 2)';
# calc '2 * 2^3^2';
# calc '(2^5)^2';
# calc '2^5^2';
# calc '0*1/(2+3)-4^5';
# calc '2/3+1';