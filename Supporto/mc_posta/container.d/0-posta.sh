#!/usr/bin/env sh
#
# setup posta
#
# Luca Cappelletti (c) 2015 <luca.cappelletti@positronic.ch>
#
# WTF
#

#
# MYSQL
#

MC_CONTAINER_D_DIR="/root/container.d"


DEBIAN_FRONTEND=noninteractive  apt-get install --force-yes --assume-yes -y  pwgen
wait

DEBIAN_FRONTEND=noninteractive apt-get install --force-yes --assume-yes -y nginx-full git rsync libmysqlclient18 libjpeg62 postfix postfix-mysql swaks dovecot-mysql dovecot-pop3d dovecot-imapd dovecot-managesieved postfixadmin
wait

apt-get clean
wait


# mailuser password
[ -f /root/mysql_mailuser_pwd.txt ] && MYSQL_MAILUSER_PWD="$(cat /root/mysql_mailuser_pwd.txt)"

MYSQL_RANDOM_PASSWORD="$(pwgen -s 25 1)"
wait

echo $MYSQL_RANDOM_PASSWORD > /root/mysql_pwd.txt
mysqladmin -u root password $MYSQL_RANDOM_PASSWORD
wait

MYSQL_MAILUSER_PWD="$(pwgen -s 25 1)"
wait
echo $MYSQL_MAILUSER_PWD > /root/mysql_mailuser_pwd.txt

ROOT_PWD="$(cat /root/mysql_pwd.txt)"
DB_NAME="mailserver"
DB_USER="mailuser"
DB_USER_PWD="$(cat /root/mysql_mailuser_pwd.txt)"

mysql -u root --password=$ROOT_PWD -e "CREATE DATABASE IF NOT EXISTS "$DB_NAME";"
wait

mysql -u root --password=$ROOT_PWD -e "DROP USER '"$DB_USER"'@'localhost'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD -e "CREATE USER '"$DB_USER"'@'localhost' IDENTIFIED BY '"$DB_USER_PWD"'; FLUSH PRIVILEGES;"
wait

mysql -u root --password=$ROOT_PWD mailserver < $MC_CONTAINER_D_DIR/$DB_NAME.sql
wait

mysql -u root --password=$ROOT_PWD -e  "GRANT SELECT,INSERT,UPDATE,DELETE ON "$DB_NAME".* TO '"$DB_USER"'@'localhost';"
wait

mysql -u root --password=$ROOT_PWD -e 'show databases;' > /root/the_final_cut.txt
wait

######################
# POSTFIX NEEDS LOVE #
######################

# 1) /etc/postfix/mysql-virtual-mailbox-domains.cf 

mkdir -p /etc/postfix
cat << EOVIRTUALMAILBOXDOMAIN > /etc/postfix/mysql-virtual-mailbox-domains.cf
    user = mailuser
    password = $DB_USER_PWD
    hosts = 127.0.0.1
    dbname = mailserver
    query = SELECT 1 FROM virtual_domains WHERE name='%s'
EOVIRTUALMAILBOXDOMAIN
wait

# 2) postconf -e virtual_mailbox_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postconf -e virtual_mailbox_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
wait


# 3) /etc/postfix/mysql-virtual-mailbox-maps.cf

cat << EOVIRTUALMAILBOXMAPS > /etc/postfix/mysql-virtual-mailbox-maps.cf
    user = mailuser
    password = $DB_USER_PWD
    hosts = 127.0.0.1
    dbname = mailserver
    query = SELECT 1 FROM virtual_users WHERE email='%s'
EOVIRTUALMAILBOXMAPS
wait

# 4) postconf -e virtual_mailbox_maps=mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
postconf -e virtual_mailbox_maps=mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
wait

# 5) /etc/postfix/mysql-virtual-alias-maps.cf

cat << EOVIRTUALALIASMAPS > /etc/postfix/mysql-virtual-alias-maps.cf
    user = mailuser
    password = $DB_USER_PWD
    hosts = 127.0.0.1
    dbname = mailserver
    query = SELECT destination FROM virtual_aliases WHERE source='%s'
EOVIRTUALALIASMAPS
wait

