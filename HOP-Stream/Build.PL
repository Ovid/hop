use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'HOP::Stream',
    dist_author        => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from  => 'lib/HOP/Stream.pm',
    requires           => { 'Test::More' => 0, },
    add_to_cleanup     => ['HOP-Stream-*'],
    create_makefile_pl => 'traditional',
    meta_merge         => {
        license     => 'http://hop.perl.plover.com/Examples/LICENSE.txt',
        MailingList => 'http://hop.perl.plover.com/~alias/list.cgi/2/',
    },
);

$builder->create_build_script();
