#! /bin/sh
# vim:ff=unix:enc=utf8:ts=3:sw=3:et
#
# rc.K 		This file is executed by init when it goes into runlevel
#		1, which is the administrative state. It kills all
#		daemons and then puts the system into single user mode.
#		Note that the file systems are kept mounted.
#
# Version:	@(#)/etc/rc.d/rc.K	3.1415 Sat Jan 13 13:37:26 PST 2001
#
# Author:	Miquel van Smoorenburg <miquels@drinkel.nl.mugnet.org>
# Modified by:  Patrick J. Volkerding <volkerdi@slackware.com>
#

# Set the path.
PATH=/sbin:/bin:/usr/bin:/usr/sbin

# Load any needed keyboard mappings:
if test -x /etc/rc.d/rc.keymap ; then
   /etc/rc.d/rc.keymap
fi

# If there are SystemV init scripts for this runlevel, run them.
if test -x /etc/rc.d/rc.sysvinit ; then
   /etc/rc.d/rc.sysvinit
fi

# Try to turn off quota:
if grep -q quota /etc/fstab ; then
   if test -x /sbin/quotaoff ; then
      echo "Turning off filesystem quotas."
      /sbin/quotaoff -a
   fi
fi

# Try to turn off accounting:
if test -x /sbin/accton -a -r /var/log/pacct ; then
   /sbin/accton off
fi

# Run any local shutdown scripts:
if test -x /etc/rc.d/rc.local_shutdown ; then
   /etc/rc.d/rc.local_shutdown stop
fi

# Stop the Apache web server:
if test -x /etc/rc.d/rc.httpd ; then
   /etc/rc.d/rc.httpd stop
fi

# Stop the Samba server:
if test -x /etc/rc.d/rc.samba ; then
   /etc/rc.d/rc.samba stop
fi

# Shut down the NFS server:
if test -x /etc/rc.d/rc.nfsd ; then
   /etc/rc.d/rc.nfsd stop
fi

# Unmount any NFS, SMB, or CIFS filesystems:
echo "Unmounting remote filesystems."
umount -a -r -t nfs,smbfs,cifs

# Shut down PCMCIA devices:
if test -x /etc/rc.d/rc.pcmcia ; then
   /etc/rc.d/rc.pcmcia stop
   # The cards might need a little extra time here to deactivate:
   sleep 5
fi

# Terminate acpid before syslog:
if test -x /etc/rc.d/rc.acpid && test -r /var/run/acpid.pid ; then # quit
   /etc/rc.d/rc.acpid stop
fi

# Kill all processes.
echo
echo "Sending all processes the SIGHUP signal."
killall5 -1
echo -n "Waiting for processes to hang up"
for loop in 0 1 2 3 4 5 ; do
   sleep 1
   echo -n "."
done

echo
echo "Sending all processes the SIGTERM signal."
killall5 -15
echo -n "Waiting for processes to terminate"
for loop in 0 1 2 3 4 5 ; do
   sleep 1
   echo -n "."
done

echo
echo "Sending all processes the SIGKILL signal."
killall5 -9
echo -n "Waiting for processes to exit"
for loop in 0 1 2 3 4 5 ; do
   sleep 1
   echo -n "."
done
echo

# Now go to the single user level
echo "Going to single user mode..."
telinit -t 1 1

