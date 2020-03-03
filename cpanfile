requires 'Plack';
requires 'Starman';
requires 'common::sense';
requires 'Plack::App::File';
requires 'Plack::Builder';
requires 'HTTP::Date';
requires 'IO::Socket::INET';
requires 'IO::Select';
requires 'Socket';
requires 'JSON::MaybeXS';

on test => sub {
    requires 'Test::Harness';
    requires 'Test::Simple';
    requires 'Test::Pretty';
};
