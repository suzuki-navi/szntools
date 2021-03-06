use strict;
use warnings;
use utf8;

my $SLESS_HOME = $ENV{"SLESS_HOME"};

my $format = "";
my $verbose_flag = "";
my $color_flag = "";
my $number_flag = 0;

my @recursive_option = ();

my $target_file = undef;

while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "-f") {
        $format = shift(@ARGV);
        push(@recursive_option, $a, $format);
    } elsif ($a eq "-v") {
        $verbose_flag = 1;
        push(@recursive_option, $a);
    } elsif ($a eq "-N") {
        $number_flag = 1;
        push(@recursive_option, $a);
    } elsif ($a eq "-n") {
        $number_flag = -1;
        push(@recursive_option, $a);
    } elsif ($a eq "--color") {
        $color_flag = 1;
        push(@recursive_option, $a);
    } elsif ($a eq "--") {
        $target_file = shift(@ARGV);
    } else {
        die "Unknown argument: $a\n";
    }
}

if (defined($target_file)) {
    open(STDIN, '<', $target_file);
}

my $head_size = 100 * 4096;

my $head_buf = "";

my $left_size = $head_size;
my $gzip_flag = '';
my $xz_flag = '';
while () {
    if ($left_size <= 0) {
        last;
    }
    my $head_buf2;
    my $l = sysread(STDIN, $head_buf2, $left_size);
    if ($l == 0) {
        last;
    }
    $head_buf .= $head_buf2;
    if ($left_size >= $head_size - 2) {
        if ($head_buf =~ /\A\x1F\x8B/) {
            $gzip_flag = 1;
            last;
        }
    }
    if ($left_size >= $head_size - 6) {
        if ($head_buf =~ /\A\xFD\x37\x7A\x58\x5A\x00/) {
            $xz_flag = 1;
            last;
        }
    }
    $left_size -= $l;
}

if ($gzip_flag || $xz_flag) {
    my $READER1;
    my $WRITER1;
    pipe($READER1, $WRITER1);

    my $pid1 = fork;
    die $! if (!defined $pid1);
    if (!$pid1) {
        # 読み込み済みの入力を標準出力し、残りはcatする
        close $READER1;
        open(STDOUT, '>&=', fileno($WRITER1));
        syswrite(STDOUT, $head_buf);
        exec("cat");
    }
    close $WRITER1;
    open(STDIN, '<&=', fileno($READER1));

    my $READER2;
    my $WRITER2;
    pipe($READER2, $WRITER2);

    my $pid2 = fork;
    die $! if (!defined $pid2);
    if (!$pid2) {
        # gunzip or xz のプロセスをexecする
        close $READER2;
        open(STDOUT, '>&=', fileno($WRITER2));
        if ($gzip_flag) {
            exec("gunzip", "-c");
        } elsif ($xz_flag) {
            exec("xz", "-c", "-d");
        } else {
            die;
        }
    }
    close $WRITER2;
    open(STDIN, '<&=', fileno($READER2));

    if ($verbose_flag) {
        if ($gzip_flag) {
            print "format=gzip\n";
        } elsif ($xz_flag) {
            print "format=xz\n";
        }
    }
    exec("perl", "$SLESS_HOME/format-wrapper.pl", @recursive_option);
}

