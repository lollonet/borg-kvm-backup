#!/bin/bash

VIRSH=/usr/bin/virsh

MAXWAIT=600	# max. seconds to wait for guests to shutdown
DESTROY=no	# set to 'yes' to issue a 'destroy' after waiting MAXWAIT seconds

# sanity check
[ -x $VIRSH ] || exit 0

# get number of running guests
kvm_num_running() {
	virsh list | \
	grep 'running$' | \
	wc -l | \
	awk 'NR==1{print $1}'
}

# execute "destroy" on all running guests
kvm_destroy_all() {
	virsh list | \
	grep 'running$' | \
	sed -re 's/^\s*[0-9-]+\s+(.*?[^ ])\s+running$/"\1"/' | \
	xargs -r -n 1 -P 1 virsh destroy
}

# execute "shutdown" on all running guests
kvm_shutdown_all() {
	virsh list | \
	grep 'running$' | \
	sed -re 's/^\s*[0-9-]+\s+(.*?[^ ])\s+running$/"\1"/' | \
	xargs -r -n 1 -P 1 virsh shutdown

	local w=0
	local n=$(kvm_num_running)

	while [ $n -gt 0 -a $w -lt $MAXWAIT ]
	do
		sleep 5
		n=$(kvm_num_running)
		w=$((w + 5))
	done

	if [ $n -gt 0 -a $DESTROY = "yes" ]
	then
		failure ; echo
		echo -n $"Forcing failed guests off: "
		kvm_destroy_all
		sleep 5
		n=$(kvm_num_running)
	fi

	return $n
}

# stop service
stop() {
	echo -n $"Shutting down guest systems: "
	kvm_shutdown_all >/dev/null 2>&1 && success || failure
	echo
}

# get service status
status() {
	echo -n $"Number of guest systems running: "
	kvm_num_running
}

case "$1" in
	stop|status)
		$1
		;;
	*)
		echo $"Usage: $0 {start|stop|status}"
		exit 1
		;;
esac
