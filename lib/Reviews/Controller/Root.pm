package Reviews::Controller::Root;
use Moose;
use namespace::autoclean;
use POSIX;

#BEGIN { extends 'Catalyst::Controller' }
# Activating CatalystX::SimpleLogin
BEGIN { extends 'Catalyst::Controller::ActionRole' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

Reviews::Controller::Root - Root Controller for Reviews

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path Does('NeedsLogin') :Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->check_user_roles(qw/Administrator/)){
        $c->res->redirect($c->uri_for('/admin'));
    }
    else{
        $c->res->redirect($c->uri_for('/review'));
    }
}


sub review :Path('review') Does('NeedsLogin') :Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->check_user_roles(qw/Administrator/)){
        $c->res->redirect($c->uri_for('/admin'));
    }

    # Add score to database
    my $score = $c->req->param('score');
    my $score_poster_id = $c->req->param('score_poster_id');

    if ($score && $score_poster_id){
        my $poster = $c->model('EventsDB::ReviewersHasEventPoster')->find({
                event_poster_id => $score_poster_id, reviewer_id => $c->user->id});
        $poster->score($score);
        $poster->status(1);
        $poster->update({score => $score, status => 1});
    }



    my %param = (
        id   => 'me.event_poster_id',
        topic       => 'event_poster.event_topic_id',
        subtopic       => 'event_poster.event_subtopic_id',
        title => 'event_poster_title',
        score => 'score',
    );

    my $page;
    $page = $c->req->param('page');
    $page = 1 unless $page;

    my $order;
    if ( $c->req->param('order')) {
        $order = [{-asc => "$param{$c->req->param('order')}"}];
    }
    else{
    
        $order = [{-asc => "me.event_poster_id"}];
    }
  
    my $rs = $c->model('EventsDB::ReviewersHasEventPoster')->search(
        {
            reviewer_id => $c->user->id
        },
        {
            # join => { event_poster => [ 'event_topic', 'event_subtopic' ] },
            prefetch => { event_poster => [qw/event_topic event_subtopic /]},
        }
    );

   

    my $split = 10;

    my $total_entries = $rs->count;
    
    my $total_pages = ceil($total_entries/$split);

    my $entry_start = (($page * $split) - ( $split - 1));

    my $entry_end = $entry_start + ($split - 1);

    # Not let end be higher than number of entries
    $entry_end = $total_entries if $entry_end > $total_entries;

    my @rows = $rs->search({},
        {
            order_by => $order,
           #page => $c->req->param('page'),
            page => $page,
            rows => $split,
        } 
    );

    my $not_reviewed = $rs->search({ status => 0 })->count;
    

    # Defining template
    $c->stash(
        total_pages   => $total_pages,
        current_page  => $page,
        total_entries => $total_entries,
        entry_start   => $entry_start,
        entry_end     => $entry_end,
        not_reviewed    => $not_reviewed,


        rows       => \@rows,
        template            => 'poster_list.tt2',

    );

}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}


# Administration Area
sub admin : Path('admin') Does('NeedsLogin') : Args(0) {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles(qw/Administrator/)){
        $c->res->redirect($c->uri_for('/review'));
    }


    my %param = (
        id       => 'event_poster.event_poster_id',
        topic    => 'event_poster.event_topic_id',
        subtopic => 'event_poster.event_subtopic_id',
        title    => 'event_poster_title',
        score    => 'score',
    );

    my $page;
    $page = $c->req->param('page');
    $page = 1 unless $page;

    my $order;
    if ( $c->req->param('order') ) {
        $order = [ { -asc => "$param{$c->req->param('order')}" } ];
    }
    else {

        $order = [ { -asc => "event_poster.event_poster_id" } ];
    }

    my $rs = $c->model('EventsDB::ReviewersHasEventPoster')->search(
        {
        },
        {
            '+select' => [{ ROUND => [{AVG => 'score'},2]}, {SUM => 'status'}, {COUNT =>
                    'reviewer_id'}],
            '+as' => ['avg', 'current_score_number','expected_score_number'],
            prefetch => { event_poster => [qw/event_topic event_subtopic /] },
            group_by => [qw/ me.event_poster_id /],
        }
    );

    my $split = 50;

    my $total_entries = $rs->count;

    my $total_pages = ceil( $total_entries / $split );

    my $entry_start = ( ( $page * $split ) - ( $split - 1 ) );

    my $entry_end = $entry_start + ( $split - 1 );

    # Not let end be higher than number of entries
    $entry_end = $total_entries if $entry_end > $total_entries;

    my @rows = $rs->search(
        {},
        {
            order_by => $order,

            #page => $c->req->param('page'),
            page => $page,
            rows => $split,
        }
    );

    my $not_reviewed = $rs->search( { status => 0 } )->count;

    # Defining template
    $c->stash(
        total_pages   => $total_pages,
        current_page  => $page,
        total_entries => $total_entries,
        entry_start   => $entry_start,
        entry_end     => $entry_end,
        not_reviewed  => $not_reviewed,

        rows     => \@rows,
        template => 'admin_list.tt2',
    );



}

sub more_info : Path('admin/moreinfo') Does('NeedsLogin'): Args(1) {
	my ( $self, $c, $id ) = @_;

    my $poster_id;
    if ($id ){

	    $poster_id = $id;
    }

    my $poster = $c->model('EventsDB::EventPoster')->find($poster_id);
   
    my $rs_reviewer = $c->model('EventsDB::ReviewersHasEventPoster')->search(
        {
           event_poster_id => $poster_id
        },
        {
            prefetch => 'reviewer',
        }
    );

    my @reviewers = $rs_reviewer->all; 

    # Defining template
    $c->stash(
        poster    => $poster,
        reviewers => \@reviewers,
        no_wrapper => 1,
        template  => 'more_info.tt2',
    );

}


# Render PDF URL
sub pdf_w_arg : Path('pdf') Does('NeedsLogin'): Args(1) {
	my ( $self, $c, $id ) = @_;

    my $poster_id;
    if ($id ){

	    $poster_id = $id;
    }
    
    my $rs = $c->model('EventsDB::EventPoster')->find($poster_id);
    
    my $event_edition = $rs->event_edition->event_edition;
    
        $self->pdf_render( $c, $poster_id );

}


sub pdf_render {
	my ( $self, $c, $poster_id ) = @_;

	$c->stash( 'no_wrapper' => 1 );
	$c->stash( 'template'   => 'pdf/pdf.tt2' );
    


    my $rs =  $c->model( 'EventsDB::EventPoster' )->find( $poster_id );
    
	$c->stash( finalized => $rs->event_poster_status  );
    
	$c->stash( abstract_title => $c->model( 'Poster' )->get_abstract_title( $poster_id ) );
    
    #For LaTeX body debug uncomment bellow
	$c->stash( abstract_body => $c->model( 'Poster' )->get_abstract_body( $poster_id ) );
	$c->stash( lang => $c->model( 'Poster' )->get_abstract_body_language( $poster_id ) );
    #my %hash = $c->model( 'Poster' )->get_authors_and_institutions( $poster_id );
    #$c->stash( authors => $hash{'authors'} );
    #$c->stash( institutions => $hash{'institutions'} );

	$c->response->content_type( 'application/pdf' );

    # Generate a random numeric filename
    #my $filename = int(rand(1000000));
    my $filename = $poster_id;

	$c->response->header( 'Content-Disposition', "attachment; filename=$filename.pdf" );


}


=head1 AUTHOR

,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
