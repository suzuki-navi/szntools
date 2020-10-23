use strict;
use warnings;
use utf8;

my @tags = @ARGV;

sub isMatch {
    my ($cond) = @_;
    foreach my $tag (@tags) {
        if ($cond eq $tag) {
            return 1;
        }
    }
    return '';
}

my @stack = ();

while (my $line = <STDIN>) {
    $line =~ s/\n\z//g;
    my $output = "";
    if ($line =~ /\A\s*#if\s+([\s_a-zA-Z0-9]+)\s*\z/) {
        my @conds = split(/\s+/, $1);
        if (@stack && $stack[0]) {
            unshift(@stack, '');
        } else {
            my $f = '';
            foreach my $cond (@conds) {
                if (isMatch($cond)) {
                    $f = 1;
                    last;
                }
            }
            unshift(@stack, $f);
        }
    } elsif ($line =~ /\A\s*#else\s*\z/) {
        if (shift(@stack)) {
            unshift(@stack, '');
        } else {
            unshift(@stack, 1);
        }
    } elsif ($line =~ /\A\s*#endif\s*\z/) {
        shift(@stack);
    } else {
        if (!@stack || $stack[0]) {
            $output = $line . "\n";
        }
    }
    print $output;
}
