use warnings;
use strict;

package Jifty::Plugin::SiteNews::View::News;
use Jifty::View::Declare -base;
use Jifty::View::Declare::CRUD;

import_templates Jifty::View::Declare::CRUD under '/';

sub object_type { 'News' }

sub fragment_base_path {'/news'}


template search_region => sub {''};

template 'index.html' => page {
    title is  'Site news' ;
    form {
            render_region(
                name     => 'newslist',
                path     => '/news/list');
    }

};


template 'view' => sub {
    my $self = shift;
    my ( $object_type, $id ) = ( $self->object_type, get('id') );
    my $update = new_action(
        class => 'Update' . $object_type,
        moniker => "update-" . Jifty->web->serial,
        record  => $self->get_record( $id )
    );

    my $record = $self->get_record($id);

    h1 { $record->title };
    blockquote {$record->content};
        hyperlink(
                label   => "Edit",
                class   => "editlink",
                onclick => {
                    replace_with => $self->fragment_for('update'),
                    args         => { object_type => $object_type, id => $id }
                },
        );


};

1;