# 6) postconf -e virtual_alias_maps=mysql:/etc/postfix/mysql-virtual-alias-maps.cf
postconf -e virtual_alias_maps=mysql:/etc/postfix/mysql-virtual-alias-maps.cf
wait

# 7) sistematine di fine sessione 
chgrp postfix /etc/postfix/mysql-*.cf
​chmod u=rw,g=r,o= /etc/postfix/mysql-*.cf
wait

# 8) GO BANG
/etc/init.d/postfix restart
wait

###########
# DOVECOT #
###########

mkdir -p /var/vmail
wait
groupadd -g 5000 vmail
wait
useradd -g vmail -u 5000 vmail -d /var/vmail -m
wait
chown -R vmail:vmail /var/vmail
wait
chmod u+w /var/vmail
wait

# FIX: dovecot needs more love!!!

# abilita anche autluc login
mkdir -p /etc/dovecot/conf.d/10-auth.conf;wait
sed -i "s/auth_mechanisms = plain/auth_mechanisms = plain login/g" /etc/dovecot/conf.d/10-auth.conf;wait
sed -i 's/#!include auth-sql.conf.ext/!include auth-sql.conf.ext/g' /etc/dovecot/conf.d/10-auth.conf;wait
sed -i 's/!include auth-system.conf.ext/#!include auth-system.conf.ext/g' 10-auth.conf;wait

# genera auth-sql.conf.ext

cat << EOAUTHSQLCONF > /etc/dovecot/conf.d/auth-sql.conf.ext
# Authentication for SQL users. Included from auth.conf.
#
# <doc/wiki/AuthDatabase.SQL.txt>

passdb {
  driver = sql

  # Path for SQL configuration file, see example-config/dovecot-sql.conf.ext
  args = /etc/dovecot/dovecot-sql.conf.ext
}

# "prefetch" user database means that the passdb already provided the
# needed information and there's no need to do a separate userdb lookup.
# <doc/wiki/UserDatabase.Prefetch.txt>
#userdb {
#  driver = prefetch
#}

#userdb {
#  driver = sql
#  args = /etc/dovecot/dovecot-sql.conf.ext
#}

# If you don't have any user-specific settings, you can avoid the user_query
# by using userdb static instead of userdb sql, for example:
# <doc/wiki/UserDatabase.Static.txt>
#userdb {
  #driver = static
  #args = uid=vmail gid=vmail home=/var/vmail/%u
#}

### AGGIUNGO SOMETHING FOR YOUR MIND
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/vmail/%d/%n
}

# produce quindi: /var/vmail/dominio/utente
EOAUTHSQLCONF

#################
## 10-mail.conf
#################

cat << EOMAILCONF > /etc/dovecot/conf.d/10-mail.conf
##
## Mailbox locations and namespaces
##

# Location for users' mailboxes. The default is empty, which means that Dovecot
# tries to find the mailboxes automatically. This won't work if the user
# doesn't yet have any mail, so you should explicitly tell Dovecot the full
# location.
#
# If you're using mbox, giving a path to the INBOX file (eg. /var/mail/%u)
# isn't enough. You'll also need to tell Dovecot where the other mailboxes are
# kept. This is called the "root mail directory", and it must be the first
# path given in the mail_location setting.
#
# There are a few special variables you can use, eg.:
#
#   %u - username
#   %n - user part in user@domain, same as %u if there's no domain
#   %d - domain part in user@domain, empty if there's no domain
#   %h - home directory
#
# See doc/wiki/Variables.txt for full list. Some examples:
#
#   mail_location = maildir:~/Maildir
#   mail_location = mbox:~/mail:INBOX=/var/mail/%u
#   mail_location = mbox:/var/mail/%d/%1n/%n:INDEX=/var/indexes/%d/%1n/%n
#
# <doc/wiki/MailLocation.txt>
#
#mail_location = mbox:~/mail:INBOX=/var/mail/%u

