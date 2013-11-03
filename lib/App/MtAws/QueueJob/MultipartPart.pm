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

package App::MtAws::QueueJob::MultipartPart;

our $VERSION = '1.056_1';

use strict;
use warnings;
use Carp;

use App::MtAws::QueueJobResult;
use App::MtAws::Exceptions;
use App::MtAws::TreeHash;
use base 'App::MtAws::QueueJob';

sub init
{
	my ($self) = @_;

	defined($self->{relfilename})||confess;
	$self->{partsize}||confess;
	defined($self->{mtime})||confess;
	$self->{upload_id}||confess;
	$self->{fh}||confess;
	$self->{all_raised} = 0;
	$self->{position} = 0;
	$self->{th} = App::MtAws::TreeHash->new();
	$self->{uploadparts} ||= {};

	$self->enter('fist_part');
}

sub read_part
{
	my ($self) = @_;
	if (my $r = read($self->{fh}, my $data, $self->{partsize})) {
		my $part_th = App::MtAws::TreeHash->new(); #TODO: We calc sha twice for same data chunk here
		$part_th->eat_data(\$data);
		$part_th->calc_tree();

		my $part_final_hash = $part_th->get_final_hash();
		my $start = $self->{position};
		my $attachment = \$data,

		$self->{th}->eat_data(\$data);
		$self->{position} += $r;

		return (1, $start, $part_final_hash, $attachment);
	} else {
		confess "IO error $!" unless defined $r;
		return;
	}


}

sub get_part
{
	my ($self) = @_;

	my ($ok, $start, $part_final_hash, $attachment) = $self->read_part;
	if ($ok) {
		$self->{uploadparts}->{$start} = 1;
		return task "upload_part",
			{
				start => $start,
				upload_id => $self->{upload_id},
				part_final_hash => $part_final_hash,
				relfilename => $self->{relfilename},
				mtime => $self->{mtime},
			} => $attachment => sub {
				delete $self->{uploadparts}->{$start} or confess;
				return;
			};
	} else {
		return;
	}
}

sub on_fist_part
{
	my ($self) = @_;
	my @res = $self->get_part();
	confess "Unexpected: zero-size archive" unless @res;
	return state("other_parts"), @res;
}

sub on_other_parts
{
	my ($self) = @_;
	my @res = $self->get_part();
	return @res ? @res : (keys %{$self->{uploadparts}} ? JOB_WAIT : state('done'));
}


1;
