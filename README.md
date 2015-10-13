# rt-restore-db
Tales of restoring an RT database from backup

This project collects a number of techniques that I used to restore backup copies of the production RT database on different SQL instances.

I used these techniques successfully to restore the RT database at least twice - on a server running Ubuntu 14.04, and also on my own Mac Mini.

Given my lack of knowledge with MySQL, the activity took me some time with trial and error, and the occasional f*kup, which prompted me to write this down.
Hopefully this will save me time should I have to repeat the task.

## RT Test Server [ Ubuntu 14.04 ]

On the "official" RT Test Server, database restore should be executed frequently, reliably and easily.

To meet these goals, I configured the database and created a script to be run via `cron(1)` that automates the task.

Overall steps:

1. Install MySQL using `apt-get(1)`
2. Configure user profiles
3. Schedule execution of the restore script

### Install MySQL

TODO: Fill installation instructions

### Configuration

TODO: Fill configuration parameters values

### Restore script

A full backup of RT production is taken weekly, with an incremental backup taken daily.

Backup files are saved on the `/tmp` directory of the RT Application server.
The most relevant of these files is the weekly database dump, taken every Sunday during the early morning hours, and saved as a compressed GZip at `/tmp/rt-prod-Sun-db.gz`.

Restoring the RT Production database therefore means reading the saved dump file, decompressing it over the wire and feeding the results to the local `mysql` instance.  This can be done easily over `ssh`, provided Public Key is exchanged and password-less sessions can be successfully established.

At the time of this writing, the restored database is *~30Gb* in size.
While far from enormous, it's still big enough to create a performance and memory issue on the RT Test server, especially considering it's a rather underpowered machine.

To avoid issues, I chose to avoid restoring the largest database table ('Attachments') which weighs more than 25Gb in itself.

The resulting script (`restore_rt.sh`) should be run from `cron(1)` at 08:30 each Sunday (or later).

## Mac Mini [ OSX 10.10 Yosemite and 10.11 El Capitan ]

Restoring a backup of the RT database on a new MySQL instance installed on my Mac Mini required the following overall steps:

1. Install MySQL using HomeBrew
2. Set parameters
3. Restore backup
4. Reset users and passwords
5. Add convenient shell aliases

### Install MySQL

I used HomeBrew to install MySQL, by following instructions in [this article](http://blog.joefallon.net/2013/10/install-mysql-on-mac-osx-using-homebrew/).
Despite being a little outdated, most of it still applies.
In particular, HomeBrew now installs already shortcuts to be used with `launchctl`, that make sure the server is started under your user profile with the correct command line parameters.
As a result, I had version 5.6 ready to run.

### Configuration

The RT database to restore is large and contains very large BLOBs which cause the restore process to fail with a few errors, like:
* MySql Server has gone away
* InnoDB: The total blob data length is greater than 10% of the total redo log size. Please increase total redo log size.

To resolve these, I created a server configuration file in `/etc/my.cnf` according to the guidelines in [this article on StackOverflow](http://stackoverflow.com/questions/7973927/for-homebrew-mysql-installs-wheres-my-cnf).
I applied the settings to `max_allowed_packet` and `wait_timeout` described in [this article](http://stackoverflow.com/questions/12425287/mysql-server-has-gone-away-when-importing-large-sql-file).
The issue with the redo log size has been introduced in version 5.6, and can be fixed by setting `innodb_log_file_size` to a large value (I chose 256M).
See [this article](http://stackoverflow.com/questions/18806377/setting-the-right-mysql-innodb-log-file-size) for a discussion.

### Restore backup

No rocket science here.  Just run
```
create database rtdb;
source rt-prod-Sun-db;
```
and go.  Will take some time, and spit the errors above if the configuration hasn't been set.

### Reset users and passwords

Restoring the RT database will also completely reset user accounts, therefore some further tuning is necessary to prevent being locked out of MySQL.
```
set password for 'root'@'localhost' = password('therootpass');
set password for 'rtuser'@'localhost' = password('thertpass');
flush privileges;
```
as a minimum you'll need to care for `root` and `rtuser` otherwise your server instance will be unusable.
A good summary article can be found [here](https://help.ubuntu.com/community/MysqlPasswordReset).

### Shell aliases

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
