package Parser::parimatch;

use strict;
use Data::Dumper;
use LWP::UserAgent;
use XML::Parser;
#use JSON;
#use base 'Exporter';
#our @EXPORT = ('parser_parimatch');

our $data;
our %currentOdds;
my %mapping = ( Sport => 'sport',
        Tournament => 'tourney',
        Date => 'datetime',
        HomeTeam => 'team1',
        AwayTeam => 'team2'
        );


sub run {
    my $cfg = shift;
    my $write_log = shift;
    my $url = $cfg->{url};
    return "No URL defined" unless $url;

    $write_log->("Running parimatch parse");

    my $agent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0";

    my $ua = LWP::UserAgent->new;
    $ua->agent($agent);
    $ua->timeout(10);

    my $response = $ua->get($url);

    if ($response->is_success) {
        my $parser = XML::Parser->new();
        $parser->setHandlers( Start => \&startElement,
                End => \&endElement,
                Char => \&characterData,
                ); 
        $parser->parse($response->decoded_content); 
        my @dataArr;
        foreach (keys %{$data}) {
            push @dataArr, $data->{$_};
        }
        my %result = ( lastUpdate => time,
                       feed => 'parimatch',
                       data => \@dataArr );
        #return encode_json \@dataArr;
        #return encode_json \%result;
        return \%result;
    }
    else {
        die $response->status_line;
    }
}

sub startElement {
    my( $parseinst, $element, %attrs ) = @_;
    #print "Element: $element\n";
}

sub endElement {
    my( $parseinst, $element ) = @_;
    if ($element eq "OddsObject") {
        my $matchId = $currentOdds{MatchId};
        my $oddsType = $currentOdds{OddsType};
        $data->{$matchId}->{team1} = $currentOdds{team1};
        $data->{$matchId}->{team2} = $currentOdds{team2};
        $data->{$matchId}->{datetime} = $currentOdds{datetime};
        $data->{$matchId}->{sport} = $currentOdds{sport};
        $data->{$matchId}->{tourney} = $currentOdds{tourney};
        $data->{$matchId}->{islive} = 'unknown';
        $data->{$matchId}->{url} = 'unknown';
        if ($oddsType eq '2W') {
            $data->{$matchId}->{'2w'}->{0}->{1} = $currentOdds{HomeOdds};
            $data->{$matchId}->{'2w'}->{0}->{2} = $currentOdds{AwayOdds};
        }         
        elsif ($oddsType eq '3W' || $oddsType eq 'HalfTime 3W') {     
            my $time;
            if ($oddsType eq '3W') {
                $time = 0; 
            } elsif ($oddsType eq 'HalfTime 3W') {
                $time = 1;
            }
            $data->{$matchId}->{'3w'}->{$time}->{1} = $currentOdds{HomeOdds};
            $data->{$matchId}->{'3w'}->{$time}->{2} = $currentOdds{AwayOdds};
            $data->{$matchId}->{'3w'}->{$time}->{x} = $currentOdds{DrawOdds};
        } 
        elsif ($oddsType eq 'Total') {
            $data->{$matchId}->{totals}->{0}->{$currentOdds{Total}}->{over} = $currentOdds{OverOdds};
            $data->{$matchId}->{totals}->{0}->{$currentOdds{Total}}->{under} = $currentOdds{UnderOdds};
        } 
        elsif ($oddsType eq 'Asian Handicap') {
            $data->{$matchId}->{ah}->{0}->{0}->{1} = $currentOdds{SpreadHome};
            $data->{$matchId}->{ah}->{0}->{0}->{2} = $currentOdds{SpreadAway};
            $data->{$matchId}->{ah}->{0}->{1}->{1} = $currentOdds{SpreadOddsHome};
            $data->{$matchId}->{ah}->{0}->{1}->{2} = $currentOdds{SpreadOddsAway};
        }
        elsif ($oddsType eq 'First Team to score') {
            $data->{$matchId}->{fgoal}->{1} = $currentOdds{HomeScores};
            $data->{$matchId}->{fgoal}->{2} = $currentOdds{AwayScores};
        }
        elsif ($oddsType eq 'Goal/NoGoal') {
            $data->{$matchId}->{fgoal}->{0} = $currentOdds{NoGoal};
        }
        #else { print "!!!!!!!".$oddsType."!!!!!\n\n"; }
        undef %currentOdds;
    }
}


sub characterData {
    my( $parseinst, $data ) = @_;
    my $context = $parseinst->{Context}->[-1];
    $context = (defined $mapping{$context})?$mapping{$context}:$context;
    $currentOdds{$context} = $data;
}

1;