# If you need to set multiple mailbox locations or want to change default
# namespace settings, you can do it by defining namespace sections.
#
# You can have private, shared and public namespaces. Private namespaces
# are for user's personal mails. Shared namespaces are for accessing other
# users' mailboxes that have been shared. Public namespaces are for shared
# mailboxes that are managed by sysadmin. If you create any shared or public
# namespaces you'll typically want to enable ACL plugin also, otherwise all
# users can access all the shared mailboxes, assuming they have permissions
# on filesystem level to do so.
namespace inbox {
  # Namespace type: private, shared or public
  #type = private

  # Hierarchy separator to use. You should use the same separator for all
  # namespaces or some clients get confused. '/' is usually a good one.
  # The default however depends on the underlying mail storage format.
  #separator = 

  # Prefix required to access this namespace. This needs to be different for
  # all namespaces. For example "Public/".
  #prefix = 

  # Physical location of the mailbox. This is in same format as
  # mail_location, which is also the default for it.
  #location =

  # There can be only one INBOX, and this setting defines which namespace
  # has it.
  inbox = yes

  # If namespace is hidden, it's not advertised to clients via NAMESPACE
  # extension. You'll most likely also want to set list=no. This is mostly
  # useful when converting from another server with different namespaces which
  # you want to deprecate but still keep working. For example you can create
  # hidden namespaces with prefixes "~/mail/", "~%u/mail/" and "mail/".
  #hidden = no

  # Show the mailboxes under this namespace with LIST command. This makes the
  # namespace visible for clients that don't support NAMESPACE extension.
  # "children" value lists child mailboxes, but hides the namespace prefix.
  #list = yes

  # Namespace handles its own subscriptions. If set to "no", the parent
  # namespace handles them (empty prefix should always have this as "yes")
  #subscriptions = yes
}

# Example shared namespace configuration
#namespace {
  #type = shared
  #separator = /

  # Mailboxes are visible under "shared/user@domain/"
  # %%n, %%d and %%u are expanded to the destination user.
  #prefix = shared/%%u/

  # Mail location for other users' mailboxes. Note that %variables and ~/
  # expands to the logged in user's data. %%n, %%d, %%u and %%h expand to the
  # destination user's data.
  #location = maildir:%%h/Maildir:INDEX=~/Maildir/shared/%%u

  # Use the default namespace for saving subscriptions.
  #subscriptions = no

  # List the shared/ namespace only if there are visible shared mailboxes.
  #list = children
#}
# Should shared INBOX be visible as "shared/user" or "shared/user/INBOX"?
#mail_shared_explicit_inbox = yes

# System user and group used to access mails. If you use multiple, userdb
# can override these by returning uid or gid fields. You can use either numbers
# or names. <doc/wiki/UserIds.txt>
#mail_uid =
#mail_gid =

# Group to enable temporarily for privileged operations. Currently this is
# used only with INBOX when either its initial creation or dotlocking fails.
# Typically this is set to "mail" to give access to /var/mail.
#mail_privileged_group =

# Grant access to these supplementary groups for mail processes. Typically
# these are used to set up access to shared mailboxes. Note that it may be
# dangerous to set these if users can create symlinks (e.g. if "mail" group is
# set here, ln -s /var/mail ~/mail/var could allow a user to delete others'
# mailboxes, or ln -s /secret/shared/box ~/mail/mybox would allow reading it).
#mail_access_groups =

# Allow full filesystem access to clients. There's no access checks other than
# what the operating system does for the active UID/GID. It works with both
# maildir and mboxes, allowing you to prefix mailboxes names with eg. /path/
# or ~user/.
#mail_full_filesystem_access = no

##
## Mail processes
##

# Don't use mmap() at all. This is required if you store indexes to shared
# filesystems (NFS or clustered filesystem).
#mmap_disable = no

# Rely on O_EXCL to work when creating dotlock files. NFS supports O_EXCL
# since version 3, so this should be safe to use nowadays by default.
#dotlock_use_excl = yes

# When to use fsync() or fdatasync() calls:
#   optimized (default): Whenever necessary to avoid losing important data
#   always: Useful with e.g. NFS when write()s are delayed
#   never: Never use it (best performance, but crashes can lose data)
#mail_fsync = optimized

# Mail storage exists in NFS. Set this to yes to make Dovecot flush NFS caches
# whenever needed. If you're using only a single mail server this isn't needed.
#mail_nfs_storage = no
# Mail index files also exist in NFS. Setting this to yes requires
# mmap_disable=yes and fsync_disable=no.
#mail_nfs_index = no

