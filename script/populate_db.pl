#!/usr/bin/env perl

use strict;
use warnings;
use 5.10.0;
use Config::JFDI;
use FindBin;
use lib "$FindBin::Bin/../../Events/lib";
use Events::Schema;
use Sys::Hostname;
use Data::Dumper;
use utf8;
use String::Random;

# Getting the configuration file
sub config {

    my ($host) = Sys::Hostname::hostname() =~ m/^([^\.]+)/;
    my $path =  "$FindBin::Bin/../../Events/conf/events_" . $host . '.conf';
    die "Couldn't read your config file! Did you create a config file in $path ?" unless (-e $path);
    my $config = Config::JFDI->new(
        name => 'Events',
        path => $path,
    )->get;
    return $config;
}

sub schema {
    my $config = &config;
    my $schema = Events::Schema->connect(
        @{ $config->{'Model::EventsDB'}{connect_info} || [] } );
    return $schema;
}


print "Connecting into database...\n";
my $schema = &schema;


&add_reviewers;
&distribute_posters;
&add_admin;

sub add_reviewers {

    my $rs = $schema->resultset('Reviewer');

    my $total_rev = $rs->count;

    if ( $total_rev > 0){
    
        say  "Seems that you already have Reviewers in database!";
    }
    else {

        my %reviewer;
        open( my $in, '<', "$FindBin::Bin/../data/to_populate.txt" )
          or die "Couldn't open the file'";

        while ( my $row = <$in> ) {
            chomp $row;
            my ( $name, $email, $subtopics );
            ( $name, $email, $subtopics ) = ( $1, $2, $3 )
              if ( $row =~ /^(.*)\s*:\s*(\S+)\s+(\S+)/ );
            my @aux = split ",", $subtopics;
            if ( $reviewer{"$name|$email"} ) {
                push @{ $reviewer{"$name|$email"} }, @aux;
            }
            else {
                $reviewer{"$name|$email"} = \@aux;
            }
        }
        close($in);

        foreach my $k ( keys %reviewer ) {
            my $pass = String::Random->new();
            my ( $name, $email );
            ( $name, $email ) = ( $1, $2 ) if $k =~ /(.*)\|(.*)/;
            my $rs = $rs->create(
                {
                    reviewer_name     => $name,
                    reviewer_email    => $email,
                    reviewer_password => $pass->randpattern("CCcccc")
                }
            );

            foreach my $subtopic ( @{ $reviewer{$k} } ) {
                my $new_subtopic =
                  $schema->resultset('ReviewersHasEventSubtopic');
                $new_subtopic->create(
                    {
                        event_subtopic_id => $subtopic,
                        reviewer_id       => $rs->id,

                    }
                );
            }

        }
    }

}

sub distribute_posters {

    my %reviewer;
    my %test;
    my $rs_subtopic = $schema->resultset('EventSubtopic');
    while ( my $r_subtopic = $rs_subtopic->next ) {

        my $rs_reviewer = $schema->resultset('ReviewersHasEventSubtopic');
        $rs_reviewer = $rs_reviewer->search({event_subtopic_id =>
                $r_subtopic->id});
        my $total_rev = $rs_reviewer->count;

        my @revs = $rs_reviewer->all;

        # Posters
        my $rs_poster = $schema->resultset('EventPoster');
        $rs_poster =    $rs_poster->search( {event_subtopic_id =>
                $r_subtopic->id, event_poster_status => 1}, {} );

        if ($total_rev < 3 ){
            while ( my $poster = $rs_poster->next ) {
                foreach my $rv (@revs){
                    push @{$reviewer{$rv->id}},$poster->id;
                }
            }
        }
        else{
            my $last_pos=0;
            my $current_pos=0;
            while ( my $poster = $rs_poster->next ) {
                for ( my $i = 1 ; $i <= 3 ; $i++ ) {
                    $current_pos = $last_pos + $i;
                    #say $current_pos.'|'.$total_rev.' => '.$poster->id;
                    my $r = $revs[$current_pos - 1];
                    push
                    @{$reviewer{$r->id}},$poster->id;
                    push
                    @{$test{$r->event_subtopic->event_subtopic_name."-".$r->event_subtopic_id}{$r->reviewer->reviewer_name.'|'.$rs_poster->count.'|'.$total_rev}},$poster->id;
                    if ($current_pos ==  $total_rev ){
                        $last_pos = ( 0 - $i );
                    }
                }
                if ($current_pos <=  $#revs){
                    $last_pos = $current_pos;
                }

                else{
                    $last_pos = 0;
                }
            }
            
        }
    }

    print Dumper(%reviewer);
    my $rs_rev_poster = $schema->resultset('ReviewersHasEventPoster');

    my $total_rev_poster = $rs_rev_poster->count;

    if ( $total_rev_poster > 0){
        say "You already have reviewers and posters in database"
    }
    
    foreach my $k (sort {$a <=> $b} keys %reviewer){
        say  $k."\t". scalar @{$reviewer{$k}};
        unless ($total_rev_poster > 0){
            foreach my $poster_id ( @{ $reviewer{$k} } ) {
                my $new_row = $rs_rev_poster->create(
                    {
                        reviewer_id => $k,
                        event_poster_id => $poster_id,
                    }
                );
            }
        }
    }
   
}


sub add_admin {

        my @admins = (
            {
                name => 'Israel Tojal',
                email => 'itojal@gmail.com',
                password => 'q1w2e3',
            },
            {
                name => '',
                email => 'abhh.ti@gmail.com',
                password => 'q1w2e3',
            },

        );
        
        foreach my $r (@admins) {
            my $rs = $schema->resultset('Reviewer')->create(
                {
                    reviewer_name     => $r->{name},
                    reviewer_email    => $r->{email},
                    reviewer_password => $r->{password},
                }
            );

            # adding roles
            my $role = $schema->resultset('ReviewersHasRole')->create(
                {
                    reviewer_id     => $rs->id,
                    role_id    => 1,
                }

            );
        }


}
