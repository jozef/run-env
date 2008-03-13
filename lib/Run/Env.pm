package Run::Env;

=head1 NAME

Run::Env - running environment detection

=head1 SYNOPSIS

	MyLogger->set_log_level('ERROR')
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

There can be 3 execution modes:

	qw{
		cgi
		mod_perl
		shell
	};


In all of them we can turn on debugging.

In all of them we can set testing. That is when the tests are run.

Module is using module global variables to store envs and modes so the first time
it is initialized/set it will be the same in all other modules that
use it as well. Module is also using %ENV variables ('RUN_ENV_*') so that
the initialized/set envs and modes are propagated to the shell scripts
that can be executed by system() or ``. 

=cut

use warnings;
use strict;

use Carp::Clan ();
use File::Spec ();
use FindBin ();
use List::MoreUtils 'any';

our $VERSION = '0.01_03';


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
# should be more portable, if you need it, write and send me the patch ;)
our @os_conf_location = ($os_root_dir, 'etc');


=head1 METHODS

=head2 import()

You can pass any running environment or execution environment
or 'testing' or 'debug' to force them, '-debug', '-testing' to
clear them.

	use Run::Env qw( testing debug );
	# or
	use Run::Env 'production';
	# or
	use Run::Env '-debug';

=cut

sub import {
	my $class = shift;
	
	foreach my $env (@_) {
		next if not $env;
		
		  $env eq 'testing'  ? set_testing()
		: $env eq '-testing' ? clear_testing()
		: $env eq 'debug'    ? set_debug()
		: $env eq '-debug'   ? clear_debug()
		: any { $env eq $_ } @running_envs
		                     ? set($env)
		: any { $env eq $_ } @execution_modes
		                     ? set_execution($env)
		: Carp::Clan::croak 'no such env/mode: '.$env
	}
}


=head2 running environment

=cut

