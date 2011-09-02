#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'Reviews';
all_from 'lib/Reviews.pm';

requires 'Catalyst::Runtime' => '5.80032';
requires 'Catalyst::Plugin::ConfigLoader';

requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
# More than default
requires 'Catalyst::Plugin::ConfigLoader::Multi';
requires 'Sys::Hostname';
requires '';
requires '';
requires '';
requires '';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::Plugin::Compress';
requires 'DBIx::Class::DateTime::Epoch';
requires 'Config::JFDI';
requires 'HTML::FormHandler';
requires 'HTML::FormHandler::Model::DBIC';
requires 'parent';

test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
riteAll;
