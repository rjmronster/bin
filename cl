#!/usr/local/bin/perl


#  Script to manipulate columnar data.

$din = " "; $delo = "  "; $dell = "\n";
$pi = 4 * atan2(1,1);
$d2r = $pi/180; $r2d = 180/$pi;
$d3r = $r3d = 1;
$log10 = log(10);

@funs = ("sin", "cos", "tan", "asin", "acos", "atan", "atan2",
  "neg", "add", "subt", "mul", "div", "pow",
  "abs", "norm", "log10");

@cons = ("nc", "cc", "pi", "d2r", "r2d");

while (@ARGV) {
  $arg = shift(@ARGV);
  if ($arg =~ /^-$/) { $stdin_flag = 1; }
  elsif ($arg =~ /^-l$/) { $literal = 1 }
  elsif ($arg =~ /^-s/) { $skip = $' }
  elsif ($arg =~ /^-i/) { $infile = shift(@ARGV); open(INFILE, $infile) }
  elsif ($arg =~ /^-h/i) { `$0 -_$arg | more > /dev/tty`; exit; }
  elsif ($arg =~ /^-_-he/i) { $help_flag = 1; goto USAGE }
  elsif ($arg =~ /^-_-h/i) { goto USAGE }
  elsif ($arg =~ /^-d($|e)/) { $d3r = $d2r; $r3d = $r2d }
  elsif ($arg =~ /^-do/) { $delo = &slash(shift(@ARGV)); }
  elsif ($arg =~ /^-dl/) { $dell = &slash(shift(@ARGV)); }
  elsif ($arg =~ /^-db/) { $delb = &slash(shift(@ARGV)); }
  elsif ($arg =~ /^-di/) { $din = &slash(shift(@ARGV)); }
  elsif ($arg =~ /^-bug/) { $bug = 1 }
  elsif ($arg =~ /^-%/) { $format = "%$'" }
  elsif ($arg =~ /^-if/) { $precond = &parsley(shift(@ARGV)) }
  elsif ($arg =~ /^-post/) { $postcond = &parsley(shift(@ARGV)) }
  else {
    if ($format) { $format_in[$nx_in] = $format }
    $ex_in[$nx_in++] = $argg = $arg;
  }
}

# implicit filename argument
if (!$stdin_flag && !$infile && open(INFILE, $argg)) {
  $infile = $argg;
  $nx_in--;
}

if (!$nx_in) { goto USAGE }

if (!$stdin_flag && !$infile && (-t STDIN)) {
  die "$0: Sorry, no file to open\n";
}

if (!@format_in && $format) {
  for ($ix = 0; $ix < $nx_in; $ix++) { $format_in[$ix] = $format }
}

sub stuff_ex {
  $format_ex[$nex] = $format_in[$_[0]];
  $ex[$nex] = $_[1];
  $nex++;
}


$nex = 1;
local($i, $ix);
for ($ix = 0; $ix < $nx_in; $ix++) {
  $_ = $ex_in[$ix];
  if ($literal) { &stuff_ex($ix, &parsley($_)); next }
  if (/^(\d+)$/) { &stuff_ex($ix, "\$c[$1]") }
  elsif (/^(\d+)-(\d+)$/) {
    for ($i = $1; $i <= $2; $i++) { &stuff_ex($ix, "\$c[$i]") }
  }
  elsif (/^-(\d+)$/) {
    for ($i = 1; $i <= $1; $i++) { &stuff_ex($ix, "\$c[$i]") }
  }
  elsif (/^(\d+)-$/) {
    # flag to indicate "here to the end"
    $flag_ex[$nex] = 1;
    &stuff_ex($ix, $1);
  }
  else { &stuff_ex($ix, &parsley($_)) }
}


if ($bug) {
  for ($ix = 1; $ix <= $nex; $ix++) {
    print $ex[$ix];
    if ($flag_ex[$ix]) { print "{$flag_ex[$ix]}"; }
    if ($ix < $nex) { print "  "; }
  }
  if ($precond) { print "\npre: $precond" }
  if ($postcond) { print "\npost: $postcond" }
  print "\n", "-"x70, "\n";
}


while ($_ = $infile ? <INFILE> : <STDIN>) {
  @p = @c;
  $nline++;
  if ($nline < $skip) { next }
  chop;
  $cc = $_;
  if ( $din == " " ) {
      @c = split(" ", $_);
  } else {
      @c = split($din, $_);
  }
  unshift(@c, $nline);
  if ($nline == $skip) { next }
  if (!@f) { @f = @c }
  $nc = $#c;
  for ($i = 1; $i <= $nc; $i++) {
    # standardize exponential notation
    if ($c[$i] =~ /^[\+\-]?[\d\.]+[dD][\+\-]?\d+$/) { $c[$i] =~ s/[dD]/e/ }
  }
  if ($precond && !eval($precond)) { next }
  for ($ix = 1, $io = 0; $ix <= $nex; $ix++) {
    if ($flag_ex[$ix]) {
      for ($ixx = $ex[$ix]; $ixx <= $nc; $ixx++) {
        $o[++$io] = &formit($format_ex[$ix], $c[$ixx]);
      }
    }
    else {
      $o[++$io] = &formit($format_ex[$ix], eval($ex[$ix]));
    }
  }
  if ($postcond && !eval($postcond)) { next }
  print $delb, join($delo, @o[1..$io]), $dell;
  if ($@) { $@ =~ s/ in file \(eval\).*$//; print STDERR "$0: ", $@; }
}
exit;


sub formit {
  local($form, $expr) = @_;
  if ($form && $form ne "%") { $expr = sprintf($form, $expr) }
  $expr;
}


# parse given expression to prepare for evaluation
sub parsley {
  local($a, $b, $d, $i, $nn);
  $_ = $_[0];
  while (/.\cH/) { s/.\cH// }
  s/^\s*//;
  s/\s*$//;
  s/\s+/ /g;
  s/\#.*//;

  while (/\b([pfoc])(\d+)\b/) { $_ = "$`(\$$1\[$2\])$'" }

  for $f (@funs) { s/\&*\b$f\b/\&$f/g }
  for $f (@cons) { s/\b$f\b/\$$f/g }

  # standardize exponential notation
  while (/\b([\d\.]+)([dD])([+-]\d+)\b/) { $_ = "$`$1e$3$'" }

  $_;
}


sub log10 { log($_[0])/$log10 }
sub norm { local($ans); while (@_) { $ans += shift(@_)**2 } sqrt($ans) }

sub sin { sin($d3r * $_[0]) }
sub cos { cos($d3r * $_[0]) }
sub tan { sin($d3r * $_[0])/cos($d3r * $_[0]) }
sub asin { $r3d * atan2($_[0], sqrt(1 - $_[0]**2)) }
sub acos { $r3d * atan2(sqrt(1 - $_[0]**2), $_[0]) }
sub atan { $r3d * atan2($_[0], 1) }
sub atan2 { $r3d * atan2($_[0], $_[1]) }

sub slash { $_ = $_[0]; s/\\n/\n/g; s/\\t/\t/g; $_ }

##########################################################################

USAGE: print "
Script to manipulate columnar data.  Provides a fraction of the functionality
of awk, with simplified syntax.

Usage:  cl  expr1  [expr2]  ...  [[-i] file]
        [-]  [-s(n_skip)]  [-deg]  [-%[format_spec]]
        [-if condition]  [-post post_condition]
        [-di delim_in]  [-do delim_out]  [-dl delim_l]  [-db delim_b]
";
if (!$help_flag) { print "
Examples:

           cl 1 3 data               (picks out columns 1 and 3 from file)
cat data | cl 1 3                    (same, from data stream)
cat data | cl 0 1 3                  (same, include line number counter \"c0\")
cat data | cl 2 -s4                  (prints 2nd column skipping first 4 lines)
cat data | cl 2 -if 'c0>4'           (same, implemented with condition)
cat data | cl -%.4f 2                (prints 2nd column, formatted)
cat data | cl 'sin(c4)' 'c1+c3**2'   (perform given operations on data stream)

Note the quoting, to avoid interpretation of special characters by shell.

For more help, type cl -help

"; }
else { print "
Each line of input is split into columns c1, c2, c3...  The columns of
output o1, o2, o3... are specified by the expr's in terms of these
variables.  The expr's should be quoted if they involve characters
having special meaning to the shell.

An extra \"column 0\", c0, simply counts the input lines.  The following
types of shorthand \"column specs\" are supported, to simply pick out the
given columns from the input:
    2  5-7  -4  9-
Here, \"-4\" is equivalent to \"1-4\", and \"9-\" means from 9 to the end.

A given output variable, say o7, can depend upon the following variables:

  c0, c1, c2,...    the input columns
  p0, p1, p2,...    the previous line of input
  f0, f1, f2,...    the first line of input
  nc                the number of input columns (not counting c0)
  cc                the entire input line
  o1, o2,..., o6    the already-calculated columns of the present output line

Numerical expressions are evaluated in double precision.  In general,
operations and functions are as in c/perl (with a few additions).
Here are some of the more important:

 (constants:)  pi
(operations:)  +, -, *, /, ** (exponentiation)
(1-var fcns:)  sqrt, abs, int, log, log10, exp, sin, cos, tan, asin, acos, atan
(other fcns:)  atan2(y,x)
               norm(x1,x2...xn)      (sqrt of sum of squares)


Options:

-s(n_skip)
  Skips n_skip input lines.  The line counter c0 records the original line
  numbers.  The variables f1, f2,... refer to the first line actually used,
  while the last skipped line is parsed to provide the initial values of
  p1, p2,...  Thus, the usage

    cat data | cl 'c2-p2' -s1

  will provide all the non-trivial differences between successive values of c2.


-%[format_spec]  (default: perl-style default format)
  Specify a single-variable format (in \"c style\") for a column or columns
  of the output line.  Specifications are \"sticky\": they are used for the
  expressions which follow, until a new one is given.  A simple \"-%\" reverts
  to the default.  For example:

    cat data | cl  -%.2f 1 '2*c2'  -%.8e 3  -% 4-

  will print the first column and twice the second with 4 decimal places,
  reformat the third to exponential notation with decimal places, and return
  to default to print the remaining columns with no reformatting.

  If a format specification is given AFTER all the expressions, and no others
  have been given, then that specification is used for ALL the output.


-deg
  set degrees mode for trigonometric functions


-i  in_file
  Read from an input file, instead of standard input.  The \"-i\" flag is
  optional if the filename appears at the end of the list of expressions.


-
  Read from standard input; don't try to interpret the last expression as
  a filename.  This avoids ambiguity, in case a file already exists whose
  name coincides with the final expression (e.g. \"7\", \"c3/c1\", etc.)


-l
  Literal interpretation of expressions: disables shorthand column specifiers,
  so that a \"3\" means to print a \"3\", not the third column, which can
  always be referred to as \"c3\", anyway.
  Without this flag, a literal \"3\" can be expressed as (for example) '(3)';
  the parentheses disable the shorthand parsing.


-di  delim_in     (default: white space)
  Set the delimeter used to split a line of input into columns (tab is \"\\t\").

-do  delim_out    (default: two spaces)
-dl  delim_line   (default: \"\\n\")
-db  delim_begin  (default: null)
  Set the delimeter between output columns, at the end of each line
  of output, and at the beginning of each line of output, respectively.

" }

