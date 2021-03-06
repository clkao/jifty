package TestApp::Plugin::REST::Action::DoSomething;

use Jifty::Param::Schema;
use base qw/TestApp::Plugin::REST::Action/;
use Jifty::Action schema {

param email =>
    label is 'Email',
    default is 'example@email.com',
    ajax canonicalizes,
    ajax validates;

};

sub canonicalize_email {
    my $self = shift;
    my $address = shift;
    
    return lc($address);
}

sub validate_email {
    my $self = shift;
    my $address = shift;

    if($address =~ /bad\@email\.com/) {
        return $self->validation_error('email', "Bad looking email");
    } elsif ($address =~ /warn\@email\.com/) {
        return $self->validation_warning('email', "Warning for email");
    }
    return $self->validation_ok('email');
}

sub take_action {
    my $self = shift;

    $self->result->message("Something happened!");
}

1;
