#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
exec 1> >(logger -s -t $(basename $0)) 2>&1
####################################################################################################
#
# Title:  RESTORE_RT -- Restore an RT database from backup
# Author: Mon Oct 12 22:07 CET 2015 Luciano Restifo [ lrestifo at esselte dot com ]
# Description:
#   This script restores an RT database on the local server from a production backup.
#   The backup file is saved weekly on a known location on the production RT server.
#   This script should be scheduled to run after the production backup is complete, to restore a
#   database copy on the local server, thus refreshing the test environment.
# Caveats:
#   At the time this script was created, the database to be restored is ~30Gb.  While far from
#   enormous, it's still big enough to create a performance and memory issue on the RT Test server,
#   especially considering the trivial technique this script employs.  To avoid issues, I chose to
#   avoid restoring the largest database table ('Attachments') which weighs 25+Gb in itself.
# Prerequisites:
#   1. ssh keys exchanged between this server and RT production
#   2. mysql 'root' user credentials
# Usage:
#   This script is not meant to be interactive.  Run it from cron(1), instead - 08:30 Sunday
#
####################################################################################################
#
rtUser=sshuser
rtHost=rt.example.com
rtDump=/tmp/rt-prod-Sun-db.gz
dbUser=root
dbPass=password
dbHost=localhost

ssh $rtUser@$rtHost zcat $rtDump | grep -v '^INSERT INTO `Attachments`' | mysql --user=$dbUser --password=$dbPass --host=$dbHost
