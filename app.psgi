#!/usr/bin/env perl
# -*- coding: utf-8 mode: perl -*-

use strict;
use warnings;
use Plack::App::File;
use Plack::Builder;
use HTTP::Date;
use IO::Socket::INET;
use IO::Select;
use Socket 'inet_ntoa';
use JSON::XS;
use Data::Dumper;

my $upserver = '202.232.117.40:11300';
use constant {
    TIMEOUT  => 1,
    INTERVAL => 30,
    JSONFILE => 'stats.json',
};

my $xs = JSON::XS->new;

builder {
    mount '/' => Plack::App::File->new(file => 'index.html');
    mount '/favicon.ico' => Plack::App::File->new(file => 'favicon.ico');
    mount '/common.css' => Plack::App::File->new(file => 'common.css');
    mount '/view.css' => Plack::App::File->new(file => 'view.css');
    mount '/jquery-1.10.2.min.js' => Plack::App::File->new(file => 'jquery-1.10.2.min.js');
    mount '/wTimer.js' => Plack::App::File->new(file => 'wTimer.js');
    mount '/onload.js' => Plack::App::File->new(file => 'onload.js');
    mount '/google.js' => Plack::App::File->new(file => 'google.js');

    mount '/stats' => sub {
	my $env = shift;
	my $now = time;
	my $lastmod = (stat(JSONFILE))[9];

	if ($lastmod && $now - $lastmod < INTERVAL) {
	    cache($lastmod);
	} else {
	    main();
	}
    };
};

sub readJSON {
    open(my $fd, JSONFILE);
    local $/;
    <$fd>;
}

sub cache {
    my $lastmod = shift;
    my $json = readJSON();

    return [
	200,
	[
	    "X-MoEstats" => "cache",
	    "Last-Modified" => time2str($lastmod),
	    "Content-Type" => "application/json",
	    ],
	[ $json ],
	];
}

sub nodata {
    my $status = shift;

    my $json = readJSON();

    my $data = $xs->decode($json);

    unless (@$data) {
	$data = [
	    {name => 'DIAMOND'},
	    {name => 'PEARL'},
	    {name => 'EMERALD'}
	    ];
    }
    foreach my $server (@$data) {
	$server->{status} = '-';
	$server->{login} = '-';
	$server->{login_max} = '-';
    }

    return [
	304,
	[
	    "X-MoEstats" => $status,
	    "Content-Type" => "application/json",
	    ],
	[ $xs->encode($data) ],
	];
}

sub main {
    my $now = time;

    my $socket = IO::Socket::INET->new(PeerAddr => $upserver,
				       Proto    => 'udp',
				       Timeout  => TIMEOUT,
	) or return nodata('connect');
    my $in = IO::Select->new;
    $in->add($socket);

    my @servers;
    my $num = queryServerNum($in, $socket);
    return nodata('no server') unless $num;

    queryServerUp($socket);
    for (1 .. $num) {
	my $status = recvServerStatus($in, $socket);
	push @servers, $status;
    }
    return nodata('no data') unless @servers;

    my $json = $xs->encode(\@servers);

    open(my $fd, '>', JSONFILE);
    print $fd $json;
    close($fd);

    return [
	200,
	[
	    "X-MoEstats" => "update",
	    "Last-Modified" => time2str($now),
	    "Content-Type" => "application/json",
	    ],
	[ $json ],
	];
}

############################################################
sub queryServerNum {
    my ($select, $socket) = @_;

    my $data = "\x00\x00\x00\x03\x02";

    $socket->send($data) or return 0;
    if ($select->can_read(TIMEOUT)) {
        $socket->recv($data, 8);

        my ($num, $dummy1) = unpack('N1N1', $data);

        unless ($num) {
            return 0;
        }
	return $num;
    }
    0;
}

sub queryServerUp {
    my $socket = shift;

    my $data = "\x00\x00\x00\x05\x02";
    $socket->send($data);
}

sub getStatus {
    my $data = shift;

    my %status = (
        0x02 => 'up',
        0x12 => 'lock',
        0x32 => 'busy',
        0x3a => 'down?',
        );
    my (undef, $ipaddr, $order, $name) = unpack('NLNZ*', $data);
    my ($status, $login_now, $login_max, $reboot) = unpack('nNNN', substr($data, 22));

    return {
	name => $name,
	server => inet_ntoa(pack('N', $ipaddr)),
	reboot => $reboot,
	status => $status{$status & 0xFF} // $status,
	login => $login_now,
	login_max => $login_max,
    };
}

sub recvServerStatus {
    my ($select, $socket) = @_;

    if ($select->can_read(TIMEOUT)) {
        $socket->recv(my $data, 42);
        return getStatus($data);
    }
}
