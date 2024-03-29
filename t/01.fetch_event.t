# Fetch test (Offline mock)
use Test::More;
use strict;
use warnings;
use utf8;

use WebService::Zussar;

use DateTime::Format::ISO8601;
use File::Slurp qw//;
use FindBin;
use Plack::Loader;
use Test::TCP;
use Data::Dumper;

# Prepare the Test API response
my $test_api = sub {
	my $content = File::Slurp::read_file("$FindBin::Bin/data/sample_event.json");
	[ 200, [ 'Content-Type' => 'application/json' ], [ $content ] ];
};

# Prepare the Expected patterns (It's same as a part of item values of Test API response)
my @expect_patterns = (
	{
		owner_nickname => '__papix__',
		catch => '囲め! ゆーすけべーさん!!',
		event_id => '489104'
	},
	{
		owner_nickname => 'Kansai Perl Mongers',
		catch => '関西のPerlユーザーによる、Perlユーザーのための集会',
		event_id => '476003'
	},
);

my $expect_patterns_i = 0;

# Prepare a Test client
my $client = sub {
	my $baseurl = shift;

	# Initialize a instance
	my $obj = WebService::Zussar->new(baseurl => $baseurl);
	# Fetch events
	$obj->fetch('event');

	# Iterate a fetched events
	while(my $event = $obj->next) {
		# Compare values of item, with Expected pattern
		my $ptn = $expect_patterns[$expect_patterns_i];
		foreach(keys %$ptn){
			is($event->$_, $ptn->{$_}, "Item > $_");
		}
		$expect_patterns_i += 1;
	}

	# Reverse iterate a fetched events
	$expect_patterns_i = @expect_patterns - 1;
	while(my $event = $obj->prev) {
		# Compare values of item, with Expected pattern
		my $ptn = $expect_patterns[$expect_patterns_i];
		foreach(keys %$ptn){
			is($event->$_, $ptn->{$_}, "Item > $_");
		}
		$expect_patterns_i -= 1;
	}

	# Iterate a fetched events, only 1 item
	{
		my $event = $obj->next;
		
		# Compare values of item, with Expected pattern
		my $ptn = $expect_patterns[0];
		foreach(keys %$ptn){
			is($event->$_, $ptn->{$_}, "Item > $_");
		}
	}

	# Reverse iterate a fetched events, only 1 item
	{
		my $event = $obj->prev;
		
		# Compare values of item, with Expected pattern
		my $ptn = $expect_patterns[0];
		foreach(keys %$ptn){
			is($event->$_, $ptn->{$_}, "Item > $_");
		}
	}
};

# Test a module
test_tcp(
	client => sub {
		# Test client
		my $port = shift; # Test API server port
		my $baseurl = "http://127.0.0.1:$port/";
		# Initialize module, and fetch (with specified baseurl by Test API server)
		$client->($baseurl);
	},
	server => sub {
		# Test API server (It serves a Test API response)
		my $port = shift;
		my $server = Plack::Loader->auto(port => $port, host => '127.0.0.1',);
		$server->run($test_api);
	},
);

# End
done_testing;