do {
	our $running_env    = set(detect_running_env());
	
=head3 detect_running_env()

Detects in which environment are we running. First checks the
C<$ENV{'RUN_ENV_current'}> and then check for a presence of
special file in system configuration directories. Currently
is lookup for:

	/etc/development-machine
	/etc/staging-machine

The default running environment is production.

=cut
	
	sub detect_running_env {
		return $ENV{'RUN_ENV_current'}
			if $ENV{'RUN_ENV_current'};
	
		return 'development'
			if (-e File::Spec->catfile(@os_conf_location, 'development-machine'));
		return 'staging'
			if (-e File::Spec->catfile(@os_conf_location, 'staging-machine'));
	
		# default is production
		return 'production';
	}

=head3 current()

Return current running environment.

=cut
	
	sub current {
		return $running_env;
	}

=head3 development()

Return true/false if curently running in development environment.

=cut
	
	sub development {
		return _decide('development');
	}

=head3 staging()

Return true/false if curently running in staging environment.

=cut
	
	sub staging {
		return _decide('staging');
	}

=head3 production()

Return true/false if curently running in production environment.

=cut
	
	sub production {
		return _decide('production');
	}

=head3 set($running_env)

Set one of the 'development', 'staging', 'production'
that is passed as argument.

=cut
	
	sub set {
		my $set_running_env = shift;
		
		if ($set_running_env eq 'development') {
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

=head3 set_development()

Set running environment to development.

=cut
	
	sub set_development {
		_set('development');
	}

=head3 set_staging()

Set running environment to staging.

=cut
	
	sub set_staging {
		_set('staging');
	}

=head3 set_production()

Set running environment to production.

=cut
	
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
		$ENV{'RUN_ENV_current'} = $set_running_env; 
	}

};

=head2 debug mode

=cut

do {
	our $debug_mode = set_debug(detect_debug());

=head3 debug()

Return true/false if curently running with debug on.

=cut
	
	sub debug {
		return $debug_mode;
	}

=head3 set_debug()

Turn on debug mode.

Option is to pass an argument then the debug status is set depending
on that argument.

=cut
	
	sub set_debug {
		# turn on debugging when called whitout argument
		return set_debug(1) if (@_ == 0);
		
		$debug_mode = shift;
		if ($debug_mode) {
			$ENV{'RUN_ENV_debug'} = $debug_mode;
		}
		else {
			clear_debug();
		}
	}

=head3 clear_debug()

Turn off debug.

=cut
	
	sub clear_debug {
		$debug_mode = 0;
		delete $ENV{'RUN_ENV_debug'};
	}

=head3 detect_debug()

Detect if debug is on or off.

On if C<$ENV{'RUN_ENV_debug'}> set and true or if any of the
@ARGV is '--debug'.

=cut
	
	sub detect_debug {
		return 1 if $ENV{'RUN_ENV_debug'};
		return 1 if any { $_ eq '--debug' } @ARGV;
		return 0;
	}
};


=head2 execution mode

=cut

do {
	our $execution_mode = set_execution(detect_execution());

=head3 execution()

Return how the script is executed: cgi || mod_perl || shell.

=cut

	sub execution {
		return $execution_mode;
	}

=head3 cgi()

Return true/false if script is executed as cgi.

=cut
	
	sub cgi {
		return _decide_execution('cgi');
	}
	
=head3 mod_perl()

Return true/false if script is executed in mod_perl.

=cut
	
	sub mod_perl {
		return _decide_execution('mod_perl');
	}
	
=head3 shell()

Return true/false if script is executed as schell script.

=cut
	
	sub shell {
		return _decide_execution('shell');
	}
	
	sub _decide_execution {
		return 1 if $execution_mode eq shift;
		return 0;	
	}
	
=head3 set_execution()

Set current execution mode.

=cut
	
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

=head3 detect_execution()

Detect execution mode based on the %ENV variables.
'mod_perl if C<'$ENV{'MOD_PERL'}> is set. 'cgi' if
C<$ENV{'REQUEST_METHOD'}> is set. Otherwise 'shell'.

=cut
	
	sub detect_execution {
		return 'mod_perl'
			if exists $ENV{'MOD_PERL'};
		return 'cgi'
			if exists $ENV{'REQUEST_METHOD'};
		return 'shell';
	}

=head3 set_cgi()

Set execution mode to cgi.

=cut

	sub set_cgi {
		_set_execution('cgi');
	}

=head3 set_mod_perl()

Set execution mode to mod_perl.

=cut

	sub set_mod_perl {
		_set_execution('mod_perl');
	}

=head3 set_shell()

Set execution mode to shell.

=cut

	sub set_shell {
		_set_execution('shell');
	}

	sub _set_execution {
		my $set_execution = shift;
		$execution_mode = $set_execution;
	}
	
};


=head2 testing mode

=cut

do {
	our $testing = set_testing(detect_testing());

=head3 testing()

Return true/false if script is executed in testing mode.

=cut
	
	sub testing {
		return $testing;
	}

=head3 detect_testing

Try to detect testing mode. Checks for C<$ENV{'RUN_ENV_testing'}>
or it the current working folder is 't/'.

=cut
	
	sub detect_testing {
		return 1
			if $ENV{'RUN_ENV_testing'};
	
		# testing if current folder is 't'
		my @current_path = File::Spec->splitdir($FindBin::Bin);
		return 1
			if (pop @current_path eq 't');
	
		return 0;
	}

=head3 set_testing

Turn on testing mode.

=cut

	sub set_testing {
		# turn on testing when called whitout argument
		return set_testing(1) if (@_ == 0);

		$testing = shift;
		if ($testing) {
			$ENV{'RUN_ENV_testing'} = $testing;
		}
		else {
			clear_testing();
		}
	}

=head3 clear_testing

Turn off testing mode.

=cut 
	
	sub clear_testing {
		$testing = 0;
		delete $ENV{'RUN_ENV_testing'};
	}
};


qq/ I wonder what is Domm actually listenning to at the moment ;) /;


__END__


=head1 USAGE EXAMPLES

According to the Run::Env decide what logleves to show in the logger.
Disable debug and info and show only errors.

When running tests you can skip (or include) particular
tests depending if run on a developer, a staging or
a production machine.

If running in testing mode configuration loading and parsing module
can decide to include additional path (ex. ./) to search for a configuration.

Disable access to some special web test sections if running in production. 

=head1 TODO

	* have status functions also for the interactive io? (chk. IO::Interactive)

=head1 AUTHOR

Jozef Kutej

=cut
