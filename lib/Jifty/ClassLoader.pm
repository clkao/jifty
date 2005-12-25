use warnings;
use strict;

package Jifty::ClassLoader;

=head1 NAME

Jifty::ClassLoader - Loads the application classes

=head1 DESCRIPTION

C<Jifty::ClassLoader> loads all of the application's model and action
classes, generating classes on the fly for Collections of pre-existing
models.

=head2 new

Returns a new ClassLoader object.  Doing this installs a hook into
C<@INC> that allows L<Jifty::ClassLoader> to dynamically create needed
classes if they do not exist already.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    push @INC, $self;
    return $self;
}

=head2 INC

The hook that is called when a module has been C<require>'d that
cannot be found on disk.  If the module is a Collection, it attempts
to generate a simple class which descends from L<Jifty::Collection>.
If it is a C<::Action::CreateFoo> or a C<::Action::UpdateFoo>, it
creates the appropriate L<Jifty::Action::Record> subclass.

Also autogenerates stub classes for C<ApplicationClass>,
C<ApplicationClass::Collection> and C<ApplicationClass::Record>.

=cut

# This subroutine's name is fully qualified, as perl will ignore a 'sub INC'
sub Jifty::ClassLoader::INC {
    my ( $self, $module ) = @_;
    my $ApplicationClass = Jifty->config->framework('ApplicationClass');
    my $ActionBasePath   = Jifty->config->framework('ActionBasePath');
    return undef unless ( $module and $ApplicationClass );

    if ( $module =~ m!^($ApplicationClass)(\.pm)?$! ) {
        return $self->return_class( "use warnings; use strict; package " . $ApplicationClass . ";\n"." 1;" );
    } 
    elsif ( $module =~ m!^(?:$ApplicationClass)(?:/|::)(Record|Collection)(\.pm)?$! ) {
        return $self->return_class( "use warnings; use strict; package " . $ApplicationClass . "::". $1.";\n".
            "use base qw/Jifty::$1/; our \$VERSION ='0.01';\n"."1;" );
    } 
    
    
    
    elsif ( $module
        =~ m!^($ApplicationClass)(?:/|::)Model(?:/|::)([^:]+)Collection(\.pm)?$!
        )
    {

        # Auto-create Collection classes
        return undef
            unless $self->{models}{ $ApplicationClass . "::Model::" . $2 };

        return $self->return_class( "package " . $ApplicationClass . "::Model::" . $2 . "Collection;\n"."use base qw/@{[$ApplicationClass]}::Collection/;\n"." 1;"
        );

    } elsif ( $module
        =~ m!^($ApplicationClass)(?:/|::)Action(?:/|::)(Create|Update|Delete)([^\.:]+)(\.pm)?$!
        )
    {

        # Auto-create CRUD classes
        my $modelclass = $ApplicationClass . "::Model::" . $3;
        return undef unless $self->{models}{$modelclass};

        # warn "Auto-creating '$2' action for $modelclass ($module)";
        return $self->return_class( "package " . $ActionBasePath . "::$2$3;\n"
                . "use base qw/Jifty::Action::Record::$2/;\n"
                . "sub record_class {'$modelclass'};\n"
                . "1;" );

    }
    return undef;
}

=head2 return_class CODE

Takes CODE as a string and returns an open filehandle containing that CODE.


=cut


sub return_class {
    my $self = shift;
        my $content = shift;
        open my $fh, '<', \$content;
        return $fh;

}


=head2 require

Loads all of the application's Actions and Models.  It additionally
C<require>'s all Collections and Update/Delete actions for each Model
base class.

=cut

sub require {
    my $self = shift;
    
    my $ApplicationClass = Jifty->config->framework('ApplicationClass');
    # if we don't even have an application class, this trick will not work
    return unless  ($ApplicationClass); 
    $ApplicationClass->require;
    my $ActionBasePath = Jifty->config->framework('ActionBasePath');

    Module::Pluggable->import(
        search_path =>
          [ $ActionBasePath, map { $ApplicationClass . "::" . $_ } 'Model', 'Action', 'Notification' ],
        require => 1,
        inner => 0
    );
    $self->{models} = {map {($_ => 1)} grep {/^($ApplicationClass)::Model::([^:]+)$/ and not /Collection$/} $self->plugins};
    for my $full (keys %{$self->{models}}) {
        my($short) = $full =~ /::Model::(.*)/;
        require ($full . "Collection");
        require ($ActionBasePath . "::" . $_ . $short) for qw/Create Update/;
    }

}

1;
