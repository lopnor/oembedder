use inc::Module::Install;
name 'OEmbedder';
all_from 'lib/OEmbedder.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
