#!/usr/bin/perl

use strict;
use warnings;
use IPC::Open3;
use Symbol 'gensym';

# Read number of probes from command line argument
my $num_probes = shift @ARGV || 5;

# Read hostname:port pairs from standard input
my %hosts;
while (<STDIN>) {
    chomp;
    my ($hostname, $port) = split /:/;
    push @{$hosts{$hostname}}, $port;
}

# Resolve hostnames to IPs using dig command
my %resolved_hosts;
foreach my $hostname (keys %hosts) {
    my $cmd = "dig +short $hostname";
    my $output = `$cmd`;
    foreach my $line (split /\n/, $output) {
        push @{$resolved_hosts{$hostname}}, $line if $line =~ /^\d+\.\d+\.\d+\.\d+$/;
    }
}

# Run nping and calculate RTTs
my %rtt_results;
foreach my $hostname (keys %resolved_hosts) {
    foreach my $ip (@{$resolved_hosts{$hostname}}) {
        foreach my $port (@{$hosts{$hostname}}) {
            my $cmd = "nping --tcp -c $num_probes $ip -p $port";
            my $output = `$cmd`;
            foreach my $line (split /\n/, $output) {
                if ($line =~ /Avg rtt:\s+([\d.]+)ms/) {
                    push @{$rtt_results{$hostname}{$ip}}, $1;
                }
            }
        }
    }
}

# Calculate lowest average RTT for each hostname
my %best_ips;
foreach my $hostname (keys %rtt_results) {
    my $best_ip;
    my $lowest_rtt = 1e9;
    foreach my $ip (keys %{$rtt_results{$hostname}}) {
        foreach my $rtt (@{$rtt_results{$hostname}{$ip}}) {
            if ($rtt < $lowest_rtt) {
                $lowest_rtt = $rtt;
                $best_ip = $ip;
            }
        }
    }
    $best_ips{$hostname} = $best_ip;
}

# Hardcode the IPs with the lowest average RTT in /etc/hosts
open my $hosts_fh, '>>', '/etc/hosts' or die "Could not open /etc/hosts: $!";
foreach my $hostname (keys %best_ips) {
    print $hosts_fh "$best_ips{$hostname} $hostname\n";
}
close $hosts_fh;
