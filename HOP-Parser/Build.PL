use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'HOP::Parser',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/HOP/Parser.pm',
    requires          => {
        'Sub::Uplevel'    => 0,      # get around CPANPLUS bug
        'Test::Exception' => 0,
        'Test::More'      => 0,
        'HOP::Stream'     => 0.03,
    },
    add_to_cleanup     => ['HOP-Parser-*'],
    create_makefile_pl => 'traditional',
    license            => 'open_source',
    meta_merge         => {
        license     => 'http://hop.perl.plover.com/Examples/LICENSE.txt',
        MailingList => 'http://hop.perl.plover.com/~alias/list.cgi/2/',
    },
);

$builder->create_build_script();
