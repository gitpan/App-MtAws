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

package App::MtAws::QueueEngine;

our $VERSION = '1.051_1';

use strict;
use warnings;

use Carp;
use App::MtAws::QueueJobResult;

sub new
{
	my ($class, %args) = @_;
	my $self = \%args;
	$self->{children}||confess;
	$self->{task_inc} = 0;
	@{$self->{freeworkers}} = keys %{$self->{children}};
	bless $self, $class;
	return $self;
}


sub process
{
	my ($self, $task) = @_;
	my $tasks = {};
	while () {
		if (@{ $self->{freeworkers} }) {
			my $res = $task->next;
			if ($res->{code} eq JOB_OK) {
				my $task_id = ++$self->{task_inc};
				my $worker_id = shift @{ $self->{freeworkers} };
				$tasks->{$task_id} = $res->{task};
				$self->queue($worker_id, $task_id, $task);
			} elsif ($res->{code} eq JOB_WAIT) {
				$self->wait_worker($tasks);
			} elsif ($res->{code} eq JOB_DONE) {
				return $task
			} else {
				confess;
			}
		} else {
			$self->wait_worker($tasks);
		}
	}
}

1;
