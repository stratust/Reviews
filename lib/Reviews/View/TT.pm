package Reviews::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
	# Setting my encoding
    ENCODING     => 'utf-8',

    # Change default TT extension
    TEMPLATE_EXTENSION => '.tt2',

    # Set the location for TT files
    INCLUDE_PATH => [ Reviews->path_to( 'root', 'src' ), ],
    # Set to 1 for detailed timer stats in your HTML as comments
    TIMER              => 0,
    # This is your wrapper template located in the 'root/src'
    WRAPPER => 'wrapper.tt2',
    render_die => 1,
);

=head1 NAME

Reviews::View::TT - TT View for Reviews

=head1 DESCRIPTION

TT View for Reviews.

=head1 SEE ALSO

L<Reviews>

=head1 AUTHOR

,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
