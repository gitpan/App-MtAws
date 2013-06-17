#!/usr/bin/perl

# mt-aws-glacier - Amazon Glacier sync client
# Copyright (C) 2012-2013  Victor Efimov
# http://mt-aws.com (also http://vs-dev.com) vs@vs-dev.com
# License: GPLv3
#
# This file is part of "mt-aws-glacier"
#
#    mt-aws-glacier is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    mt-aws-glacier is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use utf8;
use Test::More tests => 7;
use FindBin;
use lib "$FindBin::RealBin/../", "$FindBin::RealBin/../../lib";
use File::Path;
use TestUtils;
use File::Temp ();


warning_fatal();

my $TEMP = File::Temp->newdir();
my $mtroot = $TEMP->dirname();
my $file = "$mtroot/config_engine_v08_test.txt";

rmtree($file);


my $line = "purge-vault --key=k --secret=s --region=myregion --config=$file --to-vault=myvault --journal x";
{
	unlink $file;
	disable_validations sub {
		my ($errors, $warnings, $command, $result) = config_create_and_parse(split(' ', $line));
		ok( $errors && !$result, "should catch missed config file");
		ok( $errors->[0] =~ "Cannot read config file \"$file\"", "should catch missed config file error message");
	};
}

{
	mkpath($file);
	disable_validations sub {
 		my ($errors, $warnings, $command, $result) = config_create_and_parse(split(' ', $line));
		ok( $errors && !$result, "should catch missed config file");
		ok( $errors->[0] =~ "Cannot read config file \"$file\"", "should catch when config file is a directory");
	}
}

{
	rmtree($file);
	open F, ">", $file;
	close F;
	disable_validations sub {
		my ($errors, $warnings, $command, $result) = config_create_and_parse(split(' ', $line));
		ok( !$errors && $result, "should work with empty config file");
	}
}

SKIP: {
	skip "Cannot run under root", 2 unless $>;
	rmtree($file);
	open F, ">", $file;
	print F " ";
	close F;
	chmod 0000, $file;
	disable_validations sub {
		my ($errors, $warnings, $command, $result) = config_create_and_parse(split(' ', $line));
		ok( $errors && !$result, "should catch permission problems with config file");
		ok( $errors->[0] =~ "Cannot read config file \"$file\"", "should catch when config file is a directory");
	}
}
1;