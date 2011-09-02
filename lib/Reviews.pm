package Reviews;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use Sys::Hostname;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader::Multi
    +CatalystX::SimpleLogin
    Static::Simple
	Unicode::Encoding
	Authentication
	Authorization::Roles
	Session
	Session::State::Cookie
	Session::Store::FastMmap
    Compress
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in reviews.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

# Getting hostname
my ($host) = Sys::Hostname::hostname() =~ m/^([^\.]+)/;

# Putting Events in the @INC
$ENV{'PERL5LIB'} .= ':' . __PACKAGE__->path_to('../Events/lib');

__PACKAGE__->config(
    name => 'Reviews',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    using_frontend_proxy   => 1,
    default_view           => 'TT',
    'Plugin::ConfigLoader' => {
        file                => __PACKAGE__->path_to('../Events/conf/'.'events_'
        . $host.'.conf'),
    },
    ENCODING => 'utf-8',
    # To add another path do static plugin
    #static   => {
        #include_path =>
          #[ '/work/submission', Events->config->{root} ],
    #},

    'Plugin::Authentication'                    => {
        default => {
            credential => {
                class          => 'Password',
                password_type  => 'clear',
                password_field => 'reviewer_password',
            },
            store => {
                class                     => 'DBIx::Class',
                user_model                => 'EventsDB::Reviewer',
                role_relation             => 'roles',
                role_field                => 'role',
                use_userdata_from_session => '0'
            }
        }
    },
    'Controller::Login' => {
        login_form_args => {
            authenticate_username_field_name => 'reviewer_email',
            authenticate_password_field_name => 'reviewer_password',
        }
      },
   'Plugin::Session' => { 
       # Never expires while window is open and logged in
       expires => 10000000000, # Forever 
       # expires when close the browser
       cookie_expires => 0, 
   },

);

# Start the application
__PACKAGE__->setup();


=head1 NAME

Reviews - Catalyst based application

=head1 SYNOPSIS

    script/reviews_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Reviews::Controller::Root>, L<Catalyst>

=head1 AUTHOR

,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
