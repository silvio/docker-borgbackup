
# Introduction

This docker project brings the small and simple backup solution [borg] to your
computer.

The container can be pulled via `docker pull silviof/docker-borgbackup`.

# Installation

Retrieve the docker image via `docker pull` and create an alias in your
`.${SHELL}rc` or put a shell script somewhere.

```
% docker pull silviof/docker-borgbackup
```

# How to run

This backup system is controlled via borgctl script from this [repository].
Alternatively the controlling script can be acquired via `docker run --rm
silviof/docker-borgbackup get_borgctl`. The used script must be the same as the
script in the container. This project is configured via ini-files. For this
you need the [shini] ini file parser located at `/usr/bin/shini.sh`. You can
get a copy with `docker run --rm silviof/docker-borgbackup get_shini`.

You have two choices to save you data. The first one is to backup on a local
file storage/mounted device and the second one is a backup via ssh/sftp
protocol and a borg server. Both are possible with this docker backup solution.

You can control the running docker container with some environment
variables.

*   `BORGBACKUP_DOCKER_RUN_SHELL_OPTION` change the docker run call for
    `shell`. Default is `-ti --rm`.
*   `BORGBACKUP_DOCKER_RUN_BACKUP_OPTION` change the docker run call for
    `backup`. Default is `--rm --sig-proxy`.
*   `BORGBACKUP_DOCKER_RUN_SERVER_OPTION` change the docker run call for
    `server`. Default is `--rm --name=backupserver`.

The docker container needs some more data like your ssh-key or/and a
connection to the ssh-agent to work correctly. The container is started via
`sudo` (configurable) and privileged to allow backup of data which isn't
owned by the user starting the container. All folders which are not
stores are mounted in read-only mode.

# a simple example (installation, inifile and backup)

For a simple example let us assume we need to backup everything under
`/development` folder without the `/development/archive` subfolder. We do our
backup everyday at 12 o\`clock and hold the backups for the last 7 days. Our
backup folder is mounted in /media/sde3. The backup should be placed into the
`BACKUP` folder of this device.

The first step is to have a `borgbackup.ini` file. The contents should be
something like this:

    [GENERAL]
    REPOSITORY = "file:///media/sde3"
    FOLDER = "/backupuser"
    SSHKEY = /home/user/.ssh/id_rsa
    ENCRYPTION = "AVeryVeryVeryVeryAndVeryVeryVeryLongishSecureWordHere"
    SUDO = 1
    FILECACHE = /home/user/.cache/borgbackup
    VERBOSE = 1
    STAT = 1
    RESTOREDIR = /storage/restore

    [BACKUP001]
    PATH = /development
    EXCLUDE = /development/archive
    COMPRESSION = zlib,6
    KEEPWITHIN = 1w

Now we should initialize the backup store via `borgctl shell` command. After
that we should be dropped into a container configured for work with borg.

    $ borgctl shell ~/borgbackup.ini
    -+> sudo docker run -ti [...] silviof/docker-borgbackup do_shell
    -+> borg environment loaded
    -+> $BORG_REPO and $BORG_PASSPHRASE are set
    $

We can now work with the `borg` command...

    $ borg --help
    usage: borg [-h]

                {serve,init,check,change-passphrase,create,extract,rename,delete,list,mount,info,prune,upgrade,help}
                ...

    [...]

We should know that `$BORG_REPO`, `$BORG_PASSPHRASE` are set and that all
folders for backup are mounted at the `/BACKUP` directory.

    $ echo $BORG_REPO
    /STORAGE//backupuser
    $ ls $BORG_REPO
    ls: cannot access /STORAGE//sfr: No such file or directory
    $ ls /BACKUP/
    /development

As we see the storage isn't initialized. We have to do this now. borg needs
some options like password, compression etc. because we have set `$BORG_REPO`
and `$BORG_PASSPHRASE` we don't need to specify the complete folder path and
the password.

    $ borg init -e repokey
    Initializing repository at ""
    Key in "<Repository /STORAGE/backupuser>" created.
    Keep this key safe. Your data will be inaccessible without it.
    Synchronizing chunks cache...
    Archives: 0, w/ cached Idx: 0, w/ outdated Idx: 0, w/o cached Idx: 0.
    Done.
    $ ls $BORG_REPO
    README  config  data  hints.0  index.0  lock.roster

The storage is now initialized.

The second step is to try do the backup by hand. Using the `borgctl` script
it is very simple. (example output)

    $ borgctl backup ~/borgbackup.ini
    -+> sudo docker run [...] silviof/docker-borgbackup do_backup

    -+> BACKUP for 001 ...
    -+> borg create -s -v -C zlib,6 -e /development/archive   ::development-201510231842060200 /BACKUP//development
    d /BACKUP/development
    [...]
    ------------------------------------------------------------------------------
    Archive name: ::development-201510231842060200
    Archive fingerprint: 1698bc896eb8c1bd0e4de84e4ddffc2402adad47d44c67eb5691ae04853fccf0
    Start time: Fri Oct 23 18:42:07 2015
    End time: Fri Oct 23 18:42:17 2015
    Duration: 9.33 seconds
    Number of files: 5

                           Original size      Compressed size    Deduplicated size
    This archive:                  362 B                411 B                411 B
    All archives:                  362 B                411 B                411 B

                           Unique chunks         Total chunks
    Chunk index:                       2                    2
    ------------------------------------------------------------------------------
    -+> PRUNE  for 001 ...
    -+> borg prune -p developmenttftp -s -v --keep-within 1w
    Keeping archive: development-201510231842060200       Fri Oct 23 18:42:07 2015

                           Original size      Compressed size    Deduplicated size
    Deleted data:                    0 B                  0 B                  0 B
    All archives:                  362 B                411 B                411 B

                           Unique chunks         Total chunks
    Chunk index:                       2                    2

After controlling that all desired folders and files are backed up, we can
configure automatic backup via cronjob.

Add this to your cronjob via `crontab -e`:

    12 * * * * borgctl backup ${HOME}/borgbackup.ini

[borg]: https://borgbackup.github.io/
[repository]: https://github.com/silvio/docker-borgbackup
[shini]: https://github.com/wallyhall/shini.git