# Locking method for index files. Alternatives are fcntl, flock and dotlock.
# Dotlocking uses some tricks which may create more disk I/O than other locking
# methods. NFS users: flock doesn't work, remember to change mmap_disable.
#lock_method = fcntl

# Directory in which LDA/LMTP temporarily stores incoming mails >128 kB.
#mail_temp_dir = /tmp

# Valid UID range for users, defaults to 500 and above. This is mostly
# to make sure that users can't log in as daemons or other system users.
# Note that denying root logins is hardcoded to dovecot binary and can't
# be done even if first_valid_uid is set to 0.
#first_valid_uid = 500
#last_valid_uid = 0

# Valid GID range for users, defaults to non-root/wheel. Users having
# non-valid GID as primary group ID aren't allowed to log in. If user
# belongs to supplementary groups with non-valid GIDs, those groups are
# not set.
#first_valid_gid = 1
#last_valid_gid = 0

# Maximum allowed length for mail keyword name. It's only forced when trying
# to create new keywords.
#mail_max_keyword_length = 50

# ':' separated list of directories under which chrooting is allowed for mail
# processes (ie. /var/mail will allow chrooting to /var/mail/foo/bar too).
# This setting doesn't affect login_chroot, mail_chroot or auth chroot
# settings. If this setting is empty, "/./" in home dirs are ignored.
# WARNING: Never add directories here which local users can modify, that
# may lead to root exploit. Usually this should be done only if you don't
# allow shell access for users. <doc/wiki/Chrooting.txt>
#valid_chroot_dirs = 

# Default chroot directory for mail processes. This can be overridden for
# specific users in user database by giving /./ in user's home directory
# (eg. /home/./user chroots into /home). Note that usually there is no real
# need to do chrooting, Dovecot doesn't allow users to access files outside
# their mail directory anyway. If your home directories are prefixed with
# the chroot directory, append "/." to mail_chroot. <doc/wiki/Chrooting.txt>
#mail_chroot = 

# UNIX socket path to master authentication server to find users.
# This is used by imap (for shared users) and lda.
#auth_socket_path = /var/run/dovecot/auth-userdb

# Directory where to look up mail plugins.
#mail_plugin_dir = /usr/lib/dovecot/modules

# Space separated list of plugins to load for all services. Plugins specific to
# IMAP, LDA, etc. are added to this list in their own .conf files.
#mail_plugins = 

##
## Mailbox handling optimizations
##

# The minimum number of mails in a mailbox before updates are done to cache
# file. This allows optimizing Dovecot's behavior to do less disk writes at
# the cost of more disk reads.
#mail_cache_min_mail_count = 0

# When IDLE command is running, mailbox is checked once in a while to see if
# there are any new mails or other changes. This setting defines the minimum
# time to wait between those checks. Dovecot can also use dnotify, inotify and
# kqueue to find out immediately when changes occur.
#mailbox_idle_check_interval = 30 secs

# Save mails with CR+LF instead of plain LF. This makes sending those mails
# take less CPU, especially with sendfile() syscall with Linux and FreeBSD.
# But it also creates a bit more disk I/O which may just make it slower.
# Also note that if other software reads the mboxes/maildirs, they may handle
# the extra CRs wrong and cause problems.
#mail_save_crlf = no

# Max number of mails to keep open and prefetch to memory. This only works with
# some mailbox formats and/or operating systems.
#mail_prefetch_count = 0

# How often to scan for stale temporary files and delete them (0 = never).
# These should exist only after Dovecot dies in the middle of saving mails.
#mail_temp_scan_interval = 1w

##
## Maildir-specific settings
##

# By default LIST command returns all entries in maildir beginning with a dot.
# Enabling this option makes Dovecot return only entries which are directories.
# This is done by stat()ing each entry, so it causes more disk I/O.
# (For systems setting struct dirent->d_type, this check is free and it's
# done always regardless of this setting)
#maildir_stat_dirs = no

# When copying a message, do it with hard links whenever possible. This makes
# the performance much better, and it's unlikely to have any side effects.
#maildir_copy_with_hardlinks = yes

