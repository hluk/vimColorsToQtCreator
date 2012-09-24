#!/usr/bin/perl
=license
    Copyright (C) 2012  Lukas Holecek

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

use strict;
use warnings;
use File::Temp;

my $version = '0.9.0';

if (not defined($ARGV[0]) or $ARGV[0] eq '-h' or $ARGV[0] eq '--help') {
    print
'Usage: '.$0.' {colorscheme} [light|dark]

vimColorToQtCreator v'.$version.'

Convert vim color schemes so they can be used in Qt Creator.

Examples:
    '.$0.' molokai
    '.$0.' soso
    '.$0.' solarized dark

Copy output files into Qt Creator\'s styles directory (usually "$HOME/.config/Nokia/qtcreator/styles").

Pay respect to the authors of the Vim color schemes.

';
    exit 0 if defined($ARGV[0]);
    exit 2;
}

my %dict = (
    Normal => ['Text', 'Local', 'SearchScope'],

    htmlLink => ['Link|underline=true'],
    Visual => ['Selection'],
    LineNr => ['LineNumber', 'DisabledCode'],
    Search => ['SearchResult'],
    MatchParen => ['Parentheses', 'Occurrences'],
    CursorLine => ['CurrentLine'],
    CursorLineNr => ['CurrentLineNumber'],
    SpellCap => ['Occurrences.Unused'],
    SpellRare => ['Occurrences.Rename'],

    Number => ['Number'],
    String => ['String'],
    Type => ['Type'],
    Identifier => ['Field'],
    cEnum => ['Static'],
    Function => ['Function', 'VirtualMethod|italic="true"'],
    Keyword => ['Keyword'],
    Operator => ['Operator'],
    PreProc => ['Preprocessor'],
    Label => ['Label'],
    Comment => ['Comment'],
    SpecialComment => ['Doxygen.Comment'],
    Todo => ['Doxygen.Tag'],
     #=> ['VisualWhitespace'],

    # TODO: Add QML syntax support.
     #=> ['QmlLocalId'],
     #=> ['QmlExternalId'],
     #=> ['QmlTypeId'],
     #=> ['QmlRootObjectProperty'],
     #=> ['QmlScopeObjectProperty'],
     #=> ['QmlExternalObjectProperty'],
     #=> ['JsScopeVar'],
     #=> ['JsImportVar'],
     #=> ['JsGlobalVar'],
     #=> ['QmlStateName'],
     #=> ['Binding'],

    DiffAdd => ['AddedLine'],
    DiffDelete => ['RemovedLine'],
    DiffText => ['DiffFile', 'DiffLocation'],

     #=> ['LastStyleSentinel'],
);

my ($fh, $filename) = File::Temp::tempfile();
close $fh;

my $color = $ARGV[0];
my $bg = defined($ARGV[1]) ? $ARGV[1] : "light";
my $outfilename = "$color-$bg.xml";
system("gvim", "-f", "-c",
    ":set bg=$bg".
    "|colo $color".
    "|so \$VIMRUNTIME/syntax/hitest.vim".
    "|ru! syntax/2html.vim".
    "|w! $filename".
    "|qa\!");

open($fh, "<", $filename) or die "Cannot open input file \"$filename\"";;
open(my $fh2, ">", $outfilename) or die "Cannot open output file \"$outfilename\"";
print "Saving to \"$outfilename\".\n";
select $fh2;

print '<?xml version="1.0" encoding="UTF-8"?>
<style-scheme version="1.0" name="'."$color - $bg".'">
  <!-- This file was generated using vimColorsToQtC.pl. -->
';

my %normal = (bg => "ff00ff", fg => "ff00ff", italic => "false", bold => "false", underline => "false");
my %styles = (
    "Normal" => \%normal
);
while(<$fh>) {
    chomp;
    if (/^\.(\w+)\s+{ ((color: (?<fg>[^;]+);|background-color: (?<bg>[^;]+);|font-weight: bold(?<bold>);|font-style: italic(?<italic>);|text-decoration: underline(?<underline>);|padding-bottom: 1px(?<underline>);|\w+=\S+) )+/) {
        my $opts = defined($styles{$1}) ? $styles{$1} : ();
        $opts->{bg} = $+{bg} if defined($+{bg});
        $opts->{fg} = $+{fg} if defined($+{fg});
        $opts->{italic} = "true" if defined($+{italic});
        $opts->{bold} = "true" if defined($+{bold});
        $opts->{underline} = "true" if defined($+{underline});
        $styles{$1} = $opts;
    } else {
        my @spans = split '</span>';
        foreach (@spans) {
            if (/<span class="([^"]+)">(.+)/ or /(\S+)    *(\S+)/) {
                next unless defined($dict{$2});
                my $style = $styles{$1} or ();
                foreach (@{$dict{$2}}) {
                    print "  <style name=\"$1\" " .
                          ' background="' . ($+{bg} or @{$style}{bg} or $normal{bg}) . '"' .
                          ' foreground="' . ($+{fg} or @{$style}{fg} or $normal{fg}) . '"' .
                          ' italic="' . ($+{italic} or @{$style}{italic} or $normal{italic}) . '"' .
                          ' bold="' . ($+{bold} or @{$style}{bold} or $normal{bold}) . '"' .
                          ' underline="' . ($+{underline} or @{$style}{underline} or $normal{underline}) . '"' .
                          "/>\n" if /([^|]+)\|?((background="(?<bg>[^"]+)"|color="(?<fg>[^"]+)"|bold="(?<bold>[^"]+)"|italic="(?<italic>[^"]+)"|underline="(?<underline>[^"]+)")\s*)*/;
                }
                delete $dict{$2};
            }
        }
    }
}

print '</style-scheme>';

close $fh;
close $fh2;
unlink $filename or die "Cannot remove temporary file \"$filename\"!";

