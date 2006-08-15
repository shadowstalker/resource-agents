#!/bin/bash

#
#  Copyright Red Hat Inc., 2004
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation; either version 2, or (at your option) any
#  later version.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; see the file COPYING.  If not, write to the
#  Free Software Foundation, Inc.,  675 Mass Ave, Cambridge, 
#  MA 02139, USA.


#
# NFS Export Client handler agent script
#

LC_ALL=C
LANG=C
PATH=/bin:/sbin:/usr/bin:/usr/sbin
export LC_ALL LANG PATH

. $(dirname $0)/ocf-shellfuncs

meta_data()
{
	cat <<EOT
<?xml version="1.0" ?>
<resource-agent version="rgmanager 2.0" name="nfsclient">
    <version>1.0</version>

    <longdesc lang="en">
        This defines how a machine or group of machines may access
        an NFS export on the cluster.  IP addresses, IP wildcards,
	hostnames, hostname wildcards, and netgroups are supported.
    </longdesc>
    <shortdesc lang="en">
        Defines an NFS client.
    </shortdesc>

    <parameters>
        <parameter name="name" unique="1" primary="1">
            <longdesc lang="en">
                This is a symbolic name of a client used to reference
                it in the resource tree.  This is NOT the same thing
                as the target option.
            </longdesc>
            <shortdesc lang="en">
                Client Name
            </shortdesc>
            <content type="string"/>
        </parameter>

        <parameter name="target" required="1">
            <longdesc lang="en">
                This is either a hostname, a wildcard (IP address or
                hostname based), or a netgroup to which defining a
                host or hosts to export to.
            </longdesc>
            <shortdesc lang="en">
                Target Hostname, Wildcard, or Netgroup
            </shortdesc>
            <content type="string"/>
        </parameter>

        <parameter name="path" inherit="path">
            <longdesc lang="en">
                This is the path to export to the target.  This
                field is generally left blank, as it inherits the
                path from the parent export.
            </longdesc>
            <shortdesc lang="en">
                Path to Export
            </shortdesc>
            <content type="string"/>
        </parameter>

        <parameter name="fsid" inherit="fsid">
            <longdesc lang="en">
	    	File system ID inherited from the parent nfsexport/
		clusterfs/fs resource.  Putting fsid in the options
		field will override this.
            </longdesc>
            <shortdesc lang="en">
	    	File system ID
            </shortdesc>
            <content type="string"/>
        </parameter>

        <parameter name="options">
            <longdesc lang="en">Defines a list of options for this
                particular client.  See 'man 5 exports' for a list
                of available options.
            </longdesc>
            <shortdesc lang="en">
                Export Options
            </shortdesc>
            <content type="string"/>
        </parameter>

        <parameter name="allow_recover">
            <longdesc lang="en">
		Allows recovery of this NFS client (default = 1) if it
		disappears from the export list.  If set to 0, the service
		will be restarted.  This is useful to help preserve export
		ordering.
            </longdesc>
            <shortdesc lang="en">
		Allow recovery
            </shortdesc>
            <content type="boolean"/>
        </parameter>

    </parameters>

    <actions>
        <action name="start" timeout="90"/>
        <action name="stop" timeout="5"/>
        <action name="recover" timeout="90"/>

	<!-- Checks to see if the export exists in /var/lib/nfs/etab -->
        <action name="status" timeout="5" interval="1m"/>
        <action name="monitor" timeout="5" interval="1m"/>

        <action name="meta-data" timeout="5"/>
        <action name="verify-all" timeout="30"/>
    </actions>

</resource-agent>
EOT
}


verify_options()
{
	declare o
	declare -i ret=0

	[ -z "$OCF_RESKEY_options" ] && return 0
	
	#
	# From exports(5)
	#
	for o in `echo $OCF_RESKEY_options | sed -e s/,/\ /g`; do
		case $o in
		fsid=*)
			ocf_log debug "Using designated $o instead of fsid=$OCF_RESKEY_fsid"
			unset OCF_RESKEY_fsid
			;;
		secure)
			;;
		insecure)
			;;

		rw)
			;;
		ro)
			;;
		async)
			;;
		sync)
			;;
		wdelay)
			;;
		no_wdelay)
			;;
		hide)
			;;
		nohide)
			;;
		subtree_check)
			;;
		no_subtree_check)
			;;
		secure_locks)
			;;
		insecure_locks)
			;;
		auth_nlm)
			;;
		no_auth_nlm)
			;;
		mountpoint=*)
			;;
		mp=*)
			;;
		root_squash)
			;;
		no_root_squash)
			;;
		all_squash)
			;;
		no_all_squash)
			;;
		anonuid)
			;;
		anongid)
			;;
		*)
			ocf_log err "Export Option $o invalid"
			ret=$OCF_ERR_ARGS
			;;
		esac
	done

	return $ret
}