# Assume Dovecot is the only MUA accessing Maildir: Scan cur/ directory only
# when its mtime changes unexpectedly or when we can't find the mail otherwise.
#maildir_very_dirty_syncs = no

# If enabled, Dovecot doesn't use the S=<size> in the Maildir filenames for
# getting the mail's physical size, except when recalculating Maildir++ quota.
# This can be useful in systems where a lot of the Maildir filenames have a
# broken size. The performance hit for enabling this is very small.
#maildir_broken_filename_sizes = no

##
## mbox-specific settings
##

# Which locking methods to use for locking mbox. There are four available:
#  dotlock: Create <mailbox>.lock file. This is the oldest and most NFS-safe
#           solution. If you want to use /var/mail/ like directory, the users
#           will need write access to that directory.
#  dotlock_try: Same as dotlock, but if it fails because of permissions or
#               because there isn't enough disk space, just skip it.
#  fcntl  : Use this if possible. Works with NFS too if lockd is used.
#  flock  : May not exist in all systems. Doesn't work with NFS.
#  lockf  : May not exist in all systems. Doesn't work with NFS.
#
# You can use multiple locking methods; if you do the order they're declared
# in is important to avoid deadlocks if other MTAs/MUAs are using multiple
# locking methods as well. Some operating systems don't allow using some of
# them simultaneously.
#mbox_read_locks = fcntl
#mbox_write_locks = dotlock fcntl

# Maximum time to wait for lock (all of them) before aborting.
#mbox_lock_timeout = 5 mins

# If dotlock exists but the mailbox isn't modified in any way, override the
# lock file after this much time.
#mbox_dotlock_change_timeout = 2 mins

# When mbox changes unexpectedly we have to fully read it to find out what
# changed. If the mbox is large this can take a long time. Since the change
# is usually just a newly appended mail, it'd be faster to simply read the
# new mails. If this setting is enabled, Dovecot does this but still safely
# fallbacks to re-reading the whole mbox file whenever something in mbox isn't
# how it's expected to be. The only real downside to this setting is that if
# some other MUA changes message flags, Dovecot doesn't notice it immediately.
# Note that a full sync is done with SELECT, EXAMINE, EXPUNGE and CHECK 
# commands.
#mbox_dirty_syncs = yes

# Like mbox_dirty_syncs, but don't do full syncs even with SELECT, EXAMINE,
# EXPUNGE or CHECK commands. If this is set, mbox_dirty_syncs is ignored.
#mbox_very_dirty_syncs = no

# Delay writing mbox headers until doing a full write sync (EXPUNGE and CHECK
# commands and when closing the mailbox). This is especially useful for POP3
# where clients often delete all mails. The downside is that our changes
# aren't immediately visible to other MUAs.
#mbox_lazy_writes = yes

# If mbox size is smaller than this (e.g. 100k), don't write index files.
# If an index file already exists it's still read, just not updated.
#mbox_min_index_size = 0

# Mail header selection algorithm to use for MD5 POP3 UIDLs when
# pop3_uidl_format=%m. For backwards compatibility we use apop3d inspired
# algorithm, but it fails if the first Received: header isn't unique in all
# mails. An alternative algorithm is "all" that selects all headers.
#mbox_md5 = apop3d

##
## mdbox-specific settings
##

# Maximum dbox file size until it's rotated.
#mdbox_rotate_size = 2M

# Maximum dbox file age until it's rotated. Typically in days. Day begins
# from midnight, so 1d = today, 2d = yesterday, etc. 0 = check disabled.
#mdbox_rotate_interval = 0

# When creating new mdbox files, immediately preallocate their size to
# mdbox_rotate_size. This setting currently works only in Linux with some
# filesystems (ext4, xfs).
#mdbox_preallocate_space = no

##
## Mail attachments
##

# sdbox and mdbox support saving mail attachments to external files, which
# also allows single instance storage for them. Other backends don't support
# this for now.

# WARNING: This feature hasn't been tested much yet. Use at your own risk.

# Directory root where to store mail attachments. Disabled, if empty.
#mail_attachment_dir =

