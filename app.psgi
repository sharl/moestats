#!/usr/bin/env perl
# -*- coding: utf-8 mode: perl -*-

my $app = sub {
    my $env = shift;
   return [
       200,
       ['Content-Type' => 'text/plain'],
       ['Hello moestats'],
   ];
};
$app;
