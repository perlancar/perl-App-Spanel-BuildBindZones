package App::Spanel::BuildBindZones;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;

our %SPEC;

$SPEC{build_bind_zones} = {
    v => 1.1,
    summary => 'Build BIND zones from YAML zones',
    description => <<'_',

This script will collect all YAML zones from user accounts (/u/*/sysetc/zone=*)
and build BIND zones then write them to the current directory with names db.*
(so /u/foo/sysetc/zone=example.com will become ./db.example.com).

Will not override existing files unless `--overwrite` (`-O`) is specified.

Will skip YAML zones that contain invalid data, e.g. name in record that
contains underscore (`_`), unknown record type, etc.

_
    args => {
        overwrite => {
            summary => 'Whether to overwrite existing output files',
            schema => 'bool*',
            cmdline_aliases => {O=>{}},
        },
    },
};
sub build_bind_zones {
    require Data::Sah;

    my %args = @_;

    my $code_validate_domain = Data::Sah::gen_validator(
        "net::hostname*",
        {return_type=>"str"},
    );
    local $CWD = "/u";
    for my $user (glob "*") {
        next unless -d $user;
        log_info "Processing user $user ...";
        if (-f "$user/sysetc/migrated") {
            log_info "User $user is migrated, skipping";
            next;
        }
        local $CWD = "$user/sysetc";
        for my $yaml_file (glob "zone=*") {
            next if $yaml_file =~ /~$/;
            log_info "Processing file $yaml_file ...";
            my ($domain) = $yaml_file =~ /^zone=(.+)/;
            if (my $err = $code_validate_domain->($domain)) {
                log_warn "$domain is not a valid hostname, skipping file $yaml_file";
                next;
            }
            print "";
        }
    }
}


1;
# ABSTRACT:

=head1 SYNOPSIS

See the included L<spanel-build-bind-zones> script.

=cut
