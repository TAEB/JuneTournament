#!/usr/bin/perl
use strict;
use warnings;

my @faq = map {chomp; $_} <>;

my @questions;
my $question = '';
my $answer = '';

for (@faq, '---')
{
  if ($_ eq '---')
  {
    push @questions, [$question, $answer];
    $question = '';
    $answer = '';
  }
  else
  {
    if ($question eq '')
    {
      $question = $_;
    }
    else
    {
      if (!/^\s*</) # does it look like plaintext?
      {
        $_ = "<p>$_</p>";
      }
      $answer .= "    $_\n";
    }
  }
}

pop @questions while $questions[-1][0] eq '';

print << "EOH";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>The 2007 June nethack.alt.org Tournament - FAQ</title>
  </head>

  <body>
    <h1>The June 2007 nethack.alt.org Tournament - FAQ</h1>
    <ol>
EOH

foreach my $num (1..@questions)
{
  my $question = $questions[$num-1][0];
  print "      <li><a href=\"#q$num\">$question</a></li>\n";
}

print "    </ol>\n";

foreach my $num (1..@questions)
{
  my ($question, $answer) = @{$questions[$num-1]};
  chomp $answer;
  print << "EOH2";
    <hr />
    <h2 id="q$num">$num. $question</h2>
$answer
EOH2
}

print << "EOH3";
  </body>
</html>
EOH3
