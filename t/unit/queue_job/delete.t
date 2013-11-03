#!/usr/bin/env perl

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
use Test::More tests => 14;
use Test::Deep;
use FindBin;
use lib map { "$FindBin::RealBin/../$_" } qw{../lib ../../lib};
use App::MtAws::QueueJobResult;
use App::MtAws::QueueJob::Delete;
use DeleteTest;
use QueueHelpers;
use TestUtils;

warning_fatal();

use Data::Dumper;

my %opts = (relfilename => 'somefile', archive_id => 'abc');

# test args validation
{
	ok eval { App::MtAws::QueueJob::Delete->new( map { $_ => $opts{$_} } qw/relfilename archive_id/); 1; };
	ok !eval { App::MtAws::QueueJob::Delete->new( map { $_ => $opts{$_} } qw/relfilename/); 1; };
	ok !eval { App::MtAws::QueueJob::Delete->new( map { $_ => $opts{$_} } qw/archive_id/); 1; };
	ok eval { App::MtAws::QueueJob::Delete->new((map { $_ => $opts{$_} } qw/archive_id/), relfilename => 0); 1; };
}

for my $relfilename ($opts{relfilename}, 0) {
	my $j = App::MtAws::QueueJob::Delete->new( relfilename => $relfilename, archive_id => $opts{archive_id});
	DeleteTest::expect_delete($j, $relfilename, $opts{archive_id});
	expect_done($j);
}


1;