sub guess_format {
    my ($head_buf) = @_;

    if (length($head_buf) >= 4) {
        my $b = substr($head_buf, 0, 4);
        if ($b eq "PK\x03\x04") {
            return "zip";
        } elsif ($b eq "PK\x05\x06") {
            return "zip";
        } elsif ($b eq "PK\x07\x08") {
            return "zip";
        }
    }
    if (length($head_buf) >= 265) {
        my $b = substr($head_buf, 257, 8);
        if ($b eq "ustar\x00\x30\x30") {
            return "tar";
        } elsif ($b eq "ustar  \x00") {
            return "tar";
        }
    }
    if ($head_buf =~ /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/) {
        return "binary";
    }

    if (length($head_buf) == 0) {
        return ""
    }
    my @lines = split(/\r?\n/, $head_buf);

    if ($lines[0] =~ /\A#!\//) {
        return "";
    }

    my $tsv = 0;
    my $json = 0;
    my $jsonl = 0;
    my $markdown = 0;
    my $perl = 0;
    if (@lines >= 2 && $lines[0] =~ /\t/ && $lines[1] =~ /\t/) {
        $tsv++;
    }
    if ($lines[0] =~ /\A\{/) {
        if (@lines >= 2 && $lines[1] =~ /\A\{/) {
            $jsonl++;
        } else {
            $json++;
        }
    }
    foreach my $line (@lines) {
        if ($line =~ /\A#+\s/) {
            $markdown++;
        } elsif ($line =~ /\A-\s/) {
            $markdown++;
        } elsif ($line =~ /\A\*\s/) {
            $markdown++;
        } elsif ($line =~ /\Ause\s+(strict|warnings|utf8)/) {
            $perl++;
        }
    }
    my $format = "";
    my $score = 0;
    $format = "tsv"      if $tsv      > $score;
    $format = "json"     if $json     > $score;
    $format = "jsonl"    if $jsonl    > $score;
    $format = "markdown" if $markdown > $score;
    $format = "perl"     if $perl     > $score;

    return $format;
}

exit(0) if length($head_buf) == 0;

if ($format eq '') {
    $format = guess_format($head_buf);
}

# フォーマットの推定結果を出力
if ($verbose_flag) {
    print "format=$format\n";
}

if (($format eq "json" || $format eq "jsonl") && $number_flag <= 0) {
    my $READER1;
    my $WRITER1;
    pipe($READER1, $WRITER1);

    my $pid1 = fork;
    die $! if (!defined $pid1);
    if (!$pid1) {
        # 読み込み済みの入力を標準出力し、残りはcatする
        close $READER1;
        open(STDOUT, '>&=', fileno($WRITER1));
        syswrite(STDOUT, $head_buf);
        exec("cat");
    }
    close $WRITER1;
    open(STDIN, '<&=', fileno($READER1));

    my @options = ();
    push(@options, ".");
    if ($color_flag) {
        push(@options, "-C");
    } else {
        push(@options, "-M");
    }
    if ($format eq "jsonl") {
        push(@options, "-c");
    }
    if ($number_flag < 0) {
        exec("bash", "$SLESS_HOME/jq.sh", @options);
    } else {
        exec("bash", "$SLESS_HOME/jqn.sh", @options);
    }
}

if ($format eq "tsv") {
    my $READER1;
    my $WRITER1;
    pipe($READER1, $WRITER1);

    my $pid1 = fork;
    die $! if (!defined $pid1);
    if (!$pid1) {
        # 読み込み済みの入力を標準出力し、残りはcatする
        close $READER1;
        open(STDOUT, '>&=', fileno($WRITER1));
        syswrite(STDOUT, $head_buf);
        exec("cat");
    }
    close $WRITER1;
    open(STDIN, '<&=', fileno($READER1));

    my @options = ();
    if ($color_flag) {
        push(@options, "--color");
    }
    exec("perl", "$SLESS_HOME/table.pl", @options);
}

if (defined($target_file)) {
    if ($format eq "zip") {
        close(STDIN);
        my @options = ("--", $target_file);
        exec("bash", "$SLESS_HOME/zip.sh", @options);
    }
}

if (1) {
    my $READER1;
    my $WRITER1;
    pipe($READER1, $WRITER1);

    my $pid1 = fork;
    die $! if (!defined $pid1);
    if (!$pid1) {
        # 読み込み済みの入力を標準出力し、残りはcatする
        close $READER1;
        open(STDOUT, '>&=', fileno($WRITER1));
        syswrite(STDOUT, $head_buf);
        exec("cat");
    }
    close $WRITER1;
    open(STDIN, '<&=', fileno($READER1));

    if ($format eq "zip") {
        my @options = ();
        exec("bash", "$SLESS_HOME/zip.sh", @options);
    } elsif ($format eq "tar") {
        my @options = ("tv");
        exec("bash", "$SLESS_HOME/tar.sh", @options);
    } elsif ($format eq "binary") {
        my @options = ("-C");
        exec("bash", "$SLESS_HOME/hexdump.sh", @options);
    } else {
        my @options = ();
        if ($color_flag) {
            push(@options, "--color=always");
        } else {
            push(@options, "--color=never");
        }
        if ($number_flag >= 0) {
            push(@options, "-n");
        } else {
            push(@options, "-p");
        }
        if ($format ne "") {
            push(@options, "--language=$format");
        }
        exec("bash", "$SLESS_HOME/bat.sh", @options);
    }
}