verify_target()
{
	# XXX need to add wildcards, hostname, ip, etc.
	[ -n "$OCF_RESKEY_target" ] && return 0
	
	return $OCF_ERR_ARGS
}


verify_path()
{
	if [ -z "$OCF_RESKEY_path" ]; then
		ocf_log err "No export path specified."
		return $OCF_ERR_ARGS
	fi

	[ -d "$OCF_RESKEY_path" ] && return 0

	ocf_log err "$OCF_RESKEY_path is not a directory"
	
	return $OCF_ERR_ARGS
}


verify_type()
{
	[ -z "$OCF_RESKEY_type" ] && return 0
	[ "$OCF_RESKEY_type" = "nfs" ] && return 0

	ocf_log err "Export type $OCF_RESKEY_type not supported yet"
	return $OCF_ERR_ARGS
}


verify_all()
{
	declare -i ret=0

	verify_type || ret=$OCF_ERR_ARGS
	verify_options || ret=$OCF_ERR_ARGS
	verify_target || ret=$OCF_ERR_ARGS
	verify_path || ret=$OCF_ERR_ARGS

	return $ret
}


case $1 in
start)
	declare option_str

	verify_all || exit $OCF_ERR_ARGS

	#
	# XXX
	# Bad: Side-effect of verify_options: unset OCF_RESKEY_fsid if
	# fsid is specified in the options string.
	#
	if [ -z "$OCF_RESKEY_options" ] && [ -n "$OCF_RESKEY_fsid" ]; then
		option_str="fsid=$OCF_RESKEY_fsid"
	elif [ -n "$OCF_RESKEY_options" ] && [ -z "$OCF_RESKEY_fsid" ]; then
		option_str="$OCF_RESKEY_options"
	elif [ -n "$OCF_RESKEY_fsid" ] && [ -n "$OCF_RESKEY_options" ]; then
		option_str="fsid=$OCF_RESKEY_fsid,$OCF_RESKEY_options"
	fi

	if [ -z "$option_str" ]; then
		ocf_log info "Adding export: ${OCF_RESKEY_target}:${OCF_RESKEY_path}"
		exportfs -i "${OCF_RESKEY_target}:${OCF_RESKEY_path}"
		rv=$?
	else
		ocf_log info "Adding export: ${OCF_RESKEY_target}:${OCF_RESKEY_path} ($option_str)"
		exportfs -i -o $option_str "${OCF_RESKEY_target}:${OCF_RESKEY_path}"
		rv=$?
	fi
	;;

stop)
	verify_all || exit $OCF_ERR_ARGS

	ocf_log info "Removing export: ${OCF_RESKEY_target}:${OCF_RESKEY_path}"
	exportfs -u "${OCF_RESKEY_target}:${OCF_RESKEY_path}"
	rv=$?
	;;

status|monitor)
	verify_all || exit $OCF_ERR_ARGS

	if [ "${OCF_RESKEY_target}" = "*" ]; then
		export OCF_RESKEY_target="\<world\>"
	fi

	#
	# Status check fix from Birger Wathne:
	# * Exports longer than 14 chars have line breaks inserted, which
	#   broke the way the status check worked.
	#
        # Status check fix from Craig Lewis: 
        # * Exports with RegExp metacharacters need to be escaped. 
        #   These metacharacters are: * ? . 
        # 
	export OCF_RESKEY_target_regexp=$(echo $OCF_RESKEY_target | \
		sed -e 's/*/[*]/g' -e 's/?/[?]/g' -e 's/\./\\./g') 
        exportfs -v | tr -d "\n" | sed -e 's/([^)]*)/\n/g' | grep -q \
		"^${OCF_RESKEY_path}[\t ]*.*${OCF_RESKEY_target_regexp}" 
	rv=$? 
	;;

recover)
	if [ "$OCF_RESKEY_allow_recover" = "0" ] || \
	   [ "$OCF_RESKEY_allow_recover" = "no" ] || \
	   [ "$OCF_RESKEY_allow_recover" = "false" ]; then
		exit 1
	fi

	$0 stop || exit 1
	$0 start || exit 1
	;;

restart)
	#
	# Recover might better be "exportfs -r" - reexport
	#
	$0 stop || exit 1
	$0 start || exit 1
	;;

meta-data)
	meta_data
	exit 0
	;;

verify-all)
	verify_all
	rv=$?
	;;

*)
	echo "usage: $0 {start|stop|status|monitor|restart|meta-data|verify-all}"
	rv=$OCF_ERR_GENERIC
	;;
esac

exit $rv