#!/usr/bin/perl -w

#    This file is part of GibCounter QuakeForge player rating
#    Copyright (C) 2003  Stanislaw Y. Pusep
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#    E-Mail:    stanis@linuxmail.org
#    Site:      http://sysdlabs.hypermart.net/

use 5.0;
use strict;
use Env qw(HOME);

my $VERSION = '0.1';
my $dir = @ARGV ? shift : "$HOME/.quakeforge/qw";
my %log = map { $_, (stat ($_))[9] } <$dir/frag*.log>;

unless (%log) {
   print STDERR "$0 - GibCounter QuakeForge player rating v$VERSION by Stas\n",
                "URL http://sysdlabs.hypermart.net/; email <stanis\@linuxmail.org>\n\n",

                "Usage: $0 [frag*.log directory]\n",
                "\t(by default \$HOME/.quakeforge/qw is used)\n";
   exit 0;
}

my $width = 300;
my $total = 0;
my $death = 0;
my (%frag, %kill, %deth, %self, %perf);

my @log = sort {
   $log{$a} <=> $log{$b}
      ||
   ($a =~ /(\d+)/)[0] <=> ($b =~ /(\d+)/)[0]
} keys %log;

foreach my $log (@log) {
   print STDERR " * reading $log\n";
   open (LOG, $log) || die "can't open log file $log: $!";
   while (<LOG>) {
      chomp;
      my ($killer, $killed) = (m%^\\(.*?)\\(.*?)\\$%);
      next if $killer =~ /^(user\-\d+|unnamed)$/;
      unless ($killer eq $killed) {
         $total++;
         $frag{$killer}++;
         $kill{$killer}++;
      } else {
         $total--;
         $frag{$killer}--;
         $self{$killer}++;
      }
      $deth{$killed}++;
      $death++;
   }
   close LOG;
}

print STDERR "\n\nProcessing...\n";
my @rating = sort { $frag{$b} <=> $frag{$a} } keys %frag;
unless (@rating) {
   print STDERR "ERROR: no statistics to be processed!\n";
   exit;
}

print <<HEADER_END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
    <meta http-equiv="Content-Language" content="en">
    <meta name="GENERATOR" content="GibCounter v$VERSION">
    <link rel="stylesheet" href="gibcounter.css" type="text/css">
    <title>GibCounter QuakeForge player rating</title>
  </head>

  <body>
    <h1>GibCounter QuakeForge player rating</h1>

    <br>

    <table align="center" summary="">
      <tr>
        <th>#:</th>
        <th>Nickname:</th>
        <th>Rating:</th>
        <th>Frags:</th>
        <th>Kills:</th>
        <th>Deaths:</th>
        <th>Suicides:</th>
      </tr>

HEADER_END
;

my $max = $width / ($frag{$rating[0]} / $total);

my $num = 1;
foreach my $name (@rating) {
   $frag{$name} = defined $frag{$name} ? $frag{$name} : 0;
   $kill{$name} = defined $kill{$name} ? $kill{$name} : 0;
   $deth{$name} = defined $deth{$name} ? $deth{$name} : 0;
   $self{$name} = defined $self{$name} ? $self{$name} : 0;

   if ($frag{$name} > 0) {
      $perf{$name} = $frag{$name} / $deth{$name};
   }

   my $funname = &qf2htm ($name);
   my $rank = $max * ($frag{$name} / $total);
   my $bar = 'pbar';
   if ($rank <= 0) {
      $bar = 'nbar';
      $rank *= -1;
   }
   my $prc = $bar eq 'pbar' ? sprintf '%.2f', 100 * ($rank / $max) : '0.00';
   $rank = int ($rank);

   print <<PLAYER_END
      <tr>
        <td class="num">$num.</td>
        <td class="nick">$funname</td>
        <td class="rating">
          <table cellpadding="0" cellspacing="0" summary="">
            <tr>
              <td><div class="$bar" style="width: ${rank}px"></div></td>
              <td class="prc">${prc}%</td>
            </tr>
          </table>
        </td>
        <td class="frags">$frag{$name}</td>
        <td class="kills">$kill{$name}</td>
        <td class="deaths">$deth{$name}</td>
        <td class="suicides">$self{$name}</td>
      </tr>
PLAYER_END
;

   $num++;
}

my $since = scalar localtime $log{$log[0]};
my $until = scalar localtime time;

my @perf = sort { $perf{$b} <=> $perf{$a} } keys %perf;
my $fragger = &qf2htm ($perf[0]) . sprintf (' with %.02f <i>frag/death</i> ratio', $perf{$perf[0]});
my $fragged = &qf2htm ($perf[-1]) . sprintf (' with %.02f <i>death/frag</i> ratio', 1 / $perf{$perf[-1]});

