package Run::Env;

=head1 NAME

Run::Env - running environment detection

=head1 SYNOPSIS

	MyLogger->set_level('ERROR')
		if Run::Env::production;

	my $config = 'config.cfg';
	$config = 'test-config.cfg'
		if Run::Env::testing;
	
	print Dumper \$config
		if Run::Env::debug;
	
	print 'Content-Type: text/html'
		if Run::Env::cgi || Run::Env::mod_perl;

=head1 DESCRIPTION

There can be 3 running environments:

	qw{
		development
		staging
		production
	}

'development' are machines that the developers run.
'staging' is where the code is tested before going to the production.
'production' is the wilde world in production.

In all of them we can turn on debugging.

In all of them we can set testing. That is when the tests are run.

Module id using module variables to store envs and modes so the first time
it is initialized/set it will be the same in all other modules that
include it. Module is also using %ENV variables ('RUN-ENV_*') so that
the initialized/set envs and modes are propagated also to the shell scripts
that can be executed by system() or ``. 

=cut

use warnings;
use strict;

use Carp::Clan ();
use File::Spec ();
use FinBin ();

our $VERSION = '0.01';


our @running_envs =	qw{
	development
	staging
	production
};

our @execution_modes = qw{
	cgi
	mod_perl
	shell
};


my $os_root_dir  = File::Spec->rootdir();
# should be more portable, if you need it write and send me the patch ;)
my @os_conf_location = ($os_root_dir, 'etc');


=head1 METHODS



=cut

sub import {
	foreach my $env (@_) {
		# TODO;
	}
}


=head2 running environment

=cut

do {
	our $running_env    = set(detect_running_env());
	sub set {
		my $set_running_env = shift;
		
		if ($set_running_env eq 'developent') {
			set_development();
		}
		elsif ($set_running_env eq 'staging') {
			set_staging();
		}
		elsif ($set_running_env eq 'production') {
			set_production();
		}
		else {
			Carp::Clan::croak 'no such running environment: '.$set_running_env;
		}
	}
	
	sub detect_running_env {
		return $ENV{'RUN-ENV_current'}
			if $ENV{'RUN-ENV_current'};
	
		return 'development'
			if (-e File::Spec->catfile(@os_conf_location, 'development-machine'));
		return 'staging'
			if (-e File::Spec->catfile(@os_conf_location, 'staging-machine'));
	
		# default is production
		return 'production';
	}
	
	sub development {
		return _decide('development');
	}
	
	sub set_development {
		_set('development');
	}
	
	sub staging {
		return _decide('staging');
	}
	
	sub set_staging {
		_set('staging');
	}
	
	sub production {
		return _decide('production');
	}
	
	sub set_production {
		_set('production'); 
	}
	
	sub _decide {
		return 1 if $running_env eq shift;
		return 0;	
	}
	
	sub _set {
		my $set_running_env = shift;
		$running_env = $set_running_env;
		$ENV{'RUN-ENV_current'} = $set_running_env; 
	}
	
	sub current {
		return $running_env;
	}
}

=head2 debug mode

=cut

do {
	our $debug_mode = set_debug($ENV{'RUN-ENV_debug'});
	
	sub debug {
		return $debug_mode;
	}
	
	sub set_debug {
		# turn on debugging when called whitout argument
		set_debug(1) if (@_ == 0);
		
		$debug_mode = shift;
		$ENV{'RUN-ENV_debug'} = $debug_mode;
	}
	
	sub clear_debug {
		$debug_mode = 0;
		delete $ENV{'RUN-ENV_debug'};
	}
}


=head2 execution mode


=cut

do {
	our $execution_mode = set_execution(detect_execution_mode());
	sub execution {
		return $execution_mode;
	}
	
	sub cgi {
		return _decide_execution('cgi');
	}
	
	sub set_cgi {
		_set_execution('cgi');
	}
	
	sub mod_perl {
		return _decide_execution('mod_perl');
	}
	
	sub set_mod_perl {
		_set_execution('mod_perl');
	}
	
	sub shell {
		return _decide_execution('shell');
	}
	
	sub set_shell {
		_set_execution('shell');
	}
	
	sub set_execution {
		my $set_execution = shift;
		
		if ($set_execution eq 'cgi') {
			set_cgi();
		}
		elsif ($set_execution eq 'mod_perl') {
			set_mod_perl();
		}
		elsif ($set_execution eq 'shell') {
			set_shell();
		}
		else {
			Carp::Clan::croak 'no such execution mode: '.$set_execution;
		}
	}
	
	sub _set_execution {
		my $set_execution = shift;
		$execution_mode = $set_execution;
	}}
	
	sub _decide_execution {
		return 1 if $execution eq shift;
		return 0;	
	}
	
	sub detect_execution_mode {
		return 'mod_perl'
			if exists $ENV{'MOD_PERL'};
		return 'cgi'
			if exists $ENV{'REQUEST_METHOD'};
		return 'shell';
	}
}

=head2 testing mode

=cut

do {
	our $testing        = detect_testing();
	sub detect_testing {
		return 1
			if $ENV{'RUN-ENV_testing'}
	
		# testing if current folder is 't'
		my @current_path = File::Spec->splitdir($FindBin::Bin);
		return 1
			if (pop @current_path eq 't');
	
		return 0;
	}
	
	sub testing {
		return $testing;
	}
	
	sub set_testing {
		# turn on testing when called whitout argument
		set_testing(1) if (@_ == 0);

		$testing = shift;
		$ENV{'RUN-ENV_testing'} = $testing;
	}
	
	sub clear_testing {
		$testing = 0;
		delete $ENV{'RUN-ENV_testing'};
	}
}


qq/ I wonder what is Domm actually listenning to at the moment ;) /;


__END__


=head1 USAGE

According to the Run::Env decide what logleves to show in the logger.

Whan running tests it make sence to skip (or include) particular
tests depending if run on developers machine, as a staging or
production machine.

If running in teststing mode configuration loading and parsing module
can decide to include additional path (ex. ./) to search for a configuration.

=head1 AUTHOR

Jozef Kutej

=cut