# Attachments smaller than this aren't saved externally. It's also possible to
# write a plugin to disable saving specific attachments externally.
#mail_attachment_min_size = 128k

# Filesystem backend to use for saving attachments:
#  posix : No SiS done by Dovecot (but this might help FS's own deduplication)
#  sis posix : SiS with immediate byte-by-byte comparison during saving
#  sis-queue posix : SiS with delayed comparison and deduplication
#mail_attachment_fs = sis posix

# Hash format to use in attachment filenames. You can add any text and
# variables: %{md4}, %{md5}, %{sha1}, %{sha256}, %{sha512}, %{size}.
# Variables can be truncated, e.g. %{sha256:80} returns only first 80 bits
#mail_attachment_hash = %{sha1}

#####
# AGGIUNGO maillocation di tipo Maildir che riflette il nuovo vmail
mail_location = maildir:/var/vmail/%d/%n/Maildir

EOMAILCONF

##################
# 10-master.conf
##################

cat << EOMASTER > /etc/dovecot/conf.d/10-master.conf
#default_process_limit = 100
#default_client_limit = 1000

# Default VSZ (virtual memory size) limit for service processes. This is mainly
# intended to catch and kill processes that leak memory before they eat up
# everything.
#default_vsz_limit = 256M

# Login user is internally used by login processes. This is the most untrusted
# user in Dovecot system. It shouldn't have access to anything at all.
#default_login_user = dovenull

# Internal user is used by unprivileged processes. It should be separate from
# login user, so that login processes can't disturb other processes.
#default_internal_user = dovecot

service imap-login {
  inet_listener imap {
    #port = 143
  }
  inet_listener imaps {
    #port = 993
    #ssl = yes
  }

  # Number of connections to handle before starting a new process. Typically
  # the only useful values are 0 (unlimited) or 1. 1 is more secure, but 0
  # is faster. <doc/wiki/LoginProcess.txt>
  #service_count = 1

  # Number of processes to always keep waiting for more connections.
  #process_min_avail = 0

  # If you set service_count=0, you probably need to grow this.
  #vsz_limit = $default_vsz_limit
}

service pop3-login {
  inet_listener pop3 {
    #port = 110
  }
  inet_listener pop3s {
    #port = 995
    #ssl = yes
  }
}

service lmtp {
  unix_listener lmtp {
    #mode = 0666
  }

  # Create inet listener only if you can't use the above UNIX socket
  #inet_listener lmtp {
    # Avoid making LMTP visible for the entire internet
    #address =
    #port = 
  #}
}

service imap {
  # Most of the memory goes to mmap()ing files. You may need to increase this
  # limit if you have huge mailboxes.
  #vsz_limit = $default_vsz_limit

  # Max. number of IMAP processes (connections)
  #process_limit = 1024
}

service pop3 {
  # Max. number of POP3 processes (connections)
  #process_limit = 1024
}

service auth {
  # auth_socket_path points to this userdb socket by default. It's typically
  # used by dovecot-lda, doveadm, possibly imap process, etc. Users that have
  # full permissions to this socket are able to get a list of all usernames and
  # get the results of everyone's userdb lookups.
  #
  # The default 0666 mode allows anyone to connect to the socket, but the
  # userdb lookups will succeed only if the userdb returns an "uid" field that
  # matches the caller process's UID. Also if caller's uid or gid matches the
  # socket's uid or gid the lookup succeeds. Anything else causes a failure.
  #
  # To give the caller full permissions to lookup all users, set the mode to
  # something else than 0666 and Dovecot lets the kernel enforce the
  # permissions (e.g. 0777 allows everyone full permissions).
  unix_listener auth-userdb {
    #mode = 0666
    #user = 
    #group = 
  }

  # Postfix smtp-auth
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }

  # Auth process is run as this user.
  #user = $default_internal_user
}

service auth-worker {
  # Auth worker process is run as root by default, so that it can access
  # /etc/shadow. If this isn't necessary, the user should be changed to
  # $default_internal_user.
  #user = root
}

service dict {
  # If dict proxy is used, mail processes should have access to its socket.
  # For example: mode=0660, group=vmail and global mail_access_groups=vmail
  unix_listener dict {
    #mode = 0600
    #user = 
    #group = 
  }
}

