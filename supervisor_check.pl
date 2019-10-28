#!/usr/bin/perl

use strict;
use Switch;

# --------- base config -------------
my $ZabbixServer = "1.2.3.4";
my $HostName = "HostName";
# ----------------------------------

sub escapeZabbixItemKey
{
    my $itemKey = $_[0];
    $itemKey =~ s/:/_/g;
    return $itemKey;
}

switch ($ARGV[0])
{
    case "discovery" {
        my $first = 1;

        print "{\n";
        print "\t\"data\":[\n\n";

        my $result = `/usr/bin/supervisorctl status`;

        my @lines = split /\n/, $result;
        foreach my $l (@lines) {
            my @stat = split / +/, $l;
            print ",\n" if not $first;
            $first = 0;
            my $name = escapeZabbixItemKey($stat[0]);

            print "\t{\n";
            print "\t\t\"{#NAME}\":\"$name\",\n";
            print "\t\t\"{#STATUS}\":\"$stat[1]\"\n";
            print "\t}";
        }

        print "\n\t]\n";
        print "}\n";
    }

    case "status" {
        my $result = `/usr/bin/supervisorctl pid`;

        if ( $result =~ m/^\d+$/ ) {
            $result = `/usr/bin/zabbix_sender -z $ZabbixServer -s $HostName -k "supervisor.status" -o "OK"`;
            print $result;

            $result = `/usr/bin/supervisorctl status`;

            my @lines = split /\n/, $result;
            foreach my $l (@lines) {
                my @stat = split / +/, $l;
                my $name = escapeZabbixItemKey($stat[0]);

                $result = `/usr/bin/zabbix_sender -z $ZabbixServer -s $HostName -k "supervisor.check[$name,Status]" -o $stat[1]`;
                print $result;
            }
        } else {
            # error supervisor not runing
            $result = `/usr/bin/zabbix_sender -z $ZabbixServer -s $HostName -k "supervisor.status" -o "FAIL"`;
            print $result;
        }
    }
}
