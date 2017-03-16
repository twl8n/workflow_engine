#!/usr/bin/perl


# Run the v3 state table. This has 4 columns, test are functions, empty test
# defaults to true, empty function defaults to no-op (aka null),

use strict;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use session_lib qw(:all);
require 'wf_lib.pm';

# Usage: ./index.pl A state file 'state.dat' is expected in he current directory. The state file is
# expected to be in Emacs org-table format.

# sub read_state_data() is hard coded for our needs, but Perl's Text::Table might handle it, and more
# flexibly.

# http://search.cpan.org/~shlomif/Text-Table-1.130/lib/Text/Table.pm

# Also: http://search.cpan.org/~perlancar/Org-Parser-0.44/

our @table; # state table, our to share with wf_lib.pm
our %ch; # CGI hash, our to share with wf_lib.pm
our %known_states;
our $default_state = 'login'; 
our $msg = '';

main();

sub main
{
    $| = 1; # unbuffer stdout

    # The column args determine the name of the hash keys for the state table. That needs to be fixed, if for
    # no other reason it is very obscure.
    read_state_data("states.dat", 'edge', 'test', 'func', 'next');

    sanity_check_states();

    my $qq = new CGI;
    %ch = $qq->Vars();
    
    my $temp;

    # Works
    # foreach my $var ($qq->param('options'))
    # {
    #     $temp .= "$var<br>\n";
    # }

    # also works
    # foreach my $var (split("\0", $ch{options}))
    # {
    #     $temp .= "$var<br>\n";
    # }
    
    # my $curr_state = $default_state;
    # if ($ch{curr_state})
    # {
    #     $curr_state = $ch{curr_state};
    # }
    # my $wait_next = '';
    
    # Get input. If none, do the default state until wait.
    
    # If we have input, then auto next until wait, print results, print next choices, print current state.
    my %trav = traverse($default_state);
    
    my $curr_state = $trav{wait_next};
        
    msg(sprintf("Upcoming choices will be: (for: $curr_state)"));
    my $options_list_str = '';
    my $checked = '';
    foreach my $hr (@table)
    {
        if (! $checked)
        {
            $checked = "checked";
        }
        if (($hr->{edge} eq $curr_state) && $hr->{test})
        {
            $options_list_str .= sprintf("$hr->{test}<br>\n");
        }
        $checked = ' '; # ugly way of setting checked to a non-value.
    }
    
    render({options => options_checkboxes($curr_state),
            options_list_str => $options_list_str,
            curr_state => $trav{wait_next},
            msg => "$msg$trav{msg}"});
    
}

