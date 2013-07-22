# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 21; # last test to print

my $module;

BEGIN {
   $module = 'Net::Amazon::S3::Policy';
   use_ok($module);
}

{
   my $expiration = '1220292602';
   my $policy = $module->new({expiration => $expiration});

   ok($policy, 'new with expiration time');
   isa_ok($policy, $module);
   is($policy->expiration(), '2008-09-01T18:10:02.000Z',
      'expiration time');

   $policy->add($_)
     for (
      q( prova eq ciao ),
      q( provaxxx starts-with ciao ),
      q( 0 <= something <= 123312391 ),
      q( anything * ),
      q( anything2 starts_with ),
      q( anything2 starts_with blah ),
     );

   my $conditions = $policy->conditions();
   ok($conditions, 'conditions exists');
   is(scalar(@$conditions), 6, 'all conditions added');
   is_deeply(
      $conditions,
      [
         [qw( eq $prova ciao )],
         [qw( starts-with $provaxxx ciao )],
         [qw( something 0 123312391 )],
         [qw( starts-with $anything ),  ''],
         [qw( starts-with $anything2 ), ''],
         [qw( starts-with $anything2 blah )],
      ],
      'conditions match'
   );

   my $expected_json =
'{"conditions":[["eq","$prova","ciao"],["starts-with","$provaxxx","ciao"],["something","0","123312391"],["starts-with","$anything",""],["starts-with","$anything2",""],["starts-with","$anything2","blah"]],"expiration":"2008-09-01T18:10:02.000Z"}';
   is($policy->stringify({canonical => 1}), $expected_json, 'JSON generation');
}

{
   my $json =
'{"conditions":[["eq","$prova","ciao"],["starts-with","$provaxxx","ciao"],["something","0","123312391"],["starts-with","$anything",""],["starts-with","$anything2",""],["starts-with","$anything2","blah"],{"what":"this"}],"expiration":"2008-09-01T18:10:02.000Z"}';

   my $policy = Net::Amazon::S3::Policy->new(json => $json);
   ok($policy, 'new with expiration time');
   isa_ok($policy, $module);
   is($policy->expiration(), '2008-09-01T18:10:02.000Z',
      'expiration time');

   my $conditions = $policy->conditions();
   ok($conditions, 'conditions exists');
   is(scalar(@$conditions), 7, 'all conditions present');
   is_deeply(
      $conditions,
      [
         [qw( eq $prova ciao )],
         [qw( starts-with $provaxxx ciao )],
         [qw( something 0 123312391 )],
         [qw( starts-with $anything ),  ''],
         [qw( starts-with $anything2 ), ''],
         [qw( starts-with $anything2 blah )],
         [qw( eq $what this )],
      ],
      'conditions match',
   );
}

{
   my $json =
'{"conditions":[["eq","$prova","ciao"],["starts-with","$provaxxx","ciaoBLACKHEART"],["something","0","123312391"],["starts-with","$anything",""],["starts-with","$anything2",""],["starts-with","$anything2","blah"],{"what":"this"}],"expiration":"2008-09-01T18:10:02.000Z"}';
   $json =~ s/BLACKHEART/\x{2665}/mxs;

   my $policy = Net::Amazon::S3::Policy->new(json => $json);
   ok($policy, 'new with expiration time');
   isa_ok($policy, $module);
   is($policy->expiration(), '2008-09-01T18:10:02.000Z',
      'expiration time');

   my $conditions = $policy->conditions();
   ok($conditions, 'conditions exists');
   is(scalar(@$conditions), 7, 'all conditions present');
   is_deeply(
      $conditions,
      [
         [qw( eq $prova ciao )],
         [qw( starts-with $provaxxx ), "ciao\x{2665}"],
         [qw( something 0 123312391 )],
         [qw( starts-with $anything ),  ''],
         [qw( starts-with $anything2 ), ''],
         [qw( starts-with $anything2 blah )],
         [qw( eq $what this )],
      ],
      'conditions match',
   );

   my $base64 = 'undefined';
   eval { $base64 = $policy->base64(); };
   my $expected_base64 = 'eyJleHBpcmF0aW9uIjoiMjAwOC0wOS0wMVQxODoxMDowMi4wMDBaIiwiY29uZGl0aW9ucyI6W1siZXEiLCIkcHJvdmEiLCJjaWFvIl0sWyJzdGFydHMtd2l0aCIsIiRwcm92YXh4eCIsImNpYW/imaUiXSxbInNvbWV0aGluZyIsIjAiLCIxMjMzMTIzOTEiXSxbInN0YXJ0cy13aXRoIiwiJGFueXRoaW5nIiwiIl0sWyJzdGFydHMtd2l0aCIsIiRhbnl0aGluZzIiLCIiXSxbInN0YXJ0cy13aXRoIiwiJGFueXRoaW5nMiIsImJsYWgiXSxbImVxIiwiJHdoYXQiLCJ0aGlzIl1dfQ==';
   is($base64, $expected_base64, 'base64 encoding');
}
