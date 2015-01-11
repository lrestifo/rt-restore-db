# rt-restore-db
Tales of restoring an RT database from backup

This document describes the steps I took to restore a backup of the RT database on a new MySQL instance that I installed on my Mac Mini.
Given my lack of knowledge with MySQL, the activity took me some time with trial and error, and the occasional f*kup, which prompted me to write this down.
Hopefully this will save me time should I have to repeat the task.

Overall steps:

1. Install MySQL using HomeBrew
2. Set parameters
3. Restore backup
4. Reset users and passwords
5. Add convenient shell aliases

## Install MySQL

I used HomeBrew to install MySQL, by following instructions in [this article](http://blog.joefallon.net/2013/10/install-mysql-on-mac-osx-using-homebrew/).
Despite being a little outdated, most of it still applies.
In particular, HomeBrew now installs already shortcuts to be used with `launchctl`, that make sure the server is started under your user profile with the correct command line parameters.
As a result, I had version 5.6 ready to run.

## Configuration

The RT database to restore is large and contains very large BLOBs which cause the restore process to fail with a few errors, like:
* MySql Server has gone away
* InnoDB: The total blob data length is greater than 10% of the total redo log size. Please increase total redo log size.

To resolve these, I created a server configuration file in `/etc/my.cnf` according to the guidelines in [this article on StackOverflow](http://stackoverflow.com/questions/7973927/for-homebrew-mysql-installs-wheres-my-cnf).
I applied the settings to `max_allowed_packet` and `wait_timeout` described in [this article](http://stackoverflow.com/questions/12425287/mysql-server-has-gone-away-when-importing-large-sql-file).
The issue with the redo log size has been introduced in version 5.6, and can be fixed by setting `innodb_log_file_size` to a large value (I chose 256M).
See [this article](http://stackoverflow.com/questions/18806377/setting-the-right-mysql-innodb-log-file-size) for a discussion.

## Restore backup

No rocket science here.  Just run
```
create database rtdb;
source rt-prod-Sun-db;
```
and go.  Will take some time, and spit the errors above if the configuration hasn't been set.

## Reset users and passwords

Restoring the RT database will also completely reset user accounts, therefore some further tuning is necessary to prevent being locked out of MySQL.
```
set password for 'root'@'localhost' = password('therootpass');
set password for 'rtuser'@'localhost' = password('thertpass');
flush privileges;
```
as a minimum you'll need to care for `root` and `rtuser` otherwise your server instance will be unusable.
A good summary article can be found [here](https://help.ubuntu.com/community/MysqlPasswordReset).

## Shell aliases

Given I could never remember all the necessary commands, I decided to create a shell alias for `mysql` that accepts the following commands:
```
To run a client session:
  mysql report   start mysql client as user 'report'
  mysql root     start mysql client as user 'root'
  mysql rtuser   start mysql client as user 'rtuser'

To run server administration commands:
  mysql errlog   monitor server error log
  mysql start    start mysql server
  mysql stop     stop mysql server
  mysql restart  restart mysql server
  mysql status   report server status
```
This is implemented as a [fish shell](http://fishshell.com/) function.
