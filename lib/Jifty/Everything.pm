use warnings;
use strict;

package Jifty::Everything;

=head1 NAME

Jifty::Everything - Load all of the Jifty modules

=cut

# Could use Module::Pluggable, I guess.

use Jifty;
use Jifty::Config;
use Jifty::Handle;
use Jifty::ClassLoader;
use Jifty::Util;

use Jifty::Action;
use Jifty::Action::Record;
use Jifty::Action::Record::Create;
use Jifty::Action::Record::Update;

use Jifty::Collection;

use Jifty::Continuation;

use Jifty::Logger;
use Jifty::Handler;

use Jifty::MasonInterp;

use Jifty::Model::Schema;

use Jifty::Object;

use Jifty::Record;

use Jifty::Request;
use Jifty::Result;
use Jifty::Response;
use Jifty::CurrentUser;

# We can _not_ load Server.pm unless we're in a Server context because
# HTTP::Server::Simple::Mason bastardizes HTML::Mason::FakeApache::send_http_header
# with hook::lexwrap
#use Jifty::Server;

use Jifty::Test;

use Jifty::Web;
use Jifty::Web::PageRegion;
use Jifty::Web::Form;
use Jifty::Web::Form::Clickable;
use Jifty::Web::Form::Element;
use Jifty::Web::Form::Link;
use Jifty::Web::Form::Field;
use Jifty::Web::Menu;

use Module::Pluggable;
Module::Pluggable->import(search_path => ['Jifty::Web::Form::Field'], require => 1);
__PACKAGE__->plugins;

1;

