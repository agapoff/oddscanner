package oddscanner;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use Data::Dumper;
use IO::Socket;
use POSIX qw(strftime);
use Storable;
use JSON;

our $data;

my %dispatchGET = (
		'/hello' => \&resp_hello,
		);
my %dispatchPOST = (
		'/hello' => \&handle_post,
		);

our $cacheDir = '/var/cache/oddscanner/';

write_log ('Oddscanner initializing');

my $cfg = &read_config;

my %feeds = map { $_ => 1 } @{$cfg->{feeds}};

foreach my $feed ( keys %feeds ) {
    print "Starting scanner for $feed...\n" if ($cfg->{debug});
    write_log("Starting scanner for $feed...");
    next if $pid = fork;

    die "cannot fork: $!" unless defined $pid;
    write_log("Spawned child feed $feed with Pid $$");

    my $module = "Parser/$feed.pm";
    if (eval { require $module; 1; }) {
        print "Module $feed.pm loaded ok\n" if ($cfg->{debug});
        write_log ("Module $feed.pm loaded ok");
    } else {
        print "Could not load $feed.pm. Error Message: $@\n" if ($cfg->{debug});
        write_log ("Could not load $feed.pm. Error Message: $@");
        exit;
    }
    my $queryInterval = $cfg->{$feed}->{queryInterval} || $cfg->{queryInterval} || 60;
    my $lastUpdate = 0;
    while (1) {
        if ( time > $lastUpdate + $queryInterval ) {
            $lastUpdate = time;
            my $parsedData = "Parser::${feed}::run"->($cfg->{$feed},\&write_log);
            #$data->{$feed} = $parsedData;
            store $parsedData, $cacheDir.$feed.'.cache';
        }
        sleep 2;
    }
    exit;
}

    
while(0) {
    #if ($line =~ /"feed":"(\w+)"/) {
    #    print "Parent Pid $$ got message from feed $_\n";
    #    $data->{$_} = $line;
    #}
    ##print "Parent Pid $$ just read this: '$line'\n";
    if ( -e $cacheDir.'parimatch.cache' ) {
      my $d = retrieve($cacheDir.'parimatch.cache');
      print Dumper($d);
    }
    sleep 5;
}
#waitpid($pid,0);

sub handle_request {
	my $self = shift;
	my $cgi  = shift;

	my $path = $cgi->path_info();
	my $method = $cgi->request_method();
	my $ip = $cgi->http('X-Forwarded-For') || $cgi->http('x-forwarded-for') || $cgi->remote_addr();

    (my $clearPath = $path) =~ s/\///g;

	write_log ("$ip $method $path");

	my $handler = ($method eq "GET")?$dispatchGET{$path}:$dispatchPOST{$path};

	if (ref($handler) eq "CODE") {
		print "HTTP/1.0 200 OK\r\n";
		$handler->($cgi);
    } elsif (exists($feeds{$clearPath})) {
        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header;
        print getCache($clearPath);
	} else {
		print "HTTP/1.0 404 Not found\r\n";
		print $cgi->header,
		      $cgi->start_html('Not found'),
		      $cgi->h1('Not found'.Dumper($data)),
		      $cgi->end_html;
	}
}

sub getCache {
    my $feed = shift;
    if ( -e $cacheDir.$feed.'.cache' ) {
      my $cache = retrieve($cacheDir.$feed.'.cache');
      #print Dumper($d);
      return encode_json $cache;
    }
    return "[]";
}

sub resp_hello {
	my $cgi  = shift;   # CGI.pm object
		return if !ref $cgi;

	my $who = $cgi->http('X-Forwarded-For') || $cgi->http('x-forwarded-for') || $cgi->remote_addr();

	print $cgi->header,
	      $cgi->start_html("Hello"),
	      $cgi->h1("Hello $who!");
	print $cgi->h1(Dumper($cfg)) if ($cfg->{debug});
    print $cgi->span($data->{parimatch});
	print $cgi->end_html;
}

sub handle_post {
	my $cgi  = shift;
	return if !ref $cgi;
	write_log(Dumper($cgi)) if ($cfg->{debug});
}

sub read_config {
	use File::Basename;
	my $myPath = dirname(__FILE__);
	my %var;
	my $cf = $myPath."/config.ini"; 
    my $block;
	if (-s $cf and open(CONF, "<$cf")) {
		while (<CONF>) {
			chomp;
	    	next if /^\s*(#.*)*$/o; # skip comments and empty lines
            if (/^\[(.+)\]\s*$/) {
                $block = $1;
            }
			next unless /^(\S+)\s*=\s*([^#]*)/o;

			my ($key, $val) = ($1, $2);
			if ($val =~ /,/o) {
                if ($block) {
                    $var{$block}->{$key} = [ split(/,\s/, $val) ];
                } else {
				    $var{$key} = [ split(/,\s?/, $val) ];
                }
				next;
			}
			elsif ($val =~ /^'(.*)'$/o) {
				$val = $1;
			}
			elsif ($val =~ /^"(.*)"$/o) {
				$val = $1;
			}
            if ($block) {
                $var{$block}->{$key} = $val;
            } else {
			    $var{$key} = $val;
            }
		}
		close(CONF);
	}
	return \%var;
}

sub open_log ($;$) {
	my $filename = shift;
	my $lock = shift;
	my $tmpfh;
	defined($filename) or croak("no filename given to open_log()");
	open $tmpfh, ">>$filename" or die(3, "Error: failed to open file '$filename': $!");
	if($lock){
		flock($tmpfh, LOCK_EX | LOCK_NB) or quit(3, "Failed to aquire a lock on file '$filename', another instance of this code may be running?");
	}
	return $tmpfh;
}

sub write_log {
	my $text = shift;
	my $logfh = open_log("/var/log/oddscanner/oddscanner.log");
	my $date = strftime "%Y-%m-%d %H:%M:%S", localtime;
	print $logfh $date.' '.$text."\n";
	close $logfh;
	return;
}

sub is_private {
	my $ip = shift;
	if ($ip =~ /(^127\.0\.0\.1)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)/) {
		return 1;
	}
	return 0;
}


1;

__END__