EOMASTER 


###############
# 15-lda.conf #
###############

cat << EOLDA > /etc/dovecot/conf.d/15-lda.conf
##
## LDA specific settings (also used by LMTP)
##

# Address to use when sending rejection mails.
# Default is postmaster@<your domain>.
#postmaster_address =

# Hostname to use in various parts of sent mails, eg. in Message-Id.
# Default is the system's real hostname.
#hostname = 

# If user is over quota, return with temporary failure instead of
# bouncing the mail.
#quota_full_tempfail = no

# Binary to use for sending mails.
#sendmail_path = /usr/sbin/sendmail

# If non-empty, send mails via this SMTP host[:port] instead of sendmail.
#submission_host =

# Subject: header to use for rejection mails. You can use the same variables
# as for rejection_reason below.
#rejection_subject = Rejected: %s

# Human readable error message for rejection mails. You can use variables:
#  %n = CRLF, %r = reason, %s = original subject, %t = recipient
#rejection_reason = Your message to <%t> was automatically rejected:%n%r

# Delimiter character between local-part and detail in email address.
#recipient_delimiter = +

# Header where the original recipient address (SMTP's RCPT TO: address) is taken
# from if not available elsewhere. With dovecot-lda -a parameter overrides this. 
# A commonly used header for this is X-Original-To.
#lda_original_recipient_header =

# Should saving a mail to a nonexistent mailbox automatically create it?
#lda_mailbox_autocreate = no

# Should automatically created mailboxes be also automatically subscribed?
#lda_mailbox_autosubscribe = no


protocol lda {
  # Space separated list of plugins to load (default is global mail_plugins).
  mail_plugins = \$mail_plugins sieve
}

EOLDA

#####################################
# /etc/dovecot/dovecot-sql.conf.ext #
#####################################

cat << EOSQLCONF > /etc/dovecot/dovecot-sql.conf.ext
# This file is opened as root, so it should be owned by root and mode 0600.
#
# http://wiki2.dovecot.org/AuthDatabase/SQL
#
# For the sql passdb module, you'll need a database with a table that
# contains fields for at least the username and password. If you want to
# use the user@domain syntax, you might want to have a separate domain
# field as well.
#
# If your users all have the same uig/gid, and have predictable home
# directories, you can use the static userdb module to generate the home
# dir based on the username and domain. In this case, you won't need fields
# for home, uid, or gid in the database.
#
# If you prefer to use the sql userdb module, you'll want to add fields
# for home, uid, and gid. Here is an example table:
#
# CREATE TABLE users (
#     username VARCHAR(128) NOT NULL,
#     domain VARCHAR(128) NOT NULL,
#     password VARCHAR(64) NOT NULL,
#     home VARCHAR(255) NOT NULL,
#     uid INTEGER NOT NULL,
#     gid INTEGER NOT NULL,
#     active CHAR(1) DEFAULT 'Y' NOT NULL
# );

# Database driver: mysql, pgsql, sqlite
#driver = 

# Database connection string. This is driver-specific setting.
#
# HA / round-robin load-balancing is supported by giving multiple host
# settings, like: host=sql1.host.org host=sql2.host.org
#
# pgsql:
#   For available options, see the PostgreSQL documention for the
#   PQconnectdb function of libpq.
#   Use maxconns=n (default 5) to change how many connections Dovecot can
#   create to pgsql.
#
# mysql:
#   Basic options emulate PostgreSQL option names:
#     host, port, user, password, dbname
#
#   But also adds some new settings:
#     client_flags        - See MySQL manual
#     ssl_ca, ssl_ca_path - Set either one or both to enable SSL
#     ssl_cert, ssl_key   - For sending client-side certificates to server
#     ssl_cipher          - Set minimum allowed cipher security (default: HIGH)
#     option_file         - Read options from the given file instead of
#                           the default my.cnf location
#     option_group        - Read options from the given group (default: client)
# 
#   You can connect to UNIX sockets by using host: host=/var/run/mysql.sock
#   Note that currently you can't use spaces in parameters.
#
# sqlite:
#   The path to the database file.
#
# Examples:
#   connect = host=192.168.1.1 dbname=users
#   connect = host=sql.example.com dbname=virtual user=virtual password=blarg
#   connect = /etc/dovecot/authdb.sqlite
#
#connect =

