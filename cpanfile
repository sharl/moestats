requires 'Plack';
requires 'Starman';
requires 'common::sense';

on test => sub {
    requires 'Test::Harness';
    requires 'Test::Simple';
    requires 'Test::Pretty';
};