print <<SUMMARY_END
    </table>

    <br><br>

    <table align="center" summary="">
      <tr>
        <th>Summary:</th>
        <th>Value:</th>
      </tr>

      <tr>
        <td class="summary">Logs processed since:</td>
        <td class="value"><i>$since</i></td>
      </tr>

      <tr>
        <td class="summary">Logs processed until:</td>
        <td class="value"><i>$until</i></td>
      </tr>

      <tr>
        <td class="summary">Total # of deaths:</td>
        <td class="value">$death</td>
      </tr>

      <tr>
        <td colspan="2"><hr></td>
      </tr>

      <tr>
        <td class="summary">Top Fragger:</td>
        <td class="value">$fragger</td>
      </tr>

      <tr>
        <td class="summary">Top Fragged:</td>
        <td class="value">$fragged</td>
      </tr>
SUMMARY_END
;


print <<FOOTER_END
    </table>
    
    <br><br>
    
    <table class="footer" summary="">
      <tr>
        <td class="gen">
          &laquo;&nbsp;
          Generated by
          <a href="http://sysdlabs.hypermart.net/proj/#gib" target="_blank">GibCounter</a>
          <a href="http://www.quakeforge.net/" target="_blank">QuakeForge</a>
          player rating
          &nbsp;&raquo;
        </td>
        <td class="val">
          <a href="http://validator.w3.org/check/referer"><img border="0"
              src="http://www.w3.org/Icons/valid-html401"
              alt="Valid HTML 4.01!" height="31" width="88"></a>
          &nbsp;
          <a href="http://jigsaw.w3.org/css-validator/">
            <img style="border:0;width:88px;height:31px"
                   src="http://jigsaw.w3.org/css-validator/images/vcss" 
                   alt="Valid CSS!">
          </a>
        </td>
      </tr>
    </table>
                                  
  </body>
</html>
FOOTER_END
;


print STDERR "\nDone!\n";
exit;


sub qf2asc {
   ### ripped from quakeforge-0.5.2/libs/util/sys.c
   ### (ported to Perl by Stas)

   #/* The translation table between the graphical font and plain ASCII  --KB */
   #const char sys_char_map[256] = {
   my @sys_char_map = (
        "\0", '#', '#', '#', '#', '.', '#', '#',
        '#', chr(9), chr(10), '#', ' ', chr(13), '.', '.',
        '[', ']', '0', '1', '2', '3', '4', '5',
        '6', '7', '8', '9', '.', '<', '=', '>',
        ' ', '!', '"', '#', '$', '%', '&', "'",
        '(', ')', '*', '+', ',', '-', '.', '/',
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', ':', ';', '<', '=', '>', '?',
        '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
        'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
        'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
        'X', 'Y', 'Z', '[', '\\', ']', '^', '_',
        '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g',
        'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
        'p', 'q', 'r', 's', 't', 'u', 'v', 'w',
        'x', 'y', 'z', '{', '|', '}', '~', '<',

        '<', '=', '>', '#', '#', '.', '#', '#',
        '#', '#', ' ', '#', ' ', '>', '.', '.',
        '[', ']', '0', '1', '2', '3', '4', '5',
        '6', '7', '8', '9', '.', '<', '=', '>',
        ' ', '!', '"', '#', '$', '%', '&', "'",
        '(', ')', '*', '+', ',', '-', '.', '/',
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', ':', ';', '<', '=', '>', '?',
        '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
        'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
        'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
        'X', 'Y', 'Z', '[', '\\', ']', '^', '_',
        '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g',
        'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
        'p', 'q', 'r', 's', 't', 'u', 'v', 'w',
        'x', 'y', 'z', '{', '|', '}', '~', '<'
   );
   #};


   my $qstr = shift;
   my $str = '';
   for (my $i = 0; $i < length ($qstr); $i++) {
      my $chr = substr ($qstr, $i, 1);
      $str .= $sys_char_map[ord ($chr)];
   }
   return $str;
}

sub qf2htm {
   ### ripped from quakeforge-0.5.2/libs/console/server.c
   ### (ported to Perl by Stas)

   #static chtype attr_table[4] = {
   #    A_NORMAL,
   #    COLOR_PAIR(1),
   #    COLOR_PAIR(2),
   #    COLOR_PAIR(3),
   #};

   my @attr_table = (
        qw0     => 'white',
        qw1     => 'orange',
        qw2     => 'gold',
        qw3     => 'brown',
   );

   #static const byte attr_map[256] = {
   my @attr_map = (
        3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 0, 3, 3,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 0, 3, 3,
        2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   );
   #};


   my $qstr = shift;
   my $str = '';
   my $last = 'UNDEFINED';
   for (my $i = 0; $i < length ($qstr); $i++) {
      my $chr = substr ($qstr, $i, 1);
      my $asc = &qf2asc ($chr);

      if ($asc eq '<') {
         $asc = '&lt;'
      } elsif ($asc eq '>') {
         $asc = '&gt;'
      } elsif ($asc eq '&') {
         $asc = '&amp;'
      }

      my $clr = $attr_table[$attr_map[ord ($chr)] * 2];

      if ($clr ne $last) {
         $str .= '</span>' if $i;
         $str .= "<span class=\"$clr\">$asc";
      } else {
         $str .= $asc;
      }

      $last = $clr;
   }
   return "$str</span>";
}