# Default password scheme.
#
# List of supported schemes is in
# http://wiki2.dovecot.org/Authentication/PasswordSchemes
#
#default_pass_scheme = MD5

# passdb query to retrieve the password. It can return fields:
#   password - The user's password. This field must be returned.
#   user - user@domain from the database. Needed with case-insensitive lookups.
#   username and domain - An alternative way to represent the "user" field.
#
# The "user" field is often necessary with case-insensitive lookups to avoid
# e.g. "name" and "nAme" logins creating two different mail directories. If
# your user and domain names are in separate fields, you can return "username"
# and "domain" fields instead of "user".
#
# The query can also return other fields which have a special meaning, see
# http://wiki2.dovecot.org/PasswordDatabase/ExtraFields
#
# Commonly used available substitutions (see http://wiki2.dovecot.org/Variables
# for full list):
#   %u = entire user@domain
#   %n = user part of user@domain
#   %d = domain part of user@domain
# 
# Note that these can be used only as input to SQL query. If the query outputs
# any of these substitutions, they're not touched. Otherwise it would be
# difficult to have eg. usernames containing '%' characters.
#
# Example:
#   password_query = SELECT userid AS user, pw AS password \
#     FROM users WHERE userid = '%u' AND active = 'Y'
#
#password_query = \
#  SELECT username, domain, password \
#  FROM users WHERE username = '%n' AND domain = '%d'

# userdb query to retrieve the user information. It can return fields:
#   uid - System UID (overrides mail_uid setting)
#   gid - System GID (overrides mail_gid setting)
#   home - Home directory
#   mail - Mail location (overrides mail_location setting)
#
# None of these are strictly required. If you use a single UID and GID, and
# home or mail directory fits to a template string, you could use userdb static
# instead. For a list of all fields that can be returned, see
# http://wiki2.dovecot.org/UserDatabase/ExtraFields
#
# Examples:
#   user_query = SELECT home, uid, gid FROM users WHERE userid = '%u'
#   user_query = SELECT dir AS home, user AS uid, group AS gid FROM users where userid = '%u'
#   user_query = SELECT home, 501 AS uid, 501 AS gid FROM users WHERE userid = '%u'
#
#user_query = \
#  SELECT home, uid, gid \
#  FROM users WHERE username = '%n' AND domain = '%d'

# If you wish to avoid two SQL lookups (passdb + userdb), you can use
# userdb prefetch instead of userdb sql in dovecot.conf. In that case you'll
# also have to return userdb fields in password_query prefixed with "userdb_"
# string. For example:
#password_query = \
#  SELECT userid AS user, password, \
#    home AS userdb_home, uid AS userdb_uid, gid AS userdb_gid \
#  FROM users WHERE userid = '%u'

# Query to get a list of all usernames.
#iterate_query = SELECT username AS user FROM users


### THE MAGIC HAPPENS
driver = mysql
connect = host=127.0.0.1 dbname=mailserver user=mailuser password=$DB_USER_PWD
default_pass_scheme = PLAIN-MD5
password_query = SELECT email as user, password FROM virtual_users WHERE email='%u';

EOSQLCONF

##########################
# DOVECOT THE FINAL LOVE #
##########################

chown root:root /etc/dovecot/dovecot-sql.conf.ext
chmod go= /etc/dovecot/dovecot-sql.conf.ext

service dovecot restart

#######################################
# POSTFIX and DOVECOT wants make love #
#######################################
cat << EOPOSTFIXMASTER >> /etc/postfix/master.cf

dovecot   unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/dovecot-lda -f \${sender} -d \${recipient}

EOPOSTFIXMASTER

service postfix restart

postconf -e virtual_transport=dovecot
postconf -e dovecot_destination_recipient_limit=1

service postfix restart

##############
# CLEAN ROOM #
##############
[ -f /etc/rc.local.original ] && { mv /etc/rc.local /etc/rc.local.init; } && { mv /etc/rc.local.original /etc/rc.local; }
wait

reboot

exit 0


