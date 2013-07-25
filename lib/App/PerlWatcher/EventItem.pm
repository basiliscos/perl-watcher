package App::PerlWatcher::EventItem;
{
  $App::PerlWatcher::EventItem::VERSION = '0.11';
}

use 5.12.0;
use strict;
use warnings;

use Devel::Comments;

sub new {
    my ( $class, $content ) = @_;
    
    my $self = {
        _content   => $content, 
        _timestamp => time,
    };
    return bless $self, $class;
}

sub content {
    shift -> {_content};
}

sub timestamp {
    my ($self, $value) = @_;
    $self -> {_timestamp} = $value if defined($value);
    return $self -> {_timestamp};
}

1;
