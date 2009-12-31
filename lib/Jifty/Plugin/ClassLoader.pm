use warnings;
use strict;

package Jifty::Plugin::ClassLoader;

=head1 NAME

Jifty::Plugin::ClassLoader - Autogenerates application classes

=head1 DESCRIPTION

C<Jifty::Plugin::ClassLoader> loads additional model and action classes on
behalf of the application out of the configured plugin classes.  Unlike, 
C<Jifty::ClassLoader>, this class will only autogenerate classes if the
plugin provides them.  The plugin classes are checked before the base Jifty
classes, so that a plugin can override the Jifty class, just as any
existing application classes will be loaded first.

=head2 new

Returns a new ClassLoader object.  Doing this installs a hook into
C<@INC> that allows L<Jifty::Plugin::ClassLoader> to dynamically create
needed classes if they do not exist already.  This works because if
use/require encounters a blessed reference in C<@INC>, it will
invoke the INC method with the name of the module it is searching
for on the reference.

Takes two mandatory arguments, C<base>, which should be the 
application's base path; and C<plugin> which is the plugin classname.

=cut

sub new {
    my $class = shift;
    my %args = (@_);
    my @exist = grep {ref $_ eq $class and $_->{base} eq $args{base}} @INC;
     return $exist[0] if @exist;


    my $self = bless {%args}, $class;

    push @INC, $self;
    return $self;
}

=head2 INC

The hook that is called when a module has been C<require>'d that
cannot be found on disk.  The following stub classes are
auto-generated:

=over

=item I<Application>

An empty application base class is created that doen't provide any
methods or inherit from anything.

=item I<Application>::Record

An empty class that descends from L<Jifty::Record> is created.

=item I<Application>::Collection

An empty class that descends from L<Jifty::Collection> is created.

=item I<Application>::Notification

An empty class that descends from L<Jifty::Notification>.

=item I<Application>::Dispatcher

An empty class that descends from L<Jifty::Dispatcher>.

=item I<Application>::Bootstrap

An empty class that descends from L<Jifty::Bootstrap>.

=item I<Application>::Upgrade

An empty class that descends from L<Jifty::Upgrade>.

=item I<Application>::CurrentUser

An empty class that descends from L<Jifty::CurrentUser>.

=item I<Application>::Model::I<Anything>Collection

If C<I<Application>::Model::I<Something>> is a valid model class, then
it creates a subclass of L<Jifty::Collection> whose C<record_class> is
C<I<Application>::Model::I<Something>>.

=item I<Application>::Action::(Create or Update or Delete)I<Anything>

If C<I<Application>::Model::I<Something>> is a valid model class, then
it creates a subclass of L<Jifty::Action::Record::Create>,
L<Jifty::Action::Record::Update>, or L<Jifty::Action::Record::Delete>
whose I<record_class> is C<I<Application>::Model::I<Something>>.

=back

=cut

# This subroutine's name is fully qualified, as perl will ignore a 'sub INC'
sub Jifty::Plugin::ClassLoader::INC {
    my ( $self, $module ) = @_;

    my $base = $self->{base};
    my $plugin = $self->{plugin};
    return undef unless ( $module and $base and $plugin);



    # Canonicalize $module to :: style rather than / and .pm style;
    $module =~ s/.pm$//;
    $module =~ s{/}{::}g;

    # The quick check
    return undef unless $module =~ m!^$base!;

    # Note that at this point, all of the plugins classes will already be
    # loaded, so we can just check their presence when deciding whether
    # this is a class the plugin intends to autocreate
    if ( $module =~ m{^(?:$base)::CurrentUser$} ) {
        my $method = "${plugin}::CurrentUser";
        if ( Jifty::Util->already_required($method) ) {
            Jifty->log->debug("Implementing $module using $method");
            $Jifty::ClassLoader::AUTOGENERATED{$module} = 1;
            return Jifty::ClassLoader->return_class(
                  "use warnings; use strict; package $module;\n"
                . "use base qw/$method/;\n"
                . "1;" ) 
        }
        else {
            Jifty->log->debug("Couldn't implement $module using $method");
        }
    } elsif ( $module =~ m!^(?:$base)::Action::(Create|Update|Delete|Search)([^\.]+)$! ) {
        my $model = "::Model::" . $2;
        my $method = $plugin . "::Action::" . $1 . $2;

        # Check to see if this is an action for a model that this plugin 
        # doesn't provide
        return undef unless Jifty::Util->already_required("$plugin$model");

        if ( Jifty::Util->already_required($method) ) {
            Jifty->log->debug("Implementing $module using $method");
            $Jifty::ClassLoader::AUTOGENERATED{$module} = 1;
            return Jifty::ClassLoader->return_class(
                  "use warnings; use strict; package $module;\n"
                . "use base qw/$method/;\n"
                . "sub record_class { '$base$model' };\n"
                . "1;" )
        }
        else {
            Jifty->log->debug("Couldn't implement $module using $method");
        }
    } elsif ( $module =~ m{^(?:$base)::(Action|Notification)([^\.]+)$} ) {
        my $method = $plugin . "::" . $1 . $2;
        if ( Jifty::Util->already_required($method) ) {
            Jifty->log->debug("Implementing $module using $method");
            $Jifty::ClassLoader::AUTOGENERATED{$module} = 1;
            return Jifty::ClassLoader->return_class(
                  "use warnings; use strict; package $module;\n"
                . "use base qw/$method/;\n"
                . "1;" )
        }
        else {
            Jifty->log->debug("Couldn't implement $module using $method");
        }

    } 

    return undef;
}

=head2 require

Loads all of the application's Actions and Models.  It additionally
C<require>'s all Collections and Create/Update actions for each Model
base class -- which will auto-create them using the above code if they
do not exist on disk.

=cut

sub require {
    my $self = shift;
    
    my $base = $self->{plugin};


    # if we don't even have an application class, this trick will not work
    return unless ($base); 
    Jifty::Util->require($base);
    Jifty::Util->require($base."::CurrentUser");

    Jifty::Module::Pluggable->import(
        search_path =>
          [ map { $base . "::" . $_ } 'Model', 'Action', 'Notification' ],
        require => 1,
        except  => qr/\.#/,
        inner   => 0
    );
    $self->{models}{$_} = 1 for grep {/^($base)::Model::(.*)$/ and not /Collection$/} $self->plugins;
    for my $full (keys %{$self->{models}}) {
        my($short) = $full =~ /::Model::(.*)/;
        Jifty::Util->require($full . "Collection");
        Jifty::Util->require($base . "::Action::" . $_ . $short)
            for qw/Create Update Delete/;
    }
}

=head2 DESTROY

When the ClassLoader gets garbage-collected, its entry in @INC needs
to be removed.

=cut

# The entries in @INC end up having SvTYPE == SVt_RV, but SvRV(sv) ==
# 0x0 and !SvROK(sv) (!?)  This may be something that perl should cope
# with more cleanly.
#
# We call this explictly in an END block in Jifty.pm, because
# otherwise the DESTROY block gets called *after* there's already a
# bogus entry in @INC

# This bug manifests itself as warnings that look like this:

# Use of uninitialized value in require at /tmp/7730 line 9 during global destruction.


sub DESTROY {
    my $self = shift;
    @INC = grep {!$self} @INC;
}

1;
